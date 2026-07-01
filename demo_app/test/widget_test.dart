import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/app/app.dart';
import 'package:demo_app/app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the `flutter_secure_storage` platform channel. The
/// SDK (Module 6) installs the real Keychain/Keystore-backed secure store, which
/// has no implementation in a widget test, so we service the channel here.
void _mockSecureStorageChannel() {
  final store = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    final key = args['key'] as String?;
    switch (call.method) {
      case 'read':
        return store[key];
      case 'write':
        store[key!] = args['value'] as String;
        return null;
      case 'delete':
        store.remove(key);
        return null;
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(key);
      case 'readAll':
        return Map<String, String>.from(store);
      default:
        return null;
    }
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  _mockSecureStorageChannel();
  final prefs = await SharedPreferences.getInstance();
  WealthSdk.reset();
  final sdk = WealthSdk.initialize(
    const WealthSdkConfig(
      apiBaseUrl: 'https://api.test/api/v1',
      tenantId: 'idbi-demo',
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...sdk.overrides,
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DemoBankApp(),
    ),
  );
}

void main() {
  testWidgets('App boots into the animated splash screen', (tester) async {
    await _pumpApp(tester);

    expect(find.text('IDBI Wealth AI'), findsOneWidget);
    expect(find.byIcon(Icons.auto_graph_rounded), findsOneWidget);

    // Flush the splash bootstrap timer so no timers remain pending.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('Splash routes to login when no session exists', (tester) async {
    await _pumpApp(tester);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Login screen shows no extra navigation buttons', (tester) async {
    await _pumpApp(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('Theme controller defaults to system mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController(prefs);
    expect(controller.state, ThemeMode.system);
  });
}
