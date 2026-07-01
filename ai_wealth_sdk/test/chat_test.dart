import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/chat/data/datasources/chat_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/chat/data/models/chat_dtos.dart';
import 'package:ai_wealth_sdk/src/chat/data/repositories/chat_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _replyJson({
  String conversationId = 'conv_1',
  String content = 'Hello Demo!',
  Map<String, dynamic>? explanation,
}) =>
    {
      'conversation_id': conversationId,
      'title': 'Hello',
      'message': {
        'id': 'msg_1',
        'role': 'assistant',
        'content': content,
        'created_at': '2026-06-29T10:00:00Z',
        'explanation': explanation,
      },
    };

void main() {
  group('ChatDtos', () {
    test('decodes a reply with an explanation', () {
      final reply = ChatDtos.replyFromJson(_replyJson(explanation: {
        'summary': 'Diversify.',
        'reasons': ['Lower risk.'],
        'confidence': 0.7,
      }));

      expect(reply.conversationId, 'conv_1');
      expect(reply.message.isAssistant, isTrue);
      expect(reply.message.hasExplanation, isTrue);
      expect(reply.message.explanation!.confidencePercent, 70);
    });

    test('decodes a reply without an explanation', () {
      final reply = ChatDtos.replyFromJson(_replyJson());
      expect(reply.message.hasExplanation, isFalse);
      expect(reply.message.content, 'Hello Demo!');
    });
  });

  group('ChatController', () {
    ChatController controller(FakeRemote remote) {
      final repo = ChatRepositoryImpl(remote: remote, logger: _logger);
      return ChatController(
        sendMessage: SendMessageUseCase(repo),
        getConversation: GetConversationUseCase(repo),
      );
    }

    test('optimistically adds the user message then appends the reply', () async {
      final c = controller(FakeRemote(_replyJson(content: 'Hi Demo!')));
      addTearDown(c.dispose);

      await c.send('hello');

      expect(c.state.messages.length, 2);
      expect(c.state.messages.first.isUser, isTrue);
      expect(c.state.messages.first.pending, isFalse); // confirmed
      expect(c.state.messages.last.isAssistant, isTrue);
      expect(c.state.messages.last.content, 'Hi Demo!');
      expect(c.state.conversationId, 'conv_1');
      expect(c.state.status, ChatStatus.idle);
    });

    test('reuses the conversation id on the second turn', () async {
      final remote = FakeRemote(_replyJson());
      final c = controller(remote);
      addTearDown(c.dispose);

      await c.send('hi');
      await c.send('and again');

      expect(remote.lastConversationId, 'conv_1'); // sent back on 2nd turn
      expect(c.state.messages.length, 4);
    });

    test('keeps the user message and surfaces an error on failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);

      await c.send('hello');

      expect(c.state.status, ChatStatus.error);
      expect(c.state.errorMessage, isNotNull);
      // User message stays visible; no assistant reply was appended.
      expect(c.state.messages.single.isUser, isTrue);
    });

    test('ignores blank input', () async {
      final c = controller(FakeRemote(_replyJson()));
      addTearDown(c.dispose);
      await c.send('   ');
      expect(c.state.messages, isEmpty);
    });
  });
}

class FakeRemote implements ChatRemoteDataSource {
  FakeRemote(this._reply) : _fail = false;
  FakeRemote.failing()
      : _reply = const {},
        _fail = true;

  final Map<String, dynamic> _reply;
  final bool _fail;
  String? lastConversationId;

  @override
  Future<ChatReply> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    lastConversationId = conversationId;
    if (_fail) throw NetworkException('offline');
    return ChatDtos.replyFromJson(_reply);
  }

  @override
  Future<Conversation> getConversation(String conversationId) async =>
      throw UnimplementedError();
  @override
  Future<List<ConversationSummary>> listConversations() async => const [];
  @override
  Future<void> deleteConversation(String conversationId) async {}
}
