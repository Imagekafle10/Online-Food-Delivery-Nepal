import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/distance_util.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  /// The user's current GPS position, if known. When present (and the
  /// business has lat/lng), the delivery fee shown is calculated by distance
  /// from here using the same tiers as CartProvider.deliveryFee, instead of
  /// falling back to the business's flat base_delivery_fee.
  final double? userLat;
  final double? userLng;

  const BusinessCard({
    super.key,
    required this.business,
    required this.onTap,
    this.userLat,
    this.userLng,
  });

  /// Straight-line distance in km from the user to the business, or null if
  /// either location is unknown.
  double? get _distanceKm {
    if (userLat == null ||
        userLng == null ||
        business.latitude == null ||
        business.longitude == null) {
      return null;
    }
    return distanceKm(
        userLat!, userLng!, business.latitude!, business.longitude!);
  }

  /// Rs. amount to show on the card: distance-based from the user's current
  /// location when we have both points, otherwise the business's flat fee.
  double get _displayFee {
    final km = _distanceKm;
    if (km == null) return business.baseDeliveryFee;
    return deliveryFeeForDistance(km);
  }

  /// "450 m away" / "2.3 km away", or null when the distance is unknown.
  String? get _distanceLabel {
    final km = _distanceKm;
    if (km == null) return null;
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

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
                        style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2),
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
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            business.city ?? business.address ?? '',
                            if (_distanceLabel != null) _distanceLabel!,
                          ].where((s) => s.isNotEmpty).join(' • '),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining,
                          size: 15, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text('Rs. ${_displayFee.toStringAsFixed(0)} delivery',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted)),
                      const SizedBox(width: 12),
                      RatingPill(
                          rating: business.avgRating,
                          count: business.ratingCount),
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
        style: const TextStyle(
            color: AppColors.gold,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5),
      ),
    );
  }
}

/// Small "★ 4.5 (12)" pill. Shows "New" for restaurants with no ratings yet.
class RatingPill extends StatelessWidget {
  final double rating;
  final int count;
  const RatingPill({super.key, required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 15, color: AppColors.gold),
        const SizedBox(width: 3),
        Text(
          count == 0 ? 'New' : '${rating.toStringAsFixed(1)} ($count)',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ]),
    );
  }
}
