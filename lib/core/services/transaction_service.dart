import '../services/supabase_service.dart';
import '../../models/transaction.dart';

class TransactionService {
  final _supabase = SupabaseService();

  Future<String> createTransaction({
    required String cashierId,
    String? shiftId,
    required double total,
  }) async {
    final data = await _supabase.client
        .from('transactions')
        .insert({'cashier_id': cashierId, 'shift_id': shiftId, 'total': total})
        .select('id')
        .single();
    return data['id'].toString();
  }

  Future<void> createTransactionItems({
    required String transactionId,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = items
        .map(
          (item) => {
            'transaction_id': transactionId,
            'product_id': item['product_id'],
            'qty': item['qty'],
            'price': item['price'],
          },
        )
        .toList();
    await _supabase.client.from('transaction_items').insert(payload);
  }

  Future<void> createStockOutMovements({
    required String transactionId,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = items
        .map(
          (item) => {
            'product_id': item['product_id'],
            'qty': item['qty'],
            'type': 'out',
            'note': 'Transaksi #$transactionId',
          },
        )
        .toList();

    if (payload.isEmpty) return;
    await _supabase.client.from('stock_movements').insert(payload);
  }

  Future<List<TransactionRecord>> fetchTransactions() async {
    final data = await _supabase.client
        .from('transactions')
        .select('id,total,created_at,cashier_id,shift_id')
        .order('created_at', ascending: false);
    return (data as List)
        .map((item) => TransactionRecord.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
