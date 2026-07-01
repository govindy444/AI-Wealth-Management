import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/predictive/data/datasources/predictive_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/predictive/data/models/predictive_dtos.dart';
import 'package:ai_wealth_sdk/src/predictive/data/repositories/predictive_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _forecastJson() => {
      'as_of': '2026-06-29',
      'current_liquid_balance': 334700.0,
      'projected_month_end_balance': 290000.0,
      'predictions': [
        {
          'type': 'salary_credit',
          'title': 'Salary expected',
          'message': 'Your salary is expected.',
          'predicted_date': '2026-07-01',
          'days_away': 2,
          'severity': 'info',
          'amount': 145000.0,
        },
        {
          'type': 'emi_due',
          'title': 'EMI due: Home Loan',
          'message': '₹21,500 due.',
          'predicted_date': '2026-07-05',
          'days_away': 6,
          'severity': 'warning',
          'amount': 21500.0,
        },
        {
          'type': 'low_balance',
          'title': 'Low balance ahead',
          'message': 'Balance may fall.',
          'predicted_date': '2026-07-03',
          'days_away': 4,
          'severity': 'critical',
          'amount': 12000.0,
        },
      ],
      'insight': {'summary': 'Heads up — low balance ahead.', 'confidence': 0.75},
    };

void main() {
  group('PredictiveDtos', () {
    test('decodes a forecast with typed, dated predictions', () {
      final f = PredictiveDtos.forecastFromJson(_forecastJson());
      expect(f.currentLiquidBalance, 334700.0);
      expect(f.predictions, hasLength(3));
      expect(f.predictions.first.type, PredictionType.salaryCredit);
      expect(f.predictions.first.amount, 145000.0);
      expect(f.insight.confidencePercent, 75);
    });

    test('alerts surfaces only warning/critical predictions', () {
      final f = PredictiveDtos.forecastFromJson(_forecastJson());
      final alertTypes = f.alerts.map((p) => p.type).toSet();
      expect(alertTypes, {PredictionType.emiDue, PredictionType.lowBalance});
      expect(alertTypes.contains(PredictionType.salaryCredit), isFalse);
    });

    test('handles a null amount', () {
      final json = _forecastJson();
      json['predictions'] = [
        {
          'type': 'tax_reminder',
          'title': 'Tax reminder',
          'message': 'Plan 80C.',
          'predicted_date': '2026-07-15',
          'days_away': 16,
          'severity': 'info',
          'amount': null,
        },
      ];
      final f = PredictiveDtos.forecastFromJson(json);
      expect(f.predictions.single.amount, isNull);
      expect(f.predictions.single.type, PredictionType.taxReminder);
    });
  });

  group('PredictiveController', () {
    PredictiveController controller(FakeRemote remote) {
      final repo = PredictiveRepositoryImpl(remote: remote, logger: _logger);
      return PredictiveController(getForecast: GetForecastUseCase(repo));
    }

    test('load populates the forecast', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, PredictiveStatus.ready);
      expect(c.state.forecast?.predictions, hasLength(3));
    });

    test('surfaces an error on failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, PredictiveStatus.error);
    });
  });
}

class FakeRemote implements PredictiveRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  @override
  Future<Forecast> getForecast() async {
    if (_fail) throw NetworkException('offline');
    return PredictiveDtos.forecastFromJson(_forecastJson());
  }
}
