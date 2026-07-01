import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/wealth_sdk_config.dart';
import '../logging/sdk_logger.dart';
import '../network/api_client.dart';
import '../network/api_request.dart';
import '../network/api_response.dart';
import '../network/token_provider.dart';
import '../storage/key_value_store.dart';
import '../storage/secure_store.dart';


final wealthSdkConfigProvider = Provider<WealthSdkConfig>((ref) {
  throw StateError(
    'WealthSdkConfig was not provided. Call WealthSdk.initialize() and install '
    'the returned overrides into a ProviderScope.',
  );
});

final sdkLoggerProvider = Provider<SdkLogger>((ref) {
  final config = ref.watch(wealthSdkConfigProvider);
  return SdkLogger(
    minLevel: config.environment == WealthSdkEnvironment.production
        ? SdkLogLevel.warning
        : SdkLogLevel.debug,
  );
});


final secureStoreProvider = Provider<SecureStore>((ref) => InMemorySecureStore());


final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => InMemoryKeyValueStore(),
);


final tokenProviderProvider = Provider<TokenProvider>(
  (ref) => const UnauthenticatedTokenProvider(),
);


final apiClientProvider = Provider<ApiClient>((ref) {
  return _UnconfiguredApiClient();
});


class _UnconfiguredApiClient implements ApiClient {
  Never _fail() => throw StateError(
        'ApiClient is not configured. The Dio-backed client is installed by '
        'Module 5 (Networking/API layer).',
      );

  @override
  Future<ApiResponse> send(ApiRequest request) async => _fail();
  @override
  Future<ApiResponse> get(String path,
          {Map<String, dynamic>? queryParameters, bool requiresAuth = true}) async =>
      _fail();
  @override
  Future<ApiResponse> post(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          bool requiresAuth = true}) async =>
      _fail();
  @override
  Future<ApiResponse> put(String path,
          {Object? data, bool requiresAuth = true}) async =>
      _fail();
  @override
  Future<ApiResponse> patch(String path,
          {Object? data, bool requiresAuth = true}) async =>
      _fail();
  @override
  Future<ApiResponse> delete(String path,
          {Object? data, bool requiresAuth = true}) async =>
      _fail();
}
