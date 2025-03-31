import 'package:flutter_chat_app/domain/entities/user.dart';

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
  
  /// Create attachment from GraphQL response
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      size: json['size'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

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
  
  /// Convert attachment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'contentType': contentType,
      'size': size,
      'metadata': metadata,
    };
  }
}

/// Entity đại diện cho một tin nhắn chat
class ChatMessage {
  final String id;
  final String conversationId;
  final User sender;
  final ContentType contentType;
  final String content;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<User> readBy;
  final Map<String, dynamic>? metadata;
  final bool isDeleted;
  final bool isSent;
  final String? replyToMessageId;
  final String? localId;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.contentType,
    required this.content,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.readBy = const [],
    this.metadata,
    this.isDeleted = false,
    this.isSent = true,
    this.replyToMessageId,
    this.localId,
  });

  // Aliases for backward compatibility
  String get senderId => sender.id;
  String? get senderName => sender.fullName;
  String? get senderAvatar => sender.avatar;
  DateTime get timestamp => createdAt;
  
  bool get isDelivered => readBy.isNotEmpty;
  bool get isRead => readBy.isNotEmpty;

  /// Create ChatMessage from GraphQL response
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      contentType: _parseContentType(json['contentType']),
      content: json['content'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isSent: json['isSent'] as bool? ?? true,
      replyToMessageId: json['replyToMessageId'] as String?,
      localId: json['localId'] as String?,
    );
  }
  
  /// Parse content type from string or enum
  static ContentType _parseContentType(dynamic value) {
    if (value is ContentType) return value;
    
    final strValue = value.toString().toLowerCase();
    
    switch (strValue) {
      case 'text':
        return ContentType.text;
      case 'image':
        return ContentType.image;
      case 'video':
        return ContentType.video;
      case 'audio':
        return ContentType.audio;
      case 'file':
        return ContentType.file;
      case 'location':
        return ContentType.location;
      case 'contact':
        return ContentType.contact;
      case 'sticker':
        return ContentType.sticker;
      case 'system':
        return ContentType.system;
      default:
        return ContentType.text;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    User? sender,
    ContentType? contentType,
    String? content,
    List<Attachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<User>? readBy,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    bool? isSent,
    String? replyToMessageId,
    String? localId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readBy: readBy ?? this.readBy,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      isSent: isSent ?? this.isSent,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      localId: localId ?? this.localId,
    );
  }
  
  /// Convert to JSON for sending to GraphQL
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender.toJson(),
      'contentType': contentType.toString().split('.').last,
      'content': content,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'readBy': readBy.map((u) => u.toJson()).toList(),
      'isDeleted': isDeleted,
      'isSent': isSent,
      'replyToMessageId': replyToMessageId,
      'localId': localId,
      'metadata': metadata,
    };
  }

  /// Create a draft message with local ID
  factory ChatMessage.draft({
    required String conversationId,
    required User sender,
    required ContentType contentType,
    required String content,
    List<Attachment> attachments = const [],
    String? replyToMessageId,
  }) {
    final now = DateTime.now();
    final localId = 'draft_${now.millisecondsSinceEpoch}_${sender.id}';
    
    return ChatMessage(
      id: localId,
      localId: localId,
      conversationId: conversationId,
      sender: sender,
      contentType: contentType,
      content: content,
      attachments: attachments,
      createdAt: now,
      updatedAt: now,
      isSent: false,
      replyToMessageId: replyToMessageId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage &&
      other.id == id &&
      other.conversationId == conversationId &&
      other.sender == sender &&
      other.contentType == contentType &&
      other.content == content &&
      _listEquals(other.attachments, attachments) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      _listEquals(other.readBy, readBy) &&
      other.isDeleted == isDeleted &&
      other.isSent == isSent &&
      other.replyToMessageId == replyToMessageId &&
      other.localId == localId;
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
      sender.hashCode ^
      contentType.hashCode ^
      content.hashCode ^
      attachments.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      readBy.hashCode ^
      isDeleted.hashCode ^
      isSent.hashCode ^
      replyToMessageId.hashCode ^
      localId.hashCode;
  }
} 