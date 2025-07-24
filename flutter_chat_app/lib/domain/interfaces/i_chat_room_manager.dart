/// **CHAT ROOM MANAGER INTERFACE - INTERFACE SEGREGATION PRINCIPLE**
///
/// Focused interface for chat room management only
/// Following ISP: clients depend only on methods they use
///
/// **Architecture:** Clean Architecture + SOLID principles

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// **Chat Room Manager Interface**
///
/// Single responsibility: Chat room operations
abstract class IChatRoomManager {
  /// Join a chat room
  Future<Either<Failure, bool>> joinChat(String chatId);
  
  /// Leave a chat room
  Future<Either<Failure, bool>> leaveChat(String chatId);
  
  /// Get list of joined chats
  Set<String> get joinedChats;
  
  /// Check if joined to specific chat
  bool isJoinedToChat(String chatId);
}
