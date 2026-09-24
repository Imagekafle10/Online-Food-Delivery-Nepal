import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'addresses_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

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
                  (user?.fullName.isNotEmpty == true ? user!.fullName[0] : '?').toUpperCase(),
                  style: const TextStyle(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? user?.phone ?? '', style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _tile(context, Icons.location_on_outlined, 'Delivery addresses',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressesScreen()))),
          _tile(context, Icons.notifications_outlined, 'Notifications', onTap: () {}),
          _tile(context, Icons.help_outline, 'Help & support', onTap: () {}),
          _tile(context, Icons.info_outline, 'About', onTap: () {}),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.logout,
            'Log out',
            danger: true,
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, {required VoidCallback onTap, bool danger = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: danger ? AppColors.danger : AppColors.gold),
        title: Text(title, style: TextStyle(color: danger ? AppColors.danger : AppColors.textPrimary, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ),
    );
  }
}
