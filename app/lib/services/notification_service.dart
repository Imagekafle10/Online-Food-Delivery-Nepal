import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/api_config.dart';
import '../screens/orders/order_tracking_screen.dart';
import '../screens/rider/rider_order_screen.dart';
import 'api_client.dart';

/// Must be top-level. Runs when a push arrives while the app is in the
/// background / killed. Messages carry a `notification` block, so Android/iOS
/// show them automatically - we only need Firebase to be initialised.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push + local notification handling.
///
/// - `init()`            call once from main() (after Firebase.initializeApp)
/// - `registerDevice()`  call after login (sends the FCM token to the backend)
/// - `unregisterDevice()` call before logout
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Used to open screens when a notification is tapped.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _token;

  // Channel ids must match the `channel` values the backend sends.
  static const _channels = <AndroidNotificationChannel>[
    AndroidNotificationChannel('order_updates', 'Order updates',
        description: 'Status updates for your orders', importance: Importance.high),
    AndroidNotificationChannel('rider_alerts', 'Delivery alerts',
        description: 'New deliveries assigned to you', importance: Importance.max),
    AndroidNotificationChannel('business_orders', 'Incoming orders',
        description: 'New orders for your restaurant', importance: Importance.max),
  ];

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      final fcm = FirebaseMessaging.instance;

      // Android 13+ and iOS ask for permission at runtime.
      await fcm.requestPermission(alert: true, badge: true, sound: true);
      // iOS: show banners even when the app is open.
      await fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (resp) {
          final payload = resp.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            _openFromData(Map<String, dynamic>.from(jsonDecode(payload) as Map));
          } catch (_) {}
        },
      );

      final androidPlugin =
          _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      for (final c in _channels) {
        await androidPlugin?.createNotificationChannel(c);
      }

      // App open: Android does NOT draw FCM notifications in the foreground,
      // so we show them ourselves.
      FirebaseMessaging.onMessage.listen(_showForeground);

      // App was in background and the user tapped the notification.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _openFromData(m.data));

      // App was killed and the user tapped the notification.
      final initial = await fcm.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openFromData(initial.data));
      }

      // Token rotated by Firebase -> tell the backend (only if signed in).
      fcm.onTokenRefresh.listen((t) {
        _token = t;
        _send(t);
      });

      _ready = true;
    } catch (e) {
      debugPrint('[push] init failed: $e');
    }
  }

  /// Send this phone's FCM token to the backend for the signed-in user.
  Future<void> registerDevice() async {
    if (kIsWeb) return;
    if (!_ready) await init();
    try {
      _token = await FirebaseMessaging.instance.getToken();
      if (_token != null) await _send(_token!);
    } catch (e) {
      debugPrint('[push] token registration failed: $e');
    }
  }

  /// Stop pushes for the signed-in user on this phone. Call BEFORE clearing auth tokens.
  Future<void> unregisterDevice() async {
    if (kIsWeb) return;
    try {
      final t = _token ?? await FirebaseMessaging.instance.getToken();
      if (t != null && ApiClient.instance.isAuthenticated) {
        await ApiClient.instance.post(ApiConfig.devicesRemove, body: {'token': t});
      }
      await FirebaseMessaging.instance.deleteToken(); // next login gets a fresh token
      _token = null;
    } catch (e) {
      debugPrint('[push] unregister failed: $e');
    }
  }

  Future<void> _send(String token) async {
    if (!ApiClient.instance.isAuthenticated) return;
    try {
      await ApiClient.instance.post(ApiConfig.devices, body: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('[push] backend register failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage m) async {
    final title = m.notification?.title ?? m.data['title'];
    final body = m.notification?.body ?? m.data['body'];
    if (title == null && body == null) return;

    final channelId = m.data['channel'] ?? 'order_updates';
    final channel = _channels.firstWhere((c) => c.id == channelId, orElse: () => _channels.first);

    await _local.show(
      m.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(m.data),
    );
  }

  /// Notification tapped -> open the right screen.
  void _openFromData(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    final orderId = int.tryParse('${data['orderId'] ?? ''}');
    if (nav == null || orderId == null) return;

    switch (data['type']) {
      case 'order_status':
        nav.push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
        break;
      case 'delivery_assigned':
        nav.push(MaterialPageRoute(builder: (_) => RiderOrderScreen(orderId: orderId)));
        break;
      default:
        break; // business alerts have no screen in this app
    }
  }
}
