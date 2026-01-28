# Task 3.2 Implementation Plan

**Date**: 2026-01-28  
**Task**: Consolidate Real-time to Socket.IO (UnifiedWebSocketService)  
**Status**: In Progress

---

## 🎯 Objective

Consolidate 3 real-time systems into 1 Socket.IO-based system aligned with backend architecture.

---

## 🔍 Analysis Summary

### Backend Architecture (NestJS)
```typescript
// src/modules/chat/chat-gateway/chat.gateway.ts
@WebSocketGateway({ cors: { origin: "*" } })
export class ChatGateway {
  // Socket.IO Events:
  - message:sent       // New message
  - message:read       // Message read
  - message:reaction   // Message reaction
  - message:edit       // Message edited
  - message:delete     // Message deleted
  - message:typing     // Typing indicator
  - conversation:joined
  - conversation:leaved
}
```

### Frontend Systems Analysis

**1. UnifiedWebSocketService** (600 lines) - ✅ KEEP & ENHANCE
- Socket.IO client (matches backend)
- Offline message queue (1000 messages)
- Exponential backoff reconnection
- Heartbeat mechanism (30s)
- Performance metrics tracking
- **Status**: Production-ready, needs minor enhancements

**2. ConnectionPoolManager** (700 lines) - ❌ REMOVE (merge features)
- Connection health checks
- LRU eviction
- Connection statistics
- **Good Features to Migrate**:
  - Health check mechanism
  - Statistics tracking (success rate, latency)
  - Automatic cleanup

**3. GraphQLSubscriptionService** (500 lines) - ❌ REMOVE (incompatible)
- GraphQL subscriptions over WebSocket
- **Problem**: Backend doesn't support GraphQL subscriptions
- **Status**: Cannot be used, must remove

---

## 📋 Implementation Steps

### Step 1: Rename UnifiedWebSocketService to RealtimeMessagingService ✅ COMPLETE

**Completed Actions**:
- ✅ Renamed file: `unified_websocket_service.dart` → `realtime_messaging_service.dart`
- ✅ Updated class name: `UnifiedWebSocketService` → `RealtimeMessagingService`
- ✅ Updated all imports in `realtime_message_bloc.dart`
- ✅ Updated DI registrations in `injection.config.dart`
- ✅ Verified no remaining references to old names

