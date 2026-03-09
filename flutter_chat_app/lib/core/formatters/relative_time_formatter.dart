import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:intl/intl.dart';

/// Formats timestamps for chat list using absolute time display.
///
/// Follows industry standards (WhatsApp, Telegram, Slack):
/// - < 1 minute: "Just now"
/// - Today: "10:30" (HH:mm)
/// - Yesterday: "Yesterday"
/// - Within 7 days: Short weekday name ("Mon", "Tue", "Thứ 2", "Thứ 3")
/// - Older (same year): "15/03"
/// - Older (different year): "15/03/2025"
///
/// ## Design Decisions
/// - **Absolute time eliminates stale timestamp problem**: Unlike relative
///   time ("5 minutes ago") which becomes incorrect without periodic rebuilds,
///   absolute timestamps remain accurate indefinitely.
/// - No timer or periodic rebuild needed — the displayed value stays correct.
/// - Compact format for space efficiency in chat lists.
/// - Gracefully handles null timestamps.
///
/// ## Usage
/// ```dart
/// final timeText = RelativeTimeFormatter.format(context, message.createdAt);
/// // "10:30" or "Yesterday" or "Mon" or "15/03"
/// ```
class RelativeTimeFormatter {
  const RelativeTimeFormatter._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Formats a timestamp for chat list display.
  ///
  /// Returns:
  /// - "Just now" if < 1 minute ago
  /// - "HH:mm" if today
  /// - "Yesterday" if yesterday
  /// - Short weekday name if within 7 days
  /// - "dd/MM" if older (same year)
  /// - "dd/MM/yyyy" if older (different year)
  /// - Empty string if timestamp is null
  static String format(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = now.difference(dateTime);

    // Just now (< 1 minute) — only relative display, transitions to HH:mm
    if (difference.inSeconds < 60) {
      return context.l10n.justNow;
    }

    // Today → show time "10:30"
    if (messageDate == today) {
      return _timeFormat.format(dateTime);
    }

    // Yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) {
      return context.l10n.yesterday;
    }

    // Within 7 days → short weekday name
    final daysDifference = today.difference(messageDate).inDays;
    if (daysDifference < 7) {
      return _getShortWeekday(context, dateTime.weekday);
    }

    // Older → absolute date
    return _formatAbsoluteDate(dateTime, now);
  }

  /// Returns localized short weekday name.
  ///
  /// Uses [DateTime.monday] (1) through [DateTime.sunday] (7).
  static String _getShortWeekday(BuildContext context, int weekday) {
    final l10n = context.l10n;
    switch (weekday) {
      case DateTime.monday:
        return l10n.weekdayMon;
      case DateTime.tuesday:
        return l10n.weekdayTue;
      case DateTime.wednesday:
        return l10n.weekdayWed;
      case DateTime.thursday:
        return l10n.weekdayThu;
      case DateTime.friday:
        return l10n.weekdayFri;
      case DateTime.saturday:
        return l10n.weekdaySat;
      case DateTime.sunday:
        return l10n.weekdaySun;
      default:
        return '';
    }
  }

  /// Formats absolute date for messages older than 7 days.
  static String _formatAbsoluteDate(DateTime dateTime, DateTime now) {
    if (dateTime.year == now.year) {
      return DateFormat('dd/MM').format(dateTime);
    }
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}
