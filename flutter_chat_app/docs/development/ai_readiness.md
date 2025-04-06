# AI Readiness: Chuẩn hóa code để làm việc hiệu quả với AI

Tài liệu này cung cấp hướng dẫn để chuẩn hóa codebase, giúp AI hiểu và phân tích code dễ dàng hơn, từ đó nâng cao hiệu quả khi làm việc với công cụ AI như Claude, GitHub Copilot, Claude trong Cursor, hoặc ChatGPT.

## 1. Tại sao cần AI Readiness?

AI đã trở thành một phần quan trọng trong quy trình phát triển phần mềm hiện đại. Việc chuẩn hóa code giúp:

- Tăng hiệu quả khi làm việc với AI coding assistants
- Giảm thời gian AI cần để hiểu codebase
- Nhận được gợi ý chất lượng cao từ AI
- Tận dụng AI trong quá trình review code, tìm lỗi và tối ưu hiệu suất
- Giảm technical debt thông qua việc tổ chức code chuẩn mực

## 2. Nguyên tắc đặt tên

### Tên biến và hàm

```dart
// KHÔNG TỐT: Tên biến không rõ ràng
var x = 0;
var lst = [];
bool chk() { ... }

// TỐT: Tên biến rõ ràng, dễ hiểu
int messageCount = 0;
List<Message> unreadMessages = [];
bool isUserAuthenticated() { ... }
```

### Tên file và thư mục

```
// KHÔNG TỐT
├── lib/
│   ├── a.dart
│   ├── stuff.dart
│   ├── utils.dart
│   └── helpers.dart

// TỐT
├── lib/
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── chat_screen.dart
│   │   │   └── login_screen.dart
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart
│   │   │   └── user_avatar.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── message.dart
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   ├── message_repository.dart
│   │   │   └── auth_repository.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   └── remote/
│   │   ├── repositories/
│   │   │   ├── message_repository_impl.dart
│   │   │   └── auth_repository_impl.dart
│   └── core/
│       ├── utils/
│       │   ├── date_formatter.dart
│       │   └── string_utils.dart
│       ├── errors/
│       │   └── exceptions.dart
```

## 3. Doc Comments

### Loại Doc Comments

1. **Class-level**: mô tả mục đích và chức năng chính của class
2. **Method-level**: mô tả chức năng, tham số đầu vào và giá trị trả về
3. **Property-level**: mô tả mục đích của thuộc tính 
4. **Parameter-level**: mô tả tham số khi cần thiết

### Sử dụng doc comments hiệu quả

```dart
/// Quản lý quá trình gửi tin nhắn, đảm bảo hoạt động cả khi offline.
/// 
/// Class này xử lý:
/// - Gửi tin nhắn trực tiếp khi có kết nối
/// - Lưu tạm tin nhắn vào hàng đợi khi offline
/// - Đồng bộ tin nhắn khi khôi phục kết nối
class MessageQueueService {
  /// Số lượng tin nhắn tối đa có thể chờ trong hàng đợi
  final int maxQueueSize;
  
  /// Thời gian tối đa (ms) chờ trước khi timeout một yêu cầu gửi tin nhắn
  final int sendTimeoutMs;
  
  /// Gửi tin nhắn và xử lý theo trạng thái kết nối.
  /// 
  /// Nếu thiết bị online, gửi trực tiếp đến server.
  /// Nếu offline, thêm vào hàng đợi để gửi sau.
  /// 
  /// [chatId] ID của cuộc trò chuyện
  /// [content] Nội dung tin nhắn
  /// [type] Loại tin nhắn (text, image, ...)
  /// 
  /// Trả về [Message] với ID tạm thời nếu offline, hoặc ID thật nếu online.
  /// Ném ra [NetworkException] nếu gặp lỗi kết nối không dự đoán.
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
  }) async {
    // Implementation
  }
}
```

### Tips cho doc comments hiệu quả

