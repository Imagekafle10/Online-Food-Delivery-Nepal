import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';

class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final int quantityInCart;
  final VoidCallback onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const MenuItemTile({
    super.key,
    required this.item,
    required this.quantityInCart,
    required this.onAdd,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
                child: item.imageUrl != null
                    ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.isVeg ? Icons.eco : Icons.set_meal,
                        size: 14,
                        color: item.isVeg ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.description!,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.hasDiscount)
                        Text('Rs. ${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough)),
                      if (item.hasDiscount) const SizedBox(width: 6),
                      Text('Rs. ${item.effectivePrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                      if (item.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.discountPercent!.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                                color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 10.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!item.isAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Sold out', style: TextStyle(color: AppColors.danger, fontSize: 12)),
              )
            else if (quantityInCart == 0)
              _AddButton(onTap: onAdd)
            else
              _StepperButton(quantity: quantityInCart, onIncrement: onIncrement!, onDecrement: onDecrement!),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant_menu, color: AppColors.gold),
      );
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
      ),
      onPressed: onTap,
      child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _StepperButton({required this.quantity, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(onTap: onDecrement, child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16, color: AppColors.black))),
          Text('$quantity', style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w800)),
          InkWell(onTap: onIncrement, child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16, color: AppColors.black))),
        ],
      ),
    );
  }
}
