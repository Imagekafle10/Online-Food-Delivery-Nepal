import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rider_provider.dart';
import '../../theme/app_theme.dart';
import 'rider_deliveries_screen.dart' show StatusPill;

/// Deliveries this rider has completed. Since the backend has no
/// delivery-history endpoint, entries are recorded on-device the moment a
/// job is marked delivered (see RiderProvider.addToHistory) and persisted
/// in SharedPreferences, so they survive app restarts.
class RiderHistoryScreen extends StatelessWidget {
  const RiderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rider = context.watch<RiderProvider>();
    final entries = rider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery history'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(context, rider),
            ),
        ],
      ),
      body: entries.isEmpty
          ? const _EmptyHistory()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final entry = entries[i];
                final o = entry.order;
                final business = rider.businessOf(o.businessId);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('#${o.orderNumber}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                            StatusPill(status: o.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.storefront, size: 18, color: AppColors.gold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(business?.name ?? 'Restaurant #${o.businessId}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        if ((o.customerName ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 26),
                            child: Text('to ${o.customerName}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Rs. ${o.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
                            const Spacer(),
                            Text(_formatWhen(entry.finishedAt),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, RiderProvider rider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes your delivery history from this device. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) await rider.clearHistory();
  }

  static String _formatWhen(DateTime t) {
    final now = DateTime.now();
    final sameDay = now.year == t.year && now.month == t.month && now.day == t.day;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    if (sameDay) return 'Today $hh:$mm';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} $hh:$mm';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.gold.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            const Text('No completed deliveries yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Orders you deliver will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
