/// Enum cho các loại nội dung tin nhắn
enum ContentType {
  text,
  image,
  video,
  audio,
  file,
  location,
  contact,
  sticker,
  system
}

/// Extension cho ContentType để tiện sử dụng
extension ContentTypeExtension on ContentType {
  String toLowerCase() {
    return toString().split('.').last.toLowerCase();
  }
  
  String getDisplayName() {
    switch (this) {
      case ContentType.text:
        return 'Tin nhắn';
      case ContentType.image:
        return 'Hình ảnh';
      case ContentType.video:
        return 'Video';
      case ContentType.audio:
        return 'Ghi âm';
      case ContentType.file:
        return 'Tệp đính kèm';
      case ContentType.location:
        return 'Vị trí';
      case ContentType.contact:
        return 'Danh thiếp';
      case ContentType.sticker:
        return 'Nhãn dán';
      case ContentType.system:
        return 'Thông báo hệ thống';
      default:
        return 'Tin nhắn';
    }
  }
}

/// Entity đại diện cho một tệp đính kèm
class Attachment {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String fileName;
  final String contentType;
  final int size;
  final Map<String, dynamic>? metadata;

  const Attachment({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.fileName,
    required this.contentType,
    required this.size,
    this.metadata,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Attachment &&
      other.id == id &&
      other.url == url &&
      other.thumbnailUrl == thumbnailUrl &&
      other.fileName == fileName &&
      other.contentType == contentType &&
      other.size == size;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      url.hashCode ^
      thumbnailUrl.hashCode ^
      fileName.hashCode ^
      contentType.hashCode ^
      size.hashCode;
  }
}

/// Entity đại diện cho một tin nhắn chat
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final ContentType contentType;
  final String content;
  final List<Attachment> attachments;
  final DateTime timestamp;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final bool isDeleted;
  final bool isSent;
  final String? replyToMessageId;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.contentType,
    required this.content,
    this.attachments = const [],
    required this.timestamp,
    this.deliveredAt,
    this.readAt,
    this.metadata,
    this.isDeleted = false,
    this.isSent = true,
    this.replyToMessageId,
  });

  bool get isDelivered => deliveredAt != null;
  bool get isRead => readAt != null;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    ContentType? contentType,
    String? content,
    List<Attachment>? attachments,
    DateTime? timestamp,
    DateTime? deliveredAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    bool? isSent,
    String? replyToMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      isSent: isSent ?? this.isSent,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage &&
      other.id == id &&
      other.conversationId == conversationId &&
      other.senderId == senderId &&
      other.senderName == senderName &&
      other.senderAvatar == senderAvatar &&
      other.contentType == contentType &&
      other.content == content &&
      _listEquals(other.attachments, attachments) &&
      other.timestamp == timestamp &&
      other.deliveredAt == deliveredAt &&
      other.readAt == readAt &&
      other.isDeleted == isDeleted &&
      other.isSent == isSent &&
      other.replyToMessageId == replyToMessageId;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      conversationId.hashCode ^
      senderId.hashCode ^
      senderName.hashCode ^
      senderAvatar.hashCode ^
      contentType.hashCode ^
      content.hashCode ^
      attachments.hashCode ^
      timestamp.hashCode ^
      deliveredAt.hashCode ^
      readAt.hashCode ^
      isDeleted.hashCode ^
      isSent.hashCode ^
      replyToMessageId.hashCode;
  }
} 