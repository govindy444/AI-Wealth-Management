import '../../../core/domain/explainability.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/spending_summary.dart';
import '../../domain/entities/transaction.dart';

/// Wire decoders for the spending endpoints.
class SpendingDtos {
  const SpendingDtos._();

  static Transaction transactionFromJson(Map<String, dynamic> j) => Transaction(
        id: (j['id'] as String?) ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        merchant: (j['merchant'] as String?) ?? '',
        amount: _toDouble(j['amount']),
        direction: TransactionDirection.fromWire((j['direction'] as String?) ?? 'debit'),
        category: SpendCategory.fromWire((j['category'] as String?) ?? 'other'),
      );

  static SpendingSummary summaryFromJson(Map<String, dynamic> j) {
    final insight = j['insight'];
    return SpendingSummary(
      month: (j['month'] as String?) ?? '',
      totalSpent: _toDouble(j['total_spent']),
      totalIncome: _toDouble(j['total_income']),
      net: _toDouble(j['net']),
      previousMonthSpent: _toDouble(j['previous_month_spent']),
      changePct: _toDouble(j['change_pct']),
      categories: (j['categories'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_categoryFromJson)
          .toList(growable: false),
      topMerchants:
          (j['top_merchants'] as List? ?? const []).map((e) => e.toString()).toList(),
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static Budget budgetFromJson(Map<String, dynamic> j) => Budget(
        category: SpendCategory.fromWire((j['category'] as String?) ?? 'other'),
        monthlyLimit: _toDouble(j['monthly_limit']),
        spent: _toDouble(j['spent']),
        remaining: _toDouble(j['remaining']),
        usedPct: _toDouble(j['used_pct']),
        status: BudgetStatus.fromWire((j['status'] as String?) ?? 'under'),
      );

  static CategorySpend _categoryFromJson(Map<String, dynamic> j) => CategorySpend(
        category: SpendCategory.fromWire((j['category'] as String?) ?? 'other'),
        amount: _toDouble(j['amount']),
        percentage: _toDouble(j['percentage']),
      );

  static double _toDouble(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}
