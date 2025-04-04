import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:graphql_flutter/graphql_flutter.dart' hide ServerException, UnknownException;
import 'package:injectable/injectable.dart';

/// Chat repository implementation
@LazySingleton(as: IChatRepository)
class ChatRepositoryImpl implements IChatRepository {
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
  GraphQLClient get client => _graphQLClient.client;

  @override
  Future<List<Chat>> getChats() async {
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
  Future<Chat?> getChatById(String chatId) async {
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
  Future<List<Chat>> getChatsFromLocalStorage() async {
    try {
      return await _localDataSource.getChats();
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<void> saveChatLocally(Chat chat) async {
    try {
      await _localDataSource.saveChat(chat);
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<Chat> createChat({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      if (isGroup) {
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
      } else {
        // Direct chat
        final result = await _graphQLClient.mutate(
          ChatMutations.createDirectChat,
          variables: {
            'participantId': participantIds.first,
          },
        );
        
        final chatData = result['createDirectChat'];
        final Chat newChat = Chat.fromJson(chatData as Map<String, dynamic>);
        
        // Save to local storage
        await _localDataSource.saveChat(newChat);
        
        return newChat;
      }
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<Chat> updateChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      final variables = {
        'chatId': chatId,
      };
      
      if (name != null) {
        variables['name'] = name;
      }
      
      if (avatarUrl != null) {
        variables['avatarUrl'] = avatarUrl;
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.updateChat,
        variables: variables,
      );
      
      final chatData = result['updateChat'];
      final Chat updatedChat = Chat.fromJson(chatData as Map<String, dynamic>);
      
      // Save to local storage
      await _localDataSource.saveChat(updatedChat);
      
      return updatedChat;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> addParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.addUserToChat,
        variables: {
          'chatId': chatId,
          'userIds': userIds,
        },
      );
      
      final success = result['addUsersToChat']['success'] as bool;
      
      if (success) {
        // Reload chat data to update participants
        final chatResult = await _graphQLClient.query(
          ChatQueries.getChatDetails,
          variables: {
            'chatId': chatId,
          },
        );
        
        final chatData = chatResult['getChatById'];
        final Chat updatedChat = Chat.fromJson(chatData as Map<String, dynamic>);
        
        // Save to local storage
        await _localDataSource.saveChat(updatedChat);
      }
      
      return success;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> removeParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.removeUserFromChat,
        variables: {
          'chatId': chatId,
          'userIds': userIds,
        },
      );
      
      final success = result['removeUsersFromChat']['success'] as bool;
      
      if (success) {
        // Reload chat data to update participants
        final chatResult = await _graphQLClient.query(
          ChatQueries.getChatDetails,
          variables: {
            'chatId': chatId,
          },
        );
        
        final chatData = chatResult['getChatById'];
        final Chat updatedChat = Chat.fromJson(chatData as Map<String, dynamic>);
        
        // Save to local storage
        await _localDataSource.saveChat(updatedChat);
      }
      
      return success;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> leaveChat(String chatId) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.leaveChat,
        variables: {
          'chatId': chatId,
        },
      );
      
      final success = result['leaveChat']['success'] as bool;
      
      if (success) {
        // Delete from local storage
        await _localDataSource.deleteChat(chatId);
      }
      
      return success;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> deleteChat(String chatId) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw NoInternetException();
      }
      
      final result = await _graphQLClient.mutate(
        ChatMutations.deleteChat,
        variables: {
          'chatId': chatId,
        },
      );
      
      final success = result['deleteChat']['success'] as bool;
      
      if (success) {
        // Delete from local storage
        await _localDataSource.deleteChat(chatId);
      }
      
      return success;
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> markChatAsRead(String chatId) async {
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
  Future<void> syncChat(String chatId) async {
    try {
      if (!await _networkInfo.isConnected) {
        return;
      }
      
      // Get chat from server
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