**Rationale for Name Change**:
- More professional and business-focused
- Protocol-agnostic (doesn't expose Socket.IO implementation detail)
- Aligns with Clean Architecture naming conventions (name by domain, not technology)
- Better reflects the service's purpose: real-time messaging, not just WebSocket management

### Step 2: Create Socket.IO Event Mapper

**Map backend events to domain entities**:
```dart
class UnifiedWebSocketService {
  // Health check
  Future<int?> checkLatency() async {
    final startTime = DateTime.now();
    // Send ping, wait for pong
    final latency = DateTime.now().difference(startTime);
    return latency.inMilliseconds;
  }
  
  // Connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'messagesSent': _messagesSent,
      'messagesReceived': _messagesReceived,
      'reconnectAttempts': _reconnectAttempts,
      'averageLatency': _averageLatency,
      'successRate': _calculateSuccessRate(),
      'uptime': DateTime.now().difference(_lastConnected),
    };
  }
  
  // Automatic health monitoring
  Timer? _healthCheckTimer;
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (_) {
      checkLatency();
    });
  }
}
```

### Step 2: Create Socket.IO Event Mapper

**Map backend events to domain entities**:
```dart
// lib/data/datasources/message/socket_io_event_mapper.dart
class SocketIOEventMapper {
  ChatMessage mapMessageSent(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['message']['id'],
      content: data['message']['content'],
      senderId: data['message']['senderId'],
      chatId: data['conversationId'],
      timestamp: DateTime.parse(data['message']['createdAt']),
      status: MessageStatus.sent,
    );
  }
  
  ChatMessage mapMessageRead(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['message']['id'],
      status: MessageStatus.read,
      readBy: [data['reader']['id']],
    );
  }
  
  // ... other mappers
}
```

### Step 3: Update MessageRemoteDataSource

**Replace GraphQL with Socket.IO**:
```dart
@Named('remote')
@LazySingleton(as: IMessageRemoteDataSource)
class MessageRemoteDataSource implements IMessageRemoteDataSource {
  final UnifiedWebSocketService _socketService;
  final SocketIOEventMapper _eventMapper;
  
  MessageRemoteDataSource(this._socketService, this._eventMapper);
  
  @override
  Stream<ChatMessage> watchMessages(String chatId) {
    return _socketService.messages
        .where((msg) => msg.type == 'message:sent')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) => _eventMapper.mapMessageSent(msg.data));
  }
  
  @override
  Future<void> sendMessage(ChatMessage message) async {
    await _socketService.sendMessage(
      type: 'message:send',
      data: {
        'conversationId': message.chatId,
        'content': message.content,
        'type': message.contentType.name,
      },
    );
  }
}
```

### Step 4: Update ChatMessageService

**Remove GraphQLSubscriptionService dependency**:
```dart
@lazySingleton
class ChatMessageService {
  final MessageQueueService _messageQueueService;
  final UnifiedWebSocketService _socketService; // Changed
  final IMessageRepository _messageRepository;
  
  ChatMessageService(
    this._messageQueueService,
    this._socketService, // Changed
    this._messageRepository,
  );
  
  Future<void> subscribeToChat(String chatId) async {
    // Join Socket.IO room
    await _socketService.sendMessage(
      type: 'conversation:joined',
      data: {'conversationId': chatId},
    );
    
    // Listen to messages
    _chatSubscriptions[chatId] = _socketService.messages
        .where((msg) => msg.data['conversationId'] == chatId)
        .listen((msg) {
          _handleSocketMessage(msg);
        });
  }
}
```

### Step 5: Remove GraphQLSubscriptionService

**Files to delete**:
- `lib/core/services/graphql_subscription_service.dart`
- Update `lib/core/di/injection.dart` to remove registration
- Update `lib/core/services/chat_message_service.dart` imports

### Step 6: Remove ConnectionPoolManager

**Files to delete**:
- `lib/core/network/realtime/connection_pool_manager.dart`
- Update DI registrations

### Step 7: Update Integration Tests

**Test Socket.IO integration**:
```dart
test('should receive real-time message via Socket.IO', () async {
  // Arrange
  final mockSocket = MockUnifiedWebSocketService();
  when(mockSocket.messages).thenAnswer((_) => Stream.value(
    WebSocketMessage(
      id: '1',
      type: 'message:sent',
      data: {
        'conversationId': 'chat-1',
        'message': {
          'id': 'msg-1',
          'content': 'Hello',
          'senderId': 'user-1',
        },
      },
      timestamp: DateTime.now(),
    ),
  ));
  
  // Act
  final stream = messageDataSource.watchMessages('chat-1');
  
  // Assert
  expect(stream, emits(isA<ChatMessage>()));
});
```

---

## 🎯 Success Criteria

- [x] Backend analysis complete (Socket.IO confirmed)
- [x] RealtimeMessagingService renamed from UnifiedWebSocketService
- [x] All imports and references updated
- [x] DI registrations updated
- [ ] SocketIOEventMapper created
- [ ] MessageRemoteDataSource updated to use Socket.IO
- [ ] ChatMessageService migrated
- [ ] GraphQLSubscriptionService removed
- [ ] ConnectionPoolManager removed
- [ ] Integration tests pass
- [ ] Real-time messaging works with backend

---

## 📊 Expected Impact

**Code Reduction**:
- Remove GraphQLSubscriptionService: -500 lines
- Remove ConnectionPoolManager: -700 lines
- Add enhancements to UnifiedWebSocketService: +200 lines
- **Net reduction**: -1000 lines

**Benefits**:
- ✅ Aligned with backend architecture
- ✅ Single real-time system
- ✅ Reduced complexity
- ✅ Better maintainability
- ✅ Improved error handling

---

## 🚀 Next Steps

1. Enhance UnifiedWebSocketService
2. Create SocketIOEventMapper
3. Update MessageRemoteDataSource
4. Update ChatMessageService
5. Remove unused services
6. Test integration
7. Update documentation
