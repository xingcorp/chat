# Chiến lược Tối ưu Hiệu suất

Tài liệu này mô tả các chiến lược và kỹ thuật được áp dụng trong ứng dụng chat để tối ưu hiệu suất, đảm bảo ứng dụng hoạt động mượt mà trên nhiều loại thiết bị khác nhau, từ cấu hình thấp đến cao cấp.

## Mô hình Đo lường Hiệu suất

Trước khi tối ưu, ứng dụng sử dụng mô hình đo lường hiệu suất để xác định các vấn đề cần giải quyết:

```dart
class PerformanceMetrics {
  // Định nghĩa ngưỡng cho từng metric
  static const Duration acceptableFrameTime = Duration(milliseconds: 16); // 60 FPS
  static const Duration poorFrameTime = Duration(milliseconds: 32); // 30 FPS
  static const int acceptableMemoryMB = 100;
  static const Duration acceptableNetworkTime = Duration(milliseconds: 300);
  
  // Flutter performance overlay
  static Widget buildPerformanceOverlay() {
    return const PerformanceOverlay.allEnabled(
      optionsMask: PerformanceOverlay.rasterizerStatistics |
          PerformanceOverlay.displayStatistics |
          PerformanceOverlay.visualizeRasterizerStatistics |
          PerformanceOverlay.visualizeEngineStatistics,
    );
  }
}
```

## Tối ưu UI Rendering

### 1. Widget Caching và Constant Constructors

```dart
// KHÔNG TỐT: Tạo mới widget mỗi lần build
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Messages'),
      Icon(Icons.message),
      // Tạo mới widget không cần thiết
      MessageList(
        messages: messages,
        onTap: (message) => handleMessageTap(message),
      ),
    ],
  );
}

// TỐT: Sử dụng const constructors khi có thể
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      const Text('Messages'), // Được cache
      const Icon(Icons.message), // Được cache
      MessageList(
        messages: messages,
        onTap: handleMessageTap, // Truyền reference thay vì closure
      ),
    ],
  );
}
```

### 2. Build Method Optimization

```dart
// KHÔNG TỐT: Method build quá lớn
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(chat.name)),
    body: Column(
      children: [
        // Phần header
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(child: Text(chat.name[0])),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${chat.memberCount} members', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        
        // Phần messages list
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return MessageBubble(
                message: message,
                isOwn: message.senderId == currentUserId,
              );
            },
          ),
        ),
        
        // Phần input
        Container(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: () => handleAttachment(),
              ),
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () => sendMessage(textController.text),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// TỐT: Chia thành các components nhỏ hơn
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(chat.name)),
    body: Column(
      children: [
        _buildChatHeader(),
        _buildMessagesList(),
        _buildInputArea(),
      ],
    ),
  );
}

Widget _buildChatHeader() {
  return ChatHeaderWidget(chat: chat);
}

Widget _buildMessagesList() {
  return Expanded(
    child: MessageListWidget(
      messages: messages,
      currentUserId: currentUserId,
    ),
  );
}

Widget _buildInputArea() {
  return MessageInputWidget(
    controller: textController,
    onSend: sendMessage,
    onAttachment: handleAttachment,
  );
}
```

### 3. ShouldRebuild và buildWhen trong BLoC

```dart
// Sử dụng buildWhen trong BlocBuilder để giảm rebuild không cần thiết
BlocBuilder<ChatBloc, ChatState>(
  buildWhen: (previous, current) {
    // Chỉ rebuild khi danh sách tin nhắn thay đổi
    return previous.messages != current.messages;
  },
  builder: (context, state) {
    return MessageList(messages: state.messages);
  },
)
```

### 4. RepaintBoundary

```dart
class MessageList extends StatelessWidget {
  final List<Message> messages;
  
  const MessageList({Key? key, required this.messages}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        // Wrap message bubble trong RepaintBoundary để tách biệt với phần còn lại của UI
        return RepaintBoundary(
          child: MessageBubble(message: message),
        );
      },
    );
  }
}
```

## Tối ưu Memory

### 1. Lazy Loading và Pagination

