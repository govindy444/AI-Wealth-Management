import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/voice/voice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVoiceRepository implements VoiceRepository {
  @override
  Future<Result<VoiceConfig>> getConfig() async => success(const VoiceConfig(
        locales: [
          VoiceLocale(code: 'en', bcp47: 'en-IN', label: 'English'),
          VoiceLocale(code: 'hi', bcp47: 'hi-IN', label: 'हिन्दी'),
        ],
        defaultLocale: 'en-IN',
        wakeWord: 'Hey IDBI',
        defaultRate: 0.5,
        defaultPitch: 1.0,
      ));

  @override
  Future<Result<VoiceTurn>> takeTurn({
    required String transcript,
    String? conversationId,
    String? locale,
  }) async =>
      success(
        VoiceTurn(
          conversationId: 'conv_1',
          transcript: transcript,
          reply: ChatMessage(
            id: 'msg_1',
            role: ChatRole.assistant,
            content: 'Here is my advice.',
            createdAt: DateTime(2026, 6, 29),
          ),
          settings: const VoiceSettings(locale: 'en-IN', rate: 0.5, pitch: 1.0),
        ),
      );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        voiceRepositoryProvider.overrideWithValue(_FakeVoiceRepository()),
        // Leave speech providers as SDK stubs (recognizer unavailable, no-op TTS).
      ],
      child: const MaterialApp(home: VoiceScreen()),
    ),
  );
  await tester.pump(); // post-frame init()
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('loads config: shows locales and the typed fallback', (tester) async {
    await _pump(tester);

    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    // STT stub is unavailable → fallback prompt is shown.
    expect(find.textContaining('type your question'), findsOneWidget);
  });

  testWidgets('typed fallback returns and displays the spoken reply',
      (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'How do I save more?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(); // processing
    await tester.pump(const Duration(milliseconds: 50)); // turn + noop speak

    expect(find.text('Here is my advice.'), findsOneWidget);
    expect(find.text('Advisor'), findsOneWidget);
  });
}
