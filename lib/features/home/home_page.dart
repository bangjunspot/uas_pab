import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/location_service.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../auth/biometric_gate.dart';
import '../dashboard/dashboard_page.dart';
import '../kasir/kasir_page.dart';
import '../kasir/widgets/barcode_scanner_sheet.dart';
import '../product/product_page.dart';
import '../stock/stock_page.dart';
import '../settings/settings_page.dart';
import '../../theme/clay_colors.dart';
import '../../widgets/clay_card.dart';

// Breakpoint: < ini pakai bottom nav, >= pakai sidebar
const double _kSidebarBreakpoint = 700;
const double _kSidebarExtended = 1100;

class HomePage extends StatelessWidget {
  final Profile profile;
  const HomePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final role = profile.role.toLowerCase();
    if (role == 'admin') return const AdminHomePage();
    return const KasirHomePage();
  }
}

// -----------------------------------------------------------------------------
// ADMIN HOME
// -----------------------------------------------------------------------------
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _index = 1;

  static const _pages = [
    BiometricGate(child: DashboardPage()),
    KasirPage(),
    ProductPage(),
    StockPage(),
    SettingsPage(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.shopping_cart_rounded, label: 'Kasir'),
    _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Produk'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Stok'),
    _NavItem(icon: Icons.manage_accounts_rounded, label: 'User'),
  ];

  void _onTabChanged(int value) {
    setState(() => _index = value);
    if (value == 0) context.read<TransactionProvider>().loadTransactions();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _LogoutDialog(),
    );
    if (confirmed == true && mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _kSidebarBreakpoint) {
      return _SidebarLayout(
        index: _index,
        pages: _pages,
        navItems: _navItems,
        onChanged: _onTabChanged,
        onLogout: _confirmLogout,
      );
    }
    return _BottomNavLayout(
      index: _index,
      pages: _pages,
      navItems: _navItems,
      onChanged: _onTabChanged,
      onLogout: _confirmLogout,
    );
  }
}

// -----------------------------------------------------------------------------
// BOTTOM NAV LAYOUT (Mobile / Narrow)
// -----------------------------------------------------------------------------
class _BottomNavLayout extends StatelessWidget {
  final int index;
  final List<Widget> pages;
  final List<_NavItem> navItems;
  final ValueChanged<int> onChanged;
  final VoidCallback onLogout;

