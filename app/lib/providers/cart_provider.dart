import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/menu_item.dart';

/// The backend places one order against a single `business_id`, so the cart
/// can only ever hold items from one business at a time. Adding from a
/// different business requires the caller to confirm clearing the cart first
/// (see CartScreen / BusinessDetailScreen for the confirmation flow).
class CartProvider extends ChangeNotifier {
  Business? _business;
  final List<CartLine> _lines = [];

  Business? get business => _business;
  List<CartLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.fold(0, (s, l) => s + l.quantity);

  double get subtotal => _lines.fold(0, (s, l) => s + l.lineTotal);
  double get deliveryFee => isEmpty ? 0 : (_business?.baseDeliveryFee ?? 0);
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
