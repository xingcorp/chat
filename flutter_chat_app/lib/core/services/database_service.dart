import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/chat_draft_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/data/models/offline_operation_model.dart';
import 'package:flutter_chat_app/data/models/sync_metadata_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'dart:async';

/// Service class responsible for managing the Isar database instance
/// and providing methods for database operations.
///
/// Uses manual DI registration in core_module.dart due to async initialization.
/// @preResolve annotation removed - now registered manually.
class DatabaseService {
  final IDatabaseImplementation _implementation;
  bool _isInitialized = false;

  /// Private constructor with implementation
  DatabaseService._(this._implementation);

  /// Factory method for manual DI registration
  ///
  /// Creates platform-specific implementation and initializes the database.
  /// Called by core_module.dart during DI setup.
  static Future<DatabaseService> create() async {
    // Create platform-specific implementation
    final implementation =
        kIsWeb ? WebDatabaseImplementation() : NativeDatabaseImplementation();

    // Create service instance
    final service = DatabaseService._(implementation);

    // Initialize database
    await service.initialize();

    debugPrint(
        'DatabaseService created for ${kIsWeb ? "web" : "native"} platform');

    return service;
  }

  /// Returns whether the database is initialized
  bool get isInitialized => _isInitialized;

  /// Returns the Isar instance
  Isar get isar => _implementation.isar;

  /// Initializes the database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _implementation.initialize();
      _isInitialized = true;
      debugPrint(
          'Isar DB initialized for ${kIsWeb ? 'web' : 'native'} platform');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  /// Closes the database
  Future<void> close() async {
    if (!_isInitialized) return;
    await _implementation.close();
    _isInitialized = false;
    debugPrint('Isar DB closed');
  }

  /// Clears all data in the database
  Future<void> clearAllData() async {
    if (!_isInitialized) await initialize();
    await _implementation.clearAllData();
    debugPrint('Isar DB cleared');
  }

  /// Performs a database backup
  Future<String?> backup() async {
    if (!_isInitialized) return null;
    return _implementation.backup();
  }

