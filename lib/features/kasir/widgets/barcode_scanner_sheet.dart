import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../models/product.dart';
import '../../../theme/clay_colors.dart';
import '../../../widgets/clay_button.dart';
import '../../../widgets/clay_card.dart';

class BarcodeScannerSheet extends StatefulWidget {
  final List<Product> products;
  final void Function(Product product) onProductFound;

  const BarcodeScannerSheet({
    super.key,
    required this.products,
    required this.onProductFound,
  });

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandled = false;
  String? _lastInvalidCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Proses hasil scan barcode/QR satu kali per sesi.
  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isHandled) return;

    final rawCode = capture.barcodes.first.rawValue?.trim();
    if (rawCode == null || rawCode.isEmpty) return;

    final product = _findProductById(rawCode);
    if (product == null) {
      if (_lastInvalidCode == rawCode) return;
      _lastInvalidCode = rawCode;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk tidak ditemukan untuk kode: $rawCode'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    _isHandled = true;
    await _controller.stop();
    if (!mounted) return;

    widget.onProductFound(product);
    Navigator.of(context).pop();
  }

  /// Cari produk berdasarkan ID yang terbaca dari kamera.
  Product? _findProductById(String code) {
    for (final product in widget.products) {
      if (product.id == code) {
        return product;
      }
    }
    return null;
  }

  /// Tutup scanner secara manual oleh user.
  void _closeScanner() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _handleDetect,
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  ClayButton(
                    label: 'Tutup',
                    onPressed: _closeScanner,
                  ),
                  const Spacer(),
                  ClayCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: const Text(
                      'Arahkan kamera ke barcode/QR produk',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: ClayCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: ClayColors.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan sekali untuk menambahkan produk ke keranjang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ClayColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kode harus sama dengan ID produk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ClayColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
