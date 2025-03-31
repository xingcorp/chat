import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Service xử lý định dạng thời gian trong ứng dụng chat
class DateFormatterService {
  /// Định dạng ngày để hiển thị trong nhóm tin nhắn
  /// Ví dụ: 'Hôm nay', 'Hôm qua', '15/05/2023'
  static String formatDateForGrouping(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isAtSameMomentAs(today)) {
      return 'Hôm nay';
    } else if (dateOnly.isAtSameMomentAs(yesterday)) {
      return 'Hôm qua';
    } else if (date.year == now.year) {
      return DateFormat('dd/MM').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
  
  /// Định dạng thời gian để hiển thị trong tin nhắn
  /// Ví dụ: '15:30'
  static String formatTimeForMessage(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  /// Định dạng đầy đủ ngày giờ
  /// Ví dụ: '15:30 15/05/2023'
  static String formatFullDateTime(DateTime date) {
    return '${DateFormat('HH:mm').format(date)} ${DateFormat('dd/MM/yyyy').format(date)}';
  }
  
  /// Định dạng thời gian tương đối
  /// Ví dụ: 'Vừa xong', '5 phút trước', '2 giờ trước'
  static String formatRelativeTime(DateTime date, {DateTime? comparedTo}) {
    final now = comparedTo ?? DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inSeconds < 30) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 1) {
      return 'Vài giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else {
      return '${(difference.inDays / 365).floor()} năm trước';
    }
  }
  
  /// Định dạng thời gian truy cập lần cuối
  /// Ví dụ: 'Hoạt động 5 phút trước', 'Đang hoạt động'
  static String formatLastSeen(DateTime? lastSeen, {bool isOnline = false}) {
    if (isOnline) {
      return 'Đang hoạt động';
    }
    
    if (lastSeen == null) {
      return '';
    }
    
    return 'Hoạt động ${formatRelativeTime(lastSeen)}';
  }
  
  /// Định dạng khoảng thời gian (như thời lượng âm thanh, video)
  /// Ví dụ: '00:45', '1:23:45'
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
  
  /// Lấy thông tin thời gian của tin nhắn
  /// Trả về thời gian hoặc ngày tùy thuộc vào ngày nhắn tin
  static String getMessageTimeInfo(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isAtSameMomentAs(today)) {
      return formatTimeForMessage(date);
    } else if (dateOnly.isAtSameMomentAs(yesterday)) {
      return 'Hôm qua, ${formatTimeForMessage(date)}';
    } else {
      return formatFullDateTime(date);
    }
  }
} 