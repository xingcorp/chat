/// **MESSAGE RECEIVER INTERFACE - INTERFACE SEGREGATION PRINCIPLE**
///
/// Focused interface for receiving messages only
/// Following ISP: clients depend only on methods they use
///
/// **Architecture:** Clean Architecture + SOLID principles

import 'package:flutter_chat_app/core/services/messaging_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';

/// **Message Receiver Interface**
///
/// Single responsibility: Message receiving operations
abstract class IMessageReceiver {
  /// Stream of incoming messages
  Stream<ChatMessage> get messageStream;
  
  /// Stream of typing indicators
  Stream<TypingIndicator> get typingStream;
  
  /// Stream of user status updates
  Stream<UserStatus> get userStatusStream;
  
  /// Stream of read receipts
  Stream<ReadReceipt> get readReceiptStream;
}
