import '../../../core/domain/explainability.dart';
import '../../domain/entities/investment_product.dart';
import '../../domain/entities/recommendation.dart';

/// Wire decoders for the recommendation endpoints.
class RecommendationDtos {
  const RecommendationDtos._();

  static InvestmentProduct productFromJson(Map<String, dynamic> j) =>
      InvestmentProduct(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        type: ProductType.fromWire((j['type'] as String?) ?? ''),
        riskLevel: RiskLevel.fromWire((j['risk_level'] as String?) ?? 'moderate'),
        expectedReturn: _d(j['expected_return']),
        minInvestment: _d(j['min_investment']),
        description: (j['description'] as String?) ?? '',
        tags: (j['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
      );

  static Recommendation recommendationFromJson(Map<String, dynamic> j) {
    final rationale = j['rationale'];
    return Recommendation(
      product: productFromJson(
        (j['product'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      allocationPct: _d(j['allocation_pct']),
      suggestedAmount: _d(j['suggested_amount']),
      rationale: rationale is Map<String, dynamic>
          ? Explanation.fromJson(rationale)
          : const Explanation(summary: ''),
    );
  }

  static RecommendationSet setFromJson(Map<String, dynamic> j) {
    final insight = j['insight'];
    return RecommendationSet(
      riskProfile: RiskProfile.fromWire((j['risk_profile'] as String?) ?? 'moderate'),
      totalAmount: _d(j['total_amount']),
      horizonYears: (j['horizon_years'] as num?)?.toInt() ?? 5,
      blendedExpectedReturn: _d(j['blended_expected_return']),
      recommendations: (j['recommendations'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(recommendationFromJson)
          .toList(growable: false),
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}
