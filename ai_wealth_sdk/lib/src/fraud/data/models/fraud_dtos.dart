import '../../../core/domain/explainability.dart';
import '../../domain/entities/fraud_alert.dart';
import '../../domain/entities/fraud_reports.dart';

class FraudDtos {
  const FraudDtos._();

  static FraudAlert alertFromJson(Map<String, dynamic> j) => FraudAlert(
        id: (j['id'] as String?) ?? '',
        type: FraudAlertType.fromWire((j['type'] as String?) ?? 'unusual_amount'),
        riskLevel: FraudRiskLevel.fromWire((j['risk_level'] as String?) ?? 'low'),
        merchant: (j['merchant'] as String?) ?? '',
        amount: _d(j['amount']),
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        reason: (j['reason'] as String?) ?? '',
      );

  static FraudAlerts alertsFromJson(Map<String, dynamic> j) {
    final insight = j['insight'];
    return FraudAlerts(
      scannedCount: (j['scanned_count'] as num?)?.toInt() ?? 0,
      alerts: (j['alerts'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(alertFromJson)
          .toList(growable: false),
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static MessageCheck messageCheckFromJson(Map<String, dynamic> j) {
    final explanation = j['explanation'];
    return MessageCheck(
      riskLevel: FraudRiskLevel.fromWire((j['risk_level'] as String?) ?? 'low'),
      score: (j['score'] as num?)?.toInt() ?? 0,
      isSafe: (j['is_safe'] as bool?) ?? true,
      explanation: explanation is Map<String, dynamic>
          ? Explanation.fromJson(explanation)
          : const Explanation(summary: ''),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}
