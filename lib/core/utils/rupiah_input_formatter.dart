import 'package:flutter/services.dart';

/// TextInputFormatter yang memformat angka ke ribuan Rupiah (tanpa simbol).
/// Contoh ketikan "10000" → tampil "10.000" (separator titik ala id_ID)
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip semua non-digit
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    final number = int.tryParse(digits) ?? 0;
    final formatted = formatNumber(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Format angka ke string ribuan pakai titik (id_ID)
  /// Contoh: 10000 → "10.000"
  static String formatNumber(int value) {
    if (value == 0) return '0';
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  /// Parse formatted string kembali ke double.
  /// Contoh: "10.000" → 10000.0
  static double parse(String formatted) {
    final raw = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(raw) ?? 0;
  }
}
