import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/spending/spending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpendingRepository implements SpendingRepository {
  @override
  Future<Result<SpendingSummary>> getSummary({String? month}) async => success(
        SpendingSummary(
          month: '2026-06',
          totalSpent: 20000,
          totalIncome: 145000,
          net: 125000,
          previousMonthSpent: 16000,
          changePct: 25,
          categories: const [
            CategorySpend(
                category: SpendCategory.dining, amount: 12000, percentage: 60),
            CategorySpend(
                category: SpendCategory.groceries, amount: 8000, percentage: 40),
          ],
          topMerchants: const ['Swiggy', 'BigBasket'],
          insight: const Explanation(
            summary: 'You spent ₹20,000 this month, up 25%.',
            reasons: ['Dining is your biggest category.'],
            confidence: 0.78,
          ),
        ),
      );

  @override
  Future<Result<List<Budget>>> getBudgets({String? month}) async => success(const [
        Budget(
          category: SpendCategory.dining,
          monthlyLimit: 4000,
          spent: 12000,
          remaining: -8000,
          usedPct: 300,
          status: BudgetStatus.over,
        ),
      ]);

  @override
  Future<Result<Paginated<Transaction>>> getTransactions({
    String? month,
    SpendCategory? category,
    int limit = 50,
    int offset = 0,
  }) async =>
      success(const Paginated(items: [], page: 1, pageSize: 0, total: 0));

  @override
  Future<Result<Budget>> setBudget({
    required SpendCategory category,
    required double monthlyLimit,
  }) async =>
      success(Budget(
        category: category,
        monthlyLimit: monthlyLimit,
        spent: 12000,
        remaining: monthlyLimit - 12000,
        usedPct: 12000 / monthlyLimit * 100,
        status: BudgetStatus.over,
      ));
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        spendingRepositoryProvider.overrideWithValue(_FakeSpendingRepository()),
      ],
      child: const MaterialApp(home: SpendingScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders summary, categories, insight and budgets', (tester) async {
    await _pump(tester);

    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.textContaining('25% vs last month'), findsOneWidget);
    expect(find.text('Dining'), findsWidgets); // category + budget
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.textContaining('up 25%'), findsOneWidget); // insight
    expect(find.text('Budgets'), findsOneWidget);
    // Over-budget warning icon present.
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
