import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk_example/app.dart';
import 'package:ai_wealth_sdk_example/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';


void _mockSecureStorageChannel() {
  final store = <String, String>{};
  const ch = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(ch, (call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
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
  _mockSecureStorageChannel();
  WealthSdk.reset();
  final sdk = WealthSdk.initialize(
    const WealthSdkConfig(
      apiBaseUrl: 'http://localhost:8099/api/v1',
      tenantId: 'test',
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: sdk.overrides,
      child: const ExampleApp(),
    ),
  );
}


void main() {
  tearDown(WealthSdk.reset);

  // ── Boot / splash ───────────────────────────────────────────────────────────

  testWidgets('shows splash indicator on first frame', (tester) async {
    await _pumpApp(tester);
    // Before bootstrap() runs, auth status is AuthStatus.unknown → _SplashScreen.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders MaterialApp with the correct title', (tester) async {
    await _pumpApp(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'My Bank — AI Wealth');
  });

  // ── Login screen (after bootstrap with no stored session) ──────────────────

  testWidgets('shows login screen when no session is stored', (tester) async {
    await _pumpApp(tester);
    // Flush bootstrap() — secure storage returns null → unauthenticated.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('login form shows two fields pre-filled', (tester) async {
    await _pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('demo@idbi.example'), findsOneWidget);
  });

  testWidgets('validates empty password', (tester) async {
    await _pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Clear the pre-filled password field.
    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('validates invalid email', (tester) async {
    await _pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });
}
