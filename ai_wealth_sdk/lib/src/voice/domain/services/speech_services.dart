/// Host-provided speech capabilities for the Voice Assistant.
///
/// Speech I/O is a *device* capability, so — like storage and the HTTP client —
/// the SDK defines the contracts here and ships safe no-op defaults. The host
/// app overrides `speechRecognizerProvider` / `speechSynthesizerProvider` with
/// real implementations (e.g. `speech_to_text` + `flutter_tts`). Server-side
/// ASR / neural TTS can also be slotted in at Module 21 behind these same
/// interfaces.
library;

/// Speech-to-text recognizer.
abstract interface class SpeechRecognizer {
  /// Whether on-device recognition is available and permitted.
  Future<bool> isAvailable();

  /// Listens for a single utterance and resolves with the final transcript
  /// (or null if nothing was recognised). [onPartial] receives interim results
  /// for live captioning.
  Future<String?> listen({String? localeId, void Function(String partial)? onPartial});

  /// Cancels an in-progress listen.
  Future<void> stop();
}

/// Text-to-speech synthesizer.
abstract interface class SpeechSynthesizer {
  Future<bool> isAvailable();

  /// Speaks [text]. Resolves when playback completes (or is stopped).
  Future<void> speak(String text, {String? localeId, double? rate, double? pitch});

  Future<void> stop();
}

/// Default recognizer used until the host installs a real one. Reports
/// unavailable so the UI can offer a typed fallback instead of failing.
class UnavailableSpeechRecognizer implements SpeechRecognizer {
  const UnavailableSpeechRecognizer();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<String?> listen({
    String? localeId,
    void Function(String partial)? onPartial,
  }) async =>
      null;

  @override
  Future<void> stop() async {}
}

/// Default synthesizer used until the host installs a real one. No-op so the
/// rest of the voice flow still works (the reply is shown as text).
class NoopSpeechSynthesizer implements SpeechSynthesizer {
  const NoopSpeechSynthesizer();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> speak(String text, {String? localeId, double? rate, double? pitch}) async {}

  @override
  Future<void> stop() async {}
}
