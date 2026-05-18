import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir_pab/core/utils/currency_formatter.dart';

void main() {
  test('formatRupiah mengembalikan format Rp tanpa desimal', () {
    expect(formatRupiah(15000), 'Rp 15.000');
    expect(formatRupiah(1234.56), 'Rp 1.235');
  });
}
