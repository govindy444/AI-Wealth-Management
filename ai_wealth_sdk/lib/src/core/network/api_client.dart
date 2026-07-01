import 'api_request.dart';
import 'api_response.dart';


abstract interface class ApiClient {
  Future<ApiResponse> send(ApiRequest request);

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

  Future<ApiResponse> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  });

  Future<ApiResponse> put(String path, {Object? data, bool requiresAuth = true});

  Future<ApiResponse> patch(String path, {Object? data, bool requiresAuth = true});

  Future<ApiResponse> delete(String path, {Object? data, bool requiresAuth = true});
}
