import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/chat_enums.dart';

/// **APP MESSAGE BUBBLE**
///
/// Message bubble component supporting multiple content types (text, image, video, audio, file).
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Multiple content types (text, image, video, audio, file, location, contact, system)
/// - Sender/receiver alignment (left/right/center)
/// - Tail indicator for message direction
/// - Long-press for context menu
/// - Media thumbnail with loading states
/// - Reply preview integration
/// - Reaction display
/// - Timestamp and status indicators
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based interaction
///
/// **Usage**:
/// ```dart
/// // Text message
/// AppMessageBubble.text(
///   message: 'Hello, how are you?',
///   isSender: false,
///   timestamp: DateTime.now(),
///   status: MessageStatus.read,
///   onLongPress: () => _showContextMenu(),
/// )
///
/// // Image message
/// AppMessageBubble.image(
///   imageUrl: 'https://example.com/image.jpg',
///   isSender: true,
///   timestamp: DateTime.now(),
///   onTap: () => _openGallery(),
/// )
///
/// // Message with reply
/// AppMessageBubble.text(
///   message: 'Thanks for the info!',
///   isSender: true,
///   replyToMessage: 'Original message text',
///   replyToAuthor: 'John Doe',
/// )
/// ```

class AppMessageBubble extends BaseStatelessWidget {
  /// Creates a message bubble.
  const AppMessageBubble({
    super.key,
    required this.messageType,
    required this.isSender,
    this.message,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.locationName,
    this.contactName,
    this.timestamp,
    this.status,
    this.replyToMessage,
    this.replyToAuthor,
    this.reactions = const [],
    this.showTail = true,
    this.size = MessageBubbleSize.normal,
    this.onTap,
    this.onLongPress,
    this.onReplyTap,
    this.onReactionTap,
  });

  /// Creates a text message bubble.
  factory AppMessageBubble.text({
    Key? key,
    required String message,
    required bool isSender,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyToMessage,
    String? replyToAuthor,
    List<String> reactions = const [],
    bool showTail = true,
    MessageBubbleSize size = MessageBubbleSize.normal,
    VoidCallback? onLongPress,
    VoidCallback? onReplyTap,
    ValueChanged<String>? onReactionTap,
  }) {
    return AppMessageBubble(
      key: key,
      messageType: MessageType.text,
      isSender: isSender,
      message: message,
      timestamp: timestamp,
      status: status,
      replyToMessage: replyToMessage,
      replyToAuthor: replyToAuthor,
      reactions: reactions,
      showTail: showTail,
      size: size,
      onLongPress: onLongPress,
      onReplyTap: onReplyTap,
      onReactionTap: onReactionTap,
    );
  }

  /// Creates an image message bubble.
  factory AppMessageBubble.image({
    Key? key,
    required String imageUrl,
    required bool isSender,
    String? message,
    DateTime? timestamp,
    MessageStatus? status,
    List<String> reactions = const [],
    bool showTail = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ValueChanged<String>? onReactionTap,
  }) {
    return AppMessageBubble(
      key: key,
      messageType: MessageType.image,
      isSender: isSender,
      imageUrl: imageUrl,
      message: message,
      timestamp: timestamp,
      status: status,
      reactions: reactions,
      showTail: showTail,
      onTap: onTap,
      onLongPress: onLongPress,
      onReactionTap: onReactionTap,
    );
  }

  /// Creates a video message bubble.
  factory AppMessageBubble.video({
    Key? key,
    required String videoUrl,
    required bool isSender,
    String? message,
    DateTime? timestamp,
    MessageStatus? status,
    List<String> reactions = const [],
    bool showTail = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ValueChanged<String>? onReactionTap,
  }) {
    return AppMessageBubble(
      key: key,
      messageType: MessageType.video,
      isSender: isSender,
      videoUrl: videoUrl,
      message: message,
      timestamp: timestamp,
      status: status,
      reactions: reactions,
      showTail: showTail,
      onTap: onTap,
      onLongPress: onLongPress,
      onReactionTap: onReactionTap,
    );
  }

