import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/goals/goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _goal({
  String id = 'goal_1',
  String name = 'Emergency Fund',
  bool onTrack = false,
}) =>
    Goal(
      id: id,
      name: name,
      category: GoalCategory.emergency,
      targetAmount: 600000,
      currentAmount: 248500,
      targetDate: DateTime(2027, 6, 1),
      monthlyContribution: 15000,
      expectedReturnRate: 0.06,
      progressPct: 41.4,
      monthsRemaining: 12,
      requiredMonthly: 28000,
      projectedValue: 450000,
      onTrack: onTrack,
      surplusOrShortfall: -150000,
    );

class _FakeGoalRepository implements GoalRepository {
  @override
  Future<Result<List<Goal>>> listGoals() async =>
      success([_goal(), _goal(id: 'goal_2', name: 'Dream Vacation', onTrack: true)]);

  @override
  Future<Result<GoalSimulation>> simulate({
    required double targetAmount,
    required DateTime targetDate,
    double currentAmount = 0,
    double? monthlyContribution,
    double expectedReturnRate = 0.10,
  }) async =>
      success(GoalSimulation(
        targetAmount: targetAmount,
        months: 60,
        requiredMonthly: 12345,
        projectedValue: 380000,
        onTrack: false,
        insight: const Explanation(summary: 'Invest steadily each month.'),
      ));

  @override
  Future<Result<Goal>> createGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    double currentAmount = 0,
    double monthlyContribution = 0,
    double expectedReturnRate = 0.10,
    GoalCategory category = GoalCategory.other,
  }) async =>
      success(_goal(id: 'new'));

  @override
  Future<Result<Goal>> updateGoal({
    required String id,
    double? targetAmount,
    double? currentAmount,
    double? monthlyContribution,
    DateTime? targetDate,
    double? expectedReturnRate,
  }) async =>
      success(_goal(id: id));

  @override
  Future<Result<void>> deleteGoal(String id) async => success(null);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [goalRepositoryProvider.overrideWithValue(_FakeGoalRepository())],
      child: const MaterialApp(home: GoalsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists goals with progress and on-track status', (tester) async {
    await _pump(tester);

    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('Dream Vacation'), findsOneWidget);
    expect(find.text('Behind'), findsOneWidget); // emergency: not on track
    expect(find.text('On track'), findsOneWidget); // vacation
  });

  testWidgets('SIP planner computes a required monthly amount', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Plan a goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Invest'), findsWidgets);
    expect(find.textContaining('12,345'), findsOneWidget); // required monthly
  });
}
