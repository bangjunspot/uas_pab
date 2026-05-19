import '../services/supabase_service.dart';
import '../../models/cashier_shift.dart';

class CashierShiftService {
  final _supabase = SupabaseService();

  Future<CashierShift?> fetchActiveShift(String cashierId) async {
    final data = await _supabase.client
        .from('cashier_shifts')
        .select()
        .eq('cashier_id', cashierId)
        .filter('closed_at', 'is', null)
        .order('opened_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return CashierShift.fromMap(data);
  }

  Future<List<CashierShift>> fetchRecent(String cashierId) async {
    final data = await _supabase.client
        .from('cashier_shifts')
        .select()
        .eq('cashier_id', cashierId)
        .order('opened_at', ascending: false)
        .limit(10);

    return (data as List)
        .map((item) => CashierShift.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<CashierShift> openShift({
    required String cashierId,
    required double openingCash,
  }) async {
    final data = await _supabase.client
        .from('cashier_shifts')
        .insert({
          'cashier_id': cashierId,
          'opening_cash': openingCash,
          'expected_cash': openingCash,
        })
        .select()
        .single();

    return CashierShift.fromMap(data);
  }

  Future<(double, int)> fetchShiftSummary(String shiftId) async {
    final data = await _supabase.client
        .from('transactions')
        .select('total')
        .eq('shift_id', shiftId);

    final items = data as List;
    final total = items.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );
    return (total, items.length);
  }

  Future<CashierShift> closeShift({
    required String shiftId,
    required double closingCash,
    required double expectedCash,
    String? note,
  }) async {
    final data = await _supabase.client
        .from('cashier_shifts')
        .update({
          'closed_at': DateTime.now().toIso8601String(),
          'closing_cash': closingCash,
          'expected_cash': expectedCash,
          'cash_difference': closingCash - expectedCash,
          'note': note,
        })
        .eq('id', shiftId)
        .select()
        .single();

    return CashierShift.fromMap(data);
  }
}
