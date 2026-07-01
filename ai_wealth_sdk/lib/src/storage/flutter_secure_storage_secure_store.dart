import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/error/exceptions.dart';
import '../core/storage/secure_store.dart';

/// Encrypted-at-rest [SecureStore] backed by `flutter_secure_storage`.
///
/// Uses the platform keystores — Android Keystore (with EncryptedSharedPreferences)
/// and iOS/macOS Keychain — so sensitive values (auth tokens, PII) are never
/// stored in plaintext. This is the production replacement for
/// `InMemorySecureStore`, installed in Module 6 via [secureStoreProvider].
class FlutterSecureStorageSecureStore implements SecureStore {
  FlutterSecureStorageSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  Future<T> _guard<T>(String op, Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw CacheException('SecureStore.$op failed: $e');
    }
  }

  @override
  Future<String?> read(String key) =>
      _guard('read', () => _storage.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _guard('write', () => _storage.write(key: key, value: value));

  @override
  Future<void> delete(String key) =>
      _guard('delete', () => _storage.delete(key: key));

  @override
  Future<void> deleteAll() => _guard('deleteAll', () => _storage.deleteAll());

  @override
  Future<bool> contains(String key) =>
      _guard('contains', () => _storage.containsKey(key: key));
}
