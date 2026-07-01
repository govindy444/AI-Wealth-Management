import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/portfolio/portfolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements PortfolioRepository {
  @override
  Future<Result<PortfolioSummary>> getSummary() async => success(
        const PortfolioSummary(
          totalValue: 797000,
          totalInvested: 720000,
          totalGain: 77000,
          gainPct: 10.7,
          riskScore: 50,
          riskLabel: RiskLabel.moderate,
          diversificationScore: 68,
          allocation: [
            AllocationSlice(assetClass: AssetClass.debt, percentage: 42.7, value: 340000),
            AllocationSlice(assetClass: AssetClass.equity, percentage: 37.6, value: 300000),
            AllocationSlice(assetClass: AssetClass.gold, percentage: 8.4, value: 67000),
          ],
          topHoldings: [
            Holding(
              id: 'hld_fd',
              name: 'IDBI Fixed Deposit',
              assetClass: AssetClass.debt,
              invested: 200000,
              currentValue: 212000,
              gain: 12000,
              gainPct: 6,
            ),
          ],
          insight: Explanation(
            summary: 'Your portfolio is worth ₹7,97,000 with a moderate risk profile.',
            alternatives: ['Rebalance toward target equity.'],
            confidence: 0.8,
          ),
        ),
      );

  @override
  Future<Result<List<Holding>>> getHoldings() async => success(const []);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [portfolioRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: const MaterialApp(home: PortfolioScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders value, allocation, risk meter and holdings', (tester) async {
    await _pump(tester);

    expect(find.text('Portfolio value'), findsOneWidget);
    expect(find.text('Asset allocation'), findsOneWidget);
    expect(find.text('Risk meter'), findsOneWidget);
    expect(find.textContaining('Moderate (50)'), findsOneWidget);
    expect(find.textContaining('Diversification: 68/100'), findsOneWidget);
    expect(find.text('Debt'), findsWidgets); // allocation legend + holding subtitle
    expect(find.text('IDBI Fixed Deposit'), findsOneWidget);
  });
}
