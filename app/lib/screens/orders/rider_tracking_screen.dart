import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../models/order.dart';
import '../../services/business_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// Live "Track Rider" screen opened from an order in history/tracking.
///
/// There's no REST endpoint for a customer to poll the rider's current
/// position (the rider only POSTs pings — see RiderService.ping), so this
/// listens on Socket.io instead, matching the room/event names already
/// documented in OrderTrackingScreen: room `order:<id>`, event
/// `rider:location`. If your backend's `src/utils/socket.ts` uses a
/// different join call or payload shape, that's the one place to change
/// (see `_connectSocket` below) — order status still polls every few
/// seconds regardless, so the screen keeps working even if the socket
/// never connects.
class RiderTrackingScreen extends StatefulWidget {
  final int orderId;
  const RiderTrackingScreen({super.key, required this.orderId});

  @override
  State<RiderTrackingScreen> createState() => _RiderTrackingScreenState();
}

class _RiderTrackingScreenState extends State<RiderTrackingScreen> {
  final _orderService = OrderService();
  final _businessService = BusinessService();
  final _mapController = fm.MapController();
  socket_io.Socket? _socket;
  Timer? _statusTimer;

  FoodOrder? _order;
  ll.LatLng? _businessLatLng;
  ll.LatLng? _riderLatLng;
  DateTime? _lastPing;
  bool _loading = true;
  String? _error;

  static const List<OrderStatus> _finished = [OrderStatus.delivered, OrderStatus.cancelled];

  @override
  void initState() {
    super.initState();
    _load();
    _statusTimer = Timer.periodic(const Duration(seconds: 8), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await _orderService.getOne(widget.orderId);
      ll.LatLng? biz;
      try {
        final business = await _businessService.getOne(order.businessId);
        if (business.latitude != null && business.longitude != null) {
          biz = ll.LatLng(business.latitude!, business.longitude!);
        }
      } catch (_) {
        // Non-fatal — the map just won't have a starting center from this.
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _businessLatLng = biz;
        _loading = false;
      });
      _connectSocket();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    if (_finished.contains(_order?.status)) return;
    try {
      final order = await _orderService.getOne(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
      if (_finished.contains(order.status)) {
        _statusTimer?.cancel();
        _socket?.dispose();
        _socket = null;
      }
    } catch (_) {
      // Transient network hiccup — next tick will retry.
    }
  }

  void _connectSocket() {
    final o = _order;
    if (o == null || _finished.contains(o.status)) return;
    final socket = socket_io.io(
      ApiConfig.socketUrl,
      socket_io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    _socket = socket;
    socket
      ..onConnect((_) => socket.emit('join', 'order:${widget.orderId}'))
      ..on('rider:location', (data) {
        if (!mounted || data is! Map) return;
        final lat = _num(data['lat'] ?? data['latitude']);
        final lng = _num(data['lng'] ?? data['longitude']);
        if (lat == null || lng == null) return;
        setState(() {
          _riderLatLng = ll.LatLng(lat, lng);
          _lastPing = DateTime.now();
        });
      })
      ..on('order:status', (_) => _refreshStatus())
      ..connect();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track your rider')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null || _order == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error ?? 'Order not found', style: const TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : _buildBody(_order!),
    );
  }

  Widget _buildBody(FoodOrder o) {
    if (!o.hasRiderAssigned) {
      return _NoRiderState(order: o);
    }

    final drop = (o.deliveryLat != null && o.deliveryLng != null) ? ll.LatLng(o.deliveryLat!, o.deliveryLng!) : null;
    final center = _riderLatLng ?? drop ?? _businessLatLng ?? const ll.LatLng(28.6139, 80.6199); // Dhangadhi fallback

    return Column(
      children: [
        Expanded(
          child: fm.FlutterMap(
            mapController: _mapController,
            options: fm.MapOptions(initialCenter: center, initialZoom: _riderLatLng == null ? 13 : 15),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.bhansa', // your applicationId
                maxNativeZoom: 20,
              ),
              fm.RichAttributionWidget(
                attributions: [
                  fm.TextSourceAttribution('OpenStreetMap contributors'),
                  fm.TextSourceAttribution('CARTO'),
                ],
              ),
              fm.MarkerLayer(markers: [
                if (_businessLatLng != null)
                  fm.Marker(
                    point: _businessLatLng!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.storefront, color: AppColors.gold, size: 32),
                  ),
                if (drop != null)
                  fm.Marker(
                    point: drop,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.success, size: 34),
                  ),
                if (_riderLatLng != null)
                  fm.Marker(
                    point: _riderLatLng!,
                    width: 44,
                    height: 44,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.gold,
                      child: Icon(Icons.two_wheeler, color: AppColors.black),
                    ),
                  ),
              ]),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Order #${o.orderNumber} • ${orderStatusLabel(o.status)}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.surfaceAlt,
                      child: Icon(Icons.two_wheeler, color: AppColors.gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.riderName?.isNotEmpty == true ? o.riderName! : 'Your rider',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            _riderLatLng == null
                                ? 'Waiting for live location…'
                                : 'Updated ${_secondsAgo(_lastPing)}s ago',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    if ((o.riderPhone ?? '').isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.call, color: AppColors.success),
                        onPressed: () => _call(o.riderPhone!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _secondsAgo(DateTime? t) {
    if (t == null) return 0;
    return DateTime.now().difference(t).inSeconds;
  }
}

class _NoRiderState extends StatelessWidget {
  final FoodOrder order;
  const _NoRiderState({required this.order});

  @override
  Widget build(BuildContext context) {
    final delivered = order.status == OrderStatus.delivered;
    final cancelled = order.status == OrderStatus.cancelled;
    final String title;
    final String subtitle;
    final IconData icon;
    if (delivered) {
      title = 'This order was delivered';
      subtitle = 'Tracking ends once an order is delivered.';
      icon = Icons.check_circle_outline;
    } else if (cancelled) {
      title = 'This order was cancelled';
      subtitle = 'There is no rider to track.';
      icon = Icons.cancel_outlined;
    } else {
      title = 'No rider assigned yet';
      subtitle = 'Once a rider picks up your order, you can track them live here.';
      icon = Icons.two_wheeler_outlined;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.gold.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
