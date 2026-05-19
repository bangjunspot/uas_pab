import 'package:geolocator/geolocator.dart';
import '../services/supabase_service.dart';

enum TravelMode { walking, motorcycle, car }

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
    final updated = await _supabase.client
        .from('profiles')
        .update({'store_lat': lat, 'store_lng': lng})
        .eq('id', userId)
        .select('id')
        .maybeSingle();

    // RLS bisa membuat update "diam-diam gagal" (0 row terpengaruh tanpa error).
    if (updated == null) {
      throw Exception(
        'Lokasi tidak tersimpan. Pastikan akun punya izin update profil.',
      );
    }
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

    return {'lat': lat, 'lng': lng};
  }

  /// Hitung jarak (KM) dari posisi user ke kedai.
  double calculateDistanceKm({
    required double userLat,
    required double userLng,
    required double storeLat,
    required double storeLng,
  }) {
    final meters = Geolocator.distanceBetween(
      userLat,
      userLng,
      storeLat,
      storeLng,
    );
    return meters / 1000;
  }

  /// Estimasi menit tempuh berdasarkan mode perjalanan.
  int estimateTravelMinutes({
    required double distanceKm,
    TravelMode mode = TravelMode.motorcycle,
  }) {
    if (distanceKm <= 0) return 0;

    // Kecepatan rata-rata perkiraan dalam kota.
    final speedKmPerHour = switch (mode) {
      TravelMode.walking => 5.0,
      TravelMode.motorcycle => 30.0,
      TravelMode.car => 25.0,
    };

    final minutes = (distanceKm / speedKmPerHour) * 60;
    return minutes.ceil();
  }

  /// Label ringkas ETA, contoh: "12 menit".
  String formatEta(int minutes) {
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return '$hours jam';
    return '$hours jam $rem menit';
  }
}
