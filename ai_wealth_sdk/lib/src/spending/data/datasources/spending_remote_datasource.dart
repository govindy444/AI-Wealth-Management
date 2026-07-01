import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/spending_summary.dart';
import '../../domain/entities/transaction.dart';
import '../models/spending_dtos.dart';

/// Talks to the backend `/spending` endpoints via the transport-agnostic
/// [ApiClient].
abstract interface class SpendingRemoteDataSource {
  Future<SpendingSummary> getSummary({String? month});
  Future<Paginated<Transaction>> getTransactions({
    String? month,
    SpendCategory? category,
    int limit,
    int offset,
  });
  Future<List<Budget>> getBudgets({String? month});
  Future<Budget> setBudget({
    required SpendCategory category,
    required double monthlyLimit,
  });
}

class SpendingRemoteDataSourceImpl implements SpendingRemoteDataSource {
  SpendingRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<SpendingSummary> getSummary({String? month}) async {
    final res = await _client.get(
      '/spending/summary',
      queryParameters: {if (month != null) 'month': month},
    );
    return SpendingDtos.summaryFromJson(res.asMap);
  }

  @override
  Future<Paginated<Transaction>> getTransactions({
    String? month,
    SpendCategory? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client.get(
      '/spending/transactions',
      queryParameters: {
        if (month != null) 'month': month,
        if (category != null) 'category': category.wire,
        'limit': limit,
        'offset': offset,
      },
    );
    return Paginated.fromJson(res.asMap, SpendingDtos.transactionFromJson);
  }

  @override
  Future<List<Budget>> getBudgets({String? month}) async {
    final res = await _client.get(
      '/spending/budgets',
      queryParameters: {if (month != null) 'month': month},
    );
    return res.asList
        .cast<Map<String, dynamic>>()
        .map(SpendingDtos.budgetFromJson)
        .toList(growable: false);
  }

  @override
  Future<Budget> setBudget({
    required SpendCategory category,
    required double monthlyLimit,
  }) async {
    final res = await _client.put(
      '/spending/budgets/${category.wire}',
      data: {'monthly_limit': monthlyLimit},
    );
    return SpendingDtos.budgetFromJson(res.asMap);
  }
}
