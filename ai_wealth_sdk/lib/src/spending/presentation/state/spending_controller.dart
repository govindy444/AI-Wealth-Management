import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/usecases/spending_usecases.dart';
import 'spending_state.dart';

/// Drives the spending analytics screen: loads the monthly summary and budgets,
/// and applies budget edits.
class SpendingController extends StateNotifier<SpendingState> {
  SpendingController({
    required GetSpendingSummaryUseCase getSummary,
    required GetBudgetsUseCase getBudgets,
    required SetBudgetUseCase setBudget,
  })  : _getSummary = getSummary,
        _getBudgets = getBudgets,
        _setBudget = setBudget,
        super(const SpendingState.initial());

  final GetSpendingSummaryUseCase _getSummary;
  final GetBudgetsUseCase _getBudgets;
  final SetBudgetUseCase _setBudget;

  String? _month;

  /// Loads the summary and budgets for [month] (null = current month).
  Future<void> load({String? month}) async {
    _month = month;
    state = state.copyWith(status: SpendingStatus.loading, clearError: true);

    final summaryResult = await _getSummary(SpendingMonthParams(month: month));
    final summary = summaryResult.fold((_) => null, (s) => s);
    if (summary == null) {
      state = state.copyWith(
        status: SpendingStatus.error,
        errorMessage: summaryResult.fold((f) => f.message, (_) => null),
      );
      return;
    }

    final budgetsResult = await _getBudgets(SpendingMonthParams(month: month));
    state = state.copyWith(
      status: SpendingStatus.ready,
      summary: summary,
      budgets: budgetsResult.fold((_) => state.budgets, (b) => b),
    );
  }

  Future<void> refresh() => load(month: _month);

  /// Updates a category budget and refreshes the budget list.
  Future<bool> setBudget(SpendCategory category, double monthlyLimit) async {
    final result = await _setBudget(
      SetBudgetParams(category: category, monthlyLimit: monthlyLimit),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (updated) {
        final next = [
          for (final b in state.budgets)
            if (b.category == updated.category) updated else b,
        ];
        // Add it if it wasn't already in the list.
        if (!next.any((b) => b.category == updated.category)) next.add(updated);
        state = state.copyWith(budgets: next);
        return true;
      },
    );
  }
}
