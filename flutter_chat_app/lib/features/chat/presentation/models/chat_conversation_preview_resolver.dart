import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/services/chat_draft_service.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

@immutable
class ChatConversationPreviewData {
  const ChatConversationPreviewData({
    required this.text,
    required this.isDraft,
  });

  final String text;
  final bool isDraft;
}

class ChatConversationPreviewResolver {
  static ChatConversationPreviewData resolve({
    required BuildContext context,
    required Chat chat,
    required ChatDraftService draftService,
  }) {
    final draft = draftService.getDraftSync(chat.id);
    if (draft != null && draft.hasContent) {
      final formattedDraft = _normalizeSingleLine(
        draft.text.formatChatMessage(
          mentionNameById: draft.mentionNameById,
        ),
      );

      final content =
          formattedDraft.isEmpty ? context.l10n.noMessages : formattedDraft;

      return ChatConversationPreviewData(
        text: context.l10n.draftMessagePreview(content),
        isDraft: true,
      );
    }

    final formattedLastMessage = _normalizeSingleLine(
      (chat.lastMessagePreview ?? context.l10n.noMessages).formatChatMessage(
        mentionNameById: {
          for (final member in chat.members)
            if (member.userId.trim().isNotEmpty &&
                (member.fullName?.trim().isNotEmpty ?? false))
              member.userId.trim(): member.fullName!.trim(),
        },
      ),
    );

    return ChatConversationPreviewData(
      text: formattedLastMessage.isEmpty
          ? context.l10n.noMessages
          : formattedLastMessage,
      isDraft: false,
    );
  }

  static String _normalizeSingleLine(String input) {
    final collapsedSpaces = input.replaceAll(RegExp(r'\s+'), ' ');
    return collapsedSpaces.trim();
  }
}
