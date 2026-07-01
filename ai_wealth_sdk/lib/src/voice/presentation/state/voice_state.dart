import 'package:equatable/equatable.dart';

import '../../../chat/domain/entities/chat_message.dart';
import '../../domain/entities/voice_config.dart';

enum VoiceStatus { initial, loadingConfig, ready, listening, processing, speaking, error }

/// Immutable state for the voice assistant.
class VoiceState extends Equatable {
  const VoiceState({
    this.status = VoiceStatus.initial,
    this.config,
    this.locale = 'en-IN',
    this.sttAvailable = false,
    this.partialTranscript,
    this.lastTranscript,
    this.reply,
    this.conversationId,
    this.errorMessage,
  });

  final VoiceStatus status;
  final VoiceConfig? config;
  final String locale; // bcp47
  final bool sttAvailable;

  /// Live interim transcript while listening.
  final String? partialTranscript;

  /// The finalised transcript of the last turn.
  final String? lastTranscript;

  /// The assistant's reply for the last turn.
  final ChatMessage? reply;
  final String? conversationId;
  final String? errorMessage;

  const VoiceState.initial() : this();

  bool get isListening => status == VoiceStatus.listening;
  bool get isProcessing => status == VoiceStatus.processing;
  bool get isSpeaking => status == VoiceStatus.speaking;
  bool get isBusy =>
      status == VoiceStatus.listening ||
      status == VoiceStatus.processing ||
      status == VoiceStatus.speaking;

  VoiceState copyWith({
    VoiceStatus? status,
    VoiceConfig? config,
    String? locale,
    bool? sttAvailable,
    String? partialTranscript,
    String? lastTranscript,
    ChatMessage? reply,
    String? conversationId,
    String? errorMessage,
    bool clearPartial = false,
    bool clearError = false,
  }) {
    return VoiceState(
      status: status ?? this.status,
      config: config ?? this.config,
      locale: locale ?? this.locale,
      sttAvailable: sttAvailable ?? this.sttAvailable,
      partialTranscript:
          clearPartial ? null : (partialTranscript ?? this.partialTranscript),
      lastTranscript: lastTranscript ?? this.lastTranscript,
      reply: reply ?? this.reply,
      conversationId: conversationId ?? this.conversationId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        config,
        locale,
        sttAvailable,
        partialTranscript,
        lastTranscript,
        reply,
        conversationId,
        errorMessage,
      ];
}
