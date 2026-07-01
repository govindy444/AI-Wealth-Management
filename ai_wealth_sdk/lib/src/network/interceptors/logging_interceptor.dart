import 'package:dio/dio.dart';

import '../../core/logging/sdk_logger.dart';

/// Logs outbound requests, responses, and errors through the SDK [SdkLogger]
/// (which is silent in release unless the host attaches a sink). Never logs
/// request/response bodies or the Authorization header to avoid leaking secrets.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this.logger);
  final SdkLogger logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.debug('→ ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.debug(
      '← ${response.statusCode} ${response.requestOptions.uri.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.warning(
      '✗ ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.uri.path}',
    );
    handler.next(err);
  }
}
