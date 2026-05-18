import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_fade_slide.dart';
import '../../theme/clay_colors.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});
  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _categoryOptions = [
    'Aneka Ayam',
    'Aneka Nasi Goreng',
    'Aneka Indomie',
    'Minuman',
    'Lainnya',
  ];

  bool _cartExpanded = true;
  late final AnimationController _cartAnim;
  late final Animation<double> _cartCurve;

  @override
  void initState() {
    super.initState();
    _cartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _cartCurve = CurvedAnimation(parent: _cartAnim, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Muat SEMUA produk (aktif & nonaktif) supaya bisa tampil label stok habis
      context.read<ProductProvider>().loadProducts(onlyActive: false);
      context.read<StockProvider>().loadMovements();
    });
  }

  @override
  void dispose() {
    _cartAnim.dispose();
    super.dispose();
  }

  void _toggleCart() {
    setState(() => _cartExpanded = !_cartExpanded);
    if (_cartExpanded) {
      _cartAnim.forward();
    } else {
      _cartAnim.reverse();
    }
  }

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

  /// Cegah qty melebihi stok tersedia dan tampilkan warning jika perlu.
  bool _tryIncreaseQty({
    required BuildContext context,
    required CartProvider cart,
    required Product product,
    required Map<String, int> stockMap,
  }) {
    final stockQty = stockMap[product.id] ?? 0;
    final qtyInCart = cart.items[product.id]?.quantity ?? 0;
    if (qtyInCart >= stockQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maks stok ${product.name}: $stockQty'),
          backgroundColor: ClayColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return false;
    }
    cart.addItem(product);
    return true;
  }

  /// Kelompokkan SEMUA produk (bukan hanya aktif)
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

  Future<void> _checkout(CartProvider cart) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final transactionProvider = context.read<TransactionProvider>();
    final stockProvider = context.read<StockProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${formatRupiah(cart.totalPrice)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '${cart.totalItems} item',
              style: TextStyle(color: ClayColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ClayColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final items = cart.itemsList
          .map(
            (item) => {
              'product_id': item.product.id,
              'qty': item.quantity,
              'price': item.product.price,
            },
          )
          .toList();
      final total = cart.totalPrice;

      await transactionProvider.createTransaction(
        cashierId: user.id,
        total: total,
        items: items,
      );
      await stockProvider.loadMovements();

      cart.clear();
      await LocalNotificationService.showTransactionSuccess(total);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Transaksi ${formatRupiah(total)} berhasil!'),
            ],
          ),
          backgroundColor: ClayColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal checkout: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();
    final stockProvider = context.watch<StockProvider>();

    if (productProvider.isLoading || stockProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (productProvider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Gagal memuat menu: ${productProvider.error}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<ProductProvider>().loadProducts(
                onlyActive: false,
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final products = productProvider.products;
    if (products.isEmpty) {
      return const Center(child: Text('Belum ada menu.'));
    }

    final stockMap = stockProvider.stockMap;
    final grouped = _groupProducts(products);
    final categories = _orderedCategories(grouped.keys);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: _buildMenuWidgets(
              context,
              categories,
              grouped,
              cart,
              stockMap,
            ),
          ),
        ),
        _buildCartPanel(context, cart, stockMap),
      ],
    );
  }

  List<Widget> _buildMenuWidgets(
    BuildContext context,
    List<String> categories,
    Map<String, List<Product>> grouped,
    CartProvider cart,
    Map<String, int> stockMap,
  ) {
    final widgets = <Widget>[];
    var itemIndex = 0;

    for (final category in categories) {
      final items = grouped[category] ?? [];
      if (items.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ClayColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      );

      for (final product in items) {
        final idx = itemIndex++;
        final stockQty = stockMap[product.id] ?? 0;
        // Bisa dipesan: harus aktif DAN ada stok
        final canOrder = product.isActive && stockQty > 0;
        final qtyInCart = cart.items[product.id]?.quantity ?? 0;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClayFadeSlide(
              index: idx,
              child: Opacity(
                opacity: canOrder ? 1.0 : 0.6,
                child: ClayCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),

                                // Label stok / status - di bawah nama, bukan di Row nama
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(product.price),
                              style: TextStyle(
                                color: ClayColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Badge stok
                            if (!canOrder)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stockQty <= 0 ? '! Stok Habis' : '! Nonaktif',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ClayColors.success.withAlpha(22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Stok: $stockQty',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: ClayColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Tombol add/qty - disable jika stok habis/nonaktif
                      if (!canOrder)
                        GestureDetector(
                          onTap: () {
                            final msg = stockQty <= 0
                                ? 'Stok "${product.name}" habis, tidak bisa dipesan.'
                                : '"${product.name}" sedang nonaktif.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(msg)),
                                  ],
                                ),
                                backgroundColor: ClayColors.warning,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              size: 20,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      else if (qtyInCart > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SmallIconBtn(
                              icon: Icons.remove,
                              onTap: () => cart.decrease(product.id),
                              color: ClayColors.textMuted,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '$qtyInCart',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _SmallIconBtn(
                              icon: Icons.add,
                              onTap: () {
                                _tryIncreaseQty(
                                  context: context,
                                  cart: cart,
                                  product: product,
                                  stockMap: stockMap,
                                );
                              },
                              color: ClayColors.primary,
                            ),
                          ],
                        )
                      else
                        _SmallIconBtn(
                          icon: Icons.add_shopping_cart_rounded,
                          onTap: () {
                            final added = _tryIncreaseQty(
                              context: context,
                              cart: cart,
                              product: product,
                              stockMap: stockMap,
                            );
                            if (added) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} ditambahkan'),
                                  duration: const Duration(milliseconds: 600),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          color: ClayColors.primary,
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
    return widgets;
  }

  Widget _buildCartPanel(
    BuildContext context,
    CartProvider cart,
    Map<String, int> stockMap,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClayCard(
        padding: EdgeInsets.zero,
        elevation: ClayElevation.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: cart.isEmpty ? null : _toggleCart,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_rounded,
                      color: ClayColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pesanan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (cart.totalItems > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ClayColors.primary.withAlpha(38),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cart.totalItems} item',
                          style: TextStyle(
                            fontSize: 12,
                            color: ClayColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formatRupiah(cart.totalPrice),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ClayColors.primary,
                      ),
                    ),
                    if (!cart.isEmpty) ...[
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _cartExpanded ? 0 : 0.5,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: ClayColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _cartCurve,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  if (cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Belum ada pesanan',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: cart.itemsList.length,
                        itemBuilder: (context, index) {
                          final item = cart.itemsList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ClayCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              elevation: ClayElevation.surface,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          formatRupiah(item.total),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ClayColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _SmallIconBtn(
                                        icon: Icons.remove,
                                        onTap: () =>
                                            cart.decrease(item.product.id),
                                        color: ClayColors.textMuted,
                                        size: 18,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _SmallIconBtn(
                                        icon: Icons.add,
                                        onTap: () => _tryIncreaseQty(
                                          context: context,
                                          cart: cart,
                                          product: item.product,
                                          stockMap: stockMap,
                                        ),
                                        color: ClayColors.primary,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  _SmallIconBtn(
                                    icon: Icons.delete_outline_rounded,
                                    onTap: () => cart.remove(item.product.id),
                                    color: Colors.red.shade300,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!cart.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => cart.clear(),
                            icon: const Icon(
                              Icons.delete_sweep_rounded,
                              size: 16,
                            ),
                            label: const Text('Clear'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ClayColors.textMuted,
                              side: BorderSide(color: ClayColors.textMuted),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClayButton(
                              label: 'Bayar ${formatRupiah(cart.totalPrice)}',
                              onPressed: () => _checkout(cart),
                              fullWidth: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  const _SmallIconBtn({
    required this.icon,
    required this.onTap,
    required this.color,
    this.size = 20,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

