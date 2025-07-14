# Real-time Messaging Rules - Enterprise Performance Standards

**Type**: Auto  
**Description**: Comprehensive real-time messaging implementation with <100ms delivery, offline-first architecture, and enterprise scalability

## Performance Requirements

### Messaging Performance Targets
- **Message Delivery**: <100ms end-to-end
- **Connection Establishment**: <2s initial connect
- **Reconnection Time**: <5s after network recovery
- **Memory Usage**: <150MB for 10,000+ messages
- **Battery Optimization**: Minimal background drain
- **Offline Queue**: Support 1,000+ pending messages

## WebSocket Architecture

### Connection Management
```dart
class WebSocketManager {
  static const int _maxReconnectAttempts = 5;
  static const List<int> _backoffDelays = [1000, 2000, 4000, 8000, 16000];
  
  final String _url;
  final AuthService _authService;
  final Logger _logger;
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  
  Stream<ConnectionState> get connectionState => _connectionStateController.stream;
  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  
  Future<void> connect() async {
    if (_isConnecting || _channel != null) return;
    
    _isConnecting = true;
    _connectionStateController.add(ConnectionState.connecting);
    
    try {
      final token = await _authService.getAccessToken();
      final uri = Uri.parse('$_url?token=$token');
      
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      
      _setupMessageListener();
      _startHeartbeat();
      _resetReconnectAttempts();
      
      _connectionStateController.add(ConnectionState.connected);
      _logger.i('WebSocket connected successfully');
      
    } catch (e) {
      _logger.e('WebSocket connection failed: $e');
      _handleConnectionError();
    } finally {
      _isConnecting = false;
    }
  }
  
  void _setupMessageListener() {
    _subscription = _channel!.stream.listen(
      (data) => _handleIncomingMessage(data),
      onError: (error) => _handleConnectionError(),
      onDone: () => _handleConnectionClosed(),
    );
  }
  
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_channel != null) {
        _sendMessage(WebSocketMessage.heartbeat());
      }
    });
  }
  
  void _handleConnectionError() {
    _connectionStateController.add(ConnectionState.disconnected);
    _cleanup();
    
    if (_shouldReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      _connectionStateController.add(ConnectionState.failed);
    }
  }
  
  void _scheduleReconnect() {
    final delay = _backoffDelays[
      math.min(_reconnectAttempts, _backoffDelays.length - 1)
    ];
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      _reconnectAttempts++;
      connect();
    });
    
    _logger.i('Scheduling reconnect attempt $_reconnectAttempts in ${delay}ms');
  }
}
```

### Message Queue & Offline Support
```dart
class MessageQueue {
  final IsarService _isarService;
  final NetworkInfo _networkInfo;
  final WebSocketManager _webSocketManager;
  
  final Queue<PendingMessage> _pendingMessages = Queue();
  final _processingController = StreamController<bool>.broadcast();
  
  Stream<bool> get isProcessing => _processingController.stream;
  
  Future<void> queueMessage(MessageModel message) async {
    final pendingMessage = PendingMessage(
      id: message.localId,
      message: message,
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    
    // Save to local storage immediately
    await _isarService.savePendingMessage(pendingMessage);
    _pendingMessages.add(pendingMessage);
    
    // Try to send immediately if online
    if (await _networkInfo.isConnected) {
      _processQueue();
    }
  }
  
  Future<void> _processQueue() async {
    if (_pendingMessages.isEmpty || !await _networkInfo.isConnected) return;
    
    _processingController.add(true);
    
    while (_pendingMessages.isNotEmpty) {
      final pendingMessage = _pendingMessages.first;
      
      try {
        await _sendMessage(pendingMessage.message);
        
        // Remove from queue and local storage on success
        _pendingMessages.removeFirst();
        await _isarService.deletePendingMessage(pendingMessage.id);
        
      } catch (e) {
        _logger.e('Failed to send queued message: $e');
        
        // Increment retry count
        pendingMessage.retryCount++;
        
        if (pendingMessage.retryCount >= 3) {
          // Move to failed queue after 3 attempts
          _pendingMessages.removeFirst();
          await _isarService.markMessageAsFailed(pendingMessage.id);
        } else {
          // Retry later
          break;
        }
      }
    }
    
    _processingController.add(false);
  }
  
  Future<void> _sendMessage(MessageModel message) async {
    final webSocketMessage = WebSocketMessage.sendMessage(
      conversationId: message.chatId,
      content: message.content,
      type: message.type,
      tempId: message.localId,
    );
    
    _webSocketManager.sendMessage(webSocketMessage);
    
    // Wait for acknowledgment with timeout
    final ackReceived = await _waitForAcknowledgment(message.localId)
        .timeout(Duration(seconds: 10));
    
    if (!ackReceived) {
      throw TimeoutException('Message acknowledgment timeout');
    }
  }
}
```

