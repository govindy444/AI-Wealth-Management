import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WealthSdkConfig', () {
    test('copyWith overrides only provided fields', () {
      const config = WealthSdkConfig(
        apiBaseUrl: 'https://api.test/api/v1',
        tenantId: 'idbi-demo',
      );
      final updated = config.copyWith(tenantId: 'idbi-prod');

      expect(updated.tenantId, 'idbi-prod');
      expect(updated.apiBaseUrl, config.apiBaseUrl);
      expect(updated.environment, WealthSdkEnvironment.sandbox);
    });
  });

  group('WealthSdk lifecycle', () {
    setUp(WealthSdk.reset);

    test('throws before initialize', () {
      expect(() => WealthSdk.instance, throwsStateError);
      expect(WealthSdk.isInitialized, isFalse);
    });

    test('initialize stores config and exposes overrides', () {
      const config = WealthSdkConfig(
        apiBaseUrl: 'https://api.test/api/v1',
        tenantId: 'idbi-demo',
      );
      final sdk = WealthSdk.initialize(config);

      expect(WealthSdk.isInitialized, isTrue);
      expect(WealthSdk.instance.config.tenantId, 'idbi-demo');
      expect(sdk.overrides, isNotEmpty);
    });
  });

  group('Explanation', () {
    test('confidencePercent rounds and clamps', () {
      const e = Explanation(summary: 'x', confidence: 0.846);
      expect(e.confidencePercent, 85);

      const over = Explanation(summary: 'x', confidence: 1.5);
      expect(over.confidencePercent, 100);
    });
  });

  group('Result helpers', () {
    test('success and failure construct correct Either sides', () {
      final ok = success<int>(42);
      final err = failure<int>(const NetworkFailure('offline'));

      expect(ok.isRight(), isTrue);
      expect(err.isLeft(), isTrue);
      expect(ok.getOrElse(() => -1), 42);
    });
  });
}
