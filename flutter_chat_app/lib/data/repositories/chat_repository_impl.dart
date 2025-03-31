import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:flutter_chat_app/domain/repositories/chat_repository.dart';

/// Chat repository implementation
class ChatRepositoryImpl implements ChatRepository {
  final GraphQLClientWrapper _graphQLClient;
  final ChatLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  /// Constructor
  ChatRepositoryImpl(
    this._graphQLClient,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<List<Chat>> getUserChats() async {
    try {
      // Try to load from local storage first (offline-first)
      final localChats = await _localDataSource.getChats();
      
      // If online, fetch latest from server
      if (await _networkInfo.isConnected) {
        try {
          final result = await _graphQLClient.query(
            ChatQueries.getUserChats,
            variables: {
              'limit': 50,
              'offset': 0,
            },
          );
          
          final List<dynamic> chatData = result['getUserChats'] ?? [];
          final List<Chat> remoteChats = chatData
              .map((chat) => Chat.fromJson(chat as Map<String, dynamic>))
              .toList();
          
          // Save to local storage
          await _localDataSource.saveChats(remoteChats);
          
          return remoteChats;
        } catch (e) {
          // If remote fetch fails but we have local data, use that
          if (localChats.isNotEmpty) {
            return localChats;
          }
          rethrow;
        }
      }
      
      return localChats;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<Chat> getChatDetails(String chatId) async {
    try {
      // Try to load from local storage first
      final localChat = await _localDataSource.getChatById(chatId);
      
      // If online, fetch latest from server
      if (await _networkInfo.isConnected) {
        try {
          final result = await _graphQLClient.query(
            ChatQueries.getChatDetails,
            variables: {
              'chatId': chatId,
            },
          );
          
          final chatData = result['getChatById'];
          final Chat remoteChat = Chat.fromJson(chatData as Map<String, dynamic>);
          
          // Save to local storage
          await _localDataSource.saveChat(remoteChat);
          
          return remoteChat;
        } catch (e) {
          // If remote fetch fails but we have local data, use that
          if (localChat != null) {
            return localChat;
          }
          rethrow;
        }
      }
      
      if (localChat != null) {
        return localChat;
      }
      throw NotFoundException(message: 'Chat not found');
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String chatId, {int limit = 20, String? before}) async {
    try {
      // Try to load from local storage first
      final localMessages = await _localDataSource.getChatMessages(chatId, limit: limit, before: before);
      
      // If online, fetch latest from server
      if (await _networkInfo.isConnected) {
        try {
          final result = await _graphQLClient.query(
            ChatQueries.getChatMessages,
            variables: {
              'chatId': chatId,
              'limit': limit,
              'before': before,
            },
          );
          
          final List<dynamic> messageData = result['getChatMessages'] ?? [];
          final List<ChatMessage> remoteMessages = messageData
              .map((message) => ChatMessage.fromJson(message as Map<String, dynamic>))
              .toList();
          
          // Save to local storage
          await _localDataSource.saveMessages(chatId, remoteMessages);
          
          return remoteMessages;
        } catch (e) {
          // If remote fetch fails but we have local data, use that
          if (localMessages.isNotEmpty) {
            return localMessages;
          }
          rethrow;
        }
      }
      
      return localMessages;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<Chat> createDirectChat(String participantId) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.createDirectChat,
        variables: {
          'participantId': participantId,
        },
      );
      
      final chatData = result['createDirectChat'];
      final Chat newChat = Chat.fromJson(chatData as Map<String, dynamic>);
      
      // Save to local storage
      await _localDataSource.saveChat(newChat);
      
      return newChat;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<Chat> createGroupChat(String name, List<String> participantIds) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.createGroupChat,
        variables: {
          'name': name,
          'participantIds': participantIds,
        },
      );
      
      final chatData = result['createGroupChat'];
      final Chat newChat = Chat.fromJson(chatData as Map<String, dynamic>);
      
      // Save to local storage
      await _localDataSource.saveChat(newChat);
      
      return newChat;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<ChatMessage> sendMessage(String chatId, String content, {String contentType = 'TEXT', List<Map<String, dynamic>>? attachments}) async {
    try {
      final Map<String, dynamic> variables = {
        'chatId': chatId,
        'content': content,
        'contentType': contentType,
      };

      if (attachments != null && attachments.isNotEmpty) {
        variables['attachments'] = attachments;
      }
      
      // If offline, store message locally and mark for sync
      if (!await _networkInfo.isConnected) {
        final message = ChatMessage(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          chatId: chatId,
          content: content,
          contentType: contentType,
          attachments: attachments?.map((attachment) => 
            Attachment.fromJson(attachment)
          ).toList() ?? [],
          sender: User(
            id: 'current_user', // Will be replaced with actual user ID from auth
            username: 'Me',
            avatar: '', 
          ),
          status: MessageStatus.sending,
          createdAt: DateTime.now(),
        );
        
        // Save to local storage and mark for sync
        await _localDataSource.saveMessage(chatId, message, needsSync: true);
        
        return message;
      }
      
      // If online, send directly
      final result = await _graphQLClient.mutate(
        ChatMutations.sendMessage,
        variables: variables,
      );
      
      final messageData = result['sendMessage'];
      final ChatMessage newMessage = ChatMessage.fromJson(messageData as Map<String, dynamic>);
      
      // Save to local storage
      await _localDataSource.saveMessage(chatId, newMessage);
      
      return newMessage;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> markMessagesAsRead(String chatId) async {
    try {
      if (!await _networkInfo.isConnected) {
        // Mark locally and queue for sync
        await _localDataSource.markChatAsRead(chatId);
        return true;
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.markMessagesAsRead,
        variables: {
          'chatId': chatId,
        },
      );
      
      final success = result['markMessagesAsRead']['success'] as bool;
      
      if (success) {
        await _localDataSource.markChatAsRead(chatId);
      }
      
      return success;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Stream<ChatMessage> subscribeToChatMessages(String? chatId) {
    return _graphQLClient
        .subscribe(
          ChatSubscriptions.newMessage,
          variables: chatId != null ? {'chatId': chatId} : null,
        )
        .asyncMap((event) {
          final messageData = event['newMessage'];
          final message = ChatMessage.fromJson(messageData as Map<String, dynamic>);
          
          // Save to local storage
          _localDataSource.saveMessage(message.chatId, message);
          
          return message;
        });
  }

  @override
  Stream<Map<String, dynamic>> subscribeToTypingStatus(String chatId) {
    return _graphQLClient
        .subscribe(
          ChatSubscriptions.typingStatus,
          variables: {'chatId': chatId},
        )
        .map((event) => event['typingStatus'] as Map<String, dynamic>);
  }

  @override
  Future<bool> syncOfflineMessages() async {
    if (!await _networkInfo.isConnected) {
      return false;
    }
    
    try {
      final pendingMessages = await _localDataSource.getPendingMessages();
      
      for (final message in pendingMessages) {
        try {
          Map<String, dynamic> variables = {
            'chatId': message.chatId,
            'content': message.content,
            'contentType': message.contentType,
          };
          
          if (message.attachments.isNotEmpty) {
            variables['attachments'] = message.attachments.map((attachment) => {
              'url': attachment.url,
              'type': attachment.type,
              'name': attachment.name,
              'size': attachment.size,
            }).toList();
          }
          
          final result = await _graphQLClient.mutate(
            ChatMutations.sendMessage,
            variables: variables,
          );
          
          final messageData = result['sendMessage'];
          final syncedMessage = ChatMessage.fromJson(messageData as Map<String, dynamic>);
          
          // Replace local message with synced one
          await _localDataSource.replaceMessage(message.chatId, message.id, syncedMessage);
        } catch (e) {
          // Mark as failed and continue with next message
          await _localDataSource.updateMessageStatus(message.chatId, message.id, MessageStatus.failed);
        }
      }
      
      return true;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  Exception _handleException(Exception e) {
    if (e is NoInternetException || 
        e is ServerException || 
        e is CacheException ||
        e is AuthException ||
        e is ValidationException ||
        e is NotFoundException) {
      return e;
    }
    return UnknownException(message: e.toString());
  }
} 