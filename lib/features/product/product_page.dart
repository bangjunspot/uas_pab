import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/emoji_filter.dart';
import '../../core/utils/input_validators.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/rupiah_input_formatter.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../theme/clay_colors.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_input.dart';
import '../../widgets/clay_fade_slide.dart';
import '../../widgets/clay_fab.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  static const List<String> _categoryOptions = [
    'Aneka Ayam',
    'Aneka Nasi Goreng',
    'Aneka Indomie',
    'Minuman',
    'Lainnya',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  List<String> _orderedCategories(Iterable<String> keys) {
    final ordered = <String>[];
    for (final key in _categoryOptions) {
      if (keys.contains(key)) ordered.add(key);
    }
    final extras = keys.where((k) => !_categoryOptions.contains(k)).toList()
      ..sort();
    ordered.addAll(extras);
    return ordered;
  }

  Map<String, List<Product>> _groupProducts(List<Product> items) {
    final map = <String, List<Product>>{};
    for (final product in items) {
      final raw = product.category?.trim();
      final key = (raw == null || raw.isEmpty) ? 'Lainnya' : raw;
      map.putIfAbsent(key, () => []).add(product);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(onlyActive: false);
      context.read<StockProvider>().loadMovements();
    });
  }

  /// Tampilkan snackbar dengan gaya konsisten.
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

  Future<Uint8List?> _cropAndReadBytes(String sourcePath) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 78,
        maxWidth: 1280,
        maxHeight: 1280,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Foto Produk',
            toolbarColor: ClayColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Foto Produk',
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 450, height: 520),
          ),
        ],
      );

      if (cropped == null) return null;
      return await cropped.readAsBytes();
    } catch (e) {
      _showSnackBar('Gagal crop foto: $e', success: false);
      return null;
    }
  }

  Future<Uint8List?> _pickFromImageSource(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return null;
      if (!mounted) return null;
      return _cropAndReadBytes(picked.path);
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e', success: false);
      return null;
    }
  }

  Future<Uint8List?> _pickFromStorage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (kIsWeb) {
        return file.bytes;
      }

      if (file.path == null || file.path!.isEmpty) {
        _showSnackBar('File tidak valid', success: false);
        return null;
      }

      return _cropAndReadBytes(file.path!);
    } catch (e) {
      _showSnackBar('Gagal memilih file: $e', success: false);
      return null;
    }
  }

  Future<Uint8List?> _pickProductPhoto() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_rounded),
              title: const Text('Penyimpanan'),
              onTap: () => Navigator.pop(ctx, 'storage'),
            ),
          ],
        ),
      ),
    );

    switch (option) {
      case 'camera':
        return _pickFromImageSource(ImageSource.camera);
      case 'gallery':
        return _pickFromImageSource(ImageSource.gallery);
      case 'storage':
        return _pickFromStorage();
      default:
        return null;
    }
  }

  /// Upload foto produk ke Supabase Storage dan ambil public URL.
  Future<String> _uploadProductPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final bucket = Supabase.instance.client.storage.from('product-images');
    await bucket.uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    return bucket.getPublicUrl(fileName);
  }

  /// Tampilkan pesan error upload yang lebih jelas untuk storage.
  String _mapPhotoUploadError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('bucket not found')) {
      return 'Bucket "product-images" belum ada. Buat bucket dulu di Supabase Storage.';
    }
    if (msg.contains('permission') || msg.contains('unauthorized')) {
      return 'Tidak punya izin upload ke bucket product-images.';
    }
    return 'Gagal simpan foto: $error';
  }

  /// Bangun preview foto di dalam dialog tambah/edit produk.
  Widget _buildPhotoPreview({
    required Uint8List? photoBytes,
    required String? imageUrl,
  }) {
    Widget child;

    if (photoBytes != null) {
      child = Image.memory(
        photoBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        cacheWidth: 1080,
        filterQuality: FilterQuality.low,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      child = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (_, _, _) => _buildPhotoPlaceholder(),
      );
    } else {
      child = _buildPhotoPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: child,
      ),
    );
  }

  /// Placeholder jika foto belum tersedia.
  Widget _buildPhotoPlaceholder() {
    return Container(
      color: ClayColors.surfaceAlt,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              size: 42,
              color: ClayColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada foto',
              style: TextStyle(
                color: ClayColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog tambah/edit produk beserta foto (kamera/galeri/penyimpanan).
  Future<void> _openProductForm({Product? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null && product.price > 0
          ? RupiahInputFormatter.formatNumber(product.price.toInt())
          : '',
    );

    String selectedCategory = product?.category?.trim().isNotEmpty == true
        ? product!.category!.trim()
        : _categoryOptions.first;
    if (!_categoryOptions.contains(selectedCategory)) {
      selectedCategory = 'Lainnya';
    }

    bool isActive = product?.isActive ?? true;
    String? currentImageUrl = product?.imageUrl;
    Uint8List? selectedPhotoBytes;
    bool isUploadingPhoto = false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            Future<void> pickPhoto() async {
              final photo = await _pickProductPhoto();
              if (photo == null) return;
              setStateDialog(() {
                selectedPhotoBytes = photo;
              });
            }

            return AlertDialog(
              title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPhotoPreview(
                          photoBytes: selectedPhotoBytes,
                          imageUrl: selectedPhotoBytes == null
                              ? currentImageUrl
                              : null,
                        ),
                        const SizedBox(height: 10),
                        ClayButton(
                          label: 'Pilih Foto',
                          onPressed: isUploadingPhoto ? null : pickPhoto,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 14),
                        ClayInput(
                          controller: nameController,
                          label: 'Nama Produk',
                          inputFormatters: [EmojiFilter.denyEmoji],
                          validator: (v) =>
                              InputValidators.requiredField(v, 'Nama produk'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                          ),
                          items: _categoryOptions
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => selectedCategory = val);
                            }
                          },
                          validator: (v) =>
                              InputValidators.requiredField(v, 'Kategori'),
                        ),
                        const SizedBox(height: 10),
                        ClayInput(
                          controller: priceController,
                          label: 'Harga (Rp)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            EmojiFilter.denyEmoji,
                            RupiahInputFormatter(),
                          ],
                          validator: (v) {
                            final raw =
                                v?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
                            if (raw.isEmpty) return 'Harga wajib diisi';
                            final val = double.tryParse(raw);
                            if (val == null || val <= 0) {
                              return 'Harga harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Aktif'),
                            Switch(
                              value: isActive,
                              activeThumbColor: ClayColors.success,
                              onChanged: (val) =>
                                  setStateDialog(() => isActive = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploadingPhoto
                      ? null
                      : () => Navigator.pop(dialogCtx, false),
                  child: const Text('Batal'),
                ),
                ClayButton(
                  onPressed: isUploadingPhoto
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setStateDialog(() => isUploadingPhoto = true);
                          try {
                            if (selectedPhotoBytes != null) {
                              final fileId = product?.id.isNotEmpty == true
                                  ? product!.id
                                  : DateTime.now().millisecondsSinceEpoch
                                      .toString();
                              final fileName = 'products/$fileId.jpg';
                              try {
                                currentImageUrl = await _uploadProductPhoto(
                                  bytes: selectedPhotoBytes!,
                                  fileName: fileName,
                                );
                              } catch (e) {
                                if (!dialogCtx.mounted) return;
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(_mapPhotoUploadError(e)),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                // Tetap lanjut simpan produk meski upload foto gagal.
                                currentImageUrl = product?.imageUrl;
                              }
                            }

                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx, true);
                          } catch (e) {
                            if (!dialogCtx.mounted) return;
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(
                                content: Text('Gagal simpan foto: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (dialogCtx.mounted) {
                              setStateDialog(() => isUploadingPhoto = false);
                            }
                          }
                        },
                  label: isUploadingPhoto ? 'Menyimpan...' : 'Simpan',
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;
    if (!mounted) return;

    final provider = context.read<ProductProvider>();

    final rawPrice = priceController.text.replaceAll(RegExp(r'[^\d]'), '');
    final price = double.tryParse(rawPrice) ?? 0;
    if (!mounted) return;

    final newProduct = Product(
      id: product?.id ?? '',
      name: nameController.text.trim(),
      category: selectedCategory.trim().isEmpty
          ? 'Lainnya'
          : selectedCategory.trim(),
      price: price,
      imageUrl: currentImageUrl,
      minStock: product?.minStock ?? 3,
      isActive: isActive,
      createdAt: product?.createdAt,
    );

    try {
      if (product == null) {
        await provider.addProduct(newProduct);
        _showSnackBar('Menu berhasil ditambahkan');
      } else {
        await provider.updateProduct(newProduct);
        _showSnackBar('Menu berhasil diperbarui');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        product == null
            ? 'Gagal menambahkan menu: $e'
            : 'Gagal memperbarui menu: $e',
        success: false,
      );
    }
  }

  /// Toggle aktif/nonaktif - hanya bisa aktif jika ada stok.
  Future<void> _toggleActive(
    Product product,
    bool newValue,
    Map<String, int> stockMap,
  ) async {
    final stock = stockMap[product.id] ?? 0;

    if (newValue && stock <= 0) {
      _showSnackBar(
        'Tidak bisa diaktifkan - stok "${product.name}" masih habis. '
        'Tambah stok di halaman Stok terlebih dahulu.',
        success: false,
      );
      return;
    }

    final updated = Product(
      id: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      imageUrl: product.imageUrl,
      minStock: product.minStock,
      isActive: newValue,
      createdAt: product.createdAt,
    );
    try {
      await context.read<ProductProvider>().updateProduct(updated);
      if (!mounted) return;
      _showSnackBar(
        newValue
            ? '"${product.name}" diaktifkan'
            : '"${product.name}" dinonaktifkan',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah status: $e', success: false);
    }
  }

  /// Hapus produk setelah konfirmasi.
  Future<void> _deleteProduct(Product product) async {
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
            const Text('Hapus Menu'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(ctx).style,
            children: [
              const TextSpan(text: 'Hapus menu '),
              TextSpan(
                text: product.name,
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
    try {
      await context.read<ProductProvider>().deleteProduct(product.id);
      _showSnackBar('Menu "${product.name}" berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal hapus menu: $e', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final stockProvider = context.watch<StockProvider>();
    final stockMap = stockProvider.stockMap;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Gagal memuat produk: ${provider.error}'));
    }

    final products = provider.products;
    final grouped = _groupProducts(products);
    final categories = _orderedCategories(grouped.keys);

    return Scaffold(
      floatingActionButton: ClayFab(
        icon: Icons.add,
        onPressed: () => _openProductForm(),
      ),
      body: products.isEmpty
          ? const Center(child: Text('Belum ada produk.'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: () {
                final widgets = <Widget>[];
                var itemIndex = 0;
                for (final category in categories) {
                  final items = grouped[category] ?? [];
                  if (items.isEmpty) continue;
                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  );
                  widgets.addAll(
                    items.map((product) {
                      final idx = itemIndex++;
                      final stock = stockMap[product.id] ?? 0;
                      final stockEmpty = stock <= 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ClayFadeSlide(
                          index: idx,
                          child: ClayCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: ClayColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.black.withAlpha(10),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: product.imageUrl != null &&
                                            product.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                              Icons.restaurant_menu_rounded,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.restaurant_menu_rounded,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatRupiah(product.price),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ClayColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          _StatusBadge(
                                            label: stockEmpty
                                                ? 'Stok Habis'
                                                : 'Stok: $stock',
                                            color: stockEmpty
                                                ? Colors.red
                                                : ClayColors.success,
                                          ),
                                          if (!product.isActive)
                                            const _StatusBadge(
                                              label: 'Nonaktif',
                                              color: Colors.grey,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: stockEmpty && !product.isActive
                                          ? 'Tambah stok dulu untuk mengaktifkan'
                                          : product.isActive
                                          ? 'Klik untuk nonaktifkan'
                                          : 'Klik untuk aktifkan',
                                      child: Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: product.isActive,
                                          onChanged:
                                              (stockEmpty && !product.isActive)
                                              ? null
                                              : (val) => _toggleActive(
                                                  product,
                                                  val,
                                                  stockMap,
                                                ),
                                          activeThumbColor: ClayColors.success,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      product.isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: product.isActive
                                            ? ClayColors.success
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () =>
                                      _openProductForm(product: product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red.shade300,
                                  onPressed: () => _deleteProduct(product),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }
                return widgets;
              }(),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

