import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/use_case.dart';
import '../../domain/services/speech_services.dart';
import '../../domain/usecases/voice_usecases.dart';
import 'voice_state.dart';

/// Orchestrates a full voice turn: listen (STT) → send transcript → speak the
/// reply (TTS). Speech I/O is delegated to the host-provided [SpeechRecognizer]
/// and [SpeechSynthesizer]; when recognition is unavailable the UI falls back to
/// typed input via [submitText].
class VoiceController extends StateNotifier<VoiceState> {
  VoiceController({
    required GetVoiceConfigUseCase getConfig,
    required VoiceTurnUseCase takeTurn,
    required SpeechRecognizer recognizer,
    required SpeechSynthesizer synthesizer,
  })  : _getConfig = getConfig,
        _takeTurn = takeTurn,
        _recognizer = recognizer,
        _synthesizer = synthesizer,
        super(const VoiceState.initial());

  final GetVoiceConfigUseCase _getConfig;
  final VoiceTurnUseCase _takeTurn;
  final SpeechRecognizer _recognizer;
  final SpeechSynthesizer _synthesizer;

  /// Loads config and probes whether speech recognition is available.
  Future<void> init() async {
    if (state.status == VoiceStatus.loadingConfig) return;
    state = state.copyWith(status: VoiceStatus.loadingConfig, clearError: true);

    final available = await _recognizer.isAvailable();
    final result = await _getConfig(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: VoiceStatus.error,
        errorMessage: failure.message,
        sttAvailable: available,
      ),
      (config) => state.copyWith(
        status: VoiceStatus.ready,
        config: config,
        locale: config.defaultLocale,
        sttAvailable: available,
      ),
    );
  }

  void selectLocale(String bcp47) => state = state.copyWith(locale: bcp47);

  /// Begins listening for an utterance, then submits the transcript.
  Future<void> startListening() async {
    if (state.isBusy) return;
    if (!state.sttAvailable) {
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Speech recognition is unavailable. Type your question instead.',
      );
      return;
    }
    state = state.copyWith(status: VoiceStatus.listening, clearPartial: true, clearError: true);

    final transcript = await _recognizer.listen(
      localeId: state.locale,
      onPartial: (partial) {
        if (state.isListening) {
          state = state.copyWith(partialTranscript: partial);
        }
      },
    );

    if (transcript == null || transcript.trim().isEmpty) {
      state = state.copyWith(status: VoiceStatus.ready, clearPartial: true);
      return;
    }
    await _submit(transcript.trim());
  }

  /// Cancels an in-progress listen.
  Future<void> cancelListening() async {
    await _recognizer.stop();
    if (mounted) state = state.copyWith(status: VoiceStatus.ready, clearPartial: true);
  }

  /// Typed fallback when speech recognition isn't available.
  Future<void> submitText(String text) async {
    if (text.trim().isEmpty || state.isBusy) return;
    await _submit(text.trim());
  }

  /// Stops any in-progress speech playback.
  Future<void> stopSpeaking() async {
    await _synthesizer.stop();
    if (mounted) state = state.copyWith(status: VoiceStatus.ready);
  }

  Future<void> _submit(String transcript) async {
    state = state.copyWith(
      status: VoiceStatus.processing,
      lastTranscript: transcript,
      clearPartial: true,
      clearError: true,
    );

    final result = await _takeTurn(VoiceTurnParams(
      transcript: transcript,
      conversationId: state.conversationId,
      locale: state.locale,
    ));

    await result.fold(
      (failure) async {
        if (mounted) {
          state = state.copyWith(
            status: VoiceStatus.error,
            errorMessage: failure.message,
          );
        }
      },
      (turn) async {
        if (!mounted) return;
        state = state.copyWith(
          status: VoiceStatus.speaking,
          reply: turn.reply,
          conversationId: turn.conversationId,
        );
        await _synthesizer.speak(
          turn.reply.content,
          localeId: turn.settings.locale,
          rate: turn.settings.rate,
          pitch: turn.settings.pitch,
        );
        if (mounted && state.status == VoiceStatus.speaking) {
          state = state.copyWith(status: VoiceStatus.ready);
        }
      },
    );
  }

  @override
  void dispose() {
    _recognizer.stop();
    _synthesizer.stop();
    super.dispose();
  }
}
