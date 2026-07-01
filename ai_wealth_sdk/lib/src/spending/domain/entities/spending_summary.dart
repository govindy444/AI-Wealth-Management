import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';
import 'transaction.dart';

/// Spend in a single category for the period.
class CategorySpend extends Equatable {
  const CategorySpend({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final SpendCategory category;
  final double amount;
  final double percentage; // share of total spend, 0–100

  @override
  List<Object?> get props => [category, amount, percentage];
}

/// Monthly spending summary with category breakdown, month-over-month trend, and
/// an explainable insight.
class SpendingSummary extends Equatable {
  const SpendingSummary({
    required this.month,
    required this.totalSpent,
    required this.totalIncome,
    required this.net,
    required this.previousMonthSpent,
    required this.changePct,
    required this.categories,
    required this.topMerchants,
    required this.insight,
  });

  final String month; // "YYYY-MM"
  final double totalSpent;
  final double totalIncome;
  final double net;
  final double previousMonthSpent;
  final double changePct; // +/- vs previous month
  final List<CategorySpend> categories;
  final List<String> topMerchants;
  final Explanation insight;

  bool get isUp => changePct >= 0;

  @override
  List<Object?> get props => [
        month,
        totalSpent,
        totalIncome,
        net,
        previousMonthSpent,
        changePct,
        categories,
        topMerchants,
        insight,
      ];
}
