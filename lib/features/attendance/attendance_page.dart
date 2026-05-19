import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/location_service.dart';
import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/clay_colors.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_fade_slide.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  XFile? _photo;
  double? _lat;
  double? _lng;
  double? _distanceKm;
  bool _locationReady = false;
  bool _biometricReady = false;
  bool _isCapturingPhoto = false;
  bool _isDetectingLocation = false;
  bool _isCheckingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().profile?.id;
      if (userId != null) {
        context.read<AttendanceProvider>().loadRecent(userId);
      }
    });
  }

  Future<void> _capturePhoto() async {
    setState(() => _isCapturingPhoto = true);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 72,
        maxWidth: 1200,
      );
      if (!mounted || photo == null) return;
      setState(() => _photo = photo);
    } catch (e) {
      _showSnackBar('Kamera belum bisa digunakan: $e', success: false);
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
    }
  }

  Future<void> _detectLocation() async {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    setState(() => _isDetectingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      if (position == null) {
        _showSnackBar(
          'Lokasi belum terdeteksi. Aktifkan GPS dan izinkan lokasi.',
          success: false,
        );
        return;
      }

      double? distanceKm;
      if (profile?.storeLat != null && profile?.storeLng != null) {
        distanceKm = _locationService.calculateDistanceKm(
          userLat: position.latitude,
          userLng: position.longitude,
          storeLat: profile!.storeLat!,
          storeLng: profile.storeLng!,
        );
      }

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _distanceKm = distanceKm;
        _locationReady = true;
      });
    } catch (e) {
      _showSnackBar('Gagal mendeteksi lokasi: $e', success: false);
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _verifyBiometric() async {
    setState(() => _isCheckingBiometric = true);
    try {
      final verified = await context.read<AuthProvider>().verifyBiometric(
        reason: 'Verifikasi sidik jari untuk absensi BANGJUN SPOT',
      );
      if (!mounted) return;
      setState(() => _biometricReady = verified);
      if (!verified) {
        _showSnackBar(
          context.read<AuthProvider>().error ?? 'Verifikasi sidik jari gagal.',
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingBiometric = false);
    }
  }

  Future<void> _submitAttendance() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final profile = auth.profile;
    final photo = _photo;

    if (profile == null) {
      _showSnackBar(
        'Profil tidak ditemukan. Silakan login ulang.',
        success: false,
      );
      return;
    }
    if (!_locationReady || _lat == null || _lng == null) {
      _showSnackBar('Deteksi lokasi dulu sebelum absensi.', success: false);
      return;
    }
    if (photo == null) {
      _showSnackBar('Ambil foto kehadiran dulu.', success: false);
      return;
    }
    if (!_biometricReady) {
      _showSnackBar('Verifikasi sidik jari dulu.', success: false);
      return;
    }

    final type = attendance.nextType;
    final success = await attendance.submit(
      userId: profile.id,
      type: type,
      lat: _lat!,
      lng: _lng!,
      photo: photo,
      distanceKm: _distanceKm,
    );
    if (!mounted) return;

    if (success) {
      setState(() {
        _photo = null;
        _lat = null;
        _lng = null;
        _distanceKm = null;
        _locationReady = false;
        _biometricReady = false;
      });
      _showSnackBar('Absensi $type berhasil disimpan.');
    } else {
      _showSnackBar(
        attendance.error ?? 'Absensi gagal disimpan.',
        success: false,
      );
    }
  }

  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? ClayColors.success : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final profile = context.watch<AuthProvider>().profile;
    final nextType = attendance.nextType;
    final canSubmit =
        _locationReady &&
        _photo != null &&
        _biometricReady &&
        !attendance.isLoading;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = profile?.id;
          if (userId != null) {
            await context.read<AttendanceProvider>().loadRecent(userId);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ClayColors.primary.withAlpha(28),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.fact_check_rounded,
                          color: ClayColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Absensi UMKM',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?.email ?? '-',
                              style: TextStyle(
                                color: ClayColors.textMuted,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(label: nextType.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SensorTile(
                    icon: Icons.my_location_rounded,
                    title: 'Geolokasi',
                    subtitle: _locationReady
                        ? _formatLocationSubtitle()
                        : 'Belum dideteksi',
                    ready: _locationReady,
                    loading: _isDetectingLocation,
                    actionLabel: 'Deteksi',
                    onPressed: _detectLocation,
                  ),
                  const SizedBox(height: 10),
                  _SensorTile(
                    icon: Icons.photo_camera_rounded,
                    title: 'Kamera',
                    subtitle: _photo == null ? 'Belum ada foto' : 'Foto siap',
                    ready: _photo != null,
                    loading: _isCapturingPhoto,
                    actionLabel: 'Foto',
                    onPressed: _capturePhoto,
                    trailingPreview: _photo == null
                        ? null
                        : _PhotoPreview(photo: _photo!),
                  ),
                  const SizedBox(height: 10),
                  _SensorTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Sidik Jari',
                    subtitle: _biometricReady
                        ? 'Terverifikasi'
                        : 'Belum diverifikasi',
                    ready: _biometricReady,
                    loading: _isCheckingBiometric,
                    actionLabel: 'Verifikasi',
                    onPressed: _verifyBiometric,
                  ),
                  const SizedBox(height: 18),
                  ClayButton(
                    label: attendance.isLoading
                        ? 'Menyimpan...'
                        : 'Simpan Absensi ${nextType.toUpperCase()}',
                    onPressed: canSubmit ? _submitAttendance : null,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Riwayat Absensi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (attendance.isLoading && attendance.records.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (attendance.records.isEmpty)
              ClayCard(
                child: Center(
                  child: Text(
                    'Belum ada absensi',
                    style: TextStyle(color: ClayColors.textMuted),
                  ),
                ),
              )
            else
              ...attendance.records.asMap().entries.map(
                (entry) => ClayFadeSlide(
                  index: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AttendanceHistoryCard(record: entry.value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatLocationSubtitle() {
    final coordinate =
        '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
    if (_distanceKm == null) return coordinate;
    return '$coordinate - ${_distanceKm!.toStringAsFixed(2)} km dari kedai';
  }
}

class _PhotoPreview extends StatelessWidget {
  final XFile photo;

  const _PhotoPreview({required this.photo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder<Uint8List>(
        future: photo.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              width: 42,
              height: 42,
              color: ClayColors.surfaceAlt,
              child: const SizedBox(
                width: 14,
                height: 14,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return Image.memory(
            snapshot.data!,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool ready;
  final bool loading;
  final String actionLabel;
  final VoidCallback onPressed;
  final Widget? trailingPreview;

  const _SensorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ready,
    required this.loading,
    required this.actionLabel,
    required this.onPressed,
    this.trailingPreview,
  });

  @override
  Widget build(BuildContext context) {
    final color = ready ? ClayColors.success : ClayColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: ClayColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailingPreview != null) ...[
            const SizedBox(width: 8),
            trailingPreview!,
          ],
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: loading ? null : onPressed,
            child: Text(loading ? '...' : actionLabel),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ClayColors.secondary.withAlpha(35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ClayColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy, HH:mm').format(record.createdAt);
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: record.isCheckIn
                  ? ClayColors.success.withAlpha(25)
                  : ClayColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
              color: record.isCheckIn ? ClayColors.success : ClayColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.type.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: ClayColors.textMuted),
                ),
                Text(
                  '${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 12, color: ClayColors.textMuted),
                ),
              ],
            ),
          ),
          if (record.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                record.photoUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_rounded,
                  color: ClayColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
