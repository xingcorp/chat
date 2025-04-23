import 'dart:convert';
import 'dart:math';

/// Mixin cung cấp các tiện ích cho các dịch vụ realtime
mixin RealtimeUtilsMixin {
  /// Tạo một ID phiên ngẫu nhiên
  String generateSessionId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
  
  /// Tạo một ID tin nhắn ngẫu nhiên
  String generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomStr = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return '$timestamp-$randomStr';
  }
  
  /// Chuyển đổi dữ liệu thô thành Map
  Map<String, dynamic>? parseJsonData(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is String) {
        return json.decode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      // Trả về null nếu có lỗi
    }
    
    return null;
  }
} 