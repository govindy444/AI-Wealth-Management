import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:ai_wealth_sdk/src/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/dashboard/data/models/dashboard_dto.dart';
import 'package:ai_wealth_sdk/src/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// Representative backend payload (matches `DashboardService` output shape).
Map<String, dynamic> _payload({double netWorth = 100000}) => {
      'user_id': 'usr_demo_0001',
      'full_name': 'Demo User',
      'currency': 'INR',
      'net_worth': netWorth,
      'total_assets': 150000.0,
      'total_liabilities': 50000.0,
      'monthly_change': 5000.0,
      'accounts': [
        {
          'id': 'acc_sav_01',
          'name': 'IDBI Savings',
          'type': 'savings',
          'masked_number': '4821',
          'balance': 150000.0,
          'currency': 'INR',
          'monthly_change': 5000.0,
          'is_liability': false,
        },
        {
          'id': 'acc_cc_01',
          'name': 'Credit Card',
          'type': 'credit_card',
          'masked_number': '3302',
          'balance': 50000.0,
          'currency': 'INR',
          'monthly_change': 1000.0,
          'is_liability': true,
        },
      ],
      'insight': {
        'summary': 'Your net worth grew this month.',
        'reasons': ['Assets exceed liabilities.'],
        'risks': const [],
        'benefits': ['Positive monthly trend.'],
        'alternatives': const [],
        'citations': ['Latest sync.'],
        'confidence': 0.8,
      },
    };

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

void main() {
  group('DashboardDto.toEntity', () {
    test('decodes summary, accounts and explanation', () {
      final summary = DashboardDto.fromJson(_payload()).toEntity();

      expect(summary.fullName, 'Demo User');
      expect(summary.netWorth, 100000);
      expect(summary.isUp, isTrue);
      expect(summary.accounts.length, 2);
      expect(summary.assets.single.type, AccountType.savings);
      expect(summary.liabilities.single.type, AccountType.creditCard);
      expect(summary.liabilities.single.isLiability, isTrue);
      expect(summary.insight.summary, 'Your net worth grew this month.');
      expect(summary.insight.confidencePercent, 80);
    });

    test('tolerates missing fields without throwing', () {
      final summary = DashboardDto.fromJson(const {}).toEntity();
      expect(summary.accounts, isEmpty);
      expect(summary.currency, 'INR');
      expect(summary.insight.summary, '');
    });
  });

  group('DashboardRepositoryImpl', () {
    test('fetches from remote and caches the snapshot', () async {
      final remote = FakeRemote(_payload(netWorth: 222000));
      final local = FakeLocal();
      final repo = DashboardRepositoryImpl(
        remote: remote, local: local, logger: _logger);

      final result = await repo.getDashboard();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (s) => expect(s.netWorth, 222000));
      expect(remote.calls, 1);
      expect(local.cached, isNotNull); // snapshot persisted
    });

    test('serves cached snapshot when the network is down', () async {
      final local = FakeLocal()..cached = DashboardDto.fromJson(_payload(netWorth: 999));
      final remote = FakeRemote.offline();
      final repo = DashboardRepositoryImpl(
        remote: remote, local: local, logger: _logger);

      final result = await repo.getDashboard();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (s) => expect(s.netWorth, 999));
    });

    test('propagates NetworkFailure when offline and no cache exists', () async {
      final repo = DashboardRepositoryImpl(
        remote: FakeRemote.offline(), local: FakeLocal(), logger: _logger);

      final result = await repo.getDashboard();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('expected failure'));
    });
  });
}

class FakeRemote implements DashboardRemoteDataSource {
  FakeRemote(this._payload) : _offline = false;
  FakeRemote.offline()
      : _payload = const {},
        _offline = true;

  final Map<String, dynamic> _payload;
  final bool _offline;
  int calls = 0;

  @override
  Future<DashboardDto> fetchDashboard() async {
    calls++;
    if (_offline) throw NetworkException('no connection');
    return DashboardDto.fromJson(_payload);
  }
}

class FakeLocal implements DashboardLocalDataSource {
  DashboardDto? cached;

  @override
  Future<void> cache(DashboardDto dto) async => cached = dto;
  @override
  Future<DashboardDto?> readCached() async => cached;
  @override
  Future<void> clear() async => cached = null;
}
