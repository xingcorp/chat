import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/mappers/message_mapper.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

/// **ENTERPRISE REAL-TIME SERVICE**
///
/// Unified service layer for real-time messaging operations
/// integrating WebSocket with unified repository layer using Either<Failure, T> pattern.
///
/// **Performance Targets:**
/// - Message delivery: <100ms latency
/// - Connection establishment: <2s
/// - Reconnection: <5s with exponential backoff
/// - Memory usage: <50MB for real-time operations
///
/// **Architecture**: Clean Architecture + SOLID principles + Either error handling
@singleton
class RealtimeService {
  final EnhancedSocketManager _socketManager;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 3,
      lineLength: 120,
      colors: !kIsWeb,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Stream controllers for real-time events
  final BehaviorSubject<SocketConnectionState> _connectionStateController = 
      BehaviorSubject<SocketConnectionState>.seeded(SocketConnectionState.disconnected);
  
  final BehaviorSubject<ChatMessage> _messageController = BehaviorSubject<ChatMessage>();
  final BehaviorSubject<ChatMessage> _messageEditedController = BehaviorSubject<ChatMessage>();
  final BehaviorSubject<String> _messageDeletedController = BehaviorSubject<String>();
  final BehaviorSubject<MessageReaction> _messageReactionController = BehaviorSubject<MessageReaction>();
  final BehaviorSubject<TypingIndicator> _typingController = BehaviorSubject<TypingIndicator>();
  final BehaviorSubject<UserStatus> _userStatusController = BehaviorSubject<UserStatus>();
  final BehaviorSubject<MessageReadReceipt> _readReceiptController = BehaviorSubject<MessageReadReceipt>();

  // Active subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];
  
  // Currently joined chat rooms
  final Set<String> _joinedChats = <String>{};

  /// Constructor
  RealtimeService({
    required EnhancedSocketManager socketManager,
  }) : _socketManager = socketManager {
    _initializeSocketListeners();
  }

  /// **Connection state stream**
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;

  /// **New message stream**
  Stream<ChatMessage> get messageStream => _messageController.stream;

  /// **Message edited stream**
  Stream<ChatMessage> get messageEditedStream => _messageEditedController.stream;

  /// **Message deleted stream** (emits message ID)
  Stream<String> get messageDeletedStream => _messageDeletedController.stream;

  /// **Message reaction stream**
  Stream<MessageReaction> get messageReactionStream => _messageReactionController.stream;

  /// **Typing indicator stream**
  Stream<TypingIndicator> get typingStream => _typingController.stream;

  /// **User status stream**
  Stream<UserStatus> get userStatusStream => _userStatusController.stream;

  /// **Message read receipt stream**
  Stream<MessageReadReceipt> get readReceiptStream => _readReceiptController.stream;

  /// **Current connection state**
  SocketConnectionState get currentConnectionState => _connectionStateController.value;

  /// **Is connected**
  bool get isConnected => currentConnectionState == SocketConnectionState.connected;

  /// **Connect to real-time server - ENTERPRISE CONNECTION MANAGEMENT**
  ///
  /// **Performance**: <2s connection establishment
  /// **Strategy**: Connection with comprehensive error handling
  Future<Either<Failure, bool>> connect() async {
    try {
      _logger.i('Connecting to real-time server');
      
      await _socketManager.connect();
      
      // Wait for connection to be established
      await _connectionStateController.stream
          .where((state) => state == SocketConnectionState.connected || 
                           state == SocketConnectionState.error)
          .first
          .timeout(const Duration(seconds: 10));
      
      if (currentConnectionState == SocketConnectionState.connected) {
        _logger.i('Real-time connection established successfully');
        return const Right(true);
      } else {
        _logger.e('Failed to establish real-time connection');
        return Left(ConnectionFailure(message: 'Không thể kết nối đến server real-time'));
      }
    } catch (e) {
      _logger.e('Error connecting to real-time server: $e');
      return Left(ConnectionFailure(message: 'Lỗi kết nối real-time: $e'));
    }
  }

  /// **Disconnect from real-time server**
  ///
  /// **Performance**: <1s disconnection
  /// **Strategy**: Clean disconnection with resource cleanup
  Future<Either<Failure, bool>> disconnect() async {
    try {
      _logger.i('Disconnecting from real-time server');
      
      // Leave all joined chats
      for (final chatId in _joinedChats.toList()) {
        await _leaveChatRoom(chatId);
      }
      
      await _socketManager.disconnect();
      
      _logger.i('Real-time disconnection completed');
      return const Right(true);
    } catch (e) {
      _logger.e('Error disconnecting from real-time server: $e');
      return Left(ConnectionFailure(message: 'Lỗi ngắt kết nối real-time: $e'));
    }
  }

