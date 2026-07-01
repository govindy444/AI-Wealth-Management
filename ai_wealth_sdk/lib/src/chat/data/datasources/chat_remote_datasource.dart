import '../../../core/network/api_client.dart';
import '../../domain/entities/conversation.dart';
import '../models/chat_dtos.dart';

abstract interface class ChatRemoteDataSource {
  Future<ChatReply> sendMessage({required String message, String? conversationId});
  Future<Conversation> getConversation(String conversationId);
  Future<List<ConversationSummary>> listConversations();
  Future<void> deleteConversation(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<ChatReply> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    final res = await _client.post('/chat/messages', data: {
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
    });
    return ChatDtos.replyFromJson(res.asMap);
  }

  @override
  Future<Conversation> getConversation(String conversationId) async {
    final res = await _client.get('/chat/conversations/$conversationId');
    return ChatDtos.conversationFromJson(res.asMap);
  }

  @override
  Future<List<ConversationSummary>> listConversations() async {
    final res = await _client.get('/chat/conversations');
    return res.asList
        .cast<Map<String, dynamic>>()
        .map(ChatDtos.summaryFromJson)
        .toList(growable: false);
  }

  @override
  Future<void> deleteConversation(String conversationId) =>
      _client.delete('/chat/conversations/$conversationId');
}
