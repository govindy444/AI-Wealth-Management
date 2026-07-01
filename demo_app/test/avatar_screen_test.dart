import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/avatar/avatar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAvatarRepository implements AvatarRepository {
  @override
  Future<Result<List<AvatarPersona>>> listPersonas() async => success(const [
        AvatarPersona(
          id: 'aanya',
          name: 'Aanya',
          title: 'Wealth Advisor',
          accentColorHex: '#6C4DF4',
          languages: ['en', 'hi'],
          defaultLanguage: 'en',
        ),
        AvatarPersona(
          id: 'vikram',
          name: 'Vikram',
          title: 'Investment Specialist',
          accentColorHex: '#0E8F6E',
          languages: ['en'],
          defaultLanguage: 'en',
        ),
      ]);

  @override
  Future<Result<AvatarPresentation>> present({
    String? text,
    String? personaId,
    String? language,
  }) async =>
      success(
        const AvatarPresentation(
          personaId: 'aanya',
          personaName: 'Aanya',
          language: 'en',
          expression: AvatarExpression.happy,
          text: 'Hello from Aanya.',
          segments: [
            AvatarSegment(
              text: 'Hello from Aanya.',
              duration: Duration(milliseconds: 50),
            ),
          ],
        ),
      );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        avatarRepositoryProvider.overrideWithValue(_FakeAvatarRepository()),
      ],
      child: const MaterialApp(home: AvatarScreen()),
    ),
  );
  // Let the post-frame init() + async persona load complete (no pumpAndSettle:
  // the face has a perpetual blink animation that never settles).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('loads personas and language options', (tester) async {
    await _pump(tester);

    expect(find.text('Aanya'), findsWidgets); // title + persona chip
    expect(find.text('Wealth Advisor'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // dispose tickers/timers
  });

  testWidgets('Greet me triggers a presentation and shows the caption',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Greet me'));
    await tester.pump(); // process the present() future
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Hello from Aanya.'), findsOneWidget);

    // Let the 50ms segment finish so its playback timer is cleared.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(const SizedBox());
  });
}
