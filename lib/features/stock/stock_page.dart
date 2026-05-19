import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/emoji_filter.dart';
import '../../core/utils/input_validators.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../theme/clay_colors.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_input.dart';
import '../../widgets/clay_fade_slide.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(onlyActive: false);
      context.read<StockProvider>().loadMovements();
    });
  }

  Future<void> _openStockDialog(
    Product product,
    String type,
    int currentQty,
  ) async {
    final qtyController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(type == 'in' ? 'Tambah Stok' : 'Kurangi Stok'),
          // ── SizedBox(width: double.maxFinite) kunci agar tidak melebar ──
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClayInput(
                    controller: qtyController,
                    label: 'Qty',
                    keyboardType: TextInputType.number,
                    inputFormatters: [EmojiFilter.denyEmoji],
                    validator: InputValidators.qty,
                  ),
                  const SizedBox(height: 10),
                  // Catatan: maxLines terbatas + SizedBox agar tidak melebar
                  SizedBox(
                    // Batasi lebar field catatan
                    width: double.maxFinite,
                    child: ClayInput(
                      controller: noteController,
                      label: 'Catatan (opsional)',
                      inputFormatters: [EmojiFilter.denyEmoji],
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ClayButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              label: 'Simpan',
            ),
          ],
        );
      },
    );

    if (result != true) return;
    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
    if (qty <= 0) return;
    if (!mounted) return;

    try {
      await context.read<StockProvider>().addMovement(
        productId: product.id,
        qty: qty,
        type: type,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      final newQty = type == 'in' ? currentQty + qty : currentQty - qty;

      // ── Auto-nonaktif jika stok habis ──────────────────────────────
      if (newQty <= 0 && product.isActive) {
        final deactivated = Product(
          id: product.id,
          name: product.name,
          category: product.category,
          price: product.price,
          imageUrl: product.imageUrl,
          minStock: product.minStock,
          isActive: false,
          createdAt: product.createdAt,
        );
        if (mounted) {
          await context.read<ProductProvider>().updateProduct(deactivated);
          if (!mounted) return;
          _showSnackBar(
            'Stok "${product.name}" habis — produk dinonaktifkan otomatis',
            success: false,
          );
        }
      }
      // ── Auto-aktif kembali jika stok naik dari 0 ───────────────────
      else if (currentQty <= 0 && newQty > 0 && !product.isActive) {
        final activated = Product(
          id: product.id,
          name: product.name,
          category: product.category,
          price: product.price,
          imageUrl: product.imageUrl,
          minStock: product.minStock,
          isActive: true,
          createdAt: product.createdAt,
        );
        if (mounted) {
          await context.read<ProductProvider>().updateProduct(activated);
          if (!mounted) return;
          _showSnackBar(
            '"${product.name}" diaktifkan kembali karena stok tersedia',
          );
        }
      } else {
        _showSnackBar(
          type == 'in'
              ? 'Stok "${product.name}" berhasil ditambah (+$qty)'
              : 'Stok "${product.name}" berhasil dikurangi (-$qty)',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal simpan stok: $e', success: false);
    }
  }

  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? ClayColors.success : ClayColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final stockProvider = context.watch<StockProvider>();

    if (productProvider.isLoading || stockProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (productProvider.error != null) {
      return Center(
        child: Text('Gagal memuat produk: ${productProvider.error}'),
      );
    }
    if (stockProvider.error != null) {
      return Center(child: Text('Gagal memuat stok: ${stockProvider.error}'));
    }

    final products = productProvider.products;
    final stockMap = stockProvider.stockMap;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Stok Produk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final qty = stockMap[product.id] ?? 0;
                final isEmpty = qty <= 0;
                return ClayFadeSlide(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClayCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!product.isActive)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(40),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Nonaktif',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isEmpty
                                        ? Colors.red.withAlpha(25)
                                        : ClayColors.success.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isEmpty ? 'Stok Habis' : 'Stok: $qty',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isEmpty
                                          ? Colors.red.shade600
                                          : ClayColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red.shade400,
                            tooltip: 'Kurangi stok',
                            onPressed: () =>
                                _openStockDialog(product, 'out', qty),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: ClayColors.success,
                            tooltip: 'Tambah stok',
                            onPressed: () =>
                                _openStockDialog(product, 'in', qty),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Riwayat Stok',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: stockProvider.movements.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada riwayat stok',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.builder(
                    itemCount: stockProvider.movements.length,
                    itemBuilder: (context, index) {
                      final movement = stockProvider.movements[index];
                      final product = products.firstWhere(
                        (p) => p.id == movement.productId,
                        orElse: () => Product(
                          id: movement.productId,
                          name: 'Produk',
                          category: null,
                          price: 0,
                          imageUrl: null,
                          minStock: 3,
                          isActive: true,
                          createdAt: null,
                        ),
                      );
                      final isIn = movement.type == 'in';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClayFadeSlide(
                          index: index,
                          child: ClayCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isIn
                                        ? ClayColors.success.withAlpha(25)
                                        : Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isIn
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: isIn
                                        ? ClayColors.success
                                        : Colors.red.shade400,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${isIn ? "Masuk" : "Keluar"} ${movement.qty}'
                                        '${movement.note != null ? ' • ${movement.note}' : ''}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ClayColors.textMuted,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
