# Quản lý State với BLoC Pattern

Tài liệu này mô tả chi tiết về cách ứng dụng chat sử dụng BLoC Pattern (Business Logic Component) để quản lý state trong toàn bộ ứng dụng. BLoC là một pattern giúp tách biệt logic nghiệp vụ ra khỏi UI, làm cho code dễ bảo trì, test và mở rộng hơn.

## Kiến trúc BLoC

### Nguyên tắc cơ bản

BLoC pattern tuân theo các nguyên tắc chính:

1. **Inputs → BLoC → Outputs**: BLoC nhận inputs (events), xử lý chúng và phát ra outputs (states)
2. **Dependencies point inwards**: BLoC không phụ thuộc vào UI, UI phụ thuộc vào BLoC
3. **Single Responsibility**: Mỗi BLoC chịu trách nhiệm cho một tính năng cụ thể
4. **Unidirectional Data Flow**: Luồng dữ liệu một chiều, dễ dàng theo dõi và debug

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│             │    │             │    │             │
│     UI      │───▶│    BLoC     │───▶│   Domain    │
│  (Flutter)  │    │  (Business  │    │  (Entities) │
│             │◀───│   Logic)    │◀───│             │
└─────────────┘    └─────────────┘    └─────────────┘
                          │                  ▲
                          │                  │
                          ▼                  │
                   ┌─────────────┐          │
                   │             │          │
                   │    Data     │──────────┘
                   │  (Repos)    │
                   │             │
                   └─────────────┘
```

### Các thành phần chính

#### 1. Events 

Events là inputs gửi đến BLoC, thường là các hành động của người dùng hoặc system events.

```dart
@immutable
abstract class ChatEvent {
  const ChatEvent();
}

class LoadChats extends ChatEvent {
  const LoadChats();
}

class SendMessage extends ChatEvent {
  final String chatId;
  final String content;
  final MessageType type;

  const SendMessage({
    required this.chatId,
    required this.content,
    required this.type,
  });
}

class MarkMessageAsRead extends ChatEvent {
  final String messageId;
  
  const MarkMessageAsRead(this.messageId);
}
```

#### 2. States

States là outputs của BLoC, đại diện cho trạng thái của UI.

```dart
@immutable
abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatsLoaded extends ChatState {
  final List<Chat> chats;
  
  const ChatsLoaded(this.chats);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatsLoaded &&
          runtimeType == other.runtimeType &&
          listEquals(chats, other.chats);

  @override
  int get hashCode => chats.hashCode;
}

class MessageSent extends ChatState {
  final Message message;
  
  const MessageSent(this.message);
}

class ChatError extends ChatState {
  final String message;
  
  const ChatError(this.message);
}
```

#### 3. BLoC

BLoC xử lý events và phát ra states tương ứng. BLoC sử dụng repositories để lấy và lưu trữ dữ liệu.

```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final MessageRepository messageRepository;
  
  ChatBloc({
    required this.chatRepository,
    required this.messageRepository,
  }) : super(const ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<SendMessage>(_onSendMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
  }
  
  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    try {
      final chats = await chatRepository.getChats();
      emit(ChatsLoaded(chats));
    } catch (e) {
      emit(ChatError('Failed to load chats: ${e.toString()}'));
    }
  }
  
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await messageRepository.sendMessage(
        chatId: event.chatId,
        content: event.content,
        type: event.type,
      );
      emit(MessageSent(message));
    } catch (e) {
      emit(ChatError('Failed to send message: ${e.toString()}'));
    }
  }
  
  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await messageRepository.markAsRead(event.messageId);
    } catch (e) {
      emit(ChatError('Failed to mark message as read: ${e.toString()}'));
    }
  }
}
```

## Cấu trúc BLoC trong ứng dụng Chat

### BLoC Organization

Ứng dụng chat tổ chức các BLoC theo tính năng:

```
lib/
├── presentation/
│   ├── blocs/
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── chat/
│   │   │   ├── chat_bloc.dart
│   │   │   ├── chat_event.dart
│   │   │   └── chat_state.dart
│   │   ├── message/
│   │   │   ├── message_bloc.dart
│   │   │   ├── message_event.dart
│   │   │   └── message_state.dart
│   │   └── user/
│   │       ├── user_bloc.dart
│   │       ├── user_event.dart
│   │       └── user_state.dart
```

### Provider và BLoC Access

Chúng tôi sử dụng `flutter_bloc` và `get_it` để cung cấp và truy cập các BLoC trong ứng dụng:

```dart
void setupBlocs() {
  // Register repositories
  GetIt.instance.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authService: GetIt.instance<AuthService>(),
      userDao: GetIt.instance<UserDao>(),
    ),
  );
  
  GetIt.instance.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      chatService: GetIt.instance<ChatService>(),
      chatDao: GetIt.instance<ChatDao>(),
    ),
  );
  
  GetIt.instance.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      messageService: GetIt.instance<MessageService>(),
      messageDao: GetIt.instance<MessageDao>(),
      messageQueueService: GetIt.instance<MessageQueueService>(),
    ),
  );
  
  // Register BLoCs
  GetIt.instance.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: GetIt.instance<AuthRepository>(),
    ),
  );
  
  GetIt.instance.registerFactory<ChatBloc>(
    () => ChatBloc(
      chatRepository: GetIt.instance<ChatRepository>(),
      messageRepository: GetIt.instance<MessageRepository>(),
    ),
  );
  
  GetIt.instance.registerFactory<MessageBloc>(
    () => MessageBloc(
      messageRepository: GetIt.instance<MessageRepository>(),
    ),
  );
  
  GetIt.instance.registerFactory<UserBloc>(
    () => UserBloc(
      userRepository: GetIt.instance<UserRepository>(),
    ),
  );
}

