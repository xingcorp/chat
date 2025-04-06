# Hệ thống Tin nhắn Thời gian thực

Tài liệu này mô tả kiến trúc và cách triển khai hệ thống tin nhắn thời gian thực trong ứng dụng chat, đảm bảo trải nghiệm mượt mà và đáng tin cậy cho người dùng.

## Kiến trúc Tổng quan

Ứng dụng chat sử dụng kiến trúc kết hợp WebSocket và MQTT để đảm bảo tin nhắn được truyền tải nhanh chóng và tiết kiệm pin:

```
+-------------+                +------------+                +-------------+
|             |  WebSocket/   |            |  Push          |             |
| Flutter App |<------------->| Chat Server|<-------------->| Push Service|
|             |  MQTT         |            |  Notifications |             |
+-------------+                +------------+                +-------------+
      ^                              ^
      |                              |
      v                              v
+-------------+                +------------+
| Local       |                | Database   |
| Database    |                | Server     |
+-------------+                +------------+
```

## Sử dụng WebSocket vs MQTT

### WebSocket
- Được sử dụng cho giao tiếp hai chiều liên tục
- Tốt cho việc chat 1-1 và trong nhóm nhỏ
- Triển khai: `web_socket_channel` package

### MQTT
- Được sử dụng cho những trường hợp có nhiều kết nối với cùng topic
- Tốt cho các nhóm chat lớn và kênh thông báo
- Tiết kiệm pin hơn WebSocket trong nhiều trường hợp
- Triển khai: `mqtt_client` package

## Kết nối và Quản lý Phiên

### Thiết lập kết nối

```dart
// Ví dụ thiết lập WebSocket
Future<WebSocketChannel> establishWebSocketConnection() async {
  final token = await authService.getToken();
  final uri = Uri.parse('wss://api.example.com/ws?token=$token');
  
  return WebSocketChannel.connect(uri);
}

// Ví dụ thiết lập MQTT
Future<MqttClient> setupMqttClient() async {
  final client = MqttClient('broker.example.com', '');
  client.port = 8883;
  client.secure = true;
  client.keepAlivePeriod = 60;
  
  final token = await authService.getToken();
  final connStatus = await client.connect(
    userId,
    token,
  );
  
  if (connStatus?.state == MqttConnectionState.connected) {
    log('Connected to MQTT broker');
    return client;
  } else {
    throw Exception('Could not connect to MQTT broker');
  }
}
```

### Quản lý kết nối

Kết nối được quản lý thông qua `ConnectionService` nằm trong `lib/core/services/connection_service.dart`:

```dart
class ConnectionService {
  final _connectionStatusController = BehaviorSubject<ConnectionStatus>.seeded(ConnectionStatus.disconnected);
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  
  // Kết nối lại tự động với exponential backoff
  Future<void> reconnect() async {
    int attemptCount = 0;
    const maxAttempts = 10;
    
    while (attemptCount < maxAttempts) {
      try {
        final connection = await establishConnection();
        _handleConnection(connection);
        _connectionStatusController.add(ConnectionStatus.connected);
        return;
      } catch (e) {
        attemptCount++;
        final delay = min(pow(2, attemptCount) * 1000, 30000);
        await Future.delayed(Duration(milliseconds: delay.toInt()));
      }
    }
    
    _connectionStatusController.add(ConnectionStatus.failed);
  }
  
  // ...
}
```

## Xử lý Tin nhắn

### Định dạng tin nhắn

Mọi tin nhắn thời gian thực được cấu trúc theo định dạng sau:

```json
{
  "type": "message|receipt|typing|presence",
  "id": "unique-message-id",
  "sender": "user-id",
  "recipient": "user-id or group-id",
  "timestamp": 1627884600000,
  "content": {
    "text": "Hello, world!",
    "attachments": [],
    "mentions": []
  },
  "metadata": {
    "client_sent_at": 1627884598000
  }
}
```

### Luồng tin nhắn đi ra (Outgoing)

1. Tin nhắn được tạo ở local với ID duy nhất
2. Lưu vào local database với trạng thái "sending"
3. Gửi qua WebSocket/MQTT
4. Cập nhật trạng thái khi nhận được receipt từ server

```dart
Future<void> sendMessage(Message message) async {
  // 1. Lưu tin nhắn vào local database
  await messageRepository.saveMessage(
    message.copyWith(status: MessageStatus.sending)
  );
  
  // 2. Gửi qua WebSocket/MQTT
  try {
    await messagingService.sendMessage(message);
  } catch (e) {
    // Xử lý lỗi, đánh dấu tin nhắn cần retry
    await messageRepository.updateMessageStatus(
      message.id, 
      MessageStatus.failed
    );
  }
}
```

### Luồng tin nhắn đến (Incoming)

1. Nhận tin nhắn từ WebSocket/MQTT
2. Xác thực và xử lý tin nhắn
3. Lưu vào local database
4. Gửi acknowledgment về server
5. Cập nhật UI

```dart
void handleIncomingMessage(RawMessage rawMessage) {
  // 1. Xác thực và chuyển đổi định dạng
  final message = _validateAndTransform(rawMessage);
  if (message == null) return;
  
  // 2. Lưu vào local database
  messageRepository.saveMessage(message);
  
  // 3. Gửi acknowledgment
  messagingService.sendAcknowledgment(message.id);
  
  // 4. Cập nhật UI qua BLoC/Cubit
  chatBloc.add(MessageReceived(message));
}
```

