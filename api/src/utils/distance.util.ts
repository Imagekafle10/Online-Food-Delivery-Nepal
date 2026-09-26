/**
 * Great-circle distance between two lat/lng points, in kilometers.
 * Mirrors lib/utils/distance_util.dart on the Flutter app so client-side
 * estimates and the server-computed final fee always agree.
 */
export function distanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const earthRadiusKm = 6371.0;
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

function deg2rad(deg: number): number {
  return deg * (Math.PI / 180);
}

/**
 * Delivery fee tiers by straight-line distance from the business to the
 * delivery address (same tiers as deliveryFeeForDistance in the Flutter app):
 *   0   - 3km  -> Rs. 50
 *   3   - 8km  -> Rs. 150
 *   8   - 12km -> Rs. 250
 *   >12km      -> Rs. 350
 */
export function deliveryFeeForDistance(km: number): number {
  if (km <= 3) return 50;
  if (km <= 8) return 150;
  if (km <= 12) return 250;
  return 350;
}
