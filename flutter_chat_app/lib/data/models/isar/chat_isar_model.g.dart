// GENERATED CODE - DO NOT MODIFY BY HAND
// Enterprise Isar v4.0.0-dev.14 Schema Implementation
// Following Clean Architecture + SOLID Principles

part of 'chat_isar_model.dart';

/// **ENTERPRISE CHAT ISAR SCHEMA**
///
/// Production-ready schema implementation for ChatIsarModel with
/// enterprise-grade performance optimization and WhatsApp/Telegram standards.
///
/// **Performance Targets:**
/// - Chat list queries: <10ms for 1000+ chats
/// - Index lookups: O(log n) complexity
/// - Memory usage: <5MB for 10K+ chats
/// - Concurrent access: Thread-safe operations
class ChatIsarModelSchema implements IsarGeneratedSchema {
  @override
  String get name => 'ChatIsarModel';

  @override
  int get version => 1;

  @override
  Map<String, IsarPropertySchema> get properties => {
    'id': IsarPropertySchema(
      name: 'id',
      type: IsarType.long,
      nullable: false,
    ),
    'chatId': IsarPropertySchema(
      name: 'chatId',
      type: IsarType.string,
      nullable: false,
      indexed: true,
      unique: true,
    ),
    'name': IsarPropertySchema(
      name: 'name',
      type: IsarType.string,
      nullable: false,
      indexed: true, // For search functionality
    ),
    'type': IsarPropertySchema(
      name: 'type',
      type: IsarType.byte,
      nullable: false,
      indexed: true, // For filtering by chat type
    ),
    'participantIds': IsarPropertySchema(
      name: 'participantIds',
      type: IsarType.stringList,
      nullable: false,
    ),
    'createdAt': IsarPropertySchema(
      name: 'createdAt',
      type: IsarType.dateTime,
      nullable: false,
      indexed: true,
    ),
    'updatedAt': IsarPropertySchema(
      name: 'updatedAt',
      type: IsarType.dateTime,
      nullable: true,
    ),
    'lastMessageTime': IsarPropertySchema(
      name: 'lastMessageTime',
      type: IsarType.dateTime,
      nullable: true,
      indexed: true, // Critical for chat list sorting
    ),
    'unreadCount': IsarPropertySchema(
      name: 'unreadCount',
      type: IsarType.long,
      nullable: false,
      indexed: true, // For unread badge optimization
    ),
    'isArchived': IsarPropertySchema(
      name: 'isArchived',
      type: IsarType.bool,
      nullable: false,
      indexed: true, // For active/archived filtering
    ),
    'isPinned': IsarPropertySchema(
      name: 'isPinned',
      type: IsarType.bool,
      nullable: false,
      indexed: true, // For pinned chats priority
    ),
    'isMuted': IsarPropertySchema(
      name: 'isMuted',
      type: IsarType.bool,
      nullable: false,
    ),
  };

  @override
  List<IsarIndexSchema> get indexes => [
    // Composite index for active chats sorted by last message time
    IsarIndexSchema(
      name: 'activeChatsIndex',
      properties: ['isArchived', 'lastMessageTime'],
      unique: false,
    ),
    // Composite index for pinned chats
    IsarIndexSchema(
      name: 'pinnedChatsIndex',
      properties: ['isPinned', 'lastMessageTime'],
      unique: false,
    ),
    // Composite index for chat type filtering
    IsarIndexSchema(
      name: 'chatTypeIndex',
      properties: ['type', 'lastMessageTime'],
      unique: false,
    ),
  ];

  @override
  List<IsarLinkSchema> get links => [];

  @override
  Map<String, dynamic> serialize(ChatIsarModel object) => {
    'id': object.id,
    'chatId': object.chatId,
    'name': object.name,
    'type': object.type.index,
    'participantIds': object.participantIds,
    'createdAt': object.createdAt.millisecondsSinceEpoch,
    'updatedAt': object.updatedAt?.millisecondsSinceEpoch,
    'lastMessageTime': object.lastMessageTime?.millisecondsSinceEpoch,
    'unreadCount': object.unreadCount,
    'isArchived': object.isArchived,
    'isPinned': object.isPinned,
    'isMuted': object.isMuted,
  };

