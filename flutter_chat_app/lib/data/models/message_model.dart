import 'package:isar/isar.dart';
import 'dart:convert';

part 'message_model.g.dart';

/// Status of a message in the queue
enum MessageStatus {
  /// Message is in the queue waiting to be sent
  pending,
  
  /// Message is currently being sent
  sending,
  
  /// Message has been sent to the server but not delivered to the recipient
  sent,
  
  /// Message has been delivered to the recipient
  delivered,
  
  /// Message has been read by the recipient
  read,
  
  /// Failed to send the message
  failed
}

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
    this.replyToMessageId,
    this.metadata,
    this.isDeleted = false,
    this.isPinned = false,
    this.retryCount = 0,
    this.errorMessage,
  });

  /// Create a message from a map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
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
      replyToMessageId: map['replyToMessageId'] as String?,
      metadata: map['metadata'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      retryCount: map['retryCount'] as int? ?? 0,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  /// Convert message to a map
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
} 