/// **REALTIME MESSAGE BLOC**
///
/// Manages real-time messaging with WebSocket integration
/// Handles message sending, receiving, and connection state
///
/// **Features:**
/// - Real-time message delivery <100ms
/// - Connection state management
/// - Offline message queuing
/// - Typing indicators
/// - Read receipts
/// - Message status updates
///
/// **Architecture:** BLoC Pattern + Clean Architecture

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../../core/services/unified_websocket_service.dart';
import '../../../domain/entities/chat_message.dart';

/// **REALTIME MESSAGE EVENTS**
abstract class RealtimeMessageEvent extends Equatable {
  const RealtimeMessageEvent();

  @override
  List<Object?> get props => [];
}

class ConnectToRealtimeEvent extends RealtimeMessageEvent {
  final String? authToken;
  
  const ConnectToRealtimeEvent({this.authToken});
  
  @override
  List<Object?> get props => [authToken];
}

class DisconnectFromRealtimeEvent extends RealtimeMessageEvent {
  const DisconnectFromRealtimeEvent();
}

class SendRealtimeMessageEvent extends RealtimeMessageEvent {
  final String chatId;
  final String content;
  final String messageType;
  final MessagePriority priority;
  
  const SendRealtimeMessageEvent({
    required this.chatId,
    required this.content,
    required this.messageType,
    this.priority = MessagePriority.normal,
  });
  
  @override
  List<Object?> get props => [chatId, content, messageType, priority];
}

class SendTypingIndicatorEvent extends RealtimeMessageEvent {
  final String chatId;
  final bool isTyping;
  
  const SendTypingIndicatorEvent({
    required this.chatId,
    required this.isTyping,
  });
  
  @override
  List<Object?> get props => [chatId, isTyping];
}

class MarkMessageAsReadEvent extends RealtimeMessageEvent {
  final String chatId;
  final String messageId;
  
  const MarkMessageAsReadEvent({
    required this.chatId,
    required this.messageId,
  });
  
  @override
  List<Object?> get props => [chatId, messageId];
}

class RealtimeMessageReceivedEvent extends RealtimeMessageEvent {
  final WebSocketMessage message;
  
