/// Buffer socket events trong khi background fetch đang chạy.
/// Sau khi merge hoàn tất, apply buffered events lên state mới.
///
/// Generic type T cho phép buffer bất kỳ event type nào
/// mà không cần import message_bloc.dart (tránh circular dependency).
class SocketEventBuffer<T> {
  final List<T> _buffer = [];
  bool _isBuffering = false;

  /// Bắt đầu buffering (khi background fetch bắt đầu)
  void startBuffering() {
    _isBuffering = true;
    _buffer.clear();
  }

  /// Thêm event vào buffer (nếu đang buffering).
  /// Returns true nếu event đã được buffer, false nếu cần xử lý ngay.
  bool bufferIfNeeded(T event) {
    if (!_isBuffering) return false;
    _buffer.add(event);
    return true;
  }

  /// Dừng buffering và trả về events đã buffer theo thứ tự nhận.
  List<T> stopBuffering() {
    _isBuffering = false;
    final events = List<T>.from(_buffer);
    _buffer.clear();
    return events;
  }

  /// Kiểm tra đang buffering không
  bool get isBuffering => _isBuffering;
}
