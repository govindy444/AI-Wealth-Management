import '../../../core/utils/result.dart';
import '../entities/avatar_persona.dart';
import '../entities/avatar_presentation.dart';


abstract interface class AvatarRepository {
  FutureResult<List<AvatarPersona>> listPersonas();

  FutureResult<AvatarPresentation> present({
    String? text,
    String? personaId,
    String? language,
  });
}
