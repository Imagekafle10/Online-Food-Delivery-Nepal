class AppUser {
  final int id;
  final String uuid;
  final String fullName;
  final String? email;
  final String? phone;
  final String role; // customer | business_owner | staff | rider | super_admin
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.uuid,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        uuid: json['uuid']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        role: json['role']?.toString() ?? 'customer',
        avatarUrl: json['avatar_url']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'avatar_url': avatarUrl,
      };

  bool get isRider => role == 'rider';

  /// Best available display name (the /auth/me payload has no full_name).
  String get displayName =>
      fullName.isNotEmpty ? fullName : (email ?? phone ?? 'Rider');
}
