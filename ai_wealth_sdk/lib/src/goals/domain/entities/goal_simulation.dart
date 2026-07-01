import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';

class GoalSimulation extends Equatable {
  const GoalSimulation({
    required this.targetAmount,
    required this.months,
    required this.requiredMonthly,
    required this.onTrack,
    required this.insight,
    this.projectedValue,
  });

  final double targetAmount;
  final int months;

  /// Monthly SIP needed to reach the target exactly.
  final double requiredMonthly;

  /// Projected value at the supplied contribution (null if none was given).
  final double? projectedValue;
  final bool onTrack;
  final Explanation insight;

  @override
  List<Object?> get props =>
      [targetAmount, months, requiredMonthly, projectedValue, onTrack, insight];
}