// Trong main.dart
void main() {
  setupDependencies();
  setupBlocs();
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => GetIt.instance<AuthBloc>(),
        ),
        BlocProvider<UserBloc>(
          create: (context) => GetIt.instance<UserBloc>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Screen-level vs. Global BLoCs

- **Global BLoCs**: Được cung cấp ở mức ứng dụng, quản lý state trong toàn bộ ứng dụng (ví dụ: `AuthBloc`, `UserBloc`)
- **Screen-level BLoCs**: Được cung cấp ở mức screen, quản lý state cho một màn hình cụ thể (ví dụ: `ChatDetailBloc`)

```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<ChatBloc>()..add(const LoadChats()),
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ChatsLoaded) {
            return ListView.builder(
              itemCount: state.chats.length,
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                return ChatListItem(
                  chat: chat,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => GetIt.instance<MessageBloc>()
                            ..add(LoadMessages(chatId: chat.id)),
                          child: ChatDetailScreen(chat: chat),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is ChatError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

## Tối ưu hiệu suất

### Selective Rebuilds

Để tối ưu hiệu suất, chúng tôi sử dụng `BlocSelector` để chỉ rebuild UI khi các phần cụ thể của state thay đổi:

```dart
BlocSelector<MessageBloc, MessageState, List<Message>>(
  selector: (state) {
    if (state is MessagesLoaded) {
      return state.messages;
    }
    return [];
  },
  builder: (context, messages) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  },
)
```

### Hiệu suất với danh sách dài

Đối với danh sách tin nhắn dài, chúng tôi sử dụng:

- `ListView.builder` thay vì `ListView` để lazy-load items
- `DeviceCapabilityService` để điều chỉnh số lượng tin nhắn tải vào bộ nhớ dựa trên khả năng của thiết bị
- `const` constructors cho widgets không thay đổi

```dart
@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository _messageRepository;
  final DeviceCapabilityService _deviceCapabilityService;
  
  MessageBloc({
    required MessageRepository messageRepository,
    required DeviceCapabilityService deviceCapabilityService,
  }) : _messageRepository = messageRepository,
       _deviceCapabilityService = deviceCapabilityService,
       super(MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
  }
  
  Future<void> _onLoadMessages(
    LoadMessages event, 
    Emitter<MessageState> emit
  ) async {
    emit(MessagesLoading());
    
    try {
      // Điều chỉnh số lượng tin nhắn dựa trên khả năng thiết bị
      final deviceTier = _deviceCapabilityService.deviceTier;
      final limit = deviceTier == DeviceTier.low ? 50 : 
                   deviceTier == DeviceTier.medium ? 100 : 200;
      
      final messages = await _messageRepository.getMessages(
        chatId: event.chatId,
        limit: limit,
      );
      
      emit(MessagesLoaded(messages));
    } catch (e) {
      emit(MessageError('Không thể tải tin nhắn: ${e.toString()}'));
    }
  }
}
```

### Stream Transformers for Debouncing

Chúng tôi sử dụng stream transformers để debounce events như typing notifications:

```dart
class TypingBloc extends Bloc<TypingEvent, TypingState> {
  final TypingRepository _typingRepository;
  