## Message Status Tracking

### Delivery Status Implementation
```dart
enum MessageStatus {
  sending,    // Optimistic update, not yet sent
  sent,       // Sent to server, not delivered
  delivered,  // Delivered to recipient's device
  read,       // Read by recipient
  failed,     // Failed to send
}

class MessageStatusTracker {
  final Map<String, MessageStatus> _messageStatuses = {};
  final _statusController = StreamController<MessageStatusUpdate>.broadcast();
  
  Stream<MessageStatusUpdate> get statusUpdates => _statusController.stream;
  
  void updateMessageStatus(String messageId, MessageStatus status) {
    final previousStatus = _messageStatuses[messageId];
    _messageStatuses[messageId] = status;
    
    _statusController.add(MessageStatusUpdate(
      messageId: messageId,
      status: status,
      previousStatus: previousStatus,
      timestamp: DateTime.now(),
    ));
  }
  
  MessageStatus getMessageStatus(String messageId) {
    return _messageStatuses[messageId] ?? MessageStatus.sending;
  }
  
  void handleDeliveryReceipt(String messageId, List<String> deliveredTo) {
    if (deliveredTo.isNotEmpty) {
      updateMessageStatus(messageId, MessageStatus.delivered);
    }
  }
  
  void handleReadReceipt(String messageId, List<String> readBy) {
    if (readBy.isNotEmpty) {
      updateMessageStatus(messageId, MessageStatus.read);
    }
  }
}
```

### Typing Indicators
```dart
class TypingIndicatorManager {
  final WebSocketManager _webSocketManager;
  final Map<String, Timer> _typingTimers = {};
  final Map<String, Set<String>> _typingUsers = {};
  
  final _typingController = StreamController<TypingUpdate>.broadcast();
  Stream<TypingUpdate> get typingUpdates => _typingController.stream;
  
  void startTyping(String conversationId) {
    // Cancel existing timer
    _typingTimers[conversationId]?.cancel();
    
    // Send typing start event
    _webSocketManager.sendMessage(WebSocketMessage.typing(
      conversationId: conversationId,
      isTyping: true,
    ));
    
    // Auto-stop typing after 3 seconds
    _typingTimers[conversationId] = Timer(Duration(seconds: 3), () {
      stopTyping(conversationId);
    });
  }
  
  void stopTyping(String conversationId) {
    _typingTimers[conversationId]?.cancel();
    _typingTimers.remove(conversationId);
    
    _webSocketManager.sendMessage(WebSocketMessage.typing(
      conversationId: conversationId,
      isTyping: false,
    ));
  }
  
  void handleTypingEvent(TypingEvent event) {
    final typingUsers = _typingUsers[event.conversationId] ??= {};
    
    if (event.isTyping) {
      typingUsers.add(event.userId);
      
      // Auto-remove after 5 seconds if no update
      Timer(Duration(seconds: 5), () {
        typingUsers.remove(event.userId);
        _emitTypingUpdate(event.conversationId);
      });
    } else {
      typingUsers.remove(event.userId);
    }
    
    _emitTypingUpdate(event.conversationId);
  }
  
  void _emitTypingUpdate(String conversationId) {
    final typingUsers = _typingUsers[conversationId] ?? {};
    _typingController.add(TypingUpdate(
      conversationId: conversationId,
      typingUserIds: typingUsers.toList(),
    ));
  }
}
```

## Performance Optimization

### Message Batching
```dart
class MessageBatcher {
  static const int _batchSize = 10;
  static const Duration _batchTimeout = Duration(milliseconds: 100);
  
  final List<MessageModel> _batch = [];
  Timer? _batchTimer;
  
  final _batchController = StreamController<List<MessageModel>>.broadcast();
  Stream<List<MessageModel>> get batchStream => _batchController.stream;
  
  void addMessage(MessageModel message) {
    _batch.add(message);
    
    if (_batch.length >= _batchSize) {
      _flushBatch();
    } else {
      _scheduleBatchFlush();
    }
  }
  
  void _scheduleBatchFlush() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchTimeout, _flushBatch);
  }
  
  void _flushBatch() {
    if (_batch.isNotEmpty) {
      _batchController.add(List.from(_batch));
      _batch.clear();
    }
    _batchTimer?.cancel();
  }
}
```

