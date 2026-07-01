import 'package:equatable/equatable.dart';

/// Spending category. Wire values mirror the backend `SpendCategory` enum.
enum SpendCategory {
  groceries,
  dining,
  transport,
  utilities,
  shopping,
  entertainment,
  health,
  rent,
  income,
  transfer,
  other;

  String get wire => switch (this) {
        SpendCategory.groceries => 'groceries',
        SpendCategory.dining => 'dining',
        SpendCategory.transport => 'transport',
        SpendCategory.utilities => 'utilities',
        SpendCategory.shopping => 'shopping',
        SpendCategory.entertainment => 'entertainment',
        SpendCategory.health => 'health',
        SpendCategory.rent => 'rent',
        SpendCategory.income => 'income',
        SpendCategory.transfer => 'transfer',
        SpendCategory.other => 'other',
      };

  static SpendCategory fromWire(String value) => SpendCategory.values.firstWhere(
        (c) => c.wire == value,
        orElse: () => SpendCategory.other,
      );

  /// Human-readable label (Title Case).
  String get label => switch (this) {
        SpendCategory.groceries => 'Groceries',
        SpendCategory.dining => 'Dining',
        SpendCategory.transport => 'Transport',
        SpendCategory.utilities => 'Utilities',
        SpendCategory.shopping => 'Shopping',
        SpendCategory.entertainment => 'Entertainment',
        SpendCategory.health => 'Health',
        SpendCategory.rent => 'Rent',
        SpendCategory.income => 'Income',
        SpendCategory.transfer => 'Transfer',
        SpendCategory.other => 'Other',
      };
}

enum TransactionDirection {
  debit,
  credit;

  static TransactionDirection fromWire(String value) =>
      value == 'credit' ? TransactionDirection.credit : TransactionDirection.debit;
}

/// A single transaction.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.date,
    required this.merchant,
    required this.amount,
    required this.direction,
    required this.category,
  });

  final String id;
  final DateTime date;
  final String merchant;
  final double amount;
  final TransactionDirection direction;
  final SpendCategory category;

  bool get isDebit => direction == TransactionDirection.debit;

  @override
  List<Object?> get props => [id, date, merchant, amount, direction, category];
}
