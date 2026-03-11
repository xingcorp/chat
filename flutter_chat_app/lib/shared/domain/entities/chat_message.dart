import 'dart:typed_data';

import 'package:flutter_chat_app/shared/domain/entities/content_format.dart';

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

  /// Sticker
  sticker,
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
    case ContentType.sticker:
      return 'Sticker';
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

  /// URL của tệp (empty string if uploading)
  final String url;

  /// Loại tệp
  final String type;

  /// Kích thước tệp
  final int size;

  /// Tên tệp
  final String name;

  /// Đường dẫn cục bộ (for displaying local file during upload - mobile only)
  final String? localPath;

  /// Bytes cục bộ (for displaying local file during upload - web only)
  final Uint8List? localBytes;

  /// Upload progress (0.0 - 1.0, null when not uploading)
  final double? uploadProgress;

  /// Whether file is currently uploading
  bool get isUploading => uploadProgress != null && uploadProgress! < 1.0;

  /// Constructor
  MessageAttachment({
    required this.id,
    required this.url,
    required this.type,
    required this.size,
    required this.name,
    this.localPath,
    this.localBytes,
    this.uploadProgress,
  });

  /// Create a copy with updated values
  MessageAttachment copyWith({
    String? id,
    String? url,
    String? type,
    int? size,
    String? name,
    String? localPath,
    Uint8List? localBytes,
    double? uploadProgress,
  }) {
    return MessageAttachment(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      size: size ?? this.size,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      localBytes: localBytes ?? this.localBytes,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  /// Tạo từ JSON
  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      size: json['size'] as int,
      name: json['name'] as String,
      localPath: json['localPath'] as String?,
      uploadProgress: json['uploadProgress'] as double?,
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
      if (localPath != null) 'localPath': localPath,
      if (uploadProgress != null) 'uploadProgress': uploadProgress,
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
           other.name == name &&
           other.localPath == localPath &&
           other.uploadProgress == uploadProgress;
  }

  @override
  int get hashCode => id.hashCode ^ url.hashCode ^ type.hashCode ^ size.hashCode ^ name.hashCode ^ localPath.hashCode ^ uploadProgress.hashCode;
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
  /// 
  /// **DEPRECATED/UNUSED**: Backend thực hiện hard-delete, không trả về
  /// tin nhắn đã xóa. Field này giữ lại để:
  /// - Tương thích với DTO mapping (backend có thể trả về trong tương lai)
  /// - Forward compatibility nếu backend chuyển sang soft-delete
  /// 
  /// Hiện tại UI không render tombstone vì message bị xóa hoàn toàn khỏi list.
  final DateTime? deletedAt;

  /// Danh sách URLs (cho image, video, file)
  final List<String> urls;

  /// Tên file (cho file attachments)
  final String? fileName;

  /// ID tin nhắn được forward từ đâu
  final String? forwardedFromMessageId;

  /// Tin nhắn gốc được forward (nested object từ backend)
  final ChatMessage? forwardedFromMessage;

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

  /// Local status override for optimistic UI
  /// Used for: pending, sending, failed states before server confirmation
  /// null = use computed status from readBy/deliveredTo
  final MessageStatus? localStatus;

  /// Client-generated ID for tracking optimistic messages
  /// Used to match API responses with pending drafts
  /// Format: UUID v4 (e.g., "550e8400-e29b-41d4-a716-446655440000")
  /// null for messages received from server/WebSocket
  final String? clientId;

  /// Rich text content as Quill Delta JSON string.
  ///
  /// Null for plain text messages or messages received from the server
  /// that don't have local rich text data. The Delta JSON is persisted
  /// to Isar only — the server receives [content] (plain text) via the
  /// existing `message` field.
  final String? contentDelta;

  /// Format of the content.
  ///
  /// Defaults to [ContentFormat.plainText] for backward compatibility.
  /// When [contentDelta] is non-null, this is [ContentFormat.deltaJson].
  final ContentFormat contentFormat;

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
    this.forwardedFromMessage,
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
    this.localStatus,
    this.clientId,
    this.contentDelta,
    this.contentFormat = ContentFormat.plainText,
  });

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? content,
    ContentType? contentType,
    MessageSender? sender,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    List<String>? urls,
    String? fileName,
    String? forwardedFromMessageId,
    ChatMessage? forwardedFromMessage,
    String? replyMessageId,
    ChatMessage? replyMessage,
    String? actionType,
    MessageSender? actor,
    List<MessageSender>? targetUsers,
    String? newValue,
    String? oldValue,
    List<MessageSender>? mentionTo,
    List<String>? readBy,
    List<String>? deliveredTo,
    List<MessageAttachment>? attachments,
    List<MessageReaction>? reactions,
    MessageStatus? localStatus,
    bool clearLocalStatus = false,
    String? clientId,
    bool clearClientId = false,
    String? contentDelta,
    bool clearContentDelta = false,
    ContentFormat? contentFormat,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      urls: urls ?? this.urls,
      fileName: fileName ?? this.fileName,
      forwardedFromMessageId: forwardedFromMessageId ?? this.forwardedFromMessageId,
      forwardedFromMessage: forwardedFromMessage ?? this.forwardedFromMessage,
      replyMessageId: replyMessageId ?? this.replyMessageId,
      replyMessage: replyMessage ?? this.replyMessage,
      actionType: actionType ?? this.actionType,
      actor: actor ?? this.actor,
      targetUsers: targetUsers ?? this.targetUsers,
      newValue: newValue ?? this.newValue,
      oldValue: oldValue ?? this.oldValue,
      mentionTo: mentionTo ?? this.mentionTo,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      localStatus: clearLocalStatus ? null : (localStatus ?? this.localStatus),
      clientId: clearClientId ? null : (clientId ?? this.clientId),
      contentDelta: clearContentDelta ? null : (contentDelta ?? this.contentDelta),
      contentFormat: contentFormat ?? this.contentFormat,
    );
  }
  
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
      forwardedFromMessage: json['forwardedFromMessage'] != null
          ? ChatMessage.fromJson(json['forwardedFromMessage'] as Map<String, dynamic>)
          : null,
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
      contentDelta: json['contentDelta'] as String?,
      contentFormat: json['contentFormat'] == 'deltaJson'
          ? ContentFormat.deltaJson
          : ContentFormat.plainText,
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
      if (forwardedFromMessage != null) 'forwardedFromMessage': forwardedFromMessage!.toJson(),
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
      if (contentDelta != null) 'contentDelta': contentDelta,
      if (contentFormat != ContentFormat.plainText)
        'contentFormat': contentFormat.name,
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
      other.forwardedFromMessage == forwardedFromMessage &&
      other.replyMessageId == replyMessageId &&
      other.actionType == actionType &&
      other.actor == actor &&
      other.newValue == newValue &&
      other.oldValue == oldValue &&
      _listEquals(other.mentionTo, mentionTo) &&
      _listEquals(other.readBy, readBy) &&
      _listEquals(other.deliveredTo, deliveredTo) &&
      _listEquals(other.attachments, attachments) &&
      _listEquals(other.reactions, reactions) &&
      other.localStatus == localStatus &&
      other.contentDelta == contentDelta &&
      other.contentFormat == contentFormat;
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
      (forwardedFromMessage?.hashCode ?? 0) ^
      (replyMessageId?.hashCode ?? 0) ^
      (actionType?.hashCode ?? 0) ^
      (actor?.hashCode ?? 0) ^
      (newValue?.hashCode ?? 0) ^
      (oldValue?.hashCode ?? 0) ^
      mentionTo.hashCode ^
      readBy.hashCode ^
      deliveredTo.hashCode ^
      attachments.hashCode ^
      reactions.hashCode ^
      (localStatus?.hashCode ?? 0) ^
      (contentDelta?.hashCode ?? 0) ^
      contentFormat.hashCode;
  }
  
  /// Trạng thái hiện tại của tin nhắn
  /// Priority: localStatus (for optimistic UI) > computed from readBy/deliveredTo
  MessageStatus get status {
    // Use local status if set (for pending, sending, failed states)
    if (localStatus != null) {
      return localStatus!;
    }
    // Compute from server data
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
                      contentType == ContentType.sticker ||
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

  /// Kiểm tra tin nhắn có phải sticker
  bool get isSticker => contentType == ContentType.sticker;
  
  /// Tên tệp đính kèm
  String? get attachmentFileName {
    if (attachments.isNotEmpty) {
      return attachments.first.name;
    }
    return null;
  }

  /// Kiểm tra tin nhắn đã bị xóa
  /// 
  /// **DEPRECATED/UNUSED**: Xem comment `deletedAt` field.
  /// Backend hard-delete nên getter này luôn return false với data từ server.
  bool get isDeleted => deletedAt != null;

  /// Kiểm tra tin nhắn đã được đọc bởi người dùng hiện tại
  bool get isReadByCurrentUser => readBy.contains('current_user_id'); // Replace with actual logic
}
