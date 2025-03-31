import 'dart:async';

/// Tiện ích giúp trì hoãn thực hiện một hành động
/// cho đến khi không có yêu cầu mới trong một khoảng thời gian nhất định
class Debouncer {
  /// Khoảng thời gian trì hoãn (mili giây)
  final int milliseconds;
  
  /// Timer để theo dõi thời gian
  Timer? _timer;
  
  /// Constructor với thời gian trì hoãn mặc định 300ms
  Debouncer({this.milliseconds = 300});
  
  /// Chạy một hành động với cơ chế debounce
  void run(void Function() action) {
    // Huỷ timer cũ nếu có
    _timer?.cancel();
    
    // Tạo timer mới
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
  
  /// Huỷ timer hiện tại
  void cancel() {
    _timer?.cancel();
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
} 