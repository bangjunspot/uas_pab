class TransactionRecord {
  final String id;
  final String cashierId;
  final String? shiftId;
  final double total;
  final DateTime? createdAt;

  TransactionRecord({
    required this.id,
    required this.cashierId,
    this.shiftId,
    required this.total,
    required this.createdAt,
  });

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'].toString(),
      cashierId: map['cashier_id'].toString(),
      shiftId: map['shift_id']?.toString(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}
