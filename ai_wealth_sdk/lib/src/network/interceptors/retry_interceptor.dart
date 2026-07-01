import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/logging/sdk_logger.dart';

/// Retries transient transport failures (timeouts, connection errors) with
/// exponential backoff. Does NOT retry HTTP error responses (4xx/5xx) — those
/// are deterministic and handled elsewhere.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.retry,
    required this.logger,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 300),
  });

  final Future<Response<dynamic>> Function(RequestOptions options) retry;
  final SdkLogger logger;
  final int maxRetries;
  final Duration baseDelay;

  static const _attemptKey = 'retry_attempt';

  bool _isTransient(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_isTransient(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final nextAttempt = attempt + 1;
    final delay = baseDelay * (1 << attempt); // 300ms, 600ms, ...
    logger.warning(
      'Transient network error; retrying ($nextAttempt/$maxRetries) in '
      '${delay.inMilliseconds}ms',
      data: options.path,
    );
    await Future<void>.delayed(delay);

    options.extra[_attemptKey] = nextAttempt;
    try {
      final response = await retry(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