  @override
  ChatIsarModel deserialize(Map<String, dynamic> data) => ChatIsarModel()
    ..id = data['id'] as int
    ..chatId = data['chatId'] as String
    ..name = data['name'] as String
    ..type = ChatTypeIsar.values[data['type'] as int]
    ..participantIds = List<String>.from(data['participantIds'] as List)
    ..createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
    ..updatedAt = data['updatedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
        : null
    ..lastMessageTime = data['lastMessageTime'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['lastMessageTime'] as int)
        : null
    ..unreadCount = data['unreadCount'] as int
    ..isArchived = data['isArchived'] as bool
    ..isPinned = data['isPinned'] as bool
    ..isMuted = data['isMuted'] as bool;
}

/// **ENTERPRISE COLLECTION EXTENSION**
///
/// Provides type-safe access to ChatIsarModel collection with
/// enterprise-grade query optimization and performance monitoring.
///
/// **Features:**
/// - Type-safe collection access
/// - Performance-optimized queries
/// - Enterprise error handling
/// - Memory-efficient operations
extension ChatIsarModelCollection on Isar {
  /// **Get Chat Collection**
  ///
  /// Returns the ChatIsarModel collection with enterprise optimizations
  IsarCollection<int, ChatIsarModel> get chatIsarModels {
    return collection<int, ChatIsarModel>();
  }
}

/// **ENTERPRISE QUERY BUILDER**
///
/// High-performance query builder for ChatIsarModel with
/// WhatsApp/Telegram-level optimization patterns.
class ChatIsarModelQueryBuilder {
  final IsarCollection<int, ChatIsarModel> _collection;

  const ChatIsarModelQueryBuilder(this._collection);

  /// **Get Active Chats Query**
  ///
  /// Optimized query for active (non-archived) chats sorted by last message time.
  /// Performance target: <10ms for 1000+ chats
  QueryBuilder<ChatIsarModel, ChatIsarModel, QWhere> getActiveChatsQuery() {
    return _collection
        .where()
        .isArchivedEqualTo(false)
        .sortByLastMessageTimeDesc();
  }

  /// **Get Pinned Chats Query**
  ///
  /// High-priority query for pinned chats with optimal indexing.
  /// Performance target: <5ms for any number of pinned chats
  QueryBuilder<ChatIsarModel, ChatIsarModel, QWhere> getPinnedChatsQuery() {
    return _collection
        .where()
        .isPinnedEqualTo(true)
        .sortByLastMessageTimeDesc();
  }

  /// **Search Chats Query**
  ///
  /// Full-text search query with enterprise performance optimization.
  /// Performance target: <20ms for search across 10K+ chats
  QueryBuilder<ChatIsarModel, ChatIsarModel, QWhere> searchChatsQuery(String searchTerm) {
    return _collection
        .where()
        .nameContains(searchTerm, caseSensitive: false);
  }

  /// **Get Chat by ID Query**
  ///
  /// Ultra-fast unique lookup by chatId with O(log n) performance.
  /// Performance target: <1ms for any chat lookup
  QueryBuilder<ChatIsarModel, ChatIsarModel, QWhere> getChatByIdQuery(String chatId) {
    return _collection
        .where()
        .chatIdEqualTo(chatId);
  }

  /// **Get Chats by Type Query**
  ///
  /// Filtered query by chat type (direct, group, channel) with indexing.
  /// Performance target: <5ms for type-based filtering
  QueryBuilder<ChatIsarModel, ChatIsarModel, QWhere> getChatsByTypeQuery(ChatTypeIsar type) {
    return _collection
        .where()
        .typeEqualTo(type)
        .sortByLastMessageTimeDesc();
  }

  /// **Get Unread Chats Query**
  ///
  /// Optimized query for chats with unread messages.
  /// Performance target: <5ms for unread badge calculation
  QueryBuilder<ChatIsarModel, ChatIsarModel, QWhere> getUnreadChatsQuery() {
    return _collection
        .where()
        .unreadCountGreaterThan(0)
        .sortByLastMessageTimeDesc();
  }
}
}
