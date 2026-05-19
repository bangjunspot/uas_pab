import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../theme/clay_colors.dart';
import '../../widgets/clay_background.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';

class BiometricGate extends StatefulWidget {
  final Widget child;

  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _supportsBiometric = true;
  bool _isCheckingSupport = true;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  /// Cek apakah perangkat mendukung biometrik.
  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!mounted) return;
      setState(() {
        _supportsBiometric = canCheck && supported;
        _isCheckingSupport = false;
      });
    } catch (e) {
      debugPrint('Biometric support error: $e');
      if (!mounted) return;
      setState(() {
        _supportsBiometric = false;
        _isCheckingSupport = false;
      });
    }
  }

  /// Jalankan autentikasi sidik jari untuk membuka dashboard.
  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);
    try {
      final result = await _auth.authenticate(
        localizedReason:
            'Verifikasi sidik jari untuk membuka laporan keuangan BANGJUN SPOT',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;
      if (result) {
        setState(() => _isAuthenticated = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verifikasi gagal. Coba lagi.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric error: $e');
      if (!mounted) return;
      setState(() => _isAuthenticated = true);
    } catch (e) {
      debugPrint('Biometric auth fallback: $e');
      if (!mounted) return;
      setState(() => _isAuthenticated = true);
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSupport || !_supportsBiometric || _isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: ClayBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ClayCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 1.0, end: 1.08),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: ClayColors.primary.withAlpha(24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 72,
                        color: ClayColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verifikasi Identitas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sentuh sensor sidik jari untuk membuka Laporan Keuangan',
                    style: TextStyle(color: ClayColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ClayButton(
                    label: _isAuthenticating
                        ? 'Memverifikasi...'
                        : 'Verifikasi Sekarang',
                    onPressed: _isAuthenticating ? null : _authenticate,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _isAuthenticated = true),
                    child: const Text('Gunakan Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
