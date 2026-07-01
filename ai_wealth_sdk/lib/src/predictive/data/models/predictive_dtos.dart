import '../../../core/domain/explainability.dart';
import '../../domain/entities/forecast.dart';
import '../../domain/entities/prediction.dart';

/// Wire decoders for the predictive endpoints.
class PredictiveDtos {
  const PredictiveDtos._();

  static Prediction predictionFromJson(Map<String, dynamic> j) => Prediction(
        type: PredictionType.fromWire((j['type'] as String?) ?? 'bill_due'),
        title: (j['title'] as String?) ?? '',
        message: (j['message'] as String?) ?? '',
        predictedDate:
            DateTime.tryParse(j['predicted_date'] as String? ?? '') ?? DateTime.now(),
        daysAway: (j['days_away'] as num?)?.toInt() ?? 0,
        severity: PredictionSeverity.fromWire((j['severity'] as String?) ?? 'info'),
        amount: j['amount'] == null ? null : (j['amount'] as num).toDouble(),
      );

  static Forecast forecastFromJson(Map<String, dynamic> j) {
    final insight = j['insight'];
    return Forecast(
      asOf: DateTime.tryParse(j['as_of'] as String? ?? '') ?? DateTime.now(),
      currentLiquidBalance: _d(j['current_liquid_balance']),
      projectedMonthEndBalance: _d(j['projected_month_end_balance']),
      predictions: (j['predictions'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(predictionFromJson)
          .toList(growable: false),
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}
