import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository so the chat screen test never touches the network.
class _FakeChatRepository implements ChatRepository {
  int sends = 0;

  @override
  Future<Result<ChatReply>> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    sends++;
    return success(
      ChatReply(
        conversationId: 'conv_1',
        title: message,
        message: ChatMessage(
          id: 'msg_$sends',
          role: ChatRole.assistant,
          content: 'Here is my advice about: $message',
          createdAt: DateTime(2026, 6, 29),
          explanation: const Explanation(
            summary: 'Diversify and automate.',
            reasons: ['Lowers risk.'],
            confidence: 0.75,
          ),
        ),
      ),
    );
  }

  @override
  Future<Result<Conversation>> getConversation(String id) async =>
      failure(const UnexpectedFailure('unused'));
  @override
  Future<Result<List<ConversationSummary>>> listConversations() async =>
      success(const []);
  @override
  Future<Result<void>> deleteConversation(String id) async => success(null);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(_FakeChatRepository()),
      ],
      child: const MaterialApp(home: ChatScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state with suggestion chips', (tester) async {
    await _pump(tester);
    expect(find.text('Your AI wealth advisor'), findsOneWidget);
    expect(find.text('How should I invest my savings?'), findsOneWidget);
  });

  testWidgets('sending a message shows the user bubble and assistant reply',
      (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'How do I save more?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('How do I save more?'), findsOneWidget); // user bubble
    expect(
      find.text('Here is my advice about: How do I save more?'),
      findsOneWidget,
    );
    // Explainable-AI affordance is attached to the assistant reply.
    expect(find.textContaining('Why this?'), findsOneWidget);
  });

  testWidgets('tapping a suggestion chip sends it', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Help me plan a goal'));
    await tester.pumpAndSettle();

    expect(
      find.text('Here is my advice about: Help me plan a goal'),
      findsOneWidget,
    );
  });
}
