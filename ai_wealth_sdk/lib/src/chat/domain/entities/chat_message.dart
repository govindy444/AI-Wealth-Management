import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';

enum ChatRole {
  user,
  assistant;

  static ChatRole fromWire(String value) =>
      value == 'assistant' ? ChatRole.assistant : ChatRole.user;
}


class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.explanation,
    this.pending = false,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final Explanation? explanation;


  final bool pending;

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;
  bool get hasExplanation => explanation != null;

  ChatMessage copyWith({bool? pending}) => ChatMessage(
        id: id,
        role: role,
        content: content,
        createdAt: createdAt,
        explanation: explanation,
        pending: pending ?? this.pending,
      );

  @override
  List<Object?> get props =>
      [id, role, content, createdAt, explanation, pending];
}
