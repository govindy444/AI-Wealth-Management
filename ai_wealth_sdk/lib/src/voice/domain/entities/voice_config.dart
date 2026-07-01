import 'package:equatable/equatable.dart';

/// A speakable/recognisable locale offered by the voice assistant.
class VoiceLocale extends Equatable {
  const VoiceLocale({
    required this.code,
    required this.bcp47,
    required this.label,
  });

  final String code; // ISO-639-1, e.g. "hi"
  final String bcp47; // platform tag, e.g. "hi-IN"
  final String label; // native display name

  @override
  List<Object?> get props => [code, bcp47, label];
}

/// Synthesis settings the client should use to speak a reply.
class VoiceSettings extends Equatable {
  const VoiceSettings({
    required this.locale,
    required this.rate,
    required this.pitch,
  });

  final String locale; // bcp47
  final double rate;
  final double pitch;

  @override
  List<Object?> get props => [locale, rate, pitch];
}

/// Voice assistant capabilities/configuration from the backend.
class VoiceConfig extends Equatable {
  const VoiceConfig({
    required this.locales,
    required this.defaultLocale,
    required this.wakeWord,
    required this.defaultRate,
    required this.defaultPitch,
  });

  final List<VoiceLocale> locales;
  final String defaultLocale; // bcp47
  final String wakeWord;
  final double defaultRate;
  final double defaultPitch;

  @override
  List<Object?> get props =>
      [locales, defaultLocale, wakeWord, defaultRate, defaultPitch];
}
