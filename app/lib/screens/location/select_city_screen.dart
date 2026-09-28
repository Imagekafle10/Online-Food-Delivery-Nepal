import 'package:flutter/material.dart';
import '../../services/city_store.dart';
import '../../theme/app_theme.dart';

class SelectCityScreen extends StatefulWidget {
  /// Called after a city is saved (first-launch flow).
  final void Function(String city)? onSelected;
  /// true when opened from Discover to change city (pops with the result).
  final bool canGoBack;
  const SelectCityScreen({super.key, this.onSelected, this.canGoBack = false});

  @override
  State<SelectCityScreen> createState() => _SelectCityScreenState();
}

class _SelectCityScreenState extends State<SelectCityScreen> {
  static const _cities = [
    'Kathmandu', 'Butwal', 'Pokhara', 'Lalitpur', 'Bhaktapur',
    'Chitwan', 'Biratnagar', 'Dhangadhi', 'Nepalgunj', 'Janakpur',
  ];
  final _ctrl = TextEditingController();

  Future<void> _pick(String city) async {
    city = city.trim();
    if (city.isEmpty) return;
    await CityStore.set(city);
    if (!mounted) return;
    if (widget.canGoBack) {
      Navigator.of(context).pop(city);
    } else {
      widget.onSelected?.call(city);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _ctrl.text.trim().toLowerCase();
    final list = _cities.where((c) => c.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: widget.canGoBack ? AppBar(title: const Text('Change location')) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!widget.canGoBack) ...[
              const SizedBox(height: 24),
              const Icon(Icons.location_on, color: AppColors.gold, size: 40),
              const SizedBox(height: 12),
              const Text('Where do you want food delivered?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Pick your city to see restaurants near you.', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 20),
            ],
            TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              onSubmitted: _pick,
              decoration: const InputDecoration(
                hintText: 'Search or type your city',
                prefixIcon: Icon(Icons.search, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(children: [
                for (final c in list)
                  Card(
                    color: AppColors.surface,
                    child: ListTile(
                      leading: const Icon(Icons.location_city, color: AppColors.gold),
                      title: Text(c, style: const TextStyle(color: AppColors.textPrimary)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      onTap: () => _pick(c),
                    ),
                  ),
                if (q.isNotEmpty && !_cities.any((c) => c.toLowerCase() == q))
                  Card(
                    color: AppColors.surface,
                    child: ListTile(
                      leading: const Icon(Icons.add_location_alt, color: AppColors.gold),
                      title: Text('Use "${_ctrl.text.trim()}"', style: const TextStyle(color: AppColors.textPrimary)),
                      onTap: () => _pick(_ctrl.text),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