- Sử dụng ngôn ngữ rõ ràng, không mơ hồ
- Mô tả "tại sao" và "điều gì", không chỉ "làm thế nào"
- Ghi chú các edge cases và behavior đặc biệt
- Thêm ví dụ cho các API phức tạp
- Liệt kê các exceptions có thể xảy ra và trong trường hợp nào

## 4. Cấu trúc code

### Cấu trúc function/method

```dart
/// Tìm kiếm và trả về danh sách chat phù hợp với từ khóa.
///
/// [query] Từ khóa tìm kiếm, không phân biệt hoa thường
/// [limit] Số kết quả tối đa, mặc định là 20
/// [includeArchived] Nếu true, bao gồm cả chat đã lưu trữ
///
/// Trả về danh sách chat phù hợp, sắp xếp theo mức độ liên quan
Future<List<Chat>> searchChats({
  required String query,
  int limit = 20,
  bool includeArchived = false,
}) async {
  // 1. Validation
  if (query.trim().isEmpty) {
    return [];
  }
  
  // 2. Setup - define variables, prepare data
  final normalizedQuery = query.toLowerCase();
  final List<Chat> result = [];
  
  // 3. Core logic
  final allChats = includeArchived 
      ? await _chatDao.getAllChats() 
      : await _chatDao.getActiveChats();
  
  for (final chat in allChats) {
    if (_matchesSearchCriteria(chat, normalizedQuery)) {
      result.add(chat);
    }
    
    if (result.length >= limit) {
      break;
    }
  }
  
  // 4. Sort and prepare for return
  result.sort((a, b) => _calculateRelevance(b, normalizedQuery)
      .compareTo(_calculateRelevance(a, normalizedQuery)));
  
  // 5. Return
  return result;
}
```

### Cấu trúc Class

```dart
class ChatRepository {
  // 1. Fields (private first, then public)
  final ChatDao _chatDao;
  final ChatService _chatService;
  final ConnectivityService _connectivityService;
  
  // 2. Constructors
  ChatRepository({
    required ChatDao chatDao,
    required ChatService chatService,
    required ConnectivityService connectivityService,
  }) : _chatDao = chatDao,
       _chatService = chatService,
       _connectivityService = connectivityService;
  
  // 3. Public API methods
  Future<List<Chat>> getChats() async {
    // Implementation
  }
  
  // 4. Private helper methods
  Future<void> _syncChats() async {
    // Implementation
  }
}
```

## 5. Comments trong code

### Khi nào sử dụng comments

```dart
// KHÔNG TỐT: Comment không cần thiết
// Increase message count
messageCount++;

// TỐT: Comment giải thích ý định hoặc logic phức tạp
// Skip messages from blocked users 
if (blockedUserIds.contains(message.senderId)) {
  continue;
}

// KHÔNG TỐT: Comment giải thích code không rõ ràng
// Check if x is not null and if it's greater than y
if (x != null && x > y) {
  // ...
}

// TỐT: Viết lại code để tự giải thích
if (messageCount != null && messageCount > maxAllowedMessages) {
  // ...
}
```

### TODO, FIXME, và Markers

```dart
// TODO(username): Implement caching mechanism before v1.2 release
// FIXME: This has a memory leak when processing large images
// HACK: Temporary workaround for API limitation, remove when server is updated
// NOTE: This approach is O(n²) but acceptable for small datasets (<100 items)
```

## 6. Typing và Type Annotations

### Sử dụng kiểu chặt chẽ

```dart
// KHÔNG TỐT: Sử dụng dynamic hoặc var không cần thiết
var result = fetchData();
List items = getItems();

// TỐT: Type annotations rõ ràng
Future<User> result = fetchUser();
List<ChatMessage> messages = getRecentMessages();
```

### Generics

```dart
// KHÔNG TỐT: Thiếu generic types
Future<List> getMessages() async {
  // ...
}

// TỐT: Generic types đầy đủ
Future<List<Message>> getMessages() async {
  // ...
}

// TỐT: Generic types phức tạp
Future<Map<String, List<MessageReaction>>> getMessageReactions(List<String> messageIds) async {
  // ...
}
```

## 7. Error Handling

