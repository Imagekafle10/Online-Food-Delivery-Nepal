import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final AppUser user;
  AuthResult(this.user);
}

/// One remembered login on this device — like a browser's saved passwords,
/// there can be several (e.g. a rider's own account plus a friend's, or a
/// customer + rider account tested on the same phone).
class SavedAccount {
  final String identifier;
  final String password;
  final DateTime lastUsedAt;

  SavedAccount({required this.identifier, required this.password, required this.lastUsedAt});

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(
        identifier: j['identifier']?.toString() ?? '',
        password: j['password']?.toString() ?? '',
        lastUsedAt: DateTime.tryParse(j['lastUsedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class AuthService {
  final ApiClient _api = ApiClient.instance;
  static const _kUser = 'cachedUser';
  static const _kSavedAccounts = 'saved_login_accounts';
  // Old single-slot keys from the first version of this feature — read once
  // to migrate, then removed.
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
    // Saved login id/password are intentionally left in place so the next
    // login on this device is pre-filled, exactly like "remember me" on
    // most apps. Call clearSavedCredentials() explicitly if that's not
    // wanted (e.g. a "forget me" / shared-device option in Settings).
  }

  // ------------------------------------------------------------ remember me
  //
  // Saved logins are stored as a JSON list under one SharedPreferences key
  // (list operations need read-modify-write anyway, so one key keeps that
  // atomic-ish and easy to reason about) — one entry per identifier, most
  // recently used first.
  //
  // NOTE: passwords are stored in plain text in SharedPreferences (same
  // mechanism already used for the cached user above). That's fine for a
  // personal phone, but on a shared/rooted device it's readable by anything
  // with access to the app's local storage. If that matters for your riders,
  // swap the prefs calls below for the `flutter_secure_storage` package (OS
  // keychain / keystore) instead — same shape, safer at rest.

  /// All remembered logins on this device, most recently used first.
  Future<List<SavedAccount>> savedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyCredential(prefs);
    final raw = prefs.getStringList(_kSavedAccounts) ?? const [];
    final accounts = raw
        .map((s) {
          try {
            return SavedAccount.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<SavedAccount>()
        .toList();
    accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return accounts;
  }

  /// The most recently used saved account, if any — used to pre-fill the
  /// login form the first time it opens.
  Future<SavedAccount?> mostRecentAccount() async {
    final accounts = await savedAccounts();
    return accounts.isEmpty ? null : accounts.first;
  }

  /// Remembers (or updates) the login for [identifier]. Matching is
  /// case-insensitive so `Rider@x.com` and `rider@x.com` count as the same
  /// account and don't create a duplicate entry.
  Future<void> saveAccount({required String identifier, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await savedAccounts();
    accounts.removeWhere((a) => a.identifier.toLowerCase() == identifier.toLowerCase());
    accounts.insert(0, SavedAccount(identifier: identifier, password: password, lastUsedAt: DateTime.now()));
    await prefs.setStringList(_kSavedAccounts, accounts.map((a) => jsonEncode(a.toJson())).toList());
  }

  /// Removes one saved login (e.g. the user tapped "Forget" on it).
  Future<void> removeSavedAccount(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await savedAccounts();
    accounts.removeWhere((a) => a.identifier.toLowerCase() == identifier.toLowerCase());
    await prefs.setStringList(_kSavedAccounts, accounts.map((a) => jsonEncode(a.toJson())).toList());
  }

  Future<void> clearSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedAccounts);
  }

  /// One-time migration from the old single-slot ("remember me") storage
  /// used by the first version of this feature, so nobody loses their saved
  /// login when this update lands.
  Future<void> _migrateLegacyCredential(SharedPreferences prefs) async {
    final identifier = prefs.getString(_kLegacyIdentifier);
    final password = prefs.getString(_kLegacyPassword);
    if (identifier != null && password != null) {
      final existing = prefs.getStringList(_kSavedAccounts) ?? const [];
      final accounts = existing
          .map((s) {
            try {
              return SavedAccount.fromJson(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<SavedAccount>()
          .toList();
      accounts.removeWhere((a) => a.identifier.toLowerCase() == identifier.toLowerCase());
      accounts.insert(0, SavedAccount(identifier: identifier, password: password, lastUsedAt: DateTime.now()));
      await prefs.setStringList(_kSavedAccounts, accounts.map((a) => jsonEncode(a.toJson())).toList());
    }
    await prefs.remove(_kLegacyIdentifier);
    await prefs.remove(_kLegacyPassword);
    await prefs.remove(_kLegacyRemember);
  }
}
