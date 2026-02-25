import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/extensions/text_span_builder.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart' as domain;
import 'package:flutter_chat_app/shared/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/presentation/widgets/message_status_indicator.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/media_preview.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/media_gallery.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reaction_bar.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reply_preview.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/audio_player_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/video_player_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/link_preview_card.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/read_receipt_avatars.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';

class MessageItem extends StatefulWidget {
  final MessageUIState uiState;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  // Selection mode
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  // Swipe-to-reply
  final VoidCallback? onSwipeReply;

  // Reply preview tap (scroll to original)
  final VoidCallback? onReplyPreviewTap;

  // Read receipts
  final List<ReaderInfo>? readReceipts;

  const MessageItem({
    Key? key,
    required this.uiState,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onSwipeReply,
    this.onReplyPreviewTap,
    this.readReceipts,
  }) : super(key: key);

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> with AutomaticKeepAliveClientMixin {
  bool _isMediaLoaded = false;
  bool _isMediaError = false;
  late double _mediaAspectRatio = 16 / 9;
  File? _localMediaFile;

  @override
  bool get wantKeepAlive => widget.uiState.hasMedia;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildMentionableMessageText({
    required ThemeData theme,
    required Color textColor,
  }) {
    final mentionNameById = <String, String>{
      for (final m in widget.uiState.mentionTo)
        if (m.id.isNotEmpty && m.name.trim().isNotEmpty) m.id: m.name.trim(),
    };

    final raw = widget.uiState.content;
    final normalized = raw.formatChatMessage(mentionNameById: mentionNameById);

    final spans = TextSpanBuilder.buildSpans(
      rawContent: raw,
      normalizedContent: normalized,
      textStyle: TextStyle(
        color: textColor,
        fontSize: 16.0,
      ),
      linkStyle: TextStyle(
        color: widget.uiState.isFromCurrentUser
            ? textColor
            : theme.colorScheme.primary,
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
      mentionStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
      ),
      mentionNameById: mentionNameById,
      onTapMention: (userId) {
        context.push(
          '/users/$userId',
          extra: {
            'displayName': mentionNameById[userId],
          },
        );
      },
      context: context,
    );

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _parseMentionSpans({
    required String rawContent,
    required String normalizedContent,
    required TextStyle textStyle,
    required TextStyle mentionStyle,
    required Map<String, String> mentionNameById,
    required void Function(String userId) onTapMention,
  }) {
    if (!rawContent.contains('@') && !rawContent.contains('[')) {
      return [TextSpan(text: normalizedContent, style: textStyle)];
    }

    final normalizedRaw = rawContent
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll('<br>', '\n');

    final mentionPattern = RegExp(
      r'\[@([^\]]+)\]|@([0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{12})',
    );

    final matches = mentionPattern.allMatches(normalizedRaw).toList();
    if (matches.isEmpty) {
      return [TextSpan(text: normalizedContent, style: textStyle)];
    }

    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final m in matches) {
      if (m.start > lastIndex) {
        spans.add(
          TextSpan(
            text: normalizedRaw.substring(lastIndex, m.start),
            style: textStyle,
          ),
        );
      }

      final id = (m.group(1) ?? m.group(2) ?? '').trim();
      final displayName = mentionNameById[id];
      if (id.isEmpty || displayName == null || displayName.trim().isEmpty) {
        spans.add(
          TextSpan(
            text: normalizedRaw.substring(m.start, m.end),
            style: textStyle,
          ),
        );
      } else {
        final text = '@${displayName.trim()}';
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => onTapMention(id),
              child: Text(
                text,
                style: mentionStyle,
              ),
            ),
          ),
        );
      }

