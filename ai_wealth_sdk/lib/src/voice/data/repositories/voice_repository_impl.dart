import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/voice_config.dart';
import '../../domain/entities/voice_turn.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/voice_remote_datasource.dart';

/// Coordinates the voice API, mapping transport exceptions to [Failure]s via
/// [BaseRepository.guard].
class VoiceRepositoryImpl with BaseRepository implements VoiceRepository {
  VoiceRepositoryImpl({
    required VoiceRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final VoiceRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<VoiceConfig> getConfig() => guard(() => _remote.getConfig());

  @override
  FutureResult<VoiceTurn> takeTurn({
    required String transcript,
    String? conversationId,
    String? locale,
  }) =>
      guard(() => _remote.takeTurn(
            transcript: transcript,
            conversationId: conversationId,
            locale: locale,
          ));
}
