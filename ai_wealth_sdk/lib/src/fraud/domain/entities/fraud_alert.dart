import 'package:equatable/equatable.dart';

enum FraudRiskLevel {
  low,
  medium,
  high;

  static FraudRiskLevel fromWire(String value) => switch (value) {
        'high' => FraudRiskLevel.high,
        'medium' => FraudRiskLevel.medium,
        _ => FraudRiskLevel.low,
      };

  String get label => switch (this) {
        FraudRiskLevel.low => 'Low',
        FraudRiskLevel.medium => 'Medium',
        FraudRiskLevel.high => 'High',
      };
}

enum FraudAlertType {
  unusualAmount,
  duplicateCharge,
  newMerchantHighValue;

  static FraudAlertType fromWire(String value) => switch (value) {
        'unusual_amount' => FraudAlertType.unusualAmount,
        'duplicate_charge' => FraudAlertType.duplicateCharge,
        'new_merchant_high_value' => FraudAlertType.newMerchantHighValue,
        _ => FraudAlertType.unusualAmount,
      };

  String get label => switch (this) {
        FraudAlertType.unusualAmount => 'Unusual amount',
        FraudAlertType.duplicateCharge => 'Duplicate charge',
        FraudAlertType.newMerchantHighValue => 'New merchant',
      };
}

/// A flagged, potentially-fraudulent transaction.
class FraudAlert extends Equatable {
  const FraudAlert({
    required this.id,
    required this.type,
    required this.riskLevel,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.reason,
  });

  final String id;
  final FraudAlertType type;
  final FraudRiskLevel riskLevel;
  final String merchant;
  final double amount;
  final DateTime date;
  final String reason;

  @override
  List<Object?> get props => [id, type, riskLevel, merchant, amount, date, reason];
}
