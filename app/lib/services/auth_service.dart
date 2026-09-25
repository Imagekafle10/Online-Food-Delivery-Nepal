import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final AppUser user;
  AuthResult(this.user);
}

class AuthService {
  final ApiClient _api = ApiClient.instance;
  static const _kUser = 'cachedUser';
  // Old "remember this device" keys from a removed feature — cleared once
  // on the next login/logout so nobody's device keeps a stray saved
  // password sitting in SharedPreferences.
  static const _kLegacySavedAccounts = 'saved_login_accounts';
  static const _kLegacyIdentifier = 'saved_login_identifier';
  static const _kLegacyPassword = 'saved_login_password';
  static const _kLegacyRemember = 'saved_login_remember';

  /// Backend requires email OR phone (src/services/auth.service.ts).
  /// `role` may be `customer` or `rider` (the backend also allows
  /// `business_owner`). Riders get a row in the `riders` table automatically.
  Future<AuthResult> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    String role = 'customer',
  }) async {
    final data = await _api.post(ApiConfig.register, body: {
      'full_name': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'role': role,
    });
    return _finish(data);
  }

  /// `identifier` can be email or phone (src/controllers/auth.controller.ts).
  Future<AuthResult> login({required String identifier, required String password}) async {
    final data = await _api.post(ApiConfig.login, body: {
      'identifier': identifier,
      'password': password,
    });
    return _finish(data);
  }

  Future<AuthResult> _finish(dynamic data) async {
    await _api.saveTokens(accessToken: data['accessToken'], refreshToken: data['refreshToken']);
    final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    await _cacheUser(user);
    await _clearLegacySavedLogins();
    return AuthResult(user);
  }

  /// GET /auth/me returns only the JWT payload (id, uuid, role, email).
  Future<AppUser> fetchMe() async {
    final data = await _api.get(ApiConfig.me);
    final user = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    await _cacheUser(user);
    return user;
  }

  Future<AppUser?> cachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    await _api.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
    await _clearLegacySavedLogins();
  }

  /// Removes the old "saved logins" / "remember this account" data
  /// (identifiers + plaintext passwords) that a previous version of this
  /// screen stored in SharedPreferences. Safe to call even if it was never
  /// set.
  Future<void> _clearLegacySavedLogins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLegacySavedAccounts);
    await prefs.remove(_kLegacyIdentifier);
    await prefs.remove(_kLegacyPassword);
    await prefs.remove(_kLegacyRemember);
  }
}
