import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/goal.dart';
import '../entities/goal_simulation.dart';
import '../repositories/goal_repository.dart';

class ListGoalsUseCase implements UseCase<List<Goal>, NoParams> {
  ListGoalsUseCase(this._repository);
  final GoalRepository _repository;

  @override
  FutureResult<List<Goal>> call(NoParams params) => _repository.listGoals();
}

class CreateGoalParams extends Equatable {
  const CreateGoalParams({
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    this.currentAmount = 0,
    this.monthlyContribution = 0,
    this.expectedReturnRate = 0.10,
    this.category = GoalCategory.other,
  });

  final String name;
  final double targetAmount;
  final DateTime targetDate;
  final double currentAmount;
  final double monthlyContribution;
  final double expectedReturnRate;
  final GoalCategory category;

  @override
  List<Object?> get props => [
        name,
        targetAmount,
        targetDate,
        currentAmount,
        monthlyContribution,
        expectedReturnRate,
        category,
      ];
}

class CreateGoalUseCase implements UseCase<Goal, CreateGoalParams> {
  CreateGoalUseCase(this._repository);
  final GoalRepository _repository;

  @override
  FutureResult<Goal> call(CreateGoalParams p) => _repository.createGoal(
        name: p.name,
        targetAmount: p.targetAmount,
        targetDate: p.targetDate,
        currentAmount: p.currentAmount,
        monthlyContribution: p.monthlyContribution,
        expectedReturnRate: p.expectedReturnRate,
        category: p.category,
      );
}

class UpdateGoalParams extends Equatable {
  const UpdateGoalParams({
    required this.id,
    this.targetAmount,
    this.currentAmount,
    this.monthlyContribution,
    this.targetDate,
    this.expectedReturnRate,
  });

  final String id;
  final double? targetAmount;
  final double? currentAmount;
  final double? monthlyContribution;
  final DateTime? targetDate;
  final double? expectedReturnRate;

  @override
  List<Object?> get props =>
      [id, targetAmount, currentAmount, monthlyContribution, targetDate, expectedReturnRate];
}

class UpdateGoalUseCase implements UseCase<Goal, UpdateGoalParams> {
  UpdateGoalUseCase(this._repository);
  final GoalRepository _repository;

  @override
  FutureResult<Goal> call(UpdateGoalParams p) => _repository.updateGoal(
        id: p.id,
        targetAmount: p.targetAmount,
        currentAmount: p.currentAmount,
        monthlyContribution: p.monthlyContribution,
        targetDate: p.targetDate,
        expectedReturnRate: p.expectedReturnRate,
      );
}

class DeleteGoalUseCase implements UseCase<void, String> {
  DeleteGoalUseCase(this._repository);
  final GoalRepository _repository;

  @override
  FutureResult<void> call(String id) => _repository.deleteGoal(id);
}

class SimulateGoalParams extends Equatable {
  const SimulateGoalParams({
    required this.targetAmount,
    required this.targetDate,
    this.currentAmount = 0,
    this.monthlyContribution,
    this.expectedReturnRate = 0.10,
  });

  final double targetAmount;
  final DateTime targetDate;
  final double currentAmount;
  final double? monthlyContribution;
  final double expectedReturnRate;

  @override
  List<Object?> get props =>
      [targetAmount, targetDate, currentAmount, monthlyContribution, expectedReturnRate];
}

class SimulateGoalUseCase implements UseCase<GoalSimulation, SimulateGoalParams> {
  SimulateGoalUseCase(this._repository);
  final GoalRepository _repository;

  @override
  FutureResult<GoalSimulation> call(SimulateGoalParams p) => _repository.simulate(
        targetAmount: p.targetAmount,
        targetDate: p.targetDate,
        currentAmount: p.currentAmount,
        monthlyContribution: p.monthlyContribution,
        expectedReturnRate: p.expectedReturnRate,
      );
}
