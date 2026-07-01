import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import '../core/network/api_client.dart';
import '../core/network/token_provider.dart';
import 'dio_api_client.dart';

/// DI wiring for the Networking module (Module 5).
///
/// [networkApiClientProvider] builds the production Dio-backed client from the
/// SDK config, token provider, and logger. It is installed as the override for
/// the core `apiClientProvider` via [networkApiClientOverride] in
/// `WealthSdk.overrides`, so every datasource that depends on `apiClientProvider`
/// now talks to the real backend.
final networkApiClientProvider = Provider<ApiClient>(
  (ref) => DioApiClient(
    config: ref.watch(wealthSdkConfigProvider),
    tokenProvider: ref.watch(tokenProviderProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final Override networkApiClientOverride =
    apiClientProvider.overrideWith((ref) => ref.watch(networkApiClientProvider));

/// A bare, unauthenticated Dio client used ONLY for token refresh.
///
/// This breaks the otherwise-circular dependency
/// `apiClient → tokenProvider → refresh → apiClient`: the session token provider
/// refreshes through this client (which never consults the token provider),
/// while all other traffic uses the authenticated [networkApiClientProvider].
final refreshApiClientProvider = Provider<ApiClient>(
  (ref) => DioApiClient(
    config: ref.watch(wealthSdkConfigProvider),
    tokenProvider: const UnauthenticatedTokenProvider(),
    logger: ref.watch(sdkLoggerProvider),
  ),
);
