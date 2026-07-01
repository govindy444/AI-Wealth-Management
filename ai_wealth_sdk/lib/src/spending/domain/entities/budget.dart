import 'package:equatable/equatable.dart';

import 'transaction.dart';

enum BudgetStatus {
  under,
  near,
  over;

  static BudgetStatus fromWire(String value) => switch (value) {
        'over' => BudgetStatus.over,
        'near' => BudgetStatus.near,
        _ => BudgetStatus.under,
      };
}

/// A category budget with this month's progress.
class Budget extends Equatable {
  const Budget({
    required this.category,
    required this.monthlyLimit,
    required this.spent,
    required this.remaining,
    required this.usedPct,
    required this.status,
  });

  final SpendCategory category;
  final double monthlyLimit;
  final double spent;
  final double remaining;
  final double usedPct;
  final BudgetStatus status;

  @override
  List<Object?> get props =>
      [category, monthlyLimit, spent, remaining, usedPct, status];
}
