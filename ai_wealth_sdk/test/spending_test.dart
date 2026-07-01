import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/spending/data/datasources/spending_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/spending/data/models/spending_dtos.dart';
import 'package:ai_wealth_sdk/src/spending/data/repositories/spending_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _summaryJson() => {
      'month': '2026-06',
      'total_spent': 20000.0,
      'total_income': 145000.0,
      'net': 125000.0,
      'previous_month_spent': 16000.0,
      'change_pct': 25.0,
      'categories': [
        {'category': 'dining', 'amount': 12000.0, 'percentage': 60.0},
        {'category': 'groceries', 'amount': 8000.0, 'percentage': 40.0},
      ],
      'top_merchants': ['Swiggy', 'BigBasket'],
      'insight': {'summary': 'Spending up 25%.', 'reasons': ['Dining led.'], 'confidence': 0.78},
    };

Map<String, dynamic> _budgetJson(String status) => {
      'category': 'dining',
      'monthly_limit': 4000.0,
      'spent': 12000.0,
      'remaining': -8000.0,
      'used_pct': 300.0,
      'status': status,
    };

void main() {
  group('SpendingDtos', () {
    test('decodes summary with categories, trend and insight', () {
      final s = SpendingDtos.summaryFromJson(_summaryJson());
      expect(s.month, '2026-06');
      expect(s.isUp, isTrue);
      expect(s.categories.first.category, SpendCategory.dining);
      expect(s.categories.first.percentage, 60.0);
      expect(s.insight.confidencePercent, 78);
      expect(s.topMerchants, ['Swiggy', 'BigBasket']);
    });

    test('decodes a budget with status', () {
      final b = SpendingDtos.budgetFromJson(_budgetJson('over'));
      expect(b.category, SpendCategory.dining);
      expect(b.status, BudgetStatus.over);
      expect(b.remaining, -8000.0);
    });

    test('category enum round-trips through wire values', () {
      for (final c in SpendCategory.values) {
        expect(SpendCategory.fromWire(c.wire), c);
      }
    });
  });

  group('SpendingController', () {
    SpendingController controller(FakeRemote remote) {
      final repo = SpendingRepositoryImpl(remote: remote, logger: _logger);
      return SpendingController(
        getSummary: GetSpendingSummaryUseCase(repo),
        getBudgets: GetBudgetsUseCase(repo),
        setBudget: SetBudgetUseCase(repo),
      );
    }

    test('load fetches summary and budgets', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);

      await c.load();

      expect(c.state.status, SpendingStatus.ready);
      expect(c.state.summary?.totalSpent, 20000.0);
      expect(c.state.budgets, hasLength(1));
    });

    test('setBudget updates the matching budget in place', () async {
      final remote = FakeRemote();
      final c = controller(remote);
      addTearDown(c.dispose);
      await c.load();

      remote.nextBudgetStatus = 'near'; // server recomputes after the change
      final ok = await c.setBudget(SpendCategory.dining, 20000);

      expect(ok, isTrue);
      expect(remote.lastSetLimit, 20000);
      expect(
        c.state.budgets.firstWhere((b) => b.category == SpendCategory.dining).status,
        BudgetStatus.near,
      );
    });

    test('surfaces an error when the summary fails', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, SpendingStatus.error);
    });
  });
}

class FakeRemote implements SpendingRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  String nextBudgetStatus = 'over';
  double? lastSetLimit;

  @override
  Future<SpendingSummary> getSummary({String? month}) async {
    if (_fail) throw NetworkException('offline');
    return SpendingDtos.summaryFromJson(_summaryJson());
  }

  @override
  Future<Paginated<Transaction>> getTransactions({
    String? month,
    SpendCategory? category,
    int limit = 50,
    int offset = 0,
  }) async =>
      Paginated.fromJson(
        {'items': const [], 'total': 0},
        SpendingDtos.transactionFromJson,
      );

  @override
  Future<List<Budget>> getBudgets({String? month}) async =>
      [SpendingDtos.budgetFromJson(_budgetJson('over'))];

  @override
  Future<Budget> setBudget({
    required SpendCategory category,
    required double monthlyLimit,
  }) async {
    lastSetLimit = monthlyLimit;
    return SpendingDtos.budgetFromJson(_budgetJson(nextBudgetStatus));
  }
}
