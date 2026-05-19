import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cashier_shift_provider.dart';
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
  bool _isRepeatingLastOrder = false;
  bool _showQuickPanel = true;
  String _searchQuery = '';
  final List<String> _recentProductIds = [];
  final FocusNode _shortcutFocusNode = FocusNode();
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
      context.read<TransactionProvider>().loadTransactions();
      final profile = context.read<AuthProvider>().profile;
      if (profile != null) {
        context.read<CashierShiftProvider>().load(profile.id);
      }
    });
  }

  @override
  void dispose() {
    _cartAnim.dispose();
    _shortcutFocusNode.dispose();
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

  void _rememberRecentProduct(String productId) {
    _recentProductIds.remove(productId);
    _recentProductIds.insert(0, productId);
    if (_recentProductIds.length > 8) {
      _recentProductIds.removeRange(8, _recentProductIds.length);
    }
  }

  void _clearQuickSearchState() {
    setState(() {
      _searchQuery = '';
      _recentProductIds.clear();
      _showQuickPanel = false;
    });
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
    _rememberRecentProduct(product.id);
    return true;
  }

  double _parseRupiahInput(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }

  Future<void> _openShiftDialog() async {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    if (profile == null) return;

    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mulai Shift'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Modal kas awal',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, _parseRupiahInput(controller.text)),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    final provider = context.read<CashierShiftProvider>();
    final success = await provider.open(
      cashierId: profile.id,
      openingCash: result,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Shift dimulai. Modal awal ${formatRupiah(result)}'
              : 'Gagal mulai shift: ${provider.error}',
        ),
        backgroundColor: success ? ClayColors.success : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _closeShiftDialog() async {
    final provider = context.read<CashierShiftProvider>();
    final shift = provider.activeShift;
    if (shift == null) return;

    final cashController = TextEditingController(
      text: provider.expectedCash.toInt().toString(),
    );
    final noteController = TextEditingController();
    final result = await showDialog<(double, String?)>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tutup Shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah transaksi: ${provider.shiftTransactionCount}'),
            Text('Total transaksi: ${formatRupiah(provider.shiftSalesTotal)}'),
            Text('Uang seharusnya: ${formatRupiah(provider.expectedCash)}'),
            const SizedBox(height: 12),
            TextField(
              controller: cashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uang fisik di laci',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan opsional'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, (
              _parseRupiahInput(cashController.text),
              noteController.text.trim().isEmpty
                  ? null
                  : noteController.text.trim(),
            )),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    final expectedCash = provider.expectedCash;
    final success = await provider.close(
      closingCash: result.$1,
      note: result.$2,
    );
    if (!mounted) return;
    final difference = result.$1 - expectedCash;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Shift ditutup. Selisih ${formatRupiah(difference)}'
              : 'Gagal tutup shift: ${provider.error}',
        ),
        backgroundColor: success ? ClayColors.success : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProductDetail(
    BuildContext context, {
    required Product product,
    required int stockQty,
    required bool canOrder,
    required int qtyInCart,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _DetailImageFallback(),
                      )
                    : const _DetailImageFallback(),
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.category_rounded,
                label: 'Kategori',
                value: product.category?.trim().isNotEmpty == true
                    ? product.category!.trim()
                    : 'Lainnya',
              ),
              _DetailRow(
                icon: Icons.payments_rounded,
                label: 'Harga',
                value: formatRupiah(product.price),
              ),
              _DetailRow(
                icon: Icons.inventory_2_rounded,
                label: 'Stok',
                value: '$stockQty tersedia',
              ),
              _DetailRow(
                icon: Icons.shopping_bag_rounded,
                label: 'Di pesanan',
                value: '$qtyInCart item',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: canOrder
                      ? ClayColors.success.withAlpha(25)
                      : Colors.red.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  canOrder
                      ? 'Menu tersedia untuk dipesan'
                      : stockQty <= 0
                      ? 'Stok menu sedang habis'
                      : 'Menu sedang nonaktif',
                  style: TextStyle(
                    color: canOrder ? ClayColors.success : Colors.red.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (canOrder)
            ClayButton(
              label: 'Tambah ke Pesanan',
              onPressed: () {
                Navigator.pop(ctx);
                final added = _tryIncreaseQty(
                  context: context,
                  cart: context.read<CartProvider>(),
                  product: product,
                  stockMap: {product.id: stockQty},
                );
                if (added) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} ditambahkan'),
                      duration: const Duration(milliseconds: 700),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
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

  Future<void> _repeatLastOrder({
    required CartProvider cart,
    required List<Product> products,
    required Map<String, int> stockMap,
  }) async {
    final txProvider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final latest = txProvider.transactions.isNotEmpty
        ? txProvider.transactions.first
        : null;
    if (latest == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Belum ada transaksi terakhir untuk diulang.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isRepeatingLastOrder) return;
    setState(() => _isRepeatingLastOrder = true);

    try {
      cart.clear();
      final productById = {for (final p in products) p.id: p};
      final dynamic itemsRaw = _extractTransactionItems(latest);
      if (itemsRaw is! List || itemsRaw.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Data item transaksi terakhir tidak ditemukan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      var addedCount = 0;
      for (final raw in itemsRaw) {
        final parsed = _parseRepeatOrderItem(raw);
        if (parsed == null) continue;
        final productId = parsed.$1;
        final qty = parsed.$2;
        final product = productById[productId];
        if (product == null) continue;
        if (!product.isActive) continue;
        final stock = stockMap[product.id] ?? 0;
        if (stock <= 0) continue;
        final safeQty = qty > stock ? stock : qty;
        for (var i = 0; i < safeQty; i++) {
          cart.addItem(product);
        }
        _rememberRecentProduct(product.id);
        addedCount += safeQty;
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            addedCount > 0
                ? 'Order terakhir berhasil dimuat ($addedCount item).'
                : 'Tidak ada item valid yang bisa dimuat ulang.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRepeatingLastOrder = false);
      }
    }
  }

  dynamic _extractTransactionItems(dynamic tx) {
    try {
      final dynamic itemsField = tx.items;
      if (itemsField != null) return itemsField;
    } catch (_) {}
    try {
      if (tx is Map<String, dynamic>) return tx['items'];
    } catch (_) {}
    return null;
  }

  (String, int)? _parseRepeatOrderItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final id = (raw['product_id'] ?? raw['productId'])?.toString();
      final qtyRaw = raw['qty'] ?? raw['quantity'] ?? raw['count'] ?? 1;
      final qty = qtyRaw is num ? qtyRaw.toInt() : int.tryParse('$qtyRaw') ?? 1;
      if (id == null || id.isEmpty || qty <= 0) return null;
      return (id, qty);
    }
    return null;
  }

  Future<void> _checkout(CartProvider cart) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final transactionProvider = context.read<TransactionProvider>();
    final stockProvider = context.read<StockProvider>();
    final shiftProvider = context.read<CashierShiftProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final activeShift = shiftProvider.activeShift;

    if (activeShift == null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Mulai shift dulu sebelum transaksi.'),
          backgroundColor: ClayColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      final receiptItems = List<dynamic>.from(cart.itemsList);
      final total = cart.totalPrice;

      final transactionId = await transactionProvider.createTransaction(
        cashierId: user.id,
        shiftId: activeShift.id,
        total: total,
        items: items,
      );
      await stockProvider.loadMovements();
      await shiftProvider.load(user.id);

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
      await _showReceiptActions(
        transactionId: transactionId,
        items: receiptItems,
        total: total,
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

  String _buildReceiptText({
    required String transactionId,
    required List<dynamic> items,
    required double total,
  }) {
    final buffer = StringBuffer()
      ..writeln('BANGJUN SPOT')
      ..writeln('Struk Transaksi')
      ..writeln(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()))
      ..writeln('No: ${transactionId.substring(0, 8)}')
      ..writeln('-------------------------');

    for (final item in items) {
      final product = item.product;
      final qty = item.quantity;
      final lineTotal = item.total;
      buffer.writeln('${product.name} x$qty');
      buffer.writeln(formatRupiah(lineTotal));
    }

    buffer
      ..writeln('-------------------------')
      ..writeln('Total: ${formatRupiah(total)}')
      ..writeln('Terima kasih.');
    return buffer.toString();
  }

  Future<File> _saveReceiptPdf({
    required String transactionId,
    required List<dynamic> items,
    required double total,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BANGJUN SPOT',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Struk Transaksi'),
            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(now)),
            pw.Text('No: ${transactionId.substring(0, 8)}'),
            pw.SizedBox(height: 14),
            pw.Divider(),
            ...items.map((item) {
              final product = item.product;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text('${product.name} x${item.quantity}'),
                    ),
                    pw.Text(formatRupiah(item.total)),
                  ],
                ),
              );
            }),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  formatRupiah(total),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Text('Terima kasih.'),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final safeId = transactionId.substring(0, 8);
    final file = File('${dir.path}/struk-bangjun-$safeId.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> _shareReceiptToWhatsapp(String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membuka WhatsApp.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showReceiptActions({
    required String transactionId,
    required List<dynamic> items,
    required double total,
  }) async {
    final receiptText = _buildReceiptText(
      transactionId: transactionId,
      items: items,
      total: total,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Struk Transaksi'),
        content: const Text('Transaksi berhasil. Pilih aksi untuk struk.'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _shareReceiptToWhatsapp(receiptText);
            },
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Share WhatsApp'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final file = await _saveReceiptPdf(
                transactionId: transactionId,
                items: items,
                total: total,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF tersimpan: ${file.path}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Simpan PDF'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Print bluetooth bisa ditambahkan di tahap berikutnya.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print_rounded),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();
    final stockProvider = context.watch<StockProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final shiftProvider = context.watch<CashierShiftProvider>();

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
    final recentProducts = _recentProductIds
        .map((id) {
          try {
            return products.firstWhere((p) => p.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Product>()
        .toList();

    final quickSearchResults = products
        .where(
          (p) =>
              p.isActive &&
              (stockMap[p.id] ?? 0) > 0 &&
              (_searchQuery.trim().isEmpty ||
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase())),
        )
        .take(8)
        .toList();

    const digitKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    const numpadKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];

    final shortcuts = <ShortcutActivator, Intent>{};
    for (var i = 0; i < quickSearchResults.length && i < 9; i++) {
      shortcuts[SingleActivator(digitKeys[i])] = _QuickAddIntent(i);
      shortcuts[SingleActivator(numpadKeys[i])] = _QuickAddIntent(i);
    }

    return Focus(
      autofocus: true,
      focusNode: _shortcutFocusNode,
      child: Shortcuts(
        shortcuts: shortcuts,
        child: Actions(
          actions: {
            _QuickAddIntent: CallbackAction<_QuickAddIntent>(
              onInvoke: (intent) {
                final idx = intent.index;
                if (idx < 0 || idx >= quickSearchResults.length) return null;
                _tryIncreaseQty(
                  context: context,
                  cart: cart,
                  product: quickSearchResults[idx],
                  stockMap: stockMap,
                );
                return null;
              },
            ),
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: !_showQuickPanel
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _showQuickPanel = true),
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Buka Cari Menu Cepat'),
                        ),
                      )
                    : ClayCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                      ),
                                      hintText: 'Cari menu cepat...',
                                      suffixIcon: _searchQuery.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () => setState(
                                                () => _searchQuery = '',
                                              ),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tutup panel cepat & hapus riwayat',
                                  onPressed: _clearQuickSearchState,
                                  icon: const Icon(
                                    Icons.close_fullscreen_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (quickSearchResults.isNotEmpty) ...[
                              Text(
                                'Quick add (hotkey 1-9)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ClayColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: quickSearchResults
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final p = entry.value;
                                      final hotkey = index < 9
                                          ? ' [${index + 1}]'
                                          : '';
                                      return ActionChip(
                                        label: Text('${p.name}$hotkey'),
                                        onPressed: () {
                                          _tryIncreaseQty(
                                            context: context,
                                            cart: cart,
                                            product: p,
                                            stockMap: stockMap,
                                          );
                                        },
                                      );
                                    })
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (recentProducts.isNotEmpty) ...[
                              Row(
                                children: [
                                  Text(
                                    'Recent items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ClayColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _recentProductIds.clear(),
                                    ),
                                    child: const Text('Hapus Riwayat'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: recentProducts.take(6).map((p) {
                                  return ActionChip(
                                    avatar: const Icon(Icons.history, size: 14),
                                    label: Text(p.name),
                                    onPressed: () {
                                      _tryIncreaseQty(
                                        context: context,
                                        cart: cart,
                                        product: p,
                                        stockMap: stockMap,
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                            ClayButton(
                              label: _isRepeatingLastOrder
                                  ? 'Memuat order terakhir...'
                                  : 'Ulang Order Terakhir',
                              onPressed:
                                  _isRepeatingLastOrder || txProvider.isLoading
                                  ? null
                                  : () => _repeatLastOrder(
                                      cart: cart,
                                      products: products,
                                      stockMap: stockMap,
                                    ),
                              fullWidth: true,
                            ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: _ShiftSummaryCard(
                  provider: shiftProvider,
                  onOpenShift: _openShiftDialog,
                  onCloseShift: _closeShiftDialog,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: _buildMenuWidgets(
                    context,
                    categories,
                    grouped,
                    cart,
                    stockMap,
                    _searchQuery,
                  ),
                ),
              ),
              _buildCartPanel(context, cart, stockMap),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuWidgets(
    BuildContext context,
    List<String> categories,
    Map<String, List<Product>> grouped,
    CartProvider cart,
    Map<String, int> stockMap,
    String searchQuery,
  ) {
    final widgets = <Widget>[];
    var itemIndex = 0;
    final normalizedSearch = searchQuery.trim().toLowerCase();

    for (final category in categories) {
      final allItems = grouped[category] ?? [];
      final items = normalizedSearch.isEmpty
          ? allItems
          : allItems
                .where((p) => p.name.toLowerCase().contains(normalizedSearch))
                .toList();
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
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _showProductDetail(
                                  context,
                                  product: product,
                                  stockQty: stockQty,
                                  canOrder: canOrder,
                                  qtyInCart: qtyInCart,
                                ),
                                icon: const Icon(
                                  Icons.visibility_rounded,
                                  size: 15,
                                ),
                                label: const Text('Lihat Detail'),
                                style: TextButton.styleFrom(
                                  foregroundColor: ClayColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
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

class _QuickAddIntent extends Intent {
  final int index;
  const _QuickAddIntent(this.index);
}

class _ShiftSummaryCard extends StatelessWidget {
  final CashierShiftProvider provider;
  final VoidCallback onOpenShift;
  final VoidCallback onCloseShift;

  const _ShiftSummaryCard({
    required this.provider,
    required this.onOpenShift,
    required this.onCloseShift,
  });

  @override
  Widget build(BuildContext context) {
    final shift = provider.activeShift;
    final isOpen = shift != null;
    final openedAt = shift == null
        ? '-'
        : DateFormat('dd/MM HH:mm').format(shift.openedAt);

    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      elevation: ClayElevation.surface,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (isOpen ? ClayColors.success : ClayColors.warning)
                  .withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOpen ? Icons.point_of_sale_rounded : Icons.lock_clock_rounded,
              color: isOpen ? ClayColors.success : ClayColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'Shift aktif sejak $openedAt' : 'Belum mulai shift',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOpen
                      ? '${provider.shiftTransactionCount} transaksi - Total ${formatRupiah(provider.shiftSalesTotal)} - Laci ${formatRupiah(provider.expectedCash)}'
                      : 'Mulai shift sebelum transaksi agar laporan kas rapi.',
                  style: TextStyle(fontSize: 11, color: ClayColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: provider.isLoading
                ? null
                : isOpen
                ? onCloseShift
                : onOpenShift,
            child: Text(isOpen ? 'Tutup' : 'Mulai'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: ClayColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: ClayColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: ClayColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImageFallback extends StatelessWidget {
  const _DetailImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      color: ClayColors.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            color: ClayColors.textMuted,
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            'Foto menu belum tersedia',
            style: TextStyle(fontSize: 12, color: ClayColors.textMuted),
          ),
        ],
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
