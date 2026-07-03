import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Displays message delivery status icons in chat list preview (WhatsApp-style).
///
/// Shows:
/// - Single grey check (✓) for sent messages
/// - Double blue checks (✓✓) for read messages
/// - Clock icon for pending/sending messages
/// - Error icon for failed messages
///
/// Only displayed for messages sent by the current user.
///
/// **Usage:**
/// ```dart
/// MessageStatusIcon(
///   status: MessageStatus.read,
///   size: 14.0,
/// )
/// ```
class MessageStatusIcon extends StatelessWidget {
  /// The message delivery status to display.
  final MessageDeliveryStatus status;

  /// Size of the status icon.
  final double size;

  /// Creates a [MessageStatusIcon].
  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageDeliveryStatus.pending:
        return AppIcon.svg(
          AppIcons.statusPending,
          size: size,
          color: AppColors.messageSentStatus,
        );
      case MessageDeliveryStatus.sending:
        return AppIcon.svg(
          AppIcons.statusSending,
          size: size,
          color: AppColors.messageSentStatus,
        );
      case MessageDeliveryStatus.sent:
        return AppIcon.svg(
          AppIcons.statusSent,
          size: size,
          color: AppColors.messageSentStatus,
        );
      case MessageDeliveryStatus.read:
        return AppIcon.svg(
          AppIcons.statusRead,
          size: size,
          color: AppColors.messageReadStatus,
        );
      case MessageDeliveryStatus.failed:
        return AppIcon.svg(
          AppIcons.statusFailed,
          size: size,
          color: AppColors.error,
        );
    }
  }
}

/// Message delivery status for display purposes.
///
/// Maps to the domain `MessageStatus` enum but only includes
/// statuses relevant for UI display in chat list preview.
enum MessageDeliveryStatus {
  /// Message queued locally, not yet sent
  pending,

  /// Message being sent to server
  sending,

  /// Message delivered to server (single check)
  sent,

  /// Message read by recipient (double check blue)
  read,

  /// Message failed to send
  failed,
}
