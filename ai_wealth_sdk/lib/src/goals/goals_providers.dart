import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/goal_remote_datasource.dart';
import 'data/repositories/goal_repository_impl.dart';
import 'domain/repositories/goal_repository.dart';
import 'domain/usecases/goal_usecases.dart';
import 'presentation/state/goals_controller.dart';
import 'presentation/state/goals_state.dart';



final goalRemoteDataSourceProvider = Provider<GoalRemoteDataSource>(
  (ref) => GoalRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepositoryImpl(
    remote: ref.watch(goalRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final listGoalsUseCaseProvider =
    Provider((ref) => ListGoalsUseCase(ref.watch(goalRepositoryProvider)));
final createGoalUseCaseProvider =
    Provider((ref) => CreateGoalUseCase(ref.watch(goalRepositoryProvider)));
final updateGoalUseCaseProvider =
    Provider((ref) => UpdateGoalUseCase(ref.watch(goalRepositoryProvider)));
final deleteGoalUseCaseProvider =
    Provider((ref) => DeleteGoalUseCase(ref.watch(goalRepositoryProvider)));
final simulateGoalUseCaseProvider =
    Provider((ref) => SimulateGoalUseCase(ref.watch(goalRepositoryProvider)));

final goalsControllerProvider =
    StateNotifierProvider<GoalsController, GoalsState>(
  (ref) => GoalsController(
    listGoals: ref.watch(listGoalsUseCaseProvider),
    createGoal: ref.watch(createGoalUseCaseProvider),
    updateGoal: ref.watch(updateGoalUseCaseProvider),
    deleteGoal: ref.watch(deleteGoalUseCaseProvider),
    simulateGoal: ref.watch(simulateGoalUseCaseProvider),
  ),
);
