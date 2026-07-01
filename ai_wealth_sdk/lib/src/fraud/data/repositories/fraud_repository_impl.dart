import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/fraud_reports.dart';
import '../../domain/repositories/fraud_repository.dart';
import '../datasources/fraud_remote_datasource.dart';


class FraudRepositoryImpl with BaseRepository implements FraudRepository {
  FraudRepositoryImpl({
    required FraudRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final FraudRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<FraudAlerts> getAlerts() => guard(() => _remote.getAlerts());

  @override
  FutureResult<MessageCheck> checkMessage(String text) =>
      guard(() => _remote.checkMessage(text));
}
