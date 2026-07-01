import '../../../core/utils/result.dart';
import '../entities/investment_product.dart';
import '../entities/recommendation.dart';

/// Investment Recommendation repository contract.
abstract interface class RecommendationRepository {
  /// The available product shelf.
  FutureResult<List<InvestmentProduct>> listProducts();

  /// An explainable, risk-matched portfolio recommendation.
  FutureResult<RecommendationSet> recommend({
    required RiskProfile riskProfile,
    double amount,
    int horizonYears,
  });
}
