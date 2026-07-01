import 'package:dio/dio.dart';

import '../core/config/wealth_sdk_config.dart';
import '../core/logging/sdk_logger.dart';
import '../core/network/api_client.dart';
import '../core/network/api_request.dart';
import '../core/network/api_response.dart';
import '../core/network/http_method.dart';
import '../core/network/token_provider.dart';
import 'dio_error_mapper.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Production [ApiClient] backed by Dio. Wires the logging, retry, and auth
/// (token-attach + 401 refresh) interceptors and maps all Dio failures to the
/// SDK's transport exceptions. This is the override installed for
/// `apiClientProvider` by `WealthSdk.overrides`.
class DioApiClient implements ApiClient {
  DioApiClient({
    required WealthSdkConfig config,
    required TokenProvider tokenProvider,
    required SdkLogger logger,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = config.apiBaseUrl
      ..connectTimeout = config.connectTimeout
      ..receiveTimeout = config.receiveTimeout
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Tenant-Id': config.tenantId,
      })
      // Treat any >= 400 as an error so the interceptor chain (notably the auth
      // 401-refresh handler) runs; we map the thrown DioException ourselves.
      ..validateStatus = (status) => status != null && status < 400;

    _dio.interceptors.addAll([
      LoggingInterceptor(logger),
      RetryInterceptor(retry: _reissue, logger: logger),
      AuthInterceptor(tokenProvider: tokenProvider, retry: _reissue),
    ]);
  }

  final Dio _dio;

  /// Re-issues a request from its [RequestOptions] (used by retry/auth refresh).
  Future<Response<dynamic>> _reissue(RequestOptions options) =>
      _dio.fetch<dynamic>(options);

  @override
  Future<ApiResponse> send(ApiRequest request) async {
    try {
      final response = await _dio.request<dynamic>(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        options: Options(
          method: request.method.value,
          headers: request.headers,
          extra: {'requiresAuth': request.requiresAuth},
        ),
      );

      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        data: response.data,
        headers: response.headers.map,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) =>
      send(ApiRequest(
        path: path,
        queryParameters: queryParameters,
        requiresAuth: requiresAuth,
      ));

  @override
  Future<ApiResponse> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) =>
      send(ApiRequest(
        path: path,
        method: HttpMethod.post,
        data: data,
        queryParameters: queryParameters,
        requiresAuth: requiresAuth,
      ));

  @override
  Future<ApiResponse> put(String path, {Object? data, bool requiresAuth = true}) =>
      send(ApiRequest(
        path: path,
        method: HttpMethod.put,
        data: data,
        requiresAuth: requiresAuth,
      ));

  @override
  Future<ApiResponse> patch(String path, {Object? data, bool requiresAuth = true}) =>
      send(ApiRequest(
        path: path,
        method: HttpMethod.patch,
        data: data,
        requiresAuth: requiresAuth,
      ));

  @override
  Future<ApiResponse> delete(String path, {Object? data, bool requiresAuth = true}) =>
      send(ApiRequest(
        path: path,
        method: HttpMethod.delete,
        data: data,
        requiresAuth: requiresAuth,
      ));
}
