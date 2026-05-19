import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/clay_colors.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_fade_slide.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static final Uri _bangjunMapsUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=BangJun%20Spot%20Samarinda',
  );

  WebViewController? _controller;

  static const String _mapHtml = '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body { width: 100%; height: 100%; }
      iframe { width: 100%; height: 100%; border: none; }
    </style>
  </head>
  <body>
    <iframe
      src="https://maps.google.com/maps?q=Kedai+Bang+Jun+Samarinda&z=15&output=embed"
      loading="lazy"
      allowfullscreen>
    </iframe>
  </body>
  </html>
  ''';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(_mapHtml);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<AuthProvider>().loadProfile();
      context.read<ProductProvider>().loadProducts(onlyActive: false);
      context.read<StockProvider>().loadMovements();
    });
  }

  /// Tampilkan snackbar dengan style konsisten.
  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? ClayColors.success : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openGoogleMapsRoute() async {
    final launched = await launchUrl(
      _bangjunMapsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      _showSnackBar('Tidak bisa membuka Google Maps.', success: false);
    }
  }

  double _calcTotalByDay(List<dynamic> transactions, DateTime day) {
    return transactions
        .where((t) {
          final d = t.createdAt;
          if (d == null) return false;
          return d.year == day.year && d.month == day.month && d.day == day.day;
        })
        .fold<double>(0, (sum, t) => sum + ((t.total as num).toDouble()));
  }

  double _calcRecentDaysTotal(List<dynamic> transactions, int days) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return transactions
        .where((t) {
          final d = t.createdAt;
          if (d == null) return false;
          return !d.isBefore(start);
        })
        .fold<double>(0, (sum, t) => sum + ((t.total as num).toDouble()));
  }

  double _calcPreviousDaysTotal(List<dynamic> transactions, int days) {
    final now = DateTime.now();
    final endCurrent = DateTime(now.year, now.month, now.day);
    final endPrevious = endCurrent.subtract(Duration(days: days));
    final startPrevious = endPrevious.subtract(Duration(days: days));
    return transactions
        .where((t) {
          final d = t.createdAt;
          if (d == null) return false;
          return !d.isBefore(startPrevious) && d.isBefore(endPrevious);
        })
        .fold<double>(0, (sum, t) => sum + ((t.total as num).toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final productProvider = context.watch<ProductProvider>();
    final stockProvider = context.watch<StockProvider>();

    if (tx.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tx.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Gagal memuat data: ${tx.error}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => tx.loadTransactions(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final todayTotal = tx.todayTotal;
    final monthTotal = tx.monthTotal;
    final last7Days = tx.last7Days;
    final transactions = tx.transactions;
    final has7DaysData = last7Days.any((e) => e.value > 0);
    final products = productProvider.products;
    final stockMap = stockProvider.stockMap;
    final criticalProducts =
        products.where((p) {
          final stock = stockMap[p.id] ?? 0;
          return p.isActive && stock > 0 && stock <= p.minStock;
        }).toList()..sort(
          (a, b) => (stockMap[a.id] ?? 0).compareTo(stockMap[b.id] ?? 0),
        );
    final nonActiveWithStock = products.where((p) {
      final stock = stockMap[p.id] ?? 0;
      return !p.isActive && stock > 0;
    }).toList();
    final recentTransactions = transactions.take(3).toList();
    final topMenus = _computeTopMenus(transactions, limit: 3);
    final yesterdayTotal = _calcTotalByDay(
      transactions,
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final this7 = _calcRecentDaysTotal(transactions, 7);
    final prev7 = _calcPreviousDaysTotal(transactions, 7);
    final omzetDownVsYesterday =
        yesterdayTotal > 0 && todayTotal < yesterdayTotal;
    final omzetDownVsLastWeek = prev7 > 0 && this7 < prev7;

    return RefreshIndicator(
      onRefresh: () => tx.loadTransactions(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -- Ringkasan Real-time (Above the fold) --
          ClayFadeSlide(
            index: 0,
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.flash_on_rounded,
                    title: 'Ringkasan Real-time',
                    color: ClayColors.primary,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickInfoChip(
                          icon: Icons.payments_rounded,
                          label: 'Omzet Hari Ini',
                          value: formatRupiah(todayTotal),
                          color: ClayColors.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickInfoChip(
                          icon: Icons.receipt_long_rounded,
                          label: 'Transaksi Terakhir',
                          value: '${recentTransactions.length} item',
                          color: ClayColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickInfoChip(
                          icon: Icons.warning_amber_rounded,
                          label: 'Stok Kritis',
                          value: '${criticalProducts.length} menu',
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickInfoChip(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Menu Terlaris',
                          value: topMenus.isEmpty
                              ? 'Belum ada data'
                              : '${topMenus.first.$1} (${topMenus.first.$2})',
                          color: ClayColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  if (topMenus.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: topMenus.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final menu = entry.value;
                        final rankColor = switch (rank) {
                          1 => Colors.amber.shade700,
                          2 => Colors.blueGrey,
                          _ => Colors.deepOrange.shade400,
                        };
                        final menuName = menu.$1;
                        return Tooltip(
                          message: 'Klik untuk lihat detail penjualan menu',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              final totalAll = _countMenuQty(
                                transactions,
                                menuName,
                              );
                              final total7Days = _countMenuQty(
                                _filterRecentDaysTransactions(transactions, 7),
                                menuName,
                              );
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Detail $menuName'),
                                  content: Text(
                                    'Total terjual: $totalAll\n'
                                    '7 hari terakhir: $total7Days',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: rankColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: rankColor.withAlpha(60),
                                ),
                              ),
                              child: Text(
                                '#$rank ${menu.$1} (${menu.$2})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: rankColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (recentTransactions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Transaksi terbaru:',
                      style: TextStyle(
                        fontSize: 12,
                        color: ClayColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...recentTransactions.map((t) {
                      final date = t.createdAt != null
                          ? '${t.createdAt!.day}/${t.createdAt!.month} ${t.createdAt!.hour.toString().padLeft(2, '0')}:${t.createdAt!.minute.toString().padLeft(2, '0')}'
                          : '-';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$date • ${formatRupiah(t.total)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ClayColors.textPrimary,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Notifikasi Cerdas --
          ClayFadeSlide(
            index: 1,
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifikasi Cerdas',
                    color: ClayColors.secondary,
                  ),
                  const SizedBox(height: 10),
                  if (criticalProducts.isNotEmpty)
                    _AlertTile(
                      icon: Icons.inventory_2_rounded,
                      color: Colors.orange.shade700,
                      title: 'Stok hampir habis',
                      message: criticalProducts
                          .take(3)
                          .map((p) => '${p.name} (${stockMap[p.id] ?? 0})')
                          .join(', '),
                    ),
                  if (nonActiveWithStock.isNotEmpty)
                    _AlertTile(
                      icon: Icons.visibility_off_rounded,
                      color: Colors.blueGrey,
                      title: 'Menu nonaktif masih tersedia',
                      message: nonActiveWithStock
                          .take(3)
                          .map((p) => '${p.name} (${stockMap[p.id] ?? 0})')
                          .join(', '),
                    ),
                  if (omzetDownVsYesterday)
                    _AlertTile(
                      icon: Icons.trending_down_rounded,
                      color: Colors.red.shade600,
                      title: 'Omzet turun dibanding kemarin',
                      message:
                          'Hari ini ${formatRupiah(todayTotal)} vs kemarin ${formatRupiah(yesterdayTotal)}',
                    ),
                  if (omzetDownVsLastWeek)
                    _AlertTile(
                      icon: Icons.calendar_view_week_rounded,
                      color: Colors.red.shade500,
                      title: 'Omzet turun dibanding 7 hari sebelumnya',
                      message:
                          '7 hari ini ${formatRupiah(this7)} vs 7 hari sebelumnya ${formatRupiah(prev7)}',
                    ),
                  if (criticalProducts.isEmpty &&
                      nonActiveWithStock.isEmpty &&
                      !omzetDownVsYesterday &&
                      !omzetDownVsLastWeek)
                    Text(
                      'Tidak ada alert penting saat ini. Performa operasional terlihat aman.',
                      style: TextStyle(
                        color: ClayColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Summary Cards --
          Row(
            children: [
              Expanded(
                child: ClayFadeSlide(
                  index: 2,
                  child: _StatCard(
                    icon: Icons.today_rounded,
                    title: 'Hari Ini',
                    value: formatRupiah(todayTotal),
                    color: ClayColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClayFadeSlide(
                  index: 3,
                  child: _StatCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Bulan Ini',
                    value: formatRupiah(monthTotal),
                    color: ClayColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -- 7 Hari Terakhir --
          ClayFadeSlide(
            index: 4,
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.bar_chart_rounded,
                    title: '7 Hari Terakhir',
                    color: ClayColors.primary,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: has7DaysData
                        ? _BarChart7Days(data: last7Days)
                        : const _EmptyChart(
                            icon: Icons.bar_chart_rounded,
                            message: 'Belum ada transaksi\n7 hari terakhir',
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Grafik Keuntungan Tahun Ini (per bulan) --
          ClayFadeSlide(
            index: 5,
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.trending_up_rounded,
                    title: 'Keuntungan Tahun ${tx.selectedYear}',
                    color: ClayColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: tx.yearlyMonthTotals.any((v) => v > 0)
                        ? _YearlyBarChart(
                            totals: tx.yearlyMonthTotals,
                            selectedMonth: tx.selectedMonth - 1,
                          )
                        : const _EmptyChart(
                            icon: Icons.trending_up_rounded,
                            message: 'Belum ada data tahun ini',
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Grafik Detail Bulan (with month filter) --
          ClayFadeSlide(
            index: 6,
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        color: ClayColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Grafik Detail Bulan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MonthDropdown(
                        selectedMonth: tx.selectedMonth,
                        selectedYear: tx.selectedYear,
                        onChanged: (m, y) => tx.setMonthFilter(m, y),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${formatRupiah(tx.filteredMonthTotal)}',
                    style: TextStyle(fontSize: 12, color: ClayColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: tx.filteredMonthDays.any((e) => e.value > 0)
                        ? _LineChartMonth(data: tx.filteredMonthDays)
                        : const _EmptyChart(
                            icon: Icons.show_chart_rounded,
                            message: 'Belum ada transaksi\npada bulan ini',
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Recent Transactions --
          ClayFadeSlide(
            index: 7,
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.receipt_long_rounded,
                    title: 'Transaksi Terbaru',
                    color: ClayColors.secondary,
                  ),
                  const SizedBox(height: 8),
                  if (transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...transactions.take(10).toList().asMap().entries.map((
                      entry,
                    ) {
                      final t = entry.value;
                      final date = t.createdAt != null
                          ? '${t.createdAt!.day}/${t.createdAt!.month} '
                                '${t.createdAt!.hour.toString().padLeft(2, '0')}:'
                                '${t.createdAt!.minute.toString().padLeft(2, '0')}'
                          : '-';
                      return ClayFadeSlide(
                        index: entry.key,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: ClayColors.success.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: ClayColors.success,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  date,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                formatRupiah(t.total),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ClayColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Detail BangJun --
          ClayFadeSlide(
            index: 8,
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: ClayColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Detail BangJun',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BangJun Spot - UMKM kuliner Samarinda',
                    style: TextStyle(fontSize: 12, color: ClayColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BangJun Spot adalah usaha kuliner lokal dengan menu utama '
                    'aneka ayam, nasi goreng, indomie, dan minuman. Dashboard '
                    'ini dipakai untuk memantau penjualan, stok, produk, kasir, '
                    'dan absensi operasional toko.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ClayColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Peta di bawah ditetapkan ke pencarian Google Maps BangJun Spot Samarinda.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ClayColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClayButton(
                    label: 'Tekan untuk Buka GMaps',
                    onPressed: _openGoogleMapsRoute,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _controller != null
                          ? WebViewWidget(controller: _controller!)
                          : Container(
                              color: ClayColors.surfaceAlt,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    color: ClayColors.primary,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pratinjau peta tidak tersedia di platform ini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: ClayColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Gunakan perangkat Android/iOS untuk preview peta di aplikasi.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: ClayColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<(String, int)> _computeTopMenus(
  List<dynamic> transactions, {
  int limit = 3,
}) {
  final freq = <String, int>{};

  for (final tx in transactions) {
    final dynamic items = _extractTransactionItems(tx);
    if (items is! List) continue;

    for (final rawItem in items) {
      final parsed = _parseItem(rawItem);
      if (parsed == null) continue;
      final (name, qty) = parsed;
      if (name.isEmpty || qty <= 0) continue;
      freq[name] = (freq[name] ?? 0) + qty;
    }
  }

  final sorted = freq.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(limit).map((e) => (e.key, e.value)).toList();
}

List<dynamic> _filterRecentDaysTransactions(
  List<dynamic> transactions,
  int days,
) {
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: days - 1));
  return transactions.where((t) {
    final d = t.createdAt;
    if (d == null) return false;
    return !d.isBefore(start);
  }).toList();
}

int _countMenuQty(List<dynamic> transactions, String menuName) {
  var total = 0;
  for (final tx in transactions) {
    final dynamic items = _extractTransactionItems(tx);
    if (items is! List) continue;
    for (final rawItem in items) {
      final parsed = _parseItem(rawItem);
      if (parsed == null) continue;
      final (name, qty) = parsed;
      if (name.toLowerCase() == menuName.toLowerCase()) {
        total += qty;
      }
    }
  }
  return total;
}

dynamic _extractTransactionItems(dynamic tx) {
  try {
    final dynamic itemsField = tx.items;
    if (itemsField != null) return itemsField;
  } catch (_) {}

  try {
    final dynamic cartItemsField = tx.cartItems;
    if (cartItemsField != null) return cartItemsField;
  } catch (_) {}

  try {
    if (tx is Map<String, dynamic>) {
      return tx['items'] ?? tx['cart_items'];
    }
  } catch (_) {}

  return null;
}

(String, int)? _parseItem(dynamic rawItem) {
  if (rawItem == null) return null;

  if (rawItem is Map<String, dynamic>) {
    final name =
        (rawItem['name'] ??
                rawItem['product_name'] ??
                rawItem['menu_name'] ??
                rawItem['title'])
            ?.toString()
            .trim();
    final qtyNum =
        rawItem['qty'] ??
        rawItem['quantity'] ??
        rawItem['count'] ??
        rawItem['jumlah'] ??
        1;
    final qty = qtyNum is num
        ? qtyNum.toInt()
        : int.tryParse(qtyNum.toString()) ?? 1;
    if (name == null || name.isEmpty) return null;
    return (name, qty);
  }

  try {
    final dynamic name = rawItem.name;
    final dynamic qtyRaw =
        rawItem.qty ?? rawItem.quantity ?? rawItem.count ?? 1;
    final qty = qtyRaw is num
        ? qtyRaw.toInt()
        : int.tryParse(qtyRaw.toString()) ?? 1;
    if (name == null) return null;
    final text = name.toString().trim();
    if (text.isEmpty) return null;
    return (text, qty);
  } catch (_) {
    return null;
  }
}

// --- Month Dropdown -----------------------------------------------------------
class _MonthDropdown extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final void Function(int month, int year) onChanged;

  const _MonthDropdown({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: ClayColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMonth,
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            color: ClayColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          items: List.generate(12, (i) {
            final m = i + 1;
            return DropdownMenuItem(
              value: m,
              child: Text(TransactionProvider.monthNames[i]),
            );
          }),
          onChanged: (m) {
            if (m != null) onChanged(m, now.year);
          },
        ),
      ),
    );
  }
}

// --- Bar Chart 7 Days ---------------------------------------------------------
class _BarChart7Days extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  const _BarChart7Days({required this.data});

  String _abbrevRupiah(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yInterval = _niceInterval(maxY);

    return BarChart(
      BarChartData(
        maxY: (maxY * 1.25).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.black.withAlpha(15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _abbrevRupiah(value),
                    style: TextStyle(fontSize: 9, color: ClayColors.textMuted),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatDateShort(data[index].key),
                    style: TextStyle(fontSize: 9, color: ClayColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ClayColors.primary.withAlpha(220),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                formatRupiah(rod.toY),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].value,
                color: ClayColors.primary,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}

// --- Yearly Monthly Bar Chart -------------------------------------------------
class _YearlyBarChart extends StatelessWidget {
  final List<double> totals;
  final int selectedMonth;

  const _YearlyBarChart({required this.totals, required this.selectedMonth});

  String _abbrevRupiah(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final maxY = totals.reduce((a, b) => a > b ? a : b);
    final yInterval = _niceInterval(maxY);

    return BarChart(
      BarChartData(
        maxY: (maxY * 1.25).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.black.withAlpha(15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _abbrevRupiah(value),
                    style: TextStyle(fontSize: 9, color: ClayColors.textMuted),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= 12) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    TransactionProvider.monthNames[idx],
                    style: TextStyle(
                      fontSize: 9,
                      color: idx == selectedMonth
                          ? ClayColors.secondary
                          : ClayColors.textMuted,
                      fontWeight: idx == selectedMonth
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ClayColors.secondary.withAlpha(220),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${TransactionProvider.monthNames[group.x]}\n${formatRupiah(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(12, (i) {
          final isSelected = i == selectedMonth;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: totals[i],
                color: isSelected
                    ? ClayColors.secondary
                    : ClayColors.secondary.withAlpha(100),
                width: 16,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}

// --- Line Chart Monthly -------------------------------------------------------
class _LineChartMonth extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  const _LineChartMonth({required this.data});

  String _abbrevRupiah(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yInterval = _niceInterval(maxY);

    return LineChart(
      LineChartData(
        maxY: (maxY * 1.3).ceilToDouble(),
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.black.withAlpha(15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => ClayColors.success.withAlpha(220),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final date = data[spot.x.toInt()].key;
                return LineTooltipItem(
                  '${date.day} ${TransactionProvider.monthNames[date.month - 1]}\n${formatRupiah(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _abbrevRupiah(value),
                    style: TextStyle(fontSize: 9, color: ClayColors.textMuted),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (data.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${data[idx].key.day}',
                    style: TextStyle(fontSize: 9, color: ClayColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: ClayColors.success,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: spot.y > 0 ? 3 : 0,
                  color: ClayColors.success,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: ClayColors.success.withAlpha(30),
            ),
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].value),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}

// --- Helpers ------------------------------------------------------------------
double _niceInterval(double maxY) {
  if (maxY <= 0) return 1;
  final raw = maxY / 4;
  final magnitude = (raw == 0)
      ? 1
      : (10 * (1 << (raw.toString().split('.')[0].length - 1)));
  return (raw / magnitude).ceil() * magnitude.toDouble();
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyChart({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: ClayColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: ClayColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    color: ClayColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