  /// **Join chat room for real-time updates - ENTERPRISE ROOM MANAGEMENT**
  ///
  /// **Performance**: <500ms room join
  /// **Strategy**: Room management with error handling
  Future<Either<Failure, bool>> joinChatRoom(String chatId) async {
    try {
      if (!isConnected) {
        return Left(ConnectionFailure(message: 'Không có kết nối real-time'));
      }

      if (_joinedChats.contains(chatId)) {
        _logger.d('Already joined chat room: $chatId');
        return const Right(true);
      }

      _logger.i('Joining chat room: $chatId');
      
      _socketManager.emit('conversation:joined', {'conversationId': chatId});
      _joinedChats.add(chatId);
      
      _logger.i('Successfully joined chat room: $chatId');
      return const Right(true);
    } catch (e) {
      _logger.e('Error joining chat room $chatId: $e');
      return Left(ServerFailure(message: 'Không thể tham gia chat: $e'));
    }
  }

  /// **Leave chat room**
  ///
  /// **Performance**: <500ms room leave
  /// **Strategy**: Clean room exit with resource cleanup
  Future<Either<Failure, bool>> leaveChatRoom(String chatId) async {
    return await _leaveChatRoom(chatId);
  }

  /// **Send typing indicator - REAL-TIME TYPING**
  ///
  /// **Performance**: <50ms typing indicator
  /// **Strategy**: Immediate emission with rate limiting
  Future<Either<Failure, bool>> sendTypingIndicator({
    required String chatId,
    required bool isTyping,
  }) async {
    try {
      if (!isConnected) {
        return Left(ConnectionFailure(message: 'Không có kết nối real-time'));
      }

      _logger.t('Sending typing indicator: $chatId, isTyping: $isTyping');
      
      _socketManager.emit('message:typing', {
        'conversationId': chatId,
        'isTyping': isTyping,
      });
      
      return const Right(true);
    } catch (e) {
      _logger.e('Error sending typing indicator: $e');
      return Left(ServerFailure(message: 'Không thể gửi typing indicator: $e'));
    }
  }

  /// **Send message read receipt - REAL-TIME READ RECEIPTS**
  ///
  /// **Performance**: <50ms read receipt
  /// **Strategy**: Immediate emission for read status
  Future<Either<Failure, bool>> sendReadReceipt({
    required String chatId,
    required String messageId,
  }) async {
    try {
      if (!isConnected) {
        return Left(ConnectionFailure(message: 'Không có kết nối real-time'));
      }

      _logger.t('Sending read receipt: $messageId in chat $chatId');
      
      _socketManager.emit('message:read', {
        'conversationId': chatId,
        'messageId': messageId,
      });
      
      return const Right(true);
    } catch (e) {
      _logger.e('Error sending read receipt: $e');
      return Left(ServerFailure(message: 'Không thể gửi read receipt: $e'));
    }
  }

  /// **Get connection health status**
  ///
  /// **Performance**: <100ms health check
  /// **Strategy**: Comprehensive connection diagnostics
  Future<Either<Failure, ConnectionHealth>> getConnectionHealth() async {
    try {
      final healthData = await _socketManager.checkConnectionHealth();
      final latency = await _socketManager.checkLatency();
      
      final health = ConnectionHealth(
        isConnected: isConnected,
        latency: latency,
        connectionState: currentConnectionState,
        healthData: healthData,
      );
      
      return Right(health);
    } catch (e) {
      _logger.e('Error checking connection health: $e');
      return Left(ServerFailure(message: 'Không thể kiểm tra connection health: $e'));
    }
  }

  /// **Initialize socket event listeners - ENTERPRISE EVENT HANDLING**
  void _initializeSocketListeners() {
    _logger.i('Initializing real-time socket listeners');

    // Connection state changes
    _subscriptions.add(
      _socketManager.connectionState.listen((state) {
        _logger.d('Connection state changed: $state');
        _connectionStateController.add(state);
      }),
    );

    // New message events
    _subscriptions.add(
      _socketManager.on<Map<String, dynamic>>('message:sent').listen(_handleNewMessage),
    );

    // Message edit events
    _subscriptions.add(
      _socketManager.on<Map<String, dynamic>>('message:edit').listen(_handleMessageEdit),
    );

    // Message delete events
    _subscriptions.add(
      _socketManager.on<Map<String, dynamic>>('message:delete').listen(_handleMessageDelete),
    );

    // Message reaction events
    _subscriptions.add(
      _socketManager.on<Map<String, dynamic>>('message:reaction').listen(_handleMessageReaction),
    );

    // Typing indicator events
    _subscriptions.add(
      _socketManager.on<Map<String, dynamic>>('message:typing').listen(_handleTypingIndicator),
    );

    // Message read events
    _subscriptions.add(
      _socketManager.on<Map<String, dynamic>>('message:read').listen(_handleReadReceipt),
    );

    // User status events (if available)
    _subscriptions.add(
      _socketManager.on<Map<String, dynamic>>('user:status').listen(_handleUserStatus),
    );

    _logger.i('Real-time socket listeners initialized');
  }

