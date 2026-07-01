import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';
import 'holding.dart';

enum RiskLabel {
  low,
  moderate,
  high;

  static RiskLabel fromWire(String value) => switch (value) {
        'high' => RiskLabel.high,
        'moderate' => RiskLabel.moderate,
        _ => RiskLabel.low,
      };

  String get label => switch (this) {
        RiskLabel.low => 'Low',
        RiskLabel.moderate => 'Moderate',
        RiskLabel.high => 'High',
      };
}

/// One asset-class slice of the allocation.
class AllocationSlice extends Equatable {
  const AllocationSlice({
    required this.assetClass,
    required this.percentage,
    required this.value,
  });

  final AssetClass assetClass;
  final double percentage;
  final double value;

  @override
  List<Object?> get props => [assetClass, percentage, value];
}

/// Portfolio value, performance, allocation, and risk/diversification scores.
class PortfolioSummary extends Equatable {
  const PortfolioSummary({
    required this.totalValue,
    required this.totalInvested,
    required this.totalGain,
    required this.gainPct,
    required this.riskScore,
    required this.riskLabel,
    required this.diversificationScore,
    required this.allocation,
    required this.topHoldings,
    required this.insight,
  });

  final double totalValue;
  final double totalInvested;
  final double totalGain;
  final double gainPct;
  final int riskScore; // 0–100
  final RiskLabel riskLabel;
  final int diversificationScore; // 0–100
  final List<AllocationSlice> allocation;
  final List<Holding> topHoldings;
  final Explanation insight;

  bool get isUp => totalGain >= 0;

  @override
  List<Object?> get props => [
        totalValue,
        totalInvested,
        totalGain,
        gainPct,
        riskScore,
        riskLabel,
        diversificationScore,
        allocation,
        topHoldings,
        insight,
      ];
}