```dart
class MessageListBloc extends Bloc<MessageListEvent, MessageListState> {
  final MessageRepository _repository;
  static const _pageSize = 20;
  
  MessageListBloc({required MessageRepository repository})
      : _repository = repository,
        super(MessageListState.initial()) {
    on<LoadInitialMessages>(_onLoadInitial);
    on<LoadMoreMessages>(_onLoadMore);
  }
  
  Future<void> _onLoadInitial(
    LoadInitialMessages event,
    Emitter<MessageListState> emit,
  ) async {
    emit(state.copyWith(status: MessageListStatus.loading));
    
    try {
      final messages = await _repository.getMessages(
        chatId: event.chatId,
        limit: _pageSize,
      );
      
      emit(state.copyWith(
        status: MessageListStatus.loaded,
        messages: messages,
        hasReachedEnd: messages.length < _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MessageListStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  Future<void> _onLoadMore(
    LoadMoreMessages event,
    Emitter<MessageListState> emit,
  ) async {
    if (state.hasReachedEnd) return;
    
    emit(state.copyWith(status: MessageListStatus.loadingMore));
    
    try {
      final lastMessageId = state.messages.last.id;
      
      final moreMessages = await _repository.getMessages(
        chatId: event.chatId,
        limit: _pageSize,
        beforeId: lastMessageId,
      );
      
      emit(state.copyWith(
        status: MessageListStatus.loaded,
        messages: [...state.messages, ...moreMessages],
        hasReachedEnd: moreMessages.length < _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MessageListStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
```

### 2. Cached Network Image và Memory Cache

```dart
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  
  const OptimizedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final deviceCapability = GetIt.instance<DeviceCapabilityService>();
    
    // Tính toán kích thước cache dựa trên khả năng thiết bị
    final int memCacheSize = deviceCapability.isLowEndDevice
        ? 300 // 300KB cho thiết bị thấp
        : deviceCapability.isHighEndDevice
            ? 1500 // 1.5MB cho thiết bị cao cấp
            : 700; // 700KB cho thiết bị trung bình
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      memCacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).toInt() : null,
      memCacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).toInt() : null,
      maxWidthDiskCache: 800, // Giới hạn kích thước cache trên disk
      fadeInDuration: const Duration(milliseconds: 300),
      progressIndicatorBuilder: (context, url, progress) => ShimmerPlaceholder(
        width: width,
        height: height,
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      cacheManager: CustomCacheManager.instance,
    );
  }
}

// Custom Cache Manager
class CustomCacheManager {
  static const key = 'optimizedCache';
  static late CacheManager instance;
  
  static void initialize() {
    instance = CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
  }
  
  static void clearCache() {
    instance.emptyCache();
  }
}
```

### 3. Memory Leak Prevention

```dart
class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late StreamSubscription _messageSubscription;
  
  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
  }
  
  void _subscribeToMessages() {
    _messageSubscription = GetIt.instance<MessageRepository>()
        .watchMessages(widget.chatId)
        .listen((messages) {
      // Update UI
    });
  }
  
  @override
  void dispose() {
    // Hủy subscription khi widget bị dispose
    _messageSubscription.cancel();
    super.dispose();
  }
}
```

### 4. Image Resolution Adaptation

```dart
class AdaptiveImage {
  static String getOptimizedUrl(String originalUrl, BuildContext context) {
    // Lấy mật độ điểm ảnh của thiết bị
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final connectivityService = GetIt.instance<ConnectivityService>();
    final connectionType = connectivityService.currentConnectionType;
    
    // Tính toán quality dựa trên kết nối và thiết bị
    int quality;
    if (connectionType == ConnectionType.wifi) {
      quality = 85;
    } else if (connectionType == ConnectionType.mobile) {
      quality = 70;
    } else {
      quality = 60; // Kết nối chậm
    }
    
    // Tính toán kích thước ảnh phù hợp
    final maxWidth = (devicePixelRatio * 500).round(); // 500 là chiều rộng cơ bản
    
    // Chuyển đổi url gốc thành url có tham số
    final Uri originalUri = Uri.parse(originalUrl);
    final optimizedUri = originalUri.replace(
      queryParameters: {
        ...originalUri.queryParameters,
        'w': maxWidth.toString(),
        'q': quality.toString(),
        'auto': 'format', // Chọn định dạng tốt nhất (WebP/AVIF cho modern browsers)
      },
    );
    
    return optimizedUri.toString();
  }
}
```

## Tối ưu Network

### 1. Network Request Batching và Debouncing

