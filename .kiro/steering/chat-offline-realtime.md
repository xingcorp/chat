---
title: Chat Offline-First & Real-time Features
inclusion: conditional
fileMatchPattern: "flutter_chat_app/lib/**/*{offline,sync,socket,realtime}*.dart"
priority: high
---

# Chat Offline-First & Real-time Features

> Implement offline-first architecture with real-time synchronization

## 🎯 Offline-First Strategy

### Architecture Overview
```
User Action
    ↓
Save to Local DB (Isar)
    ↓
Add to Sync Queue
    ↓
Update UI (Optimistic)
    ↓
Send to Server (when online)
    ↓
Update Local DB with Server Response
    ↓
Remove from Sync Queue
```

## 📦 Sync Queue Implementation

### Queue Model
```dart
// lib/data/models/sync/sync_queue_item_model.dart
@collection
class SyncQueueItemModel {
  @Id()
  late int id;
  
  @Index()
  late String itemId; // Message ID or conversation ID
  
  @Enumerated(EnumType.name)
  late SyncAction action;
  
  @Enumerated(EnumType.name)
  late SyncStatus status;
  
  late String payload; // JSON string
  
  late int retryCount;
  
  late DateTime createdAt;
  
  DateTime? lastAttemptAt;
  
  String? errorMessage;
}

enum SyncAction {
  sendMessage,
  editMessage,
  deleteMessage,
  addReaction,
  removeReaction,
  markAsRead,
  createGroup,
  editGroup,
  leaveGroup,
}

enum SyncStatus {
  pending,
  processing,
  failed,
  completed,
}
```

### Sync Queue Service
```dart
// lib/core/services/sync_queue_service.dart
@singleton
class SyncQueueService {
  final Isar _isar;
  final INetworkInfo _networkInfo;
  final Logger _logger;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  SyncQueueService(this._isar, this._networkInfo, this._logger);
  
  /// Add item to sync queue
  Future<void> enqueue({
    required String itemId,
    required SyncAction action,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItemModel()
      ..itemId = itemId
      ..action = action
      ..status = SyncStatus.pending
      ..payload = jsonEncode(payload)
      ..retryCount = 0
      ..createdAt = DateTime.now();
    
    await _isar.writeTxn(() async {
      await _isar.syncQueueItemModels.put(item);
    });
    
    _logger.i('Enqueued sync item', data: {
      'itemId': itemId,
      'action': action.name,
    });
    
    // Try to sync immediately if online
    if (await _networkInfo.isConnected) {
      unawaited(processQueue());
    }
  }
  
  /// Start periodic sync
  void startPeriodicSync({Duration interval = const Duration(seconds: 30)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) async {
      if (await _networkInfo.isConnected) {
        await processQueue();
      }
    });
  }
  
  /// Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  /// Process sync queue
  Future<void> processQueue() async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping');
      return;
    }
    
    if (!await _networkInfo.isConnected) {
      _logger.d('No internet connection, skipping sync');
      return;
    }
    
    _isSyncing = true;
    
    try {
      final pendingItems = await _isar.syncQueueItemModels
          .filter()
          .statusEqualTo(SyncStatus.pending)
          .or()
          .statusEqualTo(SyncStatus.failed)
          .sortByCreatedAt()
          .findAll();
      
      _logger.i('Processing ${pendingItems.length} sync items');
      
      for (final item in pendingItems) {
        await _processSyncItem(item);
      }
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _processSyncItem(SyncQueueItemModel item) async {
    // Update status to processing
    item.status = SyncStatus.processing;
    item.lastAttemptAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.syncQueueItemModels.put(item);
    });
    
    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      
      switch (item.action) {
        case SyncAction.sendMessage:
          await _syncSendMessage(payload);
          break;
        case SyncAction.editMessage:
          await _syncEditMessage(payload);
          break;
        case SyncAction.deleteMessage:
          await _syncDeleteMessage(payload);
          break;
        case SyncAction.addReaction:
          await _syncAddReaction(payload);
          break;
        case SyncAction.markAsRead:
          await _syncMarkAsRead(payload);
          break;
        // Add other actions...
      }
      
      // Mark as completed and remove
      await _isar.writeTxn(() async {
        await _isar.syncQueueItemModels.delete(item.id);
      });
      
      _logger.i('Sync item completed', data: {
        'itemId': item.itemId,
        'action': item.action.name,
      });
      
    } catch (e, stackTrace) {
      _logger.e('Sync item failed', error: e, stackTrace: stackTrace);
      
      // Update retry count and status
      item.retryCount++;
      item.errorMessage = e.toString();
      
      if (item.retryCount >= 3) {
        item.status = SyncStatus.failed;
        _logger.e('Sync item failed permanently after 3 retries', data: {
          'itemId': item.itemId,
          'action': item.action.name,
        });
      } else {
        item.status = SyncStatus.pending;
      }
      
      await _isar.writeTxn(() async {
        await _isar.syncQueueItemModels.put(item);
      });
    }
  }
  
  Future<void> _syncSendMessage(Map<String, dynamic> payload) async {
    // Implement actual API call
    final messageId = payload['messageId'] as String;
    final conversationId = payload['conversationId'] as String;
    final content = payload['content'] as String?;
    
    // Call remote data source
    // Update local message with server response
  }
  
  // Implement other sync methods...
  
  void dispose() {
    stopPeriodicSync();
  }
}
```

