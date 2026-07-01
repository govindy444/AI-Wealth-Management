import '../../../core/utils/result.dart';
import '../entities/voice_config.dart';
import '../entities/voice_turn.dart';

/// Voice assistant repository contract. Implemented in the data layer; consumed
/// by use-cases. Returns [Result] so callers handle failures as values.
abstract interface class VoiceRepository {
  /// Fetches the voice configuration (locales, wake word, default settings).
  FutureResult<VoiceConfig> getConfig();

  /// Submits a recognised [transcript] and returns the assistant's spoken-ready
  /// reply, continuing [conversationId] when provided.
  FutureResult<VoiceTurn> takeTurn({
    required String transcript,
    String? conversationId,
    String? locale,
  });
}
