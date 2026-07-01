import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';

enum ChatStatus { idle, loading, sending, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.idle,
    this.conversationId,
    this.messages = const [],
    this.errorMessage,
  });

  final ChatStatus status;
  final String? conversationId;
  final List<ChatMessage> messages;
  final String? errorMessage;

  const ChatState.initial() : this();

  bool get isSending => status == ChatStatus.sending;
  bool get isLoading => status == ChatStatus.loading;
  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({
    ChatStatus? status,
    String? conversationId,
    List<ChatMessage>? messages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, conversationId, messages, errorMessage];
}