  /// Export database to JSON format
  Future<Map<String, dynamic>> exportToJson() async {
    if (!_isInitialized) await initialize();

    final chats = await getAllChats();
    final messages = await getAllMessages();
    final users = await getAllUsers();

    return {
      'chats': chats.map((c) => c.toMap()).toList(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'users': users.map((u) => u.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Import database from JSON format
  Future<bool> importFromJson(Map<String, dynamic> data) async {
    if (!_isInitialized) await initialize();

    try {
      await _implementation.importFromJson(data);
      debugPrint('Database imported successfully');
      return true;
    } catch (e) {
      debugPrint('Error importing database: $e');
      return false;
    }
  }

  /// Returns instance of a collection
  IsarCollection<ID, OBJ> collection<ID, OBJ>() {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _implementation.collection<ID, OBJ>();
  }

  /// Watches for changes on a collection
  Stream<List<T>> watchCollection<T>() {
    return _implementation.watchCollection<T>();
  }

  /// Gets all objects from a collection
  Future<List<T>> getAll<T>() async {
    return _implementation.getAll<T>();
  }

  /// Saves an object to the database
  Future<int> save<T>(T object) async {
    if (!_isInitialized) await initialize();
    return _implementation.save<T>(object);
  }

  /// Saves multiple objects to the database
  Future<void> saveAll<T>(List<T> objects) async {
    if (!_isInitialized) await initialize();
    await _implementation.saveAll<T>(objects);
  }

  /// Deletes an object from the database
  Future<bool> delete<T>(int id) async {
    if (!_isInitialized) await initialize();
    return _implementation.delete<T>(id);
  }

  /// Gets all chats
  Future<List<ChatModel>> getAllChats() async {
    return _implementation.getAllChats();
  }

  /// Gets all messages
  Future<List<MessageModel>> getAllMessages() async {
    return _implementation.getAllMessages();
  }

  /// Gets all users
  Future<List<UserModel>> getAllUsers() async {
    return _implementation.getAllUsers();
  }

  /// Gets chat by ID
  Future<ChatModel?> getChatById(int id) async {
    return _implementation.getChatById(id);
  }

  /// Gets message by ID
  Future<MessageModel?> getMessageById(int id) async {
    return _implementation.getMessageById(id);
  }

  /// Gets user by ID
  Future<UserModel?> getUserById(int id) async {
    return _implementation.getUserById(id);
  }

  /// Gets all messages in a chat
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    return _implementation.getMessagesForChat(chatId);
  }

  /// Streams changes to messages in a chat
  Stream<List<MessageModel>> watchMessagesForChat(String chatId) {
    return _implementation.watchMessagesForChat(chatId);
  }

  /// Gets user by server ID
  Future<UserModel?> getUserByServerId(String serverId) async {
    return _implementation.getUserByServerId(serverId);
  }
}

/// Interface for database implementations
abstract class IDatabaseImplementation {
  /// The Isar instance
  Isar get isar;

  /// Initialize the database
  Future<void> initialize();

  /// Close the database
  Future<void> close();

  /// Clear all data in the database
  Future<void> clearAllData();

  /// Backup the database
  Future<String?> backup();

  /// Import data from JSON
  Future<void> importFromJson(Map<String, dynamic> data);

  /// Get a collection
  IsarCollection<ID, OBJ> collection<ID, OBJ>();

  /// Watch changes to a collection
  Stream<List<T>> watchCollection<T>();

  /// Get all objects in a collection
  Future<List<T>> getAll<T>();

  /// Save an object
  Future<int> save<T>(T object);

  /// Save multiple objects
  Future<void> saveAll<T>(List<T> objects);

  /// Delete an object
  Future<bool> delete<T>(int id);

  /// Get all chats
  Future<List<ChatModel>> getAllChats();

  /// Get all messages
  Future<List<MessageModel>> getAllMessages();

  /// Get all users
  Future<List<UserModel>> getAllUsers();

  /// Get chat by ID
  Future<ChatModel?> getChatById(int id);

  /// Get message by ID
  Future<MessageModel?> getMessageById(int id);

  /// Get user by ID
  Future<UserModel?> getUserById(int id);

  /// Get all messages in a chat
  Future<List<MessageModel>> getMessagesForChat(String chatId);

  /// Watch all messages in a chat
  Stream<List<MessageModel>> watchMessagesForChat(String chatId);

  /// Get user by server ID
  Future<UserModel?> getUserByServerId(String serverId);
}

/// Web implementation of the database
class WebDatabaseImplementation implements IDatabaseImplementation {
  late final Isar _isar;

  @override
  Isar get isar => _isar;

  @override
  Future<void> initialize() async {
    final schemas = [
      ChatModelSchema,
      ChatDraftModelSchema,
      MessageModelSchema,
      UserModelSchema,
      OfflineOperationModelSchema,
      SyncMetadataModelSchema,
    ];

    await Isar.initialize();

    _isar = Isar.open(
      schemas: schemas,
      directory: Isar.sqliteInMemory,
      engine: IsarEngine.sqlite,
      inspector: kDebugMode,
      name: 'chat_app_db',
    );
  }

  @override
  Future<void> close() async {
    _isar.close();
  }

  @override
  Future<void> clearAllData() async {
    _isar.write((isar) {
      isar.clear();
    });
  }

  @override
  Future<String?> backup() async {
    // Not supported on web
    return null;
  }

  @override
  Future<void> importFromJson(Map<String, dynamic> data) async {
    _isar.write((isar) {
      isar.clear();

      final users = (data['users'] as List?)
              ?.map((u) => UserModel.fromMap(u as Map<String, dynamic>))
              .toList() ??
          [];
      isar.userModels.putAll(users);

      final chats = (data['chats'] as List?)
              ?.map((c) => ChatModel.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [];
      isar.chatModels.putAll(chats);

      final messages = (data['messages'] as List?)
              ?.map((m) => MessageModel.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [];
      isar.messageModels.putAll(messages);
    });
  }

  @override
  IsarCollection<ID, OBJ> collection<ID, OBJ>() {
    return _isar.collection<ID, OBJ>();
  }

  @override
  Stream<List<T>> watchCollection<T>() {
    final collection = this.collection<int, T>();
    // Create a periodic stream that fetches data every 1 second
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => collection.where().findAll());
  }

  @override
  Future<List<T>> getAll<T>() async {
    return collection<int, T>().where().findAll();
  }

  @override
  Future<int> save<T>(T object) async {
    await _isar.write((isar) async {
      collection<int, T>().put(object);
    });
    if (object is ChatModel) return object.id ?? 0;
    if (object is MessageModel) return object.id ?? 0;
    if (object is UserModel) return object.id ?? 0;
    throw ArgumentError(
        'Object type does not have a retrievable ID after save');
  }

  @override
  Future<void> saveAll<T>(List<T> objects) async {
    _isar.write((isar) {
      collection<int, T>().putAll(objects);
    });
  }

  @override
  Future<bool> delete<T>(int id) async {
    return await _isar.write((isar) async {
      return collection<int, T>().delete(id);
    });
  }

  @override
  Future<List<ChatModel>> getAllChats() async {
    return _isar.chatModels.where().findAll();
  }

  @override
  Future<List<MessageModel>> getAllMessages() async {
    return _isar.messageModels.where().findAll();
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return _isar.userModels.where().findAll();
  }

  @override
  Future<ChatModel?> getChatById(int id) async {
    return _isar.chatModels.get(id);
  }

  @override
  Future<MessageModel?> getMessageById(int id) async {
    return _isar.messageModels.get(id);
  }

  @override
  Future<UserModel?> getUserById(int id) async {
    return _isar.userModels.get(id);
  }

  @override
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    return _isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAt()
        .findAll();
  }

  @override
  Stream<List<MessageModel>> watchMessagesForChat(String chatId) {
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => getMessagesForChat(chatId));
  }

  @override
  Future<UserModel?> getUserByServerId(String serverId) async {
    return _isar.userModels.where().serverIdEqualTo(serverId).findFirst();
  }
}

/// Native implementation of the database (Android, iOS, Desktop)
class NativeDatabaseImplementation implements IDatabaseImplementation {
  late final Isar _isar;

  @override
  Isar get isar => _isar;

  @override
  Future<void> initialize() async {
    final schemas = [
      ChatModelSchema,
      ChatDraftModelSchema,
      MessageModelSchema,
      UserModelSchema,
      OfflineOperationModelSchema,
      SyncMetadataModelSchema,
    ];

    final dir = await getApplicationDocumentsDirectory();
    _isar = Isar.open(
      schemas: schemas,
      directory: dir.path,
      inspector: kDebugMode,
      name: 'chat_app_db',
    );
  }

  @override
  Future<void> close() async {
    _isar.close();
  }

  @override
  Future<void> clearAllData() async {
    _isar.write((isar) {
      isar.clear();
    });
  }

  @override
  Future<String?> backup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupPath =
          '${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.isar';

      _isar.copyToFile(backupPath);
      debugPrint('Database backed up to: $backupPath');

      return backupPath;
    } catch (e) {
      debugPrint('Error during database backup: $e');
      return null;
    }
  }

