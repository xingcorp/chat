import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';

/// Widget hiển thị forward indicator phía trên message bubble
///
/// Thiết kế theo pattern của ReplyPreview, tương tự Zalo/Telegram/Messenger:
/// - Icon forward + label "Đã chuyển tiếp"
/// - Tên người gửi tin nhắn gốc
/// - Preview content theo type: TEXT, IMAGE, VIDEO, AUDIO, FILE
/// - Thumbnail cho IMAGE/VIDEO
/// - Styling theo isFromCurrentUser
///
/// Features:
/// - Hiển thị sender name + avatar (optional)
/// - Preview content theo type: TEXT, IMAGE, VIDEO, AUDIO, FILE, LOCATION
/// - Thumbnail cho IMAGE/VIDEO
/// - Icon + label cho AUDIO, FILE
/// - Styling theo isFromCurrentUser
class ForwardPreview extends StatelessWidget {
  /// Forward message data
  final ForwardMessageInfo forwardInfo;

  /// Tin nhắn hiện tại có phải của currentUser không
  final bool isFromCurrentUser;

  /// Whether the parent bubble is painted with primary color.
  /// For media-only messages, the bubble can be transparent.
  final bool isOnPrimaryBackground;

  /// Callback khi tap vào forward preview (optional)
  final VoidCallback? onTap;

  /// Có hiển thị thumbnail/icon không (compact mode)
  final bool showThumbnail;

  const ForwardPreview({
    Key? key,
    required this.forwardInfo,
    this.isFromCurrentUser = false,
    this.isOnPrimaryBackground = false,
    this.onTap,
    this.showThumbnail = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final isPrimaryBubble = isFromCurrentUser && isOnPrimaryBackground;

    // Background color: lighter variant của bubble color
    final bgColor = isPrimaryBubble
        ? Colors.white.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);

    // Accent color: sử dụng màu khác với reply để phân biệt
    final accentColor = isPrimaryBubble
        ? Colors.white.withValues(alpha: 0.85)
        : theme.colorScheme.secondary;

    // Text color
    final textColor = isPrimaryBubble
        ? Colors.white.withValues(alpha: 0.9)
        : theme.textTheme.bodyMedium?.color ?? Colors.black87;

    // Forward icon color - sử dụng màu secondary để phân biệt với reply
    final forwardIconColor = isPrimaryBubble
        ? Colors.white.withValues(alpha: 0.9)
        : theme.colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(
              color: forwardIconColor,
              width: 3.0,
            ),
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Icon (optional)
            if (showThumbnail && forwardInfo.contentType != null) ...[
              _buildPreviewMedia(context, theme),
              const SizedBox(width: 8.0),
            ],

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Forward label + sender name
                  Row(
                    children: [
                      AppIcon.svg(
                        AppIcons.forward,
                        size: 14.0,
                        color: forwardIconColor,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          _getForwardLabel(l10n),
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: forwardIconColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Sender name (nếu có)
                  if (forwardInfo.originalSenderName != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      forwardInfo.originalSenderName!,
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Preview text (nếu có)
                  if (forwardInfo.previewText != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      forwardInfo.previewText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get forward label
  String _getForwardLabel(AppLocalizations l10n) {
    // Nếu có tên người gửi, hiển thị "Đã chuyển tiếp" + tên
    if (forwardInfo.originalSenderName != null) {
      return '${l10n.forwardedMessage} · ${forwardInfo.originalSenderName}';
    }
    // Nếu không, chỉ hiển thị "Tin nhắn được chuyển tiếp"
    return l10n.forwardedMessage;
  }

  /// Build thumbnail hoặc icon preview
  Widget _buildPreviewMedia(BuildContext context, ThemeData theme) {
    const size = 40.0;
    final iconColor = theme.iconTheme.color?.withValues(alpha: 0.7);

    final contentType = forwardInfo.contentType;
    if (contentType == null) return const SizedBox.shrink();

    switch (contentType) {
      case ContentType.image:
        // Image thumbnail
        if (forwardInfo.previewUrl != null &&
            forwardInfo.previewUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: AppImage.network(
              imageUrl: forwardInfo.previewUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
        return _buildIconContainer(
          theme,
          AppIcons.photo,
          size,
          iconColor,
        );

      case ContentType.video:
        // Video thumbnail với play icon overlay
        if (forwardInfo.previewUrl != null &&
            forwardInfo.previewUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Stack(
              children: [
                AppImage.network(
                  imageUrl: forwardInfo.previewUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
                // Play icon overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: AppIcon.svg(
                        AppIcons.playCircle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildIconContainer(
          theme,
          AppIcons.video,
          size,
          iconColor,
        );

      case ContentType.audio:
        return _buildIconContainer(
          theme,
          AppIcons.mic,
          size,
          iconColor,
        );

      case ContentType.file:
        return _buildIconContainer(
          theme,
          AppIcons.file,
          size,
          iconColor,
        );

      case ContentType.location:
        return _buildIconContainer(
          theme,
          AppIcons.location,
          size,
          iconColor,
        );

      case ContentType.link:
        return _buildIconContainer(
          theme,
          AppIcons.formatLink,
          size,
          iconColor,
        );

      case ContentType.sticker:
        return _buildIconContainer(
          theme,
          AppIcons.emoji,
          size,
          iconColor,
        );

      case ContentType.event:
        return _buildIconContainer(
          theme,
          AppIcons.about,
          size,
          iconColor,
        );

      case ContentType.text:
        // Text message - hiển thị icon message
        return _buildIconContainer(
          theme,
          AppIcons.chatBubble,
          size,
          iconColor,
        );
    }
  }

  /// Helper: build icon container
  Widget _buildIconContainer(
    ThemeData theme,
    String icon,
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
      child: Center(
        child: AppIcon.svg(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}
