import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ChatDraft {
  const ChatDraft({
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'conversationId': conversationId,
      'text': text,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'mentionNameById': mentionNameById,
    };
  }

  factory ChatDraft.fromJson(Map<String, dynamic> json) {
    final mentionMapRaw = json['mentionNameById'];
    final mentionMap = <String, String>{};

    if (mentionMapRaw is Map) {
      for (final entry in mentionMapRaw.entries) {
        final key = entry.key?.toString().trim() ?? '';
        final value = entry.value?.toString().trim() ?? '';
        if (key.isEmpty || value.isEmpty) continue;
        mentionMap[key] = value;
      }
    }

    return ChatDraft(
      conversationId: (json['conversationId'] as String?)?.trim() ?? '',
      text: (json['text'] as String?) ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAtMs'] as num?)?.toInt() ?? 0,
      ),
      mentionNameById: mentionMap,
    );
  }
}

class ChatDraftService {
  ChatDraftService({
    required SharedPreferences preferences,
    required AppLogger logger,
  })  : _preferences = preferences,
        _logger = logger {
    _hydrateDraftsFromStorage();
  }

  static const String _storagePrefix = 'chat_draft_v2_';

  final SharedPreferences _preferences;
  final AppLogger _logger;
  final ValueNotifier<Map<String, ChatDraft>> _draftsNotifier =
      ValueNotifier<Map<String, ChatDraft>>(const <String, ChatDraft>{});

  ValueListenable<Map<String, ChatDraft>> get draftsListenable =>
      _draftsNotifier;

  ChatDraft? getDraftSync(String conversationId) {
    final normalizedId = conversationId.trim();
    if (normalizedId.isEmpty) return null;
    return _draftsNotifier.value[normalizedId];
  }

  Future<ChatDraft?> getDraft(String conversationId) async {
    return getDraftSync(conversationId);
  }

  Future<void> saveDraft({
    required String conversationId,
    required String text,
    Map<String, String> mentionNameById = const <String, String>{},
  }) async {
    final normalizedId = conversationId.trim();
    if (normalizedId.isEmpty) return;

    final normalizedText = text.replaceAll('\r\n', '\n');
    if (normalizedText.trim().isEmpty) {
      await removeDraft(normalizedId);
      return;
    }

    final normalizedMentions = <String, String>{
      for (final entry in mentionNameById.entries)
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
          entry.key.trim(): entry.value.trim(),
    };

    final draft = ChatDraft(
      conversationId: normalizedId,
      text: normalizedText,
      updatedAt: DateTime.now(),
      mentionNameById: normalizedMentions,
    );

    try {
      final key = _storageKey(normalizedId);
      await _preferences.setString(key, jsonEncode(draft.toJson()));

      final updated = Map<String, ChatDraft>.from(_draftsNotifier.value);
      updated[normalizedId] = draft;
      _draftsNotifier.value = Map<String, ChatDraft>.unmodifiable(updated);
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to save draft',
        error: error,
        stackTrace: stackTrace,
        context: <String, dynamic>{'conversationId': normalizedId},
      );
    }
  }

  Future<void> removeDraft(String conversationId) async {
    final normalizedId = conversationId.trim();
    if (normalizedId.isEmpty) return;

    try {
      await _preferences.remove(_storageKey(normalizedId));

      if (!_draftsNotifier.value.containsKey(normalizedId)) {
        return;
      }

      final updated = Map<String, ChatDraft>.from(_draftsNotifier.value)
        ..remove(normalizedId);
      _draftsNotifier.value = Map<String, ChatDraft>.unmodifiable(updated);
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to remove draft',
        error: error,
        stackTrace: stackTrace,
        context: <String, dynamic>{'conversationId': normalizedId},
      );
    }
  }

  void _hydrateDraftsFromStorage() {
    final hydrated = <String, ChatDraft>{};

    for (final key in _preferences.getKeys()) {
      if (!key.startsWith(_storagePrefix)) {
        continue;
      }

      final conversationId = key.substring(_storagePrefix.length).trim();
      if (conversationId.isEmpty) {
        continue;
      }

      final raw = _preferences.getString(key);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final draft = ChatDraft.fromJson(decoded);
          if (draft.conversationId.isNotEmpty && draft.hasContent) {
            hydrated[draft.conversationId] = draft;
          }
          continue;
        }

        if (decoded is Map) {
          final dynamicMap = <String, dynamic>{
            for (final entry in decoded.entries)
              entry.key.toString(): entry.value,
          };
          final draft = ChatDraft.fromJson(dynamicMap);
          if (draft.conversationId.isNotEmpty && draft.hasContent) {
            hydrated[draft.conversationId] = draft;
          }
          continue;
        }
      } catch (_) {
        // Fallback for legacy raw string format.
      }

      hydrated[conversationId] = ChatDraft(
        conversationId: conversationId,
        text: raw,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    _draftsNotifier.value = Map<String, ChatDraft>.unmodifiable(hydrated);
  }

  String _storageKey(String conversationId) {
    return '$_storagePrefix$conversationId';
  }
}
