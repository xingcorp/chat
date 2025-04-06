# Tiêu chuẩn lập trình và quy ước coding

Tài liệu này mô tả các tiêu chuẩn lập trình và quy ước coding được áp dụng trong dự án Flutter Chat App để đảm bảo tính nhất quán và dễ bảo trì của code.

## Nguyên tắc chung

1. **Đơn giản hóa**: Luôn ưu tiên các giải pháp đơn giản và dễ hiểu.
2. **Rõ ràng hơn thông minh**: Code dễ đọc quan trọng hơn code thông minh.
3. **Nhất quán**: Tuân thủ các quy ước đã được thiết lập.
4. **Khả năng tái sử dụng**: Thiết kế các thành phần có thể tái sử dụng.
5. **Khả năng kiểm thử**: Viết code dễ dàng kiểm thử.

## Cấu trúc thư mục

```
lib/
├── core/                  # Core utilities, DI, services
│   ├── di/                # Dependency injection
│   ├── errors/            # Error handling
│   ├── services/          # Core services
│   └── utils/             # Utilities
├── data/                  # Data layer
│   ├── datasources/       # Local và remote data sources
│   │   ├── local/         # Local data sources (SQLite, SharedPrefs)
│   │   └── remote/        # Remote data sources (API)
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
├── domain/                # Domain layer
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Use cases
├── presentation/          # Presentation layer
│   ├── blocs/             # BLoCs/Cubits
│   ├── screens/           # Screens
│   └── widgets/           # Reusable widgets
│       ├── chat/          # Chat-related widgets
│       ├── common/        # Common widgets
│       └── media/         # Media-related widgets
├── app.dart               # App configuration
└── main.dart              # Entry point
```

## Quy tắc đặt tên

### 1. Classes, Enums, và Typedefs

- Sử dụng PascalCase: `ChatMessage`, `UserStatus`, `MessageType`
- Đặt tên rõ ràng, mô tả đầy đủ mục đích

```dart
class ChatMessage { ... }
enum MessageStatus { sending, sent, delivered, read }
typedef MessageCallback = void Function(ChatMessage message);
```

### 2. Biến và hàm

- Sử dụng camelCase: `messageList`, `getUserData()`
- Tránh abbreviations trừ khi phổ biến: `id`, `http`, `json`

```dart
final ChatMessage message;
List<User> getActiveUsers() { ... }
```

### 3. Hằng số

- Sử dụng SCREAMING_SNAKE_CASE cho các hằng số toàn cục: `MAX_MESSAGE_LENGTH`
- Sử dụng camelCase cho các hằng số cấp lớp: `defaultAnimationDuration`

```dart
const int MAX_MESSAGE_LENGTH = 500;
const Duration defaultAnimationDuration = Duration(milliseconds: 300);
```

### 4. Tệp tin

- Sử dụng snake_case: `chat_message.dart`, `user_repository.dart`
- Đảm bảo tên file phản ánh nội dung chính

### 5. Packages và imports

- Sắp xếp imports theo thứ tự:
  1. Dart core libraries (`dart:...`)
  2. Flutter libraries (`package:flutter/...`)
  3. Third-party packages
  4. Local imports (relative paths)
- Tách nhóm imports bằng dòng trống

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/message.dart';
import '../../widgets/common/hero_avatar.dart';
```

## Phong cách code

### 1. Formatting

- Sử dụng 2 spaces cho indentation
- Giới hạn 80 ký tự cho một dòng
- Sử dụng trailing commas cho các list, map, và parameter lists có nhiều dòng
- Sử dụng `dartfmt` hoặc formatter của IDE

```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Chat'),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            // Search action
          },
        ),
      ],
    ),
    body: ChatList(),
  );
}
```

### 2. Tổ chức Class

- Sắp xếp các thành phần của class theo thứ tự:
  1. Static properties và methods
  2. Instance properties
  3. Constructors
  4. Override methods (lifecycle methods đầu tiên: `initState`, `build`, v.v.)
  5. Public methods
  6. Private methods (`_method`)

```dart
class MessageItem extends StatelessWidget {
  // 1. Static properties
  static const double avatarSize = 40.0;
  
