import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/investment_product.dart';
import '../../domain/usecases/recommendation_usecases.dart';
import 'recommendations_state.dart';

/// Drives the recommendations screen: holds the inputs (risk profile, amount,
/// horizon) and fetches an explainable, risk-matched portfolio.
class RecommendationsController extends StateNotifier<RecommendationsState> {
  RecommendationsController({required RecommendUseCase recommend})
      : _recommend = recommend,
        super(const RecommendationsState.initial());

  final RecommendUseCase _recommend;

  /// Fetches a recommendation for the current (or overridden) inputs.
  Future<void> load({
    RiskProfile? riskProfile,
    double? amount,
    int? horizonYears,
  }) async {
    final profile = riskProfile ?? state.riskProfile;
    final amt = amount ?? state.amount;
    final horizon = horizonYears ?? state.horizonYears;

    state = state.copyWith(
      status: RecommendationsStatus.loading,
      riskProfile: profile,
      amount: amt,
      horizonYears: horizon,
      clearError: true,
    );

    final result = await _recommend(RecommendParams(
      riskProfile: profile,
      amount: amt,
      horizonYears: horizon,
    ));

    state = result.fold(
      (failure) => state.copyWith(
        status: RecommendationsStatus.error,
        errorMessage: failure.message,
      ),
      (set) => state.copyWith(
        status: RecommendationsStatus.ready,
        recommendation: set,
      ),
    );
  }

  /// Re-fetches for a newly selected risk profile.
  Future<void> selectProfile(RiskProfile profile) => load(riskProfile: profile);
}
