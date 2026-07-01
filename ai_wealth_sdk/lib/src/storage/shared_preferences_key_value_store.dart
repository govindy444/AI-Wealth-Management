import 'package:shared_preferences/shared_preferences.dart';

import '../core/error/exceptions.dart';
import '../core/storage/key_value_store.dart';

/// Persistent [KeyValueStore] backed by `shared_preferences`.
///
/// The SDK is embedded inside a host banking app that owns its own
/// `SharedPreferences`. To avoid colliding with — or wiping — the host's keys,
/// every entry is written under a [namespace] prefix and [clear] only removes
/// keys inside that namespace. The underlying `SharedPreferences` instance is
/// loaded lazily and cached, so the first access pays the platform-channel cost
/// and subsequent calls are cheap.
class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore({
    String namespace = defaultNamespace,
    Future<SharedPreferences> Function()? prefsLoader,
  })  : _namespace = namespace,
        _loader = prefsLoader ?? SharedPreferences.getInstance;

  /// Default key prefix for all SDK-owned preferences.
  static const String defaultNamespace = 'wealth_sdk.';

  final String _namespace;
  final Future<SharedPreferences> Function() _loader;
  Future<SharedPreferences>? _cached;

  Future<SharedPreferences> get _prefs => _cached ??= _loader();

  String _scoped(String key) => '$_namespace$key';

  Future<T> _guard<T>(String op, Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw CacheException('KeyValueStore.$op failed: $e');
    }
  }

  @override
  Future<String?> getString(String key) =>
      _guard('getString', () async => (await _prefs).getString(_scoped(key)));

  @override
  Future<void> setString(String key, String value) => _guard(
        'setString',
        () async => (await _prefs).setString(_scoped(key), value),
      );

  @override
  Future<bool?> getBool(String key) =>
      _guard('getBool', () async => (await _prefs).getBool(_scoped(key)));

  @override
  Future<void> setBool(String key, bool value) => _guard(
        'setBool',
        () async => (await _prefs).setBool(_scoped(key), value),
      );

  @override
  Future<int?> getInt(String key) =>
      _guard('getInt', () async => (await _prefs).getInt(_scoped(key)));

  @override
  Future<void> setInt(String key, int value) =>
      _guard('setInt', () async => (await _prefs).setInt(_scoped(key), value));

  @override
  Future<void> remove(String key) =>
      _guard('remove', () async => (await _prefs).remove(_scoped(key)));

  @override
  Future<bool> containsKey(String key) => _guard(
        'containsKey',
        () async => (await _prefs).containsKey(_scoped(key)),
      );

  /// Clears only the SDK's namespaced keys — never the host app's preferences.
  @override
  Future<void> clear() => _guard('clear', () async {
        final prefs = await _prefs;
        final owned =
            prefs.getKeys().where((k) => k.startsWith(_namespace)).toList();
        for (final k in owned) {
          await prefs.remove(k);
        }
      });
}
