import 'dart:convert';

import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'message_model.g.dart';

/// Type of message content
enum MessageType {
  /// Plain text message
  text,
  
  /// Image message
  image,
  
  /// Video message
  video,
  
  /// Audio message
  audio,
  
  /// File message
  file,
  
  /// Location message
  location,
  
  /// Contact message
  contact,
  
  /// System message
  system
}

/// Model class representing a message
@collection
class MessageModel {
  /// Message's unique identifier in the database
  @Id()
  final int id;

  /// Server ID of the message
  @Index(unique: true)
  final String? serverId;

  /// Local unique ID for the message
  @Index(unique: true)
  final String localId;

  /// ID of the chat this message belongs to
  @Index()
  final String chatId;

  /// ID of the user who sent the message
  @Index()
  final String senderId;

  /// IDs of users who have read the message
  final List<String> readBy;

  /// Message content (text, file path, etc.)
  final String content;

  /// Type of message
  @enumValue
  final MessageType type;

  /// Status of the message
  @enumValue
  final MessageStatus status;

  /// Timestamp when the message was created
  @Index()
  final DateTime createdAt;

  /// Timestamp when the message was updated
  final DateTime? updatedAt;

  /// Timestamp when the message was edited
  final DateTime? editedAt;

  /// Timestamp when the message was deleted
  final DateTime? deletedAt;

  /// List of URLs (for images, videos, files)
  final List<String> urls;

  /// File name (for file attachments)
  final String? fileName;

  /// ID of the message this was forwarded from
  final String? forwardedFromMessageId;

  /// IDs of users mentioned in the message (stored as JSON)
  final String? mentionToJson;

  /// Message that this message is replying to
  final String? replyToMessageId;

  /// Additional data for the message (like file metadata)
  final String? metadata;

  /// Indicates if the message has been deleted
  final bool isDeleted;

  /// Indicates if the message is pinned
  final bool isPinned;

  /// Number of failed attempts to send the message
  final int retryCount;

  /// Error message if sending failed
  final String? errorMessage;

  /// Default constructor
  MessageModel({
    this.id = 0,
    this.serverId,
    required this.localId,
    required this.chatId,
    required this.senderId,
    this.readBy = const [],
    required this.content,
    required this.type,
    this.status = MessageStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.editedAt,
    this.deletedAt,
    this.urls = const [],
    this.fileName,
    this.forwardedFromMessageId,
    this.mentionToJson,
    this.replyToMessageId,
    this.metadata,
    this.isDeleted = false,
    this.isPinned = false,
    this.retryCount = 0,
    this.errorMessage,
  });

  /// Create a message from a map (legacy format)
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    // Extract mentionTo and convert to JSON string
    String? mentionToJson;
    if (map['mentionTo'] != null) {
      mentionToJson = jsonEncode(map['mentionTo']);
    }

