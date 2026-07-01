import '../../../core/domain/explainability.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_simulation.dart';

class GoalDtos {
  const GoalDtos._();

  
  static String dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Goal goalFromJson(Map<String, dynamic> j) => Goal(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        category: GoalCategory.fromWire((j['category'] as String?) ?? 'other'),
        targetAmount: _d(j['target_amount']),
        currentAmount: _d(j['current_amount']),
        targetDate: DateTime.tryParse(j['target_date'] as String? ?? '') ?? DateTime.now(),
        monthlyContribution: _d(j['monthly_contribution']),
        expectedReturnRate: _d(j['expected_return_rate']),
        progressPct: _d(j['progress_pct']),
        monthsRemaining: (j['months_remaining'] as num?)?.toInt() ?? 0,
        requiredMonthly: _d(j['required_monthly']),
        projectedValue: _d(j['projected_value']),
        onTrack: (j['on_track'] as bool?) ?? false,
        surplusOrShortfall: _d(j['surplus_or_shortfall']),
      );

  static GoalSimulation simulationFromJson(Map<String, dynamic> j) {
    final insight = j['insight'];
    return GoalSimulation(
      targetAmount: _d(j['target_amount']),
      months: (j['months'] as num?)?.toInt() ?? 0,
      requiredMonthly: _d(j['required_monthly']),
      projectedValue: j['projected_value'] == null ? null : _d(j['projected_value']),
      onTrack: (j['on_track'] as bool?) ?? false,
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}
