import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_client.dart';
import '../../services/business_service.dart';
import '../../services/location_helper.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance_util.dart';
import '../../widgets/menu_item_tile.dart';
import '../cart/cart_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final int businessId;
  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  final _service = BusinessService();

  Business? _business;
  List<MenuCategory> _menu = [];
  bool _loading = true;
  String? _error;

  // Current GPS fix, used to quote the real distance-based delivery fee here
  // (same tiers as CartProvider.deliveryFee). Best-effort - if unavailable we
  // fall back to the business's flat base fee, same as the checkout flow does.
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _load();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await LocationHelper.current();
      if (mounted) setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
    } catch (_) {
      // Silently keep showing the flat fee if location isn't available.
    }
  }

  /// Rs. amount for the info chip: distance-based from the user's current
  /// location when we have both points, otherwise the business's flat fee.
  double _deliveryFeeFor(Business b) {
    if (_userLat == null || _userLng == null || b.latitude == null || b.longitude == null) {
      return b.baseDeliveryFee;
    }
    final km = distanceKm(_userLat!, _userLng!, b.latitude!, b.longitude!);
    return deliveryFeeForDistance(km);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getOne(widget.businessId),
        _service.getMenu(widget.businessId),
      ]);
      setState(() {
        _business = results[0] as Business;
        _menu = (results[1] as List<MenuCategory>).where((c) => c.items.isNotEmpty).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not load this menu right now.';
        _loading = false;
      });
    }
  }

  void _handleAdd(MenuItem item) {
    final cart = context.read<CartProvider>();
    if (cart.belongsToDifferentBusiness(_business!)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Start a new cart?'),
          content: Text('Your cart has items from ${cart.business?.name}. Adding from ${_business!.name} will clear it.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                cart.clear();
                cart.addItem(_business!, item);
                Navigator.pop(ctx);
                _showAddedSnack(item);
              },
              child: const Text('Clear & add'),
            ),
          ],
        ),
      );
      return;
    }
    cart.addItem(_business!, item);
    _showAddedSnack(item);
  }

  void _showAddedSnack(MenuItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.gold,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    if (_error != null || _business == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Not found', style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final b = _business!;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: b.coverImageUrl != null
                  ? CachedNetworkImage(imageUrl: b.coverImageUrl!, fit: BoxFit.cover)
                  : Container(color: AppColors.surfaceAlt, child: const Icon(Icons.storefront, size: 60, color: AppColors.gold)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  if (b.description != null && b.description!.isNotEmpty)
                    Text(b.description!, style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.timer_outlined, '${b.avgPrepTimeMins} min'),
                      _infoChip(Icons.delivery_dining, 'Rs. ${_deliveryFeeFor(b).toStringAsFixed(0)} delivery'),
                      if (b.minOrderAmount > 0) _infoChip(Icons.shopping_bag_outlined, 'Min Rs. ${b.minOrderAmount.toStringAsFixed(0)}'),
                      _infoChip(b.isOpen ? Icons.check_circle : Icons.cancel, b.isOpen ? 'Open now' : 'Closed'),
                    ],
                  ),
                  const Divider(height: 32),
                ],
              ),
            ),
          ),
          if (_menu.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Menu coming soon.', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ..._menu.map((category) => SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: Text(category.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gold)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: category.items.length,
                        itemBuilder: (context, i) {
                          final item = category.items[i];
                          final line = cart.lines.where((l) => l.item.id == item.id && l.selectedAddons.isEmpty).toList();
                          final qty = line.isEmpty ? 0 : line.first.quantity;
                          return MenuItemTile(
                            item: item,
                            quantityInCart: qty,
                            onAdd: () => _handleAdd(item),
                            onIncrement: () => cart.addItem(b, item),
                            onDecrement: line.isEmpty ? null : () => cart.updateQuantity(line.first, line.first.quantity - 1),
                          );
                        },
                      ),
                    ),
                  ],
                )),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      bottomNavigationBar: cart.isEmpty || cart.business?.id != b.id
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''} • Rs. ${cart.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w800)),
                          const Text('VIEW CART', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
