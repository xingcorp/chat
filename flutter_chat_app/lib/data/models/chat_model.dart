import 'package:isar/isar.dart';
import 'dart:convert';

import 'package:flutter_chat_app/domain/entities/chat.dart' as domain;

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
  @Id()
  final int id;

  /// Server ID of the chat
  @Index(unique: true)
  final String serverId;

  /// Name of the chat (for groups and channels)
  final String? name;

  /// Type of the chat
  @enumValue
  final ChatType type;

  /// ID of the last message in the chat
  final String? lastMessageId;

  /// Text preview of the last message
  final String? lastMessagePreview;

  /// Timestamp of the last message
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
    this.id = 0,
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

  /// Create a chat from a map (legacy format)
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

  /// **Create ChatModel from Backend API Response**
  ///
  /// Maps backend conversation object to ChatModel.
  /// Backend uses different field names and structure.
  ///
  /// **Backend Fields:**
  /// - id, name, type, description, imgUrl, groupType
  /// - createdAt, lastMessageAt, lastMessageId
  /// - creator { id, fullname, avatarUrl }
  /// - members[] { id, userId, admin, unreadCount, user {...} }
  ///
  /// **Parameters:**
  /// - map: Backend conversation object
  /// - currentUserId: Current user's ID to extract unreadCount
  ///
  /// **Returns:** ChatModel instance
  factory ChatModel.fromBackendMap(
    Map<String, dynamic> map,
    String currentUserId,
  ) {
    // Extract members array
    final members = (map['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    // Extract participant IDs from members
    final participantIds = members
        .map((m) => m['userId'] as String?)
        .whereType<String>()
        .toList();
    
    // Find admin (first member with admin=true)
    final adminMember = members.firstWhere(
      (m) => m['admin'] == true,
      orElse: () => <String, dynamic>{},
    );
    final adminId = adminMember['userId'] as String?;
    
    // Find current user's member to get unreadCount
    final currentUserMember = members.firstWhere(
      (m) => m['userId'] == currentUserId,
      orElse: () => <String, dynamic>{},
    );
    final unreadCount = currentUserMember['unreadCount'] as int? ?? 0;
    
    // Parse type
    final typeStr = (map['type'] as String?)?.toLowerCase() ?? 'direct';
    final type = ChatType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ChatType.direct,
    );
    
    // Parse timestamps
    final createdAt = _parseTimestamp(map['createdAt']);
    final lastMessageTime = _parseTimestamp(map['lastMessageAt']);
    
    return ChatModel(
      serverId: map['id'] as String,
      name: map['name'] as String?,
      type: type,
      lastMessageId: map['lastMessageId'] as String?,
      lastMessagePreview: null, // Backend doesn't provide preview
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      participantIds: participantIds,
      adminId: adminId,
      avatarUrl: map['imgUrl'] as String?, // Backend uses imgUrl
      isMuted: false, // Backend doesn't provide this
      isPinned: false, // Backend doesn't provide this
      createdAt: createdAt,
      updatedAt: lastMessageTime,
      metadata: jsonEncode({
        'description': map['description'],
        'groupType': map['groupType'],
        'creator': map['creator'],
        'members': members,
      }),
    );
  }

  /// Parse timestamp from backend (milliseconds since epoch or DateTime string)
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is double) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    
    return DateTime.now();
  }

  /// Convert chat to a map (legacy format)
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

  /// **Convert ChatModel to Backend API Format**
  ///
  /// Converts ChatModel to format expected by backend mutations.
  /// Used for creating/updating groups.
  ///
  /// **Backend Expected Format:**
  /// - name: String
  /// - imgUrl: String (not avatarUrl)
  /// - description: String
  /// - groupType: String ("Public" | "Private")
  /// - memberIds: [String] (not participantIds)
  ///
  /// **Parameters:**
  /// - includeId: Whether to include conversationId (for updates)
  ///
  /// **Returns:** Map ready for backend API
  Map<String, dynamic> toBackendMap({bool includeId = false}) {
    final metadataMap = metadataMap;
    
    final result = <String, dynamic>{
      'name': name,
      'imgUrl': avatarUrl, // Backend expects imgUrl
      'description': metadataMap?['description'] as String?,
      'groupType': metadataMap?['groupType'] as String? ?? 'Private',
      'memberIds': participantIds, // Backend expects memberIds
    };
    
    if (includeId) {
      result['conversationId'] = serverId;
    }
    
    // Add adminIds if updating group
    if (includeId && adminId != null) {
      result['adminIds'] = [adminId];
    }
    
    return result;
  }

  /// Create a copy of this chat with changed fields
  ChatModel copyWith({
    int? id,
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
      id: id ?? this.id,
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

  /// Convert ChatModel to domain Chat entity
  domain.Chat toDomain() {
    return domain.Chat(
      id: serverId,
      name: name,
      avatarUrl: avatarUrl,
      lastMessageTime: lastMessageTime,
      lastMessagePreview: lastMessagePreview,
      unreadCount: unreadCount,
      type: _mapToDomainChatType(type),
      participantIds: participantIds,
    );
  }

  /// Map data layer ChatType to domain layer ChatType
  static domain.ChatType _mapToDomainChatType(ChatType dataType) {
    switch (dataType) {
      case ChatType.direct:
        return domain.ChatType.direct;
      case ChatType.group:
        return domain.ChatType.group;
      case ChatType.channel:
        return domain.ChatType.channel;
    }
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