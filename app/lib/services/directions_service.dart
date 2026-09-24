import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteStep {
  final String instruction;
  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final LatLng start;
  final LatLng end;
  final String? maneuver;

  RouteStep({
    required this.instruction,
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.start,
    required this.end,
    this.maneuver,
  });
}

class RouteResult {
  final List<LatLng> points;
  final List<RouteStep> steps;
  final String distanceText;
  final String durationText;
  final int distanceMeters;
  final int durationSeconds;

  RouteResult({
    required this.points,
    required this.steps,
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class DirectionsException implements Exception {
  final String message;
  DirectionsException(this.message);
  @override
  String toString() => message;
}

/// Free routing via OSRM (OpenStreetMap). No API key, no billing.
/// The public server is for light use. For heavy production traffic,
/// host your own OSRM or use a paid routing provider.
class DirectionsService {
  DirectionsService._();
  static final DirectionsService instance = DirectionsService._();

  Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );

    late final http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw DirectionsException('Network error loading route: $e');
    }
    if (res.statusCode != 200) {
      throw DirectionsException('Routing HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw DirectionsException(
          data['message']?.toString() ?? 'No route found (${data['code']})');
    }

    final route = (data['routes'] as List).first as Map<String, dynamic>;
    final coords = (route['geometry'] as Map<String, dynamic>)['coordinates'] as List;
    final points = coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    final totalM = (route['distance'] as num).round();
    final totalS = (route['duration'] as num).round();

    final steps = <RouteStep>[];
    final legs = route['legs'] as List? ?? [];
    if (legs.isNotEmpty) {
      final raw = (legs.first as Map<String, dynamic>)['steps'] as List? ?? [];
      for (var i = 0; i < raw.length; i++) {
        final s = raw[i] as Map<String, dynamic>;
        final m = s['maneuver'] as Map<String, dynamic>;
        final loc = m['location'] as List;
        final start =
            LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
        LatLng end = destination;
        if (i + 1 < raw.length) {
          final nl = (raw[i + 1]['maneuver']['location']) as List;
          end = LatLng((nl[1] as num).toDouble(), (nl[0] as num).toDouble());
        }
        final dist = (s['distance'] as num).round();
        final dur = (s['duration'] as num).round();
        steps.add(RouteStep(
          instruction: _instruction(
            m['type']?.toString() ?? '',
            m['modifier']?.toString(),
            s['name']?.toString() ?? '',
          ),
          distanceText: _fmtDist(dist),
          distanceMeters: dist,
          durationText: _fmtDur(dur),
          start: start,
          end: end,
          maneuver: _maneuver(m['type']?.toString(), m['modifier']?.toString()),
        ));
      }
    }

    return RouteResult(
      points: points,
      steps: steps,
      distanceText: _fmtDist(totalM),
      durationText: _fmtDur(totalS),
      distanceMeters: totalM,
      durationSeconds: totalS,
    );
  }

  Future<List<LatLng>?> getRoutePoints({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      return (await getRoute(origin: origin, destination: destination)).points;
    } catch (_) {
      return null;
    }
  }

  static Uri navigationUri(LatLng destination, {String? label}) {
    final dest = '${destination.latitude},${destination.longitude}';
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$dest&travelmode=driving&dir_action=navigate',
    );
  }

  static Uri androidNavigationUri(LatLng destination) {
    return Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}&mode=d',
    );
  }

  static String _fmtDist(int m) =>
      m < 1000 ? '$m m' : '${(m / 1000).toStringAsFixed(1)} km';

  static String _fmtDur(int s) {
    final min = (s / 60).round();
    if (min < 60) return '$min min';
    return '${min ~/ 60} h ${min % 60} min';
  }

  static String? _maneuver(String? type, String? mod) {
    if (type == 'arrive') return 'straight';
    switch (mod) {
      case 'left':
        return 'turn-left';
      case 'right':
        return 'turn-right';
      case 'slight left':
        return 'turn-slight-left';
      case 'slight right':
        return 'turn-slight-right';
      case 'sharp left':
        return 'turn-sharp-left';
      case 'sharp right':
        return 'turn-sharp-right';
      case 'uturn':
        return 'uturn-left';
      default:
        return 'straight';
    }
  }

  static String _instruction(String type, String? mod, String road) {
    final onto = road.isEmpty ? '' : ' onto $road';
    final on = road.isEmpty ? '' : ' on $road';
    switch (type) {
      case 'depart':
        return 'Head${mod != null ? ' $mod' : ''}$on';
      case 'arrive':
        return 'Arrive at your destination';
      case 'roundabout':
      case 'rotary':
        return 'Take the roundabout$onto';
      case 'turn':
      case 'end of road':
        return 'Turn ${mod ?? ''}$onto'.replaceAll('  ', ' ');
      case 'fork':
        return 'Keep ${mod ?? 'straight'} at the fork$onto';
      case 'merge':
        return 'Merge$onto';
      default:
        return 'Continue${mod != null ? ' $mod' : ''}$on';
    }
  }
}
