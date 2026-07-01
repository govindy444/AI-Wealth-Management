import 'dart:async';

import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';


class PlatformSpeechRecognizer implements SpeechRecognizer {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  bool _initOk = false;

  Future<bool> _ensureInit() async {
    if (_initialized) return _initOk;
    _initialized = true;
    try {
      _initOk = await _stt.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _initOk = false;
    }
    return _initOk;
  }

  @override
  Future<bool> isAvailable() => _ensureInit();

  @override
  Future<String?> listen({
    String? localeId,
    void Function(String partial)? onPartial,
  }) async {
    if (!await _ensureInit()) return null;

    final completer = Completer<String?>();
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId?.replaceAll('-', '_'),
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        if (result.finalResult) {
          if (!completer.isCompleted) completer.complete(result.recognizedWords);
        } else {
          onPartial?.call(result.recognizedWords);
        }
      },
    );

    _stt.statusListener = (status) {
      if (status == 'notListening' && !completer.isCompleted) {
        completer.complete(_stt.lastRecognizedWords);
      }
    };

    return completer.future;
  }

  @override
  Future<void> stop() => _stt.stop();
}

class PlatformSpeechSynthesizer implements SpeechSynthesizer {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> speak(
    String text, {
    String? localeId,
    double? rate,
    double? pitch,
  }) async {
    await _configure();
    if (localeId != null) await _tts.setLanguage(localeId);
    if (rate != null) await _tts.setSpeechRate(rate);
    if (pitch != null) await _tts.setPitch(pitch);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
