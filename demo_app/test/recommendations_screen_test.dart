import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/recommendations/recommendations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

InvestmentProduct _product(String name, ProductType type) => InvestmentProduct(
      id: name,
      name: name,
      type: type,
      riskLevel: RiskLevel.moderate,
      expectedReturn: 0.11,
      minInvestment: 500,
      description: 'A product.',
      tags: const ['equity'],
    );

class _FakeRepo implements RecommendationRepository {
  String? lastProfile;

  @override
  Future<Result<List<InvestmentProduct>>> listProducts() async =>
      success([_product('IDBI FD', ProductType.fixedDeposit)]);

  @override
  Future<Result<RecommendationSet>> recommend({
    required RiskProfile riskProfile,
    double amount = 100000,
    int horizonYears = 5,
  }) async {
    lastProfile = riskProfile.wire;
    return success(RecommendationSet(
      riskProfile: riskProfile,
      totalAmount: amount,
      horizonYears: horizonYears,
      blendedExpectedReturn: 0.105,
      recommendations: [
        Recommendation(
          product: _product('IDBI Nifty 50 Index Fund', ProductType.indexFund),
          allocationPct: 60,
          suggestedAmount: amount * 0.6,
          rationale: const Explanation(
            summary: 'Growth engine.',
            reasons: ['Broad equity exposure.'],
            risks: ['Can be volatile short-term.'],
            confidence: 0.7,
          ),
        ),
      ],
      insight: Explanation(
        summary: 'A ${riskProfile.label} portfolio targets ~10.5% a year.',
        confidence: 0.72,
      ),
    ));
  }
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recommendationRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: RecommendationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the strategy and an explainable recommendation',
      (tester) async {
    await _pump(tester, _FakeRepo());

    expect(find.text('10.5% p.a.'), findsOneWidget); // blended return
    expect(find.text('IDBI Nifty 50 Index Fund'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.textContaining('Why this?'), findsOneWidget); // explainability
  });

  testWidgets('selecting a risk profile re-fetches', (tester) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);

    await tester.tap(find.text('Aggressive'));
    await tester.pumpAndSettle();

    expect(repo.lastProfile, 'aggressive');
    expect(find.textContaining('Aggressive portfolio'), findsOneWidget);
  });
}
