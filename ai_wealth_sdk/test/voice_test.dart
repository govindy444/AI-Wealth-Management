import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/voice/data/datasources/voice_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/voice/data/models/voice_dtos.dart';
import 'package:ai_wealth_sdk/src/voice/data/repositories/voice_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _configJson() => {
      'locales': [
        {'code': 'en', 'bcp47': 'en-IN', 'label': 'English'},
        {'code': 'hi', 'bcp47': 'hi-IN', 'label': 'हिन्दी'},
      ],
      'default_locale': 'en-IN',
      'wake_word': 'Hey IDBI',
      'default_rate': 0.5,
      'default_pitch': 1.0,
    };

Map<String, dynamic> _turnJson(String transcript) => {
      'conversation_id': 'conv_1',
      'transcript': transcript,
      'reply': {
        'id': 'msg_1',
        'role': 'assistant',
        'content': 'Here is my advice.',
        'created_at': '2026-06-29T10:00:00Z',
        'explanation': null,
      },
      'voice': {'locale': 'en-IN', 'rate': 0.5, 'pitch': 1.0},
    };

void main() {
  group('VoiceDtos', () {
    test('decodes config and a turn (reply reuses the chat message contract)', () {
      final config = VoiceDtos.configFromJson(_configJson());
      expect(config.locales.length, 2);
      expect(config.defaultLocale, 'en-IN');
      expect(config.wakeWord, 'Hey IDBI');

      final turn = VoiceDtos.turnFromJson(_turnJson('How do I save?'));
      expect(turn.transcript, 'How do I save?');
      expect(turn.reply.isAssistant, isTrue);
      expect(turn.settings.locale, 'en-IN');
    });
  });

  group('VoiceController orchestration', () {
    VoiceController build(
      FakeVoiceRemote remote, {
      required SpeechRecognizer recognizer,
      required SpeechSynthesizer synth,
    }) {
      final repo = VoiceRepositoryImpl(remote: remote, logger: _logger);
      return VoiceController(
        getConfig: GetVoiceConfigUseCase(repo),
        takeTurn: VoiceTurnUseCase(repo),
        recognizer: recognizer,
        synthesizer: synth,
      );
    }

    test('init loads config and reflects STT availability', () async {
      final c = build(FakeVoiceRemote(),
          recognizer: FakeRecognizer(available: true), synth: FakeSynth());
      addTearDown(c.dispose);

      await c.init();

      expect(c.state.status, VoiceStatus.ready);
      expect(c.state.sttAvailable, isTrue);
      expect(c.state.locale, 'en-IN');
    });

    test('listening → transcript → reply → speaks it (full turn)', () async {
      final synth = FakeSynth();
      final c = build(FakeVoiceRemote(),
          recognizer: FakeRecognizer(available: true, transcript: 'How do I save?'),
          synth: synth);
      addTearDown(c.dispose);
      await c.init();

      await c.startListening();

      expect(c.state.lastTranscript, 'How do I save?');
      expect(c.state.reply?.content, 'Here is my advice.');
      expect(synth.spoken, 'Here is my advice.'); // reply was synthesised
      expect(c.state.status, VoiceStatus.ready); // returns to ready after speaking
    });

    test('typed fallback submits without speech recognition', () async {
      final synth = FakeSynth();
      final c = build(FakeVoiceRemote(),
          recognizer: FakeRecognizer(available: false), synth: synth);
      addTearDown(c.dispose);
      await c.init();

      expect(c.state.sttAvailable, isFalse);
      await c.submitText('help me budget');

      expect(c.state.reply?.content, 'Here is my advice.');
      expect(synth.spoken, isNotNull);
    });

    test('startListening errors clearly when STT unavailable', () async {
      final c = build(FakeVoiceRemote(),
          recognizer: FakeRecognizer(available: false), synth: FakeSynth());
      addTearDown(c.dispose);
      await c.init();

      await c.startListening();

      expect(c.state.status, VoiceStatus.error);
      expect(c.state.errorMessage, contains('unavailable'));
    });

    test('surfaces a failure from the turn use-case', () async {
      final c = build(FakeVoiceRemote.failing(),
          recognizer: FakeRecognizer(available: true, transcript: 'hi'),
          synth: FakeSynth());
      addTearDown(c.dispose);
      await c.init();

      await c.submitText('hi');
      expect(c.state.status, VoiceStatus.error);
    });
  });
}

class FakeVoiceRemote implements VoiceRemoteDataSource {
  FakeVoiceRemote() : _fail = false;
  FakeVoiceRemote.failing() : _fail = true;
  final bool _fail;

  @override
  Future<VoiceConfig> getConfig() async => VoiceDtos.configFromJson(_configJson());

  @override
  Future<VoiceTurn> takeTurn({
    required String transcript,
    String? conversationId,
    String? locale,
  }) async {
    if (_fail) throw NetworkException('offline');
    return VoiceDtos.turnFromJson(_turnJson(transcript));
  }
}

class FakeRecognizer implements SpeechRecognizer {
  FakeRecognizer({required this.available, this.transcript});
  final bool available;
  final String? transcript;

  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<String?> listen({String? localeId, void Function(String partial)? onPartial}) async {
    onPartial?.call(transcript ?? '');
    return transcript;
  }

  @override
  Future<void> stop() async {}
}

class FakeSynth implements SpeechSynthesizer {
  String? spoken;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> speak(String text, {String? localeId, double? rate, double? pitch}) async {
    spoken = text;
  }

  @override
  Future<void> stop() async {}
}
