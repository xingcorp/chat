import 'dart:convert';

import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:isar/isar.dart';

part 'chat_model.g.dart';

/// Model class representing a chat conversation
@collection
class ChatModel {
  /// Chat's unique identifier in the database
  @Id()
  final int id;

  /// Server ID of the chat
  @Index(unique: true)
  final String serverId;

  /// Name of the chat (for groups and channels)
  final String? name;

  /// Description of the chat (for groups)
  final String? description;

  /// Type of the chat
  @enumValue
  final ChatType type;

  /// Group type (Public/Private) - only for group chats
  final String? groupType;

  /// ID of the creator (for groups)
  final String? creatorId;

  /// Members data as JSON string (contains full member info)
  final String? membersJson;

  /// ID of the last message in the chat
  final String? lastMessageId;

  /// Text preview of the last message
  final String? lastMessagePreview;

  /// Timestamp of the last message
  final DateTime? lastMessageTime;

  /// Number of unread messages
  final int unreadCount;

  /// List of participant user IDs (backward compatibility)
  final List<String> participantIds;

  /// ID of the admin user (for groups and channels) - backward compatibility
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
    this.id = 0,
    required this.serverId,
    this.name,
    this.description,
    required this.type,
    this.groupType,
    this.creatorId,
    this.membersJson,
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

