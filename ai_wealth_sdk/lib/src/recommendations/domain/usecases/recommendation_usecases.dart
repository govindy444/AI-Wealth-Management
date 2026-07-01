import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/investment_product.dart';
import '../entities/recommendation.dart';
import '../repositories/recommendation_repository.dart';

class ListProductsUseCase implements UseCase<List<InvestmentProduct>, NoParams> {
  ListProductsUseCase(this._repository);
  final RecommendationRepository _repository;

  @override
  FutureResult<List<InvestmentProduct>> call(NoParams params) =>
      _repository.listProducts();
}

class RecommendParams extends Equatable {
  const RecommendParams({
    this.riskProfile = RiskProfile.moderate,
    this.amount = 100000,
    this.horizonYears = 5,
  });

  final RiskProfile riskProfile;
  final double amount;
  final int horizonYears;

  @override
  List<Object?> get props => [riskProfile, amount, horizonYears];
}

class RecommendUseCase implements UseCase<RecommendationSet, RecommendParams> {
  RecommendUseCase(this._repository);
  final RecommendationRepository _repository;

  @override
  FutureResult<RecommendationSet> call(RecommendParams p) => _repository.recommend(
        riskProfile: p.riskProfile,
        amount: p.amount,
        horizonYears: p.horizonYears,
      );
}
