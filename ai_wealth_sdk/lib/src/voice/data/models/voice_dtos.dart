import '../../../chat/data/models/chat_dtos.dart';
import '../../domain/entities/voice_config.dart';
import '../../domain/entities/voice_turn.dart';

/// Wire decoders for the voice endpoints. The reply reuses the chat message
/// decoder so voice and chat share one message contract.
class VoiceDtos {
  const VoiceDtos._();

  static VoiceConfig configFromJson(Map<String, dynamic> j) => VoiceConfig(
        locales: (j['locales'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(_localeFromJson)
            .toList(growable: false),
        defaultLocale: (j['default_locale'] as String?) ?? 'en-IN',
        wakeWord: (j['wake_word'] as String?) ?? 'Hey IDBI',
        defaultRate: _toDouble(j['default_rate'], 0.5),
        defaultPitch: _toDouble(j['default_pitch'], 1.0),
      );

  static VoiceTurn turnFromJson(Map<String, dynamic> j) => VoiceTurn(
        conversationId: (j['conversation_id'] as String?) ?? '',
        transcript: (j['transcript'] as String?) ?? '',
        reply: ChatDtos.messageFromJson(
          (j['reply'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        settings: _settingsFromJson(
          (j['voice'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );

  static VoiceLocale _localeFromJson(Map<String, dynamic> j) => VoiceLocale(
        code: (j['code'] as String?) ?? 'en',
        bcp47: (j['bcp47'] as String?) ?? 'en-IN',
        label: (j['label'] as String?) ?? 'English',
      );

  static VoiceSettings _settingsFromJson(Map<String, dynamic> j) => VoiceSettings(
        locale: (j['locale'] as String?) ?? 'en-IN',
        rate: _toDouble(j['rate'], 0.5),
        pitch: _toDouble(j['pitch'], 1.0),
      );

  static double _toDouble(Object? v, double fallback) =>
      (v as num?)?.toDouble() ?? fallback;
}
