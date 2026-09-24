import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _service = OrderService();
  List<FoodOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _service.myOrders();
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Center(child: Text('No orders yet', style: TextStyle(fontWeight: FontWeight.w700))),
                      SizedBox(height: 6),
                      Center(child: Text('Your food orders will show up here.', style: TextStyle(color: AppColors.textMuted))),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      final isActive = ![
                        OrderStatus.delivered,
                        OrderStatus.cancelled,
                      ].contains(o.status);
                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id)),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: isActive ? AppColors.gold : AppColors.surfaceAlt,
                            child: Icon(Icons.receipt_long, color: isActive ? AppColors.black : AppColors.gold, size: 20),
                          ),
                          title: Text('Order #${o.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Rs. ${o.totalAmount.toStringAsFixed(0)} • ${orderStatusLabel(o.status)}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
