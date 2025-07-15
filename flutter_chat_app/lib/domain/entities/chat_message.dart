/// Loại nội dung của tin nhắn
enum ContentType {
  /// Văn bản
  text,
  
  /// Hình ảnh
  image,
  
  /// Tệp
  file,
  
  /// Âm thanh
  audio,
  
  /// Video
  video,
  
  /// Vị trí
  location,
  
  /// Liên kết
  link,
  
  /// Sự kiện
  event,
}

/// Trạng thái tin nhắn
enum MessageStatus {
  /// Đang chờ gửi (offline queue)
  pending,

  /// Đang gửi
  sending,

  /// Đã gửi (đến server)
  sent,

  /// Đã nhận (đến thiết bị người nhận)
  delivered,

  /// Đã đọc (người nhận đã đọc)
  read,

  /// Gửi thất bại
  failed,
}

/// Hàm tiện ích để so sánh danh sách
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  
  return true;
}

/// Lấy tên hiển thị cho loại nội dung tin nhắn
String getContentTypeName(ContentType type) {
  switch (type) {
    case ContentType.text:
      return 'Văn bản';
    case ContentType.image:
      return 'Hình ảnh';
    case ContentType.video:
      return 'Video';
    case ContentType.audio:
      return 'Âm thanh';
    case ContentType.file:
      return 'Tệp tin';
    case ContentType.location:
      return 'Vị trí';
    case ContentType.link:
      return 'Liên kết';
    case ContentType.event:
      return 'Sự kiện';
    default:
      return 'Tin nhắn';
  }
}

/// Class đại diện cho thông tin người gửi tin nhắn
class MessageSender {
  /// ID người gửi
  final String id;
  
  /// Tên người gửi
  final String name;
  
  /// Avatar của người gửi
  final String? avatar;
  
  /// Constructor
  MessageSender({
    required this.id, 
    required this.name, 
    this.avatar,
  });
  
  /// Tạo từ JSON
  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
    );
  }
  
  /// Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatar != null) 'avatar': avatar,
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MessageSender &&
           other.id == id &&
           other.name == name &&
           other.avatar == avatar;
  }
  
  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ avatar.hashCode;
}

/// Thông tin tệp đính kèm
class MessageAttachment {
  /// ID của tệp đính kèm
  final String id;
  
  /// URL của tệp
  final String url;
  
  /// Loại tệp
  final String type;
  
  /// Kích thước tệp
  final int size;
  
  /// Tên tệp
  final String name;
  
  /// Constructor
  MessageAttachment({
    required this.id,
    required this.url,
    required this.type,
    required this.size,
    required this.name,
  });
  
  /// Tạo từ JSON
  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      size: json['size'] as int,
      name: json['name'] as String,
    );
  }
  
  /// Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type,
      'size': size,
      'name': name,
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MessageAttachment &&
           other.id == id &&
           other.url == url &&
           other.type == type &&
           other.size == size &&
           other.name == name;
  }
  
  @override
  int get hashCode => id.hashCode ^ url.hashCode ^ type.hashCode ^ size.hashCode ^ name.hashCode;
}

/// Class đại diện cho một tin nhắn chat
class ChatMessage {
  /// ID tin nhắn
  final String id;
  
  /// ID của đoạn chat
  final String chatId;
  
  /// Nội dung tin nhắn
  final String content;
  
  /// Loại nội dung
  final ContentType contentType;
  
  /// Thông tin người gửi
  final MessageSender sender;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Thời gian cập nhật
  final DateTime updatedAt;
  
  /// Danh sách người đã đọc tin nhắn
  final List<String> readBy;
  
  /// Danh sách người đã nhận tin nhắn
  final List<String> deliveredTo;
  
  /// Danh sách tệp đính kèm
  final List<MessageAttachment> attachments;
  
