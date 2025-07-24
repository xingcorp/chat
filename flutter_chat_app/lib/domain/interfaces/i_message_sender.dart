/// **MESSAGE SENDER INTERFACE - INTERFACE SEGREGATION PRINCIPLE**
///
/// Focused interface for sending messages only
/// Following ISP: clients depend only on methods they use
///
/// **Architecture:** Clean Architecture + SOLID principles

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';

/// **Message Sender Interface**
///
/// Single responsibility: Message sending operations
abstract class IMessageSender {
  /// Send real-time message
  Future<Either<Failure, bool>> sendMessage(ChatMessage message);
  
  /// Send typing indicator
  Future<Either<Failure, bool>> sendTypingIndicator({
    required String chatId,
    required bool isTyping,
  });
  
  /// Send read receipt
  Future<Either<Failure, bool>> sendReadReceipt({
    required String messageId,
    required String chatId,
  });
}
