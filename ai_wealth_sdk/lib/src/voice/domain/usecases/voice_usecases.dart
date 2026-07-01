import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/voice_config.dart';
import '../entities/voice_turn.dart';
import '../repositories/voice_repository.dart';

/// Loads the voice assistant configuration.
class GetVoiceConfigUseCase implements UseCase<VoiceConfig, NoParams> {
  GetVoiceConfigUseCase(this._repository);
  final VoiceRepository _repository;

  @override
  FutureResult<VoiceConfig> call(NoParams params) => _repository.getConfig();
}

class VoiceTurnParams extends Equatable {
  const VoiceTurnParams({
    required this.transcript,
    this.conversationId,
    this.locale,
  });
  final String transcript;
  final String? conversationId;
  final String? locale;

  @override
  List<Object?> get props => [transcript, conversationId, locale];
}

/// Submits a transcript and returns the assistant's reply + voice settings.
class VoiceTurnUseCase implements UseCase<VoiceTurn, VoiceTurnParams> {
  VoiceTurnUseCase(this._repository);
  final VoiceRepository _repository;

  @override
  FutureResult<VoiceTurn> call(VoiceTurnParams params) => _repository.takeTurn(
        transcript: params.transcript,
        conversationId: params.conversationId,
        locale: params.locale,
      );
}