  @override
  Future<void> importFromJson(Map<String, dynamic> data) async {
    _isar.write((isar) {
      isar.clear();

      final users = (data['users'] as List?)
              ?.map((u) => UserModel.fromMap(u as Map<String, dynamic>))
              .toList() ??
          [];
      isar.userModels.putAll(users);

      final chats = (data['chats'] as List?)
              ?.map((c) => ChatModel.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [];
      isar.chatModels.putAll(chats);

      final messages = (data['messages'] as List?)
              ?.map((m) => MessageModel.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [];
      isar.messageModels.putAll(messages);
    });
  }

  @override
  IsarCollection<ID, OBJ> collection<ID, OBJ>() {
    return _isar.collection<ID, OBJ>();
  }

  @override
  Stream<List<T>> watchCollection<T>() {
    final collection = this.collection<int, T>();
    return collection.where().watch(fireImmediately: true);
  }

  @override
  Future<List<T>> getAll<T>() async {
    return collection<int, T>().where().findAll();
  }

  @override
  Future<int> save<T>(T object) async {
    await _isar.write((isar) async {
      collection<int, T>().put(object);
    });
    if (object is ChatModel) return object.id ?? 0;
    if (object is MessageModel) return object.id ?? 0;
    if (object is UserModel) return object.id ?? 0;
    throw ArgumentError(
        'Object type does not have a retrievable ID after save');
  }

  @override
  Future<void> saveAll<T>(List<T> objects) async {
    _isar.write((isar) {
      collection<int, T>().putAll(objects);
    });
  }

  @override
  Future<bool> delete<T>(int id) async {
    return await _isar.write((isar) async {
      return collection<int, T>().delete(id);
    });
  }

  @override
  Future<List<ChatModel>> getAllChats() async {
    return _isar.chatModels.where().findAll();
  }

  @override
  Future<List<MessageModel>> getAllMessages() async {
    return _isar.messageModels.where().findAll();
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return _isar.userModels.where().findAll();
  }

  @override
  Future<ChatModel?> getChatById(int id) async {
    return _isar.chatModels.get(id);
  }

  @override
  Future<MessageModel?> getMessageById(int id) async {
    return _isar.messageModels.get(id);
  }

  @override
  Future<UserModel?> getUserById(int id) async {
    return _isar.userModels.get(id);
  }

  @override
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    return _isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAt()
        .findAll();
  }

  @override
  Stream<List<MessageModel>> watchMessagesForChat(String chatId) {
    return _isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  @override
  Future<UserModel?> getUserByServerId(String serverId) async {
    return _isar.userModels.where().serverIdEqualTo(serverId).findFirst();
  }

  /// Watch chats collection changes
  Stream<List<ChatModel>> watchChats() {
    return isar.chatModels.where().watch(fireImmediately: true);
  }

  /// Get chat by server ID
  Future<ChatModel?> getChatByServerId(String serverId) async {
    return isar.chatModels.where().serverIdEqualTo(serverId).findFirst();
  }

  /// Get message by server ID
  Future<MessageModel?> getMessageByServerId(String serverId) async {
    return isar.messageModels.where().serverIdEqualTo(serverId).findFirst();
  }

  /// Get message by local ID
  Future<MessageModel?> getMessageByLocalId(String localId) async {
    return isar.messageModels.where().localIdEqualTo(localId).findFirst();
  }

  /// Watch users collection changes
  Stream<List<UserModel>> watchUsers() {
    return isar.userModels.where().watch(fireImmediately: true);
  }

  /// Save chat — atomic upsert by serverId.
  ///
  /// Isar v4 `put()` upserts by `@Id()` only, not by unique index.
  /// To prevent duplicates when the Isar int ID differs between callers,
  /// we delete any stale record with the same serverId in the same txn.
  Future<void> saveChat(ChatModel chat) async {
    isar.write((isar) {
      final existing =
          isar.chatModels.where().serverIdEqualTo(chat.serverId).findFirst();
      if (existing != null && existing.id != chat.id) {
        isar.chatModels.delete(existing.id);
      }
      isar.chatModels.put(chat);
    });
  }

  /// Save multiple chats in a single write transaction — O(1) txn overhead.
  ///
  /// For each chat, removes any stale record whose serverId matches but whose
  /// Isar int ID differs (same dedup logic as [saveChat]), then bulk-inserts.
  Future<void> saveChatsBatch(List<ChatModel> chats) async {
    if (chats.isEmpty) return;
    isar.write((isar) {
      for (final chat in chats) {
        final existing =
            isar.chatModels.where().serverIdEqualTo(chat.serverId).findFirst();
        if (existing != null && existing.id != chat.id) {
          isar.chatModels.delete(existing.id);
        }
      }
      isar.chatModels.putAll(chats);
    });
  }

  /// Save message
  /// Note: Isar v4 treats id=0 as valid ID, not auto-increment.
  /// For new messages (id=0), assigns autoIncrement ID before saving.
  Future<void> saveMessage(MessageModel message) async {
    isar.write((isar) {
      final toSave = message.id == 0
          ? message.copyWith(id: isar.messageModels.autoIncrement())
          : message;
      isar.messageModels.put(toSave);
    });
  }

  /// Atomic upsert message — resolves existing record by serverId or localId
  /// before writing. Prevents duplicate messages regardless of ID source.
  ///
  /// Lookup priority:
  ///   1. serverId (strongest server-side identity)
  ///   2. Cross-reference: existing.localId == incoming.serverId
  ///      (handles client-sent message being fetched from server)
  ///   3. localId (for pending messages without serverId)
  void saveMessageUpsert(MessageModel message) {
    isar.write((isar) {
      final existing = _resolveExistingMessage(isar, message);
      final MessageModel toSave;
      if (existing != null) {
        toSave = message.copyWith(id: existing.id);
      } else {
        // Isar v4: id=0 is a valid ID, NOT auto-increment.
        // Must explicitly get next ID for new records.
        final newId = isar.messageModels.autoIncrement();
        toSave = message.copyWith(id: newId);
      }
      isar.messageModels.put(toSave);
      debugPrint(
          '[DB-DIAG] saveMessageUpsert(single): '
          'chatId="${message.chatId}" '
          'serverId="${message.serverId}" '
          'existingId=${existing?.id} '
          'saveId=${toSave.id}');
    });
  }

  /// Batch atomic upsert messages in a single write transaction.
  ///
  /// Uses individual `put()` calls instead of `putAll()` to avoid
  /// Isar v4-dev issue where batch putAll with id=0 (auto-increment)
  /// combined with unique indexes silently fails to persist records.
  /// Each put() within the same write transaction is still atomic.
  void saveMessagesUpsert(List<MessageModel> messages) {
    if (messages.isEmpty) return;

    // DEBUG: count BEFORE write — total in Isar (no filter)
    final totalBefore = isar.messageModels.where().findAll().length;
    final chatId = messages.first.chatId;
    final byChatBefore = isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .findAll()
        .length;
    debugPrint(
        '[DB-DIAG] saveMessagesUpsert START: '
        'input=${messages.length} chatId=$chatId '
        'totalBefore=$totalBefore byChatBefore=$byChatBefore');

    isar.write((isar) {
      var newCount = 0;
      var updateCount = 0;
      for (final message in messages) {
        final existing = _resolveExistingMessage(isar, message);
        final MessageModel toSave;
        if (existing != null) {
          toSave = message.copyWith(id: existing.id);
          updateCount++;
        } else {
          // Isar v4: id=0 is a valid ID, NOT auto-increment.
          // Must explicitly get next ID for new records.
          final newId = isar.messageModels.autoIncrement();
          toSave = message.copyWith(id: newId);
          newCount++;
        }
        // DEBUG: log first 3 + last message details
        if (newCount + updateCount <= 3 ||
            newCount + updateCount == messages.length) {
          debugPrint(
              '[DB-DIAG]   msg[${newCount + updateCount - 1}]: '
              'chatId="${message.chatId}" '
              'serverId="${message.serverId}" '
              'localId="${message.localId}" '
              'existingId=${existing?.id} '
              'saveId=${toSave.id}');
        }
        isar.messageModels.put(toSave);
      }
      debugPrint(
          '[DB-DIAG] saveMessagesUpsert WROTE: '
          'new=$newCount updated=$updateCount');
    });

    // DEBUG: count AFTER write — verify persistence
    final totalAfter = isar.messageModels.where().findAll().length;
    final byChatAfter = isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .findAll()
        .length;
    debugPrint(
        '[DB-DIAG] saveMessagesUpsert END: '
        'totalAfter=$totalAfter byChatAfter=$byChatAfter '
        'delta=${totalAfter - totalBefore}');
  }

  /// Core identity resolution — finds existing record for a message.
  ///
  /// Solves the identity mismatch problem:
  ///   Client sends: {localId: "UUID-1", serverId: null} → later updated to {serverId: "S1"}
  ///   Server sync:  {localId: "S1",     serverId: "S1"}
  ///   → Must recognize these as the SAME message.
  MessageModel? _resolveExistingMessage(Isar isar, MessageModel incoming) {
    // Priority 1: Match by serverId (strongest identity)
    if (incoming.serverId != null && incoming.serverId!.isNotEmpty) {
      final byServerId = isar.messageModels
          .where()
          .serverIdEqualTo(incoming.serverId!)
          .findFirst();
      if (byServerId != null) return byServerId;

      // Priority 2: Cross-reference — existing.localId == incoming.serverId
      final byLocalIdAsServerId = isar.messageModels
          .where()
          .localIdEqualTo(incoming.serverId!)
          .findFirst();
      if (byLocalIdAsServerId != null) return byLocalIdAsServerId;
    }

    // Priority 3: Match by localId (for pending messages)
    final byLocalId = isar.messageModels
        .where()
        .localIdEqualTo(incoming.localId)
        .findFirst();
    return byLocalId;
  }

  /// Query messages by status — uses indexed field for O(log n) performance.
  List<MessageModel> getMessagesByStatus(MessageStatus status) {
    return isar.messageModels
        .where()
        .statusEqualTo(status)
        .findAll();
  }

  /// Watch recent messages for a chat with limit and descending order.
  ///
  /// Uses Isar watch + Dart take() for limiting since Isar v4 QueryBuilder
  /// does not support .limit() in the chain before .watch().
  Stream<List<MessageModel>> watchRecentMessagesForChat(
    String chatId, {
    int limit = 20,
  }) {
    return _isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((messages) => messages.take(limit).toList());
  }

  /// Get messages for chat with cursor-based pagination.
  List<MessageModel> getMessagesWithCursor({
    required String chatId,
    required int limit,
    DateTime? beforeTimestamp,
  }) {
    final allForChat = _isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtDesc()
        .findAll();

    if (beforeTimestamp != null) {
      return allForChat
          .where((m) => m.createdAt.isBefore(beforeTimestamp))
          .take(limit)
          .toList();
    }

    return allForChat.take(limit).toList();
  }

  /// Delete all messages for a chat.
  void deleteMessagesForChat(String chatId) {
    isar.write((isar) {
      isar.messageModels.where().chatIdEqualTo(chatId).deleteAll();
    });
  }

  /// Save user
  Future<void> saveUser(UserModel user) async {
    isar.write((isar) {
      isar.userModels.put(user);
    });
  }

  /// Delete chat
  Future<void> deleteChat(int id) async {
    isar.write((isar) {
      isar.chatModels.delete(id);
    });
  }

  /// Delete message
  Future<void> deleteMessage(int id) async {
    isar.write((isar) {
      isar.messageModels.delete(id);
    });
  }

  /// Delete user
  Future<void> deleteUser(int id) async {
    isar.write((isar) {
      isar.userModels.delete(id);
    });
  }
}
extension WebDatabaseImplementationExtension on WebDatabaseImplementation {
  /// Watch chats collection changes
  Stream<List<ChatModel>> watchChats() {
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => isar.chatModels.where().findAll());
  }

  /// Get chat by server ID
  Future<ChatModel?> getChatByServerId(String serverId) async {
    return isar.chatModels.where().serverIdEqualTo(serverId).findFirst();
  }

  /// Get message by server ID
  Future<MessageModel?> getMessageByServerId(String serverId) async {
    return isar.messageModels.where().serverIdEqualTo(serverId).findFirst();
  }

  /// Get message by local ID
  Future<MessageModel?> getMessageByLocalId(String localId) async {
    return isar.messageModels.where().localIdEqualTo(localId).findFirst();
  }

  /// Watch users collection changes
  Stream<List<UserModel>> watchUsers() {
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => isar.userModels.where().findAll());
  }

