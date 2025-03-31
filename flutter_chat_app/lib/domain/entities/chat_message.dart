import 'package:flutter_chat_app/domain/entities/user.dart';

/// Định nghĩa các loại nội dung của tin nhắn
enum ContentType {
  /// Tin nhắn văn bản
  text,
  
  /// Tin nhắn chỉ có phương tiện (ảnh, video...)
  media,
  
  /// Tin nhắn kết hợp văn bản và phương tiện
  mixed,
  
  /// Tin nhắn chia sẻ vị trí
  location,
  
  /// Tin nhắn chia sẻ liên hệ
  contact,
  
  /// Tin nhắn ghi âm
  voice,
  
  /// Tin nhắn là tệp đính kèm
  file,
  
  /// Tin nhắn hệ thống (ví dụ: "X đã thêm Y vào nhóm")
  system,
}

/// Đối tượng mô tả tệp đính kèm
class Attachment {
  /// ID duy nhất của tệp đính kèm
  final String id;
  
  /// Tên tệp
  final String fileName;
  
  /// Kích thước tệp (byte)
  final int size;
  
  /// Loại MIME
  final String mimeType;
  
  /// URL tải tệp
  final String url;
  
  /// Khởi tạo Attachment
  const Attachment({
    required this.id,
    required this.fileName,
    required this.size,
    required this.mimeType,
    required this.url,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Attachment &&
      other.id == id &&
      other.fileName == fileName &&
      other.size == size &&
      other.mimeType == mimeType &&
      other.url == url;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      fileName.hashCode ^
      size.hashCode ^
      mimeType.hashCode ^
      url.hashCode;
  }
  
  /// Create a copy with modified values
  Attachment copyWith({
    String? id,
    String? fileName,
    int? size,
    String? mimeType,
    String? url,
  }) {
    return Attachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      url: url ?? this.url,
    );
  }
  
  /// Tạo Attachment từ JSON
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      size: json['size'] as int,
      mimeType: json['mimeType'] as String,
      url: json['url'] as String,
    );
  }
  
  /// Chuyển Attachment thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'size': size,
      'mimeType': mimeType,
      'url': url,
    };
  }
}

/// Entity tin nhắn trong cuộc trò chuyện
class ChatMessage {
  /// ID duy nhất tin nhắn
  final String id;
  
  /// Nội dung tin nhắn
  final String content;
  
  /// Loại nội dung tin nhắn
  final ContentType contentType;
  
  /// Người gửi tin nhắn
  final User sender;
  
  /// Danh sách người dùng đã đọc tin nhắn
  final List<User> readBy;
  
  /// Danh sách tệp đính kèm
  final List<Attachment> attachments;
  
  /// ID của tin nhắn cục bộ (để theo dõi trạng thái gửi)
  final String? localId;
  
  /// Thời gian tạo tin nhắn
  final DateTime createdAt;
  
  /// Thời gian cập nhật tin nhắn
  final DateTime updatedAt;
  
  /// Khởi tạo ChatMessage
  const ChatMessage({
    required this.id,
    required this.content,
    required this.contentType,
    required this.sender,
    this.readBy = const [],
    this.attachments = const [],
    this.localId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage &&
      other.id == id &&
      other.content == content &&
      other.contentType == contentType &&
      other.sender == sender &&
      _listEquals(other.readBy, readBy) &&
      _listEquals(other.attachments, attachments) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  /// Helper to compare equality of two lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      content.hashCode ^
      contentType.hashCode ^
      sender.hashCode ^
      readBy.hashCode ^
      attachments.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }

  /// Tạo bản sao của ChatMessage với một số thuộc tính thay đổi
  ChatMessage copyWith({
    String? id,
    String? content,
    ContentType? contentType,
    User? sender,
    List<User>? readBy,
    List<Attachment>? attachments,
    String? localId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      sender: sender ?? this.sender,
      readBy: readBy ?? this.readBy,
      attachments: attachments ?? this.attachments,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Tạo ChatMessage từ JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      contentType: _parseContentType(json['contentType']),
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      readBy: (json['readBy'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      localId: json['localId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Chuyển ChatMessage thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'contentType': contentType.toString().split('.').last,
      'sender': sender.toJson(),
      'readBy': readBy.map((user) => user.toJson()).toList(),
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
      'localId': localId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Chuyển đổi từ chuỗi sang ContentType
  static ContentType _parseContentType(dynamic value) {
    if (value is ContentType) return value;
    
    final strValue = value.toString().toLowerCase();
    
    switch (strValue) {
      case 'text':
        return ContentType.text;
      case 'media':
        return ContentType.media;
      case 'mixed':
        return ContentType.mixed;
      case 'location':
        return ContentType.location;
      case 'contact':
        return ContentType.contact;
      case 'voice':
        return ContentType.voice;
      case 'file':
        return ContentType.file;
      case 'system':
        return ContentType.system;
      default:
        return ContentType.text;
    }
  }
  
  /// Kiểm tra xem tin nhắn có chứa phương tiện không
  bool get hasMedia {
    return contentType == ContentType.media ||
           contentType == ContentType.mixed ||
           attachments.isNotEmpty;
  }
  
  /// Kiểm tra xem tin nhắn có chứa văn bản không
  bool get hasText {
    return contentType == ContentType.text ||
           contentType == ContentType.mixed ||
           (contentType != ContentType.media && content.trim().isNotEmpty);
  }
} 