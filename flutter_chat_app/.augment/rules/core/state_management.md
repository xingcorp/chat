# State Management Rules - BLoC Pattern for Messaging App

**Type**: Auto  
**Description**: Comprehensive BLoC pattern implementation for real-time messaging with performance optimization

## BLoC Architecture Overview

### Event-State-BLoC Pattern
```dart
// Events - User actions and external triggers
@freezed
class MessageEvent with _$MessageEvent {
  const factory MessageEvent.loadMessages({
    required String chatId,
    int limit = 20,
  }) = LoadMessagesEvent;
  
  const factory MessageEvent.sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    List<String>? attachmentIds,
  }) = SendMessageEvent;
  
  const factory MessageEvent.receiveMessage({
    required ChatMessage message,
  }) = ReceiveMessageEvent;
  
  const factory MessageEvent.markAsRead({
    required String messageId,
  }) = MarkAsReadEvent;
}

// States - Application state representations
@freezed
class MessageState with _$MessageState {
  const factory MessageState.initial() = MessageInitial;
  
  const factory MessageState.loading({
    @Default([]) List<ChatMessage> messages,
  }) = MessageLoading;
  
  const factory MessageState.loaded({
    required List<ChatMessage> messages,
    required String chatId,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
  }) = MessageLoaded;
  
  const factory MessageState.error({
    required String message,
    @Default([]) List<ChatMessage> messages,
  }) = MessageError;
}
```

### BLoC Implementation with Use Cases
```dart
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  final MarkMessageAsReadUseCase _markAsRead;
  final StreamSubscription<ChatMessage>? _messageSubscription;
  
  MessageBloc({
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
    required MarkMessageAsReadUseCase markAsRead,
  }) : _getMessages = getMessages,
       _sendMessage = sendMessage,
       _markAsRead = markAsRead,
       super(const MessageState.initial()) {
    
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<MarkAsReadEvent>(_onMarkAsRead);
  }
  
  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageState.loading(messages: _getCurrentMessages()));
    
    final result = await _getMessages(GetMessagesParams(
      chatId: event.chatId,
      limit: event.limit,
    ));
    
    result.fold(
      (failure) => emit(MessageState.error(
        message: failure.message,
        messages: _getCurrentMessages(),
      )),
      (messages) => emit(MessageState.loaded(
        messages: messages,
        chatId: event.chatId,
        hasMore: messages.length >= event.limit,
      )),
    );
  }
  
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessageLoaded) return;
    
    // Optimistic update
    final optimisticMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: event.chatId,
      content: event.content,
      type: event.type,
      sender: await _getCurrentUser(),
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    emit(currentState.copyWith(
      messages: [optimisticMessage, ...currentState.messages],
    ));
    
    final result = await _sendMessage(SendMessageParams(
      chatId: event.chatId,
      content: event.content,
      type: event.type,
      attachmentIds: event.attachmentIds,
    ));
    
    result.fold(
      (failure) {
        // Remove optimistic message and show error
        final updatedMessages = currentState.messages
            .where((m) => m.id != optimisticMessage.id)
            .toList();
        emit(MessageState.error(
          message: failure.message,
          messages: updatedMessages,
        ));
      },
      (sentMessage) {
        // Replace optimistic message with real message
        final updatedMessages = currentState.messages
            .map((m) => m.id == optimisticMessage.id ? sentMessage : m)
            .toList();
        emit(currentState.copyWith(messages: updatedMessages));
      },
    );
  }
  
  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
```

## Real-time Integration

### WebSocket Message Handling
```dart
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  late final StreamSubscription<ChatMessage> _messageSubscription;
  
  MessageBloc({...}) : super(...) {
    // Subscribe to real-time messages
    _messageSubscription = _webSocketService
        .messageStream
        .listen((message) => add(MessageEvent.receiveMessage(message: message)));
  }
  
  void _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<MessageState> emit,
  ) {
    final currentState = state;
    if (currentState is MessageLoaded && 
        currentState.chatId == event.message.chatId) {
      
      // Check if message already exists (avoid duplicates)
      final existingIndex = currentState.messages
          .indexWhere((m) => m.id == event.message.id);
      
      List<ChatMessage> updatedMessages;
      if (existingIndex != -1) {
        // Update existing message
        updatedMessages = List.from(currentState.messages);
        updatedMessages[existingIndex] = event.message;
      } else {
        // Add new message
        updatedMessages = [event.message, ...currentState.messages];
      }
      
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }
}
```

## Performance Optimization

