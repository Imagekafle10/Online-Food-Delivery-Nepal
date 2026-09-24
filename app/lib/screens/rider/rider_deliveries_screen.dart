import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/rider_order.dart';
import '../../providers/rider_provider.dart';
import '../../theme/app_theme.dart';
import 'rider_order_screen.dart';

class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
  late final RiderProvider _rider;

  @override
  void initState() {
    super.initState();
    _rider = context.read<RiderProvider>();
    _rider.onNewAssignments = (count) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(count == 1 ? 'New delivery assigned to you!' : '$count new deliveries assigned!'),
      ));
    };
  }

  @override
  void dispose() {
    _rider.onNewAssignments = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rider = context.watch<RiderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Deliveries')),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: rider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _StatusCard(rider: rider),
            if (rider.error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: rider.error!),
            ],
            const SizedBox(height: 20),
            Text(
              rider.deliveries.isEmpty ? 'No active deliveries' : 'Active deliveries (${rider.deliveries.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (!rider.hasLoaded)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
              )
            else if (rider.deliveries.isEmpty)
              _EmptyState(online: rider.isOnline)
            else
              ...rider.deliveries.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DeliveryCard(order: o, business: rider.businessOf(o.businessId)),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final RiderProvider rider;
  const _StatusCard({required this.rider});

  @override
  Widget build(BuildContext context) {
    final online = rider.isOnline;
    final busy = rider.deliveries.isNotEmpty;
    final title = busy ? 'On a delivery' : (online ? "You're online" : "You're offline");
    final sub = busy
        ? 'Location is shared with your customers'
        : (online ? 'Waiting for the next order near you' : 'Go online to start receiving orders');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (online ? AppColors.success : AppColors.textMuted).withValues(alpha: 0.18),
              ),
              child: Icon(Icons.two_wheeler, color: online ? AppColors.success : AppColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
            if (rider.isToggling)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
              )
            else
              Switch(
                value: online,
                activeColor: AppColors.gold,
                onChanged: (_) => rider.toggleOnline(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool online;
  const _EmptyState({required this.online});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(online ? Icons.radar : Icons.bedtime_outlined, size: 56, color: AppColors.gold.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          Text(
            online ? 'Looking for orders…' : 'You are offline',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            online
                ? 'New deliveries are assigned automatically\nonce the kitchen accepts an order.'
                : 'Turn on the switch above to get orders.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final RiderOrder order;
  final RiderBusiness? business;
  const _DeliveryCard({required this.order, this.business});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RiderOrderScreen(orderId: order.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('#${order.orderNumber}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  StatusPill(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.storefront, size: 18, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(business?.name ?? 'Restaurant #${order.businessId}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if ((business?.fullAddress ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(business!.fullAddress,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.isCashToCollect ? 'COLLECT CASH' : 'PAID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: order.isCashToCollect ? AppColors.goldLight : AppColors.success,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final OrderStatus status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == OrderStatus.onTheWay
        ? AppColors.success
        : (status == OrderStatus.cooking ? AppColors.goldLight : AppColors.gold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(riderStatusLabel(status),
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
