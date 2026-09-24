import 'order.dart';

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// Reads the first non-empty scalar value among [keys], looking at the top
/// level first and then inside common nested objects (customer, user, ...).
String? _s(Map<String, dynamic> j, List<String> keys) {
  String? read(Map m) {
    for (final k in keys) {
      final v = m[k];
      if (v == null || v is Map || v is List) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty && t != 'null') return t;
    }
    return null;
  }

  final top = read(j);
  if (top != null) return top;
  for (final n in const ['customer', 'user', 'address', 'delivery_address', 'delivery']) {
    final v = j[n];
    if (v is Map) {
      final r = read(v);
      if (r != null) return r;
    }
  }
  return null;
}

String? _customerName(Map<String, dynamic> j) {
  final direct = _s(j, ['customer_name', 'recipient_name', 'contact_name', 'full_name']);
  if (direct != null) return direct;
  final first = _s(j, ['customer_first_name', 'first_name']);
  final last = _s(j, ['customer_last_name', 'last_name']);
  final both = [first, last].where((e) => e != null && e.isNotEmpty).join(' ');
  return both.isEmpty ? null : both;
}

String? _dropAddress(Map<String, dynamic> j) {
  final line = _s(j, [
    'delivery_address',
    'delivery_address_line',
    'address_line',
    'delivery_address_text',
    'full_address',
  ]);
  final city = _s(j, ['delivery_city', 'city']);
  final parts = [line, city].where((e) => e != null && e.isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join(', ');
}

/// Restaurant / hotel the rider collects the food from.
/// Parsed from GET /api/businesses/:id.
class RiderBusiness {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final double? latitude;
  final double? longitude;

  RiderBusiness({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
    this.latitude,
    this.longitude,
  });

  factory RiderBusiness.fromJson(Map<String, dynamic> j) => RiderBusiness(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? 'Restaurant',
        address: j['address']?.toString(),
        city: j['city']?.toString(),
        phone: j['phone']?.toString(),
        latitude: _d(j['latitude']),
        longitude: _d(j['longitude']),
      );

  String get fullAddress =>
      [address, city].where((e) => e != null && e.isNotEmpty).join(', ');
}

/// A delivery job. Built from the raw `orders` row returned by
/// GET /api/delivery/mine, optionally enriched with items from
/// GET /api/orders/:id.
class RiderOrder {
  final int id;
  final String orderNumber;
  final int businessId;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String paymentMethod; // esewa | khalti | cod
  final String paymentStatus;
  final double? dropLat;
  final double? dropLng;
  final String? deliveryInstructions;
  final String? specialInstructions;
  final String? customerName;
  final String? customerPhone;
  final String? dropAddress;
  final List<OrderItemLine> items;

  RiderOrder({
    required this.id,
    required this.orderNumber,
    required this.businessId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.dropLat,
    this.dropLng,
    this.deliveryInstructions,
    this.specialInstructions,
    this.customerName,
    this.customerPhone,
    this.dropAddress,
    this.items = const [],
  });

  /// Cash the rider must collect from the customer.
  bool get isCashToCollect => paymentMethod == 'cod' && paymentStatus != 'paid';

  factory RiderOrder.fromJson(Map<String, dynamic> j, {List<dynamic>? items}) =>
      RiderOrder(
        id: (j['id'] as num).toInt(),
        orderNumber: j['order_number']?.toString() ?? '#${j['id']}',
        businessId: (j['business_id'] as num?)?.toInt() ?? 0,
        status: orderStatusFromString(j['status']?.toString() ?? 'placed'),
        subtotal: _d(j['subtotal']) ?? 0,
        deliveryFee: _d(j['delivery_fee']) ?? 0,
        totalAmount: _d(j['total_amount']) ?? 0,
        paymentMethod: j['payment_method']?.toString() ?? 'cod',
        paymentStatus: j['payment_status']?.toString() ?? 'unpaid',
        dropLat: _d(j['delivery_latitude']),
        dropLng: _d(j['delivery_longitude']),
        deliveryInstructions: j['delivery_instructions']?.toString(),
        specialInstructions: j['special_instructions']?.toString(),
        customerName: _customerName(j),
        customerPhone: _s(j, [
          'customer_phone',
          'delivery_phone',
          'contact_phone',
          'recipient_phone',
          'phone',
          'phone_number',
          'mobile',
        ]),
        dropAddress: _dropAddress(j),
        items: (items ?? const [])
            .map((e) => OrderItemLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

String riderStatusLabel(OrderStatus s) {
  switch (s) {
    case OrderStatus.accepted:
    case OrderStatus.cooking:
      return 'Go to restaurant';
    case OrderStatus.onTheWay:
      return 'On the way to customer';
    case OrderStatus.delivered:
      return 'Delivered';
    default:
      return orderStatusLabel(s);
  }
}
