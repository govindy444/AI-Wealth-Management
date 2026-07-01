import '../../../core/network/api_client.dart';
import '../../domain/entities/voice_config.dart';
import '../../domain/entities/voice_turn.dart';
import '../models/voice_dtos.dart';

/// Talks to the backend `/voice` endpoints via the transport-agnostic [ApiClient].
abstract interface class VoiceRemoteDataSource {
  Future<VoiceConfig> getConfig();
  Future<VoiceTurn> takeTurn({
    required String transcript,
    String? conversationId,
    String? locale,
  });
}

class VoiceRemoteDataSourceImpl implements VoiceRemoteDataSource {
  VoiceRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<VoiceConfig> getConfig() async {
    final res = await _client.get('/voice/config');
    return VoiceDtos.configFromJson(res.asMap);
  }

  @override
  Future<VoiceTurn> takeTurn({
    required String transcript,
    String? conversationId,
    String? locale,
  }) async {
    final res = await _client.post('/voice/turn', data: {
      'transcript': transcript,
      if (conversationId != null) 'conversation_id': conversationId,
      if (locale != null) 'locale': locale,
    });
    return VoiceDtos.turnFromJson(res.asMap);
  }
}
