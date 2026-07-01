import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/portfolio/data/datasources/portfolio_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/portfolio/data/models/portfolio_dtos.dart';
import 'package:ai_wealth_sdk/src/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _summaryJson() => {
      'total_value': 797000.0,
      'total_invested': 720000.0,
      'total_gain': 77000.0,
      'gain_pct': 10.7,
      'risk_score': 50,
      'risk_label': 'moderate',
      'diversification_score': 68,
      'allocation': [
        {'asset_class': 'debt', 'percentage': 42.7, 'value': 340000.0},
        {'asset_class': 'equity', 'percentage': 37.6, 'value': 300000.0},
        {'asset_class': 'cash', 'percentage': 11.3, 'value': 90000.0},
        {'asset_class': 'gold', 'percentage': 8.4, 'value': 67000.0},
      ],
      'top_holdings': [
        {
          'id': 'hld_fd',
          'name': 'IDBI Fixed Deposit',
          'asset_class': 'debt',
          'invested': 200000.0,
          'current_value': 212000.0,
          'gain': 12000.0,
          'gain_pct': 6.0,
        },
      ],
      'insight': {'summary': 'Moderate risk portfolio.', 'confidence': 0.8},
    };

void main() {
  group('PortfolioDtos', () {
    test('decodes summary with allocation, risk and holdings', () {
      final s = PortfolioDtos.summaryFromJson(_summaryJson());
      expect(s.totalValue, 797000.0);
      expect(s.isUp, isTrue);
      expect(s.riskLabel, RiskLabel.moderate);
      expect(s.diversificationScore, 68);
      expect(s.allocation.first.assetClass, AssetClass.debt);
      expect(s.allocation.first.percentage, 42.7);
      expect(s.topHoldings.first.assetClass, AssetClass.debt);
      expect(s.insight.confidencePercent, 80);
    });

    test('asset class wire round-trip incl. real_estate', () {
      expect(AssetClass.fromWire('real_estate'), AssetClass.realEstate);
      expect(AssetClass.fromWire('equity'), AssetClass.equity);
    });
  });

  group('PortfolioController', () {
    PortfolioController controller(FakeRemote remote) {
      final repo = PortfolioRepositoryImpl(remote: remote, logger: _logger);
      return PortfolioController(getSummary: GetPortfolioSummaryUseCase(repo));
    }

    test('load populates the summary', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, PortfolioStatus.ready);
      expect(c.state.summary?.riskScore, 50);
    });

    test('surfaces an error on failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, PortfolioStatus.error);
    });
  });
}

class FakeRemote implements PortfolioRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  @override
  Future<PortfolioSummary> getSummary() async {
    if (_fail) throw NetworkException('offline');
    return PortfolioDtos.summaryFromJson(_summaryJson());
  }

  @override
  Future<List<Holding>> getHoldings() async => const [];
}
