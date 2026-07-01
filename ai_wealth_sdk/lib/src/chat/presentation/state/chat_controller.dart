import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_state.dart';


class ChatController extends StateNotifier<ChatState> {
  ChatController({
    required SendMessageUseCase sendMessage,
    required GetConversationUseCase getConversation,
  })  : _sendMessage = sendMessage,
        _getConversation = getConversation,
        super(const ChatState.initial());

  final SendMessageUseCase _sendMessage;
  final GetConversationUseCase _getConversation;

 
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
      pending: true,
    );

    state = state.copyWith(
      status: ChatStatus.sending,
      messages: [...state.messages, userMessage],
      clearError: true,
    );

    final result = await _sendMessage(
      SendMessageParams(message: trimmed, conversationId: state.conversationId),
    );

    state = result.fold(
      (failure) => state.copyWith(
        status: ChatStatus.error,
        errorMessage: failure.message,
        messages: _withConfirmedUser(userMessage),
      ),
      (reply) => state.copyWith(
        status: ChatStatus.idle,
        conversationId: reply.conversationId,
        messages: [..._withConfirmedUser(userMessage), reply.message],
      ),
    );
  }

  Future<void> openConversation(String conversationId) async {
    state = state.copyWith(status: ChatStatus.loading, clearError: true);
    final result = await _getConversation(conversationId);
    state = result.fold(
      (failure) => state.copyWith(
        status: ChatStatus.error,
        errorMessage: failure.message,
      ),
      (conversation) => ChatState(
        status: ChatStatus.idle,
        conversationId: conversation.id,
        messages: conversation.messages,
      ),
    );
  }

  void startNew() => state = const ChatState.initial();

  List<ChatMessage> _withConfirmedUser(ChatMessage userMessage) {
    return [
      for (final m in state.messages)
        if (m.id == userMessage.id) m.copyWith(pending: false) else m,
    ];
  }
}
