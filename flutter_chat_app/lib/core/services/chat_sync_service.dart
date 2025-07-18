import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/data/repositories/chat_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that handles chat synchronization with the server
@lazySingleton
class ChatSyncService {
  static const String _backgroundChannelPort = 'chat_sync_background_port';
  static const int _syncInterval = 60; // seconds
  
  final ChatRepository _chatRepository;
  final IMessageRepository _messageRepository;
  final LocalStorageService _localStorageService;
  final ConnectivityService _connectivityService;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _messageSubscription;
  DateTime _lastSyncTime = DateTime.now();
  final List<String> _pendingChatsToSync = [];
  
  /// Constructor
  ChatSyncService(
    this._chatRepository,
    this._messageRepository,
    this._localStorageService,
    this._connectivityService,
  );
  
  /// Initialize the service
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_handleConnectivityChanged);
    
    // Set up background channel for receiving messages when app is not in foreground
    final receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort, 
      _backgroundChannelPort
    );
    
    receivePort.listen((message) {
      if (message is Map<String, dynamic> && message.containsKey('type')) {
        if (message['type'] == 'new_message') {
          final chatId = message['chatId'] as String;
          syncChatMessages(chatId);
        }
      }
    });
    
    // Restore last sync time from storage
    final lastSyncTimeStr = await _localStorageService.getString('last_sync_time');
    if (lastSyncTimeStr != null) {
      _lastSyncTime = DateTime.parse(lastSyncTimeStr);
    }
    
    // Start periodic sync
    _startPeriodicSync();
    
    // Subscribe to new messages
    _setupMessageSubscription();
  }

  /// Set up GraphQL subscription for real-time message updates
  void _setupMessageSubscription() {
    try {
      final options = SubscriptionOptions(
        document: gql(r'''
          subscription OnNewMessage {
            messageCreated {
              id
              content
              contentType
              sender {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              readBy {
                id
              }
              attachments {
                id
                fileName
                size
                mimeType
                url
              }
              createdAt
              updatedAt
            }
          }
        '''),
      );

      _messageSubscription = _chatRepository.client.subscribe(options).listen(
        (QueryResult result) {
          if (!result.hasException && result.data != null) {
            final messageData = result.data?['messageCreated'];
            if (messageData != null) {
              final message = ChatMessage.fromJson(messageData);
              _handleNewMessage(message);
            }
          }
        },
        onError: (error) {
          debugPrint('Subscription error: $error');
          // Attempt to reconnect after delay
          Future.delayed(const Duration(seconds: 5), () {
            _setupMessageSubscription();
          });
        },
      );
    } catch (e) {
      debugPrint('Error setting up message subscription: $e');
      // Try again after delay
      Future.delayed(const Duration(seconds: 10), () {
        _setupMessageSubscription();
      });
    }
  }
  
  /// Handle new messages from real-time subscription
  Future<void> _handleNewMessage(ChatMessage message) async {
    try {
      // TODO: Implement saveMessageLocally in IMessageRepository
      // await _messageRepository.saveMessageLocally(message);
      
      // Check if we need to update chat's last message
      final chatList = await _chatRepository.getChatsFromLocalStorage();
      for (final chat in chatList) {
        if (chat.id == message.chatId && 
            (chat.lastMessageTime == null || 
             (message.createdAt.isAfter(chat.lastMessageTime!)))) {
          final updatedChat = chat.copyWith(
            lastMessageTime: message.createdAt,
            lastMessagePreview: message.content,
            // If there's an unread count field, you might want to increase it here
            // unreadCount: chat.unreadCount + 1,
          );
          await _chatRepository.saveChatLocally(updatedChat);
        }
      }
      
      // TODO: Implement notifyNewMessage in IMessageRepository
      // _messageRepository.notifyNewMessage(message);
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }
  
  /// Start periodic synchronization timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: _syncInterval), 
      (_) => syncAllChats()
    );
  }
  
  /// Handle connectivity changes
  void _handleConnectivityChanged(bool isConnected) {
    if (isConnected) {
      // When connection is restored, sync data
      syncAllChats();
      
      // Also try to restart periodic sync if needed
      if (_syncTimer == null || !_syncTimer!.isActive) {
        _startPeriodicSync();
      }
    } else {
      // Cancel timer when offline
      _syncTimer?.cancel();
    }
  }
  
  /// Sync all chats with the server
  Future<void> syncAllChats() async {
    if (_isSyncing || !_connectivityService.hasConnection) {
      return;
    }
    
    try {
      _isSyncing = true;
      
      // Sync pending chats first
      if (_pendingChatsToSync.isNotEmpty) {
        await syncPendingChats();
      }
      
      // Fetch fresh chats from server
      final chats = await _chatRepository.getChats();
      
      // Save to local storage
      for (final chat in chats) {
        await _chatRepository.saveChatLocally(chat);
      }
      
      // Sync messages for each chat
      for (final chat in chats) {
        await syncChatMessages(chat.id);
      }
      
      // Update last sync time
      _lastSyncTime = DateTime.now();
      await _localStorageService.setString(
        'last_sync_time', 
        _lastSyncTime.toIso8601String()
      );
    } catch (e) {
      debugPrint('Chat sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync messages for a specific chat
  Future<void> syncChatMessages(String chatId) async {
    if (!_connectivityService.hasConnection) {
      // Save for later sync when offline
      if (!_pendingChatsToSync.contains(chatId)) {
        _pendingChatsToSync.add(chatId);
      }
      return;
    }
    
    try {
      // TODO: Implement sync methods in IMessageRepository
      // final latestMessageTime = await _messageRepository.getLatestMessageTimestamp(chatId);
      // final messages = await _messageRepository.getChatMessages(chatId, since: latestMessageTime);
      // for (final message in messages) {
      //   await _messageRepository.saveMessageLocally(message);
      // }
      
      // Mark as synced
      _pendingChatsToSync.remove(chatId);
      
    } catch (e) {
      debugPrint('Message sync error for chat $chatId: $e');
    }
  }
  
  /// Sync pending chats
  Future<void> syncPendingChats() async {
    if (!_connectivityService.hasConnection) {
      return;
    }
    
    final pendingChats = List<String>.from(_pendingChatsToSync);
    for (final chatId in pendingChats) {
      await syncChatMessages(chatId);
    }
  }
  
  /// Process a notification about a new message
  Future<void> processMessageNotification(Map<String, dynamic> notification) async {
    final chatId = notification['chatId'];
    if (chatId != null) {
      // Prioritize this chat for immediate sync
      await syncChatMessages(chatId);
    }
  }
  
  /// Get the last sync time
  DateTime getLastSyncTime() {
    return _lastSyncTime;
  }
  
  /// Force immediate synchronization
  Future<void> forceSyncNow() async {
    await syncAllChats();
  }
  
  /// Clean up resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _messageSubscription?.cancel();
    
    final sendPort = IsolateNameServer.lookupPortByName(_backgroundChannelPort);
    if (sendPort != null) {
      IsolateNameServer.removePortNameMapping(_backgroundChannelPort);
    }
  }
} 