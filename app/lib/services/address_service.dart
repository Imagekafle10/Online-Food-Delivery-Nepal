import '../config/api_config.dart';
import '../models/address.dart';
import 'api_client.dart';

class AddressService {
  final ApiClient _api = ApiClient.instance;

  Future<List<UserAddress>> list() async {
    final data = await _api.get(ApiConfig.addresses);
    return (data as List).map((e) => UserAddress.fromJson(e)).toList();
  }

  Future<int> add({
    required String label,
    required String addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final data = await _api.post(ApiConfig.addresses, body: {
      'label': label,
      'address_line': addressLine,
      if (city != null) 'city': city,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default': isDefault,
    });
    return data['id'] as int;
  }

  Future<void> remove(int id) => _api.delete(ApiConfig.address(id));
}