## 🔄 Real-time Message Handling

### Socket Manager
```dart
// lib/core/network/socket_manager.dart
@singleton
class SocketManager {
  final SocketDataSource _socket;
  final Isar _isar;
  final Logger _logger;
  
  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _reactionController = StreamController<ReactionEvent>.broadcast();
  
  SocketManager(this._socket, this._isar, this._logger);
  
  Future<void> initialize(String token) async {
    await _socket.connect(token);
    _setupEventListeners();
  }
  
  void _setupEventListeners() {
    // New message received
    _socket.on<Map<String, dynamic>>('message:sent').listen((data) async {
      try {
        final messageJson = data['message'] as Map<String, dynamic>;
        final conversationId = data['conversationId'] as String;
        
        // Save to local DB
        final messageModel = MessageModel.fromJson(messageJson);
        await _isar.writeTxn(() async {
          await _isar.messageModels.put(messageModel);
        });
        
        // Emit to stream
        final message = await _buildMessageEntity(messageModel);
        _messageController.add(message);
        
        _logger.i('New message received', data: {
          'messageId': message.id,
          'conversationId': conversationId,
        });
      } catch (e, stackTrace) {
        _logger.e('Error handling new message', error: e, stackTrace: stackTrace);
      }
    });
    
    // Message read
    _socket.on<Map<String, dynamic>>('message:read').listen((data) async {
      try {
        final messageJson = data['message'] as Map<String, dynamic>;
        final readerJson = data['reader'] as Map<String, dynamic>;
        
        final messageId = messageJson['id'] as String;
        final readerId = readerJson['id'] as String;
        
        // Update local DB
        final message = await _isar.messageModels
            .filter()
            .serverIdEqualTo(messageId)
            .findFirst();
        
        if (message != null) {
          message.readerIds ??= [];
          if (!message.readerIds!.contains(readerId)) {
            message.readerIds!.add(readerId);
            
            await _isar.writeTxn(() async {
              await _isar.messageModels.put(message);
            });
          }
        }
        
        _logger.d('Message read', data: {
          'messageId': messageId,
          'readerId': readerId,
        });
      } catch (e, stackTrace) {
        _logger.e('Error handling message read', error: e, stackTrace: stackTrace);
      }
    });
    
    // Reaction added/removed
    _socket.on<Map<String, dynamic>>('message:reaction').listen((data) async {
      try {
        final reactorJson = data['reactor'] as Map<String, dynamic>;
        final reactionData = data['data'] as Map<String, dynamic>;
        
        final messageId = reactionData['messageId'] as String;
        final emoji = reactionData['code'] as String;
        final act = reactionData['act'] as int;
        final reactorId = reactorJson['id'] as String;
        
        // Update local DB
        final message = await _isar.messageModels
            .filter()
            .serverIdEqualTo(messageId)
            .findFirst();
        
        if (message != null) {
          message.reactions ??= [];
          
          final reactionIndex = message.reactions!
              .indexWhere((r) => r.emoji == emoji);
          
          if (act == 1) {
            // Add reaction
            if (reactionIndex >= 0) {
              if (!message.reactions![reactionIndex].userIds.contains(reactorId)) {
                message.reactions![reactionIndex].userIds.add(reactorId);
              }
            } else {
              message.reactions!.add(ReactionModel()
                ..emoji = emoji
                ..userIds = [reactorId]);
            }
          } else {
            // Remove reaction
            if (reactionIndex >= 0) {
              message.reactions![reactionIndex].userIds.remove(reactorId);
              if (message.reactions![reactionIndex].userIds.isEmpty) {
                message.reactions!.removeAt(reactionIndex);
              }
            }
          }
          
          await _isar.writeTxn(() async {
            await _isar.messageModels.put(message);
          });
          
          _reactionController.add(ReactionEvent(
            messageId: messageId,
            emoji: emoji,
            userId: reactorId,
            added: act == 1,
          ));
        }
        
        _logger.d('Reaction updated', data: {
          'messageId': messageId,
          'emoji': emoji,
          'act': act == 1 ? 'add' : 'remove',
        });
      } catch (e, stackTrace) {
        _logger.e('Error handling reaction', error: e, stackTrace: stackTrace);
      }
    });
    
    // Message edited
    _socket.on<Map<String, dynamic>>('message:edit').listen((data) async {
      try {
        final messageJson = data['message'] as Map<String, dynamic>;
        final messageId = messageJson['id'] as String;
        final newContent = messageJson['message'] as String;
        
        // Update local DB
        final message = await _isar.messageModels
            .filter()
            .serverIdEqualTo(messageId)
            .findFirst();
        
        if (message != null) {
          message.content = newContent;
          message.updatedAt = DateTime.parse(messageJson['updatedAt']);
          
          await _isar.writeTxn(() async {
            await _isar.messageModels.put(message);
          });
        }
        
        _logger.d('Message edited', data: {'messageId': messageId});
      } catch (e, stackTrace) {
        _logger.e('Error handling message edit', error: e, stackTrace: stackTrace);
      }
    });
    
    // Message deleted
    _socket.on<Map<String, dynamic>>('message:delete').listen((data) async {
      try {
        final messageJson = data['message'] as Map<String, dynamic>;
        final messageId = messageJson['id'] as String;
        
        // Delete from local DB
        await _isar.writeTxn(() async {
          await _isar.messageModels
              .filter()
              .serverIdEqualTo(messageId)
              .deleteAll();
        });
        
        _logger.d('Message deleted', data: {'messageId': messageId});
      } catch (e, stackTrace) {
        _logger.e('Error handling message delete', error: e, stackTrace: stackTrace);
      }
    });
    
    // Typing indicator
    _socket.on<Map<String, dynamic>>('message:typing').listen((data) {
      try {
        final userId = data['userId'] as String;
        final fullName = data['fullName'] as String;
        final isTyping = data['isTyping'] as bool;
        final conversationId = data['conversationId'] as String;
        
        _typingController.add(TypingEvent(
          userId: userId,
          userName: fullName,
          conversationId: conversationId,
          isTyping: isTyping,
        ));
      } catch (e, stackTrace) {
        _logger.e('Error handling typing', error: e, stackTrace: stackTrace);
      }
    });
  }
  
  // Emit typing indicator
  void emitTyping(String conversationId, bool isTyping) {
    _socket.emit('message:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }
  
  // Streams
  Stream<Message> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<ReactionEvent> get reactionStream => _reactionController.stream;
  
  void dispose() {
    _messageController.close();
    _typingController.close();
    _reactionController.close();
    _socket.dispose();
  }
}

class TypingEvent {
  final String userId;
  final String userName;
  final String conversationId;
  final bool isTyping;
  
  TypingEvent({
    required this.userId,
    required this.userName,
    required this.conversationId,
    required this.isTyping,
  });
}

class ReactionEvent {
  final String messageId;
  final String emoji;
  final String userId;
  final bool added;
  
  ReactionEvent({
    required this.messageId,
    required this.emoji,
    required this.userId,
    required this.added,
  });
}
```

