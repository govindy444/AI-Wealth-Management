import '../../../core/network/api_response.dart';
import '../../../core/utils/result.dart';
import '../entities/budget.dart';
import '../entities/spending_summary.dart';
import '../entities/transaction.dart';

/// Spending Analytics repository contract. Implemented in the data layer;
/// consumed by use-cases. Returns [Result] so callers handle failures as values.
abstract interface class SpendingRepository {
  /// Monthly summary (category breakdown, trend, insight). [month] is "YYYY-MM";
  /// null means the current month.
  FutureResult<SpendingSummary> getSummary({String? month});

  /// Paginated, optionally category-filtered transactions for a month.
  FutureResult<Paginated<Transaction>> getTransactions({
    String? month,
    SpendCategory? category,
    int limit = 50,
    int offset = 0,
  });

  /// Category budgets with the month's progress.
  FutureResult<List<Budget>> getBudgets({String? month});

  /// Sets/updates a category's monthly budget limit.
  FutureResult<Budget> setBudget({
    required SpendCategory category,
    required double monthlyLimit,
  });
}
