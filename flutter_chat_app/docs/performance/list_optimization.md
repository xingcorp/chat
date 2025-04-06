# Tối ưu danh sách tin nhắn

Tài liệu này cung cấp các kỹ thuật tối ưu hiệu suất để xử lý và hiển thị danh sách tin nhắn dài trong ứng dụng chat, đảm bảo cuộn mượt mà và sử dụng bộ nhớ hiệu quả.

## Các thách thức

Một ứng dụng chat có thể đối mặt với nhiều thách thức về hiệu suất khi xử lý danh sách tin nhắn:

- **Volume**: Cuộc trò chuyện có thể chứa hàng nghìn tin nhắn
- **Đa dạng nội dung**: Văn bản, hình ảnh, video, file đính kèm
- **Tương tác**: Reactions, replies, thread
- **Real-time**: Cập nhật liên tục từ server
- **Bộ nhớ**: Giới hạn bộ nhớ trên thiết bị cấu hình thấp

## Virtualization của ListView

### Nguyên lý chính

Virtualization là kỹ thuật chỉ render các mục đang hiển thị trong viewport và tái sử dụng các widget khi cuộn. Flutter đã tích hợp sẵn trong `ListView.builder` nhưng cần tối ưu thêm.

### Tối ưu ListView.builder

```dart
ListView.builder(
  // Đảm bảo itemExtent hoặc prototypeItem được chỉ định để tăng hiệu suất
  itemExtent: 70, // Chiều cao cố định cho mỗi item nếu có thể
  // Hoặc sử dụng prototypeItem cho chiều cao không cố định nhưng tương tự nhau
  prototypeItem: const MessageItem(message: prototypicalMessage),
  
  // Chỉ định initialScrollIndex để không phải cuộn từ đầu khi tải danh sách dài
  initialScrollIndex: messageCount - 20,
  
  // Sử dụng cacheExtent để preload items trước khi hiển thị
  cacheExtent: 500, // Pixel
  
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return MessageItem(
      key: ValueKey(messages[index].id),
      message: messages[index],
    );
  },
)
```

### Sử dụng ListView.separated

Khi cần hiển thị phân tách giữa các ngày hoặc nhóm tin nhắn:

```dart
ListView.separated(
  itemCount: messages.length,
  separatorBuilder: (context, index) {
    // Kiểm tra nếu cần hiển thị date separator
    if (_shouldShowDateSeparator(messages[index], messages[index + 1])) {
      return DateSeparator(date: messages[index].timestamp);
    }
    return const SizedBox.shrink();
  },
  itemBuilder: (context, index) {
    return MessageItem(
      key: ValueKey(messages[index].id),
      message: messages[index],
    );
  },
)
```

## Mô hình lazy-loading và pagination

### Chiến lược tải tin nhắn

1. **Mở đầu chat**: Tải 20-30 tin nhắn gần nhất
2. **Cuộn lên**: Tải thêm tin nhắn cũ hơn (pagination)
3. **Message jump**: Tải tin nhắn xung quanh vị trí nhảy đến

```dart
class MessageListBloc extends Bloc<MessageListEvent, MessageListState> {
  static const int INITIAL_MESSAGE_COUNT = 30;
  static const int PAGINATION_COUNT = 20;
  
  MessageListBloc({required this.messageRepository}) : super(MessageListInitial()) {
    on<LoadInitialMessages>(_onLoadInitialMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<JumpToMessage>(_onJumpToMessage);
  }
  
  Future<void> _onLoadInitialMessages(LoadInitialMessages event, Emitter<MessageListState> emit) async {
    emit(MessageListLoading());
    
    try {
      final messages = await messageRepository.getLatestMessages(
        chatId: event.chatId,
        limit: INITIAL_MESSAGE_COUNT,
      );
      
      emit(MessageListLoaded(
        messages: messages,
        hasMoreMessages: messages.length >= INITIAL_MESSAGE_COUNT,
      ));
    } catch (e) {
      emit(MessageListError(error: e.toString()));
    }
  }
  
  Future<void> _onLoadMoreMessages(LoadMoreMessages event, Emitter<MessageListState> emit) async {
    if (state is MessageListLoaded) {
      final currentState = state as MessageListLoaded;
      
      if (!currentState.hasMoreMessages || currentState.isLoadingMore) {
        return;
      }
      
      emit(currentState.copyWith(isLoadingMore: true));
      
      try {
        final oldestMessageId = currentState.messages.first.id;
        final olderMessages = await messageRepository.getMessagesBeforeId(
          chatId: event.chatId,
          messageId: oldestMessageId,
          limit: PAGINATION_COUNT,
        );
        
        emit(MessageListLoaded(
          messages: [...olderMessages, ...currentState.messages],
          hasMoreMessages: olderMessages.length >= PAGINATION_COUNT,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(MessageListError(error: e.toString()));
      }
    }
  }
  
  // Implementation for JumpToMessage...
}
```