  const RealtimeMessageReceivedEvent(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// **REALTIME MESSAGE STATES**
abstract class RealtimeMessageState extends Equatable {
  const RealtimeMessageState();

  @override
  List<Object?> get props => [];
}

class RealtimeMessageInitial extends RealtimeMessageState {
  const RealtimeMessageInitial();
}

class RealtimeMessageConnecting extends RealtimeMessageState {
  const RealtimeMessageConnecting();
}

class RealtimeMessageConnected extends RealtimeMessageState {
  final WebSocketMetrics metrics;
  
  const RealtimeMessageConnected(this.metrics);
  
  @override
  List<Object?> get props => [metrics];
}

class RealtimeMessageDisconnected extends RealtimeMessageState {
  final String? reason;
  
  const RealtimeMessageDisconnected({this.reason});
  
  @override
  List<Object?> get props => [reason];
}

class RealtimeMessageError extends RealtimeMessageState {
  final String message;
  final String? code;
  
  const RealtimeMessageError({
    required this.message,
    this.code,
  });
  
  @override
  List<Object?> get props => [message, code];
}

class RealtimeMessageSending extends RealtimeMessageState {
  final String messageId;
  
  const RealtimeMessageSending(this.messageId);
  
  @override
  List<Object?> get props => [messageId];
}

class RealtimeMessageSent extends RealtimeMessageState {
  final String messageId;
  final DateTime timestamp;
  
  const RealtimeMessageSent({
    required this.messageId,
    required this.timestamp,
  });
  
  @override
  List<Object?> get props => [messageId, timestamp];
}

class RealtimeMessageReceived extends RealtimeMessageState {
  final ChatMessage message;
  
  const RealtimeMessageReceived(this.message);
  
  @override
  List<Object?> get props => [message];
}

class TypingIndicatorUpdated extends RealtimeMessageState {
  final String chatId;
  final List<String> typingUsers;
  
  const TypingIndicatorUpdated({
    required this.chatId,
    required this.typingUsers,
  });
  
  @override
  List<Object?> get props => [chatId, typingUsers];
}

class MessageStatusUpdated extends RealtimeMessageState {
  final String messageId;
  final String status;
  final DateTime timestamp;
  
  const MessageStatusUpdated({
    required this.messageId,
    required this.status,
    required this.timestamp,
  });
  
  @override
  List<Object?> get props => [messageId, status, timestamp];
}

/// **REALTIME MESSAGE BLOC**
@injectable
class RealtimeMessageBloc extends Bloc<RealtimeMessageEvent, RealtimeMessageState> {
  final UnifiedWebSocketService _webSocketService;
  final Logger _logger = Logger();
  
  // Subscriptions
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;
  StreamSubscription<WebSocketMessage>? _messageSubscription;
  StreamSubscription<WebSocketMetrics>? _metricsSubscription;
  
  // State tracking
  final Map<String, List<String>> _typingUsers = {};
  final Map<String, DateTime> _lastTypingUpdate = {};
  static const Duration _typingTimeout = Duration(seconds: 3);

  /// Constructor
  RealtimeMessageBloc(this._webSocketService) : super(const RealtimeMessageInitial()) {
    // Register event handlers
    on<ConnectToRealtimeEvent>(_onConnectToRealtime);
    on<DisconnectFromRealtimeEvent>(_onDisconnectFromRealtime);
    on<SendRealtimeMessageEvent>(_onSendRealtimeMessage);
    on<SendTypingIndicatorEvent>(_onSendTypingIndicator);
    on<MarkMessageAsReadEvent>(_onMarkMessageAsRead);
    on<RealtimeMessageReceivedEvent>(_onRealtimeMessageReceived);
    
    _initializeWebSocketListeners();
    _logger.i('🚀 RealtimeMessageBloc initialized');
  }

  /// Initialize WebSocket listeners
  void _initializeWebSocketListeners() {
    // Connection state listener
    _connectionSubscription = _webSocketService.connectionState.listen((state) {
      switch (state) {
        case WebSocketConnectionState.connecting:
          emit(const RealtimeMessageConnecting());
          break;
        case WebSocketConnectionState.connected:
          // Will be updated when metrics arrive
          break;
        case WebSocketConnectionState.disconnected:
          emit(const RealtimeMessageDisconnected());
          break;
        case WebSocketConnectionState.reconnecting:
          emit(const RealtimeMessageConnecting());
          break;
        case WebSocketConnectionState.error:
          emit(const RealtimeMessageError(message: 'Connection error'));
          break;
      }
    });

    // Message listener
    _messageSubscription = _webSocketService.messages.listen((message) {
      add(RealtimeMessageReceivedEvent(message));
    });

    // Metrics listener
    _metricsSubscription = _webSocketService.metrics.listen((metrics) {
      if (_webSocketService.isConnected) {
        emit(RealtimeMessageConnected(metrics));
      }
    });
  }

  /// Connect to realtime service
  Future<void> _onConnectToRealtime(
    ConnectToRealtimeEvent event,
    Emitter<RealtimeMessageState> emit,
  ) async {
    try {
      emit(const RealtimeMessageConnecting());
      _logger.i('🔌 Connecting to realtime service...');
      
      final result = await _webSocketService.connect(authToken: event.authToken);
      
      result.fold(
        (error) {
          _logger.e('❌ Connection failed: $error');
          emit(RealtimeMessageError(message: error));
        },
        (success) {
          _logger.i('✅ Connected to realtime service');
          // State will be updated by metrics listener
        },
      );
      
    } catch (e) {
      _logger.e('💥 Connection error: $e');
      emit(RealtimeMessageError(message: 'Connection failed: $e'));
    }
  }

  /// Disconnect from realtime service
  Future<void> _onDisconnectFromRealtime(
    DisconnectFromRealtimeEvent event,
    Emitter<RealtimeMessageState> emit,
  ) async {
    try {
      _logger.i('🔌 Disconnecting from realtime service...');
      
      final result = await _webSocketService.disconnect();
      
      result.fold(
        (error) {
          _logger.e('❌ Disconnect failed: $error');
          emit(RealtimeMessageError(message: error));
        },
        (success) {
          _logger.i('✅ Disconnected from realtime service');
          emit(const RealtimeMessageDisconnected());
        },
      );
      
    } catch (e) {
      _logger.e('💥 Disconnect error: $e');
      emit(RealtimeMessageError(message: 'Disconnect failed: $e'));
    }
  }

  /// Send realtime message
  Future<void> _onSendRealtimeMessage(
    SendRealtimeMessageEvent event,
    Emitter<RealtimeMessageState> emit,
  ) async {
    try {
      final messageId = _generateMessageId();
      emit(RealtimeMessageSending(messageId));
      
      _logger.d('📤 Sending message to chat ${event.chatId}');
      
      final result = await _webSocketService.sendMessage(
        type: 'chat_message',
        data: {
          'messageId': messageId,
          'chatId': event.chatId,
          'content': event.content,
          'messageType': event.messageType,
          'timestamp': DateTime.now().toIso8601String(),
        },
        priority: event.priority,
      );
      
      result.fold(
        (error) {
          _logger.e('❌ Send message failed: $error');
          emit(RealtimeMessageError(message: error));
        },
        (success) {
          _logger.d('✅ Message sent successfully');
          emit(RealtimeMessageSent(
            messageId: messageId,
            timestamp: DateTime.now(),
          ));
        },
      );
      
    } catch (e) {
      _logger.e('💥 Send message error: $e');
      emit(RealtimeMessageError(message: 'Send failed: $e'));
    }
  }

  /// Send typing indicator
  Future<void> _onSendTypingIndicator(
    SendTypingIndicatorEvent event,
    Emitter<RealtimeMessageState> emit,
  ) async {
    try {
      _logger.t('⌨️ Sending typing indicator: ${event.isTyping}');
      
      final result = await _webSocketService.sendMessage(
        type: 'typing_indicator',
        data: {
          'chatId': event.chatId,
          'isTyping': event.isTyping,
          'timestamp': DateTime.now().toIso8601String(),
        },
        priority: MessagePriority.low,
      );
      
      result.fold(
        (error) => _logger.w('⚠️ Typing indicator failed: $error'),
        (success) => _logger.t('✅ Typing indicator sent'),
      );
      
    } catch (e) {
      _logger.w('⚠️ Typing indicator error: $e');
    }
  }

  /// Mark message as read
  Future<void> _onMarkMessageAsRead(
    MarkMessageAsReadEvent event,
    Emitter<RealtimeMessageState> emit,
  ) async {
    try {
      _logger.t('👁️ Marking message as read: ${event.messageId}');
      
      final result = await _webSocketService.sendMessage(
        type: 'message_read',
        data: {
          'chatId': event.chatId,
          'messageId': event.messageId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        priority: MessagePriority.low,
      );
      
      result.fold(
        (error) => _logger.w('⚠️ Read receipt failed: $error'),
        (success) => _logger.t('✅ Read receipt sent'),
      );
      
    } catch (e) {
      _logger.w('⚠️ Read receipt error: $e');
    }
  }

  /// Handle received realtime message
  Future<void> _onRealtimeMessageReceived(
    RealtimeMessageReceivedEvent event,
    Emitter<RealtimeMessageState> emit,
  ) async {
    try {
      final message = event.message;
      _logger.d('📥 Received realtime message: ${message.type}');
      
      switch (message.type) {
        case 'chat_message':
          _handleChatMessage(message, emit);
          break;
        case 'typing_indicator':
          _handleTypingIndicator(message, emit);
          break;
        case 'message_status':
          _handleMessageStatus(message, emit);
          break;
        case 'message_read':
          _handleMessageRead(message, emit);
          break;
        default:
          _logger.w('⚠️ Unknown message type: ${message.type}');
      }
      
    } catch (e) {
      _logger.e('💥 Handle message error: $e');
    }
  }

  /// Handle chat message
  void _handleChatMessage(WebSocketMessage message, Emitter<RealtimeMessageState> emit) {
    try {
      final data = message.data;
      final chatMessage = ChatMessage(
        id: data['messageId'] ?? message.id,
        chatId: data['chatId'] ?? '',
        content: data['content'] ?? '',
        contentType: _parseContentType(data['messageType'] ?? 'text'),
        sender: MessageSender(
          id: data['senderId'] ?? '',
          name: data['senderName'] ?? 'Unknown',
          avatar: data['senderAvatar'],
        ),
        createdAt: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      );
      
      emit(RealtimeMessageReceived(chatMessage));
      _logger.d('✅ Chat message processed: ${chatMessage.id}');
      
    } catch (e) {
      _logger.e('💥 Chat message processing error: $e');
    }
  }

  /// Handle typing indicator
  void _handleTypingIndicator(WebSocketMessage message, Emitter<RealtimeMessageState> emit) {
    try {
      final data = message.data;
      final chatId = data['chatId'] as String;
      final userId = data['userId'] as String;
      final isTyping = data['isTyping'] as bool;
      
      _typingUsers[chatId] ??= [];
      
      if (isTyping) {
        if (!_typingUsers[chatId]!.contains(userId)) {
          _typingUsers[chatId]!.add(userId);
        }
        _lastTypingUpdate[userId] = DateTime.now();
      } else {
        _typingUsers[chatId]!.remove(userId);
        _lastTypingUpdate.remove(userId);
      }
      
      emit(TypingIndicatorUpdated(
        chatId: chatId,
        typingUsers: List.from(_typingUsers[chatId]!),
      ));
      
      _logger.t('⌨️ Typing indicator updated for chat $chatId');
      
    } catch (e) {
      _logger.e('💥 Typing indicator processing error: $e');
    }
  }

  /// Handle message status
  void _handleMessageStatus(WebSocketMessage message, Emitter<RealtimeMessageState> emit) {
    try {
      final data = message.data;
      final messageId = data['messageId'] as String;
      final status = data['status'] as String;
      final timestamp = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();
      
      emit(MessageStatusUpdated(
        messageId: messageId,
        status: status,
        timestamp: timestamp,
      ));
      
      _logger.t('📊 Message status updated: $messageId -> $status');
      
    } catch (e) {
      _logger.e('💥 Message status processing error: $e');
    }
  }

  /// Handle message read
  void _handleMessageRead(WebSocketMessage message, Emitter<RealtimeMessageState> emit) {
    try {
      final data = message.data;
      final messageId = data['messageId'] as String;
      final timestamp = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();
      
      emit(MessageStatusUpdated(
        messageId: messageId,
        status: 'read',
        timestamp: timestamp,
      ));
      
      _logger.t('👁️ Message read receipt: $messageId');
      
    } catch (e) {
      _logger.e('💥 Message read processing error: $e');
    }
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Parse content type from string
  ContentType _parseContentType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return ContentType.text;
      case 'image':
        return ContentType.image;
      case 'video':
        return ContentType.video;
      case 'audio':
        return ContentType.audio;
      case 'file':
        return ContentType.file;
      case 'location':
        return ContentType.location;
      case 'link':
        return ContentType.link;
      case 'event':
        return ContentType.event;
      default:
        return ContentType.text;
    }
  }

  /// Clean up typing indicators
  void _cleanupTypingIndicators() {
    final now = DateTime.now();
    final expiredUsers = <String>[];

    for (final entry in _lastTypingUpdate.entries) {
      if (now.difference(entry.value) > _typingTimeout) {
        expiredUsers.add(entry.key);
      }
    }

    for (final userId in expiredUsers) {
      _lastTypingUpdate.remove(userId);
      for (final chatUsers in _typingUsers.values) {
        chatUsers.remove(userId);
      }
    }
  }

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _metricsSubscription?.cancel();
    await _webSocketService.dispose();
    return super.close();
  }
}
