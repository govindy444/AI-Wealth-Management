import '../../../core/domain/explainability.dart';
import '../../domain/entities/holding.dart';
import '../../domain/entities/portfolio_summary.dart';

/// Wire decoders for the portfolio endpoints.
class PortfolioDtos {
  const PortfolioDtos._();

  static Holding holdingFromJson(Map<String, dynamic> j) => Holding(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        assetClass: AssetClass.fromWire((j['asset_class'] as String?) ?? 'cash'),
        invested: _d(j['invested']),
        currentValue: _d(j['current_value']),
        gain: _d(j['gain']),
        gainPct: _d(j['gain_pct']),
      );

  static AllocationSlice sliceFromJson(Map<String, dynamic> j) => AllocationSlice(
        assetClass: AssetClass.fromWire((j['asset_class'] as String?) ?? 'cash'),
        percentage: _d(j['percentage']),
        value: _d(j['value']),
      );

  static PortfolioSummary summaryFromJson(Map<String, dynamic> j) {
    final insight = j['insight'];
    return PortfolioSummary(
      totalValue: _d(j['total_value']),
      totalInvested: _d(j['total_invested']),
      totalGain: _d(j['total_gain']),
      gainPct: _d(j['gain_pct']),
      riskScore: (j['risk_score'] as num?)?.toInt() ?? 0,
      riskLabel: RiskLabel.fromWire((j['risk_label'] as String?) ?? 'low'),
      diversificationScore: (j['diversification_score'] as num?)?.toInt() ?? 0,
      allocation: (j['allocation'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(sliceFromJson)
          .toList(growable: false),
      topHoldings: (j['top_holdings'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(holdingFromJson)
          .toList(growable: false),
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}