## 🔄 Repository Implementation

### Offline-First Message Repository
```dart
// lib/data/repositories/message_repository_impl.dart
@LazySingleton(as: IMessageRepository)
class MessageRepositoryImpl implements IMessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;
  final SyncQueueService _syncQueue;
  final INetworkInfo _networkInfo;
  final SocketManager _socketManager;
  
  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required MessageLocalDataSource localDataSource,
    required SyncQueueService syncQueue,
    required INetworkInfo networkInfo,
    required SocketManager socketManager,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _syncQueue = syncQueue,
       _networkInfo = networkInfo,
       _socketManager = socketManager;
  
  @override
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    int limit = 50,
    String? lastMessageId,
    DateTime? from,
  }) async {
    try {
      // Always try to get from server first if online
      if (await _networkInfo.isConnected) {
        try {
          final messages = await _remoteDataSource.getMessages(
            conversationId: conversationId,
            limit: limit,
            lastMessageId: lastMessageId,
            from: from,
          );
          
          // Save to local DB
          await _localDataSource.saveMessages(messages);
          
          // Convert to entities
          final entities = await Future.wait(
            messages.map((m) => _localDataSource.getMessageEntity(m.serverId)),
          );
          
          return Right(entities.whereType<Message>().toList());
        } on ServerException catch (e) {
          // Fall back to local if server fails
          return _getMessagesFromLocal(conversationId, limit, lastMessageId);
        }
      }
      
      // Get from local if offline
      return _getMessagesFromLocal(conversationId, limit, lastMessageId);
      
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
  
  Future<Either<Failure, List<Message>>> _getMessagesFromLocal(
    String conversationId,
    int limit,
    String? lastMessageId,
  ) async {
    try {
      final messages = await _localDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
        lastMessageId: lastMessageId,
      );
      
      final entities = await Future.wait(
        messages.map((m) => _localDataSource.getMessageEntity(m.serverId)),
      );
      
      return Right(entities.whereType<Message>().toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    String? receiverId,
    required MessageType type,
    String? content,
    List<String>? mediaUrls,
    String? fileName,
    String? replyToId,
    String? forwardedFromId,
  }) async {
    try {
      // Generate temp ID
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create local message
      final localMessage = MessageModel()
        ..serverId = tempId
        ..conversationId = conversationId
        ..senderId = 'current_user_id' // Get from auth
        ..type = type
        ..content = content
        ..mediaUrls = mediaUrls
        ..fileName = fileName
        ..replyToId = replyToId
        ..forwardedFromId = forwardedFromId
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..status = MessageStatus.sending;
      
      // Save to local DB
      await _localDataSource.saveMessage(localMessage);
      
      // Add to sync queue
      await _syncQueue.enqueue(
        itemId: tempId,
        action: SyncAction.sendMessage,
        payload: {
          'messageId': tempId,
          'conversationId': conversationId,
          'receiverId': receiverId,
          'type': type.name,
          'content': content,
          'mediaUrls': mediaUrls,
          'fileName': fileName,
          'replyToId': replyToId,
          'forwardedFromId': forwardedFromId,
        },
      );
      
      // Try to send immediately if online
      if (await _networkInfo.isConnected) {
        try {
          final sentMessage = await _remoteDataSource.sendMessage(
            conversationId: conversationId,
            receiverId: receiverId,
            type: type,
            content: content,
            mediaUrls: mediaUrls,
            fileName: fileName,
            replyToId: replyToId,
            forwardedFromId: forwardedFromId,
          );
          
          // Update local message with server response
          sentMessage.status = MessageStatus.sent;
          await _localDataSource.updateMessage(tempId, sentMessage);
          
          // Convert to entity
          final entity = await _localDataSource.getMessageEntity(sentMessage.serverId);
          return Right(entity!);
          
        } on ServerException catch (e) {
          // Mark as failed but keep in queue
          localMessage.status = MessageStatus.failed;
          await _localDataSource.saveMessage(localMessage);
          
          return Left(ServerFailure(message: e.message));
        }
      }
      
      // Return local message if offline
      final entity = await _localDataSource.getMessageEntity(tempId);
      return Right(entity!);
      
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
  
  @override
  Stream<Message> get messageStream => _socketManager.messageStream;
}
```

