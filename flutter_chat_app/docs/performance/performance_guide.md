# Hướng dẫn tối ưu hiệu suất

Tài liệu này cung cấp các hướng dẫn và chiến lược để đảm bảo ứng dụng Chat luôn hoạt động mượt mà và phản hồi nhanh trên nhiều loại thiết bị khác nhau.

## Các chỉ số hiệu suất chính (KPIs)

### 1. Thời gian khởi động
- **Mục tiêu**: < 2 giây trên thiết bị trung bình
- **Đo lường**: Từ lúc mở ứng dụng đến khi hiển thị danh sách chat

### 2. Thời gian phản hồi (Response Time)
- **Mục tiêu**: < 16ms (60fps) cho các thao tác UI
- **Đo lường**: Thời gian từ khi nhận input đến khi UI cập nhật

### 3. Sử dụng bộ nhớ
- **Mục tiêu**: < 100MB khi hoạt động bình thường
- **Đo lường**: Sử dụng Flutter DevTools và Firebase Performance

### 4. Thời gian tải tin nhắn
- **Mục tiêu**: < 500ms để tải 20 tin nhắn mới nhất
- **Đo lường**: Thời gian từ khi mở chat đến khi hiển thị tin nhắn

## Tối ưu UI Rendering

### 1. Sử dụng `const` Constructor

```dart
// KHÔNG TỐT
return Container(
  padding: EdgeInsets.all(8),
  child: Text('Hello'),
);

// TỐT
return const Container(
  padding: EdgeInsets.all(8),
  child: Text('Hello'),
);
```

### 2. Phân tách Widget

```dart
// KHÔNG TỐT - Một widget lớn xây dựng toàn bộ UI
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          // Xây dựng message item phức tạp tại đây
        },
      ),
    );
  }
}

// TỐT - Phân chia thành các widget nhỏ hơn
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(chat: chat),
      body: MessageList(messages: messages),
    );
  }
}

class MessageList extends StatelessWidget {
  final List<Message> messages;
  
  const MessageList({Key? key, required this.messages}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) => MessageItem(message: messages[index]),
    );
  }
}
```

### 3. Sử dụng `RepaintBoundary`

Bọc các widget phức tạp có animation hoặc thay đổi thường xuyên trong `RepaintBoundary`:

```dart
RepaintBoundary(
  child: TypingIndicator(),
)
```

### 4. Sử dụng công cụ `Flutter DevTools`

- Bật opcodes trong DevTools để kiểm tra số lần rebuild
- Sử dụng Performance overlay để kiểm tra GPU và CPU frame times

## Tối ưu danh sách và grid

### 1. Lazy loading và pagination

```dart
class MessageListBloc extends Bloc<MessageListEvent, MessageListState> {
  static const int PAGE_SIZE = 20;
  
  // Thêm logic để tải tin nhắn theo trang
  // Tải thêm khi người dùng cuộn đến cuối danh sách
}
```

### 2. Tái sử dụng các item trong ListView

```dart
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return MessageItem(
      key: ValueKey(messages[index].id), // Giúp Flutter nhận diện đúng widget
      message: messages[index],
    );
  },
)
```

### 3. Sử dụng các phương pháp hiển thị tối ưu

- `ListView.builder` thay vì `ListView` 
- `const` constructor khi có thể
- Xóa các item không còn trong viewport

## Tối ưu hình ảnh và media

### 1. Kích thước và nén ảnh

```dart
// Sử dụng CachedNetworkImage với các tùy chọn tối ưu
CachedNetworkImage(
  imageUrl: chat.avatarUrl,
  width: 40,
  height: 40,
  memCacheWidth: 80, // 2x cho màn hình retina
  fadeOutDuration: Duration.zero, // Tắt fade animation nếu không cần thiết
  placeholder: (context, url) => ColoredBox(color: Colors.grey.shade200),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### 2. Preloading và caching

```dart
// Trong chat list item, preload hình ảnh của chat detail khi có thể
void _preloadChatImages(Chat chat) {
  final animationService = GetIt.instance<AnimationService>();
  
  if (animationService.shouldPreloadImages) {
    precacheImage(
      CachedNetworkImageProvider(chat.avatarUrl),
      context,
    );
  }
}
```

### 3. Thức dậy và giải phóng tài nguyên

```dart
// Theo dõi vòng đời của widget để quản lý tài nguyên
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _precacheImages();
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

## Tối ưu state management

### 1. Sử dụng BLoC một cách hiệu quả

```dart
// KHÔNG TỐT - State chứa dữ liệu không cần thiết
class ChatState {
  final List<Message> messages;
  final List<User> allUsers; // Toàn bộ danh sách người dùng không cần thiết
  
  ChatState({required this.messages, required this.allUsers});
}

// TỐT - Chỉ giữ dữ liệu cần thiết trong state
class ChatState {
  final List<Message> messages;
  final Map<String, User> relevantUsers; // Chỉ lưu những người liên quan đến cuộc trò chuyện
  
  ChatState({required this.messages, required this.relevantUsers});
}
```

