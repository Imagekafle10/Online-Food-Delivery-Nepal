import '../config/api_config.dart';
import '../models/rider_order.dart';
import 'api_client.dart';

/// Wraps the rider endpoints in src/routes/delivery.routes.ts.
class RiderService {
  final ApiClient _api = ApiClient.instance;

  /// Marks the rider `available`. NOTE: the backend only auto-assigns riders
  /// that also have a location, so always [ping] right after this.
  Future<void> goOnline() async {
    await _api.post(ApiConfig.deliveryOnline);
  }

  Future<void> goOffline() async {
    await _api.post(ApiConfig.deliveryOffline);
  }

  /// POST /delivery/ping. When [orderId] is set the backend also broadcasts
  /// `rider:location` to the customer's tracking room.
  Future<void> ping(double lat, double lng, {int? orderId}) async {
    await _api.post(ApiConfig.deliveryPing, body: {
      'lat': lat,
      'lng': lng,
      if (orderId != null) 'orderId': orderId,
    });
  }

  /// GET /delivery/mine — active delivery orders assigned to this rider
  /// (accepted / cooking / on_the_way).
  Future<List<RiderOrder>> myDeliveries() async {
    final data = await _api.get(ApiConfig.deliveryMine);
    return (data as List)
        .map((e) => RiderOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /orders/:id returns `{ order, items, statusLog }`.
  Future<RiderOrder> getOrder(int id) async {
    final data = await _api.get(ApiConfig.order(id));
    return RiderOrder.fromJson(
      Map<String, dynamic>.from(data['order'] as Map),
      items: data['items'] as List<dynamic>?,
    );
  }

  /// GET /businesses/:id (public) — gives pickup name, address and lat/lng.
  Future<RiderBusiness> getBusiness(int id) async {
    final data = await _api.get(ApiConfig.business(id));
    return RiderBusiness.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> markPickedUp(int orderId) async {
    await _api.post(ApiConfig.deliveryPickedUp(orderId));
  }

  Future<void> markOnTheWay(int orderId) async {
    await _api.post(ApiConfig.deliveryOnTheWay(orderId));
  }

  Future<void> markDelivered(int orderId) async {
    await _api.post(ApiConfig.deliveryDelivered(orderId));
  }
}
