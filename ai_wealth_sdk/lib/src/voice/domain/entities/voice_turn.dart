import 'package:equatable/equatable.dart';

import '../../../chat/domain/entities/chat_message.dart';
import 'voice_config.dart';

/// The result of one voice turn: the recognised transcript, the assistant's
/// reply (a chat message, possibly with an Explanation), the conversation it
/// belongs to, and the settings the client should use to speak the reply.
class VoiceTurn extends Equatable {
  const VoiceTurn({
    required this.conversationId,
    required this.transcript,
    required this.reply,
    required this.settings,
  });

  final String conversationId;
  final String transcript;
  final ChatMessage reply;
  final VoiceSettings settings;

  @override
  List<Object?> get props => [conversationId, transcript, reply, settings];
}
