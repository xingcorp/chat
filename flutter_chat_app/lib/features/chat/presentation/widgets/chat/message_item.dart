import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:timeago/timeago.dart' as timeago;

// TODO: Refactor to use MediaBloc instead of direct repository calls
// import 'package:flutter_chat_app/core/services/media_service.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart' as domain;
import 'package:flutter_chat_app/shared/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/presentation/widgets/message_status_indicator.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/media_preview.dart';

class MessageItem extends StatefulWidget {
  final domain.ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isLastInGroup;
  final bool showSenderInfo;
  final bool highlightMessage;

  const MessageItem({
    Key? key,
    required this.message,
    this.onTap,
    this.onLongPress,
    this.isLastInGroup = false,
    this.showSenderInfo = false,
    this.highlightMessage = false,
  }) : super(key: key);

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> with AutomaticKeepAliveClientMixin {
  // TODO: Refactor to use MediaBloc for media loading
  // final _mediaService = GetIt.I<MediaService>();
  
  bool _isMediaLoaded = false;
  bool _isMediaError = false;
  late double _mediaAspectRatio = 16 / 9; // Default aspect ratio
  File? _localMediaFile;

  @override
  bool get wantKeepAlive => widget.message.hasMedia;

  @override
  void initState() {
    super.initState();
    // TODO: Implement media loading with MediaBloc
    // _processMedia();
  }

  Widget _buildMentionableMessageText({
    required ThemeData theme,
    required Color textColor,
  }) {
    final mentionNameById = <String, String>{
      for (final m in widget.message.mentionTo)
        if (m.id.isNotEmpty && m.name.trim().isNotEmpty) m.id: m.name.trim(),
    };

    final raw = widget.message.content;
    final normalized = raw.formatChatMessage(mentionNameById: mentionNameById);

    // We still need to keep userId mapping for navigation, so we parse on the
    // original raw content.
    final spans = _parseMentionSpans(
      rawContent: raw,
      normalizedContent: normalized,
      textStyle: TextStyle(
        color: textColor,
        fontSize: 16.0,
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
    // If backend already formatted to plain text without tokens, fallback.
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
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.mediaUrl != widget.message.mediaUrl) {
      // TODO: Implement media loading with MediaBloc
      // _processMedia();
    }
  }

  // TODO: Refactor to use MediaBloc instead of direct MediaService calls
  /*
  Future<void> _processMedia() async {
    if (!widget.message.hasMedia) return;

    try {
      // Use MediaRepository through MediaBloc
      // ...
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMediaError = true;
        });
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final isCurrentUser = widget.message.isFromCurrentUser;
    
    final messageBubble = RepaintBoundary(
      child: _buildMessageBubble(context, isCurrentUser),
    );
    
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          bottom: widget.isLastInGroup ? 12.0 : 4.0,
          top: widget.showSenderInfo ? 8.0 : 0.0,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender info for group chats
            if (widget.showSenderInfo && !isCurrentUser)
              Padding(
                padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: RepaintBoundary(
                  child: Text(
                    widget.message.senderName,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            
            // Message row with avatar for non-current user
            Row(
              mainAxisAlignment: isCurrentUser 
                  ? MainAxisAlignment.end 
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for messages from others
                if (!isCurrentUser && widget.isLastInGroup)
                  RepaintBoundary(
                    child: _buildAvatar(context),
                  )
                else if (!isCurrentUser)
                  const SizedBox(width: 36.0),
                
                // Message bubble
                Flexible(
                  child: messageBubble,
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
                      messageId: widget.message.id,
                      messageQueueService: GetIt.instance<MessageQueueService>(),
                      status: _mapMessageStatusToQueueStatus(widget.message.status),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  List<domain.MessageAttachment> _getRenderableAttachments() {
    final existing = widget.message.attachments;
    if (existing.isNotEmpty) return existing;

    final urls = widget.message.urls;
    if (urls.isEmpty) return const [];

    final typeName = widget.message.contentType.toString().split('.').last.toLowerCase();
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
            id: '${widget.message.id}-$u',
            type: attachmentType,
            url: u,
            size: 0,
            name: widget.message.fileName ?? '',
          ),
        )
        .toList(growable: false);
  }

  Widget _buildMessageBubble(BuildContext context, bool isFromCurrentUser) {
    final ThemeData theme = Theme.of(context);
    final messageAlignment = isFromCurrentUser 
        ? CrossAxisAlignment.end 
        : CrossAxisAlignment.start;

    final renderableAttachments = _getRenderableAttachments();
    
    // Different color for current user vs others
    final bubbleColor = isFromCurrentUser 
        ? theme.colorScheme.primary.withOpacity(0.8) 
        : theme.cardColor;
    
    final textColor = isFromCurrentUser 
        ? theme.colorScheme.onPrimary 
        : theme.textTheme.bodyMedium?.color ?? Colors.black;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: widget.highlightMessage 
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
            // Reply indicator if this is a reply
            // TODO: Add replyTo field to ChatMessage entity
            // if (widget.message.replyTo != null)
            //   _buildReplyPreview(context, isFromCurrentUser),
            
            // Attachment previews if any
            if (renderableAttachments.isNotEmpty)
              _buildAttachmentPreviews(context, attachments: renderableAttachments),
            
            // Message content
            if (widget.message.content.isNotEmpty || renderableAttachments.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
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
                    
                    const SizedBox(height: 4.0),
                    
                    // Timestamp
                    RepaintBoundary(
                      child: Text(
                        timeago.format(widget.message.createdAt, locale: 'en_short'),
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = widget.message.sender.avatar;
    final senderName = widget.message.sender.name.trim();

    final initials = senderName.isNotEmpty
        ? senderName.characters.first.toUpperCase()
        : '?';

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 4.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }
  
  Widget _buildReplyPreview(BuildContext context, bool isFromCurrentUser) {
    // Implementation of _buildReplyPreview method
    // This method should return a widget representing the reply preview
    throw UnimplementedError();
  }
  
  Widget _buildAttachmentPreviews(
    BuildContext context, {
    required List<domain.MessageAttachment> attachments,
  }) {
    final theme = Theme.of(context);

    Widget buildFileTile(domain.MessageAttachment attachment) {
      final name = attachment.name.trim().isNotEmpty ? attachment.name.trim() : 'File';
      return InkWell(
        onTap: () {
          // For web/desktop, opening the URL is handled by browser.
          // For mobile, higher-level handler can be added later.
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.download,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      );
    }

    final previewWidgets = <Widget>[];
    for (final a in attachments) {
      final type = a.type.toLowerCase();
      final url = a.url;
      if (url.trim().isEmpty) {
        previewWidgets.add(buildFileTile(a));
        continue;
      }

      if (type == 'image') {
        previewWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: MediaPreview(
              mediaUrl: url,
              isImage: true,
              width: 220,
              height: 160,
              borderRadius: 12,
            ),
          ),
        );
        continue;
      }

      if (type == 'video') {
        previewWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: MediaPreview(
              mediaUrl: url,
              isImage: false,
              width: 240,
              height: 160,
              borderRadius: 12,
            ),
          ),
        );
        continue;
      }

      previewWidgets.add(buildFileTile(a));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: previewWidgets,
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
        return MessageQueueStatus.delivered; // Map read to delivered for now
      case domain.MessageStatus.failed:
        return MessageQueueStatus.failed;
    }
  }

  BorderRadius _getBubbleBorderRadius(bool isFromCurrentUser) {
    const radius = Radius.circular(16.0);
    const smallRadius = Radius.circular(4.0);

    if (isFromCurrentUser) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: smallRadius,
      );
    }

    return const BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: smallRadius,
      bottomRight: radius,
    );
  }
}