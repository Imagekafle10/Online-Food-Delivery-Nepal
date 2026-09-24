import 'business.dart';

class MenuAddon {
  final String name;
  final double price;
  MenuAddon({required this.name, required this.price});

  factory MenuAddon.fromJson(Map<String, dynamic> json) => MenuAddon(
        name: json['name']?.toString() ?? '',
        price: _asDouble(json['price']) ?? 0,
      );

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
}

class MenuItem {
  final int id;
  final int businessId;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? discountPercent;
  final String? imageUrl;
  final bool isVeg;
  final bool isAvailable;
  final int prepTimeMins;
  final List<MenuAddon> addons;

  MenuItem({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.discountPercent,
    this.imageUrl,
    required this.isVeg,
    required this.isAvailable,
    required this.prepTimeMins,
    this.addons = const [],
  });

  /// Price after applying discountPercent (5–90), rounded to 2 decimals.
  double get effectivePrice => hasDiscount
      ? double.parse((price * (1 - discountPercent! / 100)).toStringAsFixed(2))
      : price;

  bool get hasDiscount => discountPercent != null && discountPercent! > 0;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as int,
        businessId: (json['business_id'] as num?)?.toInt() ?? 0,
        categoryId: (json['category_id'] as num?)?.toInt(),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        price: _asDouble(json['price']) ?? 0,
        discountPercent: _asDouble(json['discount_percent']),
        imageUrl: json['image_url']?.toString(),
        isVeg: _asBool(json['is_veg'], true),
        isAvailable: _asBool(json['is_available'], true),
        prepTimeMins: (json['prep_time_mins'] as num?)?.toInt() ?? 15,
        addons: (json['addons'] as List<dynamic>? ?? [])
            .map((a) => MenuAddon.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

class MenuCategory {
  final int? id;
  final String name;
  final List<MenuItem> items;

  MenuCategory({this.id, required this.name, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        id: (json['id'] as num?)?.toInt(),
        name: json['name']?.toString() ?? 'Menu',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((i) => MenuItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

/// One line in the cart: a menu item + quantity + chosen addons, tied to
/// the business it came from (backend only allows single-business orders).
class CartLine {
  final MenuItem item;
  final Business business;
  int quantity;
  final List<MenuAddon> selectedAddons;
  String? notes;

  CartLine({
    required this.item,
    required this.business,
    this.quantity = 1,
    this.selectedAddons = const [],
    this.notes,
  });

  double get addonsTotal => selectedAddons.fold(0, (s, a) => s + a.price);
  double get lineTotal => (item.effectivePrice + addonsTotal) * quantity;

  Map<String, dynamic> toOrderPayload() => {
        'menu_item_id': item.id,
        'quantity': quantity,
        if (selectedAddons.isNotEmpty)
          'addons': selectedAddons.map((a) => a.toJson()).toList(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
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
