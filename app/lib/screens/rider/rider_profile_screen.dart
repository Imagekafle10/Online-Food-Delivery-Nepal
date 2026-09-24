import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final rider = context.read<RiderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!await rider.goOfflineIfIdle()) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Finish your active deliveries before logging out.')));
      return;
    }
    await rider.reset();
    await auth.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final rider = context.watch<RiderProvider>();
    final name = user?.displayName ?? 'Rider';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceAlt,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? user?.phone ?? '', style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('RIDER',
                          style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              leading: Icon(Icons.circle, size: 14, color: rider.isOnline ? AppColors.success : AppColors.textMuted),
              title: Text(rider.isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                rider.isOnline ? 'Sharing location while the app is open' : 'Not receiving orders',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.gold),
              title: const Text('Keep the app open',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                'Your location is only shared while Bhansa is in the foreground.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              onTap: () => _logout(context),
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Log out',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
