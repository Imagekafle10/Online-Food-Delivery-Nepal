import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

/// Vertical timeline used on the order-tracking screen. Shows a simplified
/// 4-stage view (Order placed → Cooking → On the way → Delivered); see
/// `simplifiedStageIndex` in models/order.dart for how granular backend
/// statuses map onto these 4 stages.
class OrderStatusStepper extends StatelessWidget {
  final OrderStatus current;
  final bool isCancelled;

  const OrderStatusStepper(
      {super.key, required this.current, this.isCancelled = false});

  @override
  Widget build(BuildContext context) {
    if (isCancelled || current == OrderStatus.cancelled) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: AppColors.danger),
              const SizedBox(width: 12),
              Text(orderStatusLabel(current),
                  style: const TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    final currentIndex = simplifiedStageIndex(current);

    return Column(
      children: List.generate(orderStageLabels.length, (i) {
        final done = currentIndex >= 0 && i <= currentIndex;
        final isLast = i == orderStageLabels.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.gold : AppColors.surfaceAlt,
                      border: Border.all(
                          color:
                              done ? AppColors.gold : const Color(0xFF3A3A3D)),
                    ),
                    child: done
                        ? const Icon(Icons.check,
                            size: 14, color: AppColors.black)
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: done ? AppColors.gold : const Color(0xFF3A3A3D),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Text(
                    orderStageLabels[i],
                    style: TextStyle(
                      color: done ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
