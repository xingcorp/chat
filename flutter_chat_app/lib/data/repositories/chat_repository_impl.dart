import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/exceptions/exceptions.dart' as core_exceptions;
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
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
  final ChatRemoteDataSource _remoteDataSource;
  final GraphQLClientWrapper _graphQLClient;

  /// Constructor with enterprise dependencies
  ChatRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
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
        final remoteChatModels = await _remoteDataSource.getUserChats();
        return remoteChatModels.map((model) => model.toDomain()).toList();
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
        final remoteChatModel = await _remoteDataSource.getChatDetails(chatId);
        return remoteChatModel.toDomain();
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
        final ChatModel result;

        if (isGroup) {
          result = await _remoteDataSource.createGroupChat(name, participantIds);
        } else {
          if (participantIds.length != 1) {
            throw core_exceptions.InvalidArgumentException(
              message: 'Direct chats must have exactly one participant'
            );
          }
          result = await _remoteDataSource.createDirectChat(participantIds.first);
        }

        return result.toDomain();
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
        final result = await _remoteDataSource.updateChat(
          chatId,
          name: name,
          avatarUrl: avatarUrl,
        );

        return result.toDomain();
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
        return await _remoteDataSource.addUsersToChat(chatId, userIds);
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

        // Get latest chat data from remote
        final remoteChatModel = await _remoteDataSource.getChatDetails(chatId);

        // Update local cache
        await _localDataSource.saveChat(remoteChatModel.toDomain());

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
        // TODO: Implement proper participant removal in remote data source
        return await _remoteDataSource.removeUsersFromChat(chatId, userIds);
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
        // TODO: Implement proper chat leaving in remote data source
        return await _remoteDataSource.leaveChat(chatId);
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
        // TODO: Implement proper chat deletion in remote data source
        return await _remoteDataSource.deleteChat(chatId);
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
}