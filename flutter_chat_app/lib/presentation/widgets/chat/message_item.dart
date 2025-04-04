import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_chat_app/core/services/media_service.dart';
import 'package:flutter_chat_app/core/utils/date_formatter.dart';

class MessageItem extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isLastInGroup;
  final bool showSenderInfo;

  const MessageItem({
    Key? key,
    required this.message,
    this.onTap,
    this.onLongPress,
    this.isLastInGroup = false,
    this.showSenderInfo = false,
  }) : super(key: key);

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> with AutomaticKeepAliveClientMixin {
  final _mediaService = GetIt.I<MediaService>();
  
  bool _isMediaLoaded = false;
  bool _isMediaError = false;
  late double _mediaAspectRatio = 16 / 9; // Default aspect ratio
  File? _localMediaFile;

  @override
  bool get wantKeepAlive => widget.message.hasMedia;

  @override
  void initState() {
    super.initState();
    _processMedia();
  }
  
  @override
  void didUpdateWidget(MessageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.mediaUrl != widget.message.mediaUrl) {
      _processMedia();
    }
  }

  Future<void> _processMedia() async {
    if (!widget.message.hasMedia) return;

    try {
      // Check if we have local file cached
      final localFile = await _mediaService.getLocalMediaFile(widget.message.id, widget.message.mediaUrl);
      
      if (localFile != null && await localFile.exists()) {
        if (mounted) {
          setState(() {
            _localMediaFile = localFile;
            _isMediaLoaded = true;
            _isMediaError = false;
          });
        }
        
        // Get media dimensions if it's an image or video
        if (widget.message.isImage || widget.message.isVideo) {
          final dimensions = await _mediaService.getMediaDimensions(localFile);
          if (dimensions != null && mounted) {
            setState(() {
              _mediaAspectRatio = dimensions.width / dimensions.height;
            });
          }
        }
      } else {
        // We need to download the file
        _mediaService.downloadMedia(
          widget.message.id,
          widget.message.mediaUrl,
          onProgress: (progress) {
            // Could show download progress
          },
          onSuccess: (file) {
            if (mounted) {
              setState(() {
                _localMediaFile = file;
                _isMediaLoaded = true;
                _isMediaError = false;
              });
              
              // Get media dimensions if it's an image or video
              _mediaService.getMediaDimensions(file).then((dimensions) {
                if (dimensions != null && mounted) {
                  setState(() {
                    _mediaAspectRatio = dimensions.width / dimensions.height;
                  });
                }
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isMediaError = true;
              });
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMediaError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final isCurrentUser = widget.message.isFromCurrentUser;
    
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: IntrinsicWidth(
          child: Material(
            color: isCurrentUser 
                ? theme.colorScheme.primary.withOpacity(0.8)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show sender name for group chats
                  if (widget.showSenderInfo && !isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 0),
                      child: Text(
                        widget.message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isCurrentUser 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  
                  // Media content
                  if (widget.message.hasMedia)
                    _buildMediaContent(),
                  
                  // Text content
                  if (widget.message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        widget.message.content,
                        style: TextStyle(
                          color: isCurrentUser 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  
                  // Time and status indicators
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormatter.formatMessageTime(widget.message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrentUser 
                                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          _buildStatusIndicator(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMediaContent() {
    if (_isMediaError) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 40),
        ),
      );
    }
    
    if (!_isMediaLoaded) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: 250,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      );
    }
    
    // Handle different media types
    if (widget.message.isImage) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: AspectRatio(
            aspectRatio: _mediaAspectRatio,
            child: _localMediaFile != null
                ? Image.file(
                    _localMediaFile!,
                    fit: BoxFit.cover,
                    cacheWidth: 500, // Limit memory usage
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (frame == null) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        );
                      }
                      return child;
                    },
                  )
                : CachedNetworkImage(
                    imageUrl: widget.message.mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
          ),
        ),
      );
    } else if (widget.message.isVideo) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: AspectRatio(
                aspectRatio: _mediaAspectRatio,
                child: Container(
                  color: Colors.black,
                  child: _localMediaFile != null
                      ? Image.file(
                          _localMediaFile!, // This should be a thumbnail
                          fit: BoxFit.cover,
                          cacheWidth: 500,
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white.withOpacity(0.8),
                size: 48,
              ),
            ),
          ),
        ],
      );
    } else if (widget.message.isAudio) {
      return Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.audiotrack),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Audio Message', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow),
          ],
        ),
      );
    } else {
      // File attachment
      return Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.attach_file),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message.fileName ?? 'Attachment',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.download),
          ],
        ),
      );
    }
  }
  
  Widget _buildStatusIndicator() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 12, color: Colors.white70);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.white70);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 12, color: Colors.blue.shade300);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
      default:
        return const SizedBox(width: 12, height: 12);
    }
  }
} 