import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/fraud/fraud_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements FraudRepository {
  @override
  Future<Result<FraudAlerts>> getAlerts() async => success(
        FraudAlerts(
          scannedCount: 8,
          alerts: [
            FraudAlert(
              id: 'a1',
              type: FraudAlertType.unusualAmount,
              riskLevel: FraudRiskLevel.high,
              merchant: 'QuickElectronics Online',
              amount: 48999,
              date: DateTime(2026, 6, 28),
              reason: 'Far above your typical spend.',
            ),
          ],
          insight: const Explanation(summary: '1 alert found, including 1 high-risk.'),
        ),
      );

  @override
  Future<Result<MessageCheck>> checkMessage(String text) async => success(
        const MessageCheck(
          riskLevel: FraudRiskLevel.high,
          score: 60,
          isSafe: false,
          explanation: Explanation(
            summary: 'This looks like a scam.',
            reasons: ['Asks for an OTP.'],
            confidence: 0.7,
          ),
        ),
      );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [fraudRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: const MaterialApp(home: FraudScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists anomaly alerts with risk', (tester) async {
    await _pump(tester);
    expect(find.text('QuickElectronics Online'), findsOneWidget);
    expect(find.textContaining('High risk'), findsOneWidget);
    expect(find.textContaining('1 alert found'), findsOneWidget);
  });

  testWidgets('message checker flags a scam', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'Share your OTP now');
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    expect(find.textContaining('looks like a scam'), findsOneWidget);
    expect(find.textContaining('High risk (60/100)'), findsOneWidget);
  });
}