```dart
class NetworkRequestManager {
  final Map<String, List<Completer<dynamic>>> _pendingRequests = {};
  final Map<String, Timer> _debounceTimers = {};
  
  Future<T> debouncedRequest<T>({
    required String requestId,
    required Future<T> Function() request,
    Duration debounceTime = const Duration(milliseconds: 300),
  }) {
    final completer = Completer<T>();
    
    // Hủy timer cũ nếu có
    _debounceTimers[requestId]?.cancel();
    
    // Thêm completer vào danh sách chờ
    _pendingRequests.putIfAbsent(requestId, () => []).add(completer);
    
    // Tạo timer mới
    _debounceTimers[requestId] = Timer(debounceTime, () async {
      final completers = _pendingRequests[requestId] ?? [];
      _pendingRequests.remove(requestId);
      
      try {
        final result = await request();
        // Hoàn thành tất cả các completers đang chờ với kết quả
        for (final c in completers) {
          if (!c.isCompleted) c.complete(result);
        }
      } catch (e) {
        // Báo lỗi cho tất cả các completers đang chờ
        for (final c in completers) {
          if (!c.isCompleted) c.completeError(e);
        }
      }
    });
    
    return completer.future;
  }
  
  Future<List<T>> batchRequest<T>({
    required List<Future<T> Function()> requests,
    Duration maxWaitTime = const Duration(milliseconds: 50),
  }) async {
    if (requests.isEmpty) return [];
    
    final batchKey = 'batch_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<List<T>>();
    
    // Chờ maxWaitTime để tích lũy nhiều requests
    Timer(maxWaitTime, () async {
      try {
        final results = await Future.wait(requests.map((req) => req()));
        completer.complete(results);
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    return completer.future;
  }
}
```

### 2. GraphQL Optimization

```dart
class OptimizedGraphQLClient {
  final GraphQLClient _client;
  
  OptimizedGraphQLClient(this._client);
  
  Future<QueryResult> optimizedQuery({
    required QueryOptions options,
    CachePolicy? overrideCachePolicy,
  }) async {
    final connectivityService = GetIt.instance<ConnectivityService>();
    final connectionType = await connectivityService.getConnectionType();
    
    // Điều chỉnh cache policy dựa trên loại kết nối
    CachePolicy cachePolicy = overrideCachePolicy ?? CachePolicy.networkOnly;
    
    if (connectionType == ConnectionType.none) {
      // Offline: luôn sử dụng cache
      cachePolicy = CachePolicy.cacheOnly;
    } else if (connectionType == ConnectionType.mobile && 
               !overrideCachePolicy.networkOnly) {
      // Mobile: ưu tiên cache trước, sau đó background fetch
      cachePolicy = CachePolicy.cacheAndNetwork;
    }
    
    // Tạo query options mới với cache policy điều chỉnh
    final adjustedOptions = options.copyWith(
      fetchPolicy: cachePolicy,
    );
    
    return _client.query(adjustedOptions);
  }
  
  // Tối ưu fragment cho query
  static String optimizeQuery(String query, Set<String> neededFields) {
    // Đơn giản hóa: trích xuất các fields cần thiết
    // Trong thực tế, cần phân tích cú pháp GraphQL
    final fieldsString = neededFields.join('\n');
    return query.replaceAll('__FIELDS__', fieldsString);
  }
}
```

### 3. Connection-aware Operation Queue