### Try-catch blocks có ý nghĩa

```dart
// KHÔNG TỐT: Catch chung, ẩn lỗi
try {
  await uploadFile();
} catch (e) {
  print('Error: $e');
}

// TỐT: Catch từng loại lỗi cụ thể và xử lý phù hợp
try {
  await uploadFile();
} on SocketException catch (e) {
  throw NetworkException('Không thể kết nối đến server: ${e.message}');
} on TimeoutException catch (e) {
  throw TimeoutException('Quá thời gian tải lên: ${e.message}');
} on FileSystemException catch (e) {
  throw FileException('Lỗi truy cập file: ${e.message}');
} catch (e) {
  throw UnexpectedException('Lỗi không xác định: $e');
}
```

### Result types

```dart
/// Kết quả của việc gửi tin nhắn
class MessageSendResult {
  /// Tin nhắn đã gửi, null nếu có lỗi
  final Message? message;
  
  /// Thông tin lỗi, null nếu thành công
  final String? errorMessage;
  
  /// Mã lỗi, null nếu thành công
  final MessageSendErrorCode? errorCode;
  
  /// Có thành công hay không
  bool get isSuccess => message != null;
  
  /// Có lỗi hay không
  bool get isError => errorMessage != null;
  
  const MessageSendResult.success(Message message)
      : message = message,
        errorMessage = null,
        errorCode = null;
        
  const MessageSendResult.error(String error, [MessageSendErrorCode? code])
      : message = null,
        errorMessage = error,
        errorCode = code;
}
```

## 8. Modularization

### Đơn trách nhiệm

```dart
// KHÔNG TỐT: Class làm quá nhiều việc
class UserManager {
  Future<User> getUser(String id) { ... }
  Future<void> saveUser(User user) { ... }
  Future<void> validateUserData(User user) { ... }
  Future<void> sendPasswordResetEmail(String email) { ... }
  Widget buildUserProfileWidget(User user) { ... }
  Future<List<Message>> getUserMessages(String userId) { ... }
}

// TỐT: Tách thành các classes riêng biệt
class UserRepository {
  Future<User> getUser(String id) { ... }
  Future<void> saveUser(User user) { ... }
}

class UserValidator {
  Future<void> validateUserData(User user) { ... }
}

class AuthService {
  Future<void> sendPasswordResetEmail(String email) { ... }
}

class UserProfileWidget extends StatelessWidget {
  final User user;
  
  const UserProfileWidget({required this.user});
  
  @override
  Widget build(BuildContext context) { ... }
}
```

### Đóng gói

```dart
// KHÔNG TỐT: Tiết lộ chi tiết cài đặt
class MessageService {
  final http.Client _httpClient;
  final String _apiKey;
  final String _baseUrl;
  final DatabaseHelper _db;
  
  Future<Message> sendMessage(String chatId, String content) async {
    final response = await _httpClient.post(
      '$_baseUrl/messages',
      headers: {'Authorization': 'Bearer $_apiKey'},
      body: {'chatId': chatId, 'content': content},
    );
    
    if (response.statusCode == 200) {
      final message = Message.fromJson(jsonDecode(response.body));
      await _db.insert('messages', message.toMap());
      return message;
    } else {
      throw Exception('Failed to send message');
    }
  }
}

// TỐT: Ẩn chi tiết cài đặt, chỉ tiết lộ API
class MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;
  
  Future<Message> sendMessage(String chatId, String content) async {
    try {
      final message = await _remoteDataSource.sendMessage(chatId, content);
      await _localDataSource.saveMessage(message);
      return message;
    } catch (e) {
      throw MessageException('Failed to send message: $e');
    }
  }
}
```

## 9. Testing

### Viết test dễ hiểu

