import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/emoji_filter.dart';
import '../../core/utils/input_validators.dart';
import '../../widgets/clay_background.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_input.dart';
import '../../providers/auth_provider.dart';
import '../../theme/clay_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricEmailKey = 'biometric_email';
  static const String _biometricPasswordKey = 'biometric_password';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _supportBiometric = false;
  bool _biometricEnabled = false;
  bool _isLoadingBiometric = true;
  bool _isProcessingBiometric = false;
  bool _autoBiometricAttempted = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreferences();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Muat preferensi biometrik dan cek dukungan perangkat.
  Future<void> _loadBiometricPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();

      if (!mounted) return;
      setState(() {
        _biometricEnabled = enabled;
        _supportBiometric = canCheck && supported;
        _isLoadingBiometric = false;
      });
      _tryAutoBiometricLogin();
    } catch (e) {
      debugPrint('Gagal memuat biometrik: $e');
      if (!mounted) return;
      setState(() {
        _biometricEnabled = false;
        _supportBiometric = false;
        _isLoadingBiometric = false;
      });
    }
  }

  /// Simpan status toggle login sidik jari.
  Future<void> _setBiometricEnabled(bool value) async {
    if (!_supportBiometric) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Login sidik jari belum didukung di Web. Gunakan Android/iOS.'
                : 'Perangkat ini tidak mendukung sidik jari.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, value);
    if (!value) {
      await prefs.remove(_biometricEmailKey);
      await prefs.remove(_biometricPasswordKey);
    }
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
  }

  Future<void> _saveBiometricCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_biometricEmailKey, email);
    await prefs.setString(_biometricPasswordKey, password);
  }

  Future<(String, String)?> _loadBiometricCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_biometricEmailKey)?.trim();
    final password = prefs.getString(_biometricPasswordKey);
    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return null;
    }
    return (email, password);
  }

  /// Jalankan login manual memakai email dan password.
  Future<void> _handleLogin(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    await auth.login(email, password);
    if (auth.error == null && _biometricEnabled) {
      await _saveBiometricCredentials(email, password);
    }
    if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Login gagal: ${auth.error}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Jalankan login biometrik cepat.
  Future<void> _handleBiometricLogin(AuthProvider auth) async {
    if (_isProcessingBiometric) return;

    setState(() => _isProcessingBiometric = true);
    try {
      final creds = await _loadBiometricCredentials();
      if (creds == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Belum ada akun tersimpan untuk sidik jari. Login manual sekali dulu.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      final verified = await auth.verifyBiometric();
      if (!verified) {
        if (!mounted) return;
        final message = auth.error ?? 'Verifikasi sidik jari gagal.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      await auth.login(creds.$1, creds.$2);
      final success = auth.error == null;
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verifikasi berhasil. Masuk ke aplikasi...'),
            backgroundColor: ClayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        final message = auth.error ?? 'Gagal login menggunakan akun tersimpan.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal login biometrik: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingBiometric = false);
      }
    }
  }

  void _tryAutoBiometricLogin() {
    if (_autoBiometricAttempted || !_biometricEnabled || !_supportBiometric) {
      return;
    }
    _autoBiometricAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleBiometricLogin(context.read<AuthProvider>());
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: ClayBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ClayCard(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: ClayColors.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'BANGJUN SPOT',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Masuk ke akun Anda',
                        style: TextStyle(
                          fontSize: 13,
                          color: ClayColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClayInput(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [EmojiFilter.denyEmoji],
                        validator: InputValidators.email,
                      ),
                      const SizedBox(height: 12),
                      ClayInput(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: true,
                        showPasswordToggle: true,
                        inputFormatters: [EmojiFilter.denyEmoji],
                        validator: InputValidators.password,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Aktifkan Login Sidik Jari',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Switch(
                            value: _biometricEnabled,
                            onChanged: _isLoadingBiometric
                                ? null
                                : (value) => _setBiometricEnabled(value),
                            activeThumbColor: ClayColors.primary,
                          ),
                        ],
                      ),
                      if (!_isLoadingBiometric && !_supportBiometric)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              kIsWeb
                                  ? 'Sidik jari belum tersedia di Web.'
                                  : 'Sidik jari tidak tersedia di perangkat ini.',
                              style: TextStyle(
                                fontSize: 12,
                                color: ClayColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      if (_isLoadingBiometric)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ClayColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mengecek dukungan biometrik...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ClayColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      ClayButton(
                        label: auth.isLoading ? 'Memproses...' : 'Login',
                        onPressed: auth.isLoading ? null : () => _handleLogin(auth),
                        fullWidth: true,
                      ),
                      if (_biometricEnabled && _supportBiometric) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: ClayColors.textMuted.withAlpha(80)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'atau',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ClayColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: ClayColors.textMuted.withAlpha(80)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessingBiometric
                                ? null
                                : () => _handleBiometricLogin(auth),
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: Text(
                              _isProcessingBiometric
                                  ? 'Memverifikasi...'
                                  : 'Masuk dengan Sidik Jari',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ClayColors.primary,
                              side: const BorderSide(color: ClayColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Belum punya akun? Hubungi admin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: ClayColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
