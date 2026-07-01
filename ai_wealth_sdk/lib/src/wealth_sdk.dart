import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_providers.dart';
import 'core/config/wealth_sdk_config.dart';
import 'core/di/sdk_providers.dart';
import 'network/network_providers.dart';
import 'storage/storage_providers.dart';

/// Entry point for embedding the IDBI Wealth AI SDK.
///
/// Typical integration in a host banking app:
/// ```dart
/// void main() {
///   final sdk = WealthSdk.initialize(
///     const WealthSdkConfig(
///       apiBaseUrl: 'https://wealth-ai.idbi.example/api/v1',
///       tenantId: 'idbi-demo',
///     ),
///   );
///   runApp(ProviderScope(overrides: sdk.overrides, child: const MyBankApp()));
/// }
/// ```
///
/// [overrides] installs the SDK's dependency-injection graph (see
/// `core/di/sdk_providers.dart`). Later modules contribute their production
/// implementations by overriding individual providers.
class WealthSdk {
  WealthSdk._(this.config);

  final WealthSdkConfig config;

  static WealthSdk? _instance;

  /// The initialized singleton. Throws if [initialize] has not been called.
  static WealthSdk get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('WealthSdk.initialize() must be called before use.');
    }
    return i;
  }

  static bool get isInitialized => _instance != null;

  /// Initializes the SDK with [config]. Returns the [WealthSdk] handle whose
  /// [overrides] must be supplied to a Riverpod `ProviderScope`.
  static WealthSdk initialize(WealthSdkConfig config) {
    final sdk = WealthSdk._(config);
    _instance = sdk;
    debugPrint('[WealthSdk] initialized → $config');
    return sdk;
  }

  /// Riverpod overrides the host must install so the SDK can resolve its
  /// configuration and dependency graph. Module-specific overrides (network,
  /// storage, auth) are appended here as they are implemented.
  List<Override> get overrides => [
        wealthSdkConfigProvider.overrideWithValue(config),
        // Storage (Module 6): install platform-backed persistence so sessions
        // and preferences survive restarts. Auth's local datasource depends on
        // the secure store, so these are installed before the auth overrides.
        keyValueStoreOverride,
        secureStoreOverride,
        // Networking (Module 5): install the production Dio-backed API client.
        networkApiClientOverride,
        // Authentication (Module 4): route the network layer's token provider
        // through the stored session.
        authTokenProviderOverride,
      ];

  /// Resets the SDK (primarily for tests).
  @visibleForTesting
  static void reset() => _instance = null;
}
