import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/holding.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/portfolio_remote_datasource.dart';

/// Coordinates the portfolio API, mapping transport exceptions to [Failure]s via
/// [BaseRepository.guard].
class PortfolioRepositoryImpl with BaseRepository implements PortfolioRepository {
  PortfolioRepositoryImpl({
    required PortfolioRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final PortfolioRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<PortfolioSummary> getSummary() =>
      guard(() => _remote.getSummary());

  @override
  FutureResult<List<Holding>> getHoldings() =>
      guard(() => _remote.getHoldings());
}
