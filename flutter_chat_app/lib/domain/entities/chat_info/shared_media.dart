import 'package:equatable/equatable.dart';

/// Loại media được chia sẻ trong chat
enum SharedMediaType {
  /// Ảnh
  photo,

  /// Video
  video,

  /// File tài liệu
  file,

  /// Link URL
  link,
}

/// Entity cho media được chia sẻ trong chat
/// Domain layer - Pure Dart, NO Flutter dependencies
class SharedMedia extends Equatable {
  /// ID của media
  final String id;

  /// Loại media
  final SharedMediaType type;

  /// URL của media
  final String url;

  /// URL thumbnail (optional, cho video và images)
  final String? thumbnailUrl;

  /// Tên file (cho file type)
  final String? fileName;

  /// Kích thước file (bytes)
  final int? fileSize;

  /// Thời gian tạo
  final DateTime createdAt;

  /// ID người gửi
  final String senderId;

  /// Tên người gửi
  final String senderName;

  const SharedMedia({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
  });

  /// Copy with method
  SharedMedia copyWith({
    String? id,
    SharedMediaType? type,
    String? url,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    String? senderId,
    String? senderName,
  }) {
    return SharedMedia(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        url,
        thumbnailUrl,
        fileName,
        fileSize,
        createdAt,
        senderId,
        senderName,
      ];

  @override
  String toString() {
    return 'SharedMedia(id: $id, type: $type, fileName: $fileName)';
  }
}