  /// Constructor
  ChatMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.contentType,
    required this.sender,
    required this.createdAt,
    required this.updatedAt,
    this.readBy = const [],
    this.deliveredTo = const [],
    this.attachments = const [],
  });
  
  /// Tạo từ JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Xử lý contentType
    ContentType type = ContentType.text;
    final contentTypeStr = json['contentType'] as String?;
    if (contentTypeStr != null) {
      try {
        type = ContentType.values.firstWhere(
          (e) => e.toString() == 'ContentType.$contentTypeStr',
          orElse: () => ContentType.text,
        );
      } catch (_) {
        type = ContentType.text;
      }
    }
    
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      content: json['content'] as String,
      contentType: type,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      readBy: (json['readBy'] as List?)?.map((e) => e as String).toList() ?? [],
      deliveredTo: (json['deliveredTo'] as List?)?.map((e) => e as String).toList() ?? [],
      attachments: (json['attachments'] as List?)
          ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  /// Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'content': content,
      'contentType': contentType.toString().split('.').last,
      'sender': sender.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'readBy': readBy,
      'deliveredTo': deliveredTo,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }
  
  /// Create a draft message with local ID
  factory ChatMessage.draft({
    required String chatId,
    required MessageSender sender,
    required ContentType contentType,
    required String content,
    List<MessageAttachment> attachments = const [],
  }) {
    final now = DateTime.now();
    final localId = 'draft_${now.millisecondsSinceEpoch}';
    
    return ChatMessage(
      id: localId,
      chatId: chatId,
      content: content,
      contentType: contentType,
      sender: sender,
      createdAt: now,
      updatedAt: now,
      attachments: attachments,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage &&
      other.id == id &&
      other.chatId == chatId &&
      other.content == content &&
      other.contentType == contentType &&
      other.sender == sender &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      _listEquals(other.readBy, readBy) &&
      _listEquals(other.deliveredTo, deliveredTo) &&
      _listEquals(other.attachments, attachments);
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      chatId.hashCode ^
      content.hashCode ^
      contentType.hashCode ^
      sender.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      readBy.hashCode ^
      deliveredTo.hashCode ^
      attachments.hashCode;
  }
  
  /// Trạng thái hiện tại của tin nhắn
  MessageStatus get status {
    if (readBy.isNotEmpty) {
      return MessageStatus.read;
    } else if (deliveredTo.isNotEmpty) {
      return MessageStatus.delivered;
    } else {
      return MessageStatus.sent;
    }
  }
  
  /// Tên người gửi
  String get senderName => sender.name;
  
  /// Kiểm tra tin nhắn có phải từ người dùng hiện tại
  bool get isFromCurrentUser => sender.id == 'current_user_id'; // Replace with actual logic
  
  /// Kiểm tra tin nhắn có chứa media
  bool get hasMedia => contentType == ContentType.image || 
                      contentType == ContentType.video || 
                      contentType == ContentType.audio || 
                      (contentType == ContentType.file && attachments.isNotEmpty);
  
  /// URL media chính của tin nhắn
  String get mediaUrl {
    if (attachments.isNotEmpty) {
      return attachments.first.url;
    }
    return '';
  }
  
  /// Kiểm tra tin nhắn có phải là hình ảnh
  bool get isImage => contentType == ContentType.image;
  
  /// Kiểm tra tin nhắn có phải là video
  bool get isVideo => contentType == ContentType.video;
  
  /// Kiểm tra tin nhắn có phải là âm thanh
  bool get isAudio => contentType == ContentType.audio;
  
  /// Tên tệp đính kèm
  String? get fileName {
    if (attachments.isNotEmpty) {
      return attachments.first.name;
    }
    return null;
  }

  /// Kiểm tra tin nhắn đã bị xóa
  bool get isDeleted => status == MessageStatus.failed; // Temporary mapping

  /// Kiểm tra tin nhắn đã được đọc bởi người dùng hiện tại
  bool get isReadByCurrentUser => readBy.contains('current_user_id'); // Replace with actual logic
}