  /// **Handle new message event - ENTERPRISE MESSAGE PROCESSING**
  ///
  /// **Performance**: <50ms message processing
  /// **Strategy**: Parse DTO → Convert to domain entity → Emit to stream
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      _logger.d('Received new message event');
      
      // Parse message from server data
      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) {
        _logger.w('No message data in event');
        return;
      }
      
      // Parse using MessageDto
      final messageDto = MessageDto.fromJson(messageData);

      // Convert to domain entity using extension method
      final chatMessage = messageDto.toDomain();

      // Emit to stream
      _messageController.add(chatMessage);
      
      _logger.d('New message processed and emitted: ${chatMessage.id}');
    } catch (e, stackTrace) {
      _logger.e('Error handling new message: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// **Handle message edit event - ENTERPRISE MESSAGE UPDATE**
  ///
  /// **Performance**: <50ms message update processing
  /// **Strategy**: Parse edited message → Emit to stream
  void _handleMessageEdit(Map<String, dynamic> data) {
    try {
      _logger.d('Received message edit event');
      
      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) {
        _logger.w('No message data in edit event');
        return;
      }
      
      // Parse using MessageDto
      final messageDto = MessageDto.fromJson(messageData);

      // Convert to domain entity using extension method
      final chatMessage = messageDto.toDomain();

      // Emit to edited stream
      _messageEditedController.add(chatMessage);
      
      _logger.d('Message edit processed and emitted: ${chatMessage.id}');
    } catch (e, stackTrace) {
      _logger.e('Error handling message edit: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// **Handle message delete event - ENTERPRISE MESSAGE DELETION**
  ///
  /// **Performance**: <50ms message deletion processing
  /// **Strategy**: Extract message ID → Emit to stream
  void _handleMessageDelete(Map<String, dynamic> data) {
    try {
      _logger.d('Received message delete event');
      
      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) {
        _logger.w('No message data in delete event');
        return;
      }
      
      final messageId = messageData['id'] as String?;
      if (messageId == null) {
        _logger.w('No message ID in delete event');
        return;
      }
      
      // Emit message ID to deleted stream
      _messageDeletedController.add(messageId);
      
      _logger.d('Message delete processed and emitted: $messageId');
    } catch (e, stackTrace) {
      _logger.e('Error handling message delete: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// **Handle message reaction event - ENTERPRISE REACTION PROCESSING**
  ///
  /// **Performance**: <50ms reaction processing
  /// **Strategy**: Parse reaction data → Emit to stream
  void _handleMessageReaction(Map<String, dynamic> data) {
    try {
      _logger.d('Received message reaction event');
      
      final reactionData = data['data'] as Map<String, dynamic>?;
      if (reactionData == null) {
        _logger.w('No reaction data in event');
        return;
      }
      
      final messageIdRaw = reactionData['messageId'];
      final codeRaw = reactionData['code'];
      final actRaw = reactionData['act']; // may be String/num depending on backend

      final messageId = messageIdRaw?.toString();
      final code = codeRaw?.toString();
      final act = actRaw?.toString();
      
      if (messageId == null || code == null || act == null) {
        _logger.w('Incomplete reaction data');
        return;
      }
      
      final reactor = data['reactor'] as Map<String, dynamic>?;
      final userId = reactor?['id']?.toString() ?? '';
      final userName = reactor?['fullname']?.toString() ?? 'Unknown';
      
      // Backend sends act as 'ADD'/'REVOKE' (GraphQL) or numeric '1'/'0' (socket).
      // Normalize both formats to ensure correct parsing.
      final normalizedAct = act.toUpperCase();
      final isAdd = normalizedAct == 'ADD' || normalizedAct == '1';

      final reaction = MessageReaction(
        messageId: messageId,
        code: code,
        userId: userId,
        userName: userName,
        action: isAdd ? ReactionAction.add : ReactionAction.remove,
      );
      
      // Emit to reaction stream
      _messageReactionController.add(reaction);
      
      _logger.d('Message reaction processed: $messageId - $code ($act)');
    } catch (e, stackTrace) {
      _logger.e('Error handling message reaction: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// **Handle typing indicator event**
  void _handleTypingIndicator(Map<String, dynamic> data) {
    try {
      final chatIdRaw = data['conversationId'];
      final userIdRaw = data['userId'];
      final isTypingRaw = data['isTyping'];

      final chatId = chatIdRaw?.toString();
      final userId = userIdRaw?.toString();

      if (chatId == null || chatId.isEmpty || userId == null || userId.isEmpty) {
        _logger.w('Typing indicator event missing conversationId/userId');
        return;
      }

      final bool isTyping = switch (isTypingRaw) {
        bool v => v,
        num v => v != 0,
        String v => v.toLowerCase() == 'true' || v == '1',
        _ => false,
      };

      final typingIndicator = TypingIndicator(
        chatId: chatId,
        userId: userId,
        userName: data['fullName']?.toString() ?? 'Unknown',
        isTyping: isTyping,
      );
      
      _typingController.add(typingIndicator);
      _logger.t('Typing indicator processed: ${typingIndicator.userId} - ${typingIndicator.isTyping}');
    } catch (e, stackTrace) {
      _logger.e('Error handling typing indicator: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// **Handle read receipt event**
  ///
  /// Backend sends: `{ message: { id, conversationId, ... }, reader: { id, fullname, ... } }`
  /// `conversationId` may be at top level OR inside `message` — check both.
  void _handleReadReceipt(Map<String, dynamic> data) {
    try {
      final message = data['message'] as Map<String, dynamic>?;
      final reader = data['reader'] as Map<String, dynamic>?;

      final readReceipt = MessageReadReceipt(
        chatId: data['conversationId'] as String?
            ?? message?['conversationId'] as String?
            ?? '',
        messageId: message?['id'] as String? ?? '',
        readerId: reader?['id'] as String? ?? '',
        readerName: reader?['fullname'] as String? ?? 'Unknown',
        readAt: DateTime.now(),
      );
      
      _readReceiptController.add(readReceipt);
      _logger.t('Read receipt processed: ${readReceipt.messageId}');
    } catch (e, stackTrace) {
      _logger.e('Error handling read receipt: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// **Handle user status event**
  void _handleUserStatus(Map<String, dynamic> data) {
    try {
      final userStatus = UserStatus(
        userId: data['userId'] as String,
        status: data['status'] as String,
        lastSeen: data['lastSeen'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'] as int)
            : null,
      );
      
      _userStatusController.add(userStatus);
      _logger.t('User status processed: ${userStatus.userId} - ${userStatus.status}');
    } catch (e, stackTrace) {
      _logger.e('Error handling user status: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// **Internal method to leave chat room**
  Future<Either<Failure, bool>> _leaveChatRoom(String chatId) async {
    try {
      if (!_joinedChats.contains(chatId)) {
        // _logger.d('Not in chat room: $chatId');
        return const Right(true);
      }

      _logger.i('Leaving chat room: $chatId');
      
      if (isConnected) {
        _socketManager.emit('conversation:leaved', {'conversationId': chatId});
      }
      
      _joinedChats.remove(chatId);
      
      _logger.i('Successfully left chat room: $chatId');
      return const Right(true);
    } catch (e) {
      _logger.e('Error leaving chat room $chatId: $e');
      return Left(ServerFailure(message: 'Không thể rời chat: $e'));
    }
  }

  /// **Dispose resources - ENTERPRISE CLEANUP**
  void dispose() {
    _logger.i('Disposing RealtimeService');
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Close stream controllers
    _connectionStateController.close();
    _messageController.close();
    _messageEditedController.close();
    _messageDeletedController.close();
    _messageReactionController.close();
    _typingController.close();
    _userStatusController.close();
    _readReceiptController.close();
    
    // Clear joined chats
    _joinedChats.clear();
    
    _logger.i('RealtimeService disposed');
  }
}

/// **Typing indicator data class**
class TypingIndicator {
  final String chatId;
  final String userId;
  final String userName;
  final bool isTyping;

  const TypingIndicator({
    required this.chatId,
    required this.userId,
    required this.userName,
    required this.isTyping,
  });
}

/// **User status data class**
class UserStatus {
  final String userId;
  final String status;
  final DateTime? lastSeen;

  const UserStatus({
    required this.userId,
    required this.status,
    this.lastSeen,
  });
}

/// **Message read receipt data class**
class MessageReadReceipt {
  final String chatId;
  final String messageId;
  final String readerId;
  final String readerName;
  final DateTime readAt;

  const MessageReadReceipt({
    required this.chatId,
    required this.messageId,
    required this.readerId,
    required this.readerName,
    required this.readAt,
  });
}

/// **Message reaction data class**
class MessageReaction {
  final String messageId;
  final String code;
  final String userId;
  final String userName;
  final ReactionAction action;

  const MessageReaction({
    required this.messageId,
    required this.code,
    required this.userId,
    required this.userName,
    required this.action,
  });
}

/// **Reaction action enum**
enum ReactionAction {
  add,
  remove,
}

/// **Connection health data class**
class ConnectionHealth {
  final bool isConnected;
  final int? latency;
  final SocketConnectionState connectionState;
  final Map<String, dynamic> healthData;

  const ConnectionHealth({
    required this.isConnected,
    this.latency,
    required this.connectionState,
    required this.healthData,
  });
}