```dart
class OperationQueueService {
  final DatabaseHelper _db;
  final NetworkInfo _networkInfo;
  bool _isProcessing = false;
  final _operationStreamController = StreamController<OperationStatus>.broadcast();
  
  Stream<OperationStatus> get operationStream => _operationStreamController.stream;
  
  OperationQueueService(this._db, this._networkInfo) {
    // Lắng nghe thay đổi kết nối
    _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        processQueue();
      }
    });
  }
  
  Future<void> addOperation(NetworkOperation operation) async {
    // Lưu operation vào database
    await _db.insert('operations', operation.toMap());
    
    // Thông báo operation đã được thêm vào queue
    _operationStreamController.add(
      OperationStatus(
        id: operation.id,
        status: OperationStatusType.queued,
      ),
    );
    
    // Kiểm tra kết nối và xử lý queue nếu có thể
    if (await _networkInfo.isConnected) {
      processQueue();
    }
  }
  
  Future<void> processQueue() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      // Lấy tất cả operations chưa hoàn thành
      final operations = await _db.query(
        'operations',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );
      
      for (final op in operations) {
        final operation = NetworkOperation.fromMap(op);
        
        try {
          // Thông báo bắt đầu xử lý
          _operationStreamController.add(
            OperationStatus(
              id: operation.id,
              status: OperationStatusType.processing,
            ),
          );
          
          // Xử lý operation
          await _executeOperation(operation);
          
          // Cập nhật trạng thái trong DB
          await _db.update(
            'operations',
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [operation.id],
          );
          
          // Thông báo hoàn thành
          _operationStreamController.add(
            OperationStatus(
              id: operation.id,
              status: OperationStatusType.completed,
            ),
          );
        } catch (e) {
          // Tăng số lần retry
          final retryCount = operation.retryCount + 1;
          
          if (retryCount <= operation.maxRetries) {
            // Cập nhật retry count
            await _db.update(
              'operations',
              {
                'retry_count': retryCount,
                'next_retry': DateTime.now().add(calculateBackoff(retryCount)).toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [operation.id],
            );
            
            // Thông báo thất bại tạm thời
            _operationStreamController.add(
              OperationStatus(
                id: operation.id,
                status: OperationStatusType.failed,
                error: e.toString(),
                willRetry: true,
              ),
            );
          } else {
            // Đánh dấu là failed vĩnh viễn
            await _db.update(
              'operations',
              {'status': 'failed', 'error': e.toString()},
              where: 'id = ?',
              whereArgs: [operation.id],
            );
            
            // Thông báo thất bại vĩnh viễn
            _operationStreamController.add(
              OperationStatus(
                id: operation.id,
                status: OperationStatusType.failed,
                error: e.toString(),
                willRetry: false,
              ),
            );
          }
          
          // Nếu lỗi là do kết nối, dừng xử lý queue
          if (e is NetworkException) {
            break;
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
  
  Future<void> _executeOperation(NetworkOperation operation) async {
    // Thực hiện operation dựa trên loại
    switch (operation.type) {
      case OperationType.sendMessage:
        return _executeMessageSend(operation);
      case OperationType.deleteMessage:
        return _executeMessageDelete(operation);
      // Các loại operation khác...
    }
  }
  
  Duration calculateBackoff(int retryCount) {
    // Exponential backoff với jitter để tránh thundering herd
    final baseDelay = Duration(seconds: pow(2, retryCount).toInt());
    final maxJitterMs = baseDelay.inMilliseconds ~/ 4;
    final jitter = Random().nextInt(maxJitterMs);
    return baseDelay + Duration(milliseconds: jitter);
  }
}
```

### 4. Adaptive Content Loading

```dart
class AdaptiveContentLoader {
  static Future<List<Message>> getMessages({
    required String chatId,
    required MessageRepository repository,
    bool forceRefresh = false,
  }) async {
    final deviceCapability = GetIt.instance<DeviceCapabilityService>();
    final connectivityService = GetIt.instance<ConnectivityService>();
    
    // Điều chỉnh số lượng tin nhắn dựa trên thiết bị và kết nối
    int messageLimit;
    bool includeMedia;
    
    final connectionType = await connectivityService.getConnectionType();
    
    if (deviceCapability.isLowEndDevice) {
      messageLimit = 20;
      includeMedia = connectionType == ConnectionType.wifi;
    } else if (deviceCapability.isHighEndDevice) {
      messageLimit = 50;
      includeMedia = true;
    } else {
      // Thiết bị trung bình
      messageLimit = 35;
      includeMedia = connectionType != ConnectionType.slow;
    }
    
    // Xác định fetch policy
    final fetchMode = _determineFetchMode(
      connectionType: connectionType, 
      deviceCapability: deviceCapability,
      forceRefresh: forceRefresh,
    );
    
    // Fetch messages với các tham số phù hợp
    return repository.getMessages(
      chatId: chatId,
      limit: messageLimit,
      includeMedia: includeMedia,
      fetchMode: fetchMode,
    );
  }
  
  static FetchMode _determineFetchMode({
    required ConnectionType connectionType,
    required DeviceCapabilityService deviceCapability,
    required bool forceRefresh,
  }) {
    if (forceRefresh) {
      return FetchMode.networkOnly;
    }
    
    switch (connectionType) {
      case ConnectionType.none:
        return FetchMode.cacheOnly;
      case ConnectionType.wifi:
        return FetchMode.networkFirst;
      case ConnectionType.mobile:
        return deviceCapability.isLowEndDevice 
            ? FetchMode.cacheFirst 
            : FetchMode.networkFirst;
      case ConnectionType.slow:
        return FetchMode.cacheFirst;
      default:
        return FetchMode.networkFirst;
    }
  }
}

enum FetchMode {
  networkOnly,   // Chỉ lấy từ server, lỗi nếu không có kết nối
  networkFirst,  // Ưu tiên server, fallback về cache nếu lỗi
  cacheFirst,    // Ưu tiên cache, sau đó background sync nếu có kết nối
  cacheOnly,     // Chỉ lấy từ cache, lỗi nếu không có cache
}
```

