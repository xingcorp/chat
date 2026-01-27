import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/exceptions/exceptions.dart' as core_exceptions;
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/auth/auth_local_datasource.dart';
import 'package:flutter_chat_app/data/mappers/chat_mapper.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';



/// **ENTERPRISE CHAT REPOSITORY IMPLEMENTATION**
///
/// Implements IChatRepository using BaseRepository patterns with:
/// - Offline-first strategy for chat lists (cached data)
/// - Online-first strategy for chat details (fresh data)
/// - Remote-only strategy for chat operations (server confirmation)
/// - Comprehensive error handling and performance monitoring
/// - Real-time messaging optimization for WhatsApp/Telegram-level performance
@LazySingleton(as: IChatRepository)
class ChatRepositoryImpl extends BaseRepository implements IChatRepository {
  final ChatLocalDataSource _localDataSource;
  final IChatRemoteDataSource _remoteDataSource;
  final IAuthLocalDataSource _authLocalDataSource;
  final GraphQLClientWrapper _graphQLClient;

  /// Constructor with enterprise dependencies
  ChatRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._authLocalDataSource,
    this._graphQLClient, {
    required super.networkInfo,
    required super.logger,
    required super.performanceMonitor,
  });

  @override
  GraphQLClient get client => _graphQLClient.client;

  @override
  Future<Either<Failure, List<Chat>>> getChats() async {
    return executeOfflineFirst<List<Chat>>(
      localDataSource: () async {
        final localChats = await _localDataSource.getChats();
        return localChats; // Already Chat entities
      },
      remoteDataSource: () async {
        // Get current user ID for mapper
        final currentUser = await _authLocalDataSource.getCurrentUser();
        final currentUserId = currentUser?.id ?? '';
        
        // Get DTOs from remote datasource
        final response = await _remoteDataSource.getConversationList();
        final dtos = response.conversations;
        
        // Convert DTOs to Models using mapper
        final models = ChatMapper.toModelList(dtos, currentUserId);
        
        // Convert Models to Domain entities
        return models.map((model) => model.toDomain()).toList();
      },
      cacheData: (chats) async {
        // Save chats to local storage
        await Future.wait(
          chats.map((chat) => _localDataSource.saveChat(chat))
        );
      },
      operationName: 'getChats',
    );
  }

  @override
  Future<Either<Failure, Chat?>> getChatById(String chatId) async {
    return executeOnlineFirst<Chat?>(
      remoteDataSource: () async {
        // Get current user ID for mapper
        final currentUser = await _authLocalDataSource.getCurrentUser();
        final currentUserId = currentUser?.id ?? '';
        
        // Get DTO from remote datasource
        final dto = await _remoteDataSource.getConversationDetail(chatId);
        
        // Convert DTO to Model using mapper
        final model = ChatMapper.toModel(dto, currentUserId);
        
        // Convert Model to Domain entity
        return model.toDomain();
      },
      localDataSource: () async {
        final localChat = await _localDataSource.getChatById(chatId);
        return localChat;
      },
      cacheData: (chat) async {
        if (chat != null) {
          await _localDataSource.saveChat(chat);
        }
      },
      operationName: 'getChatById',
    );
  }

  @override
  Future<Either<Failure, List<Chat>>> getChatsFromLocalStorage() async {
    return executeLocalOnly<List<Chat>>(
      localDataSource: () async {
        final localChats = await _localDataSource.getChats();
        return localChats; // Already Chat entities
      },
      operationName: 'getChatsFromLocalStorage',
    );
  }

  @override
  Future<Either<Failure, void>> saveChatLocally(Chat chat) async {
    return executeLocalOnly<void>(
      localDataSource: () async {
        await _localDataSource.saveChat(chat);
      },
      operationName: 'saveChatLocally',
    );
  }

  @override
  Future<Either<Failure, Chat>> createChat({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    return executeRemoteOnly<Chat>(
      remoteDataSource: () async {
        // Get current user ID for mapper
        final currentUser = await _authLocalDataSource.getCurrentUser();
        final currentUserId = currentUser?.id ?? '';

        if (isGroup) {
          // Create group chat
          final dto = await _remoteDataSource.createGroup(
            name: name,
            memberIds: participantIds,
          );
          
          // Convert DTO to Model using mapper
          final model = ChatMapper.toModel(dto, currentUserId);
          
          // Convert Model to Domain entity
          return model.toDomain();
        } else {
          // Direct chats are not created via API, they exist when first message is sent
          if (participantIds.length != 1) {
            throw core_exceptions.InvalidArgumentException(
              message: 'Direct chats must have exactly one participant'
            );
          }
          
          // For direct chats, we create a local placeholder
          // The actual conversation will be created when first message is sent
          throw core_exceptions.InvalidArgumentException(
            message: 'Direct chats are created automatically when sending first message'
          );
        }
      },
      cacheData: (chat) async {
        // Save new chat to local storage
        await _localDataSource.saveChat(chat);
      },
      operationName: 'createChat',
    );
  }

  @override
  Future<Either<Failure, Chat>> updateChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  }) async {
    return executeRemoteOnly<Chat>(
      remoteDataSource: () async {
        // Get current user ID for mapper
        final currentUser = await _authLocalDataSource.getCurrentUser();
        final currentUserId = currentUser?.id ?? '';
        
        // Update group via remote datasource
        final dto = await _remoteDataSource.updateGroup(
          conversationId: chatId,
          name: name,
          imageUrl: avatarUrl,
        );
        
        // Convert DTO to Model using mapper
        final model = ChatMapper.toModel(dto, currentUserId);
        
        // Convert Model to Domain entity
        return model.toDomain();
      },
      cacheData: (chat) async {
        // Save updated chat to local storage
        await _localDataSource.saveChat(chat);
      },
      operationName: 'updateChat',
    );
  }

  @override
  Future<Either<Failure, bool>> addParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    return executeRemoteOnly<bool>(
      remoteDataSource: () async {
        // Add members to group
        await _remoteDataSource.addMembersToGroup(
          conversationId: chatId,
          memberIds: userIds,
        );
        return true;
      },
      cacheData: (success) async {
        if (success) {
          // Sync chat to update participant list
          await syncChat(chatId);
        }
      },
      operationName: 'addParticipants',
    );
  }

  @override
  Future<Either<Failure, void>> syncChat(String chatId) async {
    return executeSyncStrategy(
      syncOperation: () async {
        logger.d('Starting chat synchronization for chat: $chatId');

        // Get current user ID for mapper
        final currentUser = await _authLocalDataSource.getCurrentUser();
        final currentUserId = currentUser?.id ?? '';

        // Get latest chat data from remote
        final dto = await _remoteDataSource.getConversationDetail(chatId);
        
        // Convert DTO to Model using mapper
        final model = ChatMapper.toModel(dto, currentUserId);

        // Update local cache
        await _localDataSource.saveChat(model.toDomain());

        logger.i('Chat synchronization completed for chat: $chatId');
      },
      operationName: 'syncChat',
    );
  }

  @override
  Future<Either<Failure, bool>> removeParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    return executeRemoteOnly<bool>(
      remoteDataSource: () async {
        // Remove members from group
        await _remoteDataSource.removeMembersFromGroup(
          conversationId: chatId,
          memberIds: userIds,
        );
        return true;
      },
      cacheData: (success) async {
        if (success) {
          // Sync chat to update participant list
          await syncChat(chatId);
        }
      },
      operationName: 'removeParticipants',
    );
  }

  @override
  Future<Either<Failure, bool>> leaveChat(String chatId) async {
    return executeRemoteOnly<bool>(
      remoteDataSource: () async {
        // Leave conversation
        await _remoteDataSource.leaveConversation(chatId);
        return true;
      },
      cacheData: (success) async {
        if (success) {
          // Remove chat from local storage
          await _localDataSource.deleteChat(chatId);
        }
      },
      operationName: 'leaveChat',
    );
  }

  @override
  Future<Either<Failure, bool>> deleteChat(String chatId) async {
    return executeRemoteOnly<bool>(
      remoteDataSource: () async {
        // Delete conversation
        await _remoteDataSource.deleteConversation(chatId);
        return true;
      },
      cacheData: (success) async {
        if (success) {
          // Remove chat from local storage
          await _localDataSource.deleteChat(chatId);
        }
      },
      operationName: 'deleteChat',
    );
  }

  @override
  Future<Either<Failure, bool>> markChatAsRead(String chatId) async {
    return executeLocalOnly<bool>(
      localDataSource: () async {
        await _localDataSource.markChatAsRead(chatId);
        return true;
      },
      operationName: 'markChatAsRead',
    );
  }

  @override
  Future<Either<Failure, List<Chat>>> searchChats(String searchTerm, {int limit = 20}) async {
    return executeOfflineFirst<List<Chat>>(
      localDataSource: () async {
        return await _localDataSource.searchChats(searchTerm, limit: limit);
      },
      remoteDataSource: () async {
        // Get current user ID for mapper
        final currentUser = await _authLocalDataSource.getCurrentUser();
        final currentUserId = currentUser?.id ?? '';
        
        // Search conversations via remote datasource
        final response = await _remoteDataSource.searchConversations(
          keyword: searchTerm,
          limit: limit,
        );
        final dtos = response.conversations;
        
        // Convert DTOs to Models using mapper
        final models = ChatMapper.toModelList(dtos, currentUserId);
        
        // Convert Models to Domain entities
        return models.map((model) => model.toDomain()).toList();
      },
      cacheData: (chats) async {
        // Cache search results
        await Future.wait(
          chats.map((chat) => _localDataSource.saveChat(chat))
        );
      },
      operationName: 'searchChats',
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(ChatMessage message) async {
    return executeOnlineFirst<ChatMessage>(
      remoteDataSource: () async {
        // Note: Message sending is handled by MessageRepository
        // This method is kept for backward compatibility
        throw core_exceptions.InvalidArgumentException(
          message: 'Use MessageRepository.sendMessage() instead'
        );
      },
      localDataSource: () async {
        // Save message locally with pending status
        await _localDataSource.saveMessage(message.chatId, message);
        return message;
      },
      cacheData: (sentMessage) async {
        // Update local message with server response
        await _localDataSource.saveMessage(sentMessage.chatId, sentMessage);
      },
      operationName: 'sendMessage',
    );
  }
}