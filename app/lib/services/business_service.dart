import '../config/api_config.dart';
import '../models/business.dart';
import '../models/menu_item.dart';
import 'api_client.dart';

class BusinessService {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/businesses?type=&city=&search= — public, no auth needed.
  Future<List<Business>> list({String? type, String? city, String? search}) async {
    final data = await _api.get(ApiConfig.businesses, query: {
      if (type != null) 'type': type,
      if (city != null) 'city': city,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (data as List).map((e) => Business.fromJson(e)).toList();
  }

  Future<Business> getOne(int id) async {
    final data = await _api.get(ApiConfig.business(id));
    return Business.fromJson(data);
  }

  /// GET /api/menu/:businessId — returns categories grouped with items.
  Future<List<MenuCategory>> getMenu(int businessId) async {
    final data = await _api.get(ApiConfig.menu(businessId));
    return (data as List).map((e) => MenuCategory.fromJson(e)).toList();
  }

  Future<List<MenuItem>> searchMenu(String query) async {
    final data = await _api.get(ApiConfig.menuSearch, query: {'q': query});
    return (data as List).map((e) => MenuItem.fromJson(e)).toList();
  }
}
