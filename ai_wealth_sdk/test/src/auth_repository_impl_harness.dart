// Test harness that wires the Authentication module's *internal* data classes
// (which are intentionally not part of the public API) so the full data-layer
// flow can be unit-tested. Importing `package:.../src/...` from the package's own
// tests is allowed (the implementation_imports lint only targets other packages).
import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/auth/data/datasources/auth_local_datasource.dart';
import 'package:ai_wealth_sdk/src/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/auth/data/repositories/auth_repository_impl.dart';
import 'package:ai_wealth_sdk/src/auth/data/session_token_provider.dart';

class AuthHarness {
  AuthHarness({required ApiClient client, required SecureStore store})
      : logger = SdkLogger(minLevel: SdkLogLevel.error),
        remote = AuthRemoteDataSourceImpl(client),
        local = AuthLocalDataSourceImpl(store) {
    repository = AuthRepositoryImpl(remote: remote, local: local, logger: logger);
    tokenProvider =
        SessionTokenProvider(local: local, remote: remote, logger: logger);
  }

  final SdkLogger logger;
  final AuthRemoteDataSourceImpl remote;
  final AuthLocalDataSourceImpl local;
  late final AuthRepositoryImpl repository;
  late final SessionTokenProvider tokenProvider;
}
