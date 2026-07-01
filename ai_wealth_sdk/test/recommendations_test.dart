import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/recommendations/data/datasources/recommendation_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/recommendations/data/models/recommendation_dtos.dart';
import 'package:ai_wealth_sdk/src/recommendations/data/repositories/recommendation_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _product(String id, String type) => {
      'id': id,
      'name': 'IDBI $id',
      'type': type,
      'risk_level': 'moderate',
      'expected_return': 0.11,
      'min_investment': 500.0,
      'description': 'A product.',
      'tags': ['equity'],
    };

Map<String, dynamic> _setJson(String profile) => {
      'risk_profile': profile,
      'total_amount': 200000.0,
      'horizon_years': 7,
      'blended_expected_return': 0.105,
      'recommendations': [
        {
          'product': _product('idbi_nifty_index', 'index_fund'),
          'allocation_pct': 60.0,
          'suggested_amount': 120000.0,
          'rationale': {'summary': 'Growth engine.', 'risks': ['Volatile.'], 'confidence': 0.7},
        },
        {
          'product': _product('idbi_fd', 'fixed_deposit'),
          'allocation_pct': 40.0,
          'suggested_amount': 80000.0,
          'rationale': {'summary': 'Capital-safe anchor.', 'confidence': 0.7},
        },
      ],
      'insight': {'summary': 'A $profile portfolio.', 'confidence': 0.72},
    };

void main() {
  group('RecommendationDtos', () {
    test('decodes a recommendation set with rationale per item', () {
      final set = RecommendationDtos.setFromJson(_setJson('moderate'));
      expect(set.riskProfile, RiskProfile.moderate);
      expect(set.blendedExpectedReturn, 0.105);
      expect(set.recommendations, hasLength(2));

      final first = set.recommendations.first;
      expect(first.product.type, ProductType.indexFund);
      expect(first.product.type.isEquity, isTrue);
      expect(first.allocationPct, 60.0);
      expect(first.rationale.confidencePercent, 70);
      expect(set.insight.summary, 'A moderate portfolio.');
    });
  });

  group('RecommendationsController', () {
    RecommendationsController controller(FakeRemote remote) {
      final repo = RecommendationRepositoryImpl(remote: remote, logger: _logger);
      return RecommendationsController(recommend: RecommendUseCase(repo));
    }

    test('load fetches a recommendation for the default profile', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, RecommendationsStatus.ready);
      expect(c.state.recommendation?.recommendations, hasLength(2));
    });

    test('selectProfile re-fetches for the new profile', () async {
      final remote = FakeRemote();
      final c = controller(remote);
      addTearDown(c.dispose);
      await c.selectProfile(RiskProfile.aggressive);
      expect(remote.lastProfile, 'aggressive');
      expect(c.state.riskProfile, RiskProfile.aggressive);
    });

    test('surfaces an error on failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, RecommendationsStatus.error);
    });
  });
}

class FakeRemote implements RecommendationRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;
  String? lastProfile;

  @override
  Future<List<InvestmentProduct>> listProducts() async =>
      [RecommendationDtos.productFromJson(_product('idbi_fd', 'fixed_deposit'))];

  @override
  Future<RecommendationSet> recommend({
    required String riskProfile,
    required double amount,
    required int horizonYears,
  }) async {
    lastProfile = riskProfile;
    if (_fail) throw NetworkException('offline');
    return RecommendationDtos.setFromJson(_setJson(riskProfile));
  }
}