## Tracking và Phân tích Hiệu suất

```dart
class PerformanceTracking {
  static final _traces = <String, Trace>{};
  static final _timings = <String, List<Duration>>{};
  
  // Bắt đầu đo thời gian cho một hoạt động
  static void startTrace(String name) {
    _traces[name] = Trace(name: name)..start();
  }
  
  // Dừng đo thời gian và lưu kết quả
  static void stopTrace(String name) {
    if (_traces.containsKey(name)) {
      final trace = _traces[name]!;
      trace.stop();
      
      // Lưu kết quả
      _timings.putIfAbsent(name, () => []).add(trace.duration!);
      
      // Gửi lên Firebase Performance nếu cần
      FirebasePerformance.instance.newTrace(name)
        ..putAttribute('duration_ms', trace.duration!.inMilliseconds.toString())
        ..stop();
      
      _traces.remove(name);
    }
  }
  
  // Lấy thời gian trung bình cho một hoạt động
  static Duration? getAverageTime(String name) {
    final timings = _timings[name];
    if (timings == null || timings.isEmpty) return null;
    
    final totalMs = timings.fold<int>(
      0, (sum, duration) => sum + duration.inMilliseconds
    );
    return Duration(milliseconds: totalMs ~/ timings.length);
  }
  
  // Đánh dấu frame bị jank
  static void markJank() {
    FirebasePerformance.instance.newTrace('ui_jank')
      ..putAttribute('timestamp', DateTime.now().toIso8601String())
      ..stop();
  }
  
  // Theo dõi hiệu suất network request
  static Future<T> trackNetworkRequest<T>({
    required String name,
    required Future<T> Function() request,
  }) async {
    startTrace('network_$name');
    try {
      final result = await request();
      stopTrace('network_$name');
      return result;
    } catch (e) {
      stopTrace('network_$name');
      rethrow;
    }
  }
}

class Trace {
  final String name;
  DateTime? startTime;
  DateTime? endTime;
  Duration? get duration => endTime?.difference(startTime!);
  
  Trace({required this.name});
  
  void start() {
    startTime = DateTime.now();
  }
  
  void stop() {
    endTime = DateTime.now();
  }
}
```

## Adaptive Performance

