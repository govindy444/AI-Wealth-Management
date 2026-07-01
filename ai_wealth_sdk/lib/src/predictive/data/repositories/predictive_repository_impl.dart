import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/forecast.dart';
import '../../domain/repositories/predictive_repository.dart';
import '../datasources/predictive_remote_datasource.dart';

/// Coordinates the predictive API, mapping transport exceptions to [Failure]s via
/// [BaseRepository.guard].
class PredictiveRepositoryImpl with BaseRepository implements PredictiveRepository {
  PredictiveRepositoryImpl({
    required PredictiveRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final PredictiveRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<Forecast> getForecast() => guard(() => _remote.getForecast());
}
