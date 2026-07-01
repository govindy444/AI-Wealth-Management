import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/predictive/predictive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements PredictiveRepository {
  @override
  Future<Result<Forecast>> getForecast() async => success(
        Forecast(
          asOf: DateTime(2026, 6, 29),
          currentLiquidBalance: 334700,
          projectedMonthEndBalance: 290000,
          predictions: [
            Prediction(
              type: PredictionType.salaryCredit,
              title: 'Salary expected',
              message: 'Your salary of ₹1,45,000 is expected.',
              predictedDate: DateTime(2026, 7, 1),
              daysAway: 2,
              severity: PredictionSeverity.info,
              amount: 145000,
            ),
            Prediction(
              type: PredictionType.emiDue,
              title: 'EMI due: Home Loan',
              message: '₹21,500 due.',
              predictedDate: DateTime(2026, 7, 5),
              daysAway: 6,
              severity: PredictionSeverity.warning,
              amount: 21500,
            ),
          ],
          insight: const Explanation(
            summary: 'A few payments are coming up; keep an eye on spending.',
            confidence: 0.75,
          ),
        ),
      );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [predictiveRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: const MaterialApp(home: PredictiveScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders balances, outlook and dated predictions', (tester) async {
    await _pump(tester);

    expect(find.text('Available now'), findsOneWidget);
    expect(find.text('Projected month-end'), findsOneWidget);
    expect(find.textContaining('payments are coming up'), findsOneWidget);
    expect(find.text('Salary expected'), findsOneWidget);
    expect(find.text('EMI due: Home Loan'), findsOneWidget);
    expect(find.text('in 2d'), findsOneWidget);
    expect(find.text('in 6d'), findsOneWidget);
  });
}
