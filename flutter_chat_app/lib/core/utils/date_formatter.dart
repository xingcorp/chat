import 'package:intl/intl.dart';

/// Utility class for formatting dates consistently across the app
class DateFormatter {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd MMM');
  static final DateFormat _fullDateFormat = DateFormat('dd MMM yyyy');
  
  /// Format a message timestamp
  /// Shows time for today's messages, date for older ones
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return _timeFormat.format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${_timeFormat.format(dateTime)}';
    } else if (now.difference(dateTime).inDays < 7) {
      // Format weekday for messages within a week
      final weekdayFormat = DateFormat('EEEE');
      return '${weekdayFormat.format(dateTime)}, ${_timeFormat.format(dateTime)}';
    } else if (dateTime.year == now.year) {
      // Same year, show date without year
      return _dateFormat.format(dateTime);
    } else {
      // Different year, show full date
      return _fullDateFormat.format(dateTime);
    }
  }
  
  /// Format chat last message time for the chat list
  /// Shows time for today, "Yesterday" for yesterday, weekday for this week,
  /// and date for older messages
  static String formatChatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return _timeFormat.format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // Format weekday for messages within a week
      final weekdayFormat = DateFormat('EEEE');
      return weekdayFormat.format(dateTime);
    } else if (dateTime.year == now.year) {
      // Same year, show date without year
      return _dateFormat.format(dateTime);
    } else {
      // Different year, show full date
      return _fullDateFormat.format(dateTime);
    }
  }
  
  /// Format date for message group headers
  static String formatMessageGroupDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // Format weekday for messages within a week
      final weekdayFormat = DateFormat('EEEE');
      return weekdayFormat.format(dateTime);
    } else {
      // Show full date for older messages
      return _fullDateFormat.format(dateTime);
    }
  }
  
  /// Format time range (e.g., for voice messages)
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  /// Format relative time (e.g., "5 minutes ago", "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
} 