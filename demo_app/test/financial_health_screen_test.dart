import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/financial_health/financial_health_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements FinancialHealthRepository {
  @override
  Future<Result<FinancialHealth>> getScore() async => success(
        const FinancialHealth(
          score: 72,
          grade: 'B',
          status: HealthStatus.good,
          pillars: [
            HealthPillar(
              key: 'savings',
              label: 'Savings',
              score: 85,
              status: HealthStatus.excellent,
              detail: 'You save 25% of income.',
              recommendation: 'Keep automating it.',
            ),
            HealthPillar(
              key: 'emergency_fund',
              label: 'Emergency Fund',
              score: 40,
              status: HealthStatus.fair,
              detail: '2.4 months covered.',
              recommendation: 'Build toward 6 months.',
            ),
          ],
          insight: Explanation(
            summary: 'Your financial health is good (72/100, grade B).',
            alternatives: ['Build toward 6 months.'],
            confidence: 0.82,
          ),
        ),
      );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        financialHealthRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
      child: const MaterialApp(home: FinancialHealthScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders score, grade, insight and weakest-first pillars',
      (tester) async {
    await _pump(tester);

    expect(find.text('72'), findsOneWidget); // gauge score
    expect(find.textContaining('Grade B'), findsOneWidget);
    expect(find.textContaining('good (72/100'), findsOneWidget); // insight
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('Build toward 6 months.'), findsWidgets); // recommendation + next

    // Weakest pillar (Emergency Fund, 40) should appear before Savings (85).
    final efY = tester.getTopLeft(find.text('Emergency Fund')).dy;
    final savY = tester.getTopLeft(find.text('Savings')).dy;
    expect(efY, lessThan(savY));
  });
}