```dart
// KHÔNG TỐT: Test không rõ ràng
test('test message sending', () async {
  final result = await sut.send('abc', 'Hello');
  expect(result, isNotNull);
});

// TỐT: Test có mô tả rõ ràng và assertions cụ thể
test('sendMessage should return a Message with correct content and timestamp when successful', () async {
  // Arrange
  final chatId = 'chat-123';
  final content = 'Hello, world!';
  
  // Act
  final result = await messageRepository.sendMessage(chatId, content);
  
  // Assert
  expect(result.content, equals(content));
  expect(result.chatId, equals(chatId));
  expect(result.senderId, equals('current-user-id'));
  expect(result.timestamp, isNotNull);
  expect(result.status, equals(MessageStatus.sent));
});
```

### Test cases phủ edge cases

```dart
group('MessageRepository.sendMessage', () {
  test('should send message successfully when online', () async {
    // Setup and test
  });
  
  test('should queue message when offline', () async {
    // Setup offline condition and test
  });
  
  test('should handle message with empty content', () async {
    // Test with empty content
  });
  
  test('should retry failed messages when connection is restored', () async {
    // Test retry mechanism
  });
  
  test('should handle server errors gracefully', () async {
    // Test error handling
  });
});
```

## 10. Code consistency

### Consistent style

```dart
// KHÔNG TỐT: Style không nhất quán
void doSomething() {
  // ...
}

String GetUserName() {
  // ...
}

// TỐT: Style nhất quán
void doSomething() {
  // ...
}

String getUserName() {
  // ...
}
```

### Sử dụng static analysis

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_specify_types
    - annotate_overrides
    - avoid_empty_else
    - avoid_print
    - await_only_futures
    - camel_case_types
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - constant_identifier_names
    - control_flow_in_finally
    - directives_ordering
    - empty_constructor_bodies
    - empty_statements
    - hash_and_equals
    - implementation_imports
    - library_names
    - library_prefixes
    - non_constant_identifier_names
    - package_api_docs
    - package_names
    - package_prefixed_library_names
    - prefer_const_constructors
    - prefer_final_fields
    - prefer_final_locals
    - prefer_is_not_empty
    - slash_for_doc_comments
    - test_types_in_equals
    - throw_in_finally
    - type_init_formals
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_new
    - unnecessary_statements
    - unrelated_type_equality_checks
    - use_rethrow_when_possible
    - valid_regexps
```

## 11. Cải thiện khả năng đọc

### Chia nhỏ methods

```dart
// KHÔNG TỐT: Method dài, khó đọc
Future<List<Message>> getMessagesByChat(String chatId) async {
  final db = await _databaseHelper.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'messages',
    where: 'chat_id = ?',
    whereArgs: [chatId],
    orderBy: 'timestamp DESC',
  );
  
  final List<Message> messages = [];
  for (var map in maps) {
    // Convert attachments from JSON
    List<Attachment> attachments = [];
    if (map['attachments'] != null) {
      final List<dynamic> attachmentsJson = jsonDecode(map['attachments']);
      for (var attachmentJson in attachmentsJson) {
        attachments.add(Attachment.fromMap(attachmentJson));
      }
    }
    
    // Convert message status
    MessageStatus status;
    switch (map['status']) {
      case 0:
        status = MessageStatus.sending;
        break;
      case 1:
        status = MessageStatus.sent;
        break;
      // ... more cases
      default:
        status = MessageStatus.unknown;
    }
    
    // Create message and add to list
    messages.add(Message(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      content: map['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: status,
      attachments: attachments,
      reactions: await _getMessageReactions(map['id']),
    ));
  }
  
  return messages;
}

// TỐT: Các methods ngắn, tập trung và dễ đọc
Future<List<Message>> getMessagesByChat(String chatId) async {
  final maps = await _queryMessagesByChatId(chatId);
  return _convertMapsToMessages(maps);
}

Future<List<Map<String, dynamic>>> _queryMessagesByChatId(String chatId) async {
  final db = await _databaseHelper.database;
  return db.query(
    'messages',
    where: 'chat_id = ?',
    whereArgs: [chatId],
    orderBy: 'timestamp DESC',
  );
}

List<Message> _convertMapsToMessages(List<Map<String, dynamic>> maps) {
  return maps.map((map) => _convertMapToMessage(map)).toList();
}

