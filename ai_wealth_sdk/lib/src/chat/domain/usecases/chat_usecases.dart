import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class SendMessageParams extends Equatable {
  const SendMessageParams({required this.message, this.conversationId});
  final String message;
  final String? conversationId;

  @override
  List<Object?> get props => [message, conversationId];
}

class SendMessageUseCase implements UseCase<ChatReply, SendMessageParams> {
  SendMessageUseCase(this._repository);
  final ChatRepository _repository;

  @override
  FutureResult<ChatReply> call(SendMessageParams params) =>
      _repository.sendMessage(
        message: params.message,
        conversationId: params.conversationId,
      );
}

class GetConversationUseCase implements UseCase<Conversation, String> {
  GetConversationUseCase(this._repository);
  final ChatRepository _repository;

  @override
  FutureResult<Conversation> call(String conversationId) =>
      _repository.getConversation(conversationId);
}

class ListConversationsUseCase
    implements UseCase<List<ConversationSummary>, NoParams> {
  ListConversationsUseCase(this._repository);
  final ChatRepository _repository;

  @override
  FutureResult<List<ConversationSummary>> call(NoParams params) =>
      _repository.listConversations();
}

class DeleteConversationUseCase implements UseCase<void, String> {
  DeleteConversationUseCase(this._repository);
  final ChatRepository _repository;

  @override
  FutureResult<void> call(String conversationId) =>
      _repository.deleteConversation(conversationId);
}
