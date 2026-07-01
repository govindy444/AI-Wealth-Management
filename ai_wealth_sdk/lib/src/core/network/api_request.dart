import 'http_method.dart';


class ApiRequest {
  const ApiRequest({
    required this.path,
    this.method = HttpMethod.get,
    this.queryParameters,
    this.data,
    this.headers,
    this.requiresAuth = true,
  });

  final String path;
  final HttpMethod method;
  final Map<String, dynamic>? queryParameters;

  final Object? data;
  final Map<String, String>? headers;

  final bool requiresAuth;

  ApiRequest copyWith({
    String? path,
    HttpMethod? method,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    bool? requiresAuth,
  }) {
    return ApiRequest(
      path: path ?? this.path,
      method: method ?? this.method,
      queryParameters: queryParameters ?? this.queryParameters,
      data: data ?? this.data,
      headers: headers ?? this.headers,
      requiresAuth: requiresAuth ?? this.requiresAuth,
    );
  }
}
