import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:timeago/timeago.dart' as timeago;

// TODO: Refactor to use MediaBloc instead of direct repository calls
// import 'package:flutter_chat_app/core/services/media_service.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart' as domain;
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/presentation/widgets/message_status_indicator.dart';

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
                if (isCurrentUser)
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
  
  Widget _buildMessageBubble(BuildContext context, bool isFromCurrentUser) {
    final ThemeData theme = Theme.of(context);
    final messageAlignment = isFromCurrentUser 
        ? CrossAxisAlignment.end 
        : CrossAxisAlignment.start;
    
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
            if (widget.message.attachments.isNotEmpty)
              _buildAttachmentPreviews(context),
            
            // Message content
            if (widget.message.content.isNotEmpty || widget.message.attachments.isEmpty)
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
                      child: Text(
                        widget.message.content,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16.0,
                        ),
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
    // Implementation of _buildAvatar method
    // This method should return a widget representing the avatar
    throw UnimplementedError();
  }
  
  Widget _buildReplyPreview(BuildContext context, bool isFromCurrentUser) {
    // Implementation of _buildReplyPreview method
    // This method should return a widget representing the reply preview
    throw UnimplementedError();
  }
  
  Widget _buildAttachmentPreviews(BuildContext context) {
    // Implementation of _buildAttachmentPreviews method
    // This method should return a widget representing the attachment previews
    throw UnimplementedError();
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
    // Implementation of _getBubbleBorderRadius method
    // This method should return the appropriate BorderRadius for the message bubble
    throw UnimplementedError();
  }
}