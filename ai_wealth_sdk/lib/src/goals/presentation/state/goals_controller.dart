import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../../domain/entities/goal_simulation.dart';
import '../../domain/usecases/goal_usecases.dart';
import 'goals_state.dart';


class GoalsController extends StateNotifier<GoalsState> {
  GoalsController({
    required ListGoalsUseCase listGoals,
    required CreateGoalUseCase createGoal,
    required UpdateGoalUseCase updateGoal,
    required DeleteGoalUseCase deleteGoal,
    required SimulateGoalUseCase simulateGoal,
  })  : _listGoals = listGoals,
        _createGoal = createGoal,
        _updateGoal = updateGoal,
        _deleteGoal = deleteGoal,
        _simulateGoal = simulateGoal,
        super(const GoalsState.initial());

  final ListGoalsUseCase _listGoals;
  final CreateGoalUseCase _createGoal;
  final UpdateGoalUseCase _updateGoal;
  final DeleteGoalUseCase _deleteGoal;
  final SimulateGoalUseCase _simulateGoal;

  Future<void> load() async {
    state = state.copyWith(status: GoalsStatus.loading, clearError: true);
    final result = await _listGoals(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: GoalsStatus.error,
        errorMessage: failure.message,
      ),
      (goals) => state.copyWith(status: GoalsStatus.ready, goals: goals),
    );
  }

  Future<bool> create(CreateGoalParams params) =>
      _mutate(_createGoal(params));

  Future<bool> update(UpdateGoalParams params) =>
      _mutate(_updateGoal(params));

  Future<bool> delete(String id) => _mutate(_deleteGoal(id));

  /// Runs a simulation; returns null on failure (and records the error).
  Future<GoalSimulation?> simulate(SimulateGoalParams params) async {
    final result = await _simulateGoal(params);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return null;
      },
      (sim) => sim,
    );
  }


  Future<bool> _mutate<T>(FutureResult<T> action) async {
    final result = await action;
    if (result.isRight()) {
      await load();
      return true;
    }
    state = state.copyWith(
      errorMessage: result.fold((f) => f.message, (_) => null),
    );
    return false;
  }
}
