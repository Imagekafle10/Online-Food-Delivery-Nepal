import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gold_button.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: cart.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, size: 18, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(cart.business?.name ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final line = cart.lines[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(line.item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    if (line.selectedAddons.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          line.selectedAddons.map((a) => a.name).join(', '),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text('Rs. ${line.lineTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () => cart.updateQuantity(line, line.quantity - 1),
                                    ),
                                    Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => cart.updateQuantity(line, line.quantity + 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _Summary(cart: cart),
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CartProvider cart;
  const _Summary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFF2A2A2E))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _row('Subtotal', cart.subtotal),
            _row('Delivery fee', cart.deliveryFee),
            _row('Tax (13%)', cart.tax),
            const Divider(height: 20),
            _row('Total', cart.total, bold: true),
            const SizedBox(height: 16),
            GoldButton(
              label: 'PROCEED TO CHECKOUT',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
      fontSize: bold ? 16 : 14,
      color: bold ? AppColors.gold : AppColors.textMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs. ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Add something tasty from a restaurant.', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
