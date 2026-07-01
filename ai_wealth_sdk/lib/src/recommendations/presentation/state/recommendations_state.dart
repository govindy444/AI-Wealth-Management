import 'package:equatable/equatable.dart';

import '../../domain/entities/investment_product.dart';
import '../../domain/entities/recommendation.dart';

enum RecommendationsStatus { initial, loading, ready, error }

/// Immutable state for the recommendations screen.
class RecommendationsState extends Equatable {
  const RecommendationsState({
    this.status = RecommendationsStatus.initial,
    this.riskProfile = RiskProfile.moderate,
    this.amount = 100000,
    this.horizonYears = 5,
    this.recommendation,
    this.errorMessage,
  });

  final RecommendationsStatus status;
  final RiskProfile riskProfile;
  final double amount;
  final int horizonYears;
  final RecommendationSet? recommendation;
  final String? errorMessage;

  const RecommendationsState.initial() : this();

  bool get isLoading => status == RecommendationsStatus.loading;
  bool get hasData => recommendation != null;

  RecommendationsState copyWith({
    RecommendationsStatus? status,
    RiskProfile? riskProfile,
    double? amount,
    int? horizonYears,
    RecommendationSet? recommendation,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecommendationsState(
      status: status ?? this.status,
      riskProfile: riskProfile ?? this.riskProfile,
      amount: amount ?? this.amount,
      horizonYears: horizonYears ?? this.horizonYears,
      recommendation: recommendation ?? this.recommendation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, riskProfile, amount, horizonYears, recommendation, errorMessage];
}
