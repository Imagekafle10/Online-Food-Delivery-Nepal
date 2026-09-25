class Business {
  final int id;
  final String name;
  final String slug;
  final String type; // hotel | restaurant | cafe | guest_house
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? city;
  final String? address;
  final bool hasFoodOrdering;
  final bool hasTableBooking;
  final bool hasRoomBooking;
  final double baseDeliveryFee;
  final double minOrderAmount;
  final int avgPrepTimeMins;
  final bool isOpen;
  final String status;
  final double? latitude;
  final double? longitude;

  Business({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.city,
    this.address,
    required this.hasFoodOrdering,
    required this.hasTableBooking,
    required this.hasRoomBooking,
    required this.baseDeliveryFee,
    required this.minOrderAmount,
    required this.avgPrepTimeMins,
    required this.isOpen,
    required this.status,
    this.latitude,
    this.longitude,
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        type: json['type']?.toString() ?? 'restaurant',
        description: json['description']?.toString(),
        logoUrl: json['logo_url']?.toString(),
        coverImageUrl: json['cover_image_url']?.toString(),
        city: json['city']?.toString(),
        address: json['address']?.toString(),
        hasFoodOrdering: _asBool(json['has_food_ordering'], true),
        hasTableBooking: _asBool(json['has_table_booking'], false),
        hasRoomBooking: _asBool(json['has_room_booking'], false),
        baseDeliveryFee: _asDouble(json['base_delivery_fee']) ?? 50,
        minOrderAmount: _asDouble(json['min_order_amount']) ?? 0,
        avgPrepTimeMins: (json['avg_prep_time_mins'] as num?)?.toInt() ?? 20,
        isOpen: _asBool(json['is_open'], true),
        status: json['status']?.toString() ?? 'approved',
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
      );
}

bool _asBool(dynamic v, bool fallback) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  return fallback;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
