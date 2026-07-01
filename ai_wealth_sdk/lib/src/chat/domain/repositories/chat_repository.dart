import '../../../core/utils/result.dart';
import '../entities/conversation.dart';


abstract interface class ChatRepository {

  FutureResult<ChatReply> sendMessage({
    required String message,
    String? conversationId,
  });

  FutureResult<Conversation> getConversation(String conversationId);

  FutureResult<List<ConversationSummary>> listConversations();

  FutureResult<void> deleteConversation(String conversationId);
}
