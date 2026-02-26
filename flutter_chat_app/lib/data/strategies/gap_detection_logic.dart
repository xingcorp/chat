/// Logic phát hiện gap (tin nhắn bị miss) trong delta sync.
class GapDetectionLogic {
  /// Kiểm tra xem delta sync có đầy đủ không.
  ///
  /// Returns true nếu cần full refresh (có gap).
  ///
  /// Heuristic: nếu delta trả về >= pageSize → có thể còn tin nhắn bị miss.
  static bool hasGap({
    required int deltaCount,
    required int pageSize,
  }) {
    return deltaCount >= pageSize;
  }
}
