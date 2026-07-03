import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/extensions/emoji_extensions.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/extensions/text_span_builder.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/utils/message_utils.dart';
import 'package:flutter_chat_app/core/utils/platform_utils.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_html_content.dart';
import 'package:flutter_html/flutter_html.dart' show Style, FontSize;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/audio_player_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/bubble_shape.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/expandable_rich_text.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/rich_text_bubble.dart';
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
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/voice_note_player.dart';
import 'package:flutter_chat_app/presentation/widgets/message_status_indicator.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart'
    as domain;
import 'package:flutter_chat_app/shared/domain/entities/message_queue_status.dart';
import 'package:get_it/get_it.dart';

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
  final String currentUserId;

  /// Key assigned to the bubble RepaintBoundary so that
  /// [DesktopMessageHoverWrapper] can measure the bubble's position
  /// and place the hover action bar beside it (Lark-style).
  final GlobalKey? bubbleKey;

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
    this.currentUserId = '',
    this.bubbleKey,
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
    // Rich text rendering: khi có Delta JSON, dùng RichTextBubble
    if (widget.uiState.contentDelta != null &&
        widget.uiState.contentDelta!.trim().isNotEmpty) {
      return RichTextBubble(
        plainText: widget.uiState.content,
        isSender: widget.uiState.isFromCurrentUser,
        deltaJson: widget.uiState.contentDelta,
        textStyle: TextStyle(
          color: textColor,
          fontSize: 16.0,
        ),
      );
    }

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

    // ── Block-level HTML rendering ──────────────────────────
    // Khi message chứa block HTML (h1, h2, ol, ul, li, code, pre, blockquote…)
    // → dùng AppHtmlContent (flutter_html) thay vì TextSpanBuilder (regex inline)
    if (MessageUtils.containsBlockHtml(raw)) {
      return _buildBlockHtmlMessage(
        raw: raw,
        mentionNameById: mentionNameById,
        textColor: textColor,
        theme: theme,
      );
    }

    final normalized = raw.formatChatMessage(mentionNameById: mentionNameById);

    // Emoji-only detection: 1-3 emoji → font size lớn (pattern WhatsApp/Telegram)
    final isEmojiOnly = normalized.isOnlyEmoji;
    final fontSize = isEmojiOnly ? 42.0 : 16.0;

    final spans = TextSpanBuilder.buildSpans(
      rawContent: raw,
      normalizedContent: normalized,
      textStyle: TextStyle(
        color: textColor,
        fontSize: fontSize,
      ),
      linkStyle: TextStyle(
        color: widget.uiState.isFromCurrentUser
            ? textColor
            : theme.colorScheme.primary,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
      mentionStyle: TextStyle(
        // For current user: use onPrimary (white) since bubble is primary (blue)
        // For other users: use primary (blue) for visibility on light background
        color: widget.uiState.isFromCurrentUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.primary,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      highlightedMentionStyle: TextStyle(
        color: AppColors.error,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      mentionNameById: mentionNameById,
      highlightMentionIds: {
        if (widget.currentUserId.trim().isNotEmpty) widget.currentUserId.trim(),
        // "@all" should be highlighted for everyone.
        'all',
      },
      onTapMention: (userId) {
        ChatNavigationHelper.navigateToUserProfile(
          context,
          userId: userId,
          displayName: mentionNameById[userId],
        );
      },
      context: context,
      selectable: PlatformUtils.isDesktopDeviceOrWeb,
    );

    // Emoji-only: render trực tiếp (không cần expand/collapse)
    // Desktop/Web: SelectableText.rich → user drag-to-select + Ctrl+C
    // Mobile: RichText (giữ nguyên) → copy qua long-press action sheet
    if (isEmojiOnly) {
      final emojiTextSpan = TextSpan(
        children: spans,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
        ),
      );
      if (PlatformUtils.isDesktopDeviceOrWeb) {
        // Own message (blue bubble): selection highlight trắng để nhìn thấy
        final isOwn = widget.uiState.isFromCurrentUser;
        Widget selectable = SelectableText.rich(emojiTextSpan);
        if (isOwn) {
          selectable = TextSelectionTheme(
            data: TextSelectionThemeData(
              selectionColor: Colors.white.withValues(alpha: 0.3),
            ),
            child: selectable,
          );
        }
        return selectable;
      }
      return RichText(text: emojiTextSpan);
    }

    // Selection color: own message bubble (primary/blue) cần highlight trắng
    final isDesktop = PlatformUtils.isDesktopDeviceOrWeb;
    final selectionColor = isDesktop && widget.uiState.isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.3)
        : null;

    return ExpandableRichText(
      spans: spans,
      plainText: normalized,
      style: TextStyle(
        color: textColor,
        fontSize: 16.0,
      ),
      selectable: isDesktop,
      selectionColor: selectionColor,
      toggleColor: widget.uiState.isFromCurrentUser ? Colors.white : null,
    );
  }

  // ══════════════════════════════════════════════════════════
  // Block-level HTML message rendering (flutter_html)
  // ══════════════════════════════════════════════════════════

  /// Regex thay thế `[@id]` → `<b>@DisplayName</b>` trong HTML content.
  static final RegExp _mentionBracketRegex = RegExp(r'\[@([^\]]+)\]');

  /// Regex thay thế `@<uuid>` → `<b>@DisplayName</b>` trong HTML content.
  static final RegExp _uuidMentionRegex = RegExp(
    r'@([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
  );

  /// Render message chứa block-level HTML bằng [AppHtmlContent].
  ///
  /// Pre-process:
  /// 1. Thay `[@id]` / `@uuid` mentions → `<b>@DisplayName</b>`
  /// 2. Override `em` style (italic thay vì search-highlight)
  /// 3. Điều chỉnh màu cho own message bubble (text trắng, code background tối hơn)
  Widget _buildBlockHtmlMessage({
    required String raw,
    required Map<String, String> mentionNameById,
    required Color textColor,
    required ThemeData theme,
  }) {
    var htmlContent = raw;

    // 1. Replace [@id] mentions → <b>@DisplayName</b>
    htmlContent = htmlContent.replaceAllMapped(
      _mentionBracketRegex,
      (match) {
        final id = match.group(1) ?? '';
        if (id.isEmpty) return '@';
        final name = mentionNameById[id];
        if (name != null && name.trim().isNotEmpty) {
          return '<b>@${name.trim()}</b>';
        }
        return '@$id';
      },
    );

    // 2. Replace @uuid mentions → <b>@DisplayName</b>
    htmlContent = htmlContent.replaceAllMapped(
      _uuidMentionRegex,
      (match) {
        final id = match.group(1) ?? '';
        final name = mentionNameById[id];
        if (name != null && name.trim().isNotEmpty) {
          return '<b>@${name.trim()}</b>';
        }
        return match.group(0) ?? '@$id';
      },
    );

    // 3. Style overrides cho message context
    // - em: italic (không dùng search-highlight background)
    // - own message: điều chỉnh code/pre background cho bubble xanh
    final isOwn = widget.uiState.isFromCurrentUser;
    final styleOverrides = <String, Style>{
      'em': Style(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      'body': Style(
        color: textColor,
        fontSize: FontSize(16),
      ),
      if (isOwn) ...{
        'code': Style(
          fontFamily: 'monospace',
          backgroundColor: Colors.white.withValues(alpha: 0.15),
        ),
        'pre': Style(
          fontFamily: 'monospace',
          backgroundColor: Colors.white.withValues(alpha: 0.15),
        ),
        'blockquote': Style(
          border: const Border(
            left: BorderSide(color: Colors.white, width: 3),
          ),
          fontStyle: FontStyle.italic,
        ),
        'a': Style(
          color: Colors.white,
          textDecoration: TextDecoration.underline,
        ),
      },
    };

    return AppHtmlContent(
      data: htmlContent,
      baseStyle: TextStyle(
        color: textColor,
        fontSize: 16.0,
      ),
      shrinkWrap: true,
      styleOverrides: styleOverrides,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final messageAvatarSize = AppDimens.getChatMessageAvatarSize(screenWidth);
    final messageAvatarSlotWidth =
        AppDimens.getChatMessageAvatarSlotWidth(screenWidth);

    final messageBubble = RepaintBoundary(
      key: widget.bubbleKey,
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
                    child: _buildAvatar(
                      context,
                      size: messageAvatarSize,
                    ),
                  )
                else if (!isCurrentUser && !widget.isSelectionMode)
                  SizedBox(width: messageAvatarSlotWidth),

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
      final swipeDirection = isCurrentUser
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd;

      messageContent = Dismissible(
        key: ValueKey('swipe_${widget.uiState.id}'),
        direction: swipeDirection,
        confirmDismiss: (_) async {
          widget.onSwipeReply!();
          return false; // Don't actually dismiss
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24.0),
          child: AppIcon.svg(
            AppIcons.reply,
            color: theme.colorScheme.primary,
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24.0),
          child: AppIcon.svg(
            AppIcons.reply,
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
    if (existing.isNotEmpty) {
      if (widget.uiState.contentType != domain.ContentType.video) {
        return existing;
      }

      final videoAttachments = existing
          .where((attachment) => _isLikelyVideoUrl(attachment.url))
          .toList(growable: false);

      if (videoAttachments.isNotEmpty) {
        return videoAttachments;
      }

      return <domain.MessageAttachment>[existing.first];
    }

    final urls = widget.uiState.urls;
    if (urls.isEmpty) return const [];

    final renderableUrls = _selectRenderableUrls(urls);
    if (renderableUrls.isEmpty) return const [];

    final typeName =
        widget.uiState.contentType.toString().split('.').last.toLowerCase();
    final attachmentType = switch (typeName) {
      'image' => 'image',
      'video' => 'video',
      'audio' => 'audio',
      'file' => 'file',
      _ => 'file',
    };

    return renderableUrls
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

  List<String> _selectRenderableUrls(List<String> urls) {
    final normalizedUrls = urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (normalizedUrls.isEmpty) return const [];

    if (widget.uiState.contentType != domain.ContentType.video) {
      return normalizedUrls;
    }

    final videoUrls =
        normalizedUrls.where(_isLikelyVideoUrl).toList(growable: false);
    if (videoUrls.isNotEmpty) {
      return videoUrls;
    }

    final unknownUrls = normalizedUrls
        .where((url) => !_isLikelyImageUrl(url))
        .toList(growable: false);
    if (unknownUrls.isNotEmpty) {
      return unknownUrls;
    }

    return <String>[normalizedUrls.first];
  }

  String? _extractVideoThumbnailUrl(
    List<domain.MessageAttachment> renderableAttachments,
  ) {
    if (widget.uiState.contentType != domain.ContentType.video) return null;

    final allUrls = widget.uiState.urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (allUrls.isEmpty) return null;

    final renderableUrlSet = renderableAttachments
        .map((attachment) => attachment.url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();

    for (final url in allUrls) {
      if (renderableUrlSet.contains(url)) continue;
      if (_isLikelyImageUrl(url)) return url;
    }

    return null;
  }

  static const Set<String> _videoExtensions = {
    '3gp',
    'avi',
    'flv',
    'm3u8',
    'm4v',
    'mkv',
    'mov',
    'mp4',
    'mpeg',
    'mpg',
    'webm',
    'wmv',
  };

  static const Set<String> _imageExtensions = {
    'avif',
    'bmp',
    'gif',
    'heic',
    'heif',
    'jpeg',
    'jpg',
    'png',
    'svg',
    'webp',
  };

  bool _isLikelyVideoUrl(String url) {
    final extension = _extractUrlExtension(url);
    if (extension.isNotEmpty) {
      return _videoExtensions.contains(extension);
    }

    final lower = url.toLowerCase();
    return lower.contains('/video/') ||
        lower.contains('type=video') ||
        lower.contains('content-type=video');
  }

  bool _isLikelyImageUrl(String url) {
    final extension = _extractUrlExtension(url);
    if (extension.isNotEmpty) {
      return _imageExtensions.contains(extension);
    }

    final lower = url.toLowerCase();
    return lower.contains('/image/') ||
        lower.contains('type=image') ||
        lower.contains('content-type=image');
  }

  String _extractUrlExtension(String url) {
    final parsed = Uri.tryParse(url);
    final path = (parsed?.path ?? url).toLowerCase();
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= path.length - 1) return '';
    return path.substring(dotIndex + 1);
  }

  bool _isVoiceNoteAttachment(domain.MessageAttachment attachment) {
    return attachment.type.toLowerCase() == 'voice_note';
  }

  bool _isVoiceNoteFileName(String? fileName) {
    if (fileName == null) return false;
    final normalized = fileName.trim().toLowerCase();
    return normalized.startsWith('voice_note_') && normalized.endsWith('.m4a');
  }

  String _resolveVoiceNoteSourceUrl(domain.MessageAttachment attachment) {
    if (attachment.url.trim().isNotEmpty) {
      return attachment.url.trim();
    }
    final localPath = attachment.localPath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return localPath;
    }
    return '';
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
            AppIcon.svg(
              AppIcons.blocked,
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

    // ── BubbleShape grouping derived from BubblePosition ──
    final bubblePosition = widget.uiState.position;
    final isFirstInGroup = bubblePosition == BubblePosition.first ||
        bubblePosition == BubblePosition.standalone;
    final isLastInGroup = bubblePosition == BubblePosition.last ||
        bubblePosition == BubblePosition.standalone;

    // Use BubbleShape for visual decoration — skip flat color for normal
    // text bubbles. Media-only and file-only messages keep their own colours
    // because BubbleShape is not used for them.
    final useBubbleShape = !hasOnlyMedia && !hasOnlyFiles;

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
            ? AppColors.bubbleOwnText
            : theme.textTheme.bodyMedium?.color ?? Colors.black);

    // Determine if we should use audio/video player instead of media gallery
    final isAudioMessage = contentType == domain.ContentType.audio;
    final isVideoMessage = contentType == domain.ContentType.video;
    final isVoiceNoteMessage = isAudioMessage &&
        renderableAttachments.length == 1 &&
        (_isVoiceNoteAttachment(renderableAttachments.first) ||
            _isVoiceNoteFileName(widget.uiState.fileName));
    final videoThumbnailUrl = _extractVideoThumbnailUrl(renderableAttachments);
    final hasUploadingAttachment =
        renderableAttachments.any((attachment) => attachment.isUploading);
    final useSpecialPlayer = (isAudioMessage || isVideoMessage) &&
        renderableAttachments.length == 1 &&
        !hasUploadingAttachment;

    // Build the inner column first, then conditionally wrap with BubbleShape.
    Widget bubbleContent = ClipRRect(
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
                child: isVoiceNoteMessage
                    ? VoiceNotePlayerWidget(
                        messageId: widget.uiState.id,
                        audioUrl: _resolveVoiceNoteSourceUrl(
                            renderableAttachments.first),
                        isCurrentUser: isFromCurrentUser,
                        isFailed: widget.uiState.isFailed && isFromCurrentUser,
                        onRetry: widget.uiState.isFailed && isFromCurrentUser
                            ? () {
                                context.read<MessageBloc>().add(
                                      RetryVoiceNote(
                                        draftMessageId: widget.uiState.id,
                                      ),
                                    );
                              }
                            : null,
                      )
                    : AudioPlayerWidget(
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
                  thumbnailUrl: videoThumbnailUrl,
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
    );

    // Wrap with BubbleShape for text/mixed bubbles; media-only and file-only
    // keep the legacy Container+BoxDecoration path.
    if (useBubbleShape) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: bubbleMaxWidth(),
        ),
        child: BubbleShape(
          isOwn: isFromCurrentUser,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
          child: bubbleContent,
        ),
      );
    }

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
      child: bubbleContent,
    );
  }

  Widget _buildMessageMetaRow(Color textColor) {
    if (!widget.uiState.showTimestamp && !widget.uiState.isEdited) {
      return const SizedBox.shrink();
    }

    // On own-message gradient, use the dedicated time-text token for
    // better contrast; for others keep the passed-in textColor.
    final metaColor = widget.uiState.isFromCurrentUser
        ? AppColors.bubbleOwnTimeText
        : textColor.withOpacity(0.7);
    final editedColor = widget.uiState.isFromCurrentUser
        ? AppColors.bubbleOwnTimeText
        : textColor.withOpacity(0.5);

    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.uiState.isEdited)
            Text(
              '${context.l10n.edited}  ',
              style: TextStyle(
                color: editedColor,
                fontSize: 10.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (widget.uiState.showTimestamp)
            Text(
              widget.uiState.formattedTime,
              style: TextStyle(
                color: metaColor,
                fontSize: 10.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context, {
    required double size,
  }) {
    final avatarUrl = widget.uiState.senderAvatar;
    final senderName = widget.uiState.senderName.trim();
    final senderId = widget.uiState.senderId;

    return GestureDetector(
      onTap: () => _showAvatarMenu(context, senderId, senderName, avatarUrl),
      child: Padding(
        padding: const EdgeInsets.only(right: AppDimens.chatMessageAvatarGap),
        child: HeroAvatar(
          id: senderId,
          imageUrl: avatarUrl,
          displayName: senderName,
          size: size,
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
              AppIcon.svg(AppIcons.personOutline, size: 20),
              const SizedBox(width: 12),
              Text(l10n.viewProfile),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'message',
          child: Row(
            children: [
              AppIcon.svg(AppIcons.chatBubble, size: 20),
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
          ChatNavigationHelper.navigateToUserProfile(
            context,
            userId: userId,
            displayName: displayName,
            avatarUrl: avatarUrl,
          );
          break;
        case 'message':
          _openDirectMessage(context, userId, displayName);
          break;
      }
    });
  }

  Future<void> _openDirectMessage(
    BuildContext context,
    String userId,
    String displayName,
  ) async {
    final trimmedDisplayName = displayName.trim();
    final chatRepository = GetIt.I<IChatRepository>();
    final result = await chatRepository.createChat(
      name: trimmedDisplayName.isNotEmpty ? trimmedDisplayName : userId,
      participantIds: <String>[userId],
    );

    if (!context.mounted) {
      return;
    }

    await result.fold(
      (_) async {
        await ChatNavigationHelper.navigateToChatDetail(context,
            chatId: userId);
      },
      (chat) async {
        try {
          context.read<ChatBloc>().add(ChatEvent.chatUpdated(chat: chat));
        } catch (_) {
          // MessageItem can be hosted in contexts without a shared ChatBloc.
        }
        await ChatNavigationHelper.navigateToChatDetail(
          context,
          chatId: chat.id,
        );
      },
    );
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
    //
    // progressNotifier — side-channel from MessageBloc so that upload-progress
    // ticks only rebuild the tiny overlay widget, not the entire message list.
    MessageBloc? messageBloc;
    try {
      messageBloc = context.read<MessageBloc>();
    } catch (_) {
      messageBloc = null;
    }

    return MediaGallery(
      attachments: attachments,
      layout: MediaGalleryLayout.grid,
      message: widget.uiState.message,
      chatId: widget.uiState.chatId,
      isFromCurrentUser: isFromCurrentUser,
      isOnPrimaryBackground: isOnPrimaryBackground,
      onEditedImageSend: widget.onEditedImageSend,
      progressNotifier: messageBloc?.uploadProgressNotifier,
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