### Selective Rebuilding
```dart
class MessageListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<MessageBloc, MessageState, List<ChatMessage>>(
      selector: (state) => state.maybeMap(
        loaded: (state) => state.messages,
        orElse: () => [],
      ),
      builder: (context, messages) {
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) => MessageTile(
            message: messages[index],
            key: ValueKey(messages[index].id),
          ),
        );
      },
    );
  }
}

// Separate BLoC for typing indicators
class TypingBloc extends Bloc<TypingEvent, TypingState> {
  Timer? _typingTimer;
  
  void _onStartTyping(StartTypingEvent event, Emitter<TypingState> emit) {
    _typingTimer?.cancel();
    emit(TypingState.typing(userId: event.userId));
    
    // Auto-stop typing after 3 seconds
    _typingTimer = Timer(Duration(seconds: 3), () {
      add(TypingEvent.stopTyping(userId: event.userId));
    });
  }
}
```

### Memory Management
```dart
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  static const int _maxMessagesInMemory = 100;
  
  void _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessageLoaded || currentState.isLoadingMore) return;
    
    emit(currentState.copyWith(isLoadingMore: true));
    
    final result = await _getMessages(GetMessagesParams(
      chatId: currentState.chatId,
      limit: 20,
      before: currentState.messages.last.createdAt,
    ));
    
    result.fold(
      (failure) => emit(currentState.copyWith(
        isLoadingMore: false,
      )),
      (newMessages) {
        var allMessages = [...currentState.messages, ...newMessages];
        
        // Limit messages in memory
        if (allMessages.length > _maxMessagesInMemory) {
          allMessages = allMessages.take(_maxMessagesInMemory).toList();
        }
        
        emit(currentState.copyWith(
          messages: allMessages,
          hasMore: newMessages.length >= 20,
          isLoadingMore: false,
        ));
      },
    );
  }
}
```

## Error Handling & Recovery

### Resilient State Management
```dart
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  void _onSendMessage(SendMessageEvent event, Emitter<MessageState> emit) async {
    // ... optimistic update ...
    
    final result = await _sendMessage(params);
    
    result.fold(
      (failure) {
        // Implement retry logic for network failures
        if (failure is NetworkFailure) {
          _scheduleRetry(event, emit);
        } else {
          _handleSendError(failure, emit);
        }
      },
      (sentMessage) => _handleSendSuccess(sentMessage, emit),
    );
  }
  
  void _scheduleRetry(SendMessageEvent event, Emitter<MessageState> emit) {
    Timer(Duration(seconds: 5), () {
      if (!isClosed) {
        add(event); // Retry the same event
      }
    });
  }
}
```

## Testing Strategy

### BLoC Testing with bloc_test
```dart
group('MessageBloc', () {
  late MessageBloc messageBloc;
  late MockGetMessagesUseCase mockGetMessages;
  late MockSendMessageUseCase mockSendMessage;
  
  setUp(() {
    mockGetMessages = MockGetMessagesUseCase();
    mockSendMessage = MockSendMessageUseCase();
    messageBloc = MessageBloc(
      getMessages: mockGetMessages,
      sendMessage: mockSendMessage,
    );
  });
  
  blocTest<MessageBloc, MessageState>(
    'emits [loading, loaded] when messages are loaded successfully',
    build: () {
      when(() => mockGetMessages(any()))
          .thenAnswer((_) async => Right([testMessage]));
      return messageBloc;
    },
    act: (bloc) => bloc.add(MessageEvent.loadMessages(chatId: 'chat-123')),
    expect: () => [
      MessageState.loading(),
      MessageState.loaded(
        messages: [testMessage],
        chatId: 'chat-123',
        hasMore: false,
      ),
    ],
    verify: (_) {
      verify(() => mockGetMessages(any())).called(1);
    },
  );
  
  blocTest<MessageBloc, MessageState>(
    'handles optimistic updates correctly',
    build: () => messageBloc,
    seed: () => MessageState.loaded(
      messages: [],
      chatId: 'chat-123',
    ),
    act: (bloc) {
      when(() => mockSendMessage(any()))
          .thenAnswer((_) async => Right(testMessage));
      bloc.add(MessageEvent.sendMessage(
        chatId: 'chat-123',
        content: 'Hello',
        type: MessageType.text,
      ));
    },
    expect: () => [
      // Optimistic update
      MessageState.loaded(
        messages: [isA<ChatMessage>()],
        chatId: 'chat-123',
      ),
      // Real message update
      MessageState.loaded(
        messages: [testMessage],
        chatId: 'chat-123',
      ),
    ],
  );
});
```
