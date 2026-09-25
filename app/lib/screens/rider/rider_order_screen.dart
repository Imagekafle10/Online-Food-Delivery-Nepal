import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../models/rider_order.dart';
import '../../providers/rider_provider.dart';
import '../../services/directions_service.dart';
import '../../services/location_helper.dart';
import '../../services/rider_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gold_button.dart';
import 'rider_deliveries_screen.dart' show StatusPill;

/// One delivery: map + in-app turn-by-turn directions, pickup/drop-off cards,
/// cash info, and status advance buttons.
class RiderOrderScreen extends StatefulWidget {
  final int orderId;
  const RiderOrderScreen({super.key, required this.orderId});

  @override
  State<RiderOrderScreen> createState() => _RiderOrderScreenState();
}

class _RiderOrderScreenState extends State<RiderOrderScreen> {
  final _service = RiderService();
  RiderOrder? _order;
  RiderBusiness? _business;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  final fm.MapController _map = fm.MapController();
  bool _mapReady = false;
  String? _dropGuess; // readable address looked up from the map pin

  // Route state
  RouteResult? _route;
  List<ll.LatLng> _routePoints = [];
  bool _loadingRoute = false;
  String? _routeError;
  LatLng? _lastRouteOrigin;
  LatLng? _lastRouteDest;

