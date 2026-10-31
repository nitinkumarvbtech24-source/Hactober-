class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String? address;
  final String? lat;
  final String? lng;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    this.address,
    this.lat,
    this.lng,
    this.avatarUrl,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final emailVal = json['email'] as String? ?? '';
    final nameVal = json['name'] as String? ?? (emailVal.isNotEmpty ? emailVal.split('@').first : 'User');
    final usernameVal = json['username'] as String? ?? (nameVal.isNotEmpty ? nameVal.toLowerCase().replaceAll(' ', '_') : 'user');

    return UserModel(
      id: json['id'] as String? ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: nameVal,
      username: usernameVal,
      email: emailVal,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String?,
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'address': address,
        'lat': lat,
        'lng': lng,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'createdAt': createdAt.toIso8601String(),
      };
}
