import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class ChatDraftEntity extends Equatable {
  const ChatDraftEntity({
    required this.conversationId,
    required this.text,
    required this.updatedAt,
    this.mentionNameById = const <String, String>{},
  });

  final String conversationId;
  final String text;
  final DateTime updatedAt;
  final Map<String, String> mentionNameById;

  bool get hasContent => text.trim().isNotEmpty;

  ChatDraftEntity copyWith({
    String? conversationId,
    String? text,
    DateTime? updatedAt,
    Map<String, String>? mentionNameById,
  }) {
    return ChatDraftEntity(
      conversationId: conversationId ?? this.conversationId,
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
      mentionNameById: mentionNameById ?? this.mentionNameById,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        conversationId,
        text,
        updatedAt,
        mentionNameById,
      ];
}
