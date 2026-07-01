import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesKeyValueStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    SharedPreferencesKeyValueStore store() => SharedPreferencesKeyValueStore();

    test('round-trips string, bool and int values', () async {
      final s = store();
      await s.setString('name', 'idbi');
      await s.setBool('dark', true);
      await s.setInt('count', 7);

      expect(await s.getString('name'), 'idbi');
      expect(await s.getBool('dark'), true);
      expect(await s.getInt('count'), 7);
    });

    test('returns null for missing keys and reports containsKey', () async {
      final s = store();
      expect(await s.getString('missing'), isNull);
      expect(await s.containsKey('missing'), isFalse);
      await s.setString('present', 'x');
      expect(await s.containsKey('present'), isTrue);
    });

    test('remove deletes a single key', () async {
      final s = store();
      await s.setString('k', 'v');
      await s.remove('k');
      expect(await s.containsKey('k'), isFalse);
    });

    test('namespaces keys to avoid colliding with host prefs', () async {
      SharedPreferences.setMockInitialValues({'host_key': 'host_value'});
      final s = store();
      await s.setString('sdk_key', 'sdk_value');

      final raw = await SharedPreferences.getInstance();
      // Stored under the SDK namespace, not the bare key.
      expect(raw.containsKey('wealth_sdk.sdk_key'), isTrue);
      expect(raw.containsKey('sdk_key'), isFalse);
    });

    test('clear removes only namespaced keys, leaving host prefs intact',
        () async {
      SharedPreferences.setMockInitialValues({'host_key': 'host_value'});
      final s = store();
      await s.setString('a', '1');
      await s.setInt('b', 2);

      await s.clear();

      expect(await s.containsKey('a'), isFalse);
      expect(await s.containsKey('b'), isFalse);
      final raw = await SharedPreferences.getInstance();
      expect(raw.getString('host_key'), 'host_value');
    });

    test('honours a custom namespace', () async {
      final s = SharedPreferencesKeyValueStore(namespace: 'custom.');
      await s.setString('k', 'v');
      final raw = await SharedPreferences.getInstance();
      expect(raw.containsKey('custom.k'), isTrue);
    });
  });

  group('FlutterSecureStorageSecureStore', () {
    late _MockSecureStorage mock;
    late FlutterSecureStorageSecureStore store;

    setUp(() {
      mock = _MockSecureStorage();
      store = FlutterSecureStorageSecureStore(storage: mock);
    });

    test('write delegates to the platform storage', () async {
      when(() => mock.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      await store.write('token', 'secret');
      verify(() => mock.write(key: 'token', value: 'secret')).called(1);
    });

    test('read returns the stored value', () async {
      when(() => mock.read(key: 'token')).thenAnswer((_) async => 'secret');
      expect(await store.read('token'), 'secret');
    });

    test('contains and delete delegate correctly', () async {
      when(() => mock.containsKey(key: 'token')).thenAnswer((_) async => true);
      when(() => mock.delete(key: 'token')).thenAnswer((_) async {});

      expect(await store.contains('token'), isTrue);
      await store.delete('token');
      verify(() => mock.delete(key: 'token')).called(1);
    });

    test('deleteAll delegates to the platform storage', () async {
      when(() => mock.deleteAll()).thenAnswer((_) async {});
      await store.deleteAll();
      verify(() => mock.deleteAll()).called(1);
    });

    test('wraps underlying failures in CacheException', () async {
      when(() => mock.read(key: any(named: 'key')))
          .thenThrow(Exception('keystore unavailable'));
      expect(() => store.read('token'), throwsA(isA<CacheException>()));
    });
  });

  group('WealthSdk.overrides installs platform-backed storage', () {
    test('keyValueStore and secureStore resolve to the production impls', () {
      WealthSdk.reset();
      final sdk = WealthSdk.initialize(
        const WealthSdkConfig(
          apiBaseUrl: 'https://api.test/api/v1',
          tenantId: 'idbi-demo',
        ),
      );
      final c = ProviderContainerStub.of(sdk);
      addTearDown(c.dispose);

      expect(
        c.read(keyValueStoreProvider),
        isA<SharedPreferencesKeyValueStore>(),
      );
      expect(
        c.read(secureStoreProvider),
        isA<FlutterSecureStorageSecureStore>(),
      );
    });
  });
}

/// Small helper so the override-wiring test reads clearly.
class ProviderContainerStub {
  static ProviderContainer of(WealthSdk sdk) =>
      ProviderContainer(overrides: sdk.overrides);
}