```dart
class AdaptivePerformanceService {
  final DeviceCapabilityService _deviceCapabilityService;
  AnimationLevel _currentAnimationLevel = AnimationLevel.standard;
  
  AdaptivePerformanceService(this._deviceCapabilityService) {
    _initializeAnimationLevel();
  }
  
  // Khởi tạo animation level dựa trên thiết bị
  Future<void> _initializeAnimationLevel() async {
    if (_deviceCapabilityService.isLowEndDevice) {
      _currentAnimationLevel = AnimationLevel.minimal;
    } else if (_deviceCapabilityService.isHighEndDevice) {
      _currentAnimationLevel = AnimationLevel.advanced;
    } else {
      _currentAnimationLevel = AnimationLevel.standard;
    }
    
    // Lưu setting vào local storage
    await _persistAnimationLevel();
  }
  
  AnimationLevel get animationLevel => _currentAnimationLevel;
  
  // Thay đổi animation level và lưu vào local storage
  Future<void> setAnimationLevel(AnimationLevel level) async {
    _currentAnimationLevel = level;
    await _persistAnimationLevel();
  }
  
  Future<void> _persistAnimationLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('animation_level', _currentAnimationLevel.toString());
  }
  
  // Lấy duration cho một animation dựa trên current level
  Duration getAnimationDuration(AnimationType type) {
    switch (_currentAnimationLevel) {
      case AnimationLevel.off:
        return Duration.zero;
      case AnimationLevel.minimal:
        return _getMinimalDuration(type);
      case AnimationLevel.standard:
        return _getStandardDuration(type);
      case AnimationLevel.advanced:
        return _getAdvancedDuration(type);
    }
  }
  
  Curve getAnimationCurve(AnimationType type) {
    switch (_currentAnimationLevel) {
      case AnimationLevel.off:
        return Curves.linear; // No animation
      case AnimationLevel.minimal:
        return Curves.easeIn; // Simpler curves for minimal animations
      case AnimationLevel.standard:
        return _getStandardCurve(type);
      case AnimationLevel.advanced:
        return _getAdvancedCurve(type);
    }
  }
  
  // Helper methods to get specific durations and curves
  Duration _getMinimalDuration(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
        return const Duration(milliseconds: 150);
      case AnimationType.messageAppear:
        return const Duration(milliseconds: 100);
      case AnimationType.reaction:
        return const Duration(milliseconds: 150);
      default:
        return const Duration(milliseconds: 150);
    }
  }
  
  Duration _getStandardDuration(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
        return const Duration(milliseconds: 300);
      case AnimationType.messageAppear:
        return const Duration(milliseconds: 200);
      case AnimationType.reaction:
        return const Duration(milliseconds: 300);
      default:
        return const Duration(milliseconds: 250);
    }
  }
  
  Duration _getAdvancedDuration(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
        return const Duration(milliseconds: 400);
      case AnimationType.messageAppear:
        return const Duration(milliseconds: 250);
      case AnimationType.reaction:
        return const Duration(milliseconds: 400);
      default:
        return const Duration(milliseconds: 350);
    }
  }
  
  Curve _getStandardCurve(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
        return Curves.fastOutSlowIn;
      case AnimationType.messageAppear:
        return Curves.easeOut;
      case AnimationType.reaction:
        return Curves.elasticOut;
      default:
        return Curves.easeInOut;
    }
  }
  
  Curve _getAdvancedCurve(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
        return Curves.fastLinearToSlowEaseIn;
      case AnimationType.messageAppear:
        return Curves.easeOutBack;
      case AnimationType.reaction:
        return Curves.elasticOut;
      default:
        return Curves.easeInOutCubic;
    }
  }
}

enum AnimationLevel {
  off,       // No animations
  minimal,   // Only essential animations
  standard,  // Default animations
  advanced,  // Enhanced animations
}

enum AnimationType {
  pageTransition,
  messageAppear,
  reaction,
  typing,
  loadingIndicator,
}
```

## Top Performance Tips

1. **Profile trước khi tối ưu**: Sử dụng DevTools để xác định các điểm nóng hiệu suất
2. **Tránh rebuild không cần thiết**: 
   - Sử dụng `const` constructors
   - Sử dụng `buildWhen` trong BLoC
   - Tách widget thành các component nhỏ
3. **Lazy load và virtual scrolling**:
   - Chỉ tải dữ liệu cần thiết
   - Sử dụng pagination thay vì tải tất cả một lúc
4. **Tối ưu quản lý bộ nhớ**:
   - Dispose resources khi không cần
   - Sử dụng image caching với kích thước phù hợp
5. **Tối ưu mạng**:
   - Implement retry và offline caching
   - Sử dụng batch requests và debouncing
   - Tải nội dung thích ứng với loại kết nối

## Checklist hiệu suất

- [ ] Memory Optimization
  - [ ] Sử dụng const constructors cho static widgets
  - [ ] Implement pagination cho lists dài
  - [ ] Xử lý và giải phóng resources trong dispose
  - [ ] Tối ưu image loading và caching
  
- [ ] UI Rendering
  - [ ] Tách widgets lớn thành các components nhỏ
  - [ ] Sử dụng RepaintBoundary cho widgets phức tạp
  - [ ] Tránh rebuild không cần thiết
  - [ ] Sử dụng AnimationController với deviceFrameSync
  
- [ ] Network
  - [ ] Implement offline-first strategy
  - [ ] Sử dụng debouncing và batching
  - [ ] Adaptive content loading theo loại thiết bị/kết nối
  - [ ] Xử lý network failures gracefully
  
- [ ] General
  - [ ] Đo lường hiệu suất ứng dụng
  - [ ] Kiểm tra trên thiết bị thực tế, không chỉ emulator
  - [ ] Điều chỉnh settings cho từng nhóm thiết bị
  - [ ] A/B test các thay đổi hiệu suất

## Tham khảo

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/rendering/best-practices)
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
- [Image Optimization](https://flutter.dev/docs/cookbook/images/cached-images)
- [Network Performance](https://flutter.dev/docs/cookbook/networking/fetch-data)
- [Memory Optimization](https://flutter.dev/docs/cookbook/maintenance/error-reporting) 