  /// Save chat — atomic upsert by serverId (Web implementation).
  ///
  /// Same dedup-safe logic as NativeDatabaseImplementation.saveChat.
  Future<void> saveChat(ChatModel chat) async {
    isar.write((isar) {
      final existing =
          isar.chatModels.where().serverIdEqualTo(chat.serverId).findFirst();
      if (existing != null && existing.id != chat.id) {
        isar.chatModels.delete(existing.id);
      }
      isar.chatModels.put(chat);
    });
  }

  /// Save multiple chats in a single write transaction (Web implementation).
  Future<void> saveChatsBatch(List<ChatModel> chats) async {
    if (chats.isEmpty) return;
    isar.write((isar) {
      for (final chat in chats) {
        final existing =
            isar.chatModels.where().serverIdEqualTo(chat.serverId).findFirst();
        if (existing != null && existing.id != chat.id) {
          isar.chatModels.delete(existing.id);
        }
      }
      isar.chatModels.putAll(chats);
    });
  }

  /// Save message
  /// Note: Isar v4 treats id=0 as valid ID, not auto-increment.
  Future<void> saveMessage(MessageModel message) async {
    isar.write((isar) {
      final toSave = message.id == 0
          ? message.copyWith(id: isar.messageModels.autoIncrement())
          : message;
      isar.messageModels.put(toSave);
    });
  }

