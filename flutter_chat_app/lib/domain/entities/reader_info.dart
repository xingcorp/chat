import 'package:equatable/equatable.dart';

/// Thông tin reader để hiển thị avatar trong read receipt
/// Domain layer - Pure Dart, NO Flutter dependencies
class ReaderInfo extends Equatable {
  /// ID của reader
  final String userId;

  /// Tên đầy đủ (nullable nếu không tìm thấy trong members)
  final String? fullName;

  /// URL avatar (nullable nếu không tìm thấy trong members)
  final String? avatarUrl;

  const ReaderInfo({
    required this.userId,
    this.fullName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [userId, fullName, avatarUrl];

  @override
  String toString() {
    return 'ReaderInfo(userId: $userId, fullName: $fullName)';
  }
}
