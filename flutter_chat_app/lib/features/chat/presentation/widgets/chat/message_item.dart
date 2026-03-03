import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/extensions/text_span_builder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/audio_player_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/expandable_rich_text.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/forward_preview.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/link_preview_card.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/location_message_card.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/media_gallery.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reaction_bar.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reply_preview.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/video_player_widget.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/read_receipt_avatars.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/read_receipt_bottom_sheet.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/sticker_message.dart';
import 'package:flutter_chat_app/presentation/widgets/message_status_indicator.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart'
    as domain;
import 'package:flutter_chat_app/shared/domain/entities/message_queue_status.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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

  // Group chat flag for read receipts
  final bool isGroupChat;

  // Callback when user edits and sends an image from fullscreen gallery
  final void Function(Uint8List editedBytes, String fileName)?
      onEditedImageSend;

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
    this.isGroupChat = false,
    this.onEditedImageSend,
  }) : super(key: key);

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem>
    with AutomaticKeepAliveClientMixin {
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

    // Special handling for @all mention - backend may not include it in mentionTo
    // Add fallback if not present
    if (!mentionNameById.containsKey('all') &&
        widget.uiState.content.contains('[@all]')) {
      mentionNameById['all'] = 'All';
    }

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
        // For current user: use onPrimary (white) since bubble is primary (blue)
        // For other users: use primary (blue) for visibility on light background
        color: widget.uiState.isFromCurrentUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.primary,
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

    return ExpandableRichText(
      spans: spans,
      plainText: normalized,
      style: TextStyle(
        color: textColor,
        fontSize: 16.0,
      ),
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
      if (replyId != null &&
          replyId.isNotEmpty &&
          widget.uiState.replyMessage == null) {
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
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                          padding:
                              const EdgeInsets.only(left: 4.0, bottom: 4.0),
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
                if (isCurrentUser) const SizedBox(width: 4.0),

                // Message status indicator for own messages
                if (isCurrentUser &&
                    GetIt.instance.isRegistered<MessageQueueService>() &&
                    GetIt.instance.isReadySync<MessageQueueService>())
                  RepaintBoundary(
                    child: MessageStatusIndicator(
                      messageId: widget.uiState.id,
                      messageQueueService:
                          GetIt.instance<MessageQueueService>(),
                      status:
                          _mapMessageStatusToQueueStatus(widget.uiState.status),
                    ),
                  ),
              ],
            ),

            // Read receipt avatars below own messages
            if (isCurrentUser && widget.uiState.readReceiptReaders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                child: ReadReceiptAvatars(
                  readers: widget.uiState.readReceiptReaders,
                  isGroupChat: widget.isGroupChat,
                  onTap: widget.isGroupChat
                      ? () => ReadReceiptBottomSheet.show(
                            context,
                            widget.uiState.readReceiptReaders,
                          )
                      : null,
                ),
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

    final typeName =
        widget.uiState.contentType.toString().split('.').last.toLowerCase();
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
    final messageAlignment =
        isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

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
    final parsedLocation = contentType == domain.ContentType.location
        ? LocationMessageData.tryParse(widget.uiState.content)
        : null;

    if (contentType == domain.ContentType.sticker) {
      return _buildStickerMessageBubble(
        context,
        isFromCurrentUser: isFromCurrentUser,
        messageAlignment: messageAlignment,
        maxWidth: bubbleMaxWidth(),
      );
    }

    // For file-only messages (no text), use neutral bubble color
    // to avoid blue background leaking around file tiles
    final hasTextContent =
        widget.uiState.content.isNotEmpty && parsedLocation == null;
    final hasOnlyMedia = renderableAttachments.isNotEmpty &&
        renderableAttachments
            .every((a) => a.type == 'image' || a.type == 'video') &&
        !hasTextContent;
    final hasOnlyFiles = renderableAttachments.isNotEmpty &&
        renderableAttachments
            .every((a) => a.type != 'image' && a.type != 'video') &&
        !hasTextContent;

    final isOnPrimaryBackground = isFromCurrentUser && !hasOnlyMedia;

    final bubbleColor = hasOnlyFiles
        ? (isFromCurrentUser
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest)
        : (hasOnlyMedia
            ? Colors.transparent
            : (isFromCurrentUser
                ? theme.colorScheme.primary
                : theme.cardColor));

    final textColor = hasOnlyFiles
        ? (theme.textTheme.bodyMedium?.color ?? Colors.black)
        : (isFromCurrentUser
            ? theme.colorScheme.onPrimary
            : theme.textTheme.bodyMedium?.color ?? Colors.black);

    // Determine if we should use audio/video player instead of media gallery
    final isAudioMessage = contentType == domain.ContentType.audio;
    final isVideoMessage = contentType == domain.ContentType.video;
    final hasUploadingAttachment =
        renderableAttachments.any((attachment) => attachment.isUploading);
    final useSpecialPlayer = (isAudioMessage || isVideoMessage) &&
        renderableAttachments.length == 1 &&
        !hasUploadingAttachment;

    return Container(
      constraints: BoxConstraints(
        maxWidth: bubbleMaxWidth(),
      ),
      decoration: BoxDecoration(
        color: widget.uiState.isHighlighted
            ? bubbleColor.withValues(alpha: 0.7)
            : bubbleColor,
        borderRadius: _getBubbleBorderRadius(isFromCurrentUser),
      ),
      child: ClipRRect(
        borderRadius: _getBubbleBorderRadius(isFromCurrentUser),
        child: Column(
          crossAxisAlignment: messageAlignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Forward preview
            if (widget.uiState.forwardInfo != null)
              _buildForwardPreview(
                context,
                isFromCurrentUser,
                isOnPrimaryBackground: isOnPrimaryBackground,
              ),

            // Reply preview
            if (widget.uiState.replyMessage != null)
              _buildReplyPreview(
                context,
                isFromCurrentUser,
                isOnPrimaryBackground: isOnPrimaryBackground,
              ),

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
            // No padding — media fills bubble edge-to-edge like Telegram/WhatsApp
            if (renderableAttachments.isNotEmpty && !useSpecialPlayer)
              Stack(
                children: [
                  _buildAttachmentPreviews(
                    context,
                    attachments: renderableAttachments,
                    isFromCurrentUser: isFromCurrentUser,
                    isOnPrimaryBackground: isOnPrimaryBackground,
                  ),
                  if (hasOnlyMedia)
                    Positioned(
                      right: 8.0,
                      bottom: 8.0,
                      child: ReactionBar(
                        groupedReactions: widget.uiState.groupedReactions,
                        isFromCurrentUser: isFromCurrentUser,
                        showAddButton: true,
                        onReactionTap: (
                          emojiCode,
                          reactorIds,
                          reactorNameById,
                          reactorAvatarById,
                        ) {
                          ReactionDetailModal.show(
                            context,
                            emojiCode: emojiCode,
                            reactorIds: reactorIds,
                            reactorNameById: reactorNameById,
                            reactorAvatarById: reactorAvatarById,
                          );
                        },
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

            if (parsedLocation != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LocationMessageCard(
                  location: parsedLocation,
                  isFromCurrentUser: isFromCurrentUser,
                ),
              ),

            // Message content
            if ((widget.uiState.content.isNotEmpty ||
                    renderableAttachments.isEmpty) &&
                parsedLocation == null)
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

                    if (widget.uiState.showTimestamp || widget.uiState.isEdited)
                      const SizedBox(height: 4.0),
                    _buildMessageMetaRow(textColor),
                  ],
                ),
              ),

            if (parsedLocation != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _buildMessageMetaRow(textColor),
              ),

            // Reactions bar (phia duoi content)
            if (widget.uiState.groupedReactions.isNotEmpty && !hasOnlyMedia)
              Padding(
                padding:
                    const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0),
                child: ReactionBar(
                  groupedReactions: widget.uiState.groupedReactions,
                  isFromCurrentUser: isFromCurrentUser,
                  showAddButton: true,
                  // Tap → xem danh sách ai đã react (như Messenger/WhatsApp)
                  onReactionTap: (
                    emojiCode,
                    reactorIds,
                    reactorNameById,
                    reactorAvatarById,
                  ) {
                    ReactionDetailModal.show(
                      context,
                      emojiCode: emojiCode,
                      reactorIds: reactorIds,
                      reactorNameById: reactorNameById,
                      reactorAvatarById: reactorAvatarById,
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

  Widget _buildMessageMetaRow(Color textColor) {
    if (!widget.uiState.showTimestamp && !widget.uiState.isEdited) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
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
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarUrl = widget.uiState.senderAvatar;
    final senderName = widget.uiState.senderName.trim();
    final senderId = widget.uiState.senderId;

    return GestureDetector(
      onTap: () => _showAvatarMenu(context, senderId, senderName, avatarUrl),
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: HeroAvatar(
          id: senderId,
          imageUrl: avatarUrl,
          displayName: senderName,
          size: 32,
          hasBorder: false,
          enableHero: false,
        ),
      ),
    );
  }

  void _showAvatarMenu(BuildContext context, String userId, String displayName,
      String? avatarUrl) {
    final l10n = context.l10n;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 12),
              Text(l10n.viewProfile),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'message',
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 12),
              Text(l10n.sendDirectMessage),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'profile':
          context.push(
            '/users/$userId',
            extra: {
              'displayName': displayName,
              'avatarUrl': avatarUrl,
            },
          );
          break;
        case 'message':
          _openDirectMessage(context, userId);
          break;
      }
    });
  }

  Future<void> _openDirectMessage(BuildContext context, String userId) async {
    try {
      final chatRemoteDataSource = GetIt.I<IChatRemoteDataSource>();
      final chat =
          await chatRemoteDataSource.createDirectChat(receiverId: userId);
      if (!context.mounted) return;
      await ChatNavigationHelper.navigateToChatDetail(context, chatId: chat.id);
    } catch (_) {
      if (!context.mounted) return;
      // Fallback: navigate using userId as chatId
      await ChatNavigationHelper.navigateToChatDetail(context, chatId: userId);
    }
  }

  Widget _buildReplyPreview(
    BuildContext context,
    bool isFromCurrentUser, {
    required bool isOnPrimaryBackground,
  }) {
    final reply = widget.uiState.replyMessage;
    if (reply == null) return const SizedBox.shrink();

    return ReplyPreview(
      replyMessage: reply,
      isFromCurrentUser: isFromCurrentUser,
      isOnPrimaryBackground: isOnPrimaryBackground,
      showThumbnail: true,
      onTap: widget.onReplyPreviewTap ?? () {},
    );
  }

  Widget _buildForwardPreview(
    BuildContext context,
    bool isFromCurrentUser, {
    required bool isOnPrimaryBackground,
  }) {
    final forwardInfo = widget.uiState.forwardInfo;
    if (forwardInfo == null) return const SizedBox.shrink();

    return ForwardPreview(
      forwardInfo: forwardInfo,
      isFromCurrentUser: isFromCurrentUser,
      isOnPrimaryBackground: isOnPrimaryBackground,
      showThumbnail: true,
    );
  }

  Widget _buildAttachmentPreviews(
    BuildContext context, {
    required List<domain.MessageAttachment> attachments,
    required bool isFromCurrentUser,
    required bool isOnPrimaryBackground,
  }) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    // MediaGallery now handles upload progress overlay internally
    // for each attachment with percentage display
    // Pass message and chatId for reaction/forward support in fullscreen view
    return MediaGallery(
      attachments: attachments,
      layout: MediaGalleryLayout.grid,
      message: widget.uiState.message,
      chatId: widget.uiState.chatId,
      isFromCurrentUser: isFromCurrentUser,
      isOnPrimaryBackground: isOnPrimaryBackground,
      onEditedImageSend: widget.onEditedImageSend,
    );
  }

  Widget _buildStickerMessageBubble(
    BuildContext context, {
    required bool isFromCurrentUser,
    required CrossAxisAlignment messageAlignment,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodySmall?.color ?? Colors.black;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: messageAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.uiState.forwardInfo != null)
            _buildForwardPreview(
              context,
              isFromCurrentUser,
              isOnPrimaryBackground: false,
            ),
          if (widget.uiState.replyMessage != null)
            _buildReplyPreview(
              context,
              isFromCurrentUser,
              isOnPrimaryBackground: false,
            ),
          StickerMessageWidget(
            stickerCode: widget.uiState.content,
            size: AppDimens.avatarHuge,
          ),
          if (widget.uiState.showTimestamp || widget.uiState.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.spaceXSmall),
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
          if (widget.uiState.groupedReactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.spaceXSmall),
              child: ReactionBar(
                groupedReactions: widget.uiState.groupedReactions,
                isFromCurrentUser: isFromCurrentUser,
                showAddButton: true,
                onReactionTap: (
                  emojiCode,
                  reactorIds,
                  reactorNameById,
                  reactorAvatarById,
                ) {
                  ReactionDetailModal.show(
                    context,
                    emojiCode: emojiCode,
                    reactorIds: reactorIds,
                    reactorNameById: reactorNameById,
                    reactorAvatarById: reactorAvatarById,
                  );
                },
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
    );
  }

  /// Map MessageStatus to MessageQueueStatus
  MessageQueueStatus _mapMessageStatusToQueueStatus(
      domain.MessageStatus status) {
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
