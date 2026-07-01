import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/spending_summary.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/spending_repository.dart';
import '../datasources/spending_remote_datasource.dart';

/// Coordinates the spending API, mapping transport exceptions to [Failure]s via
/// [BaseRepository.guard].
class SpendingRepositoryImpl with BaseRepository implements SpendingRepository {
  SpendingRepositoryImpl({
    required SpendingRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final SpendingRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<SpendingSummary> getSummary({String? month}) =>
      guard(() => _remote.getSummary(month: month));

  @override
  FutureResult<Paginated<Transaction>> getTransactions({
    String? month,
    SpendCategory? category,
    int limit = 50,
    int offset = 0,
  }) =>
      guard(() => _remote.getTransactions(
            month: month,
            category: category,
            limit: limit,
            offset: offset,
          ));

  @override
  FutureResult<List<Budget>> getBudgets({String? month}) =>
      guard(() => _remote.getBudgets(month: month));

  @override
  FutureResult<Budget> setBudget({
    required SpendCategory category,
    required double monthlyLimit,
  }) =>
      guard(() => _remote.setBudget(category: category, monthlyLimit: monthlyLimit));
}
