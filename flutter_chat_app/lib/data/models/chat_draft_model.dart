import 'dart:convert';

import 'package:flutter_chat_app/core/utils/isar_id.dart';
import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';
import 'package:isar/isar.dart';

part 'chat_draft_model.g.dart';

@collection
class ChatDraftModel {
  ChatDraftModel({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.updatedAt,
    required this.mentionNameByIdJson,
    this.contentDelta,
  });

  @Id()
  final int id;

  @Index(unique: true)
  final String conversationId;

  final String text;

  @Index()
  final DateTime updatedAt;

  final String mentionNameByIdJson;

  /// Rich text content as Quill Delta JSON string.
  ///
  /// Null for plain text drafts. Nullable String in Isar does not
  /// require a schema migration.
  final String? contentDelta;

  factory ChatDraftModel.fromEntity(ChatDraftEntity entity) {
    final normalizedConversationId = entity.conversationId.trim();

    return ChatDraftModel(
      id: normalizedConversationId.toIsarId(),
      conversationId: normalizedConversationId,
      text: entity.text,
      updatedAt: entity.updatedAt,
      mentionNameByIdJson: _encodeMentions(entity.mentionNameById),
      contentDelta: entity.contentDelta,
    );
  }

  ChatDraftEntity toEntity() {
    return ChatDraftEntity(
      conversationId: conversationId,
      text: text,
      updatedAt: updatedAt,
      mentionNameById: _decodeMentions(mentionNameByIdJson),
      contentDelta: contentDelta,
    );
  }

  static String _encodeMentions(Map<String, String> mentionNameById) {
    final normalized = <String, String>{
      for (final entry in mentionNameById.entries)
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
          entry.key.trim(): entry.value.trim(),
    };

    if (normalized.isEmpty) return '{}';
    return jsonEncode(normalized);
  }

  static Map<String, String> _decodeMentions(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const <String, String>{};
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return const <String, String>{};
      }

      final mentionNameById = <String, String>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isEmpty || value.isEmpty) continue;
        mentionNameById[key] = value;
      }

      return mentionNameById;
    } catch (_) {
      return const <String, String>{};
    }
  }
}
