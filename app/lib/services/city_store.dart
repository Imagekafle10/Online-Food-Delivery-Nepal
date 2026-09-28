import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the city the customer picked on first launch.
class CityStore {
  static const _k = 'selectedCity';
  static Future<String?> get() async => (await SharedPreferences.getInstance()).getString(_k);
  static Future<void> set(String city) async => (await SharedPreferences.getInstance()).setString(_k, city);
}
