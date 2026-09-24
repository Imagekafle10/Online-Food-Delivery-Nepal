class UserAddress {
  final int id;
  final String label;
  final String addressLine;
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    this.city,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) => UserAddress(
        id: json['id'] as int,
        label: json['label']?.toString() ?? 'Home',
        addressLine: json['address_line']?.toString() ?? '',
        city: json['city']?.toString(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isDefault: json['is_default'] == 1 || json['is_default'] == true,
      );
}