      lastIndex = m.end;
    }

    if (lastIndex < normalizedRaw.length) {
      spans.add(
        TextSpan(
          text: normalizedRaw.substring(lastIndex),
          style: textStyle,
        ),
      );
    }

    return spans;
  }

  @override
  void didUpdateWidget(MessageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uiState.id != widget.uiState.id) {
      // Reset media state when message changes
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (kDebugMode) {
      final replyId = widget.uiState.message?.replyMessageId;
      if (replyId != null && replyId.isNotEmpty && widget.uiState.replyMessage == null) {
        debugPrint(
          '[MessageItem] reply missing uiStateId=${widget.uiState.id} '
          'replyMessageId=$replyId contentType=${widget.uiState.contentType} '
          'content="${widget.uiState.content.replaceAll("\n", "\\n")}"',
        );
      }
    }

    final theme = Theme.of(context);
    final isCurrentUser = widget.uiState.isFromCurrentUser;
    final position = widget.uiState.position;
    final isLast = position == BubblePosition.last ||
        position == BubblePosition.standalone;

    final messageBubble = RepaintBoundary(
      child: _buildMessageBubble(context, isCurrentUser),
    );

    // Wrap in Dismissible for swipe-to-reply
    Widget messageContent = GestureDetector(
      onTap: widget.isSelectionMode
          ? () => widget.onSelectionChanged?.call(!widget.isSelected)
          : null,
      onLongPress: widget.onLongPress,
      child: Container(
        color: widget.isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : null,
        margin: EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          bottom: isLast ? 12.0 : 4.0,
          top: widget.uiState.showSenderName ? 8.0 : 0.0,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message row with avatar for non-current user
            Row(
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Selection checkbox
                if (widget.isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (val) =>
                          widget.onSelectionChanged?.call(val ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                // Avatar for messages from others
                if (!isCurrentUser && widget.uiState.showAvatar)
                  RepaintBoundary(
                    child: _buildAvatar(context),
                  )
                else if (!isCurrentUser && !widget.isSelectionMode)
                  const SizedBox(width: 36.0),

                // Sender name + message bubble aligned to the same start as bubble
                Flexible(
                  child: Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.uiState.showSenderName && !isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                          child: RepaintBoundary(
                            child: Text(
                              widget.uiState.senderName,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      messageBubble,
                    ],
                  ),
                ),

                // Space for status indicator on own messages
                if (isCurrentUser)
                  const SizedBox(width: 4.0),

                // Message status indicator for own messages
                if (isCurrentUser &&
                    GetIt.instance.isRegistered<MessageQueueService>() &&
                    GetIt.instance.isReadySync<MessageQueueService>())
                  RepaintBoundary(
                    child: MessageStatusIndicator(
                      messageId: widget.uiState.id,
                      messageQueueService: GetIt.instance<MessageQueueService>(),
                      status: _mapMessageStatusToQueueStatus(widget.uiState.status),
                    ),
                  ),
              ],
            ),

            // Read receipt avatars below own messages at last/standalone position
            if (isCurrentUser &&
                isLast &&
                widget.readReceipts != null &&
                widget.readReceipts!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                child: ReadReceiptAvatars(readers: widget.readReceipts!),
              ),
          ],
        ),
      ),
    );

    // Wrap with Dismissible for swipe-to-reply (only when not in selection mode)
    if (widget.onSwipeReply != null && !widget.isSelectionMode) {
      messageContent = Dismissible(
        key: ValueKey('swipe_${widget.uiState.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          widget.onSwipeReply!();
          return false; // Don't actually dismiss
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24.0),
          child: Icon(
            Icons.reply,
            color: theme.colorScheme.primary,
          ),
        ),
        child: messageContent,
      );
    }

    return messageContent;
  }

  List<domain.MessageAttachment> _getRenderableAttachments() {
    final existing = widget.uiState.attachments;
    if (existing.isNotEmpty) return existing;

    final urls = widget.uiState.urls;
    if (urls.isEmpty) return const [];

    final typeName = widget.uiState.contentType.toString().split('.').last.toLowerCase();
    final attachmentType = switch (typeName) {
      'image' => 'image',
      'video' => 'video',
      'audio' => 'audio',
      'file' => 'file',
      _ => 'file',
    };

    return urls
        .where((u) => u.trim().isNotEmpty)
        .map<domain.MessageAttachment>(
          (u) => domain.MessageAttachment(
            id: '${widget.uiState.id}-$u',
            type: attachmentType,
            url: u,
            size: 0,
            name: widget.uiState.fileName ?? '',
          ),
        )
        .toList(growable: false);
  }

  Widget _buildMessageBubble(BuildContext context, bool isFromCurrentUser) {
    final ThemeData theme = Theme.of(context);
    final messageAlignment = isFromCurrentUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    double bubbleMaxWidth() {
      final screenWidth = MediaQuery.of(context).size.width;
      final relative = screenWidth * 0.75;
      final isDesktop = screenWidth >= AppDimens.breakpointDesktop;
      if (!isDesktop) return relative;
      const cap = 520.0;
      return relative > cap ? cap : relative;
    }

    // Deleted message placeholder
    if (widget.uiState.isDeleted) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: bubbleMaxWidth(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: _getBubbleBorderRadius(isFromCurrentUser),
          border: Border.all(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 14.0,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            const SizedBox(width: 6.0),
            Text(
              context.l10n.messageDeleted,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                fontSize: 14.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final renderableAttachments = _getRenderableAttachments();
    final contentType = widget.uiState.contentType;

    final bubbleColor = isFromCurrentUser
        ? theme.colorScheme.primary.withOpacity(0.8)
        : theme.cardColor;

    final textColor = isFromCurrentUser
        ? theme.colorScheme.onPrimary
        : theme.textTheme.bodyMedium?.color ?? Colors.black;

    // Determine if we should use audio/video player instead of media gallery
    final isAudioMessage = contentType == domain.ContentType.audio;
    final isVideoMessage = contentType == domain.ContentType.video;
    final useSpecialPlayer = (isAudioMessage || isVideoMessage) &&
        renderableAttachments.length == 1;

    return Container(
      constraints: BoxConstraints(
        maxWidth: bubbleMaxWidth(),
      ),
      decoration: BoxDecoration(
        color: widget.uiState.isHighlighted
            ? bubbleColor.withOpacity(0.7)
            : bubbleColor,
        borderRadius: _getBubbleBorderRadius(isFromCurrentUser),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _getBubbleBorderRadius(isFromCurrentUser),
        child: Column(
          crossAxisAlignment: messageAlignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.uiState.replyMessage != null)
              _buildReplyPreview(context, isFromCurrentUser),

            // Audio player for audio messages
            if (useSpecialPlayer && isAudioMessage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: AudioPlayerWidget(
                  url: renderableAttachments.first.url,
                  isFromCurrentUser: isFromCurrentUser,
                ),
              ),

            // Video player for video messages
            if (useSpecialPlayer && isVideoMessage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: VideoPlayerWidget(
                  url: renderableAttachments.first.url,
                  isFromCurrentUser: isFromCurrentUser,
                ),
              ),

            // Attachment previews (skip for single audio/video with special player)
            if (renderableAttachments.isNotEmpty && !useSpecialPlayer)
              _buildAttachmentPreviews(context, attachments: renderableAttachments),

            // Message content
            if (widget.uiState.content.isNotEmpty || renderableAttachments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: messageAlignment,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Message text
                    RepaintBoundary(
                      child: _buildMentionableMessageText(
                        theme: theme,
                        textColor: textColor,
                      ),
                    ),

                    // Link preview card
                    if (widget.uiState.hasLink &&
                        widget.uiState.previewLink != null)
                      LinkPreviewCard(
                        url: widget.uiState.previewLink!,
                        isFromCurrentUser: isFromCurrentUser,
                      ),

                    const SizedBox(height: 4.0),

                    // Timestamp + edited indicator
                    RepaintBoundary(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.uiState.isEdited)
                            Text(
                              '${context.l10n.edited}  ',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                                fontSize: 10.0,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (widget.uiState.showTimestamp)
                            Text(
                              widget.uiState.formattedTime,
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 10.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Reactions bar (phia duoi content)
            if (widget.uiState.groupedReactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0),
                child: ReactionBar(
                  groupedReactions: widget.uiState.groupedReactions,
                  showAddButton: true,
                  // Tap → xem danh sách ai đã react (như Messenger/WhatsApp)
                  onReactionTap: (emojiCode, reactorIds, reactorNames) {
                    ReactionDetailModal.show(
                      context,
                      emojiCode: emojiCode,
                      reactorNames: reactorNames,
                    );
                  },
                  // Long press → thu hồi reaction (nếu mình đã react emoji đó)
                  onReactionLongPress: (emojiCode, isCurrentlyReacted) {
                    if (isCurrentlyReacted) {
                      context.read<MessageBloc>().add(
                        ToggleReaction(
                          messageId: widget.uiState.id,
                          emojiCode: emojiCode,
                        ),
                      );
                    }
                  },
                  onAddReaction: () {
                    EmojiPickerBottomSheet.show(
                      context,
                      onEmojiSelected: (emoji) {
                        context.read<MessageBloc>().add(
                          ToggleReaction(
                            messageId: widget.uiState.id,
                            emojiCode: emoji,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarUrl = widget.uiState.senderAvatar;
    final senderName = widget.uiState.senderName.trim();

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: HeroAvatar(
        id: widget.uiState.senderId,
        imageUrl: avatarUrl,
        displayName: senderName,
        size: 32,
        hasBorder: false,
        enableHero: false,
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isFromCurrentUser) {
    final reply = widget.uiState.replyMessage;
    if (reply == null) return const SizedBox.shrink();

    return ReplyPreview(
      replyMessage: reply,
      isFromCurrentUser: isFromCurrentUser,
      showThumbnail: true,
      onTap: widget.onReplyPreviewTap ?? () {},
    );
  }

  Widget _buildAttachmentPreviews(
    BuildContext context, {
    required List<domain.MessageAttachment> attachments,
  }) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    // MediaGallery now handles upload progress overlay internally
    // for each attachment with percentage display
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
      child: MediaGallery(
        attachments: attachments,
        layout: MediaGalleryLayout.grid,
      ),
    );
  }

  /// Map MessageStatus to MessageQueueStatus
  MessageQueueStatus _mapMessageStatusToQueueStatus(domain.MessageStatus status) {
    switch (status) {
      case domain.MessageStatus.pending:
        return MessageQueueStatus.pending;
      case domain.MessageStatus.sending:
        return MessageQueueStatus.sending;
      case domain.MessageStatus.sent:
        return MessageQueueStatus.sent;
      case domain.MessageStatus.delivered:
        return MessageQueueStatus.delivered;
      case domain.MessageStatus.read:
        return MessageQueueStatus.read;
      case domain.MessageStatus.failed:
        return MessageQueueStatus.failed;
    }
  }

  /// Border radius dua tren BubblePosition
  BorderRadius _getBubbleBorderRadius(bool isFromCurrentUser) {
    const radius = Radius.circular(16.0);
    const smallRadius = Radius.circular(4.0);

    final position = widget.uiState.position;

    if (isFromCurrentUser) {
      switch (position) {
        case BubblePosition.standalone:
          return const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: smallRadius,
          );
        case BubblePosition.first:
          return const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: smallRadius,
          );
        case BubblePosition.middle:
          return const BorderRadius.only(
            topLeft: radius,
            topRight: smallRadius,
            bottomLeft: radius,
            bottomRight: smallRadius,
          );
        case BubblePosition.last:
          return const BorderRadius.only(
            topLeft: radius,
            topRight: smallRadius,
            bottomLeft: radius,
            bottomRight: radius,
          );
      }
    }

    switch (position) {
      case BubblePosition.standalone:
        return const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: smallRadius,
          bottomRight: radius,
        );
      case BubblePosition.first:
        return const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: smallRadius,
          bottomRight: radius,
        );
      case BubblePosition.middle:
        return const BorderRadius.only(
          topLeft: smallRadius,
          topRight: radius,
          bottomLeft: smallRadius,
          bottomRight: radius,
        );
      case BubblePosition.last:
        return const BorderRadius.only(
          topLeft: smallRadius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        );
    }
  }
}
