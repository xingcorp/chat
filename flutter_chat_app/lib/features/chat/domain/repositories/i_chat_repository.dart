import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/pagination/page_request.dart';
import 'package:flutter_chat_app/core/pagination/paged_result.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// **ENTERPRISE CHAT REPOSITORY INTERFACE**
///
/// Defines chat repository operations using Either pattern for comprehensive
/// error handling and enterprise-grade reliability.
///
/// **Error Handling**: All operations return Either<Failure, T> for proper error management
/// **Performance**: Operations are monitored and optimized for enterprise scale
/// **Caching**: Supports offline-first and online-first strategies for chat data
/// **Real-time**: Optimized for real-time messaging with WhatsApp/Telegram-level performance
abstract class IChatRepository {
  /// Lấy client GraphQL để thực hiện các truy vấn
  GraphQLClient get client;

  /// Get user's chat list with offline-first strategy (cached data)
  Future<Either<Failure, List<Chat>>> getChats();

  /// Get user's chat list by page with offline-first strategy.
  Future<Either<Failure, PagedResult<Chat>>> getChatsPage(PageRequest request);

  /// Get chat details by ID with online-first strategy (fresh data)
  Future<Either<Failure, Chat?>> getChatById(String chatId);

  /// Get chat list from local storage (local-only strategy)
  Future<Either<Failure, List<Chat>>> getChatsFromLocalStorage();

  /// Save chat to local storage (local-only strategy)
  Future<Either<Failure, void>> saveChatLocally(Chat chat);

  /// Create new chat with remote-only strategy (server confirmation required)
  Future<Either<Failure, Chat>> createChat({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  });

  /// Update chat information with remote-only strategy (server confirmation required)
  Future<Either<Failure, Chat>> updateChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  });

  /// Add participants to chat with remote-only strategy
  Future<Either<Failure, bool>> addParticipants({
    required String chatId,
    required List<String> userIds,
  });

  /// Remove participants from chat with remote-only strategy
  Future<Either<Failure, bool>> removeParticipants({
    required String chatId,
    required List<String> userIds,
  });

  /// Leave chat with remote-only strategy
  Future<Either<Failure, bool>> leaveChat(String chatId);

  /// Delete chat with remote-only strategy
  Future<Either<Failure, bool>> deleteChat(String chatId);

  /// Mark chat as read with local-only strategy (immediate UI feedback)
  Future<Either<Failure, bool>> markChatAsRead(String chatId);

  /// Synchronize chat data with sync strategy (background operation)
  Future<Either<Failure, void>> syncChat(String chatId);

  /// **Send Message**
  ///
  /// Sends a message with optimistic UI updates and enterprise error handling.
  /// Uses offline-first strategy with automatic retry and sync.
  Future<Either<Failure, ChatMessage>> sendMessage(ChatMessage message);

  /// **Search Chats**
  ///
  /// Searches chats by name or content with enterprise performance optimization.
  /// Uses local-first strategy for instant results with optional remote search.
  Future<Either<Failure, List<Chat>>> searchChats(String searchTerm, {int limit = 20});
}