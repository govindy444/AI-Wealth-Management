import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/fraud/data/datasources/fraud_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/fraud/data/models/fraud_dtos.dart';
import 'package:ai_wealth_sdk/src/fraud/data/repositories/fraud_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _alertsJson() => {
      'scanned_count': 8,
      'alerts': [
        {
          'id': 'alert_amt_1',
          'type': 'unusual_amount',
          'risk_level': 'high',
          'merchant': 'QuickElectronics Online',
          'amount': 48999.0,
          'date': '2026-06-28',
          'reason': 'Far above typical spend.',
        },
        {
          'id': 'alert_dup_1',
          'type': 'duplicate_charge',
          'risk_level': 'medium',
          'merchant': 'PayFast Services',
          'amount': 2999.0,
          'date': '2026-06-27',
          'reason': 'Two identical charges.',
        },
      ],
      'insight': {'summary': '2 alerts found.', 'confidence': 0.75},
    };

Map<String, dynamic> _checkJson(String level, int score, bool safe) => {
      'risk_level': level,
      'score': score,
      'is_safe': safe,
      'explanation': {'summary': 'Scam.', 'reasons': ['Asks for OTP.'], 'confidence': 0.7},
    };

void main() {
  group('FraudDtos', () {
    test('decodes alerts with risk levels and insight', () {
      final r = FraudDtos.alertsFromJson(_alertsJson());
      expect(r.scannedCount, 8);
      expect(r.alerts, hasLength(2));
      expect(r.highRisk, hasLength(1));
      expect(r.alerts.first.type, FraudAlertType.unusualAmount);
      expect(r.alerts.first.riskLevel, FraudRiskLevel.high);
      expect(r.insight.confidencePercent, 75);
    });

    test('decodes a message check', () {
      final c = FraudDtos.messageCheckFromJson(_checkJson('high', 60, false));
      expect(c.riskLevel, FraudRiskLevel.high);
      expect(c.score, 60);
      expect(c.isSafe, isFalse);
    });
  });

  group('FraudController', () {
    FraudController controller(FakeRemote remote) {
      final repo = FraudRepositoryImpl(remote: remote, logger: _logger);
      return FraudController(
        getAlerts: GetFraudAlertsUseCase(repo),
        checkMessage: CheckMessageUseCase(repo),
      );
    }

    test('loadAlerts populates the report', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.loadAlerts();
      expect(c.state.status, FraudStatus.ready);
      expect(c.state.report?.highRisk, hasLength(1));
    });

    test('checkMessage stores the scan result', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.checkMessage('Share your OTP now');
      expect(c.state.checking, isFalse);
      expect(c.state.messageCheck?.riskLevel, FraudRiskLevel.high);
    });

    test('checkMessage ignores blank input', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.checkMessage('   ');
      expect(c.state.messageCheck, isNull);
    });

    test('surfaces an error when alerts fail', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.loadAlerts();
      expect(c.state.status, FraudStatus.error);
    });
  });
}

class FakeRemote implements FraudRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  @override
  Future<FraudAlerts> getAlerts() async {
    if (_fail) throw NetworkException('offline');
    return FraudDtos.alertsFromJson(_alertsJson());
  }

  @override
  Future<MessageCheck> checkMessage(String text) async =>
      FraudDtos.messageCheckFromJson(_checkJson('high', 60, false));
}
