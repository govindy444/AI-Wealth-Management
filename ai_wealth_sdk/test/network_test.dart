import 'dart:convert';

import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Programmable Dio adapter: routes each request through [handler] and records it.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  /// Returns (statusCode, jsonBody) for a given request.
  (int, Map<String, dynamic>) Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeTokenProvider implements TokenProvider {
  FakeTokenProvider({this.token, this.refreshed});
  String? token;
  String? refreshed;
  int refreshCalls = 0;

  @override
  Future<String?> accessToken() async => token;
  @override
  Future<String?> refresh() async {
    refreshCalls++;
    token = refreshed;
    return refreshed;
  }

  @override
  Future<bool> isAuthenticated() async => token != null;
}

const _config = WealthSdkConfig(
  apiBaseUrl: 'https://api.test/api/v1',
  tenantId: 'idbi-demo',
);
final _logger = SdkLogger(minLevel: SdkLogLevel.error);

DioApiClient _client(FakeAdapter adapter, {TokenProvider? tokens}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return DioApiClient(
    config: _config,
    tokenProvider: tokens ?? FakeTokenProvider(),
    logger: _logger,
    dio: dio,
  );
}

void main() {
  test('GET returns decoded ApiResponse and sends tenant header', () async {
    final adapter = FakeAdapter((_) => (200, {'ok': true}));
    final client = _client(adapter, tokens: FakeTokenProvider(token: 't'));

    final res = await client.get('/health');
    expect(res.statusCode, 200);
    expect(res.asMap['ok'], true);
    expect(adapter.requests.single.headers['X-Tenant-Id'], 'idbi-demo');
  });

  test('attaches bearer token on authed requests', () async {
    final adapter = FakeAdapter((_) => (200, {}));
    final client = _client(adapter, tokens: FakeTokenProvider(token: 'abc'));

    await client.get('/accounts');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test('does not attach token when requiresAuth is false', () async {
    final adapter = FakeAdapter((_) => (200, {}));
    final client = _client(adapter, tokens: FakeTokenProvider(token: 'abc'));

    await client.post('/auth/login', data: {'x': 1}, requiresAuth: false);
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('maps backend error envelope to ServerException', () async {
    final adapter = FakeAdapter(
      (_) => (
        422,
        {
          'error': {'code': 'validation_error', 'message': 'Bad input'}
        }
      ),
    );
    final client = _client(adapter);

    expect(
      () => client.get('/x'),
      throwsA(isA<ServerException>()
          .having((e) => e.statusCode, 'status', 422)
          .having((e) => e.message, 'message', 'Bad input')),
    );
  });

  test('401 triggers refresh and retries once with new token', () async {
    final tokens = FakeTokenProvider(token: 'stale', refreshed: 'fresh');
    final adapter = FakeAdapter((options) {
      final auth = options.headers['Authorization'];
      return auth == 'Bearer fresh' ? (200, {'ok': true}) : (401, {
        'error': {'code': 'unauthorized', 'message': 'expired'}
      });
    });
    final client = _client(adapter, tokens: tokens);

    final res = await client.get('/secure');
    expect(res.statusCode, 200);
    expect(tokens.refreshCalls, 1);
    expect(adapter.requests.length, 2); // original + retry
  });

  test('401 with failed refresh surfaces AuthException', () async {
    final tokens = FakeTokenProvider(token: 'stale', refreshed: null);
    final adapter = FakeAdapter((_) => (401, {
          'error': {'code': 'unauthorized', 'message': 'nope'}
        }));
    final client = _client(adapter, tokens: tokens);

    expect(() => client.get('/secure'), throwsA(isA<AuthException>()));
  });

  test('retries transient connection errors then succeeds', () async {
    var calls = 0;
    final dio = Dio();
    // Custom adapter that throws a connection error on first call, then 200.
    dio.httpClientAdapter = _FlakyAdapter(() {
      calls++;
      if (calls == 1) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/x'),
          reason: 'reset',
        );
      }
      return (200, {'ok': true});
    });
    final client = DioApiClient(
      config: _config,
      tokenProvider: FakeTokenProvider(token: 't'),
      logger: _logger,
      dio: dio,
    );

    final res = await client.get('/x');
    expect(res.statusCode, 200);
    expect(calls, 2);
  });
}

/// Adapter whose callback may throw a [DioException] to simulate transport failures.
class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter(this.step);
  (int, Map<String, dynamic>) Function() step;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = step();
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