  // 2. Instance properties
  final Message message;
  final VoidCallback? onTap;
  
  // 3. Constructors
  const MessageItem({
    Key? key,
    required this.message,
    this.onTap,
  }) : super(key: key);
  
  // 4. Override methods
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildContent(),
    );
  }
  
  // 5. Private methods
  Widget _buildContent() {
    // Implementation
  }
}
```

### 3. Documentation

- Sử dụng /// triple-slash comments cho public API
- Mô tả rõ parameters, return values, và exceptions
- Ghi chú code phức tạp

```dart
/// Fetches messages for a specific chat.
///
/// The [chatId] parameter is required to identify the chat.
/// The [limit] parameter controls the maximum number of messages to fetch.
/// Returns a list of [Message] objects ordered by timestamp.
/// Throws [DatabaseException] if the database operation fails.
Future<List<Message>> getMessages({
  required String chatId,
  int limit = 20,
}) async {
  // Implementation
}
```

## Clean Code Principles

### 1. Hàm và phương thức

- Giữ các hàm ngắn và tập trung vào một nhiệm vụ
- Giới hạn số lượng parameters (tối đa 3-4)
- Sử dụng named parameters cho clarity

```dart
// KHÔNG TỐT: Quá nhiều parameters bắt buộc
void sendMessage(String chatId, String content, String senderId, DateTime timestamp, bool isPriority);

// TỐT: Sử dụng named parameters
void sendMessage({
  required String chatId,
  required String content,
  required String senderId,
  DateTime? timestamp,
  bool isPriority = false,
});
```

### 2. Conditional Logic

- Tránh nested if statements
- Sử dụng early returns
- Tận dụng null-aware operators và conditional expressions

```dart
// KHÔNG TỐT: Nested if statements
Widget buildAvatar() {
  if (user != null) {
    if (user.avatarUrl != null) {
      return Image.network(user.avatarUrl!);
    } else {
      return Icon(Icons.person);
    }
  } else {
    return Icon(Icons.person_outline);
  }
}

// TỐT: Early returns và null-aware operators
Widget buildAvatar() {
  if (user == null) return Icon(Icons.person_outline);
  
  return user.avatarUrl != null
      ? Image.network(user.avatarUrl!)
      : Icon(Icons.person);
}
```

### 3. Error Handling

- Xử lý lỗi tại các boundary của system
- Sử dụng typed exceptions
- Đảm bảo resource cleanup với try-finally

```dart
Future<void> loadData() async {
  try {
    final result = await repository.fetchData();
    state = DataLoaded(result);
  } on NetworkException catch (e) {
    state = DataError('Network error: ${e.message}');
  } on FormatException {
    state = DataError('Invalid data format');
  } catch (e) {
    state = DataError('Unknown error occurred');
  }
}
```

## State Management

### 1. Mô hình BLoC

- Sử dụng BLoC cho business logic phức tạp
- Giữ UI layer stateless khi có thể
- Tránh business logic trong UI

```dart
// KHÔNG TỐT: Logic trong UI
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Message>>(
      future: MessageRepository().getMessages(chatId: 'chat123'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Error handling
        }
        // UI building
      },
    );
  }
}

// TỐT: Sử dụng BLoC
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        repository: context.read<MessageRepository>(),
      )..add(ChatOpened(chatId: 'chat123')),
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          // UI based on state
        },
      ),
    );
  }
}
```

### 2. Immutability

- Sử dụng immutable state
- Tránh thay đổi trực tiếp objects, sử dụng copyWith

```dart
// KHÔNG TỐT: Mutable state
void updateMessage(Message message) {
  message.status = MessageStatus.read;
  message.readTimestamp = DateTime.now();
  notifyListeners();
}