  /// Creates an audio message bubble.
  factory AppMessageBubble.audio({
    Key? key,
    required String audioUrl,
    required bool isSender,
    DateTime? timestamp,
    MessageStatus? status,
    List<String> reactions = const [],
    bool showTail = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ValueChanged<String>? onReactionTap,
  }) {
    return AppMessageBubble(
      key: key,
      messageType: MessageType.audio,
      isSender: isSender,
      audioUrl: audioUrl,
      timestamp: timestamp,
      status: status,
      reactions: reactions,
      showTail: showTail,
      onTap: onTap,
      onLongPress: onLongPress,
      onReactionTap: onReactionTap,
    );
  }

  /// Creates a file message bubble.
  factory AppMessageBubble.file({
    Key? key,
    required String fileUrl,
    required String fileName,
    required bool isSender,
    String? fileSize,
    DateTime? timestamp,
    MessageStatus? status,
    List<String> reactions = const [],
    bool showTail = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ValueChanged<String>? onReactionTap,
  }) {
    return AppMessageBubble(
      key: key,
      messageType: MessageType.file,
      isSender: isSender,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      timestamp: timestamp,
      status: status,
      reactions: reactions,
      showTail: showTail,
      onTap: onTap,
      onLongPress: onLongPress,
      onReactionTap: onReactionTap,
    );
  }

  /// Message content type
  final MessageType messageType;

  /// Whether this is a sender message (true) or receiver message (false)
  final bool isSender;

  /// Text message content
  final String? message;

  /// Image URL for image messages
  final String? imageUrl;

  /// Video URL for video messages
  final String? videoUrl;

  /// Audio URL for audio messages
  final String? audioUrl;

  /// File URL for file messages
  final String? fileUrl;

  /// File name for file messages
  final String? fileName;

  /// File size for file messages
  final String? fileSize;

  /// Location name for location messages
  final String? locationName;

  /// Contact name for contact messages
  final String? contactName;

  /// Message timestamp
  final DateTime? timestamp;

  /// Message delivery/read status
  final MessageStatus? status;

  /// Reply preview - original message text
  final String? replyToMessage;

  /// Reply preview - original message author
  final String? replyToAuthor;

  /// List of reaction emojis
  final List<String> reactions;

  /// Whether to show message tail
  final bool showTail;

  /// Message bubble size variant
  final MessageBubbleSize size;

  /// Callback when message is tapped
  final VoidCallback? onTap;

  /// Callback when message is long-pressed
  final VoidCallback? onLongPress;

  /// Callback when reply preview is tapped
  final VoidCallback? onReplyTap;

  /// Callback when a reaction is tapped
  final ValueChanged<String>? onReactionTap;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine alignment
    final alignment = isSender ? MessageAlignment.right : MessageAlignment.left;

    // Get bubble colors
    final bubbleColor = _getBubbleColor(theme, isDark);
    final textColor = _getTextColor(theme, isDark);

    // Get padding based on size
    final padding = _getPadding(size);

    return Semantics(
      label: _getSemanticLabel(l10n),
      button: onTap != null || onLongPress != null,
      child: Align(
        alignment: _getAlignment(alignment),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Column(
              crossAxisAlignment: isSender
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply preview
                if (replyToMessage != null) ...[
                  _buildReplyPreview(context, theme, l10n, isDark),
                  const SizedBox(height: AppDimens.spaceXSmall),
                ],

                // Message bubble
                Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: _getBorderRadius(alignment),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Message content
                      _buildMessageContent(context, theme, l10n, textColor),

                      // Timestamp and status
                      if (timestamp != null || status != null) ...[
                        const SizedBox(height: AppDimens.spaceXSmall),
                        _buildFooter(context, theme, l10n, textColor),
                      ],
                    ],
                  ),
                ),

