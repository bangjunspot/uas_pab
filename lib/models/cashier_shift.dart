class CashierShift {
  final String id;
  final String cashierId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double? closingCash;
  final double expectedCash;
  final double? cashDifference;
  final String? note;

  const CashierShift({
    required this.id,
    required this.cashierId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    required this.expectedCash,
    this.cashDifference,
    this.note,
  });

  bool get isOpen => closedAt == null;

  factory CashierShift.fromMap(Map<String, dynamic> map) {
    return CashierShift(
      id: map['id'].toString(),
      cashierId: map['cashier_id'].toString(),
      openedAt:
          DateTime.tryParse((map['opened_at'] ?? '').toString()) ??
          DateTime.now(),
      closedAt: map['closed_at'] == null
          ? null
          : DateTime.tryParse(map['closed_at'].toString()),
      openingCash: (map['opening_cash'] as num?)?.toDouble() ?? 0,
      closingCash: (map['closing_cash'] as num?)?.toDouble(),
      expectedCash: (map['expected_cash'] as num?)?.toDouble() ?? 0,
      cashDifference: (map['cash_difference'] as num?)?.toDouble(),
      note: map['note']?.toString(),
    );
  }
}
