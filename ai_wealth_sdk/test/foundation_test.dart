import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo with BaseRepository {
  _Repo(this.logger);
  @override
  final SdkLogger logger;
}

void main() {
  final logger = SdkLogger(minLevel: SdkLogLevel.error);

  group('BaseRepository.guard', () {
    final repo = _Repo(logger);

    test('returns success when action completes', () async {
      final r = await repo.guard(() async => 7);
      expect(r.getOrElse(() => -1), 7);
    });

    test('maps AuthException -> AuthFailure', () async {
      final r = await repo.guard<int>(() async => throw AuthException('nope', code: '401'));
      expect(r.isLeft(), isTrue);
      r.fold((f) => expect(f, isA<AuthFailure>()), (_) => fail('expected left'));
    });

    test('maps ServerException -> ServerFailure with status', () async {
      final r = await repo.guard<int>(
        () async => throw ServerException('boom', statusCode: 500),
      );
      r.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect((f as ServerFailure).statusCode, 500);
        },
        (_) => fail('expected left'),
      );
    });

    test('maps NetworkException -> NetworkFailure', () async {
      final r = await repo.guard<int>(() async => throw NetworkException('offline'));
      r.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('expected left'));
    });

    test('maps unknown error -> UnexpectedFailure', () async {
      final r = await repo.guard<int>(() async => throw StateError('x'));
      r.fold((f) => expect(f, isA<UnexpectedFailure>()), (_) => fail('expected left'));
    });
  });

  group('InMemoryKeyValueStore', () {
    test('round-trips typed values and removal', () async {
      final s = InMemoryKeyValueStore();
      await s.setString('a', 'hello');
      await s.setBool('b', true);
      await s.setInt('c', 42);

      expect(await s.getString('a'), 'hello');
      expect(await s.getBool('b'), true);
      expect(await s.getInt('c'), 42);
      expect(await s.containsKey('a'), true);

      await s.remove('a');
      expect(await s.containsKey('a'), false);

      await s.clear();
      expect(await s.containsKey('b'), false);
    });
  });

  group('InMemorySecureStore', () {
    test('round-trips and deletes', () async {
      final s = InMemorySecureStore();
      await s.write('token', 'secret');
      expect(await s.read('token'), 'secret');
      expect(await s.contains('token'), true);
      await s.delete('token');
      expect(await s.read('token'), isNull);
    });
  });

  group('UnauthenticatedTokenProvider', () {
    test('reports logged out', () async {
      const p = UnauthenticatedTokenProvider();
      expect(await p.accessToken(), isNull);
      expect(await p.refresh(), isNull);
      expect(await p.isAuthenticated(), isFalse);
    });
  });

  group('Paginated.fromJson', () {
    test('parses items and computes hasMore', () {
      final json = {
        'items': [
          {'v': 1},
          {'v': 2},
        ],
        'page': 1,
        'page_size': 2,
        'total': 5,
      };
      final p = Paginated<int>.fromJson(json, (m) => m['v'] as int);
      expect(p.items, [1, 2]);
      expect(p.total, 5);
      expect(p.hasMore, isTrue);
    });
  });

  group('SdkLogger', () {
    test('forwards records to host sink and respects minLevel', () {
      final records = <SdkLogRecord>[];
      final l = SdkLogger(
        minLevel: SdkLogLevel.warning,
        onRecord: records.add,
      );
      l.debug('ignored');
      l.info('ignored');
      l.warning('kept');
      l.error('kept too');

      expect(records.length, 2);
      expect(records.first.level, SdkLogLevel.warning);
    });
  });
}
