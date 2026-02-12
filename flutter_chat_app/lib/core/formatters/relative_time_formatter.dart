import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/core/services/date_formatter_service.dart';

/// Formats timestamps as relative time strings for chat interfaces.
///
/// Follows industry standards (Facebook Messenger, WhatsApp, Zalo):
/// - < 1 minute: "now"
/// - < 60 minutes: "5m"
/// - < 24 hours: "2h"
/// - < 7 days: "3d"
/// - >= 7 days: Absolute date format
///
/// ## Design Decisions
/// - Compact format for space efficiency in chat lists
/// - Consistent with user mental models for time
/// - Gracefully handles null timestamps
///
/// ## Usage
/// ```dart
/// final timeText = RelativeTimeFormatter.format(context, message.createdAt);
/// // "2m" or "3h" or "Yesterday"
/// ```
class RelativeTimeFormatter {
  const RelativeTimeFormatter._();

  /// Formats a timestamp as relative time.
  ///
  /// Returns:
  /// - "now" if < 1 minute ago
  /// - "Xm" if < 60 minutes ago
  /// - "Xh" if < 24 hours ago
  /// - "Xd" if < 7 days ago
  /// - Absolute date (via DateFormatterService) if >= 7 days
  /// - Empty string if timestamp is null
  static String format(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Just now (< 1 minute)
    if (difference.inSeconds < 60) {
      return context.l10n.justNow;
    }

    // Minutes ago (< 60 minutes)
    if (difference.inMinutes < 60) {
      return context.l10n.minutesAgo(difference.inMinutes);
    }

    // Hours ago (< 24 hours)
    if (difference.inHours < 24) {
      return context.l10n.hoursAgo(difference.inHours);
    }

    // Days ago (< 7 days)
    if (difference.inDays < 7) {
      return context.l10n.daysAgo(difference.inDays);
    }

    // For older messages, show absolute date using existing service
    return _formatAbsoluteDate(dateTime);
  }

  /// Formats absolute date for messages older than 7 days.
  ///
  /// Uses existing DateFormatterService for consistency across the app.
  static String _formatAbsoluteDate(DateTime dateTime) {
    return DateFormatterService.formatTimeForMessage(dateTime);
  }
}
