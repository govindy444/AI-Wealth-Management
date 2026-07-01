import 'package:equatable/equatable.dart';

enum RiskProfile {
  conservative,
  moderate,
  aggressive;

  String get wire => name;
  String get label => switch (this) {
        RiskProfile.conservative => 'Conservative',
        RiskProfile.moderate => 'Moderate',
        RiskProfile.aggressive => 'Aggressive',
      };

  static RiskProfile fromWire(String value) => RiskProfile.values.firstWhere(
        (p) => p.name == value,
        orElse: () => RiskProfile.moderate,
      );
}

enum RiskLevel {
  low,
  moderate,
  high;

  static RiskLevel fromWire(String value) => switch (value) {
        'low' => RiskLevel.low,
        'high' => RiskLevel.high,
        _ => RiskLevel.moderate,
      };
}

enum ProductType {
  indexFund,
  equityFund,
  elss,
  debtFund,
  hybridFund,
  fixedDeposit,
  gold;

  static ProductType fromWire(String value) => switch (value) {
        'index_fund' => ProductType.indexFund,
        'equity_fund' => ProductType.equityFund,
        'elss' => ProductType.elss,
        'debt_fund' => ProductType.debtFund,
        'hybrid_fund' => ProductType.hybridFund,
        'fixed_deposit' => ProductType.fixedDeposit,
        'gold' => ProductType.gold,
        _ => ProductType.hybridFund,
      };

  String get label => switch (this) {
        ProductType.indexFund => 'Index Fund',
        ProductType.equityFund => 'Equity Fund',
        ProductType.elss => 'ELSS',
        ProductType.debtFund => 'Debt Fund',
        ProductType.hybridFund => 'Hybrid Fund',
        ProductType.fixedDeposit => 'Fixed Deposit',
        ProductType.gold => 'Gold',
      };

  bool get isEquity =>
      this == ProductType.indexFund ||
      this == ProductType.equityFund ||
      this == ProductType.elss;
}

/// An investable product on the shelf.
class InvestmentProduct extends Equatable {
  const InvestmentProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.riskLevel,
    required this.expectedReturn,
    required this.minInvestment,
    required this.description,
    required this.tags,
  });

  final String id;
  final String name;
  final ProductType type;
  final RiskLevel riskLevel;
  final double expectedReturn; // annual, decimal
  final double minInvestment;
  final String description;
  final List<String> tags;

  @override
  List<Object?> get props =>
      [id, name, type, riskLevel, expectedReturn, minInvestment, description, tags];
}
