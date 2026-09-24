import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/api_config.dart';
import '../../services/address_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gold_button.dart';
import 'pick_location_screen.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController(text: 'Home');
  final _lineCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _isDefault = true;
  bool _saving = false;
  double? _latitude;
  double? _longitude;

  final _service = AddressService();

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          apiKey: ApiConfig.mapsApiKey,
          initialPosition: (_latitude != null && _longitude != null)
              ? LatLng(_latitude!, _longitude!)
              : const LatLng(28.0500, 81.6167),
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      if (result.formattedAddress != null &&
          result.formattedAddress!.isNotEmpty) {
        _lineCtrl.text = result.formattedAddress!;
      }
    });
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _lineCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.add(
        label: _labelCtrl.text.trim(),
        addressLine: _lineCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isDefault: _isDefault,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save address')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Label (Home, Work...)',
                    prefixIcon:
                        Icon(Icons.label_outline, color: AppColors.gold)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickOnMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(_latitude == null
                    ? 'Set location on map'
                    : 'Location set — tap to change'),
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _lineCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Full address',
                    prefixIcon:
                        Icon(Icons.map_outlined, color: AppColors.gold)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined,
                        color: AppColors.gold)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.gold,
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 20),
              GoldButton(
                  label: 'SAVE ADDRESS', onPressed: _save, loading: _saving),
            ],
          ),
        ),
      ),
    );
  }
}
