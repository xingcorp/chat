import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';

/// Abstract interface for offline-first repository operations
abstract class OfflineFirstRepository {
  /// Get all chats from the cache
  Stream<List<ChatModel>> getChatStream();

  /// Get a specific chat from the cache
  Future<ChatModel?> getChatById(String id);

  /// Get messages for a specific chat from the cache
  Stream<List<MessageModel>> getMessagesForChat(String chatId);

  /// Get a specific message from the cache
  Future<MessageModel?> getMessageById(String id);

  /// Get all users from the cache
  Stream<List<UserModel>> getUserStream();

  /// Get a specific user from the cache
  Future<UserModel?> getUserById(String id);

  /// Save a chat to the cache and sync if online
  Future<void> saveChat(ChatModel chat);

  /// Save a message to the cache and sync if online
  Future<void> saveMessage(MessageModel message);

  /// Save a user to the cache and sync if online
  Future<void> saveUser(UserModel user);

  /// Delete a chat from the cache and sync if online
  Future<void> deleteChat(String id);

  /// Delete a message from the cache and sync if online
  Future<void> deleteMessage(String id);

  /// Delete a user from the cache and sync if online
  Future<void> deleteUser(String id);

  /// Manually trigger a sync of all cached data with the server
  Future<void> synchronize();
}

/// Implementation of the offline-first repository
@singleton
class OfflineFirstRepositoryImpl implements OfflineFirstRepository {
  final DatabaseService _databaseService;
  final ConnectivityService _connectivityService;
  
  bool _isSynchronizing = false;
  final StreamController<bool> _syncStreamController = StreamController<bool>.broadcast();
  
  /// Constructor
  OfflineFirstRepositoryImpl(this._databaseService, this._connectivityService) {
    // Listen for connectivity changes to trigger sync
    _connectivityService.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        synchronize();
      }
    });
  }
  
  /// Stream indicating if the repository is currently synchronizing
  Stream<bool> get syncStream => _syncStreamController.stream;

  @override
  Stream<List<ChatModel>> getChatStream() {
    return _databaseService.watchChats();
  }

  @override
  Future<ChatModel?> getChatById(String id) async {
    return _databaseService.getChatByServerId(id);
  }

  @override
  Stream<List<MessageModel>> getMessagesForChat(String chatId) {
    return _databaseService.watchMessagesForChat(chatId);
  }

  @override
  Future<MessageModel?> getMessageById(String id) async {
    // First try to find by server ID
    final message = await _databaseService.getMessageByServerId(id);
    
    // If not found, try to find by local ID
    if (message == null) {
      return _databaseService.getMessageByLocalId(id);
    }
    
    return message;
  }

  @override
  Stream<List<UserModel>> getUserStream() {
    return _databaseService.watchUsers();
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    return _databaseService.getUserByServerId(id);
  }

  @override
  Future<void> saveChat(ChatModel chat) async {
    // Save locally first (offline-first)
    await _databaseService.saveChat(chat);
    
    // Then sync with server if online
    if (await _connectivityService.isConnected()) {
      _syncChat(chat);
    }
  }

  @override
  Future<void> saveMessage(MessageModel message) async {
    // Save locally first (offline-first)
    await _databaseService.saveMessage(message);
    
    // Then sync with server if online
    if (await _connectivityService.isConnected()) {
      _syncMessage(message);
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    // Save locally first (offline-first)
    await _databaseService.saveUser(user);
    
    // Then sync with server if online
    if (await _connectivityService.isConnected()) {
      _syncUser(user);
    }
  }

  @override
  Future<void> deleteChat(String id) async {
    // Find the chat by its server ID
    final chat = await _databaseService.getChatByServerId(id);
    
    if (chat != null) {
      // Delete locally first
      await _databaseService.deleteChat(chat.id);
      
      // Then sync with server if online
      if (await _connectivityService.isConnected()) {
        _syncChatDeletion(id);
      }
    }
  }

  @override
  Future<void> deleteMessage(String id) async {
    // Try to find the message by server ID first
    var message = await _databaseService.getMessageByServerId(id);
    
    // If not found, try to find by local ID
    if (message == null) {
      message = await _databaseService.getMessageByLocalId(id);
    }
    
    if (message != null) {
      // Delete locally first
      await _databaseService.deleteMessage(message.id);
      
      // Then sync with server if online
      if (await _connectivityService.isConnected()) {
        _syncMessageDeletion(id);
      }
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    // Find the user by its server ID
    final user = await _databaseService.getUserByServerId(id);
    
    if (user != null) {
      // Delete locally first
      await _databaseService.deleteUser(user.id);
      
      // Then sync with server if online
      if (await _connectivityService.isConnected()) {
        _syncUserDeletion(id);
      }
    }
  }

  @override
  Future<void> synchronize() async {
    if (_isSynchronizing) return;
    
    _isSynchronizing = true;
    _syncStreamController.add(true);
    
    try {
      debugPrint('Starting data synchronization...');
      
      // Sync chats, messages, and users
      await _syncAllChats();
      await _syncAllMessages();
      await _syncAllUsers();
      
      debugPrint('Data synchronization completed successfully');
    } catch (e) {
      debugPrint('Error during data synchronization: $e');
    } finally {
      _isSynchronizing = false;
      _syncStreamController.add(false);
    }
  }

  // PRIVATE SYNC METHODS

  Future<void> _syncAllChats() async {
    // TODO: Implement actual server sync logic
    // This would typically involve:
    // 1. Getting all unsynchronized chats from the local database
    // 2. Sending them to the server
    // 3. Getting updates from the server
    // 4. Updating the local database
  }

  Future<void> _syncAllMessages() async {
    // TODO: Implement actual server sync logic
    // This would typically involve:
    // 1. Getting all unsynchronized messages from the local database
    // 2. Sending them to the server
    // 3. Getting updates from the server
    // 4. Updating the local database
  }

  Future<void> _syncAllUsers() async {
    // TODO: Implement actual server sync logic
    // This would typically involve:
    // 1. Getting all unsynchronized users from the local database
    // 2. Sending them to the server
    // 3. Getting updates from the server
    // 4. Updating the local database
  }

  Future<void> _syncChat(ChatModel chat) async {
    // TODO: Implement actual server sync logic for a single chat
  }

  Future<void> _syncMessage(MessageModel message) async {
    // TODO: Implement actual server sync logic for a single message
  }

  Future<void> _syncUser(UserModel user) async {
    // TODO: Implement actual server sync logic for a single user
  }

  Future<void> _syncChatDeletion(String chatId) async {
    // TODO: Implement actual server sync logic for chat deletion
  }

  Future<void> _syncMessageDeletion(String messageId) async {
    // TODO: Implement actual server sync logic for message deletion
  }

  Future<void> _syncUserDeletion(String userId) async {
    // TODO: Implement actual server sync logic for user deletion
  }
} 