  static EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) {
      return events.debounceTime(duration).flatMap(mapper);
    };
  }
  
  TypingBloc({
    required TypingRepository typingRepository,
  }) : _typingRepository = typingRepository,
       super(const TypingState()) {
    on<SendTypingNotification>(
      _onSendTypingNotification,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }
  
  Future<void> _onSendTypingNotification(
    SendTypingNotification event,
    Emitter<TypingState> emit,
  ) async {
    try {
      await _typingRepository.sendTypingNotification(
        chatId: event.chatId,
        isTyping: event.isTyping,
      );
    } catch (_) {
      // Ignore typing errors
    }
  }
}
```

## Error Handling

### Tổng quan về Error Handling

Chúng tôi xử lý lỗi bằng cách bắt exceptions trong BLoC handlers và phát ra error states:

```dart
Future<void> _onLoadChats(
  LoadChats event,
  Emitter<ChatState> emit,
) async {
  emit(const ChatLoading());
  try {
    final chats = await chatRepository.getChats();
    emit(ChatsLoaded(chats));
  } on NetworkException catch (e) {
    emit(ChatError('Không thể kết nối đến server: ${e.message}'));
  } on DatabaseException catch (e) {
    emit(ChatError('Lỗi cơ sở dữ liệu: ${e.message}'));
  } catch (e) {
    emit(ChatError('Lỗi không xác định: ${e.toString()}'));
  }
}
```

### Offline Error Recovery

Khi thiết bị offline, chúng tôi sử dụng các chiến lược để recover:

```dart
Future<void> _onSendMessage(
  SendMessage event,
  Emitter<ChatState> emit,
) async {
  final connectivityService = GetIt.instance<ConnectivityService>();
  final messageQueueService = GetIt.instance<MessageQueueService>();
  
  final temporaryMessage = Message(
    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
    chatId: event.chatId,
    senderId: GetIt.instance<AuthRepository>().currentUser?.id ?? '',
    content: event.content,
    type: event.type,
    status: MessageStatus.sending,
    createdAt: DateTime.now(),
  );
  
  emit(MessageSending(temporaryMessage));
  
  try {
    if (await connectivityService.isConnected) {
      final message = await messageRepository.sendMessage(
        chatId: event.chatId,
        content: event.content,
        type: event.type,
      );
      emit(MessageSent(message));
    } else {
      // Thiết bị offline, thêm vào queue
      await messageQueueService.enqueueMessage(
        chatId: event.chatId,
        content: event.content,
        type: event.type,
      );
      
      // Cập nhật UI với trạng thái pending
      final pendingMessage = temporaryMessage.copyWith(
        status: MessageStatus.pending,
      );
      emit(MessageQueued(pendingMessage));
    }
  } catch (e) {
    // Lưu vào local DB để thử lại sau
    await messageQueueService.enqueueMessage(
      chatId: event.chatId,
      content: event.content,
      type: event.type,
      error: e.toString(),
    );
    
    // Cập nhật UI với trạng thái lỗi
    final errorMessage = temporaryMessage.copyWith(
      status: MessageStatus.error,
    );
    emit(MessageError('Không thể gửi tin nhắn', errorMessage));
  }
}
```

## BLoC Testing

### Unit Tests

BLoC pattern làm cho việc unit testing trở nên dễ dàng nhờ tính cách ly:

```dart
void main() {
  late ChatBloc chatBloc;
  late MockChatRepository mockChatRepository;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockMessageRepository = MockMessageRepository();
    chatBloc = ChatBloc(
      chatRepository: mockChatRepository,
      messageRepository: mockMessageRepository,
    );
  });

  tearDown(() {
    chatBloc.close();
  });

  group('ChatBloc', () {
    test('initial state should be ChatInitial', () {
      expect(chatBloc.state, equals(const ChatInitial()));
    });

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatsLoaded] when LoadChats is added',
      build: () {
        when(() => mockChatRepository.getChats())
            .thenAnswer((_) async => [mockChat]);
        return chatBloc;
      },
      act: (bloc) => bloc.add(const LoadChats()),
      expect: () => [
        const ChatLoading(),
        ChatsLoaded([mockChat]),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatError] when LoadChats throws exception',
      build: () {
        when(() => mockChatRepository.getChats())
            .thenThrow(Exception('Network error'));
        return chatBloc;
      },
      act: (bloc) => bloc.add(const LoadChats()),
      expect: () => [
        const ChatLoading(),
        predicate<ChatState>((state) => 
          state is ChatError && 
          state.message.contains('Network error')
        ),
      ],
    );
  });
}
```

### Widget Tests

```dart
void main() {
  testWidgets('ChatScreen shows chats when loaded', (WidgetTester tester) async {
    // Setup
    final mockChat = Chat(
      id: '1', 
      name: 'Test Chat',
      lastMessagePreview: 'Hello',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
    );
    
    final mockChatBloc = MockChatBloc();
    
    whenListen(
      mockChatBloc,
      Stream.fromIterable([
        const ChatLoading(),
        ChatsLoaded([mockChat]),
      ]),
      initialState: const ChatInitial(),
    );
    
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: const ChatScreen(),
        ),
      ),
    );
    
    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Pump for state change
    await tester.pump();
    
    // Verify chats are displayed
    expect(find.text('Test Chat'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
```

## Best Practices

### BLoC Naming Conventions

```
feature_bloc.dart
feature_event.dart
feature_state.dart
```

### Naming Events và States

- Events: Động từ (ví dụ: `LoadChats`, `SendMessage`)
- States: Trạng thái (ví dụ: `ChatsLoaded`, `MessageSent`)

### Avoid Mixing Data và Presentation Logic

```dart
// Tốt: State chỉ chứa dữ liệu
class MessagesLoaded extends MessageState {
  final List<Message> messages;
  
  const MessagesLoaded(this.messages);
}

// Không tốt: State chứa logic hiển thị
class MessagesLoaded extends MessageState {
  final List<Message> messages;
  final bool shouldScrollToBottom; // Không nên có
  
  const MessagesLoaded(this.messages, {this.shouldScrollToBottom = false});
}
```

### State Immutability

Luôn đảm bảo states là immutable bằng:
- Sử dụng `const` constructors
- Sử dụng `final` fields
- Implement `==` và `hashCode` cho so sánh chính xác

```dart
class UserState extends Equatable {
  final User? user;
  final bool isLoading;
  final String? error;

  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [user, isLoading, error];

  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

### Đảm bảo không quá nhiều states

Tránh phát quá nhiều states trong khoảng thời gian ngắn.

```dart
// Không tốt: Nhiều states liên tiếp
emit(MessagesLoading());
emit(MessagesLengthUpdated(10));
emit(MessagesLoaded(messages));

// Tốt: Kết hợp states
final messages = await _messageRepository.getMessages(chatId);
emit(MessagesLoaded(messages));
```

## Ví dụ hoàn chỉnh

### Authentication BLoC

```dart
// auth_event.dart
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class Login extends AuthEvent {
  final String email;
  final String password;
  
  const Login({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
}

class Logout extends AuthEvent {
  const Logout();
}

// auth_state.dart
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;
  
  const Authenticated(this.user);
  
  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object> get props => [message];
}

// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  AuthBloc({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository,
       super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<Login>(_onLogin);
    on<Logout>(_onLogout);
  }
  
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onLogin(
    Login event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onLogout(
    Logout event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
```

### Sử dụng AuthBloc trong UI

```dart
class LoginScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Login')),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                                  Login(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  ),
                                );
                          },
                    child: state is AuthLoading
                        ? CircularProgressIndicator()
                        : Text('Login'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## Tham khảo

- [flutter_bloc documentation](https://bloclibrary.dev/)
- [Effective BLoC pattern](https://verygood.ventures/blog/effective-bloc-pattern)
- [BLoC Design Pattern](https://medium.com/flutterpub/architecting-your-flutter-project-bd04e144a8f1)
- [BLoC vs Cubit](https://bloclibrary.dev/#/coreconcepts?id=cubit) 