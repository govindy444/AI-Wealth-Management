import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';
import 'prediction.dart';

/// A cashflow forecast: current/projected balance plus dated predictions.
class Forecast extends Equatable {
  const Forecast({
    required this.asOf,
    required this.currentLiquidBalance,
    required this.projectedMonthEndBalance,
    required this.predictions,
    required this.insight,
  });

  final DateTime asOf;
  final double currentLiquidBalance;
  final double projectedMonthEndBalance;
  final List<Prediction> predictions;
  final Explanation insight;

  /// Predictions the user should act on (warnings/criticals first).
  List<Prediction> get alerts => predictions
      .where((p) => p.severity != PredictionSeverity.info)
      .toList(growable: false);

  @override
  List<Object?> get props => [
        asOf,
        currentLiquidBalance,
        projectedMonthEndBalance,
        predictions,
        insight,
      ];
}
