import 'package:flutter_test/flutter_test.dart';
import 'package:bhansa/models/order.dart';
import 'package:bhansa/models/rider_order.dart';

void main() {
  test('RiderOrder parses a raw delivery row from /delivery/mine', () {
    final o = RiderOrder.fromJson({
      'id': 7,
      'order_number': 'ORD123',
      'business_id': 2,
      'status': 'rider_assigned',
      'subtotal': '500.00',
      'delivery_fee': '50.00',
      'total_amount': '565.00',
      'payment_method': 'cod',
      'payment_status': 'pending',
      'delivery_latitude': '28.0500000',
      'delivery_longitude': '81.6167000',
    });
    expect(o.status, OrderStatus.riderAssigned);
    expect(o.totalAmount, 565.0);
    expect(o.isCashToCollect, isTrue);
    expect(o.dropLat, closeTo(28.05, 1e-6));
  });

  test('paid orders need no cash collection', () {
    final o = RiderOrder.fromJson({
      'id': 8,
      'status': 'picked_up',
      'payment_method': 'esewa',
      'payment_status': 'paid',
    });
    expect(o.isCashToCollect, isFalse);
  });
}