  /// Create a chat from a map (legacy format)
  factory ChatModel.fromMap(Map<String, dynamic> map) {
    // Extract members and convert to JSON string
    String? membersJson;
    if (map['members'] != null) {
      membersJson = jsonEncode(map['members']);
    }

    return ChatModel(
      serverId: map['id'] as String,
      name: map['name'] as String?,
      description: map['description'] as String?,
      type: ChatType.values.firstWhere(
          (e) => e.name == (map['type'] as String),
          orElse: () => ChatType.direct),
      groupType: map['groupType'] as String?,
      creatorId: map['creatorId'] as String?,
      membersJson: membersJson,
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

  /// Convert chat to a map (legacy format)
  Map<String, dynamic> toMap() {
    return {
      'id': serverId,
      'name': name,
      'description': description,
      'type': type.name,
      'groupType': groupType,
      'creatorId': creatorId,
      'members': membersJson != null ? jsonDecode(membersJson!) : null,
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
    int? id,
    String? serverId,
    String? name,
    String? description,
    ChatType? type,
    String? groupType,
    String? creatorId,
    String? membersJson,
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
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      groupType: groupType ?? this.groupType,
      creatorId: creatorId ?? this.creatorId,
      membersJson: membersJson ?? this.membersJson,
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

  /// Create a direct (one-to-one) chat
  static ChatModel createDirectChat({
    required int id,
    required String serverId,
    required List<String> participantIds,
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
    String? avatarUrl,
  }) {
    if (participantIds.length != 2) {
      throw ArgumentError('Direct chat must have exactly 2 participants');
    }

    return ChatModel(
      id: id,
      serverId: serverId,
      type: ChatType.direct,
      participantIds: participantIds,
      lastMessageId: lastMessageId,
      lastMessagePreview: lastMessagePreview,
      lastMessageTime: lastMessageTime,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Create a group chat
  static ChatModel createGroupChat({
    required int id,
    required String serverId,
    required String name,
    required List<String> participantIds,
    required String adminId,
    String? avatarUrl,
    Map<String, dynamic>? groupMetadata,
  }) {
    if (participantIds.isEmpty) {
      throw ArgumentError('Group chat must have at least one participant');
    }

    if (!participantIds.contains(adminId)) {
      throw ArgumentError('Admin must be a participant of the group');
    }

    return ChatModel(
      id: id,
      serverId: serverId,
      name: name,
      type: ChatType.group,
      participantIds: participantIds,
      adminId: adminId,
      avatarUrl: avatarUrl,
      metadata: groupMetadata != null ? jsonEncode(groupMetadata) : null,
      createdAt: DateTime.now(),
    );
  }

  /// Create a broadcast channel
  static ChatModel createChannel({
    required int id,
    required String serverId,
    required String name,
    required List<String> participantIds,
    required String adminId,
    String? avatarUrl,
    Map<String, dynamic>? channelMetadata,
  }) {
    return ChatModel(
      id: id,
      serverId: serverId,
      name: name,
      type: ChatType.channel,
      participantIds: participantIds,
      adminId: adminId,
      avatarUrl: avatarUrl,
      metadata: channelMetadata != null ? jsonEncode(channelMetadata) : null,
      createdAt: DateTime.now(),
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

  /// Get members as list
  @ignore
  List<Map<String, dynamic>> get membersList {
    if (membersJson == null) return [];
    try {
      final decoded = jsonDecode(membersJson!);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Convert ChatModel to domain Chat entity
  Chat toDomain() {
    // Parse members from JSON
    final members = membersList.map((m) {
      return ConversationMember(
        id: m['id'] as String? ?? '',
        userId: m['userId'] as String? ?? '',
        fullName: m['fullName'] as String?,
        avatarUrl: m['avatarUrl'] as String?,
        isAdmin: m['admin'] as bool? ?? false,
        isConnected: m['connected'] as bool? ?? false,
        isHidden: m['hide'] as bool? ?? false,
        unreadCount: m['unreadCount'] as int? ?? 0,
        lastMessageReadId: m['lastMessageReadId'] as String?,
        viewMessagesFrom: m['viewMessagesFrom'] != null
            ? DateTime.parse(m['viewMessagesFrom'] as String)
            : null,
      );
    }).toList();

    // Parse groupType
    GroupType? parsedGroupType;
    if (groupType != null) {
      parsedGroupType = groupType!.toLowerCase() == 'public'
          ? GroupType.public
          : GroupType.private;
    }

    return Chat(
      id: serverId,
      name: name,
      avatarUrl: avatarUrl,
      description: description,
      groupType: parsedGroupType,
      creatorId: creatorId,
      members: members,
      lastMessageTime: lastMessageTime,
      lastMessagePreview: lastMessagePreview,
      unreadCount: unreadCount,
      type: type,
      participantIds: participantIds,
    );
  }

  /// Get chat display name
  String getDisplayName(String currentUserId, Map<String, String> userNames) {
    if (type != ChatType.direct) {
      return name ?? 'Unnamed Group';
    }

    // For direct chats, use the other user's name
    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
    
    return userNames[otherUserId] ?? 'Unknown User';
  }

  /// Check if user is admin of this chat
  bool isUserAdmin(String userId) {
    return adminId == userId;
  }

  /// Check if user is a participant of this chat
  bool hasParticipant(String userId) {
    return participantIds.contains(userId);
  }

  /// Add multiple participants to the chat
  ChatModel addParticipants(List<String> userIds) {
    if (userIds.isEmpty) return this;
    
    final newParticipants = List<String>.from(participantIds);
    for (final userId in userIds) {
      if (!newParticipants.contains(userId)) {
        newParticipants.add(userId);
      }
    }
    
    return copyWith(
      participantIds: newParticipants,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove multiple participants from the chat
  ChatModel removeParticipants(List<String> userIds) {
    if (userIds.isEmpty) return this;
    
    final newParticipants = List<String>.from(participantIds);
    newParticipants.removeWhere((id) => userIds.contains(id));
    
    return copyWith(
      participantIds: newParticipants,
      updatedAt: DateTime.now(),
    );
  }

  /// Change the admin of the chat
  ChatModel changeAdmin(String newAdminId) {
    if (!participantIds.contains(newAdminId)) {
      throw ArgumentError('New admin must be a participant of the chat');
    }
    
    return copyWith(
      adminId: newAdminId,
      updatedAt: DateTime.now(),
    );
  }

  /// Change the name of the chat (for groups and channels)
  ChatModel changeName(String newName) {
    if (type == ChatType.direct) {
      throw UnsupportedError('Cannot change name of direct chat');
    }
    
    return copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
  }

  /// Change the avatar of the chat
  ChatModel changeAvatar(String newAvatarUrl) {
    return copyWith(
      avatarUrl: newAvatarUrl,
      updatedAt: DateTime.now(),
    );
  }

  /// Update the metadata of the chat
  ChatModel updateMetadata(Map<String, dynamic> newMetadata) {
    final currentMetadata = metadataMap ?? {};
    currentMetadata.addAll(newMetadata);
    
    return copyWith(
      metadata: jsonEncode(currentMetadata),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if the chat has any messages
  bool get hasMessages => lastMessageId != null;

  /// Check if the chat is a group
  bool get isGroup => type == ChatType.group;

  /// Check if the chat is a direct chat
  bool get isDirect => type == ChatType.direct;

  /// Check if the chat is a channel
  bool get isChannel => type == ChatType.channel;

  /// Get participant count
  int get participantCount => participantIds.length;
  
  /// Check if the chat is active
  bool get isActive {
    if (lastMessageTime == null) return false;
    final now = DateTime.now();
    return now.difference(lastMessageTime!).inDays < 30; // Active if has messages in last 30 days
  }
} 