                // Reactions
                if (reactions.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.spaceXSmall),
                  _buildReactions(context, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the message content based on type
  Widget _buildMessageContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color textColor,
  ) {
    switch (messageType) {
      case MessageType.text:
        return _buildTextContent(context, theme, textColor);
      case MessageType.image:
        return _buildImageContent(context, theme, l10n, textColor);
      case MessageType.video:
        return _buildVideoContent(context, theme, l10n, textColor);
      case MessageType.audio:
        return _buildAudioContent(context, theme, l10n);
      case MessageType.file:
        return _buildFileContent(context, theme, l10n, textColor);
      case MessageType.location:
        return _buildLocationContent(context, theme, l10n, textColor);
      case MessageType.contact:
        return _buildContactContent(context, theme, l10n, textColor);
      case MessageType.system:
        return _buildSystemContent(context, theme, textColor);
    }
  }

  /// Builds text message content
  Widget _buildTextContent(BuildContext context, ThemeData theme, Color textColor) {
    return Text(
      message ?? '',
      style: AppTextStyles.bodyMedium.copyWith(color: textColor),
    );
  }

  /// Builds image message content
  Widget _buildImageContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          child: Image.network(
            imageUrl ?? '',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: theme.colorScheme.errorContainer,
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onErrorContainer,
                  size: AppDimens.iconLarge,
                ),
              );
            },
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.spaceSmall),
          Text(
            message!,
            style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          ),
        ],
      ],
    );
  }

  /// Builds video message content
  Widget _buildVideoContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: Container(
                width: 200,
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.videocam,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: AppDimens.iconXLarge,
                ),
              ),
            ),
            Container(
              width: AppDimens.iconXLarge,
              height: AppDimens.iconXLarge,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: theme.colorScheme.onPrimary,
                size: AppDimens.iconLarge,
              ),
            ),
          ],
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.spaceSmall),
          Text(
            message!,
            style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          ),
        ],
      ],
    );
  }

  /// Builds audio message content
  Widget _buildAudioContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_filled,
          color: theme.colorScheme.primary,
          size: AppDimens.iconLarge,
        ),
        const SizedBox(width: AppDimens.spaceSmall),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 32,
                constraints: const BoxConstraints(minWidth: 150),
                child: CustomPaint(
                  painter: _WaveformPainter(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spaceXSmall),
              Text(
                '0:00',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds file message content
  Widget _buildFileContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color textColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppDimens.iconXLarge,
          height: AppDimens.iconXLarge,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Icon(
            Icons.insert_drive_file,
            color: theme.colorScheme.onPrimaryContainer,
            size: AppDimens.iconMedium,
          ),
        ),
        const SizedBox(width: AppDimens.spaceSmall),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fileName ?? l10n.file,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (fileSize != null) ...[
                const SizedBox(height: AppDimens.spaceXSmall),
                Text(
                  fileSize!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Builds location message content
  Widget _buildLocationContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color textColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          color: theme.colorScheme.error,
          size: AppDimens.iconLarge,
        ),
        const SizedBox(width: AppDimens.spaceSmall),
        Flexible(
          child: Text(
            locationName ?? l10n.location,
            style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }

  /// Builds contact message content
  Widget _buildContactContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color textColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: AppDimens.iconMedium,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            color: theme.colorScheme.onPrimaryContainer,
            size: AppDimens.iconMedium,
          ),
        ),
        const SizedBox(width: AppDimens.spaceSmall),
        Flexible(
          child: Text(
            contactName ?? l10n.contact,
            style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }

  /// Builds system message content
  Widget _buildSystemContent(BuildContext context, ThemeData theme, Color textColor) {
    return Text(
      message ?? '',
      style: AppTextStyles.bodySmall.copyWith(
        color: textColor,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds reply preview
  Widget _buildReplyPreview(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onReplyTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingSmall),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              replyToAuthor ?? l10n.you,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.spaceXSmall),
            Text(
              replyToMessage ?? '',
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds message footer with timestamp and status
  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color textColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timestamp != null) ...[
          Text(
            _formatTimestamp(timestamp!),
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
        if (status != null && isSender) ...[
          const SizedBox(width: AppDimens.spaceXSmall),
          _buildStatusIcon(theme, status!),
        ],
      ],
    );
  }

  /// Builds status icon
  Widget _buildStatusIcon(ThemeData theme, MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = theme.colorScheme.onSurfaceVariant;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = theme.colorScheme.onSurfaceVariant;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = theme.colorScheme.onSurfaceVariant;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = theme.colorScheme.primary;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
        break;
      case MessageStatus.pending:
        icon = Icons.schedule;
        color = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  /// Builds reactions row
  Widget _buildReactions(BuildContext context, ThemeData theme) {
    return Wrap(
      spacing: AppDimens.spaceXSmall,
      children: reactions.map((reaction) {
        return GestureDetector(
          onTap: () => onReactionTap?.call(reaction),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingSmall,
              vertical: AppDimens.paddingXSmall,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              reaction,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Gets bubble color based on sender and theme
  Color _getBubbleColor(ThemeData theme, bool isDark) {
    if (messageType == MessageType.system) {
      return theme.colorScheme.surfaceContainerHighest;
    }
    return isSender
        ? theme.colorScheme.primaryContainer
        : (isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerHighest);
  }

  /// Gets text color based on sender and theme
  Color _getTextColor(ThemeData theme, bool isDark) {
    if (messageType == MessageType.system) {
      return theme.colorScheme.onSurfaceVariant;
    }
    return isSender
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
  }

  /// Gets padding based on size
  EdgeInsets _getPadding(MessageBubbleSize size) {
    switch (size) {
      case MessageBubbleSize.compact:
        return const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSmall,
          vertical: AppDimens.paddingXSmall,
        );
      case MessageBubbleSize.normal:
        return const EdgeInsets.all(AppDimens.paddingMedium);
      case MessageBubbleSize.comfortable:
        return const EdgeInsets.all(AppDimens.paddingLarge);
    }
  }

  /// Gets border radius based on alignment
  BorderRadius _getBorderRadius(MessageAlignment alignment) {
    const radius = Radius.circular(AppDimens.radiusMedium);
    const smallRadius = Radius.circular(AppDimens.radiusXSmall);

    if (!showTail) {
      return BorderRadius.all(radius);
    }

    switch (alignment) {
      case MessageAlignment.left:
        return const BorderRadius.only(
          topLeft: smallRadius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        );
      case MessageAlignment.right:
        return const BorderRadius.only(
          topLeft: radius,
          topRight: smallRadius,
          bottomLeft: radius,
          bottomRight: radius,
        );
      case MessageAlignment.center:
        return BorderRadius.all(radius);
    }
  }

  /// Gets alignment based on message alignment
  Alignment _getAlignment(MessageAlignment alignment) {
    switch (alignment) {
      case MessageAlignment.left:
        return Alignment.centerLeft;
      case MessageAlignment.right:
        return Alignment.centerRight;
      case MessageAlignment.center:
        return Alignment.center;
    }
  }

  /// Gets semantic label for accessibility
  String _getSemanticLabel(AppLocalizations l10n) {
    final typeLabel = _getMessageTypeLabel(l10n);
    final senderLabel = isSender ? l10n.you : '';
    final timeLabel = timestamp != null ? _formatTimestamp(timestamp!) : '';

    return '$typeLabel ${senderLabel.isNotEmpty ? "from $senderLabel" : ""} $timeLabel';
  }

  /// Gets message type label for accessibility
  String _getMessageTypeLabel(AppLocalizations l10n) {
    switch (messageType) {
      case MessageType.text:
        return l10n.textMessage;
      case MessageType.image:
        return l10n.imageMessage;
      case MessageType.video:
        return l10n.videoMessage;
      case MessageType.audio:
        return l10n.audioMessage;
      case MessageType.file:
        return l10n.fileMessage;
      case MessageType.location:
        return l10n.locationMessage;
      case MessageType.contact:
        return l10n.contactMessage;
      case MessageType.system:
        return l10n.systemMessage;
    }
  }

  /// Formats timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Custom painter for audio waveform
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw simple waveform bars
    const barCount = 30;
    final barWidth = size.width / barCount;

    for (var i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      // Random heights for demo (in real app, use actual audio data)
      final height = size.height * (0.3 + (i % 3) * 0.2);
      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => false;
}
