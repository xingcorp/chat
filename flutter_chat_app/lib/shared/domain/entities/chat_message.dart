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

/// Class đại diện cho reaction của tin nhắn
class MessageReaction {
  /// Emoji code (e.g., "👍", "❤️", "😂")
  final String code;

  /// ID người dùng đã react
  final String userId;

  /// Tên người dùng đã react (optional, for display)
  final String? userName;

  /// Thời gian react
  final DateTime createdAt;

  /// Constructor
  MessageReaction({
    required this.code,
    required this.userId,
    this.userName,
    required this.createdAt,
  });

  /// Tạo từ JSON
  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      code: json['code'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'userId': userId,
      if (userName != null) 'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MessageReaction &&
           other.code == code &&
           other.userId == userId &&
           other.createdAt == createdAt;
  }
  
  @override
  int get hashCode => code.hashCode ^ userId.hashCode ^ createdAt.hashCode;
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

  /// Thời gian chỉnh sửa (nếu có)
  final DateTime? editedAt;

  /// Thời gian xóa (nếu có)
  final DateTime? deletedAt;

  /// Danh sách URLs (cho image, video, file)
  final List<String> urls;

  /// Tên file (cho file attachments)
  final String? fileName;

  /// ID tin nhắn được forward từ đâu
  final String? forwardedFromMessageId;

  /// ID tin nhắn được reply (khớp Angular: replyMessageId)
  final String? replyMessageId;

  /// Tin nhắn được reply (khớp Angular: replyMessage — nested object)
  final ChatMessage? replyMessage;

  /// Loại action cho system event (khớp Angular: ConversationActionType)
  final String? actionType;

  /// Người thực hiện action (khớp Angular: actor)
  final MessageSender? actor;

  /// Danh sách user bị tác động (khớp Angular: targetUsers)
  final List<MessageSender> targetUsers;

  /// Giá trị mới cho system event (khớp Angular: newValue)
  final String? newValue;

  /// Giá trị cũ cho system event (khớp Angular: oldValue)
  final String? oldValue;

  /// Danh sách user được mention
  final List<MessageSender> mentionTo;

  /// Danh sách người đã đọc tin nhắn
  final List<String> readBy;

  /// Danh sách người đã nhận tin nhắn
  final List<String> deliveredTo;

  /// Danh sách tệp đính kèm
  final List<MessageAttachment> attachments;

  /// Danh sách reactions
  final List<MessageReaction> reactions;

  /// Constructor
  ChatMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.contentType,
    required this.sender,
    required this.createdAt,
    required this.updatedAt,
    this.editedAt,
    this.deletedAt,
    this.urls = const [],
    this.fileName,
    this.forwardedFromMessageId,
    this.replyMessageId,
    this.replyMessage,
    this.actionType,
    this.actor,
    this.targetUsers = const [],
    this.newValue,
    this.oldValue,
    this.mentionTo = const [],
    this.readBy = const [],
    this.deliveredTo = const [],
    this.attachments = const [],
    this.reactions = const [],
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
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt'] as String) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      urls: (json['urls'] as List?)?.map((e) => e as String).toList() ?? [],
      fileName: json['fileName'] as String?,
      forwardedFromMessageId: json['forwardedFromMessageId'] as String?,
      replyMessageId: json['replyMessageId'] as String?,
      replyMessage: json['replyMessage'] != null
          ? ChatMessage.fromJson(json['replyMessage'] as Map<String, dynamic>)
          : null,
      actionType: json['actionType'] as String?,
      actor: json['actor'] != null
          ? MessageSender.fromJson(json['actor'] as Map<String, dynamic>)
          : null,
      targetUsers: (json['targetUsers'] as List?)
          ?.map((e) => MessageSender.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      newValue: json['newValue'] as String?,
      oldValue: json['oldValue'] as String?,
      mentionTo: (json['mentionTo'] as List?)
          ?.map((e) => MessageSender.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      readBy: (json['readBy'] as List?)?.map((e) => e as String).toList() ?? [],
      deliveredTo: (json['deliveredTo'] as List?)?.map((e) => e as String).toList() ?? [],
      attachments: (json['attachments'] as List?)
          ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      reactions: (json['reactions'] as List?)
          ?.map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
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
      if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'urls': urls,
      'fileName': fileName,
      'forwardedFromMessageId': forwardedFromMessageId,
      'replyMessageId': replyMessageId,
      if (replyMessage != null) 'replyMessage': replyMessage!.toJson(),
      if (actionType != null) 'actionType': actionType,
      if (actor != null) 'actor': actor!.toJson(),
      if (targetUsers.isNotEmpty) 'targetUsers': targetUsers.map((u) => u.toJson()).toList(),
      if (newValue != null) 'newValue': newValue,
      if (oldValue != null) 'oldValue': oldValue,
      'mentionTo': mentionTo.map((m) => m.toJson()).toList(),
      'readBy': readBy,
      'deliveredTo': deliveredTo,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
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
      other.editedAt == editedAt &&
      other.deletedAt == deletedAt &&
      _listEquals(other.urls, urls) &&
      other.fileName == fileName &&
      other.forwardedFromMessageId == forwardedFromMessageId &&
      other.replyMessageId == replyMessageId &&
      other.actionType == actionType &&
      other.actor == actor &&
      other.newValue == newValue &&
      other.oldValue == oldValue &&
      _listEquals(other.mentionTo, mentionTo) &&
      _listEquals(other.readBy, readBy) &&
      _listEquals(other.deliveredTo, deliveredTo) &&
      _listEquals(other.attachments, attachments) &&
      _listEquals(other.reactions, reactions);
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
      (editedAt?.hashCode ?? 0) ^
      (deletedAt?.hashCode ?? 0) ^
      urls.hashCode ^
      (fileName?.hashCode ?? 0) ^
      (forwardedFromMessageId?.hashCode ?? 0) ^
      (replyMessageId?.hashCode ?? 0) ^
      (actionType?.hashCode ?? 0) ^
      (actor?.hashCode ?? 0) ^
      (newValue?.hashCode ?? 0) ^
      (oldValue?.hashCode ?? 0) ^
      mentionTo.hashCode ^
      readBy.hashCode ^
      deliveredTo.hashCode ^
      attachments.hashCode ^
      reactions.hashCode;
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
  String? get attachmentFileName {
    if (attachments.isNotEmpty) {
      return attachments.first.name;
    }
    return null;
  }

  /// Kiểm tra tin nhắn đã bị xóa
  bool get isDeleted => deletedAt != null;

  /// Kiểm tra tin nhắn đã được đọc bởi người dùng hiện tại
  bool get isReadByCurrentUser => readBy.contains('current_user_id'); // Replace with actual logic
}