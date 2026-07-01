import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/goals/data/datasources/goal_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/goals/data/models/goal_dtos.dart';
import 'package:ai_wealth_sdk/src/goals/data/repositories/goal_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _goalJson({String id = 'goal_1', double progress = 41.4}) => {
      'id': id,
      'name': 'Emergency Fund',
      'category': 'emergency',
      'target_amount': 600000.0,
      'current_amount': 248500.0,
      'target_date': '2027-06-01',
      'monthly_contribution': 15000.0,
      'expected_return_rate': 0.06,
      'progress_pct': progress,
      'months_remaining': 12,
      'required_monthly': 28000.0,
      'projected_value': 450000.0,
      'on_track': false,
      'surplus_or_shortfall': -150000.0,
    };

Map<String, dynamic> _simJson() => {
      'target_amount': 1000000.0,
      'months': 60,
      'required_monthly': 12000.0,
      'projected_value': 380000.0,
      'on_track': false,
      'insight': {'summary': 'Invest ₹12,000/month.', 'confidence': 0.8},
    };

void main() {
  group('GoalDtos', () {
    test('decodes a goal with projections', () {
      final g = GoalDtos.goalFromJson(_goalJson());
      expect(g.name, 'Emergency Fund');
      expect(g.category, GoalCategory.emergency);
      expect(g.progressPct, 41.4);
      expect(g.onTrack, isFalse);
      expect(g.surplusOrShortfall, -150000.0);
    });

    test('decodes a simulation with an insight', () {
      final s = GoalDtos.simulationFromJson(_simJson());
      expect(s.requiredMonthly, 12000.0);
      expect(s.projectedValue, 380000.0);
      expect(s.insight.confidencePercent, 80);
    });

    test('formats dates as YYYY-MM-DD', () {
      expect(GoalDtos.dateParam(DateTime(2027, 3, 5)), '2027-03-05');
    });
  });

  group('GoalsController', () {
    GoalsController controller(FakeRemote remote) {
      final repo = GoalRepositoryImpl(remote: remote, logger: _logger);
      return GoalsController(
        listGoals: ListGoalsUseCase(repo),
        createGoal: CreateGoalUseCase(repo),
        updateGoal: UpdateGoalUseCase(repo),
        deleteGoal: DeleteGoalUseCase(repo),
        simulateGoal: SimulateGoalUseCase(repo),
      );
    }

    test('load populates goals', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, GoalsStatus.ready);
      expect(c.state.goals, hasLength(1));
    });

    test('create reloads the list and returns true', () async {
      final remote = FakeRemote();
      final c = controller(remote);
      addTearDown(c.dispose);
      await c.load();

      final ok = await c.create(CreateGoalParams(
        name: 'Car',
        targetAmount: 150000,
        targetDate: DateTime(2028, 1, 1),
      ));

      expect(ok, isTrue);
      expect(remote.created, isTrue);
      expect(remote.listCalls, 2); // initial load + reload after create
    });

    test('simulate returns a projection without touching list state', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      final sim = await c.simulate(SimulateGoalParams(
        targetAmount: 1000000,
        targetDate: DateTime(2031, 6, 1),
        monthlyContribution: 5000,
      ));
      expect(sim, isNotNull);
      expect(sim!.requiredMonthly, 12000.0);
    });

    test('load surfaces an error on failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, GoalsStatus.error);
    });
  });
}

class FakeRemote implements GoalRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  int listCalls = 0;
  bool created = false;

  @override
  Future<List<Goal>> listGoals() async {
    listCalls++;
    if (_fail) throw NetworkException('offline');
    return [GoalDtos.goalFromJson(_goalJson())];
  }

  @override
  Future<Goal> createGoal(Map<String, dynamic> body) async {
    created = true;
    return GoalDtos.goalFromJson(_goalJson(id: 'goal_new'));
  }

  @override
  Future<Goal> updateGoal(String id, Map<String, dynamic> body) async =>
      GoalDtos.goalFromJson(_goalJson(id: id));

  @override
  Future<void> deleteGoal(String id) async {}

  @override
  Future<GoalSimulation> simulate(Map<String, dynamic> body) async =>
      GoalDtos.simulationFromJson(_simJson());
}
