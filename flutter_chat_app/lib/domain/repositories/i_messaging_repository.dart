/// **MESSAGING REPOSITORY INTERFACE - DEPENDENCY INVERSION PRINCIPLE**
///
/// Abstract interface for messaging operations
/// Following DIP: high-level modules depend on abstractions
///
/// **Architecture:** Clean Architecture + SOLID principles

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// **Messaging Repository Interface**
///
/// Abstract interface for all messaging operations
/// Implementation will be in data layer
abstract class IMessagingRepository {
  /// Get messages for a chat
  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId);
  
  /// Send a message
  Future<Either<Failure, ChatMessage>> sendMessage(ChatMessage message);
  
  /// Update message status
  Future<Either<Failure, ChatMessage>> updateMessageStatus(
    String messageId,
    String status,
  );
  
  /// Delete a message
  Future<Either<Failure, bool>> deleteMessage(String messageId);
  
  /// Search messages
  Future<Either<Failure, List<ChatMessage>>> searchMessages(
    String query,
    String chatId,
  );
  
  /// Get message by ID
  Future<Either<Failure, ChatMessage>> getMessageById(String messageId);
  
  /// Watch messages stream
  Stream<ChatMessage> watchMessages(String chatId);
  
  /// Mark messages as read
  Future<Either<Failure, bool>> markMessagesAsRead(
    String chatId,
    List<String> messageIds,
  );
}