### Memory Management
```dart
class MessageMemoryManager {
  static const int _maxMessagesInMemory = 100;
  static const int _messagesToKeepOnCleanup = 50;
  
  final Map<String, List<MessageModel>> _conversationMessages = {};
  final LRUCache<String, MessageModel> _messageCache = LRUCache(1000);
  
  void addMessage(String conversationId, MessageModel message) {
    final messages = _conversationMessages[conversationId] ??= [];
    messages.insert(0, message); // Add to beginning for chronological order
    
    _messageCache.put(message.localId, message);
    
    // Cleanup if too many messages
    if (messages.length > _maxMessagesInMemory) {
      _cleanupOldMessages(conversationId);
    }
  }
  
  void _cleanupOldMessages(String conversationId) {
    final messages = _conversationMessages[conversationId]!;
    
    // Keep only recent messages in memory
    final messagesToRemove = messages.skip(_messagesToKeepOnCleanup).toList();
    messages.removeRange(_messagesToKeepOnCleanup, messages.length);
    
    // Remove from cache
    for (final message in messagesToRemove) {
      _messageCache.remove(message.localId);
    }
    
    _logger.d('Cleaned up ${messagesToRemove.length} old messages from memory');
  }
  
  List<MessageModel> getMessages(String conversationId) {
    return _conversationMessages[conversationId] ?? [];
  }
  
  MessageModel? getMessage(String messageId) {
    return _messageCache.get(messageId);
  }
}
```

## Error Recovery & Resilience

### Connection Recovery
```dart
class ConnectionRecoveryManager {
  final WebSocketManager _webSocketManager;
  final MessageQueue _messageQueue;
  final NetworkInfo _networkInfo;
  
  late final StreamSubscription _networkSubscription;
  late final StreamSubscription _connectionSubscription;
  
  void initialize() {
    // Monitor network changes
    _networkSubscription = _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        _handleNetworkRecovery();
      } else {
        _handleNetworkLoss();
      }
    });
    
    // Monitor connection state
    _connectionSubscription = _webSocketManager.connectionState.listen((state) {
      switch (state) {
        case ConnectionState.connected:
          _handleConnectionRecovery();
          break;
        case ConnectionState.disconnected:
        case ConnectionState.failed:
          _handleConnectionLoss();
          break;
        default:
          break;
      }
    });
  }
  
  void _handleNetworkRecovery() async {
    _logger.i('Network recovered, attempting to reconnect...');
    
    // Wait a bit for network to stabilize
    await Future.delayed(Duration(seconds: 1));
    
    if (!_webSocketManager.isConnected) {
      await _webSocketManager.connect();
    }
  }
  
  void _handleConnectionRecovery() async {
    _logger.i('WebSocket connection recovered');
    
    // Process any queued messages
    await _messageQueue.processQueue();
    
    // Sync any missed messages
    await _syncMissedMessages();
  }
  
  Future<void> _syncMissedMessages() async {
    // Implementation to fetch messages that might have been missed
    // during disconnection period
  }
}
```

## Testing Strategy

### Real-time Testing
```dart
group('WebSocketManager', () {
  late WebSocketManager webSocketManager;
  late MockWebSocketChannel mockChannel;
  late MockAuthService mockAuthService;
  
  setUp(() {
    mockChannel = MockWebSocketChannel();
    mockAuthService = MockAuthService();
    webSocketManager = WebSocketManager(
      url: 'ws://test.com',
      authService: mockAuthService,
    );
  });
  
  test('should connect successfully with valid token', () async {
    when(() => mockAuthService.getAccessToken())
        .thenAnswer((_) async => 'valid_token');
    when(() => mockChannel.ready).thenAnswer((_) async {});
    
    await webSocketManager.connect();
    
    expect(webSocketManager.isConnected, true);
    verify(() => mockAuthService.getAccessToken()).called(1);
  });
  
  test('should handle connection failures with exponential backoff', () async {
    when(() => mockAuthService.getAccessToken())
        .thenAnswer((_) async => 'valid_token');
    when(() => mockChannel.ready).thenThrow(WebSocketException('Connection failed'));
    
    await webSocketManager.connect();
    
    expect(webSocketManager.isConnected, false);
    // Verify reconnection is scheduled
  });
});
```
