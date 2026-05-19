class AttendanceRecord {
  final String id;
  final String userId;
  final String type;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final bool biometricVerified;
  final double? distanceKm;
  final DateTime createdAt;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.biometricVerified,
    this.distanceKm,
    required this.createdAt,
  });

  bool get isCheckIn => type == 'masuk';

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      type: (map['type'] ?? 'masuk').toString(),
      latitude: (map['lat'] as num?)?.toDouble() ?? 0,
      longitude: (map['lng'] as num?)?.toDouble() ?? 0,
      photoUrl: map['photo_url']?.toString(),
      biometricVerified: map['biometric_verified'] == true,
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