### 2. Tránh rebuild không cần thiết

```dart
// Sử dụng BlocBuilder với điều kiện rebuild
BlocBuilder<ChatBloc, ChatState>(
  buildWhen: (previous, current) => previous.messages != current.messages,
  builder: (context, state) {
    return MessageList(messages: state.messages);
  },
)
```

### 3. Sử dụng bộ chọn (selectors) để tách dữ liệu

```dart
// Sử dụng BlocSelector để tránh rebuild toàn bộ UI
BlocSelector<ChatBloc, ChatState, bool>(
  selector: (state) => state.isTyping,
  builder: (context, isTyping) {
    return TypingIndicator(isVisible: isTyping);
  },
)
```

## Tối ưu Database và Network

### 1. Sử dụng indices cho SQLite

```dart
// Trong database_service.dart
Future<void> _createTables(Database db) async {
  await db.execute('''
    CREATE TABLE messages (
      id TEXT PRIMARY KEY,
      chat_id TEXT NOT NULL,
      sender_id TEXT NOT NULL,
      content TEXT,
      timestamp INTEGER NOT NULL,
      status INTEGER NOT NULL
    )
  ''');
  
  // Tạo indices cho các truy vấn phổ biến
  await db.execute('CREATE INDEX idx_messages_chat_id ON messages (chat_id)');
  await db.execute('CREATE INDEX idx_messages_timestamp ON messages (timestamp)');
}
```

### 2. Sử dụng batch operations

```dart
// Thay vì insert từng tin nhắn
Future<void> saveMessages(List<Message> messages) async {
  final db = await database;
  final batch = db.batch();
  
  for (final message in messages) {
    batch.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  await batch.commit(noResult: true);
}
```

### 3. Tối ưu network requests

```dart
// Sử dụng gzip compression
final httpClient = http.Client();
final request = http.Request('GET', Uri.parse('$baseUrl/messages'));
request.headers['Accept-Encoding'] = 'gzip';

// Sử dụng HTTP/2 khi có thể
// Sử dụng JSON compaction nếu API hỗ trợ
```

## Tối ưu cho thiết bị cấu hình thấp

### 1. Giảm độ phức tạp của animation

```dart
// Trong animation_service.dart
bool get shouldUseComplexAnimations {
  return deviceCapabilityService.animationLevel == AnimationLevel.high;
}

// Trong UI
final animationService = GetIt.instance<AnimationService>();
final Duration duration = animationService.shouldUseComplexAnimations
    ? const Duration(milliseconds: 300)
    : const Duration(milliseconds: 150);
```

### 2. Giảm số lượng item được render

```dart
// Hiển thị ít item hơn trên thiết bị cấu hình thấp
final deviceCapabilityService = GetIt.instance<DeviceCapabilityService>();
final int pageSize = deviceCapabilityService.animationLevel == AnimationLevel.low
    ? 10
    : 20;
```

### 3. Giảm độ phức tạp của UI

```dart
// Hiển thị UI đơn giản hơn trên thiết bị cấu hình thấp
final bool isLowEndDevice = 
    GetIt.instance<DeviceCapabilityService>().animationLevel == AnimationLevel.low;

return isLowEndDevice
    ? _buildSimpleLayout()
    : _buildRichLayout();
```

## Công cụ theo dõi hiệu suất

### 1. Flutter DevTools
- Performance tab
- Memory tab
- Widget Inspector

### 2. Lighthouse và Firebase Performance
- Đo lường thời gian khởi động
- Thời gian phản hồi trên API
- Tracking metrics tùy chỉnh

### 3. Tích hợp performance monitoring

```dart
// Đo thời gian tải tin nhắn
void _loadMessages() async {
  final Stopwatch stopwatch = Stopwatch()..start();
  
  await chatBloc.loadInitialMessages();
  
  stopwatch.stop();
  log('Time to load messages: ${stopwatch.elapsedMilliseconds}ms');
  
  // Hoặc sử dụng Firebase Performance
  final trace = FirebasePerformance.instance.newTrace('load_messages');
  trace.start();
  
  // Code to measure
  
  trace.stop();
}
```

## Checklist trước khi release

1. ✅ Thực hiện profile app trên thiết bị cấu hình thấp
2. ✅ Kiểm tra memory leaks bằng DevTools
3. ✅ Kiểm tra độ mượt của animations (đặc biệt là Hero animations)
4. ✅ Thử nghiệm với nhiều tin nhắn (1000+)
5. ✅ Đo thời gian khởi động và tải dữ liệu
6. ✅ Tối ưu các asset (hình ảnh, Lottie files)
7. ✅ Chạy Flutter analyze và fix tất cả cảnh báo

## Tài liệu tham khảo

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/rendering/best-practices)
- [DeviceCapabilityService](./animation_system.md#device-capability-service)
- [AnimationService](./animation_system.md#animation-service)
- [SQLite trong Flutter](https://flutter.dev/docs/cookbook/persistence/sqlite)
- [Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon) 