### Kết hợp với ScrollController

```dart
class MessageListView extends StatefulWidget {
  @override
  _MessageListViewState createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Cuộn xuống khi mới load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
    
    // Xử lý pagination khi cuộn đến đầu danh sách
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    // Kiểm tra vị trí cuộn để tải thêm tin nhắn cũ
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent + 200) {
      context.read<MessageListBloc>().add(LoadMoreMessages(chatId: widget.chatId));
    }
  }
  
  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessageListBloc, MessageListState>(
      listener: (context, state) {
        // Cuộn xuống khi có tin nhắn mới
        if (state is MessageListLoaded && state.hasNewMessage) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state is MessageListLoaded) {
          return ListView.builder(
            controller: _scrollController,
            reverse: true, // Hiển thị từ dưới lên trên
            itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (state.isLoadingMore && index == 0) {
                return const LoadingIndicator();
              }
              
              final adjustedIndex = state.isLoadingMore ? index - 1 : index;
              final message = state.messages[adjustedIndex];
              
              return MessageItem(message: message);
            },
          );
        }
        
        // Các trạng thái khác...
      },
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

## Hiển thị tối ưu

### Nhóm tin nhắn

Nhóm tin nhắn từ cùng một người gửi trong khoảng thời gian ngắn để giảm overhead UI:

```dart
class MessageGrouping {
  static List<MessageGroup> groupMessages(List<Message> messages) {
    final groups = <MessageGroup>[];
    Message? currentSender;
    DateTime? lastTimestamp;
    List<Message> currentGroup = [];
    
    for (final message in messages) {
      // Bắt đầu nhóm mới nếu người gửi khác hoặc thời gian cách quá xa
      final shouldStartNewGroup = currentSender?.senderId != message.senderId || 
          lastTimestamp == null ||
          message.timestamp.difference(lastTimestamp).inMinutes > 2;
      
      if (shouldStartNewGroup && currentGroup.isNotEmpty) {
        groups.add(MessageGroup(messages: List.from(currentGroup)));
        currentGroup.clear();
      }
      
      currentGroup.add(message);
      currentSender = message;
      lastTimestamp = message.timestamp;
    }
    
    // Thêm nhóm cuối cùng
    if (currentGroup.isNotEmpty) {
      groups.add(MessageGroup(messages: currentGroup));
    }
    
    return groups;
  }
}
```

### Render tối ưu phức tạp

Sử dụng `RepaintBoundary` để ngăn vẽ lại khi không cần thiết:

```dart
class MessageItem extends StatelessWidget {
  final Message message;
  
  @override
  Widget build(BuildContext context) {
    // Đặt RepaintBoundary cho mỗi message item
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: _buildMessageContent(),
      ),
    );
  }
  
  Widget _buildMessageContent() {
    // Xây dựng nội dung tin nhắn...
  }
}
```

### Kích thước hình ảnh linh hoạt

Tối ưu kích thước hình ảnh dựa trên kích thước màn hình:

```dart
Widget _buildImageMessage(ImageMessage message) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Tính toán kích thước hiển thị tối ưu
      final maxWidth = constraints.maxWidth * 0.7;
      final aspectRatio = message.width / message.height;
      
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxWidth / aspectRatio,
        ),
        child: CachedNetworkImage(
          imageUrl: message.url,
          // Sử dụng kích thước được tính toán
          memCacheWidth: (maxWidth * MediaQuery.of(context).devicePixelRatio).toInt(),
          placeholder: (context, url) => const ShimmerLoading(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    },
  );
}
```

## Quản lý bộ nhớ và caching

### Cache quản lý cho hình ảnh

```dart
// Cấu hình trong main.dart
CachedNetworkImage.logLevel = CacheManagerLogLevel.warning;

PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100 MB
```

### Chiến lược giải phóng bộ nhớ

```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Giải phóng bộ nhớ khi ứng dụng ở background
      _clearMemoryCache();
    }
  }
  
  void _clearMemoryCache() {
    // Giữ lại cache cho các hình ảnh đang hiển thị
    // nhưng giải phóng phần còn lại
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Build method...
}
```

### Giới hạn số lượng tin nhắn dựa trên thiết bị

```dart
class MessageRepository {
  // Giới hạn số lượng tin nhắn load vào bộ nhớ dựa trên thông số thiết bị
  Future<List<Message>> getLatestMessages({
    required String chatId,
    int? limit,
  }) async {
    final deviceCapability = GetIt.instance<DeviceCapabilityService>();
    
    // Điều chỉnh giới hạn dựa trên khả năng thiết bị
    final effectiveLimit = limit ?? (deviceCapability.isHighEndDevice ? 50 : 30);
    
    // Truy vấn với giới hạn được điều chỉnh
    return _messageDao.getLatestMessages(chatId, effectiveLimit);
  }
}
```

## Tối ưu cuộn và tương tác

### Smoothing cuộn với ScrollPhysics

```dart
ListView.builder(
  // Điều chỉnh physics để cảm giác mượt mà hơn
  physics: const AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  ),
  // Các thuộc tính khác...
)
```

### Quản lý cuộn khi có bàn phím

```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _keyboardVisible = false;
  
  @override
  void initState() {
    super.initState();
    
    // Theo dõi khi bàn phím hiển thị/ẩn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardVisibilityController = KeyboardVisibilityController();
      keyboardVisibilityController.onChange.listen((bool visible) {
        setState(() {
          _keyboardVisible = visible;
        });
        
        // Cuộn xuống khi bàn phím hiện ra
        if (visible) {
          _scrollToBottom();
        }
      });
    });
  }
  
  void _scrollToBottom() {
    // Implement scroll to bottom...
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: MessageListView(
              scrollController: _scrollController,
            ),
          ),
          MessageInput(
            focusNode: _inputFocusNode,
          ),
          // Thêm padding khi bàn phím hiển thị trên iPhone X+ để tránh notch
          if (_keyboardVisible && MediaQuery.of(context).padding.bottom > 0)
            SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
```

### Tối ưu việc tìm kiếm tin nhắn

```dart
class ChatSearchDelegate extends SearchDelegate<Message?> {
  final String chatId;
  final MessageRepository messageRepository;
  
  ChatSearchDelegate({
    required this.chatId,
    required this.messageRepository,
  });
  
  // Search results are fetched lazily when results() is called
  Future<List<Message>> _searchMessages(String query) async {
    if (query.length < 2) return [];
    
    return messageRepository.searchMessages(
      chatId: chatId,
      query: query,
      limit: 20,
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Message>>(
      future: _searchMessages(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No messages found'));
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final message = snapshot.data![index];
            return SearchResultItem(
              message: message,
              onTap: () => close(context, message),
            );
          },
        );
      },
    );
  }
  
  // Other required methods...
}
```

## Độ đo hiệu suất và monitoring

### Đo thời gian render và cuộn

```dart
class PerformanceMonitor {
  final _messagesPerSecond = ValueNotifier<double>(0);
  ValueNotifier<double> get messagesPerSecond => _messagesPerSecond;
  
  int _lastFrameTime = 0;
  int _frameCount = 0;
  
  void startMonitoring() {
    SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
  }
  
  void _postFrameCallback(Duration timestamp) {
    final now = timestamp.inMilliseconds;
    _frameCount++;
    
    // Tính FPS mỗi giây
    if (_lastFrameTime > 0) {
      final elapsed = now - _lastFrameTime;
      if (elapsed > 1000) {
        final fps = _frameCount * 1000 / elapsed;
        _messagesPerSecond.value = fps;
        _frameCount = 0;
        _lastFrameTime = now;
        
        log('Message list rendering at $fps fps');
      }
    } else {
      _lastFrameTime = now;
    }
    
    // Tiếp tục theo dõi
    SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
  }
  
