import 'package:flutter/material.dart';

/// Class định nghĩa các màu sắc trong ứng dụng
class AppColors {
  /// Màu chính
  static const Color primary = Color(0xFF2196F3);
  
  /// Màu chủ đề thứ cấp
  static const Color secondary = Color(0xFFFF9800);
  
  /// Màu nền
  static const Color background = Color(0xFFF5F5F5);
  
  /// Màu nền thẻ
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// Màu văn bản chính
  static const Color textPrimary = Color(0xFF212121);
  
  /// Màu văn bản thứ cấp
  static const Color textSecondary = Color(0xFF757575);
  
  /// Màu biểu tượng
  static const Color icon = Color(0xFF616161);
  
  /// Màu bóng
  static const Color shadow = Color(0x1A000000);
  
  /// Màu viền
  static const Color border = Color(0xFFE0E0E0);
  
  /// Màu xanh lá
  static const Color success = Color(0xFF4CAF50);
  
  /// Màu lỗi
  static const Color error = Color(0xFFF44336);
  
  /// Màu cảnh báo
  static const Color warning = Color(0xFFFFC107);
  
  /// Màu thông tin
  static const Color info = Color(0xFF2196F3);
  
  /// Màu nền của input chat
  static const Color chatInputBackground = Color(0xFFF5F5F5);
  
  /// Màu nền của tin nhắn gửi đi
  static const Color sentMessageBackground = Color(0xFFE3F2FD);
  
  /// Màu văn bản của tin nhắn gửi đi
  static const Color sentMessageText = Color(0xFF000000);
  
  /// Màu nền của tin nhắn nhận được
  static const Color receivedMessageBackground = Color(0xFFFFFFFF);
  
  /// Màu văn bản của tin nhắn nhận được
  static const Color receivedMessageText = Color(0xFF000000);
  
  /// Màu xám nhạt
  static const Color greyLight = Color(0xFFE0E0E0);
  
  /// Màu xám đậm
  static const Color greyDark = Color(0xFF9E9E9E);
  
  /// Màu nền chính
  static const Color primaryBackground = Color(0xFFE3F2FD);
  
  /// Màu nền thứ cấp
  static const Color secondaryBackground = Color(0xFFFFF3E0);

  /// Lấy màu nền cho tin nhắn gửi đi, dựa vào chế độ tối/sáng
  static Color getSentMessageBackgroundColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF0D47A1) : sentMessageBackground;
  }

  /// Lấy màu nền cho tin nhắn nhận được, dựa vào chế độ tối/sáng
  static Color getReceivedMessageBackgroundColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF424242) : receivedMessageBackground;
  }
} 