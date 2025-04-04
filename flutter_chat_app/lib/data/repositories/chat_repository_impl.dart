import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// Implementation of [IChatRepository]
class ChatRepositoryImpl implements IChatRepository {
  final NetworkInfo _networkInfo;
  final ChatLocalDataSource _localDataSource;
  final ChatRemoteDataSource _remoteDataSource;
  final GraphQLClientWrapper _graphQLClient;

  /// Constructor
  ChatRepositoryImpl(
    this._networkInfo,
    this._localDataSource,
    this._remoteDataSource,
    this._graphQLClient,
  );

  @override
  GraphQLClient get client => _graphQLClient.client;

  @override
  Future<List<Chat>> getChats() async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteChatModels = await _remoteDataSource.getUserChats();
        
        // Save chats to local storage
        for (final chatModel in remoteChatModels) {
          await _localDataSource.saveChat(chatModel);
        }
        
        // Convert to domain entities
        return remoteChatModels.map((model) => model.toDomain()).toList();
      } on Exception {
        // Fallback to local data on error
        return getChatsFromLocalStorage();
      }
    } else {
      // No internet connection
      return getChatsFromLocalStorage();
    }
  }

  @override
  Future<Chat?> getChatById(String chatId) async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteChatModel = await _remoteDataSource.getChatDetails(chatId);
        
        // Save to local storage
        await _localDataSource.saveChat(remoteChatModel);
        
        return remoteChatModel.toDomain();
      } on Exception {
        // Fallback to local data on error
        final localChatModel = await _localDataSource.getChatById(chatId);
        return localChatModel?.toDomain();
      }
    } else {
      // No internet connection
      final localChatModel = await _localDataSource.getChatById(chatId);
      return localChatModel?.toDomain();
    }
  }

  @override
  Future<List<Chat>> getChatsFromLocalStorage() async {
    final localChatModels = await _localDataSource.getAllChats();
    return localChatModels.map((model) => model.toDomain()).toList();
  }

  @override
  Future<void> saveChatLocally(Chat chat) async {
    final chatModel = ChatModel.fromDomain(chat);
    await _localDataSource.saveChat(chatModel);
  }

  @override
  Future<Chat> createChat({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final ChatModel result;
      
      if (isGroup) {
        result = await _remoteDataSource.createGroupChat(name, participantIds);
      } else {
        if (participantIds.length != 1) {
          throw const InvalidArgumentException(
            'Direct chats must have exactly one participant'
          );
        }
        result = await _remoteDataSource.createDirectChat(participantIds.first);
      }
      
      // Save to local storage
      await _localDataSource.saveChat(result);
      
      return result.toDomain();
    } catch (e) {
      throw ServerException(message: 'Failed to create chat: $e');
    }
  }

  @override
  Future<Chat> updateChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final result = await _remoteDataSource.updateChat(
        chatId,
        name: name,
        avatarUrl: avatarUrl,
      );
      
      // Save to local storage
      await _localDataSource.saveChat(result);
      
      return result.toDomain();
    } catch (e) {
      throw ServerException(message: 'Failed to update chat: $e');
    }
  }

  @override
  Future<bool> addParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final result = await _remoteDataSource.addUsersToChat(chatId, userIds);
      
      // Update local cache
      if (result) {
        await syncChat(chatId);
      }
      
      return result;
    } catch (e) {
      throw ServerException(message: 'Failed to add participants: $e');
    }
  }

  @override
  Future<bool> removeParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final result = await _remoteDataSource.removeUsersFromChat(chatId, userIds);
      
      // Update local cache
      if (result) {
        await syncChat(chatId);
      }
      
      return result;
    } catch (e) {
      throw ServerException(message: 'Failed to remove participants: $e');
    }
  }

  @override
  Future<bool> leaveChat(String chatId) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final result = await _remoteDataSource.leaveChat(chatId);
      
      // Remove from local storage if successfully left
      if (result) {
        await _localDataSource.deleteChat(chatId);
      }
      
      return result;
    } catch (e) {
      throw ServerException(message: 'Failed to leave chat: $e');
    }
  }

  @override
  Future<bool> deleteChat(String chatId) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final result = await _remoteDataSource.deleteChat(chatId);
      
      // Remove from local storage if successfully deleted
      if (result) {
        await _localDataSource.deleteChat(chatId);
      }
      
      return result;
    } catch (e) {
      throw ServerException(message: 'Failed to delete chat: $e');
    }
  }

  @override
  Future<bool> markChatAsRead(String chatId) async {
    // This would typically call a backend API to mark the chat as read
    // But since we haven't defined this in the remote data source yet,
    // we'll assume it's successful for now
    return true;
  }

  @override
  Future<void> syncChat(String chatId) async {
    if (!(await _networkInfo.isConnected)) {
      return; // Can't sync without internet
    }

    try {
      final remoteChat = await _remoteDataSource.getChatDetails(chatId);
      await _localDataSource.saveChat(remoteChat);
    } catch (e) {
      // Log error but don't throw, as this is a background sync
      print('Failed to sync chat $chatId: $e');
    }
  }
} 