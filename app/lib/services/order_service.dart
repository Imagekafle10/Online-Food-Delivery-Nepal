import '../config/api_config.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _api = ApiClient.instance;

  /// POST /api/orders — body shape from src/services/order.service.ts#placeOrder.
  /// Pricing (subtotal/tax/delivery fee/total) is always computed server-side.
  ///
  /// Backend responds with `{ order, items }` (see order.service.ts#placeOrder),
  /// not a flat order object — so we unwrap it before handing it to
  /// FoodOrder.fromJson, which expects `items` nested inside the order map.
  Future<FoodOrder> placeOrder({
    required int businessId,
    required String orderType, // delivery | pickup | dine_in
    required List<Map<String, dynamic>> items,
    required String paymentMethod, // esewa | khalti | cod
    int? deliveryAddressId,
    String? specialInstructions,
  }) async {
    final data = await _api.post(ApiConfig.orders, body: {
      'business_id': businessId,
      'order_type': orderType,
      'items': items,
      'payment_method': paymentMethod,
      if (deliveryAddressId != null) 'delivery_address_id': deliveryAddressId,
      if (specialInstructions != null && specialInstructions.isNotEmpty)
        'special_instructions': specialInstructions,
    });
    final orderJson = Map<String, dynamic>.from(data['order'] as Map);
    orderJson['items'] = data['items'];
    return FoodOrder.fromJson(orderJson);
  }

  /// GET /api/orders/my — order.model.ts#listByUser returns flat order rows
  /// (no items join), so no unwrapping needed here. `items` will just come
  /// back empty on each entry, which is fine for a list screen.
  Future<List<FoodOrder>> myOrders({int limit = 20, int offset = 0}) async {
    final data = await _api
        .get(ApiConfig.myOrders, query: {'limit': limit, 'offset': offset});
    return (data as List).map((e) => FoodOrder.fromJson(e)).toList();
  }

  /// GET /api/orders/:id — order.service.ts#getFullOrder responds with
  /// `{ order, items, statusLog }`, same nested shape as placeOrder. Unwrap
  /// the same way. statusLog isn't used by FoodOrder yet.
  Future<FoodOrder> getOne(int id) async {
    final data = await _api.get(ApiConfig.order(id));
    final orderJson = Map<String, dynamic>.from(data['order'] as Map);
    orderJson['items'] = data['items'];
    return FoodOrder.fromJson(orderJson);
  }

  Future<void> cancel(int id, {String reason = 'Cancelled by user'}) async {
    await _api.post(ApiConfig.orderCancel(id), body: {'reason': reason});
  }
}
