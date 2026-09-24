import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Thin wrapper around the backend's `ApiSuccess<T> / ApiError` envelope
/// (see src/utils/response.util.ts + src/types/index.ts).
///
/// If a request comes back 401 and we hold a refresh token, the client
/// transparently calls POST /auth/refresh once and retries the request.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _accessToken;
  String? _refreshToken;

  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';
  static const _timeout = Duration(seconds: 20);

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kAccess);
    _refreshToken = prefs.getString(_kRefresh);
  }

  bool get isAuthenticated => _accessToken != null;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, accessToken);
    await prefs.setString(_kRefresh, refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = query?.map((k, v) => MapEntry(k, v?.toString()))
      ?..removeWhere((k, v) => v == null);
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: (cleanQuery == null || cleanQuery.isEmpty) ? null : cleanQuery,
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _request('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _request('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool allowRefresh = true,
  }) async {
    final uri = _uri(path, query);
    http.Response res;
    try {
      switch (method) {
        case 'POST':
          res = await http
              .post(uri, headers: _headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
          break;
        case 'PATCH':
          res = await http
              .patch(uri, headers: _headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: _headers).timeout(_timeout);
          break;
        default:
          res = await http.get(uri, headers: _headers).timeout(_timeout);
      }
    } on TimeoutException {
      throw ApiException('The server took too long to respond');
    } catch (_) {
      throw ApiException('Cannot reach the server. Check your connection.');
    }

    final isAuthCall = path == ApiConfig.login ||
        path == ApiConfig.register ||
        path == ApiConfig.refresh;
    if (res.statusCode == 401 && allowRefresh && !isAuthCall && _refreshToken != null) {
      if (await _refresh()) {
        return _request(method, path, query: query, body: body, allowRefresh: false);
      }
    }
    return _handle(res);
  }

  Future<bool> _refresh() async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refresh}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(_timeout);
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;
        await saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  dynamic _handle(http.Response res) {
    Map<String, dynamic> decoded;
    try {
      decoded = res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${res.statusCode})', statusCode: res.statusCode);
    }

    if (res.statusCode >= 200 && res.statusCode < 300 && decoded['success'] == true) {
      return decoded['data'];
    }

    final message = decoded['message']?.toString() ?? 'Something went wrong';
    throw ApiException(message, statusCode: res.statusCode);
  }
}
