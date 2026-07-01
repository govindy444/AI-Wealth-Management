import 'package:equatable/equatable.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/budget.dart';
import '../entities/spending_summary.dart';
import '../entities/transaction.dart';
import '../repositories/spending_repository.dart';

class SpendingMonthParams extends Equatable {
  const SpendingMonthParams({this.month});
  final String? month; // "YYYY-MM"; null = current month

  @override
  List<Object?> get props => [month];
}

class GetSpendingSummaryUseCase
    implements UseCase<SpendingSummary, SpendingMonthParams> {
  GetSpendingSummaryUseCase(this._repository);
  final SpendingRepository _repository;

  @override
  FutureResult<SpendingSummary> call(SpendingMonthParams params) =>
      _repository.getSummary(month: params.month);
}

class GetBudgetsUseCase implements UseCase<List<Budget>, SpendingMonthParams> {
  GetBudgetsUseCase(this._repository);
  final SpendingRepository _repository;

  @override
  FutureResult<List<Budget>> call(SpendingMonthParams params) =>
      _repository.getBudgets(month: params.month);
}

class GetTransactionsParams extends Equatable {
  const GetTransactionsParams({
    this.month,
    this.category,
    this.limit = 50,
    this.offset = 0,
  });
  final String? month;
  final SpendCategory? category;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [month, category, limit, offset];
}

class GetTransactionsUseCase
    implements UseCase<Paginated<Transaction>, GetTransactionsParams> {
  GetTransactionsUseCase(this._repository);
  final SpendingRepository _repository;

  @override
  FutureResult<Paginated<Transaction>> call(GetTransactionsParams params) =>
      _repository.getTransactions(
        month: params.month,
        category: params.category,
        limit: params.limit,
        offset: params.offset,
      );
}

class SetBudgetParams extends Equatable {
  const SetBudgetParams({required this.category, required this.monthlyLimit});
  final SpendCategory category;
  final double monthlyLimit;

  @override
  List<Object?> get props => [category, monthlyLimit];
}

class SetBudgetUseCase implements UseCase<Budget, SetBudgetParams> {
  SetBudgetUseCase(this._repository);
  final SpendingRepository _repository;

  @override
  FutureResult<Budget> call(SetBudgetParams params) => _repository.setBudget(
        category: params.category,
        monthlyLimit: params.monthlyLimit,
      );
}
