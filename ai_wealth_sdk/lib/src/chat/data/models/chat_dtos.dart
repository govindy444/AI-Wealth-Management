import '../../../core/domain/explainability.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';


class ChatDtos {
  const ChatDtos._();

  static ChatMessage messageFromJson(Map<String, dynamic> j) {
    final explanation = j['explanation'];
    return ChatMessage(
      id: (j['id'] as String?) ?? '',
      role: ChatRole.fromWire((j['role'] as String?) ?? 'assistant'),
      content: (j['content'] as String?) ?? '',
      createdAt: _date(j['created_at']),
      explanation: explanation is Map<String, dynamic>
          ? Explanation.fromJson(explanation)
          : null,
    );
  }

  static ChatReply replyFromJson(Map<String, dynamic> j) => ChatReply(
        conversationId: (j['conversation_id'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        message: messageFromJson(
          (j['message'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );

  static Conversation conversationFromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        createdAt: _date(j['created_at']),
        updatedAt: _date(j['updated_at']),
        messages: (j['messages'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(messageFromJson)
            .toList(growable: false),
      );

  static ConversationSummary summaryFromJson(Map<String, dynamic> j) =>
      ConversationSummary(
        id: (j['id'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        updatedAt: _date(j['updated_at']),
        messageCount: (j['message_count'] as num?)?.toInt() ?? 0,
        lastMessage: j['last_message'] as String?,
      );

  static DateTime _date(Object? v) =>
      DateTime.tryParse(v as String? ?? '')?.toLocal() ?? DateTime.now();
}
