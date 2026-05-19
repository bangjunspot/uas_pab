import 'package:flutter/material.dart';
import '../core/services/cashier_shift_service.dart';
import '../models/cashier_shift.dart';

class CashierShiftProvider extends ChangeNotifier {
  final CashierShiftService _service = CashierShiftService();

  CashierShift? activeShift;
  List<CashierShift> recentShifts = [];
  double shiftSalesTotal = 0;
  int shiftTransactionCount = 0;
  bool isLoading = false;
  String? error;

  double get expectedCash => (activeShift?.openingCash ?? 0) + shiftSalesTotal;

  Future<void> load(String cashierId) async {
    _setLoading(true);
    error = null;
    try {
      activeShift = await _service.fetchActiveShift(cashierId);
      recentShifts = await _service.fetchRecent(cashierId);
      if (activeShift == null) {
        shiftSalesTotal = 0;
        shiftTransactionCount = 0;
      } else {
        final summary = await _service.fetchShiftSummary(activeShift!.id);
        shiftSalesTotal = summary.$1;
        shiftTransactionCount = summary.$2;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> open({
    required String cashierId,
    required double openingCash,
  }) async {
    _setLoading(true);
    error = null;
    try {
      activeShift = await _service.openShift(
        cashierId: cashierId,
        openingCash: openingCash,
      );
      shiftSalesTotal = 0;
      shiftTransactionCount = 0;
      await load(cashierId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> close({required double closingCash, String? note}) async {
    final shift = activeShift;
    if (shift == null) {
      error = 'Belum ada shift aktif.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    error = null;
    try {
      await _service.closeShift(
        shiftId: shift.id,
        closingCash: closingCash,
        expectedCash: expectedCash,
        note: note,
      );
      await load(shift.cashierId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
