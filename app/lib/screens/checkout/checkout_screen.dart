import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address.dart';
import '../../providers/cart_provider.dart';
import '../../services/address_service.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gold_button.dart';
import '../orders/order_tracking_screen.dart';
import 'add_address_screen.dart';
import 'payment_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressService = AddressService();
  final _orderService = OrderService();
  final _paymentService = PaymentService();
  final _instructionsCtrl = TextEditingController();

  List<UserAddress> _addresses = [];
  UserAddress? _selected;
  String _paymentMethod = 'cod'; // esewa | khalti | cod
  bool _loadingAddresses = true;
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final list = await _addressService.list();
      setState(() {
        _addresses = list;
        _selected = list.firstWhere((a) => a.isDefault,
            orElse: () => list.isNotEmpty ? list.first : list.first);
        _loadingAddresses = false;
      });
    } catch (_) {
      setState(() {
        _addresses = [];
        _loadingAddresses = false;
      });
    }
  }

  Future<void> _addNewAddress() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    if (added == true) _loadAddresses();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a delivery address first')));
      return;
    }
    if (cart.business != null &&
        cart.subtotal < cart.business!.minOrderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Minimum order is Rs. ${cart.business!.minOrderAmount.toStringAsFixed(0)}')),
      );
      return;
    }

    setState(() => _placingOrder = true);
    try {
      final order = await _orderService.placeOrder(
        businessId: cart.business!.id,
        orderType: 'delivery',
        items: cart.lines.map((l) => l.toOrderPayload()).toList(),
        paymentMethod: _paymentMethod,
        deliveryAddressId: _selected!.id,
        specialInstructions: _instructionsCtrl.text.trim(),
      );

      // Kick off gateway payment if needed. eSewa/Khalti open in a WebView
      // that auto-submits/loads the gateway page; COD settles on delivery.
      if (_paymentMethod != 'cod') {
        try {
          final payment = await _paymentService.initiate(
              referenceType: 'order',
              referenceId: order.id,
              method: _paymentMethod);
          if (!mounted) return;
          final outcome = await Navigator.of(context).push<PaymentOutcome>(
            MaterialPageRoute(
                builder: (_) => PaymentWebViewScreen(payment: payment)),
          );
          if (!mounted) return;
          if (outcome != PaymentOutcome.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Payment was not completed. You can retry it from order details.')),
            );
          }
        } catch (_) {
          // Order is already placed; payment can be retried from order details.
        }
      }

      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.id)),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not place order. Try again.')));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Deliver to'),
          const SizedBox(height: 10),
          if (_loadingAddresses)
            const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
          else ...[
            ..._addresses.map((a) => _AddressTile(
                  address: a,
                  selected: _selected?.id == a.id,
                  onTap: () => setState(() => _selected = a),
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addNewAddress,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add new address'),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle('Payment method'),
          const SizedBox(height: 10),
          _PaymentTile(
            title: 'Cash on Delivery',
            subtitle: 'Pay when your order arrives',
            icon: Icons.payments_outlined,
            value: 'cod',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          _PaymentTile(
            title: 'eSewa',
            subtitle: 'Pay securely with eSewa',
            icon: Icons.account_balance_wallet_outlined,
            value: 'esewa',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          _PaymentTile(
            title: 'Khalti',
            subtitle: 'Pay securely with Khalti',
            icon: Icons.credit_card,
            value: 'khalti',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Delivery instructions (optional)'),
          const SizedBox(height: 10),
          TextField(
            controller: _instructionsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'e.g. Ring the bell, leave at the gate...'),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Order summary'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _summaryRow('Subtotal', cart.subtotal),
                  _summaryRow('Delivery fee', cart.deliveryFee),
                  _summaryRow('Tax (13%)', cart.tax),
                  const Divider(height: 20),
                  _summaryRow('Total', cart.total, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          GoldButton(
            label: 'PLACE ORDER • Rs. ${cart.total.toStringAsFixed(0)}',
            onPressed: _placeOrder,
            loading: _placingOrder,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
      color: bold ? AppColors.gold : AppColors.textMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs. ${value.toStringAsFixed(2)}', style: style)
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
}

class _AddressTile extends StatelessWidget {
  final UserAddress address;
  final bool selected;
  final VoidCallback onTap;
  const _AddressTile(
      {required this.address, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: selected ? AppColors.gold : const Color(0xFF2A2A2E),
            width: selected ? 1.4 : 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: AppColors.gold),
        title: Text(address.label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${address.addressLine}${address.city != null ? ', ${address.city}' : ''}'),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: selected ? AppColors.gold : const Color(0xFF2A2A2E),
            width: selected ? 1.4 : 1),
      ),
      child: ListTile(
        onTap: () => onChanged(value),
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
        trailing: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: AppColors.gold),
      ),
    );
  }
}
