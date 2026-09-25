/// Mirrors the OrderStatus enum in the backend (src/types/index.ts) exactly.
///
/// Backend lifecycle:
///   placed → accepted → cooking → on_the_way → delivered
///   (and cancelled if there is a problem)
enum OrderStatus {
  placed,
  accepted,
  cooking,
  onTheWay,
  delivered,
  cancelled,
}

OrderStatus orderStatusFromString(String s) {
  switch (s) {
    case 'placed':
      return OrderStatus.placed;
    case 'accepted':
      return OrderStatus.accepted;
    case 'cooking':
    // Legacy aliases from older backends
    case 'preparing':
    case 'ready':
      return OrderStatus.cooking;
    case 'on_the_way':
    // Legacy aliases
    case 'rider_assigned':
    case 'picked_up':
      return OrderStatus.onTheWay;
    case 'delivered':
    case 'completed':
      return OrderStatus.delivered;
    case 'cancelled':
    case 'rejected':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.placed;
  }
}

/// Inverse of [orderStatusFromString] — the canonical backend string for a
/// status, used when caching orders locally (e.g. rider delivery history).
String orderStatusToApiString(OrderStatus s) {
  switch (s) {
    case OrderStatus.placed:
      return 'placed';
    case OrderStatus.accepted:
      return 'accepted';
    case OrderStatus.cooking:
      return 'cooking';
    case OrderStatus.onTheWay:
      return 'on_the_way';
    case OrderStatus.delivered:
      return 'delivered';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

String orderStatusLabel(OrderStatus s) {
  switch (s) {
    case OrderStatus.placed:
      return 'Order placed';
    case OrderStatus.accepted:
      return 'Accepted by kitchen';
    case OrderStatus.cooking:
      return 'Cooking';
    case OrderStatus.onTheWay:
      return 'On the way';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

/// Simplified 4-stage customer-facing timeline for the tracking screen.
/// Several granular backend statuses collapse into each stage — see
/// [simplifiedStageIndex].
const List<String> orderStageLabels = [
  'Order placed',
  'Cooking',
  'On the way',
  'Delivered',
];

/// Maps a granular backend [OrderStatus] onto one of the 4 simplified
/// stages above. Returns -1 for cancelled, which the stepper renders separately.
int simplifiedStageIndex(OrderStatus status) {
  switch (status) {
    case OrderStatus.placed:
      return 0;
    case OrderStatus.accepted:
    case OrderStatus.cooking:
      return 1; // Cooking
    case OrderStatus.onTheWay:
      return 2; // On the way
    case OrderStatus.delivered:
      return 3; // Delivered
    case OrderStatus.cancelled:
      return -1;
  }
}

class OrderItemLine {
  final int menuItemId;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final double itemSubtotal;

  OrderItemLine({
    required this.menuItemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.itemSubtotal,
  });

  factory OrderItemLine.fromJson(Map<String, dynamic> json) => OrderItemLine(
        menuItemId: (json['menu_item_id'] as num?)?.toInt() ?? 0,
        itemName: json['item_name']?.toString() ?? '',
        unitPrice: _asDouble(json['unit_price']) ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        itemSubtotal: _asDouble(json['item_subtotal']) ?? 0,
      );
}

class FoodOrder {
  final int id;
  final String uuid;
  final String orderNumber;
  final int businessId;
  final String? businessName;
  final String orderType; // delivery | pickup | dine_in
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? placedAt;
  final List<OrderItemLine> items;
  final int? riderId;
  final String? riderName;
  final String? riderPhone;
  final double? deliveryLat;
  final double? deliveryLng;

  FoodOrder({
    required this.id,
    required this.uuid,
    required this.orderNumber,
    required this.businessId,
    this.businessName,
    required this.orderType,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.placedAt,
    this.items = const [],
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.deliveryLat,
    this.deliveryLng,
  });

  /// A rider is only worth showing/tracking once one has actually been
  /// assigned — matches the window `RiderProvider.isActive` covers on the
  /// rider side (accepted / cooking / on_the_way).
  bool get hasRiderAssigned =>
      riderId != null && [OrderStatus.accepted, OrderStatus.cooking, OrderStatus.onTheWay].contains(status);

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>?) ?? [];
    final riderJson = json['rider'] is Map ? Map<String, dynamic>.from(json['rider'] as Map) : null;
    return FoodOrder(
      id: json['id'] as int,
      uuid: json['uuid']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      businessName: json['business_name']?.toString(),
      orderType: json['order_type']?.toString() ?? 'delivery',
      status: orderStatusFromString(json['status']?.toString() ?? 'placed'),
      subtotal: _asDouble(json['subtotal']) ?? 0,
      deliveryFee: _asDouble(json['delivery_fee']) ?? 0,
      taxAmount: _asDouble(json['tax_amount']) ?? 0,
      totalAmount: _asDouble(json['total_amount']) ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      placedAt: DateTime.tryParse(json['placed_at']?.toString() ?? ''),
      items: itemsJson
          .map((i) => OrderItemLine.fromJson(i as Map<String, dynamic>))
          .toList(),
      // Backend may return these flat on the order row (rider_id, rider_name,
      // rider_phone) or nested under a `rider` object depending on the join —
      // this covers either shape without needing a schema change on the app
      // side. If your backend uses different key names, adjust just here.
      riderId: (json['rider_id'] as num?)?.toInt() ?? (riderJson?['id'] as num?)?.toInt(),
      riderName: json['rider_name']?.toString() ?? riderJson?['full_name']?.toString() ?? riderJson?['name']?.toString(),
      riderPhone: json['rider_phone']?.toString() ?? riderJson?['phone']?.toString(),
      deliveryLat: _asDouble(json['delivery_latitude']),
      deliveryLng: _asDouble(json['delivery_longitude']),
    );
  }
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
