class Profile {
  final String id;
  final String email;
  final String role;
  final double? storeLat;
  final double? storeLng;

  Profile({
    required this.id,
    required this.email,
    required this.role,
    this.storeLat,
    this.storeLng,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'].toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'kasir').toString(),
      storeLat: (map['store_lat'] as num?)?.toDouble(),
      storeLng: (map['store_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'store_lat': storeLat,
      'store_lng': storeLng,
    };
  }
}
