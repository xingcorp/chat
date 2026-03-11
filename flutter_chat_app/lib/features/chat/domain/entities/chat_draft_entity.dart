import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class ChatDraftEntity extends Equatable {
  const ChatDraftEntity({
    required this.conversationId,
    required this.text,
    required this.updatedAt,
    this.mentionNameById = const <String, String>{},
    this.contentDelta,
  });

  final String conversationId;
  final String text;
  final DateTime updatedAt;
  final Map<String, String> mentionNameById;

  /// Rich text content as Quill Delta JSON string.
  ///
  /// Null when the draft contains only plain text (backward compatible).
  final String? contentDelta;

  bool get hasContent => text.trim().isNotEmpty || (contentDelta != null && contentDelta!.trim().isNotEmpty);

  ChatDraftEntity copyWith({
    String? conversationId,
    String? text,
    DateTime? updatedAt,
    Map<String, String>? mentionNameById,
    String? contentDelta,
    bool clearContentDelta = false,
  }) {
    return ChatDraftEntity(
      conversationId: conversationId ?? this.conversationId,
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
      mentionNameById: mentionNameById ?? this.mentionNameById,
      contentDelta: clearContentDelta ? null : (contentDelta ?? this.contentDelta),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        conversationId,
        text,
        updatedAt,
        mentionNameById,
        contentDelta,
      ];
}
