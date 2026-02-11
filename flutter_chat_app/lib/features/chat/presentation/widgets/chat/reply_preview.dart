import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/core/localization/l10n_helper.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';

/// Widget hiển thị reply preview phía trên message bubble
///
/// Khớp với:
/// - Angular: replyMessage render với sender name + content preview
/// - stream_chat_flutter: quoted_message_widget.dart patterns
///
/// Features:
/// - Hiển thị sender name + avatar (optional)
/// - Preview content theo type: TEXT, IMAGE, VIDEO, AUDIO, FILE, LOCATION
/// - Thumbnail cho IMAGE/VIDEO
/// - Icon + label cho AUDIO, FILE
/// - Tap → scroll đến tin nhắn gốc (callback)
/// - Styling theo isFromCurrentUser
class ReplyPreview extends StatelessWidget {
  /// Reply message data
  final ReplyMessagePreview replyMessage;

  /// Tin nhắn hiện tại có phải của currentUser không
  final bool isFromCurrentUser;

  /// Callback khi tap vào reply preview để scroll đến tin gốc
  final VoidCallback? onTap;

  /// Có hiển thị thumbnail/icon không (compact mode)
  final bool showThumbnail;

  const ReplyPreview({
    Key? key,
    required this.replyMessage,
    this.isFromCurrentUser = false,
    this.onTap,
    this.showThumbnail = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Background color: lighter variant của bubble color
    final bgColor = isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.15)
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    // Accent color: primary color
    final accentColor = theme.colorScheme.primary;

    // Text color
    final textColor = isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.9)
        : theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(
              color: accentColor,
              width: 3.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Icon (optional)
            if (showThumbnail) ...[
              _buildPreviewMedia(context, theme),
              const SizedBox(width: 8.0),
            ],

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name
                  Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 14.0,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          replyMessage.senderName,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),

                  // Preview text
                  Text(
                    _getPreviewText(l10n),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: textColor.withValues(alpha: 0.8),
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

  /// Get preview text theo content type
  String _getPreviewText(AppLocalizations l10n) {
    // Nếu có previewText từ transformer, dùng luôn
    if (replyMessage.previewText.isNotEmpty) {
      return replyMessage.previewText;
    }

    // Fallback theo contentType
    final l10nHelper = L10nHelper.current;
    switch (replyMessage.contentType) {
      case ContentType.image:
        return l10nHelper.replyPreviewImage;
      case ContentType.video:
        return l10nHelper.replyPreviewVideo;
      case ContentType.audio:
        return l10nHelper.replyPreviewAudio;
      case ContentType.file:
        return l10nHelper.replyPreviewFile('');
      case ContentType.location:
        return l10nHelper.replyPreviewLocation;
      case ContentType.link:
        return l10nHelper.replyPreviewLink;
      case ContentType.event:
        return l10nHelper.replyPreviewSystemEvent;
      case ContentType.text:
      default:
        return l10n.noMessages;
    }
  }

  /// Build thumbnail hoặc icon preview
  Widget _buildPreviewMedia(BuildContext context, ThemeData theme) {
    const size = 40.0;
    final iconColor = theme.iconTheme.color?.withValues(alpha: 0.7);

    switch (replyMessage.contentType) {
      case ContentType.image:
        // Image thumbnail
        if (replyMessage.previewUrl != null &&
            replyMessage.previewUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: AppImage.network(
              imageUrl: replyMessage.previewUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
        return _buildIconContainer(
          theme,
          Icons.image_outlined,
          size,
          iconColor,
        );

      case ContentType.video:
        // Video thumbnail với play icon overlay
        if (replyMessage.previewUrl != null &&
            replyMessage.previewUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Stack(
              children: [
                AppImage.network(
                  imageUrl: replyMessage.previewUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
                // Play icon overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildIconContainer(
          theme,
          Icons.videocam_outlined,
          size,
          iconColor,
        );

      case ContentType.audio:
        return _buildIconContainer(
          theme,
          Icons.mic_outlined,
          size,
          iconColor,
        );

      case ContentType.file:
        return _buildIconContainer(
          theme,
          Icons.insert_drive_file_outlined,
          size,
          iconColor,
        );

      case ContentType.location:
        return _buildIconContainer(
          theme,
          Icons.location_on_outlined,
          size,
          iconColor,
        );

      case ContentType.link:
        return _buildIconContainer(
          theme,
          Icons.link,
          size,
          iconColor,
        );

      default:
        return _buildIconContainer(
          theme,
          Icons.message_outlined,
          size,
          iconColor,
        );
    }
  }

  /// Helper: build icon container
  Widget _buildIconContainer(
    ThemeData theme,
    IconData icon,
    double size,
    Color? iconColor,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Icon(
        icon,
        size: 20,
        color: iconColor,
      ),
    );
  }
}

/// Widget nhỏ gọn cho reply input bar
///
/// Hiển thị khi user đang reply một tin nhắn (phía trên input field)
class ReplyInputBar extends StatelessWidget {
  final ReplyMessagePreview replyMessage;
  final VoidCallback? onCancel;

  const ReplyInputBar({
    Key? key,
    required this.replyMessage,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1.0,
          ),
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 3.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16.0,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.replyMessage} ${replyMessage.senderName}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  replyMessage.previewText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20.0),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