// TỐT: Immutable objects
void updateMessage(Message message) {
  final updatedMessage = message.copyWith(
    status: MessageStatus.read,
    readTimestamp: DateTime.now(),
  );
  emit(state.copyWith(
    messages: state.messages.map((m) => 
      m.id == updatedMessage.id ? updatedMessage : m
    ).toList(),
  ));
}
```

## Testing

### 1. Unit Tests

- Test mỗi class/function riêng biệt
- Sử dụng mocks cho dependencies
- Tuân theo pattern: Arrange-Act-Assert (AAA)

```dart
void main() {
  group('MessageRepository', () {
    late MessageRepository repository;
    late MockMessageDao mockDao;
    
    setUp(() {
      mockDao = MockMessageDao();
      repository = MessageRepository(messageDao: mockDao);
    });
    
    test('getMessages returns messages from DAO', () async {
      // Arrange
      final messages = [Message(id: '1'), Message(id: '2')];
      when(mockDao.getMessages(any)).thenAnswer((_) async => messages);
      
      // Act
      final result = await repository.getMessages(chatId: 'chat1');
      
      // Assert
      expect(result, equals(messages));
      verify(mockDao.getMessages('chat1')).called(1);
    });
  });
}
```

### 2. Widget Tests

- Test UI behavior và tương tác
- Tập trung vào testing interface, không phải implementation
- Sử dụng `testWidgets` với `WidgetTester`

```dart
testWidgets('MessageItem shows content and time', (WidgetTester tester) async {
  // Arrange
  final message = Message(
    id: '1',
    content: 'Hello',
    timestamp: DateTime(2023, 1, 1, 12, 0),
  );
  
  // Act
  await tester.pumpWidget(MaterialApp(
    home: MessageItem(message: message),
  ));
  
  // Assert
  expect(find.text('Hello'), findsOneWidget);
  expect(find.text('12:00 PM'), findsOneWidget);
});
```

## Performance

### 1. Const Constructors

- Sử dụng `const` constructors khi có thể
- Tái sử dụng widgets khi không thay đổi

```dart
// KHÔNG TỐT
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(8.0),
    child: Icon(Icons.message),
  );
}

// TỐT
Widget build(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(8.0),
    child: Icon(Icons.message),
  );
}
```

### 2. Tối ưu hóa Builds

- Tránh rebuilding không cần thiết
- Sử dụng `RepaintBoundary` khi cần
- Tách widgets thành các thành phần nhỏ hơn

```dart
// KHÔNG TỐT: Rebuild toàn bộ list khi chỉ typing indicator thay đổi
Widget build(BuildContext context) {
  return Column(
    children: [
      MessageList(messages: messages),
      TypingIndicator(isTyping: isTyping),
    ],
  );
}

// TỐT: Tách ra thành phần riêng biệt
Widget build(BuildContext context) {
  return Column(
    children: [
      MessageList(messages: messages),
      TypingIndicatorWrapper(userId: userId),
    ],
  );
}

class TypingIndicatorWrapper extends StatelessWidget {
  final String userId;
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TypingBloc, TypingState>(
      buildWhen: (previous, current) => 
          previous.typingUsers[userId] != current.typingUsers[userId],
      builder: (context, state) {
        return TypingIndicator(
          isTyping: state.typingUsers[userId] ?? false,
        );
      },
    );
  }
}
```

## Code Reviews

### Checklist trước khi gửi PR

1. Code tuân thủ style guide
2. Tất cả tests đều pass
3. Không có linter warnings
4. Documentation được cập nhật nếu cần
5. Không có code thừa (debugging code, commented code, etc.)
6. PR có kích thước nhỏ và tập trung vào một thay đổi

### Quy trình Review

1. Mô tả rõ ràng về PR và mục đích
2. Screenshots/videos của UI changes nếu có
3. Tự review code trước khi yêu cầu người khác review
4. Trả lời các comments của reviewer nhanh chóng
5. Giải thích quyết định thiết kế nếu cần

## Tham khảo

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/rendering/best-practices)
- [Clean Architecture](./architecture.md)
- [Test-Driven Development](https://en.wikipedia.org/wiki/Test-driven_development) 