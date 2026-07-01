import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository so the screen test never touches the network.
class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository(this._result);
  final Result<DashboardSummary> _result;

  @override
  Future<Result<DashboardSummary>> getDashboard({bool forceRefresh = false}) async =>
      _result;
}

DashboardSummary _summary() => const DashboardSummary(
      userId: 'usr_demo_0001',
      fullName: 'Demo User',
      currency: 'INR',
      netWorth: 2480000,
      totalAssets: 2900000,
      totalLiabilities: 420000,
      monthlyChange: 18640,
      accounts: [
        Account(
          id: 'acc_sav_01',
          name: 'IDBI Savings',
          type: AccountType.savings,
          maskedNumber: '4821',
          balance: 248500,
          currency: 'INR',
          monthlyChange: 12300,
        ),
        Account(
          id: 'acc_cc_01',
          name: 'Credit Card',
          type: AccountType.creditCard,
          maskedNumber: '3302',
          balance: 43750,
          currency: 'INR',
          monthlyChange: 43750,
        ),
      ],
      insight: Explanation(
        summary: 'Your net worth grew by ₹18,640 this month.',
        reasons: ['Assets far exceed liabilities.'],
        benefits: ['Positive monthly trend.'],
        confidence: 0.85,
      ),
    );

Future<void> _pump(WidgetTester tester, Result<DashboardSummary> result) async {
  // Tall surface so the whole (lazily-built) list is laid out in one frame.
  await tester.binding.setSurfaceSize(const Size(1000, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardRepositoryProvider
            .overrideWithValue(_FakeDashboardRepository(result)),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders net worth, accounts and AI insight', (tester) async {
    await _pump(tester, success(_summary()));

    expect(find.text('₹24.80L'), findsOneWidget); // compact net worth
    expect(find.textContaining('Hi Demo,'), findsOneWidget);
    expect(find.text('IDBI Savings'), findsOneWidget);
    expect(find.text('Credit Card'), findsOneWidget);
    expect(find.text('AI insight'), findsOneWidget);
    expect(find.text('85% confident'), findsOneWidget);
    expect(find.textContaining('grew by ₹18,640'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when the load fails',
      (tester) async {
    await _pump(tester, failure(const NetworkFailure('offline')));

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