## Chiến lược Đảm bảo Tin nhắn

### Thứ tự tin nhắn

- Mỗi tin nhắn có `timestamp` từ server để sắp xếp chính xác
- Client tính toán `clientSentAt` để xử lý thứ tự tạm thời cho các tin nhắn chưa đồng bộ

### Xử lý retry và lỗi mạng

```dart
class MessageSyncService {
  // Lịch trình sync tin nhắn bị lỗi
  final _syncScheduler = BehaviorSubject<SyncSchedule>();
  
  // Thiết lập bộ đếm thời gian sync
  void setupSyncScheduler() {
    _syncScheduler.stream
      .debounceTime(Duration(seconds: 5))
      .listen((_) => _performSync());
  }
  
  // Retry logic với back-off strategy
  Future<void> retryFailedMessages() async {
    final failedMessages = await messageRepository.getMessagesByStatus(
      MessageStatus.failed
    );
    
    // Phân nhóm theo thời gian thất bại
    final groupedByFailureTime = _groupMessagesByFailureTime(failedMessages);
    
    // Áp dụng backoff strategy cho mỗi group
    for (final group in groupedByFailureTime) {
      final backoffDelay = _calculateBackoffDelay(group.failureCount);
      await Future.delayed(backoffDelay);
      await _resendMessages(group.messages);
    }
  }
  
  // ...
}
```

### Quản lý Offline và Sync

- Tin nhắn được lưu trong queue khi offline
- Sử dụng MessageQueueService để quản lý hàng đợi
- Tự động sync khi kết nối lại

```dart
void onConnectionStatusChanged(ConnectionStatus status) {
  if (status == ConnectionStatus.connected) {
    messageSyncService.syncQueuedMessages();
  } else if (status == ConnectionStatus.disconnected) {
    // Chuyển đổi sang chế độ offline
    chatBloc.add(ConnectionStateChanged(isOnline: false));
  }
}
```

## Tối ưu hóa Hiệu suất

### Giảm độ trễ

- Tin nhắn được hiển thị ngay lập tức từ local trước khi server xác nhận
- Optimistic UI updates cho typing indicators và receipts
- Request batching cho các tin nhắn được gửi nhanh liên tiếp

### Tiết kiệm pin

- MQTT cho các kênh có nhiều người nhận
- WebSocket cho chat 1-1 có tính tương tác cao
- Quản lý lifecycle để ngắt kết nối khi không cần thiết

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    // Giảm tần suất cập nhật nhưng giữ kết nối
    messagingService.enterBackgroundMode();
  } else if (state == AppLifecycleState.resumed) {
    // Khôi phục lại
    messagingService.enterForegroundMode();
  }
}
```

## Trạng thái Typing và Presence

### Typing Indicators

```dart
void sendTypingIndicator(String chatId) {
  // Throttle để không gửi quá nhiều
  if (_shouldSendTypingIndicator(chatId)) {
    final typingEvent = TypingEvent(
      senderId: currentUserId,
      chatId: chatId,
      timestamp: DateTime.now(),
    );
    
    messagingService.sendTypingEvent(typingEvent);
    _updateLastTypingSent(chatId);
  }
}
```

### Presence (Online/Offline)

```dart
void updatePresenceStatus(PresenceStatus status) {
  final presenceEvent = PresenceEvent(
    userId: currentUserId,
    status: status,
    lastSeen: status == PresenceStatus.offline ? DateTime.now() : null,
  );
  
  messagingService.sendPresenceEvent(presenceEvent);
}
```

## Kiểm thử

### Unit Tests

```dart
test('should retry failed messages with exponential backoff', () async {
  // Arrange
  final messageSyncService = MessageSyncService(
    messagingService: mockMessagingService,
    messageRepository: mockMessageRepository,
  );
  
  final failedMessages = [
    Message(id: '1', status: MessageStatus.failed, failedAt: DateTime.now().subtract(Duration(minutes: 5))),
    Message(id: '2', status: MessageStatus.failed, failedAt: DateTime.now().subtract(Duration(minutes: 2))),
  ];
  
  when(mockMessageRepository.getMessagesByStatus(MessageStatus.failed))
    .thenAnswer((_) async => failedMessages);
  
  // Act
  await messageSyncService.retryFailedMessages();
  
  // Assert
  verify(mockMessagingService.sendMessage(any)).called(2);
});
```

### Integration Tests

```dart
testWidgets('should show sending and sent states for new message', (tester) async {
  // Arrange
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Navigate to chat screen
  await tester.tap(find.text('John Doe'));
  await tester.pumpAndSettle();
  
  // Act: Send a message
  await tester.enterText(find.byType(MessageInput), 'Hello, world!');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pump();
  
  // Assert: Initially shows sending state
  expect(find.byIcon(Icons.access_time), findsOneWidget);
  
  // Complete WebSocket call
  await mockWebSocketCompletion();
  await tester.pump();
  
  // Assert: Shows sent state
  expect(find.byIcon(Icons.check), findsOneWidget);
});
```

## Kết luận

Hệ thống tin nhắn thời gian thực được thiết kế để cung cấp trải nghiệm mượt mà với độ trễ thấp, hoạt động đáng tin cậy ngay cả khi kết nối không ổn định, và tối ưu hóa sử dụng pin. Kiến trúc kết hợp WebSocket và MQTT giúp đạt được sự cân bằng giữa tính tương tác cao và hiệu quả hoạt động trên nhiều loại thiết bị khác nhau.