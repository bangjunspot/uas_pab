import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/attendance_service.dart';
import '../models/attendance_record.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  bool isLoading = false;
  String? error;
  List<AttendanceRecord> records = [];

  AttendanceRecord? get latest => records.isEmpty ? null : records.first;
  String get nextType => latest?.type == 'masuk' ? 'pulang' : 'masuk';

  Future<void> loadRecent(String userId) async {
    _setLoading(true);
    error = null;
    try {
      records = await _service.fetchRecent(userId: userId);
    } catch (e) {
      error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submit({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    required XFile photo,
    required double? distanceKm,
  }) async {
    _setLoading(true);
    error = null;
    try {
      final photoUrl = await _service.uploadAttendancePhoto(
        userId: userId,
        photo: photo,
      );
      final record = await _service.createRecord(
        userId: userId,
        type: type,
        lat: lat,
        lng: lng,
        photoUrl: photoUrl,
        biometricVerified: true,
        distanceKm: distanceKm,
      );
      records = [record, ...records];
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
