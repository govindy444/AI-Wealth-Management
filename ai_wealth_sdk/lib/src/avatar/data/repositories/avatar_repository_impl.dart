import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/avatar_persona.dart';
import '../../domain/entities/avatar_presentation.dart';
import '../../domain/repositories/avatar_repository.dart';
import '../datasources/avatar_remote_datasource.dart';

class AvatarRepositoryImpl with BaseRepository implements AvatarRepository {
  AvatarRepositoryImpl({
    required AvatarRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final AvatarRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<List<AvatarPersona>> listPersonas() =>
      guard(() => _remote.listPersonas());

  @override
  FutureResult<AvatarPresentation> present({
    String? text,
    String? personaId,
    String? language,
  }) =>
      guard(() => _remote.present(
            text: text,
            personaId: personaId,
            language: language,
          ));
}
