import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Jalankan login manual memakai email dan password.
  Future<void> _handleLogin(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    await auth.login(email, password);
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
                      const SizedBox(height: 20),
                      ClayButton(
                        label: auth.isLoading ? 'Memproses...' : 'Login',
                        onPressed: auth.isLoading
                            ? null
                            : () => _handleLogin(auth),
                        fullWidth: true,
                      ),
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
