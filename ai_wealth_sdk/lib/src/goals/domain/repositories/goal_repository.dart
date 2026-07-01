import '../../../core/utils/result.dart';
import '../entities/goal.dart';
import '../entities/goal_simulation.dart';

/// Goal Planner repository contract.
abstract interface class GoalRepository {
  FutureResult<List<Goal>> listGoals();

  FutureResult<Goal> createGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    double currentAmount,
    double monthlyContribution,
    double expectedReturnRate,
    GoalCategory category,
  });

  FutureResult<Goal> updateGoal({
    required String id,
    double? targetAmount,
    double? currentAmount,
    double? monthlyContribution,
    DateTime? targetDate,
    double? expectedReturnRate,
  });

  FutureResult<void> deleteGoal(String id);

  /// Simulates the SIP needed to reach a target without persisting a goal.
  FutureResult<GoalSimulation> simulate({
    required double targetAmount,
    required DateTime targetDate,
    double currentAmount,
    double? monthlyContribution,
    double expectedReturnRate,
  });
}
