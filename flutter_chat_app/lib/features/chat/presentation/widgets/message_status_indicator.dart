import 'package:flutter/material.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Displays message sending status with appropriate icon and color.
///
/// Visual feedback for message delivery status in chat interfaces:
/// - Sending: clock icon (grey) - message being sent
/// - Sent: single check (grey) - message reached server
/// - Delivered: double check (grey) - message reached recipient device
/// - Read: double check (primary) - message opened by recipient
/// - Failed: error icon (red) - send failed, retry needed
///
/// ## Features
/// - Intuitive icon mapping following industry standards
/// - Color coding for status recognition
/// - Null-safe with empty fallback
/// - Configurable size for different contexts
///
/// ## Usage
/// ```dart
/// // In chat list tile
/// MessageStatusIndicator(
///   status: message.status,
///   size: 14,
/// )
///
/// // In message bubble
/// MessageStatusIndicator(
///   status: message.status,
///   size: 16,
/// )
/// ```
class MessageStatusIndicator extends StatelessWidget {
  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.size = 16.0,
  });

  /// Message delivery status.
  ///
  /// If null, widget renders as empty (no status shown).
  final MessageStatus? status;

  /// Icon size in logical pixels.
  ///
  /// Default: 16.0
  /// Recommended: 14.0 for chat list, 16.0 for message bubbles
  final double size;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    final iconData = _getIconData(status!);
    final color = _getColor(status!);

    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }

  /// Maps status to appropriate Material icon.
  IconData _getIconData(MessageStatus status) {
    return switch (status) {
      MessageStatus.pending => Icons.schedule,
      MessageStatus.sending => Icons.access_time,
      MessageStatus.sent => Icons.check,
      MessageStatus.delivered => Icons.done_all,
      MessageStatus.read => Icons.done_all,
      MessageStatus.failed => Icons.error_outline,
    };
  }

  /// Maps status to appropriate color.
  Color _getColor(MessageStatus status) {
    return switch (status) {
      MessageStatus.pending => AppColors.textSecondary,
      MessageStatus.read => AppColors.primary,
      MessageStatus.failed => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }
}