## 🎯 Typing Indicator

### Typing Cubit
```dart
// lib/presentation/blocs/typing/typing_cubit.dart
@injectable
class TypingCubit extends Cubit<TypingState> {
  final SocketManager _socketManager;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;
  
  TypingCubit(this._socketManager) : super(const TypingState.initial()) {
    _typingSubscription = _socketManager.typingStream.listen(_onTypingEvent);
  }
  
  void _onTypingEvent(TypingEvent event) {
    if (event.isTyping) {
      emit(TypingState.typing(
        userId: event.userId,
        userName: event.userName,
        conversationId: event.conversationId,
      ));
      
      // Auto-clear after 3 seconds
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        emit(const TypingState.initial());
      });
    } else {
      emit(const TypingState.initial());
    }
  }
  
  void startTyping(String conversationId) {
    _socketManager.emitTyping(conversationId, true);
    
    // Auto-stop after 3 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping(conversationId);
    });
  }
  
  void stopTyping(String conversationId) {
    _socketManager.emitTyping(conversationId, false);
    _typingTimer?.cancel();
  }
  
  @override
  Future<void> close() {
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    return super.close();
  }
}

@freezed
class TypingState with _$TypingState {
  const factory TypingState.initial() = _Initial;
  const factory TypingState.typing({
    required String userId,
    required String userName,
    required String conversationId,
  }) = _Typing;
}
```

### Typing Indicator Widget
```dart
// lib/presentation/widgets/chat/typing_indicator.dart
class TypingIndicator extends StatelessWidget {
  final String conversationId;
  
  const TypingIndicator({
    super.key,
    required this.conversationId,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TypingCubit, TypingState>(
      builder: (context, state) {
        return state.maybeWhen(
          typing: (userId, userName, convId) {
            if (convId != conversationId) {
              return const SizedBox.shrink();
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    '$userName is typing',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const TypingAnimation(),
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

class TypingAnimation extends StatefulWidget {
  const TypingAnimation({super.key});
  
  @override
  State<TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<TypingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (math.sin(value * math.pi)).clamp(0.3, 1.0);
            
            return Opacity(
              opacity: opacity,
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
```

---

**Key Points**:
- Always save to local DB first
- Add to sync queue for offline operations
- Process queue when online
- Listen to Socket.IO for real-time updates
- Implement optimistic UI updates
- Handle conflicts gracefully
