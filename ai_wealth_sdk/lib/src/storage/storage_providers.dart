import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/secure_store.dart';
import 'flutter_secure_storage_secure_store.dart';
import 'shared_preferences_key_value_store.dart';

/// DI wiring for the Storage module (Module 6).
///
/// These providers build the production, platform-backed storage
/// implementations and are installed as overrides for the core
/// `keyValueStoreProvider` / `secureStoreProvider` via [keyValueStoreOverride]
/// and [secureStoreOverride] in `WealthSdk.overrides`. Once installed, every
/// consumer (notably auth's local datasource, which persists the session to the
/// secure store) reads/writes real device storage instead of the in-memory
/// defaults.

/// `SharedPreferences`-backed, namespaced key/value store.
final sharedPreferencesKeyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => SharedPreferencesKeyValueStore(),
);

/// `flutter_secure_storage`-backed encrypted store (Keychain / Keystore).
final flutterSecureStorageSecureStoreProvider = Provider<SecureStore>(
  (ref) => FlutterSecureStorageSecureStore(),
);

final Override keyValueStoreOverride = keyValueStoreProvider
    .overrideWith((ref) => ref.watch(sharedPreferencesKeyValueStoreProvider));

final Override secureStoreOverride = secureStoreProvider
    .overrideWith((ref) => ref.watch(flutterSecureStorageSecureStoreProvider));
