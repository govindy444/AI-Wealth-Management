import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/financial_health.dart';
import '../../domain/repositories/financial_health_repository.dart';
import '../datasources/financial_health_remote_datasource.dart';


class FinancialHealthRepositoryImpl
    with BaseRepository
    implements FinancialHealthRepository {
  FinancialHealthRepositoryImpl({
    required FinancialHealthRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final FinancialHealthRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<FinancialHealth> getScore() => guard(() => _remote.getScore());
}
