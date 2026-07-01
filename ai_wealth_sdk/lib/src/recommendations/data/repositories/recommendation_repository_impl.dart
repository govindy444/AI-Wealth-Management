import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/investment_product.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/recommendation_remote_datasource.dart';

/// Coordinates the recommendations API, mapping transport exceptions to
/// [Failure]s via [BaseRepository.guard].
class RecommendationRepositoryImpl
    with BaseRepository
    implements RecommendationRepository {
  RecommendationRepositoryImpl({
    required RecommendationRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final RecommendationRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<List<InvestmentProduct>> listProducts() =>
      guard(() => _remote.listProducts());

  @override
  FutureResult<RecommendationSet> recommend({
    required RiskProfile riskProfile,
    double amount = 100000,
    int horizonYears = 5,
  }) =>
      guard(() => _remote.recommend(
            riskProfile: riskProfile.wire,
            amount: amount,
            horizonYears: horizonYears,
          ));
}
