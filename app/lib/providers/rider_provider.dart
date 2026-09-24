import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/rider_order.dart';
import '../services/api_client.dart';
import '../services/location_helper.dart';
import '../services/rider_service.dart';

/// Holds everything the rider app needs: online state, active deliveries,
/// live GPS, and the background polling / location-ping timers.
///
/// The backend has no "offer" step — a rider can be assigned once the kitchen
/// has accepted (or while cooking). The nearest `available` rider (one with a
/// known location) may be auto-assigned, or a dispatcher can assign manually.
/// The app simply polls GET /delivery/mine for new jobs and keeps pinging
/// location while online.
class RiderProvider extends ChangeNotifier {
  final RiderService _service = RiderService();

  static const _kOnline = 'rider_online';
  static const _pollEvery = Duration(seconds: 6);
  static const _pingEvery = Duration(seconds: 15);

  List<RiderOrder> _deliveries = [];
  final Map<int, RiderBusiness> _businesses = {};
  final Set<int> _loadingBusinesses = {};
  final Set<int> _knownIds = {};
  bool _online = false;
  bool _toggling = false;
  bool _loaded = false;
  bool _initStarted = false;
  String? _error;
  Position? _lastPosition;
  Timer? _pollTimer;
  Timer? _pingTimer;
  bool _polling = false;

  /// Called when new jobs appear after the first load (show a snackbar etc).
  void Function(int count)? onNewAssignments;

  List<RiderOrder> get deliveries => _deliveries;
  bool get isOnline => _online;
  bool get isToggling => _toggling;
  bool get hasLoaded => _loaded;
  String? get error => _error;
  Position? get lastPosition => _lastPosition;
  RiderBusiness? businessOf(int id) => _businesses[id];

  // ---------------------------------------------------------------- lifecycle

  Future<void> init() async {
    if (_initStarted) return;
    _initStarted = true;

    final prefs = await SharedPreferences.getInstance();
    _online = prefs.getBool(_kOnline) ?? false;

    await refresh();

    // A rider with active jobs is by definition online (server marks them busy).
    if (_deliveries.isNotEmpty) _online = true;

    if (_online && _deliveries.isEmpty) {
      // Re-announce availability + location (server state may be stale).
      try {
        final pos = await LocationHelper.current();
        _lastPosition = pos;
        await _service.goOnline();
        await _service.ping(pos.latitude, pos.longitude);
      } catch (e) {
        _online = false;
        _error = e.toString();
      }
    }

    await _persistOnline();
    if (_online) _startTimers();
    _notify();
  }

  /// Stop everything and forget state (call on logout).
  Future<void> reset() async {
    _stopTimers();
    _deliveries = [];
    _businesses.clear();
    _loadingBusinesses.clear();
    _knownIds.clear();
    _online = false;
    _toggling = false;
    _loaded = false;
    _initStarted = false;
    _error = null;
    _lastPosition = null;
    onNewAssignments = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnline);
    _notify();
  }

  // ----------------------------------------------------------------- online

  Future<void> toggleOnline() async {
    if (_toggling) return;
    _toggling = true;
    _error = null;
    _notify();
    try {
      if (_online) {
        if (_deliveries.isNotEmpty) {
          throw ApiException('Finish your active deliveries before going offline.');
        }
        await _service.goOffline();
        _online = false;
        _stopTimers();
      } else {
        final pos = await LocationHelper.current();
        await _service.goOnline();
        await _service.ping(pos.latitude, pos.longitude);
        _lastPosition = pos;
        _online = true;
        _startTimers();
      }
      await _persistOnline();
    } catch (e) {
      _error = e.toString();
    }
    _toggling = false;
    _notify();
    if (_online) refresh();
  }

  /// Best-effort: mark offline on logout if there is nothing in progress.
  Future<bool> goOfflineIfIdle() async {
    if (_deliveries.isNotEmpty) return false;
    if (_online) {
      try {
        await _service.goOffline();
      } catch (_) {}
    }
    return true;
  }

  Future<void> _persistOnline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnline, _online);
  }

  // ----------------------------------------------------------------- polling

  Future<void> refresh() async {
    if (_polling) return;
    _polling = true;
    try {
      final list = await _service.myDeliveries();
      final wasBusy = _deliveries.isNotEmpty;
      final fresh = _loaded ? list.where((o) => !_knownIds.contains(o.id)).toList() : <RiderOrder>[];

      _deliveries = list;
      _knownIds
        ..clear()
        ..addAll(list.map((o) => o.id));
      _loaded = true;
      _error = null;

      // Jobs appeared while the app thought we were offline (e.g. reinstall).
      if (list.isNotEmpty && !_online) {
        _online = true;
        _persistOnline();
        _startTimers();
      }

      // Job finished or was cancelled. The backend frees the rider on
      // "delivered" but NOT when an order is cancelled, so re-announce
      // availability to avoid being stuck as "busy".
      if (wasBusy && list.isEmpty && _online) {
        _service.goOnline().catchError((_) {});
      }

      if (fresh.isNotEmpty) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
        onNewAssignments?.call(fresh.length);
      }
      _prefetchBusinesses(list);
    } catch (e) {
      _error = e.toString();
    } finally {
      _polling = false;
      _notify();
    }
  }

  void _prefetchBusinesses(List<RiderOrder> orders) {
    for (final o in orders) {
      final id = o.businessId;
      if (id == 0 || _businesses.containsKey(id) || _loadingBusinesses.contains(id)) continue;
      _loadingBusinesses.add(id);
      _service.getBusiness(id).then((b) {
        _businesses[id] = b;
        _notify();
      }).catchError((_) {}).whenComplete(() => _loadingBusinesses.remove(id));
    }
  }

  /// Lets detail screens seed the cache after loading a business themselves.
  void cacheBusiness(RiderBusiness b) {
    _businesses[b.id] = b;
    _notify();
  }

  // -------------------------------------------------------------------- GPS

  void _startTimers() {
    _pollTimer?.cancel();
    _pingTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) => refresh());
    _pingTimer = Timer.periodic(_pingEvery, (_) => _pingTick());
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _pingTimer?.cancel();
    _pollTimer = null;
    _pingTimer = null;
  }

  Future<void> _pingTick() async {
    try {
      final pos = await LocationHelper.current();
      _lastPosition = pos;
      final active = _deliveries;
      if (active.isEmpty) {
        await _service.ping(pos.latitude, pos.longitude);
      } else {
        // One ping per active order so each customer sees live movement.
        for (final o in active) {
          await _service.ping(pos.latitude, pos.longitude, orderId: o.id);
        }
      }
      _notify();
    } catch (_) {
      // Transient GPS / network failure — try again next tick.
    }
  }

  // ------------------------------------------------------------------ misc

  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    super.dispose();
  }

  /// Convenience for UI: order still needs rider attention (go to restaurant
  /// or deliver to customer). Matches backend active delivery statuses.
  static bool isActive(OrderStatus s) =>
      s == OrderStatus.accepted || s == OrderStatus.cooking || s == OrderStatus.onTheWay;
}
