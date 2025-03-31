import 'package:isar/isar.dart';

part 'message_model.g.dart';

/// Status of a message in the queue
@enumerated
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
@enumerated
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
  Id id = Isar.autoIncrement;

  /// Server ID of the message
  @Index(unique: true, replace: true)
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
  @Enumerated(EnumType.name)
  final MessageType type;

  /// Status of the message
  @Enumerated(EnumType.name)
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
} 