  const _BottomNavLayout({
    required this.index,
    required this.pages,
    required this.navItems,
    required this.onChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, 'BANGJUN SPOT', onLogout: onLogout),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: _ClayPillBottomNav(
        currentIndex: index,
        onChanged: onChanged,
        items: navItems,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SIDEBAR LAYOUT (Tablet / Desktop)
// -----------------------------------------------------------------------------
class _SidebarLayout extends StatelessWidget {
  final int index;
  final List<Widget> pages;
  final List<_NavItem> navItems;
  final ValueChanged<int> onChanged;
  final VoidCallback onLogout;

  const _SidebarLayout({
    required this.index,
    required this.pages,
    required this.navItems,
    required this.onChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extended = constraints.maxWidth >= _kSidebarExtended;

        return Scaffold(
          body: Row(
            children: [
              _Sidebar(
                extended: extended,
                index: index,
                navItems: navItems,
                onChanged: onChanged,
                onLogout: onLogout,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.black.withAlpha(15),
              ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(navItems: navItems, index: index),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withAlpha(15),
                    ),
                    Expanded(
                      child: IndexedStack(index: index, children: pages),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool extended;
  final int index;
  final List<_NavItem> navItems;
  final ValueChanged<int> onChanged;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.extended,
    required this.index,
    required this.navItems,
    required this.onChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: extended ? 200 : 68,
      color: ClayColors.canvas,
      child: Column(
        children: [
          const SizedBox(height: 24),
          extended
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _logoIcon(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'BangJun\nSpot',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ClayColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(child: _logoIcon()),
          const SizedBox(height: 20),
          Divider(indent: 12, endIndent: 12, color: Colors.black.withAlpha(15)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final item = navItems[i];
                final active = i == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                          horizontal: extended ? 12 : 0,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? ClayColors.primary.withAlpha(28)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: extended
                            ? Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: active
                                        ? ClayColors.primary
                                        : ClayColors.textMuted,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? ClayColors.primary
                                          : ClayColors.textMuted,
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Tooltip(
                                  message: item.label,
                                  child: Icon(
                                    item.icon,
                                    size: 22,
                                    color: active
                                        ? ClayColors.primary
                                        : ClayColors.textMuted,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLogout,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: extended ? 12 : 0,
                    vertical: 11,
                  ),
                  child: extended
                      ? Row(
                          children: [
                            const SizedBox(width: 4),
                            Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Tooltip(
                            message: 'Logout',
                            child: Icon(
                              Icons.logout_rounded,
                              size: 22,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoIcon() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ClayColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.storefront_rounded,
            color: Colors.white, size: 18),
      );
}

class _TopBar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int index;
  const _TopBar({required this.navItems, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ClayColors.canvas,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            navItems[index].label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ClayColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (index == 1)
            Selector<CartProvider, int>(
              selector: (_, cart) => cart.totalItems,
              builder: (context, total, _) => total > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ClayColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$total item di keranjang',
                        style: TextStyle(
                          fontSize: 12,
                          color: ClayColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// KASIR HOME (role kasir)
// -----------------------------------------------------------------------------
class KasirHomePage extends StatelessWidget {
  const KasirHomePage({super.key});

  Future<void> _detectStoreLocation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;

    if (profile == null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Profil tidak ditemukan. Silakan login ulang.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final locationService = LocationService();
    try {
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Lokasi belum bisa dideteksi. Pastikan GPS aktif dan izin diberikan.',
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

      await locationService.saveStoreLocation(
        userId: profile.id,
        lat: position.latitude,
        lng: position.longitude,
      );
      await auth.loadProfile();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Lokasi tersimpan: '
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}',
          ),
          backgroundColor: ClayColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal deteksi lokasi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _LogoutDialog(),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
        context,
        'Kasir BANGJUN SPOT',
        onLogout: () => _confirmLogout(context),
        extra: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Deteksi Lokasi',
              onPressed: () => _detectStoreLocation(context),
              icon: const Icon(Icons.my_location_rounded),
              color: ClayColors.primary,
            ),
            IconButton(
              tooltip: 'Scan Barcode/QR',
              onPressed: () => _openBarcodeScanner(context),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              color: ClayColors.primary,
            ),
            Selector<CartProvider, int>(
              selector: (_, cart) => cart.totalItems,
              builder: (context, total, _) => total > 0
                  ? Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ClayColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$total item',
                        style: TextStyle(
                          fontSize: 12,
                          color: ClayColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const KasirPage(),
              ),
            );
          }
          return const KasirPage();
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared Widgets
// -----------------------------------------------------------------------------
class _LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Colors.red.shade400,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Logout'),
        ],
      ),
      content: const Text('Yakin ingin keluar dari aplikasi?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
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
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

AppBar _buildAppBar(
  BuildContext context,
  String title, {
  Widget? extra,
  VoidCallback? onLogout,
}) {
  return AppBar(
    title: Text(title),
    actions: [
      ?extra,
      IconButton(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded),
        tooltip: 'Logout',
      ),
    ],
  );
}

class _ClayPillBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<_NavItem> items;

  const _ClayPillBottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 380;
    final navHeight =
        (isNarrow ? 76.0 : 82.0) + MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: navHeight,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: ClayCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            elevation: ClayElevation.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final active = i == currentIndex;
                return Flexible(
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: active ? 8 : 6,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? ClayColors.primary.withAlpha(30)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: active
                                ? ClayColors.primary
                                : ClayColors.textMuted,
                          ),
                          if (!isNarrow)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) =>
                                  SizeTransition(
                                    sizeFactor: animation,
                                    axis: Axis.horizontal,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                              child: active
                                  ? Padding(
                                      key: ValueKey<String>(item.label),
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: ClayColors.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('empty'),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

Future<void> _openBarcodeScanner(BuildContext context) async {
  final productProvider = context.read<ProductProvider>();
  final cartProvider = context.read<CartProvider>();
  final products = productProvider.products;

  if (products.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Produk belum tersedia untuk dipindai'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BarcodeScannerSheet(
        products: products,
        onProductFound: (product) {
          cartProvider.addItem(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} ditambahkan via scan'),
              backgroundColor: ClayColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    ),
  );
}

