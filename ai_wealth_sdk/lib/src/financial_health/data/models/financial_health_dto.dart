import '../../../core/domain/explainability.dart';
import '../../domain/entities/financial_health.dart';
import '../../domain/entities/health_pillar.dart';

class FinancialHealthDto {
  const FinancialHealthDto._();

  static FinancialHealth fromJson(Map<String, dynamic> j) {
    final insight = j['insight'];
    return FinancialHealth(
      score: (j['score'] as num?)?.toInt() ?? 0,
      grade: (j['grade'] as String?) ?? 'E',
      status: HealthStatus.fromWire((j['status'] as String?) ?? 'poor'),
      pillars: (j['pillars'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_pillarFromJson)
          .toList(growable: false),
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static HealthPillar _pillarFromJson(Map<String, dynamic> j) => HealthPillar(
        key: (j['key'] as String?) ?? '',
        label: (j['label'] as String?) ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        status: HealthStatus.fromWire((j['status'] as String?) ?? 'poor'),
        detail: (j['detail'] as String?) ?? '',
        recommendation: (j['recommendation'] as String?) ?? '',
      );
}
