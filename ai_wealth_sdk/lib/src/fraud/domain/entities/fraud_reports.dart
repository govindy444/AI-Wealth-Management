import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';
import 'fraud_alert.dart';

class FraudAlerts extends Equatable {
  const FraudAlerts({
    required this.scannedCount,
    required this.alerts,
    required this.insight,
  });

  final int scannedCount;
  final List<FraudAlert> alerts;
  final Explanation insight;

  bool get hasAlerts => alerts.isNotEmpty;
  List<FraudAlert> get highRisk =>
      alerts.where((a) => a.riskLevel == FraudRiskLevel.high).toList(growable: false);

  @override
  List<Object?> get props => [scannedCount, alerts, insight];
}

/// The result of scoring a message for scam/phishing risk.
class MessageCheck extends Equatable {
  const MessageCheck({
    required this.riskLevel,
    required this.score,
    required this.isSafe,
    required this.explanation,
  });

  final FraudRiskLevel riskLevel;
  final int score; // 0–100
  final bool isSafe;
  final Explanation explanation;

  @override
  List<Object?> get props => [riskLevel, score, isSafe, explanation];
}
