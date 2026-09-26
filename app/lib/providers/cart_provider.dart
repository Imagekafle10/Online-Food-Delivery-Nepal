import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/menu_item.dart';
import '../models/address.dart';
import '../utils/distance_util.dart';

/// The backend places one order against a single `business_id`, so the cart
/// can only ever hold items from one business at a time. Adding from a
/// different business requires the caller to confirm clearing the cart first
/// (see CartScreen / BusinessDetailScreen for the confirmation flow).
class CartProvider extends ChangeNotifier {
  Business? _business;
  final List<CartLine> _lines = [];
  UserAddress? _deliveryAddress;

  Business? get business => _business;
  List<CartLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.fold(0, (s, l) => s + l.quantity);
  UserAddress? get deliveryAddress => _deliveryAddress;

  /// Called by CheckoutScreen whenever the user picks/changes a delivery
  /// address, so the delivery fee can be recalculated by distance.
  void setDeliveryAddress(UserAddress? address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  double get subtotal => _lines.fold(0, (s, l) => s + l.lineTotal);

  /// Distance in km between the business and the selected delivery address,
  /// or null if either location is unknown.
  double? get deliveryDistanceKm {
    final biz = _business;
    final addr = _deliveryAddress;
    if (biz?.latitude == null ||
        biz?.longitude == null ||
        addr?.latitude == null ||
        addr?.longitude == null) {
      return null;
    }
    return distanceKm(biz!.latitude!, biz.longitude!, addr!.latitude!, addr.longitude!);
  }

  /// Rs. 50 within 3km, Rs. 150 for 3-8km, Rs. 250 for 8-12km, Rs. 350 beyond.
  /// Falls back to the business's flat base_delivery_fee if either location
  /// (business or selected address) is missing lat/lng.
  double get deliveryFee {
    if (isEmpty) return 0;
    final km = deliveryDistanceKm;
    if (km == null) return _business?.baseDeliveryFee ?? 0;
    return deliveryFeeForDistance(km);
  }

  static const double _taxRate = 0.13; // matches backend's 13% tax note in README
  double get tax => subtotal * _taxRate;
  double get total => subtotal + deliveryFee + tax;

  bool belongsToDifferentBusiness(Business other) =>
      _business != null && _business!.id != other.id;

  void addItem(Business business, MenuItem item, {int quantity = 1, List<MenuAddon> addons = const [], String? notes}) {
    _business = business;
    final existingIndex = _lines.indexWhere((l) =>
        l.item.id == item.id && _sameAddons(l.selectedAddons, addons) && l.notes == notes);
    if (existingIndex != -1) {
      _lines[existingIndex].quantity += quantity;
    } else {
      _lines.add(CartLine(item: item, business: business, quantity: quantity, selectedAddons: addons, notes: notes));
    }
    notifyListeners();
  }

  void updateQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      _lines.remove(line);
    } else {
      line.quantity = quantity;
    }
    if (_lines.isEmpty) _business = null;
    notifyListeners();
  }

  void removeLine(CartLine line) {
    _lines.remove(line);
    if (_lines.isEmpty) _business = null;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _business = null;
    notifyListeners();
  }

  bool _sameAddons(List<MenuAddon> a, List<MenuAddon> b) {
    if (a.length != b.length) return false;
    final namesA = a.map((e) => e.name).toList()..sort();
    final namesB = b.map((e) => e.name).toList()..sort();
    for (var i = 0; i < namesA.length; i++) {
      if (namesA[i] != namesB[i]) return false;
    }
    return true;
  }
}
