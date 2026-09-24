import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const BusinessCard({super.key, required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: business.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: business.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                if (!business.isOpen)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                      alignment: Alignment.center,
                      child: const Text(
                        'CLOSED',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _TypeBadge(type: business.type),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          business.city ?? business.address ?? '',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text('${business.avgPrepTimeMins} min prep',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                      const SizedBox(width: 14),
                      const Icon(Icons.delivery_dining, size: 15, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text('Rs. ${business.baseDeliveryFee.toStringAsFixed(0)} delivery',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront, size: 36, color: AppColors.gold),
      );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 0.8),
      ),
      child: Text(
        type.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}