    return MessageModel(
      serverId: map['id'] as String?,
      localId: map['localId'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      readBy: List<String>.from(map['readBy'] ?? []),
      content: map['content'] as String,
      type: MessageType.values.firstWhere(
          (e) => e.name == (map['type'] as String),
          orElse: () => MessageType.text),
      status: MessageStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String?),
          orElse: () => MessageStatus.pending),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      editedAt: map['editedAt'] != null
          ? DateTime.parse(map['editedAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      urls: List<String>.from(map['urls'] ?? []),
      fileName: map['fileName'] as String?,
      forwardedFromMessageId: map['forwardedFromMessageId'] as String?,
      mentionToJson: mentionToJson,
      replyToMessageId: map['replyToMessageId'] as String?,
      metadata: map['metadata'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      retryCount: map['retryCount'] as int? ?? 0,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  /// Convert message to a map (legacy format)
  Map<String, dynamic> toMap() {
    return {
      'id': serverId,
      'localId': localId,
      'chatId': chatId,
      'senderId': senderId,
      'readBy': readBy,
      'content': content,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'urls': urls,
      'fileName': fileName,
      'forwardedFromMessageId': forwardedFromMessageId,
      'mentionTo': mentionToJson != null ? jsonDecode(mentionToJson!) : null,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      'isDeleted': isDeleted,
      'isPinned': isPinned,
      'retryCount': retryCount,
      'errorMessage': errorMessage,
    };
  }

  /// Create a copy of this message with changed fields
  MessageModel copyWith({
    int? id,
    String? serverId,
    String? localId,
    String? chatId,
    String? senderId,
    List<String>? readBy,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    List<String>? urls,
    String? fileName,
    String? forwardedFromMessageId,
    String? mentionToJson,
    String? replyToMessageId,
    String? metadata,
    bool? isDeleted,
    bool? isPinned,
    int? retryCount,
    String? errorMessage,
  }) {
    return MessageModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      localId: localId ?? this.localId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      readBy: readBy ?? this.readBy,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      urls: urls ?? this.urls,
      fileName: fileName ?? this.fileName,
      forwardedFromMessageId: forwardedFromMessageId ?? this.forwardedFromMessageId,
      mentionToJson: mentionToJson ?? this.mentionToJson,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Update the message status
  MessageModel withStatus(MessageStatus newStatus) {
    return copyWith(status: newStatus);
  }

  /// Increment retry count and update error message
  MessageModel withRetry(String? error) {
    return copyWith(
      retryCount: retryCount + 1,
      errorMessage: error,
    );
  }

  /// Mark the message as sent with a server ID
  MessageModel withServerId(String newServerId) {
    return copyWith(
      serverId: newServerId,
      status: MessageStatus.sent,
    );
  }

  /// Mark the message as read by a user
  MessageModel markReadBy(String userId) {
    if (readBy.contains(userId)) return this;
    
    final newReadBy = List<String>.from(readBy);
    newReadBy.add(userId);
    
    return copyWith(
      readBy: newReadBy,
      status: MessageStatus.read,
    );
  }

  /// Mark message as deleted
  MessageModel markAsDeleted() {
    return copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle pinned status
  MessageModel togglePinned() {
    return copyWith(
      isPinned: !isPinned,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a text message
  static MessageModel createTextMessage({
    required int id,
    required String localId,
    required String chatId, 
    required String senderId,
    required String content,
    String? replyToMessageId,
  }) {
    return MessageModel(
      id: id,
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: MessageType.text,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
    );
  }

  /// Create an image message
  static MessageModel createImageMessage({
    required int id,
    required String localId,
    required String chatId, 
    required String senderId,
    required String imagePath,
    Map<String, dynamic>? imageMetadata,
    String? caption,
  }) {
    final metadata = imageMetadata != null ? 
      jsonEncode(imageMetadata) : null;
    
    return MessageModel(
      id: id,
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: caption ?? '',
      type: MessageType.image,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create a file message
  static MessageModel createFileMessage({
    required int id,
    required String localId,
    required String chatId, 
    required String senderId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) {
    final fileData = {
      'path': filePath,
      'name': fileName,
      'size': fileSize,
      'mimeType': mimeType,
    };
    
    return MessageModel(
      id: id,
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: fileName,
      type: MessageType.file,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      metadata: jsonEncode(fileData),
    );
  }

  /// Create a video message
  static MessageModel createVideoMessage({
    required int id,
    required String localId,
    required String chatId, 
    required String senderId,
    required String videoPath,
    required String thumbnailPath,
    required int duration,
    String? caption,
  }) {
    final videoData = {
      'path': videoPath,
      'thumbnail': thumbnailPath,
      'duration': duration,
    };
    
    return MessageModel(
      id: id,
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: caption ?? '',
      type: MessageType.video,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      metadata: jsonEncode(videoData),
    );
  }

  /// Create an audio message
  static MessageModel createAudioMessage({
    required int id,
    required String localId,
    required String chatId, 
    required String senderId,
    required String audioPath,
    required int duration,
  }) {
    final audioData = {
      'path': audioPath,
      'duration': duration,
    };
    
    return MessageModel(
      id: id,
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: 'Audio message',
      type: MessageType.audio,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      metadata: jsonEncode(audioData),
    );
  }

  /// Create a location message
  static MessageModel createLocationMessage({
    required int id,
    required String localId,
    required String chatId, 
    required String senderId,
    required double latitude,
    required double longitude,
    String? address,
  }) {
    final locationData = {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
    
    return MessageModel(
      id: id,
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: address ?? 'Location',
      type: MessageType.location,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      metadata: jsonEncode(locationData),
    );
  }

  /// Create a system message (e.g., user joined, left, etc.)
  static MessageModel createSystemMessage({
    required int id,
    required String localId,
    required String chatId, 
    required String content,
  }) {
    return MessageModel(
      id: id,
      localId: localId,
      chatId: chatId,
      senderId: 'system',
      content: content,
      type: MessageType.system,
      status: MessageStatus.delivered, // System messages are always delivered
      createdAt: DateTime.now(),
      readBy: const [], // No read status for system messages
    );
  }

  /// Get metadata as a map
  Map<String, dynamic>? get metadataMap {
    if (metadata == null) return null;
    try {
      return jsonDecode(metadata!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if the message is a multimedia message
  bool get isMultimedia => 
    type == MessageType.image || 
    type == MessageType.video || 
    type == MessageType.audio || 
    type == MessageType.file;

  /// Check if the message is a media that can be displayed inline
  bool get isDisplayableMedia => 
    type == MessageType.image || 
    type == MessageType.video;

  /// Check if the message is editable
  bool get isEditable => 
    !isDeleted && 
    type == MessageType.text && 
    DateTime.now().difference(createdAt).inDays < 2; // Editable for 2 days

  /// Get the duration for audio or video messages
  int? get mediaDuration {
    final map = metadataMap;
    if (map == null) return null;
    return map['duration'] as int?;
  }

  /// Get the file size for file messages
  int? get fileSize {
    final map = metadataMap;
    if (map == null) return null;
    return map['size'] as int?;
  }

  /// Get the file mime type for file messages
  String? get fileMimeType {
    final map = metadataMap;
    if (map == null) return null;
    return map['mimeType'] as String?;
  }

  /// Get the file path (local or remote)
  String? get mediaPath {
    final map = metadataMap;
    if (map == null) return null;
    return map['path'] as String?;
  }

  /// Get mentioned users as list
  @ignore
  List<Map<String, dynamic>> get mentionToList {
    if (mentionToJson == null) return [];
    try {
      final decoded = jsonDecode(mentionToJson!);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Convert MessageModel to domain ChatMessage entity
  ChatMessage toDomain() {
    Map<String, dynamic> metadataMap = {};
    if (metadata != null && metadata!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata!);
        if (decoded is Map<String, dynamic>) {
          metadataMap = decoded;
        }
      } catch (_) {}
    }

    String? senderName;
    String? senderAvatar;
    final senderMeta = metadataMap['sender'];
    if (senderMeta is Map<String, dynamic>) {
      final fullName = senderMeta['fullname'] ?? senderMeta['fullName'] ?? senderMeta['name'];
      if (fullName is String && fullName.trim().isNotEmpty) {
        senderName = fullName.trim();
      }

      final imageUrls = senderMeta['imageUrls'];
      if (imageUrls is List && imageUrls.isNotEmpty) {
        final first = imageUrls.first;
        if (first is String && first.trim().isNotEmpty) {
          senderAvatar = first.trim();
        }
      }
    }

    // Convert MessageType to ContentType (mapping data layer to domain layer)
    ContentType contentType;
    switch (type) {
      case MessageType.text:
        contentType = ContentType.text;
        break;
      case MessageType.image:
        contentType = ContentType.image;
        break;
      case MessageType.video:
        contentType = ContentType.video;
        break;
      case MessageType.audio:
        contentType = ContentType.audio;
        break;
      case MessageType.file:
        contentType = ContentType.file;
        break;
      case MessageType.location:
        contentType = ContentType.location;
        break;
      case MessageType.contact:
        contentType = ContentType.link; // Map contact to link in domain
        break;
      case MessageType.system:
        contentType = ContentType.event; // Map system to event in domain
        break;
      default:
        contentType = ContentType.text;
    }

    // Create MessageSender from senderId (prefer metadata sender for name/avatar)
    final sender = MessageSender(
      id: senderId,
      name: (senderName != null && senderName!.isNotEmpty)
          ? senderName!
          : senderId,
      avatar: senderAvatar,
    );

    // Parse mentionTo from JSON
    final mentionedUsers = mentionToList.map((m) {
      return MessageSender(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? 'Unknown',
        avatar: m['avatar'] as String?,
      );
    }).toList();

    // Create attachments if this is a media message
    final attachments = <MessageAttachment>[];
    if (isMultimedia && (mediaPath != null || urls.isNotEmpty)) {
      final url = urls.isNotEmpty ? urls.first : (mediaPath ?? '');
      attachments.add(MessageAttachment(
        id: '$localId-attachment',
        type: _getAttachmentTypeString(type),
        url: url,
        name: fileName ?? 'attachment',
        size: fileSize ?? 0,
      ));
    }

    return ChatMessage(
      id: serverId ?? localId,
      chatId: chatId,
      content: content,
      contentType: contentType,
      sender: sender,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
      urls: urls,
      fileName: fileName,
      forwardedFromMessageId: forwardedFromMessageId,
      mentionTo: mentionedUsers,
      readBy: readBy,
      deliveredTo: status == MessageStatus.delivered || status == MessageStatus.read
          ? [senderId]
          : [],
      attachments: attachments,
    );
  }

  /// Helper method to convert MessageType to attachment type string
  String _getAttachmentTypeString(MessageType messageType) {
    switch (messageType) {
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.audio:
        return 'audio';
      case MessageType.file:
        return 'document';
      case MessageType.location:
        return 'location';
      case MessageType.contact:
        return 'contact';
      default:
        return 'document';
    }
  }
}