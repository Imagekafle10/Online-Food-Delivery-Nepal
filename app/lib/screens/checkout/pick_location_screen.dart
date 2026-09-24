import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../widgets/gold_button.dart';

/// Result returned to the caller once the user confirms a pin.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String? formattedAddress;

  PickedLocation({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
  });
}

/// Full-screen Google Map. The user drags the map to move a fixed center
/// pin, or taps the locate button to jump to their current GPS position.
/// Confirming reverse-geocodes the pin and pops [PickedLocation].
class PickLocationScreen extends StatefulWidget {
  /// Google Maps / Geocoding API key. Pass this in rather than hardcoding
  /// it here — e.g. via --dart-define=MAPS_API_KEY=xxx at build time, read
  /// with `const String.fromEnvironment('MAPS_API_KEY')`.
  final String apiKey;
  final LatLng initialPosition;

  const PickLocationScreen({
    super.key,
    required this.apiKey,
    this.initialPosition = const LatLng(28.0500, 81.6167), // Nepalgunj fallback
  });

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final fm.MapController _controller = fm.MapController();
  late LatLng _center;
  String? _address;
  bool _locating = false;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition;
    _reverseGeocode(_center);
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _resolvingAddress = true);
    try {
      // Free OpenStreetMap geocoder (no key / billing needed).
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '${pos.latitude}',
        'lon': '${pos.longitude}',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'BhansaApp/1.0',
        'Accept-Language': 'en',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final name = data['display_name']?.toString();
        if (name != null && name.isNotEmpty) {
          if (!mounted) return;
          setState(() => _address = name);
          return;
        }
      }
      if (!mounted) return;
      setState(() => _address = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _address = null);
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please turn on location services')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _controller.move(ll.LatLng(target.latitude, target.longitude), 17);
      setState(() => _center = target);
      _reverseGeocode(target);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedLocation(
        latitude: _center.latitude,
        longitude: _center.longitude,
        formattedAddress: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pin your location')),
      body: Stack(
        children: [
          fm.FlutterMap(
            mapController: _controller,
            options: fm.MapOptions(
              initialCenter: ll.LatLng(_center.latitude, _center.longitude),
              initialZoom: 16,
              onPositionChanged: (camera, hasGesture) {
                _center = LatLng(camera.center.latitude, camera.center.longitude);
              },
              onMapEvent: (event) {
                if (event is fm.MapEventMoveEnd ||
                    event is fm.MapEventFlingAnimationEnd ||
                    event is fm.MapEventDoubleTapZoomEnd ||
                    event is fm.MapEventScrollWheelZoom) {
                  _reverseGeocode(_center);
                }
              },
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bhansa', // your applicationId
              ),
            ],
          ),
          // Fixed center pin — the map moves underneath it.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, size: 44, color: AppColors.gold),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 170,
            child: FloatingActionButton(
              heroTag: 'locate',
              backgroundColor: AppColors.surface,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: AppColors.gold),
                    )
                  : const Icon(Icons.my_location, color: AppColors.gold),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _resolvingAddress
                            ? const Text('Locating address...',
                                style: TextStyle(color: AppColors.textMuted))
                            : Text(
                                _address ?? 'Move the map to set your pin',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GoldButton(label: 'CONFIRM LOCATION', onPressed: _confirm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
