import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  @override
  String toString() => message;
}

class LocationHelper {
  /// Current GPS fix. Requests permission if needed and throws a
  /// [LocationException] with a user-friendly message on failure.
  static Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Turn on location services to continue.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw LocationException('Location permission is required to receive deliveries.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw LocationException(
          'Location permission is permanently denied. Enable it in system settings.');
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw LocationException('Could not get your location. Try again in an open area.');
    }
  }
}
