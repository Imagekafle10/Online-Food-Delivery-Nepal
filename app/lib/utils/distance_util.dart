import 'dart:math';

/// Great-circle distance between two lat/lng points, in kilometers.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _deg2rad(double deg) => deg * (pi / 180);

/// Delivery fee tiers by straight-line distance from the business to the
/// delivery address:
///   0   - 3km  -> Rs. 50
///   3   - 8km  -> Rs. 150
///   8   - 12km -> Rs. 250
///   >12km      -> Rs. 350
double deliveryFeeForDistance(double km) {
  if (km <= 3) return 50;
  if (km <= 8) return 150;
  if (km <= 12) return 250;
  return 350;
}
