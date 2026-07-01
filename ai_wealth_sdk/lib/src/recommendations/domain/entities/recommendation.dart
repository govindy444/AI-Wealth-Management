import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';
import 'investment_product.dart';

/// One product recommendation with its weight, suggested amount, and an
/// Explainable-AI rationale.
class Recommendation extends Equatable {
  const Recommendation({
    required this.product,
    required this.allocationPct,
    required this.suggestedAmount,
    required this.rationale,
  });

  final InvestmentProduct product;
  final double allocationPct;
  final double suggestedAmount;
  final Explanation rationale;

  @override
  List<Object?> get props =>
      [product, allocationPct, suggestedAmount, rationale];
}

/// A complete risk-matched portfolio recommendation.
class RecommendationSet extends Equatable {
  const RecommendationSet({
    required this.riskProfile,
    required this.totalAmount,
    required this.horizonYears,
    required this.blendedExpectedReturn,
    required this.recommendations,
    required this.insight,
  });

  final RiskProfile riskProfile;
  final double totalAmount;
  final int horizonYears;
  final double blendedExpectedReturn; // annual, decimal
  final List<Recommendation> recommendations;
  final Explanation insight;

  @override
  List<Object?> get props => [
        riskProfile,
        totalAmount,
        horizonYears,
        blendedExpectedReturn,
        recommendations,
        insight,
      ];
}
