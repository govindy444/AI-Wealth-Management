import '../../../core/network/api_client.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_simulation.dart';
import '../models/goal_dtos.dart';

abstract interface class GoalRemoteDataSource {
  Future<List<Goal>> listGoals();
  Future<Goal> createGoal(Map<String, dynamic> body);
  Future<Goal> updateGoal(String id, Map<String, dynamic> body);
  Future<void> deleteGoal(String id);
  Future<GoalSimulation> simulate(Map<String, dynamic> body);
}

class GoalRemoteDataSourceImpl implements GoalRemoteDataSource {
  GoalRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<List<Goal>> listGoals() async {
    final res = await _client.get('/goals');
    return res.asList
        .cast<Map<String, dynamic>>()
        .map(GoalDtos.goalFromJson)
        .toList(growable: false);
  }

  @override
  Future<Goal> createGoal(Map<String, dynamic> body) async {
    final res = await _client.post('/goals', data: body);
    return GoalDtos.goalFromJson(res.asMap);
  }

  @override
  Future<Goal> updateGoal(String id, Map<String, dynamic> body) async {
    final res = await _client.patch('/goals/$id', data: body);
    return GoalDtos.goalFromJson(res.asMap);
  }

  @override
  Future<void> deleteGoal(String id) => _client.delete('/goals/$id');

  @override
  Future<GoalSimulation> simulate(Map<String, dynamic> body) async {
    final res = await _client.post('/goals/simulate', data: body);
    return GoalDtos.simulationFromJson(res.asMap);
  }
}