Message _convertMapToMessage(Map<String, dynamic> map) {
  return Message(
    id: map['id'],
    chatId: map['chat_id'],
    senderId: map['sender_id'],
    content: map['content'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    status: _parseMessageStatus(map['status']),
    attachments: _parseAttachments(map['attachments']),
    reactions: _getMessageReactions(map['id']),
  );
}

MessageStatus _parseMessageStatus(int statusCode) {
  switch (statusCode) {
    case 0:
      return MessageStatus.sending;
    case 1:
      return MessageStatus.sent;
    // ... more cases
    default:
      return MessageStatus.unknown;
  }
}

List<Attachment> _parseAttachments(String? attachmentsJson) {
  if (attachmentsJson == null) return [];
  
  final List<dynamic> parsed = jsonDecode(attachmentsJson);
  return parsed.map((json) => Attachment.fromMap(json)).toList();
}
```

### Magic numbers và constants

```dart
// KHÔNG TỐT: Magic numbers
if (message.timestamp.difference(DateTime.now()).inMinutes < 60) {
  // Show as "X minutes ago"
} else if (message.timestamp.difference(DateTime.now()).inHours < 24) {
  // Show as "X hours ago"
}

// TỐT: Named constants
class TimeThresholds {
  static const int recentMessageMinutes = 60;
  static const int recentMessageHours = 24;
  static const int messageHistoryDays = 30;
}

if (message.timestamp.difference(DateTime.now()).inMinutes < TimeThresholds.recentMessageMinutes) {
  // Show as "X minutes ago"
} else if (message.timestamp.difference(DateTime.now()).inHours < TimeThresholds.recentMessageHours) {
  // Show as "X hours ago"
}
```

## 12. Code annotation cho AI

### AI-specific doc markers

```dart
/// @ai-snippet chat-message-handling
/// 
/// Xử lý gửi tin nhắn đảm bảo hoạt động online và offline.
/// Sử dụng cho chức năng nhắn tin với optimistic updates.
/// 
/// Liên kết với:
/// - MessageRepository
/// - ConnectivityService
/// - MessageQueueService
/// @ai-snippet-end
```

### Giải thích code phức tạp

```dart
/// @ai-complex-algorithm
/// 
/// Thuật toán sắp xếp tin nhắn theo luồng hội thoại:
/// 1. Nhóm các tin nhắn reply theo tin nhắn gốc
/// 2. Sắp xếp theo thời gian trong mỗi nhóm
/// 3. Đan xen các tin nhắn không reply theo thứ tự thời gian
/// 
/// Độ phức tạp: O(n log n) trong trường hợp xấu nhất
/// @ai-complex-algorithm-end

List<Message> organizeMessagesByThread(List<Message> messages) {
  // Implementation
}
```

## 13. Checklist AI Readiness

```
[ ] Đặt tên rõ ràng, đúng quy ước cho biến, hàm, lớp, file và thư mục
[ ] Thêm doc comments cho classes, methods quan trọng
[ ] Cấu trúc files theo pattern rõ ràng (clean architecture, MVVM, v.v.)
[ ] Sử dụng comments chỉ khi cần thiết để giải thích ý định hoặc logic phức tạp
[ ] Kiểu dữ liệu rõ ràng, sử dụng generics đầy đủ
[ ] Xử lý lỗi cụ thể, có ý nghĩa
[ ] Chia nhỏ methods và classes theo nguyên tắc đơn trách nhiệm
[ ] Tests rõ ràng, bao gồm các edge cases
[ ] Code style nhất quán (tuân thủ linter rules)
[ ] Tránh magic numbers và strings, sử dụng constants có tên
[ ] Thêm doc markers cho AI nếu cần
```

## Tài liệu tham khảo

- [Effective Dart: Documentation](https://dart.dev/guides/language/effective-dart/documentation)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- [Clean Code by Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Designing AI-Ready Code](https://github.blog/2023-05-17-how-to-write-ai-readable-code/)
- [Flutter Lints](https://pub.dev/packages/flutter_lints) 