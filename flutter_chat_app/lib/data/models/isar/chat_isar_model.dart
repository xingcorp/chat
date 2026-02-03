// import 'package:isar/isar.dart'; // DISABLED - Isar v4 compatibility
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

/// **ENTERPRISE ISAR CHAT MODEL**
///
/// High-performance Isar database model for Chat entity optimized for
/// messaging apps with millions of users like WhatsApp/Telegram.
///
/// **Performance Features:**
/// - Binary serialization for blazing fast I/O
/// - Multi-column indexes for complex queries
/// - Efficient memory usage with lazy loading
/// - Real-time watch queries for live updates
///
/// **Indexes Optimized For:**
/// - Chat list sorting by lastMessageTime (DESC)
/// - Participant-based chat lookup
/// - Chat type filtering (direct/group)
/// - Unread count queries
/// - Search by chat name
///
/// **Architecture**: Enterprise messaging database optimization

// part 'chat_isar_model.g.dart'; // DISABLED - Isar v4 compatibility

// @collection // DISABLED - Isar v4 compatibility
class ChatIsarModel {
  /// **Primary key - Auto-generated ID**
  late int id; // Changed from Id to int for compatibility

  /// **Chat ID from server - Unique identifier**
  // @Index(unique: true) // DISABLED - Isar v4 compatibility
  late String chatId;

  /// **Chat name - Indexed for search**
  // @Index() // DISABLED - Isar v4 compatibility
  String? name;

  /// **Avatar URL for chat**
  String? avatarUrl;

  /// **Chat type - Indexed for filtering**
  // @Index() // DISABLED - Isar v4 compatibility
  late ChatTypeIsar type;

  /// **Participant IDs - Indexed for participant lookup**
  // @Index() // DISABLED - Isar v4 compatibility
  late List<String> participantIds;

  /// **Unread message count - Indexed for badge queries**
  // @Index() // DISABLED - Isar v4 compatibility
  int unreadCount = 0;

  /// **Last message timestamp - Primary sort index (DESC)**
  // @Index() // DISABLED - Isar v4 compatibility
  DateTime? lastMessageTime;

  /// **Last message preview for chat list**
  String? lastMessagePreview;

  /// **Chat creation timestamp**
  DateTime? createdAt;

  /// **Last update timestamp**
  DateTime? updatedAt;

  /// **Is chat archived**
  // @Index() // DISABLED - Isar v4 compatibility
  bool isArchived = false;

  /// **Is chat muted**
  bool isMuted = false;

  /// **Chat description (for groups)**
  String? description;

  /// **Chat settings as JSON string**
  String? settingsJson;

  /// **Convert from domain entity to Isar model**
  static ChatIsarModel fromDomain(Chat chat) {
    return ChatIsarModel()
      ..chatId = chat.id
      ..name = chat.name
      ..avatarUrl = chat.avatarUrl
      ..type = ChatTypeIsar.values[chat.type.index]
      ..participantIds = List<String>.from(chat.participantIds)
      ..unreadCount = chat.unreadCount
      ..lastMessageTime = chat.lastMessageTime
      ..lastMessagePreview = chat.lastMessagePreview
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isArchived = false
      ..isMuted = false;
  }

  /// **Convert from Isar model to domain entity**
  Chat toDomain() {
    return Chat(
      id: chatId,
      name: name,
      avatarUrl: avatarUrl,
      type: ChatType.values[type.index],
      participantIds: List<String>.from(participantIds),
      unreadCount: unreadCount,
      lastMessageTime: lastMessageTime,
      lastMessagePreview: lastMessagePreview,
    );
  }

  /// **Update from domain entity**
  void updateFromDomain(Chat chat) {
    name = chat.name;
    avatarUrl = chat.avatarUrl;
    type = ChatTypeIsar.values[chat.type.index];
    participantIds = List<String>.from(chat.participantIds);
    unreadCount = chat.unreadCount;
    lastMessageTime = chat.lastMessageTime;
    lastMessagePreview = chat.lastMessagePreview;
    updatedAt = DateTime.now();
  }
}

/// **Chat type enum for Isar**
enum ChatTypeIsar {
  direct,
  group,
  channel,
  broadcast,
}

/// **ENTERPRISE ISAR QUERY EXTENSIONS**
///
/// High-performance query methods optimized for messaging app patterns
/// **Note**: Temporarily commented out until schemas are generated
/*
extension ChatIsarQueries on IsarCollection<int, ChatIsarModel> {
  /// **Get chats sorted by last message time (most recent first)**
  /// **Performance**: O(log n) with index, handles millions of chats
  Future<List<ChatIsarModel>> getChatsSortedByTime({
    int limit = 50,
    int offset = 0,
  }) async {
    return await where()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  /// **Get chats by participant ID**
  /// **Performance**: O(log n) with participant index
  Future<List<ChatIsarModel>> getChatsByParticipant(String participantId) async {
    return await where()
        .filter()
        .participantIdsElementContains(participantId)
        .and()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc()
        .findAll();
  }

  /// **Get direct chats only**
  /// **Performance**: O(log n) with type index
  Future<List<ChatIsarModel>> getDirectChats({
    int limit = 50,
    int offset = 0,
  }) async {
    return await where()
        .filter()
        .typeEqualTo(ChatTypeIsar.direct)
        .and()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  /// **Get group chats only**
  /// **Performance**: O(log n) with type index
  Future<List<ChatIsarModel>> getGroupChats({
    int limit = 50,
    int offset = 0,
  }) async {
    return await where()
        .filter()
        .typeEqualTo(ChatTypeIsar.group)
        .and()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  /// **Search chats by name**
  /// **Performance**: O(log n) with name index + text search
  Future<List<ChatIsarModel>> searchChatsByName(String query) async {
    return await where()
        .filter()
        .nameContains(query, caseSensitive: false)
        .and()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc()
        .limit(20)
        .findAll();
  }

  /// **Get chats with unread messages**
  /// **Performance**: O(log n) with unreadCount index
  Future<List<ChatIsarModel>> getChatsWithUnreadMessages() async {
    return await where()
        .filter()
        .unreadCountGreaterThan(0)
        .and()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc()
        .findAll();
  }

  /// **Get total unread count across all chats**
  /// **Performance**: O(n) but cached by Isar
  Future<int> getTotalUnreadCount() async {
    final chats = await where()
        .filter()
        .unreadCountGreaterThan(0)
        .and()
        .isArchivedEqualTo(false)
        .findAll();
    
    return chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
  }

  /// **Get archived chats**
  /// **Performance**: O(log n) with archived index
  Future<List<ChatIsarModel>> getArchivedChats({
    int limit = 50,
    int offset = 0,
  }) async {
    return await where()
        .filter()
        .isArchivedEqualTo(true)
        .sortByLastMessageTimeDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  /// **Watch chats for real-time updates**
  /// **Performance**: Real-time updates with minimal overhead
  Stream<List<ChatIsarModel>> watchChats({int limit = 50}) {
    return where()
        .filter()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  /// **Watch unread count for real-time badge updates**
  /// **Performance**: Efficient real-time unread count tracking
  Stream<int> watchUnreadCount() {
    return where()
        .filter()
        .unreadCountGreaterThan(0)
        .and()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)
        .map((chats) => chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount));
  }
}
*/
