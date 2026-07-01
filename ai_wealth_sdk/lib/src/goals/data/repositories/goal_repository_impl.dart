import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_simulation.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_remote_datasource.dart';
import '../models/goal_dtos.dart';


class GoalRepositoryImpl with BaseRepository implements GoalRepository {
  GoalRepositoryImpl({required GoalRemoteDataSource remote, required this.logger})
      : _remote = remote;

  final GoalRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<List<Goal>> listGoals() => guard(() => _remote.listGoals());

  @override
  FutureResult<Goal> createGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    double currentAmount = 0,
    double monthlyContribution = 0,
    double expectedReturnRate = 0.10,
    GoalCategory category = GoalCategory.other,
  }) =>
      guard(() => _remote.createGoal({
            'name': name,
            'target_amount': targetAmount,
            'target_date': GoalDtos.dateParam(targetDate),
            'current_amount': currentAmount,
            'monthly_contribution': monthlyContribution,
            'expected_return_rate': expectedReturnRate,
            'category': category.wire,
          }));

  @override
  FutureResult<Goal> updateGoal({
    required String id,
    double? targetAmount,
    double? currentAmount,
    double? monthlyContribution,
    DateTime? targetDate,
    double? expectedReturnRate,
  }) =>
      guard(() => _remote.updateGoal(id, {
            if (targetAmount != null) 'target_amount': targetAmount,
            if (currentAmount != null) 'current_amount': currentAmount,
            if (monthlyContribution != null) 'monthly_contribution': monthlyContribution,
            if (targetDate != null) 'target_date': GoalDtos.dateParam(targetDate),
            if (expectedReturnRate != null) 'expected_return_rate': expectedReturnRate,
          }));

  @override
  FutureResult<void> deleteGoal(String id) => guard(() => _remote.deleteGoal(id));

  @override
  FutureResult<GoalSimulation> simulate({
    required double targetAmount,
    required DateTime targetDate,
    double currentAmount = 0,
    double? monthlyContribution,
    double expectedReturnRate = 0.10,
  }) =>
      guard(() => _remote.simulate({
            'target_amount': targetAmount,
            'target_date': GoalDtos.dateParam(targetDate),
            'current_amount': currentAmount,
            if (monthlyContribution != null) 'monthly_contribution': monthlyContribution,
            'expected_return_rate': expectedReturnRate,
          }));
}
