import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'dart:async';
import 'dart:io';

/// Service class responsible for managing the Isar database instance
/// and providing methods for database operations.
@singleton
class DatabaseService {
  late final Isar _isar;
  bool _isInitialized = false;

  /// Returns whether the database is initialized
  bool get isInitialized => _isInitialized;

  /// Returns the Isar instance
  Isar get isar => _isar;

  /// Initializes the database
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final schemas = [
      ChatModelSchema,
      MessageModelSchema,
      UserModelSchema,
    ];
    
    try {
      if (kIsWeb) {
        // Web version - for memory-only database
        _isar = Isar.open(
          schemas: schemas,
          directory: Isar.sqliteInMemory,
          inspector: kDebugMode,
          name: 'chat_app_db',
        );
      } else {
        // Native platforms
        final dir = await getApplicationDocumentsDirectory();
        _isar = Isar.open(
          schemas: schemas,
          directory: dir.path,
          inspector: kDebugMode,
          name: 'chat_app_db',
        );
      }
      
      _isInitialized = true;
      debugPrint('Isar DB initialized for ${kIsWeb ? 'web' : 'native'} platform');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  /// Closes the database
  Future<void> close() async {
    if (!_isInitialized) return;
    _isar.close();
    _isInitialized = false;
    debugPrint('Isar DB closed');
  }

  /// Clears all data in the database
  Future<void> clearAllData() async {
    if (!_isInitialized) await initialize();
    
    _isar.write((isar) {
      isar.clear(); 
    });
    
    debugPrint('Isar DB cleared');
  }

  /// Performs a database backup
  Future<String?> backup() async {
    if (!_isInitialized) return null;
    
    try {
      if (kIsWeb) {
        return null; // Not supported on web
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.isar';
      
      _isar.copyToFile(backupPath); 
      debugPrint('Database backed up to: $backupPath');
      
      return backupPath;
    } catch (e) {
      debugPrint('Error during database backup: $e');
      return null;
    }
  }

  /// Export database to JSON format
  Future<Map<String, dynamic>> exportToJson() async {
    if (!_isInitialized) await initialize();
    
    final chats = await getAllChats();
    final messages = _isar.messageModels.where().findAll();
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
      _isar.write((isar) {
        isar.clear();
        
        final users = (data['users'] as List?)
            ?.map((u) => UserModel.fromMap(u as Map<String, dynamic>))
            .toList() ?? [];
        isar.userModels.putAll(users);
        
        final chats = (data['chats'] as List?)
            ?.map((c) => ChatModel.fromMap(c as Map<String, dynamic>))
            .toList() ?? [];
        isar.chatModels.putAll(chats);
        
        final messages = (data['messages'] as List?)
            ?.map((m) => MessageModel.fromMap(m as Map<String, dynamic>))
            .toList() ?? [];
        isar.messageModels.putAll(messages);
      });
      
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
    return _isar.collection<ID, OBJ>();
  }
  
  /// Watches for changes on a collection
  Stream<List<T>> watchCollection<T>() {
    final collection = this.collection<int, T>();
    // Create a periodic stream that fetches data every 1 second
    return Stream.periodic(const Duration(seconds: 1))
      .asyncMap((_) => collection.where().findAll());
  }
  
  /// Gets all objects from a collection
  Future<List<T>> getAll<T>() async {
    return collection<int, T>().where().findAll();
  }
  
  /// Saves an object to the database
  Future<int> save<T>(T object) async {
    if (!_isInitialized) await initialize();
    await _isar.write((isar) async {
      collection<int, T>().put(object);
    });
    if (object is ChatModel) return object.id ?? 0;
    if (object is MessageModel) return object.id ?? 0;
    if (object is UserModel) return object.id ?? 0;
    throw ArgumentError('Object type does not have a retrievable ID after save');
  }
  
  /// Saves multiple objects to the database
  Future<void> saveAll<T>(List<T> objects) async {
    if (!_isInitialized) await initialize();
    _isar.write((isar) {
      collection<int, T>().putAll(objects); 
    });
  }
  
  /// Deletes an object from the database
  Future<bool> delete<T>(int id) async {
    if (!_isInitialized) await initialize();
    final success = await _isar.write((isar) async {
      return collection<int, T>().delete(id);
    });
    return success;
  }
  
  /// Deletes multiple objects from the database
  Future<int> deleteAll<T>(List<int> ids) async {
    if (!_isInitialized) await initialize();
    final count = await _isar.write((isar) async {
      return collection<int, T>().deleteAll(ids);
    });
    return count;
  }
  
  /// Executes a function within a database transaction
  Future<T> transaction<T>(Future<T> Function(Isar) action) async {
    if (!_isInitialized) await initialize();
    return await _isar.write((isar) => action(isar));
  }

  // CHAT OPERATIONS

  /// Get all chats
  Future<List<ChatModel>> getAllChats() async {
    if (!_isInitialized) await initialize();
    return _isar.chatModels.where().findAll();
  }

  /// Watch chats for changes
  Stream<List<ChatModel>> watchChats() {
    if (!_isInitialized) initialize();
    // Create a periodic stream that fetches data every 1 second
    return Stream.periodic(const Duration(seconds: 1))
      .asyncMap((_) => _isar.chatModels.where().findAll());
  }

  /// Get a specific chat by server ID
  Future<ChatModel?> getChatByServerId(String serverId) async {
    if (!_isInitialized) await initialize();
    return _isar.chatModels.where()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Save a chat
  Future<int> saveChat(ChatModel chat) async {
    if (!_isInitialized) await initialize();
    await _isar.write((isar) async {
      isar.chatModels.put(chat);
    });
    return chat.id ?? 0;
  }

  /// Save multiple chats
  Future<void> saveChats(List<ChatModel> chats) async {
    if (!_isInitialized) await initialize();
    _isar.write((isar) {
       isar.chatModels.putAll(chats);
    });
  }

  /// Delete a chat
  Future<bool> deleteChat(int id) async {
    if (!_isInitialized) await initialize();
    final success = await _isar.write((isar) async {
      return isar.chatModels.delete(id);
    });
    return success;
  }

  /// Get chats for a specific user
  Future<List<ChatModel>> getChatsForUser(String userId) async {
    if (!_isInitialized) await initialize();
    return _isar.chatModels.where()
        .participantIdsElementEqualTo(userId)
        .findAll();
  }

  /// Get direct chat between two users
  Future<ChatModel?> getDirectChatBetweenUsers(String user1Id, String user2Id) async {
    if (!_isInitialized) await initialize();
    final chats = _isar.chatModels.where()
        .typeEqualTo(ChatType.direct)
        .findAll();
    
    return chats.firstWhere(
      (chat) => 
        chat.participantIds.contains(user1Id) && 
        chat.participantIds.contains(user2Id) &&
        chat.participantIds.length == 2,
      orElse: () => throw StateError('No direct chat found between users'),
    );
  }

  /// Create a new chat ID
  Future<int> createChatId() async {
    if (!_isInitialized) await initialize();
    return _isar.chatModels.autoIncrement();
  }

  // MESSAGE OPERATIONS

  /// Get all messages for a chat
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    if (!_isInitialized) await initialize();
    return _isar.messageModels.where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAt()
        .findAll();
  }

  /// Watch messages for a chat
  Stream<List<MessageModel>> watchMessagesForChat(String chatId) {
    if (!_isInitialized) initialize();
    // Create a periodic stream that fetches data every 1 second
    return Stream.periodic(const Duration(seconds: 1))
      .asyncMap((_) => _isar.messageModels.where()
          .chatIdEqualTo(chatId)
          .sortByCreatedAt()
          .findAll());
  }

  /// Get a specific message by local ID
  Future<MessageModel?> getMessageByLocalId(String localId) async {
    if (!_isInitialized) await initialize();
    return _isar.messageModels.where()
        .localIdEqualTo(localId)
        .findFirst();
  }

  /// Get a specific message by server ID
  Future<MessageModel?> getMessageByServerId(String serverId) async {
    if (!_isInitialized) await initialize();
    return _isar.messageModels.where()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Save a message
  Future<int> saveMessage(MessageModel message) async {
    if (!_isInitialized) await initialize();
    await _isar.write((isar) async {
      isar.messageModels.put(message);
    });
    return message.id ?? 0;
  }

  /// Save multiple messages
  Future<void> saveMessages(List<MessageModel> messages) async {
    if (!_isInitialized) await initialize();
    _isar.write((isar) {
      isar.messageModels.putAll(messages);
    });
  }

  /// Delete a message
  Future<bool> deleteMessage(int id) async {
    if (!_isInitialized) await initialize();
    final success = await _isar.write((isar) async {
      return isar.messageModels.delete(id);
    });
    return success;
  }

  /// Get unread messages count for a chat
  Future<int> getUnreadMessagesCount(String chatId, String userId) async {
    if (!_isInitialized) await initialize();
    
    final messages = _isar.messageModels.where()
        .chatIdEqualTo(chatId)
        .and()
        .not().senderIdEqualTo(userId)
        .and()
        .not().readByElementEqualTo(userId)
        .findAll();
    
    return messages.length;
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    if (!_isInitialized) await initialize();
    
    final messages = _isar.messageModels.where()
        .chatIdEqualTo(chatId)
        .and()
        .not().readByElementEqualTo(userId)
        .findAll();
    
    if (messages.isEmpty) return;
    
    await _isar.write((isar) async {
      for (final message in messages) {
        final updatedMessage = message.markReadBy(userId);
        isar.messageModels.put(updatedMessage);
      }
    });
  }

  /// Create a new message ID
  Future<int> createMessageId() async {
    if (!_isInitialized) await initialize();
    return _isar.messageModels.autoIncrement();
  }

  /// Get pinned messages for a chat
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    if (!_isInitialized) await initialize();
    
    return _isar.messageModels.where()
        .chatIdEqualTo(chatId)
        .and()
        .isPinnedEqualTo(true)
        .findAll();
  }

  // USER OPERATIONS

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    if (!_isInitialized) await initialize();
    return _isar.userModels.where().findAll();
  }

  /// Watch users for changes
  Stream<List<UserModel>> watchUsers() {
    if (!_isInitialized) initialize();
    // Create a periodic stream that fetches data every 1 second
    return Stream.periodic(const Duration(seconds: 1))
      .asyncMap((_) => _isar.userModels.where().findAll());
  }

  /// Get a specific user by server ID
  Future<UserModel?> getUserByServerId(String serverId) async {
    if (!_isInitialized) await initialize();
    return _isar.userModels.where()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get a user by username
  Future<UserModel?> getUserByUsername(String username) async {
    if (!_isInitialized) await initialize();
    return _isar.userModels.where()
        .usernameEqualTo(username)
        .findFirst();
  }

  /// Save a user
  Future<int> saveUser(UserModel user) async {
    if (!_isInitialized) await initialize();
    await _isar.write((isar) async {
      isar.userModels.put(user);
    });
    return user.id ?? 0;
  }

  /// Save multiple users
  Future<void> saveUsers(List<UserModel> users) async {
    if (!_isInitialized) await initialize();
    _isar.write((isar) {
      isar.userModels.putAll(users);
    });
  }

  /// Delete a user
  Future<bool> deleteUser(int id) async {
    if (!_isInitialized) await initialize();
    final success = await _isar.write((isar) async {
      return isar.userModels.delete(id);
    });
    return success;
  }

  /// Create a new user ID
  Future<int> createUserId() async {
    if (!_isInitialized) await initialize();
    return _isar.userModels.autoIncrement();
  }

  /// Search users by name or username
  Future<List<UserModel>> searchUsers(String query) async {
    if (!_isInitialized) await initialize();
    
    if (query.isEmpty) {
      return await getAllUsers();
    }
    
    final queryLower = query.toLowerCase();
    final allUsers = await getAllUsers();
    
    return allUsers.where((user) => 
      user.username.toLowerCase().contains(queryLower) ||
      user.displayName.toLowerCase().contains(queryLower)
    ).toList();
  }

  /// Get online users
  Future<List<UserModel>> getOnlineUsers() async {
    if (!_isInitialized) await initialize();
    
    return _isar.userModels.where()
        .isOnlineEqualTo(true)
        .findAll();
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    if (!_isInitialized) await initialize();
    
    final allUsers = await getAllUsers();
    return allUsers.where((user) => user.hasRole(role)).toList();
  }

  /// Get members of a chat
  Future<List<UserModel>> getChatMembers(String chatId) async {
    if (!_isInitialized) await initialize();
    
    final chat = _isar.chatModels.where()
        .serverIdEqualTo(chatId)
        .findFirst();
    
    if (chat == null) return [];
    
    final memberIds = chat.participantIds;
    final allUsers = await getAllUsers();
    
    return allUsers.where((user) => 
      memberIds.contains(user.serverId)
    ).toList();
  }

  /// Get total database size in bytes
  Future<int> getDatabaseSize() async {
    if (!_isInitialized || kIsWeb) return 0;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/chat_app_db.isar');
      
      if (!await file.exists()) return 0;
      
      return await file.length();
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }
}