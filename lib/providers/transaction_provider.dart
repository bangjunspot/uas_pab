import 'package:flutter/material.dart';
import '../core/services/transaction_service.dart';
import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _service = TransactionService();
  List<TransactionRecord> transactions = [];
  bool isLoading = false;
  String? error;

  double todayTotal = 0;
  double monthTotal = 0;
  List<MapEntry<DateTime, double>> last7Days = [];
  List<MapEntry<DateTime, double>> monthDays = [];

  // Monthly filter state
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Per-month totals for the whole year (index 0 = Jan, 11 = Dec)
  List<double> yearlyMonthTotals = List.filled(12, 0);

  // Daily breakdown of the selected month (after filter)
  List<MapEntry<DateTime, double>> filteredMonthDays = [];
  double filteredMonthTotal = 0;

  static const List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ags',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  Future<void> loadTransactions() async {
    _setLoading(true);
    error = null;
    try {
      transactions = await _service.fetchTransactions();
      _computeSummaries();
    } catch (e) {
      error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> createTransaction({
    required String cashierId,
    String? shiftId,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    error = null;
    if (items.isEmpty) {
      throw Exception('Keranjang kosong');
    }

    final transactionId = await _service.createTransaction(
      cashierId: cashierId,
      shiftId: shiftId,
      total: total,
    );
    await _service.createTransactionItems(
      transactionId: transactionId,
      items: items,
    );
    await _service.createStockOutMovements(
      transactionId: transactionId,
      items: items,
    );
    await loadTransactions();
    return transactionId;
  }

  void setMonthFilter(int month, int year) {
    selectedMonth = month;
    selectedYear = year;
    _computeFilteredMonth();
    notifyListeners();
  }

  void _computeSummaries() {
    final now = DateTime.now();

    todayTotal = transactions
        .where((t) {
          final d = t.createdAt;
          if (d == null) return false;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        })
        .fold<double>(0, (sum, t) => sum + t.total);

    monthTotal = transactions
        .where((t) {
          final d = t.createdAt;
          if (d == null) return false;
          return d.year == now.year && d.month == now.month;
        })
        .fold<double>(0, (sum, t) => sum + t.total);

    last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final total = transactions
          .where((t) {
            final d = t.createdAt;
            if (d == null) return false;
            return d.year == date.year &&
                d.month == date.month &&
                d.day == date.day;
          })
          .fold<double>(0, (sum, t) => sum + t.total);
      return MapEntry(date, total);
    });

    monthDays = List.generate(now.day, (i) {
      final date = DateTime(now.year, now.month, i + 1);
      final total = transactions
          .where((t) {
            final d = t.createdAt;
            if (d == null) return false;
            return d.year == date.year &&
                d.month == date.month &&
                d.day == date.day;
          })
          .fold<double>(0, (sum, t) => sum + t.total);
      return MapEntry(date, total);
    });

    // Yearly monthly totals (current year)
    yearlyMonthTotals = List.generate(12, (m) {
      return transactions
          .where((t) {
            final d = t.createdAt;
            if (d == null) return false;
            return d.year == now.year && d.month == (m + 1);
          })
          .fold<double>(0, (sum, t) => sum + t.total);
    });

    _computeFilteredMonth();
  }

  void _computeFilteredMonth() {
    // How many days in selectedMonth/selectedYear
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    filteredMonthDays = List.generate(daysInMonth, (i) {
      final date = DateTime(selectedYear, selectedMonth, i + 1);
      final total = transactions
          .where((t) {
            final d = t.createdAt;
            if (d == null) return false;
            return d.year == date.year &&
                d.month == date.month &&
                d.day == date.day;
          })
          .fold<double>(0, (sum, t) => sum + t.total);
      return MapEntry(date, total);
    });

    filteredMonthTotal = filteredMonthDays.fold(0, (s, e) => s + e.value);
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
