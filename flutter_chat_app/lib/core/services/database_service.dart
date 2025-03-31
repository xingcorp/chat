import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';

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
        // Web version - passing empty string since directory is required but not used for web
        _isar = await Isar.open(
          schemas,
          directory: '',
          inspector: kDebugMode,
        );
      } else {
        // Native platforms
        final dir = await getApplicationDocumentsDirectory();
        _isar = await Isar.open(
          schemas,
          directory: dir.path,
          inspector: kDebugMode,
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
    await _isar.close();
    _isInitialized = false;
    debugPrint('Isar DB closed');
  }

  /// Clears all data in the database
  Future<void> clearAllData() async {
    if (!_isInitialized) await initialize();
    
    await _isar.writeTxn(() async {
      await _isar.clear();
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
      
      await _isar.copyToFile(backupPath);
      debugPrint('Database backed up to: $backupPath');
      
      return backupPath;
    } catch (e) {
      debugPrint('Error during database backup: $e');
      return null;
    }
  }

  /// Returns instance of a collection
  IsarCollection<T> collection<T>() {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _isar.collection<T>();
  }
  
  /// Watches for changes on a collection
  Stream<List<T>> watchCollection<T>() {
    return collection<T>().where().watch(fireImmediately: true);
  }
  
  /// Gets all objects from a collection
  Future<List<T>> getAll<T>() async {
    return collection<T>().where().findAll();
  }
  
  /// Saves an object to the database
  Future<int> save<T>(T object) async {
    late int id;
    await _isar.writeTxn(() async {
      id = await collection<T>().put(object);
    });
    return id;
  }
  
  /// Saves multiple objects to the database
  Future<void> saveAll<T>(List<T> objects) async {
    await _isar.writeTxn(() async {
      await collection<T>().putAll(objects);
    });
  }
  
  /// Deletes an object from the database
  Future<bool> delete<T>(int id) async {
    bool success = false;
    await _isar.writeTxn(() async {
      success = await collection<T>().delete(id);
    });
    return success;
  }
  
  /// Deletes multiple objects from the database
  Future<int> deleteAll<T>(List<int> ids) async {
    late int count;
    await _isar.writeTxn(() async {
      count = await collection<T>().deleteAll(ids);
    });
    return count;
  }
  
  /// Executes a function within a database transaction
  Future<T> transaction<T>(Future<T> Function() action) {
    return _isar.writeTxn(action);
  }

  // CHAT OPERATIONS

  /// Get all chats
  Future<List<ChatModel>> getAllChats() async {
    if (!_isInitialized) await initialize();
    return await _isar.chatModels.where().findAll();
  }

  /// Watch chats for changes
  Stream<List<ChatModel>> watchChats() {
    if (!_isInitialized) initialize();
    return _isar.chatModels.where().watch(fireImmediately: true);
  }

  /// Get a specific chat by server ID
  Future<ChatModel?> getChatByServerId(String serverId) async {
    if (!_isInitialized) await initialize();
    return await _isar.chatModels.where().filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Save a chat
  Future<int> saveChat(ChatModel chat) async {
    if (!_isInitialized) await initialize();
    late int id;
    await _isar.writeTxn(() async {
      id = await _isar.chatModels.put(chat);
    });
    return id;
  }

  /// Save multiple chats
  Future<void> saveChats(List<ChatModel> chats) async {
    if (!_isInitialized) await initialize();
    await _isar.writeTxn(() async {
      await _isar.chatModels.putAll(chats);
    });
  }

  /// Delete a chat
  Future<bool> deleteChat(int id) async {
    if (!_isInitialized) await initialize();
    bool success = false;
    await _isar.writeTxn(() async {
      success = await _isar.chatModels.delete(id);
    });
    return success;
  }

  // MESSAGE OPERATIONS

  /// Get all messages for a chat
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    if (!_isInitialized) await initialize();
    return await _isar.messageModels.where()
        .filter().chatIdEqualTo(chatId)
        .sortByCreatedAt()
        .findAll();
  }

  /// Watch messages for a chat
  Stream<List<MessageModel>> watchMessagesForChat(String chatId) {
    if (!_isInitialized) initialize();
    return _isar.messageModels.where()
        .filter().chatIdEqualTo(chatId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  /// Get a specific message by local ID
  Future<MessageModel?> getMessageByLocalId(String localId) async {
    if (!_isInitialized) await initialize();
    return await _isar.messageModels.where()
        .filter().localIdEqualTo(localId)
        .findFirst();
  }

  /// Get a specific message by server ID
  Future<MessageModel?> getMessageByServerId(String serverId) async {
    if (!_isInitialized) await initialize();
    return await _isar.messageModels.where()
        .filter().serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Save a message
  Future<int> saveMessage(MessageModel message) async {
    if (!_isInitialized) await initialize();
    late int id;
    await _isar.writeTxn(() async {
      id = await _isar.messageModels.put(message);
    });
    return id;
  }

  /// Save multiple messages
  Future<void> saveMessages(List<MessageModel> messages) async {
    if (!_isInitialized) await initialize();
    await _isar.writeTxn(() async {
      await _isar.messageModels.putAll(messages);
    });
  }

  /// Delete a message
  Future<bool> deleteMessage(int id) async {
    if (!_isInitialized) await initialize();
    bool success = false;
    await _isar.writeTxn(() async {
      success = await _isar.messageModels.delete(id);
    });
    return success;
  }

  // USER OPERATIONS

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    if (!_isInitialized) await initialize();
    return await _isar.userModels.where().findAll();
  }

  /// Watch users for changes
  Stream<List<UserModel>> watchUsers() {
    if (!_isInitialized) initialize();
    return _isar.userModels.where().watch(fireImmediately: true);
  }

  /// Get a specific user by server ID
  Future<UserModel?> getUserByServerId(String serverId) async {
    if (!_isInitialized) await initialize();
    return await _isar.userModels.where()
        .filter().serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Save a user
  Future<int> saveUser(UserModel user) async {
    if (!_isInitialized) await initialize();
    late int id;
    await _isar.writeTxn(() async {
      id = await _isar.userModels.put(user);
    });
    return id;
  }

  /// Save multiple users
  Future<void> saveUsers(List<UserModel> users) async {
    if (!_isInitialized) await initialize();
    await _isar.writeTxn(() async {
      await _isar.userModels.putAll(users);
    });
  }

  /// Delete a user
  Future<bool> deleteUser(int id) async {
    if (!_isInitialized) await initialize();
    bool success = false;
    await _isar.writeTxn(() async {
      success = await _isar.userModels.delete(id);
    });
    return success;
  }
}