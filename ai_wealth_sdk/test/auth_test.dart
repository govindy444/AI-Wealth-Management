import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/auth_repository_impl_harness.dart';

/// A scriptable fake ApiClient that records calls and returns canned responses.
class FakeApiClient implements ApiClient {
  final List<ApiRequest> sent = [];
  ApiResponse Function(ApiRequest req)? responder;
  Object? throwOnSend;

  ApiResponse _handle(ApiRequest req) {
    sent.add(req);
    if (throwOnSend != null) throw throwOnSend!;
    return responder?.call(req) ?? const ApiResponse(statusCode: 200, data: {});
  }

  @override
  Future<ApiResponse> send(ApiRequest request) async => _handle(request);
  @override
  Future<ApiResponse> get(String path,
          {Map<String, dynamic>? queryParameters, bool requiresAuth = true}) async =>
      _handle(ApiRequest(path: path, requiresAuth: requiresAuth));
  @override
  Future<ApiResponse> post(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          bool requiresAuth = true}) async =>
      _handle(ApiRequest(
          path: path, method: HttpMethod.post, data: data, requiresAuth: requiresAuth));
  @override
  Future<ApiResponse> put(String path, {Object? data, bool requiresAuth = true}) async =>
      _handle(ApiRequest(path: path, method: HttpMethod.put, data: data));
  @override
  Future<ApiResponse> patch(String path, {Object? data, bool requiresAuth = true}) async =>
      _handle(ApiRequest(path: path, method: HttpMethod.patch, data: data));
  @override
  Future<ApiResponse> delete(String path, {Object? data, bool requiresAuth = true}) async =>
      _handle(ApiRequest(path: path, method: HttpMethod.delete, data: data));
}

Map<String, dynamic> _tokenPayload({String email = 'demo@idbi.example'}) => {
      'access_token': 'access-123',
      'refresh_token': 'refresh-456',
      'token_type': 'bearer',
      'expires_in': 1800,
      'user': {
        'id': 'usr_1',
        'email': email,
        'full_name': 'Demo User',
        'roles': ['customer'],
      },
    };

void main() {
  late FakeApiClient client;
  late InMemorySecureStore store;
  late AuthHarness h;

  setUp(() {
    client = FakeApiClient();
    store = InMemorySecureStore();
    h = AuthHarness(client: client, store: store);
  });

  group('login', () {
    test('success persists session and returns it', () async {
      client.responder = (_) => ApiResponse(statusCode: 200, data: _tokenPayload());

      final result = await h.repository.login(
        email: 'demo@idbi.example',
        password: 'Password@123',
      );

      expect(result.isRight(), isTrue);
      final session = result.getOrElse(() => throw 'no');
      expect(session.accessToken, 'access-123');
      expect(session.user.email, 'demo@idbi.example');
      // Persisted to secure store.
      expect(await store.contains('wealth_sdk.auth.session'), isTrue);
      // Did NOT attach auth header on the login call.
      expect(client.sent.single.requiresAuth, isFalse);
    });

    test('maps server auth exception to AuthFailure', () async {
      client.throwOnSend = AuthException('Invalid email or password.', code: '401');

      final result = await h.repository.login(email: 'x@y.z', password: 'bad');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<AuthFailure>()), (_) => fail('expected left'));
      expect(await store.contains('wealth_sdk.auth.session'), isFalse);
    });
  });

  group('currentSession / logout', () {
    test('currentSession returns null when nothing stored', () async {
      final r = await h.repository.currentSession();
      expect(r.getOrElse(() => throw 'x'), isNull);
    });

    test('logout clears stored session', () async {
      client.responder = (_) => ApiResponse(statusCode: 200, data: _tokenPayload());
      await h.repository.login(email: 'demo@idbi.example', password: 'p');
      expect(await store.contains('wealth_sdk.auth.session'), isTrue);

      final r = await h.repository.logout();
      expect(r.isRight(), isTrue);
      expect(await store.contains('wealth_sdk.auth.session'), isFalse);
    });
  });

  group('SessionTokenProvider', () {
    test('returns stored access token when valid', () async {
      client.responder = (_) => ApiResponse(statusCode: 200, data: _tokenPayload());
      await h.repository.login(email: 'demo@idbi.example', password: 'p');

      expect(await h.tokenProvider.isAuthenticated(), isTrue);
      expect(await h.tokenProvider.accessToken(), 'access-123');
    });

    test('refreshes when access token expired', () async {
      // Seed an already-expired session directly.
      await h.local.cacheSession(
        AuthSession(
          accessToken: 'old',
          refreshToken: 'refresh-456',
          user: const AuthUser(id: 'usr_1', email: 'd@e.f', fullName: 'D'),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      client.responder = (_) => ApiResponse(
            statusCode: 200,
            data: {..._tokenPayload(), 'access_token': 'fresh-789'},
          );

      final token = await h.tokenProvider.accessToken();
      expect(token, 'fresh-789');
    });

    test('clears session when refresh fails', () async {
      await h.local.cacheSession(
        AuthSession(
          accessToken: 'old',
          refreshToken: 'refresh-456',
          user: const AuthUser(id: 'usr_1', email: 'd@e.f', fullName: 'D'),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      client.throwOnSend = AuthException('expired', code: '401');

      expect(await h.tokenProvider.accessToken(), isNull);
      expect(await h.tokenProvider.isAuthenticated(), isFalse);
    });
  });
}
