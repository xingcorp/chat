import 'package:flutter/foundation.dart';

/// Loại tệp đính kèm
enum AttachmentType {
  /// Hình ảnh
  image,
  
  /// Âm thanh
  audio,
  
  /// Video
  video,
  
  /// Tệp tài liệu
  document,
  
  /// Vị trí
  location,
  
  /// Liên hệ
  contact,
  
  /// Loại không xác định
  other
}

/// Trạng thái tệp đính kèm
enum AttachmentStatus {
  /// Đang chuẩn bị tải lên
  preparing,
  
  /// Đang chờ tải lên
  pending,
  
  /// Đang tải lên
  uploading,
  
  /// Đã tải lên thành công
  uploaded,
  
  /// Lỗi khi tải lên
  error
}

/// Lớp đại diện cho tệp đính kèm trong tin nhắn
class Attachment {
  /// ID duy nhất cho tệp đính kèm 
  final String id;
  
  /// Tên tệp
  final String name;
  
  /// Đường dẫn cục bộ đến tệp
  final String? localPath;
  
  /// URL sau khi tải lên
  final String? url;
  
  /// Loại tệp đính kèm
  final AttachmentType type;
  
  /// MIME type của tệp
  final String mimeType;
  
  /// Kích thước tệp (bytes)
  final int size;
  
  /// Chiều rộng (nếu là ảnh/video)
  final int? width;
  
  /// Chiều cao (nếu là ảnh/video)
  final int? height;
  
  /// Thời lượng (nếu là audio/video) tính bằng milliseconds
  final int? duration;
  
  /// Thumbnail URL (nếu có)
  final String? thumbnailUrl;
  
  /// Metadata bổ sung
  final Map<String, dynamic>? metadata;
  
  /// Trạng thái hiện tại của tệp đính kèm
  final AttachmentStatus status;
  
  /// Tiến độ tải lên (0-100)
  final int uploadProgress;
  
  /// Thông báo lỗi nếu có
  final String? errorMessage;

  /// Constructor
  Attachment({
    required this.id,
    required this.name,
    this.localPath,
    this.url,
    required this.type,
    required this.mimeType,
    required this.size,
    this.width,
    this.height,
    this.duration,
    this.thumbnailUrl,
    this.metadata,
    this.status = AttachmentStatus.pending,
    this.uploadProgress = 0,
    this.errorMessage,
  });

  /// Tạo bản sao với các giá trị đã cập nhật
  Attachment copyWith({
    String? id,
    String? name,
    String? localPath,
    String? url,
    AttachmentType? type,
    String? mimeType,
    int? size,
    int? width,
    int? height,
    int? duration,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    AttachmentStatus? status,
    int? uploadProgress,
    String? errorMessage,
  }) {
    return Attachment(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      url: url ?? this.url,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  /// Tạo đối tượng từ JSON
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      name: json['name'] as String,
      localPath: json['localPath'] as String?,
      url: json['url'] as String?,
      type: _parseAttachmentType(json['type'] as String),
      mimeType: json['mimeType'] as String,
      size: json['size'] as int,
      width: json['width'] as int?,
      height: json['height'] as int?,
      duration: json['duration'] as int?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: _parseAttachmentStatus(json['status'] as String?),
      uploadProgress: json['uploadProgress'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
  
  /// Chuyển đối tượng thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localPath': localPath,
      'url': url,
      'type': type.toString().split('.').last,
      'mimeType': mimeType,
      'size': size,
      'width': width,
      'height': height,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'status': status.toString().split('.').last,
      'uploadProgress': uploadProgress,
      'errorMessage': errorMessage,
    };
  }
  
  /// Phân tích loại tệp đính kèm từ chuỗi
  static AttachmentType _parseAttachmentType(String typeStr) {
    try {
      return AttachmentType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => AttachmentType.other,
      );
    } catch (_) {
      return AttachmentType.other;
    }
  }
  
  /// Phân tích trạng thái tệp đính kèm từ chuỗi
  static AttachmentStatus _parseAttachmentStatus(String? statusStr) {
    if (statusStr == null) return AttachmentStatus.pending;
    
    try {
      return AttachmentStatus.values.firstWhere(
        (status) => status.toString().split('.').last.toLowerCase() == statusStr.toLowerCase(),
        orElse: () => AttachmentStatus.pending,
      );
    } catch (_) {
      return AttachmentStatus.pending;
    }
  }
  
  /// Kiểm tra xem tệp đính kèm đã hoàn thành chưa
  bool get isComplete => status == AttachmentStatus.uploaded && url != null;
  
  /// Kiểm tra xem tệp đính kèm có lỗi không
  bool get hasError => status == AttachmentStatus.error;
  
  /// Kiểm tra xem tệp đính kèm có phải là hình ảnh không
  bool get isImage => type == AttachmentType.image;
  
  /// Kiểm tra xem tệp đính kèm có phải là video không
  bool get isVideo => type == AttachmentType.video;
  
  /// Kiểm tra xem tệp đính kèm có phải là âm thanh không 
  bool get isAudio => type == AttachmentType.audio;
  
  /// Kiểm tra xem tệp đính kèm có phải là tài liệu không
  bool get isDocument => type == AttachmentType.document;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Attachment &&
      other.id == id &&
      other.name == name &&
      other.localPath == localPath &&
      other.url == url &&
      other.type == type &&
      other.mimeType == mimeType &&
      other.size == size &&
      other.width == width &&
      other.height == height &&
      other.duration == duration &&
      other.thumbnailUrl == thumbnailUrl &&
      mapEquals(other.metadata, metadata) &&
      other.status == status &&
      other.uploadProgress == uploadProgress &&
      other.errorMessage == errorMessage;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      localPath.hashCode ^
      url.hashCode ^
      type.hashCode ^
      mimeType.hashCode ^
      size.hashCode ^
      width.hashCode ^
      height.hashCode ^
      duration.hashCode ^
      thumbnailUrl.hashCode ^
      (metadata != null ? Object.hashAll(metadata!.entries.map((e) => '${e.key}:${e.value}')) : 0) ^
      status.hashCode ^
      uploadProgress.hashCode ^
      errorMessage.hashCode;
  }
} 