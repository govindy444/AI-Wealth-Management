import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/financial_health/data/datasources/financial_health_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/financial_health/data/models/financial_health_dto.dart';
import 'package:ai_wealth_sdk/src/financial_health/data/repositories/financial_health_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _json() => {
      'score': 72,
      'grade': 'B',
      'status': 'good',
      'pillars': [
        {
          'key': 'savings',
          'label': 'Savings',
          'score': 85,
          'status': 'excellent',
          'detail': 'You save 25%.',
          'recommendation': 'Keep it up.',
        },
        {
          'key': 'emergency_fund',
          'label': 'Emergency Fund',
          'score': 40,
          'status': 'fair',
          'detail': '2.4 months covered.',
          'recommendation': 'Build toward 6 months.',
        },
      ],
      'insight': {
        'summary': 'Your financial health is good (72/100, grade B).',
        'risks': ['Weakest area: Emergency Fund (40/100).'],
        'confidence': 0.82,
      },
    };

void main() {
  group('FinancialHealthDto', () {
    test('decodes score, pillars and insight', () {
      final h = FinancialHealthDto.fromJson(_json());
      expect(h.score, 72);
      expect(h.grade, 'B');
      expect(h.status, HealthStatus.good);
      expect(h.pillars, hasLength(2));
      expect(h.pillars.first.status, HealthStatus.excellent);
      expect(h.insight.confidencePercent, 82);
    });

    test('byPriority orders pillars weakest-first', () {
      final h = FinancialHealthDto.fromJson(_json());
      expect(h.byPriority.first.key, 'emergency_fund'); // score 40 < 85
    });
  });

  group('FinancialHealthController', () {
    FinancialHealthController controller(FakeRemote remote) {
      final repo = FinancialHealthRepositoryImpl(remote: remote, logger: _logger);
      return FinancialHealthController(getScore: GetHealthScoreUseCase(repo));
    }

    test('load populates the score', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, HealthScoreStatus.ready);
      expect(c.state.health?.score, 72);
    });

    test('surfaces an error on failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, HealthScoreStatus.error);
      expect(c.state.errorMessage, isNotNull);
    });
  });
}

class FakeRemote implements FinancialHealthRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  @override
  Future<FinancialHealth> getScore() async {
    if (_fail) throw NetworkException('offline');
    return FinancialHealthDto.fromJson(_json());
  }
}
