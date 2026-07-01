import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = WealthSdkConfig(
  apiBaseUrl: 'https://api.test/api/v1',
  tenantId: 'idbi-demo',
);

void main() {
  group('core foundation defaults (config override only)', () {
    ProviderContainer makeCore() => ProviderContainer(
          overrides: [wealthSdkConfigProvider.overrideWithValue(_config)],
        );

    test('resolve to safe in-memory defaults', () {
      final c = makeCore();
      addTearDown(c.dispose);

      expect(c.read(wealthSdkConfigProvider).tenantId, 'idbi-demo');
      expect(c.read(secureStoreProvider), isA<InMemorySecureStore>());
      expect(c.read(keyValueStoreProvider), isA<InMemoryKeyValueStore>());
      expect(c.read(tokenProviderProvider), isA<UnauthenticatedTokenProvider>());
      expect(c.read(sdkLoggerProvider), isA<SdkLogger>());
    });

    test('unconfigured ApiClient fails loudly only when invoked', () async {
      final c = makeCore();
      addTearDown(c.dispose);

      final client = c.read(apiClientProvider);
      expect(client, isA<ApiClient>());
      expect(() => client.get('/accounts'), throwsStateError);
    });

    test('production environment raises default log level', () {
      final c = ProviderContainer(overrides: [
        wealthSdkConfigProvider.overrideWithValue(
          _config.copyWith(environment: WealthSdkEnvironment.production),
        ),
      ]);
      addTearDown(c.dispose);
      expect(c.read(sdkLoggerProvider).minLevel, SdkLogLevel.warning);
    });
  });

  group('full SDK overrides (WealthSdk.overrides)', () {
    test('install production network + session token provider', () {
      WealthSdk.reset();
      final sdk = WealthSdk.initialize(_config);
      final c = ProviderContainer(overrides: sdk.overrides);
      addTearDown(c.dispose);

      // Module 5 installs the Dio-backed client...
      expect(c.read(apiClientProvider), isA<DioApiClient>());
      // ...and Module 4 the session-backed token provider (not the default).
      expect(c.read(tokenProviderProvider), isA<TokenProvider>());
      expect(c.read(tokenProviderProvider),
          isNot(isA<UnauthenticatedTokenProvider>()));
    });
  });
}
