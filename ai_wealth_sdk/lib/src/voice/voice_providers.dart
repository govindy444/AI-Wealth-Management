import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/voice_remote_datasource.dart';
import 'data/repositories/voice_repository_impl.dart';
import 'domain/repositories/voice_repository.dart';
import 'domain/services/speech_services.dart';
import 'domain/usecases/voice_usecases.dart';
import 'presentation/state/voice_controller.dart';
import 'presentation/state/voice_state.dart';

/// DI wiring for the Voice Assistant module (Module 10).
///
/// The repository/use-cases are pure consumers of the foundation (the remote
/// datasource uses `apiClientProvider`). The **speech I/O** providers ship safe
/// no-op defaults; the host app overrides them with platform implementations
/// (e.g. `speech_to_text` / `flutter_tts`).

/// Speech-to-text. Default reports unavailable; host overrides with a real impl.
final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => const UnavailableSpeechRecognizer(),
);

/// Text-to-speech. Default is a no-op; host overrides with a real impl.
final speechSynthesizerProvider = Provider<SpeechSynthesizer>(
  (ref) => const NoopSpeechSynthesizer(),
);

final voiceRemoteDataSourceProvider = Provider<VoiceRemoteDataSource>(
  (ref) => VoiceRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final voiceRepositoryProvider = Provider<VoiceRepository>(
  (ref) => VoiceRepositoryImpl(
    remote: ref.watch(voiceRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getVoiceConfigUseCaseProvider = Provider<GetVoiceConfigUseCase>(
  (ref) => GetVoiceConfigUseCase(ref.watch(voiceRepositoryProvider)),
);
final voiceTurnUseCaseProvider = Provider<VoiceTurnUseCase>(
  (ref) => VoiceTurnUseCase(ref.watch(voiceRepositoryProvider)),
);

/// Voice assistant controller. `autoDispose` so the recognizer/synthesizer are
/// released (stopped) when the voice screen closes.
final voiceControllerProvider =
    StateNotifierProvider.autoDispose<VoiceController, VoiceState>(
  (ref) => VoiceController(
    getConfig: ref.watch(getVoiceConfigUseCaseProvider),
    takeTurn: ref.watch(voiceTurnUseCaseProvider),
    recognizer: ref.watch(speechRecognizerProvider),
    synthesizer: ref.watch(speechSynthesizerProvider),
  ),
);