  void stopMonitoring() {
    // Implement cleanup...
  }
}
```

### Profiling với DevTools

```dart
// Đánh dấu frames quan trọng để trace trong DevTools
import 'package:flutter/services.dart';

void profileChatListScrolling() {
  const int timelineEvents = Timeline.startSync('ChatList scrolling');
  
  // Code logic bạn muốn profile
  
  Timeline.finishSync();
}
```

## Phương pháp tối ưu nâng cao

### Kỹ thuật windowing hiệu quả

```dart
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OptimizedChatList extends StatelessWidget {
  final List<Message> messages;
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        
        // Sử dụng VisibilityDetector để theo dõi khi nào một message
        // hiển thị trong viewport
        return VisibilityDetector(
          key: Key('message-${message.id}'),
          onVisibilityChanged: (visibilityInfo) {
            final visiblePercentage = visibilityInfo.visibleFraction * 100;
            if (visiblePercentage > 50) {
              // Đánh dấu tin nhắn đã đọc khi hiển thị > 50%
              context.read<ChatBloc>().add(MarkMessageAsRead(message.id));
            }
          },
          child: MessageItem(message: message),
        );
      },
    );
  }
}
```

### Dự đoán hướng cuộn

```dart
class PredictiveScrollingController extends ScrollController {
  bool _isPredictiveScrolling = false;
  final int preloadCount;
  
  PredictiveScrollingController({this.preloadCount = 5});
  
  void enablePredictiveScrolling(BuildContext context, String chatId) {
    // Theo dõi hướng cuộn để preload nội dung
    addListener(() {
      final direction = position.userScrollDirection;
      
      if (!_isPredictiveScrolling) {
        _isPredictiveScrolling = true;
        
        if (direction == ScrollDirection.reverse) {
          // Đang cuộn xuống, dự đoán sẽ cần tin nhắn mới hơn
          _preloadNewerMessages(context, chatId, preloadCount);
        } else if (direction == ScrollDirection.forward) {
          // Đang cuộn lên, dự đoán sẽ cần tin nhắn cũ hơn
          _preloadOlderMessages(context, chatId, preloadCount);
        }
        
        // Reset sau một khoảng thời gian
        Future.delayed(const Duration(milliseconds: 500), () {
          _isPredictiveScrolling = false;
        });
      }
    });
  }
  
  void _preloadNewerMessages(BuildContext context, String chatId, int count) {
    context.read<ChatBloc>().add(PreloadNewerMessages(chatId, count));
  }
  
  void _preloadOlderMessages(BuildContext context, String chatId, int count) {
    context.read<ChatBloc>().add(PreloadOlderMessages(chatId, count));
  }
}
```

## Bài học và thực tiễn tốt nhất

1. **Luôn đo lường trước và sau khi tối ưu** - Sử dụng DevTools, timeline, và logging để xác định điểm nghẽn cổ chai thực sự

2. **Ưu tiên UX hơn tối ưu hóa thiếu cân nhắc** - Đôi khi, hiệu ứng mượt mà và animation quan trọng hơn việc tiết kiệm vài millisecond xử lý

3. **Thử nghiệm trên thiết bị thực tế** - Đặc biệt là các thiết bị cấu hình thấp để đảm bảo trải nghiệm nhất quán

4. **Lazy loading là chìa khóa** - Không bao giờ tải tất cả tin nhắn cùng lúc, luôn phân trang và nạp theo nhu cầu

5. **Tối ưu cả UI và data layer** - Hiệu suất tốt đến từ việc tối ưu hóa cả cách bạn truy xuất dữ liệu và cách bạn render UI

## Tham khảo

- [Flutter Performance Metrics](https://flutter.dev/docs/perf/metrics)
- [Optimizing Performance](https://flutter.dev/docs/perf/rendering/optimize-performance)
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
- [ListView và ScrollPhysics](https://api.flutter.dev/flutter/widgets/ListView-class.html)
- [Flutter Image Caching](https://flutter.dev/docs/cookbook/images/cached-images) 