  /// Atomic upsert message (Web) — same logic as NativeDatabaseImplementation.
  void saveMessageUpsert(MessageModel message) {
    isar.write((isar) {
      final existing = _resolveExistingMessage(isar, message);
      final MessageModel toSave;
      if (existing != null) {
        toSave = message.copyWith(id: existing.id);
      } else {
        // Isar v4: id=0 is a valid ID, NOT auto-increment.
        final newId = isar.messageModels.autoIncrement();
        toSave = message.copyWith(id: newId);
      }
      isar.messageModels.put(toSave);
    });
  }

  /// Batch atomic upsert messages (Web).
  ///
  /// Uses individual `put()` calls instead of `putAll()` — same fix
  /// as NativeDatabaseImplementation to avoid Isar v4-dev batch issue.
  void saveMessagesUpsert(List<MessageModel> messages) {
    if (messages.isEmpty) return;

    // DEBUG: count BEFORE write
    final totalBefore = isar.messageModels.where().findAll().length;
    final chatId = messages.first.chatId;
    final byChatBefore = isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .findAll()
        .length;
    debugPrint(
        '[DB-DIAG] saveMessagesUpsert(Web) START: '
        'input=${messages.length} chatId=$chatId '
        'totalBefore=$totalBefore byChatBefore=$byChatBefore');

    isar.write((isar) {
      var newCount = 0;
      var updateCount = 0;
      for (final message in messages) {
        final existing = _resolveExistingMessage(isar, message);
        final MessageModel toSave;
        if (existing != null) {
          toSave = message.copyWith(id: existing.id);
          updateCount++;
        } else {
          // Isar v4: id=0 is a valid ID, NOT auto-increment.
          final newId = isar.messageModels.autoIncrement();
          toSave = message.copyWith(id: newId);
          newCount++;
        }
        if (newCount + updateCount <= 3 ||
            newCount + updateCount == messages.length) {
          debugPrint(
              '[DB-DIAG]   msg[${newCount + updateCount - 1}]: '
              'chatId="${message.chatId}" '
              'serverId="${message.serverId}" '
              'localId="${message.localId}" '
              'existingId=${existing?.id} '
              'saveId=${toSave.id}');
        }
        isar.messageModels.put(toSave);
      }
      debugPrint(
          '[DB-DIAG] saveMessagesUpsert(Web) WROTE: '
          'new=$newCount updated=$updateCount');
    });

    // DEBUG: count AFTER write
    final totalAfter = isar.messageModels.where().findAll().length;
    final byChatAfter = isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .findAll()
        .length;
    debugPrint(
        '[DB-DIAG] saveMessagesUpsert(Web) END: '
        'totalAfter=$totalAfter byChatAfter=$byChatAfter '
        'delta=${totalAfter - totalBefore}');
  }

