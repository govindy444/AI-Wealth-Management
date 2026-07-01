import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';


class ChatRepositoryImpl with BaseRepository implements ChatRepository {
  ChatRepositoryImpl({
    required ChatRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final ChatRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<ChatReply> sendMessage({
    required String message,
    String? conversationId,
  }) =>
      guard(() => _remote.sendMessage(
            message: message,
            conversationId: conversationId,
          ));

  @override
  FutureResult<Conversation> getConversation(String conversationId) =>
      guard(() => _remote.getConversation(conversationId));

  @override
  FutureResult<List<ConversationSummary>> listConversations() =>
      guard(() => _remote.listConversations());

  @override
  FutureResult<void> deleteConversation(String conversationId) =>
      guard(() => _remote.deleteConversation(conversationId));
}
