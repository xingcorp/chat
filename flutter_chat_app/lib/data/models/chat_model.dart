import 'package:isar/isar.dart';

part 'chat_model.g.dart';

/// Type of chat
enum ChatType {
  /// One-to-one chat
  direct,
  
  /// Group chat
  group,
  
  /// Broadcast channel
  channel
}

/// Model class representing a chat conversation
@collection
class ChatModel {
  /// Chat's unique identifier in the database
  Id id = Isar.autoIncrement;

  /// Server ID of the chat
  @Index(unique: true, replace: true)
  final String serverId;

  /// Name of the chat (for groups and channels)
  final String? name;

  /// Type of the chat
  @enumerated
  final ChatType type;

  /// ID of the last message in the chat
  final String? lastMessageId;

  /// Text preview of the last message
  final String? lastMessagePreview;

  /// Timestamp of the last message
  @Index()
  final DateTime? lastMessageTime;

  /// Number of unread messages
  final int unreadCount;

  /// List of participant user IDs
  final List<String> participantIds;

  /// ID of the admin user (for groups and channels)
  final String? adminId;

  /// URL to the chat's avatar/image
  final String? avatarUrl;

  /// Indicates if the chat is muted
  final bool isMuted;

  /// Indicates if the chat is pinned
  final bool isPinned;

  /// Timestamp when the chat was created
  @Index()
  final DateTime createdAt;

  /// Timestamp when the chat was updated
  final DateTime? updatedAt;

  /// Custom data for the chat
  final String? metadata;

  /// Default constructor
  ChatModel({
    required this.serverId,
    this.name,
    required this.type,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.participantIds,
    this.adminId,
    this.avatarUrl,
    this.isMuted = false,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Create a chat from a map
  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      serverId: map['id'] as String,
      name: map['name'] as String?,
      type: ChatType.values.firstWhere(
          (e) => e.name == (map['type'] as String),
          orElse: () => ChatType.direct),
      lastMessageId: map['lastMessageId'] as String?,
      lastMessagePreview: map['lastMessagePreview'] as String?,
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'] as String)
          : null,
      unreadCount: map['unreadCount'] as int? ?? 0,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      adminId: map['adminId'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      isMuted: map['isMuted'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      metadata: map['metadata'] as String?,
    );
  }

  /// Convert chat to a map
  Map<String, dynamic> toMap() {
    return {
      'id': serverId,
      'name': name,
      'type': type.name,
      'lastMessageId': lastMessageId,
      'lastMessagePreview': lastMessagePreview,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'participantIds': participantIds,
      'adminId': adminId,
      'avatarUrl': avatarUrl,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create a copy of this chat with changed fields
  ChatModel copyWith({
    String? serverId,
    String? name,
    ChatType? type,
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
    int? unreadCount,
    List<String>? participantIds,
    String? adminId,
    String? avatarUrl,
    bool? isMuted,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metadata,
  }) {
    return ChatModel(
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      type: type ?? this.type,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participantIds: participantIds ?? this.participantIds,
      adminId: adminId ?? this.adminId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Update chat with a new message
  ChatModel withLastMessage({
    required String messageId,
    required String preview,
    required DateTime timestamp,
  }) {
    return copyWith(
      lastMessageId: messageId,
      lastMessagePreview: preview,
      lastMessageTime: timestamp,
      updatedAt: DateTime.now(),
    );
  }

  /// Increment unread count
  ChatModel incrementUnread() {
    return copyWith(
      unreadCount: unreadCount + 1,
    );
  }

  /// Reset unread count
  ChatModel resetUnread() {
    return copyWith(
      unreadCount: 0,
    );
  }

  /// Add a participant to the chat
  ChatModel addParticipant(String userId) {
    if (participantIds.contains(userId)) return this;
    
    final newParticipants = List<String>.from(participantIds);
    newParticipants.add(userId);
    
    return copyWith(
      participantIds: newParticipants,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a participant from the chat
  ChatModel removeParticipant(String userId) {
    if (!participantIds.contains(userId)) return this;
    
    final newParticipants = List<String>.from(participantIds);
    newParticipants.remove(userId);
    
    return copyWith(
      participantIds: newParticipants,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle muted status
  ChatModel toggleMuted() {
    return copyWith(
      isMuted: !isMuted,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle pinned status
  ChatModel togglePinned() {
    return copyWith(
      isPinned: !isPinned,
      updatedAt: DateTime.now(),
    );
  }
} 