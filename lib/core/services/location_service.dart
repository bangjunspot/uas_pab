import 'package:geolocator/geolocator.dart';
import '../services/supabase_service.dart';

class LocationService {
  final _supabase = SupabaseService();

  /// Cek apakah lokasi perangkat aktif dan siap digunakan.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Pastikan izin lokasi aman untuk dipakai aplikasi.
  Future<LocationPermission?> ensurePermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return permission;
  }

  /// Ambil posisi terbaru jika layanan dan izin lokasi sudah siap.
  Future<Position?> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    final permission = await ensurePermission();
    if (permission == null || permission == LocationPermission.denied) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Buka pengaturan aplikasi saat izin lokasi dikunci permanen.
  Future<void> openAppSettingsPage() async {
    await Geolocator.openAppSettings();
  }

  /// Simpan koordinat kedai ke tabel profiles di Supabase.
  Future<void> saveStoreLocation({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    await _supabase.client.from('profiles').update({
      'store_lat': lat,
      'store_lng': lng,
    }).eq('id', userId);
  }

  /// Ambil koordinat kedai yang tersimpan untuk user tertentu.
  Future<Map<String, double>?> fetchStoreLocation(String userId) async {
    final data = await _supabase.client
        .from('profiles')
        .select('store_lat, store_lng')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;

    final lat = (data['store_lat'] as num?)?.toDouble();
    final lng = (data['store_lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return {
      'lat': lat,
      'lng': lng,
    };
  }
}
