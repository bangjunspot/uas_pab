import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../../models/attendance_record.dart';

class AttendanceService {
  static const String bucketName = 'attendance-photos';

  final _supabase = SupabaseService();

  SupabaseClient get _client => _supabase.client;

  Future<String?> uploadAttendancePhoto({
    required String userId,
    required XFile photo,
  }) async {
    final bytes = await photo.readAsBytes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = photo.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$userId/$timestamp-$safeName';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return _client.storage.from(bucketName).getPublicUrl(path);
  }

  Future<AttendanceRecord> createRecord({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    required String? photoUrl,
    required bool biometricVerified,
    required double? distanceKm,
  }) async {
    final data = await _client
        .from('attendance_records')
        .insert({
          'user_id': userId,
          'type': type,
          'lat': lat,
          'lng': lng,
          'photo_url': photoUrl,
          'biometric_verified': biometricVerified,
          'distance_km': distanceKm,
        })
        .select()
        .single();

    return AttendanceRecord.fromMap(data);
  }

  Future<List<AttendanceRecord>> fetchRecent({required String userId}) async {
    final data = await _client
        .from('attendance_records')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return (data as List)
        .map((item) => AttendanceRecord.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