  /// Core identity resolution (Web) — same as NativeDatabaseImplementation.
  MessageModel? _resolveExistingMessage(Isar isar, MessageModel incoming) {
    if (incoming.serverId != null && incoming.serverId!.isNotEmpty) {
      final byServerId = isar.messageModels
          .where()
          .serverIdEqualTo(incoming.serverId!)
          .findFirst();
      if (byServerId != null) return byServerId;

      final byLocalIdAsServerId = isar.messageModels
          .where()
          .localIdEqualTo(incoming.serverId!)
          .findFirst();
      if (byLocalIdAsServerId != null) return byLocalIdAsServerId;
    }

    final byLocalId = isar.messageModels
        .where()
        .localIdEqualTo(incoming.localId)
        .findFirst();
    return byLocalId;
  }

  /// Query messages by status (Web).
  List<MessageModel> getMessagesByStatus(MessageStatus status) {
    return isar.messageModels
        .where()
        .statusEqualTo(status)
        .findAll();
  }

  /// Watch recent messages for a chat (Web — polling fallback).
  Stream<List<MessageModel>> watchRecentMessagesForChat(
    String chatId, {
    int limit = 20,
  }) {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) {
      final messages = isar.messageModels
          .where()
          .chatIdEqualTo(chatId)
          .sortByCreatedAtDesc()
          .findAll();
      return messages.take(limit).toList();
    });
  }

  /// Get messages with cursor-based pagination (Web).
  List<MessageModel> getMessagesWithCursor({
    required String chatId,
    required int limit,
    DateTime? beforeTimestamp,
  }) {
    final allForChat = isar.messageModels
        .where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtDesc()
        .findAll();

    if (beforeTimestamp != null) {
      return allForChat
          .where((m) => m.createdAt.isBefore(beforeTimestamp))
          .take(limit)
          .toList();
    }

    return allForChat.take(limit).toList();
  }

  /// Delete all messages for a chat (Web).
  void deleteMessagesForChat(String chatId) {
    isar.write((isar) {
      isar.messageModels.where().chatIdEqualTo(chatId).deleteAll();
    });
  }

  /// Save user
  Future<void> saveUser(UserModel user) async {
    isar.write((isar) {
      isar.userModels.put(user);
    });
  }

  /// Delete chat
  Future<void> deleteChat(int id) async {
    isar.write((isar) {
      isar.chatModels.delete(id);
    });
  }

  /// Delete message
  Future<void> deleteMessage(int id) async {
    isar.write((isar) {
      isar.messageModels.delete(id);
    });
  }

  /// Delete user
  Future<void> deleteUser(int id) async {
    isar.write((isar) {
      isar.userModels.delete(id);
    });
  }
}

