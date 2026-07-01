import 'package:equatable/equatable.dart';

import 'chat_message.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt, messages];
}

class ConversationSummary extends Equatable {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messageCount,
    this.lastMessage,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastMessage;

  @override
  List<Object?> get props => [id, title, updatedAt, messageCount, lastMessage];
}


class ChatReply extends Equatable {
  const ChatReply({
    required this.conversationId,
    required this.title,
    required this.message,
  });

  final String conversationId;
  final String title;
  final ChatMessage message;

  @override
  List<Object?> get props => [conversationId, title, message];
}
