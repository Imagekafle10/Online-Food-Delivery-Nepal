import 'package:flutter/material.dart';
import '../../models/business.dart';
import '../../services/api_client.dart';
import '../../services/business_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/business_card.dart';
import '../business/business_detail_screen.dart';

/// Food-delivery-first discovery feed. Only businesses with
/// `has_food_ordering = true` are shown (table/room booking are out of
/// scope for this app), matching the "focus on online food delivery" brief.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _service = BusinessService();
  final _searchCtrl = TextEditingController();

  List<Business> _all = [];
  bool _loading = true;
  String? _error;
  String? _typeFilter; // restaurant | cafe | hotel | guest_house | null (all)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.list(type: _typeFilter, search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
      setState(() {
        _all = list.where((b) => b.hasFoodOrdering && b.status == 'approved').toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load restaurants. Pull to refresh.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hungry?'),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Search restaurants or cuisines',
                        prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                        suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, color: AppColors.gold), onPressed: _load),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('All', null),
                          _filterChip('Restaurants', 'restaurant'),
                          _filterChip('Cafes', 'cafe'),
                          _filterChip('Hotels', 'hotel'),
                          _filterChip('Guest houses', 'guest_house'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: AppColors.textMuted, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              )
            else if (_all.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No restaurants found nearby yet.', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: _all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final b = _all[i];
                    return BusinessCard(
                      business: b,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: b.id)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _typeFilter = value);
          _load();
        },
      ),
    );
  }
}
