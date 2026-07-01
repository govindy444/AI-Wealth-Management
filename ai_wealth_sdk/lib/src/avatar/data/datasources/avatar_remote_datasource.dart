import '../../../core/network/api_client.dart';
import '../../domain/entities/avatar_persona.dart';
import '../../domain/entities/avatar_presentation.dart';
import '../models/avatar_dtos.dart';

abstract interface class AvatarRemoteDataSource {
  Future<List<AvatarPersona>> listPersonas();
  Future<AvatarPresentation> present({
    String? text,
    String? personaId,
    String? language,
  });
}

class AvatarRemoteDataSourceImpl implements AvatarRemoteDataSource {
  AvatarRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<List<AvatarPersona>> listPersonas() async {
    final res = await _client.get('/avatar/personas');
    return res.asList
        .cast<Map<String, dynamic>>()
        .map(AvatarDtos.personaFromJson)
        .toList(growable: false);
  }

  @override
  Future<AvatarPresentation> present({
    String? text,
    String? personaId,
    String? language,
  }) async {
    final res = await _client.post('/avatar/present', data: {
      if (text != null) 'text': text,
      if (personaId != null) 'persona_id': personaId,
      if (language != null) 'language': language,
    });
    return AvatarDtos.presentationFromJson(res.asMap);
  }
}
