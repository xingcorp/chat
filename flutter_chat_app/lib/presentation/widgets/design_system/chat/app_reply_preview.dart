import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/chat_enums.dart';

/// **APP REPLY PREVIEW**
///
/// Preview component for displaying the message being replied to.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Compact display with author and content snippet
/// - Tap to scroll to original message
/// - Content type indicators (text, image, video, file, etc.)
/// - Text truncation for long messages
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based interaction
///
/// **Usage**:
/// ```dart
/// AppReplyPreview(
///   author: 'John Doe',
///   message: 'This is the original message being replied to',
///   messageType: MessageType.text,
///   onTap: () => _scrollToOriginalMessage(),
/// )
///
/// // Image reply
/// AppReplyPreview(
///   author: 'Jane Smith',
///   message: 'Photo',
///   messageType: MessageType.image,
///   thumbnailUrl: 'https://example.com/thumb.jpg',
///   onTap: () => _scrollToOriginalMessage(),
/// )
/// ```
class AppReplyPreview extends BaseStatelessWidget {
  /// Creates a reply preview.
  const AppReplyPreview({
    super.key,
    required this.author,
    required this.message,
    this.messageType = MessageType.text,
    this.thumbnailUrl,
    this.maxLines = 2,
    this.showCloseButton = false,
    this.onTap,
    this.onClose,
  });

  /// Author of the original message
  final String author;

  /// Content of the original message (or description for media)
  final String message;

  /// Type of the original message
  final MessageType messageType;

  /// Thumbnail URL for media messages
  final String? thumbnailUrl;

  /// Maximum lines to display for message text
  final int maxLines;

  /// Whether to show close button (for reply composition)
  final bool showCloseButton;

  /// Callback when preview is tapped
  final VoidCallback? onTap;

  /// Callback when close button is tapped
  final VoidCallback? onClose;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Pre-calculate colors for performance
    final backgroundColor = isDark
        ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
        : theme.colorScheme.surfaceVariant.withOpacity(0.5);

    final borderColor = isDark
        ? theme.colorScheme.primary.withOpacity(0.5)
        : theme.colorScheme.primary;
        
    final textColor = theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.87);
    final iconColor = theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.54);

    return RepaintBoundary(
      child: Semantics(
        label: l10n.replyingTo(author),
        button: onTap != null,
        child: Material(
          color: theme.colorScheme.surface.withOpacity(0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingSmall),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border(
                  left: BorderSide(
                    color: borderColor,
                    width: AppDimens.dividerThick,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Thumbnail for media messages
                  if (_shouldShowThumbnail()) ...[
                    _buildThumbnail(context, theme),
                    const SizedBox(width: AppDimens.spaceSmall),
                  ],

                  // Content type icon
                  _buildContentTypeIcon(iconColor),
                  const SizedBox(width: AppDimens.spaceSmall),

                  // Author and message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Author name
                        Text(
                          author,
                          style: AppTextStyles.labelMedium(context).copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimens.spaceXSmall),

                        // Message content
                        Text(
                          _getDisplayMessage(l10n),
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: textColor,
                          ),
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  if (showCloseButton) ...[
                    const SizedBox(width: AppDimens.spaceSmall),
                    IconButton(
                      icon: const Icon(Icons.close, size: AppDimens.iconSmall),
                      onPressed: onClose,
                      padding: const EdgeInsets.all(0),
                      constraints: const BoxConstraints(
                        minWidth: AppDimens.touchTargetMin / 2,
                        minHeight: AppDimens.touchTargetMin / 2,
                      ),
                      tooltip: l10n.cancelReply,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Whether to show thumbnail for this message type
  bool _shouldShowThumbnail() {
    return thumbnailUrl != null &&
        (messageType == MessageType.image ||
            messageType == MessageType.video);
  }

  /// Build thumbnail widget with caching
  Widget _buildThumbnail(BuildContext context, ThemeData theme) {
    return Container(
      width: AppDimens.avatarMedium,
      height: AppDimens.avatarMedium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusXSmall),
        color: theme.colorScheme.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusXSmall),
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 100, // Resize for memory efficiency
          maxWidthDiskCache: 200,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: AppDimens.iconSmall,
              height: AppDimens.iconSmall,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Icon(
            _getContentTypeIconData(),
            size: AppDimens.iconSmall,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Build content type icon
  Widget _buildContentTypeIcon(Color iconColor) {
    return Icon(
      _getContentTypeIconData(),
      size: AppDimens.iconSmall,
      color: iconColor,
    );
  }

  /// Get icon data for message type
  IconData _getContentTypeIconData() {
    switch (messageType) {
      case MessageType.text:
        return Icons.chat_bubble_outline;
      case MessageType.image:
        return Icons.image_outlined;
      case MessageType.video:
        return Icons.videocam_outlined;
      case MessageType.audio:
        return Icons.mic_outlined;
      case MessageType.file:
        return Icons.insert_drive_file_outlined;
      case MessageType.location:
        return Icons.location_on_outlined;
      case MessageType.contact:
        return Icons.person_outline;
      case MessageType.system:
        return Icons.info_outline;
    }
  }

  /// Get display message based on message type
  String _getDisplayMessage(AppLocalizations l10n) {
    switch (messageType) {
      case MessageType.text:
        return message;
      case MessageType.image:
        return message.isEmpty ? l10n.photo : message;
      case MessageType.video:
        return message.isEmpty ? l10n.video : message;
      case MessageType.audio:
        return message.isEmpty ? l10n.voiceMessage : message;
      case MessageType.file:
        return message.isEmpty ? l10n.file : message;
      case MessageType.location:
        return message.isEmpty ? l10n.location : message;
      case MessageType.contact:
        return message.isEmpty ? l10n.contact : message;
      case MessageType.system:
        return message;
    }
  }
}
