import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/emoji_filter.dart';
import '../../core/utils/input_validators.dart';
import '../../providers/auth_provider.dart';
import '../../models/profile.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_input.dart';
import '../../widgets/clay_fade_slide.dart';
import '../../theme/clay_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  /// Tampilkan snackbar dengan style konsisten.
  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? ClayColors.success : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Dialog tambah user admin/kasir.
  Future<void> _openAddUserDialog() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'kasir';
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ClayColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: ClayColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Tambah User'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClayInput(
                    controller: emailCtrl,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [EmojiFilter.denyEmoji],
                    validator: InputValidators.email,
                  ),
                  const SizedBox(height: 12),
                  ClayInput(
                    controller: passCtrl,
                    label: 'Password',
                    obscureText: true,
                    showPasswordToggle: true,
                    inputFormatters: [EmojiFilter.denyEmoji],
                    validator: InputValidators.password,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ClayButton(
              label: isLoading ? 'Menyimpan...' : 'Simpan',
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateDialog(() => isLoading = true);
                      final err = await context.read<AuthProvider>().createUser(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                        role: selectedRole,
                      );
                      setStateDialog(() => isLoading = false);
                      if (!ctx.mounted) return;
                      if (err != null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Gagal: $err')),
                              ],
                            ),
                            backgroundColor: Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else {
                        Navigator.pop(ctx, true);
                      }
                    },
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      _showSnackBar('User berhasil ditambahkan');
    }
  }

  /// Dialog edit role user.
  Future<void> _openEditDialog(Profile user) async {
    String selectedRole = user.role;
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ClayColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.manage_accounts_rounded,
                  color: ClayColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Edit User'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 12),
                ClayInput(
                  controller: passCtrl,
                  label: 'Password Baru (opsional)',
                  obscureText: true,
                  showPasswordToggle: true,
                  inputFormatters: [EmojiFilter.denyEmoji],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ClayButton(
              label: 'Simpan',
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await context.read<AuthProvider>().updateRole(
                  user.id,
                  selectedRole,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      _showSnackBar('Data user berhasil diperbarui');
    }
  }

  /// Konfirmasi hapus user.
  Future<void> _confirmDeleteUser(Profile user) async {
    final currentUser = context.read<AuthProvider>().profile;
    if (currentUser?.id == user.id) {
      _showSnackBar('Tidak bisa menghapus akun sendiri', success: false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red.shade400,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Hapus User'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(ctx).style,
            children: [
              const TextSpan(text: 'Hapus akun '),
              TextSpan(
                text: user.email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?\n\nAksi ini tidak bisa dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final err = await context.read<AuthProvider>().deleteUser(user.id);
    if (!mounted) return;

    if (err != null) {
      _showSnackBar('Gagal hapus: $err', success: false);
    } else {
      _showSnackBar('User "${user.email}" berhasil dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.profile?.id;
    final isNarrow = MediaQuery.of(context).size.width < 430;

    if (auth.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (auth.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Gagal memuat user: ${auth.error}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => auth.loadUsers(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: isNarrow
          ? FloatingActionButton(
              onPressed: _openAddUserDialog,
              heroTag: 'add-user-fab-mobile',
              tooltip: 'Tambah User',
              backgroundColor: ClayColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add_rounded),
            )
          : FloatingActionButton.extended(
              onPressed: _openAddUserDialog,
              heroTag: 'add-user-fab-desktop',
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah User'),
              backgroundColor: ClayColors.primary,
              foregroundColor: Colors.white,
              extendedPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 0,
              ),
              shape: const StadiumBorder(),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: auth.users.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_off_rounded,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada user',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                ...auth.users.asMap().entries.map((entry) {
                  final user = entry.value;
                  final isSelf = user.id == currentUserId;
                  final isAdmin = user.role == 'admin';

                  return ClayFadeSlide(
                    index: entry.key,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClayCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? ClayColors.primary.withAlpha(30)
                                    : ClayColors.secondary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.person_rounded,
                                color: isAdmin
                                    ? ClayColors.primary
                                    : ClayColors.secondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.email,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelf)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ClayColors.success.withAlpha(
                                              30,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'Saya',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: ClayColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? ClayColors.primary.withAlpha(18)
                                          : ClayColors.secondary.withAlpha(18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isAdmin
                                            ? ClayColors.primary
                                            : ClayColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isSelf) ...[
                              IconButton(
                                icon: Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: ClayColors.warning,
                                ),
                                tooltip: 'Edit user',
                                onPressed: () => _openEditDialog(user),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_rounded,
                                  size: 20,
                                  color: Colors.red.shade300,
                                ),
                                tooltip: 'Hapus user',
                                onPressed: () => _confirmDeleteUser(user),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

