import 'package:dio/dio.dart';

import '../../core/network/token_provider.dart';

/// Attaches the bearer token to authenticated requests and transparently
/// refreshes it on a 401, retrying the original request once.
///
/// Uses [QueuedInterceptor] so concurrent requests don't trigger multiple
/// simultaneous refreshes — they queue behind the first one.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokenProvider, required this.retry});

  final TokenProvider tokenProvider;

  /// Re-issues a request (injected to avoid a hard dependency on the Dio
  /// instance and to keep this interceptor unit-testable).
  final Future<Response<dynamic>> Function(RequestOptions options) retry;

  static const _retriedFlag = 'auth_retried';

  bool _requiresAuth(RequestOptions options) =>
      options.extra['requiresAuth'] != false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_requiresAuth(options)) {
      final token = await tokenProvider.accessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final options = err.requestOptions;
    final alreadyRetried = options.extra[_retriedFlag] == true;

    final shouldAttemptRefresh = response?.statusCode == 401 &&
        _requiresAuth(options) &&
        !alreadyRetried;

    if (!shouldAttemptRefresh) {
      return handler.next(err);
    }

    final newToken = await tokenProvider.refresh();
    if (newToken == null) {
      // Refresh failed → propagate the original 401.
      return handler.next(err);
    }

    options
      ..extra[_retriedFlag] = true
      ..headers['Authorization'] = 'Bearer $newToken';

    try {
      final cloned = await retry(options);
      return handler.resolve(cloned);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
