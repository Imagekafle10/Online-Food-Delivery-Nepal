import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart' show AuthService;
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _initializing = true;
  String? _error;
  bool _loading = false;

  AppUser? get user => _user;
  bool get isInitializing => _initializing;

  /// Signed in = we hold a token AND know who the user is (so we can pick
  /// the customer or rider experience from `user.role`).
  bool get isAuthenticated => ApiClient.instance.isAuthenticated && _user != null;
  bool get isRider => _user?.role == 'rider';
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> bootstrap() async {
    await ApiClient.instance.loadTokens();
    if (ApiClient.instance.isAuthenticated) {
      try {
        _user = await _authService.cachedUser() ?? await _authService.fetchMe();
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          await _authService.logout();
        }
      } catch (_) {}
    }
    if (isAuthenticated) NotificationService.instance.registerDevice();
    _initializing = false;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    final ok = await _run(() async {
      final result = await _authService.login(identifier: identifier, password: password);
      _user = result.user;
    });
    if (ok) NotificationService.instance.registerDevice();
    return ok;
  }

  Future<bool> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    String role = 'customer',
  }) async {
    final ok = await _run(() async {
      final result = await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      _user = result.user;
    });
    if (ok) NotificationService.instance.registerDevice();
    return ok;
  }

  Future<void> logout() async {
    await NotificationService.instance.unregisterDevice();
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