// Add the methods to the DatabaseService class
extension DatabaseServiceExtension on DatabaseService {
  /// Watch chats collection
  Stream<List<ChatModel>> watchChats() {
    return _implementation is WebDatabaseImplementation
        ? ((_implementation as WebDatabaseImplementation).watchChats())
        : ((_implementation as NativeDatabaseImplementation).watchChats());
  }

  /// Get chat by server ID
  Future<ChatModel?> getChatByServerId(String serverId) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation)
            .getChatByServerId(serverId)
        : await (_implementation as NativeDatabaseImplementation)
            .getChatByServerId(serverId);
  }

  /// Get message by server ID
  Future<MessageModel?> getMessageByServerId(String serverId) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation)
            .getMessageByServerId(serverId)
        : await (_implementation as NativeDatabaseImplementation)
            .getMessageByServerId(serverId);
  }

  /// Get message by local ID
  Future<MessageModel?> getMessageByLocalId(String localId) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation)
            .getMessageByLocalId(localId)
        : await (_implementation as NativeDatabaseImplementation)
            .getMessageByLocalId(localId);
  }

  /// Watch users collection
  Stream<List<UserModel>> watchUsers() {
    return _implementation is WebDatabaseImplementation
        ? ((_implementation as WebDatabaseImplementation).watchUsers())
        : ((_implementation as NativeDatabaseImplementation).watchUsers());
  }

  /// Save chat
  Future<void> saveChat(ChatModel chat) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation).saveChat(chat)
        : await (_implementation as NativeDatabaseImplementation)
            .saveChat(chat);
  }

  /// Save multiple chats in a single write transaction.
  Future<void> saveChatsBatch(List<ChatModel> chats) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation)
            .saveChatsBatch(chats)
        : await (_implementation as NativeDatabaseImplementation)
            .saveChatsBatch(chats);
  }

  /// Save message
  Future<void> saveMessage(MessageModel message) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation)
            .saveMessage(message)
        : await (_implementation as NativeDatabaseImplementation)
            .saveMessage(message);
  }

  /// Atomic upsert message — prevents duplicates by resolving identity
  /// through serverId → cross-reference → localId priority chain.
  void saveMessageUpsert(MessageModel message) {
    return _implementation is WebDatabaseImplementation
        ? (_implementation as WebDatabaseImplementation)
            .saveMessageUpsert(message)
        : (_implementation as NativeDatabaseImplementation)
            .saveMessageUpsert(message);
  }

  /// Batch atomic upsert messages in a single write transaction.
  void saveMessagesUpsert(List<MessageModel> messages) {
    return _implementation is WebDatabaseImplementation
        ? (_implementation as WebDatabaseImplementation)
            .saveMessagesUpsert(messages)
        : (_implementation as NativeDatabaseImplementation)
            .saveMessagesUpsert(messages);
  }

  /// Query messages by status (indexed for O(log n) performance).
  List<MessageModel> getMessagesByStatus(MessageStatus status) {
    return _implementation is WebDatabaseImplementation
        ? (_implementation as WebDatabaseImplementation)
            .getMessagesByStatus(status)
        : (_implementation as NativeDatabaseImplementation)
            .getMessagesByStatus(status);
  }

  /// Watch recent messages for a chat with limit.
  /// Native: Isar native watch. Web: 1s polling fallback.
  Stream<List<MessageModel>> watchRecentMessagesForChat(
    String chatId, {
    int limit = 20,
  }) {
    return _implementation is WebDatabaseImplementation
        ? (_implementation as WebDatabaseImplementation)
            .watchRecentMessagesForChat(chatId, limit: limit)
        : (_implementation as NativeDatabaseImplementation)
            .watchRecentMessagesForChat(chatId, limit: limit);
  }

  /// Get messages with cursor-based pagination.
  List<MessageModel> getMessagesWithCursor({
    required String chatId,
    required int limit,
    DateTime? beforeTimestamp,
  }) {
    return _implementation is WebDatabaseImplementation
        ? (_implementation as WebDatabaseImplementation)
            .getMessagesWithCursor(
              chatId: chatId,
              limit: limit,
              beforeTimestamp: beforeTimestamp,
            )
        : (_implementation as NativeDatabaseImplementation)
            .getMessagesWithCursor(
              chatId: chatId,
              limit: limit,
              beforeTimestamp: beforeTimestamp,
            );
  }

  /// Delete all messages for a chat.
  void deleteMessagesForChat(String chatId) {
    return _implementation is WebDatabaseImplementation
        ? (_implementation as WebDatabaseImplementation)
            .deleteMessagesForChat(chatId)
        : (_implementation as NativeDatabaseImplementation)
            .deleteMessagesForChat(chatId);
  }

  /// Save user
  Future<void> saveUser(UserModel user) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation).saveUser(user)
        : await (_implementation as NativeDatabaseImplementation)
            .saveUser(user);
  }

  /// Delete chat
  Future<void> deleteChat(int id) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation).deleteChat(id)
        : await (_implementation as NativeDatabaseImplementation)
            .deleteChat(id);
  }

  /// Delete message
  Future<void> deleteMessage(int id) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation).deleteMessage(id)
        : await (_implementation as NativeDatabaseImplementation)
            .deleteMessage(id);
  }

  /// Delete user
  Future<void> deleteUser(int id) async {
    return _implementation is WebDatabaseImplementation
        ? await (_implementation as WebDatabaseImplementation).deleteUser(id)
        : await (_implementation as NativeDatabaseImplementation)
            .deleteUser(id);
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'database_type': kIsWeb ? 'web' : 'native',
      'is_initialized': _isInitialized,
      'operation_times': <String, int>{
        'read': 5, // Placeholder - would track actual times
        'write': 8,
        'query': 12,
      },
      'total_operations': 0, // Placeholder
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Perform health check
  Future<HealthCheckResult> performHealthCheck() async {
    try {
      if (!_isInitialized) {
        return HealthCheckResult(
          isHealthy: false,
          message: 'Database not initialized',
        );
      }

      // Try a simple operation to verify database is working
      await getAllChats();

      return HealthCheckResult(
        isHealthy: true,
        message: 'Database is healthy',
      );
    } catch (e) {
      return HealthCheckResult(
        isHealthy: false,
        message: 'Database health check failed: $e',
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await close();
  }

  /// Get chats (alias for getAllChats for compatibility)
  Future<List<ChatModel>> getChats() async {
    return getAllChats();
  }

  /// Get messages for chat with limit
  Future<List<MessageModel>> getMessagesForChat(String chatId,
      {int? limit}) async {
    final messages = await _implementation.getMessagesForChat(chatId);
    if (limit != null && messages.length > limit) {
      return messages.sublist(0, limit);
    }
    return messages;
  }
}

/// Health check result
class HealthCheckResult {
  final bool isHealthy;
  final String message;

  const HealthCheckResult({
    required this.isHealthy,
    required this.message,
  });
}