  // In-app navigation mode
  bool _navMode = false;
  int _currentStepIndex = 0;
  StreamSubscription<Position>? _posSub;
  Position? _livePos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await _service.getOrder(widget.orderId);
      if (!mounted) return;
      final rider = context.read<RiderProvider>();
      var business = rider.businessOf(order.businessId);
      if (business == null && order.businessId != 0) {
        business = await _service.getBusiness(order.businessId);
        if (!mounted) return;
        rider.cacheBusiness(business);
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _business = business;
        _loading = false;
        _error = null;
      });
      _fitMap();
      _lookupDropAddress();
      await _refreshRoute();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  LatLng? get _pickup {
    final b = _business;
    if (b?.latitude == null || b?.longitude == null) return null;
    return LatLng(b!.latitude!, b.longitude!);
  }

  LatLng? get _drop {
    final o = _order;
    if (o?.dropLat == null || o?.dropLng == null) return null;
    return LatLng(o!.dropLat!, o.dropLng!);
  }

  /// True while the kitchen still has the order (rider should go to restaurant).
  bool get _goingToRestaurant {
    final s = _order?.status;
    return s == OrderStatus.accepted || s == OrderStatus.cooking;
  }

  /// Where the rider should head right now.
  LatLng? get _target => _goingToRestaurant ? _pickup : _drop;

  String get _targetName => _goingToRestaurant ? 'restaurant' : 'customer';

  Future<void> _fitMap() async {
    final a = _pickup, b = _drop;
    if (!_mapReady || a == null || b == null) return;
    if (a.latitude == b.latitude && a.longitude == b.longitude) return;
    await Future.delayed(const Duration(milliseconds: 350));
    try {
      _map.fitCamera(fm.CameraFit.bounds(
        bounds: fm.LatLngBounds(
          ll.LatLng(
            a.latitude < b.latitude ? a.latitude : b.latitude,
            a.longitude < b.longitude ? a.longitude : b.longitude,
          ),
          ll.LatLng(
            a.latitude > b.latitude ? a.latitude : b.latitude,
            a.longitude > b.longitude ? a.longitude : b.longitude,
          ),
        ),
        padding: const EdgeInsets.all(70),
      ));
    } catch (_) {}
  }

  Future<void> _refreshRoute({bool force = false}) async {
    final dest = _target;
    if (dest == null || _loadingRoute) return;

    LatLng? origin;
    final pos = _livePos ?? context.read<RiderProvider>().lastPosition;
    if (pos != null) {
      origin = LatLng(pos.latitude, pos.longitude);
    } else {
      // Fall back so we still show a useful preview route.
      try {
        final p = await LocationHelper.current();
        origin = LatLng(p.latitude, p.longitude);
        _livePos = p;
      } catch (_) {
        origin = _goingToRestaurant ? null : _pickup;
      }
    }
    if (origin == null) {
      setState(() => _routeError = 'Waiting for your GPS location…');
      return;
    }

    if (!force &&
        _lastRouteOrigin != null &&
        _lastRouteDest != null &&
        _almostSame(_lastRouteOrigin!, origin) &&
        _almostSame(_lastRouteDest!, dest) &&
        _route != null) {
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      final result = await DirectionsService.instance.getRoute(
        origin: origin,
        destination: dest,
      );
      if (!mounted) return;

      _lastRouteOrigin = origin;
      _lastRouteDest = dest;

      setState(() {
        _loadingRoute = false;
        _route = result;
        _routeError = null;
        _currentStepIndex = 0;
        _routePoints =
            result.points.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
      });

      if (_mapReady && result.points.length >= 2) {
        _fitToPoints(result.points);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _route = null;
        _routePoints = [];
        _routeError = e.toString().replaceFirst('DirectionsException: ', '');
      });
    }
  }

  bool _almostSame(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 0.00015 &&
      (a.longitude - b.longitude).abs() < 0.00015;

  Future<void> _fitToPoints(List<LatLng> points) async {
    if (!_mapReady || points.isEmpty) return;
    try {
      double minLat = points.first.latitude, maxLat = points.first.latitude;
      double minLng = points.first.longitude, maxLng = points.first.longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      _map.fitCamera(fm.CameraFit.bounds(
        bounds: fm.LatLngBounds(ll.LatLng(minLat, minLng), ll.LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(60),
      ));
    } catch (_) {}
  }

  String? _distanceText() {
    final pos = _livePos ?? context.watch<RiderProvider>().lastPosition;
    final t = _target;
    if (pos == null || t == null) return null;
    final m = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, t.latitude, t.longitude);
    final d = m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';
    return '$d to $_targetName';
  }

  // ---------------------------------------------------------------------------
  // In-app navigation
  // ---------------------------------------------------------------------------

  Future<void> _startInAppNav() async {
    if (_target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No destination coordinates')),
      );
      return;
    }

    // Ensure we have a fresh route from live GPS.
    await _refreshRoute(force: true);
    if (!mounted) return;
    if (_route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_routeError ?? 'Could not load route')),
      );
      return;
    }

    setState(() {
      _navMode = true;
      _currentStepIndex = 0;
    });
    _startPositionStream();
  }

  void _stopInAppNav() {
    _posSub?.cancel();
    _posSub = null;
    setState(() => _navMode = false);
  }

  void _startPositionStream() {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8, // update every ~8 m
      ),
    ).listen((pos) {
      if (!mounted || !_navMode) return;
      setState(() => _livePos = pos);
      _updateCurrentStep(pos);
      // Keep map centred on the rider while navigating.
      if (_mapReady) {
        _map.move(ll.LatLng(pos.latitude, pos.longitude), 17);
      }
    }, onError: (_) {});
  }

  void _updateCurrentStep(Position pos) {
    final route = _route;
    if (route == null || route.steps.isEmpty) return;

    // Advance when rider is within ~35 m of the end of the current step.
    var idx = _currentStepIndex;
    while (idx < route.steps.length - 1) {
      final end = route.steps[idx].end;
      final d = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, end.latitude, end.longitude);
      if (d < 35) {
        idx++;
      } else {
        break;
      }
    }
    if (idx != _currentStepIndex) {
      setState(() => _currentStepIndex = idx);
    }
  }

  IconData _maneuverIcon(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
      case 'ramp-left':
      case 'fork-left':
      case 'keep-left':
        return Icons.turn_left;
      case 'turn-right':
      case 'ramp-right':
      case 'fork-right':
      case 'keep-right':
        return Icons.turn_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'merge':
        return Icons.merge;
      case 'straight':
        return Icons.straight;
      default:
        return Icons.navigation;
    }
  }

  /// Looks up a readable address for the customer's pin (free OpenStreetMap
  /// geocoder). Only used when the backend sends no address text.
  Future<void> _lookupDropAddress() async {
    final d = _drop;
    if (d == null || (_order?.dropAddress ?? '').isNotEmpty || _dropGuess != null) return;
    try {
      final res = await http.get(
        Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'format': 'jsonv2',
          'lat': '${d.latitude}',
          'lon': '${d.longitude}',
        }),
        headers: {'User-Agent': 'com.example.foodie_black_gold', 'Accept-Language': 'en'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final name = (jsonDecode(res.body) as Map)['display_name']?.toString();
        if (mounted && name != null && name.isNotEmpty) {
          setState(() => _dropGuess = name);
        }
      }
    } catch (_) {}
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone app')),
      );
    }
  }

  Future<void> _copyText(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what copied')),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.gold),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  // External Google Maps (kept as secondary option)
  Future<void> _openExternalMaps() async {
    final dest = _target;
    if (dest == null) return;
    Uri uri;
    if (!kIsWeb && Platform.isAndroid) {
      uri = DirectionsService.androidNavigationUri(dest);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    uri = DirectionsService.navigationUri(dest);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _confirmDelivered(RiderOrder o) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm delivery'),
        content: Text(o.isCashToCollect
            ? 'Have you handed over the order and collected Rs. ${o.totalAmount.toStringAsFixed(0)} in cash?'
            : 'Have you handed the order to the customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, delivered')),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _advance() async {
    final o = _order;
    if (o == null || _acting) return;
    final rider = context.read<RiderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (o.status == OrderStatus.onTheWay && !await _confirmDelivered(o)) return;

    setState(() => _acting = true);
    try {
      // New backend flow:
      //   accepted / cooking  → markPickedUp  → on_the_way
      //   on_the_way          → markDelivered → delivered
      switch (o.status) {
        case OrderStatus.accepted:
        case OrderStatus.cooking:
          await _service.markPickedUp(o.id);
          break;
        case OrderStatus.onTheWay:
          await _service.markDelivered(o.id);
          break;
        default:
          break;
      }
      final delivered = o.status == OrderStatus.onTheWay;
      await rider.refresh();
      if (delivered) {
        // Backend now has this order as `delivered` — pull the rider's
        // history so the just-finished job shows up right away instead of
        // waiting for the next scheduled refresh.
        unawaited(rider.refreshHistory());
        messenger.showSnackBar(const SnackBar(content: Text('Delivery completed. Great job!')));
        navigator.pop();
        return;
      }
      await _load(); // refreshes target + route
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _acting = false);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final o = _order;

    if (_navMode && o != null) {
      return _buildNavScaffold(o);
    }

    return Scaffold(
      appBar: AppBar(title: Text(o != null ? '#${o.orderNumber}' : 'Delivery')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : o == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error ?? 'Order not found',
                          style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _load();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildBody(o),
      bottomNavigationBar: o == null || _navMode ? null : _buildAction(o),
    );
  }

  /// Full-screen in-app navigation view.
  Widget _buildNavScaffold(RiderOrder o) {
    final route = _route;
    final step = (route != null && route.steps.isNotEmpty)
        ? route.steps[_currentStepIndex.clamp(0, route.steps.length - 1)]
        : null;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Next instruction banner
            if (step != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                color: AppColors.gold,
                child: Row(
                  children: [
                    Icon(_maneuverIcon(step.maneuver), color: Colors.black, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.instruction,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${step.distanceText}  ·  ${step.durationText}',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Map
            Expanded(
              flex: 3,
              child: _buildMap(navStyle: true),
            ),

            // Summary + steps list
            Expanded(
              flex: 2,
              child: Container(
                color: AppColors.surface,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          if (route != null) ...[
                            const Icon(Icons.route, color: AppColors.gold, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${route.distanceText}  ·  ${route.durationText}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _openExternalMaps,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Google Maps'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.gold,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: route == null || route.steps.isEmpty
                          ? const Center(
                              child: Text('No steps',
                                  style: TextStyle(color: AppColors.textMuted)))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              itemCount: route.steps.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: Color(0xFF2A2A2E)),
                              itemBuilder: (ctx, i) {
                                final s = route.steps[i];
                                final active = i == _currentStepIndex;
                                return ListTile(
                                  dense: true,
                                  selected: active,
                                  selectedTileColor:
                                      AppColors.gold.withValues(alpha: 0.12),
                                  leading: Icon(
                                    _maneuverIcon(s.maneuver),
                                    color: active ? AppColors.gold : AppColors.textMuted,
                                  ),
                                  title: Text(
                                    s.instruction,
                                    style: TextStyle(
                                      fontWeight:
                                          active ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  trailing: Text(
                                    s.distanceText,
                                    style: TextStyle(
                                      color: active
                                          ? AppColors.gold
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _stopInAppNav,
                                child: const Text('Exit navigation'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _acting ? null : _advance,
                                child: Text(
                                  o.status == OrderStatus.onTheWay
                                      ? 'Mark delivered'
                                      : 'Picked up',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RiderOrder o) {
    final distance = _distanceText();
    final route = _route;

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async {
        await _load();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              StatusPill(status: o.status),
              const Spacer(),
              if (distance != null)
                Row(
                  children: [
                    const Icon(Icons.near_me, size: 16, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMap(),
          const SizedBox(height: 10),

          // Primary: in-app navigation
          if (_target != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loadingRoute ? null : _startInAppNav,
                icon: _loadingRoute
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.navigation, size: 22),
                label: Text(
                  _loadingRoute ? 'Loading route…' : 'Navigate to $_targetName',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

          // Route summary / error
          if (route != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  '${route.distanceText} · ${route.durationText}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _refreshRoute(force: true),
                  child: const Text('Refresh', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ] else if (_routeError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _routeError!,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _refreshRoute(force: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry route'),
            ),
          ] else if (_loadingRoute) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                ),
                SizedBox(width: 8),
                Text('Loading route…',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              ],
            ),
          ],

          // Secondary: open external Google Maps
          TextButton.icon(
            onPressed: _openExternalMaps,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open in Google Maps instead'),
          ),

          const SizedBox(height: 8),
          _placeCard(
            icon: Icons.storefront,
            label: 'PICKUP',
            title: _business?.name ?? 'Restaurant #${o.businessId}',
            lines: [
              if ((_business?.fullAddress ?? '').isNotEmpty) _business!.fullAddress,
              if ((_business?.phone ?? '').isNotEmpty) 'Phone: ${_business!.phone}',
            ],
            actions: [
              if ((_business?.phone ?? '').isNotEmpty)
                _actionBtn(Icons.call, 'Call restaurant', () => _callPhone(_business!.phone!)),
            ],
            highlight: _goingToRestaurant,
          ),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final addr = (o.dropAddress ?? '').isNotEmpty
                ? o.dropAddress
                : _dropGuess;
            final approx = (o.dropAddress ?? '').isEmpty && _dropGuess != null;
            final phone = o.customerPhone;
            return _placeCard(
              icon: Icons.location_on,
              label: 'DROP-OFF',
              title: (o.customerName ?? '').isNotEmpty ? o.customerName! : 'Customer',
              lines: [
                if ((addr ?? '').isNotEmpty)
                  'Address: $addr${approx ? '  (approx., from map pin)' : ''}',
                if ((phone ?? '').isNotEmpty) 'Phone: $phone',
                if (_drop != null)
                  'Pin: ${_drop!.latitude.toStringAsFixed(5)}, ${_drop!.longitude.toStringAsFixed(5)}',
                if ((o.deliveryInstructions ?? '').isNotEmpty)
                  'Note: ${o.deliveryInstructions}',
                if ((o.specialInstructions ?? '').isNotEmpty)
                  'Order note: ${o.specialInstructions}',
              ],
              actions: [
                if ((phone ?? '').isNotEmpty)
                  _actionBtn(Icons.call, 'Call customer', () => _callPhone(phone!)),
                if ((addr ?? '').isNotEmpty)
                  _actionBtn(Icons.copy, 'Copy address', () => _copyText(addr!, 'Address')),
                if (_drop != null)
                  _actionBtn(Icons.pin_drop, 'Copy pin',
                      () => _copyText('${_drop!.latitude},${_drop!.longitude}', 'Pin')),
              ],
              highlight: !_goingToRestaurant,
            );
          }),
          const SizedBox(height: 16),
          _paymentCard(o),
          const SizedBox(height: 16),
          const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: o.items.isEmpty
                  ? const Text('No item details', style: TextStyle(color: AppColors.textMuted))
                  : Column(
                      children: o.items
                          .map((i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text('${i.quantity} ×  ',
                                        style: const TextStyle(
                                            color: AppColors.gold, fontWeight: FontWeight.w700)),
                                    Expanded(child: Text(i.itemName)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMap({bool navStyle = false}) {
    final pickup = _pickup, drop = _drop;
    final start = _target ?? pickup ?? drop;
    if (start == null) {
      return Container(
        height: navStyle ? double.infinity : 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: navStyle ? null : BorderRadius.circular(16),
        ),
        child: const Text('No map coordinates for this order',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final live = _livePos ?? context.watch<RiderProvider>().lastPosition;
    final map = fm.FlutterMap(
      mapController: _map,
      options: fm.MapOptions(
        initialCenter: ll.LatLng(start.latitude, start.longitude),
        initialZoom: navStyle ? 16 : 14,
        onMapReady: () {
          _mapReady = true;
          if (!navStyle) {
            _fitMap();
            _refreshRoute();
          }
        },
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bhansa', // your applicationId
        ),
        if (_routePoints.length >= 2)
          fm.PolylineLayer(polylines: [
            fm.Polyline(
              points: _routePoints,
              color: AppColors.gold,
              strokeWidth: 5,
            ),
          ]),
        fm.MarkerLayer(markers: [
          if (pickup != null)
            fm.Marker(
              point: ll.LatLng(pickup.latitude, pickup.longitude),
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.location_on, size: 40, color: Colors.orange),
            ),
          if (drop != null)
            fm.Marker(
              point: ll.LatLng(drop.latitude, drop.longitude),
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.location_on, size: 40, color: Colors.green),
            ),
          if (live != null)
            fm.Marker(
              point: ll.LatLng(live.latitude, live.longitude),
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
        ]),
      ],
    );

    if (navStyle) return map;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            map,
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _loadingRoute ? null : () => _refreshRoute(force: true),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.route, size: 16, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          _routePoints.isEmpty ? 'Show route' : 'Refresh route',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeCard({
    required IconData icon,
    required String label,
    required String title,
    required List<String> lines,
    List<Widget> actions = const [],
    bool highlight = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlight ? AppColors.gold : const Color(0xFF2A2A2E),
          width: highlight ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  for (final l in lines) ...[
                    const SizedBox(height: 3),
                    Text(l, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 6, children: actions),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(RiderOrder o) {
    final cash = o.isCashToCollect;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cash
            ? AppColors.gold.withValues(alpha: 0.12)
            : AppColors.success.withValues(alpha: 0.10),
        border: Border.all(color: cash ? AppColors.gold : AppColors.success),
      ),
      child: Row(
        children: [
          Icon(cash ? Icons.payments_outlined : Icons.check_circle_outline,
              color: cash ? AppColors.gold : AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cash ? 'Collect cash from customer' : 'Already paid (${o.paymentMethod})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    cash
                        ? 'Nothing to hand over until you collect'
                        : 'Do not collect any money',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
          Text('Rs. ${o.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cash ? AppColors.gold : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget? _buildAction(RiderOrder o) {
    String? label;
    IconData? icon;
    switch (o.status) {
      case OrderStatus.accepted:
      case OrderStatus.cooking:
        label = 'PICKED UP FROM RESTAURANT';
        icon = Icons.shopping_bag_outlined;
        break;
      case OrderStatus.onTheWay:
        label = 'MARK AS DELIVERED';
        icon = Icons.check_circle_outline;
        break;
      default:
        break;
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: label == null
            ? Text('This delivery is ${orderStatusLabel(o.status).toLowerCase()}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted))
            : GoldButton(label: label, icon: icon, loading: _acting, onPressed: _advance),
      ),
    );
  }
}
