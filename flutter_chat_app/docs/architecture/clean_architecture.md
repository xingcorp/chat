# Kiến trúc Sạch (Clean Architecture) trong Ứng dụng Chat

Tài liệu này mô tả cách áp dụng Kiến trúc Sạch (Clean Architecture) trong ứng dụng chat để tạo ra một codebase có thể bảo trì, mở rộng và dễ test.

## Nguyên tắc cơ bản

Clean Architecture được áp dụng trong ứng dụng chat của chúng ta dựa trên các nguyên tắc chính:

1. **Phụ thuộc hướng vào trong (Dependencies point inward)**: Các lớp bên ngoài phụ thuộc vào các lớp bên trong, không bao giờ ngược lại
2. **Tách biệt mối quan tâm (Separation of concerns)**: Các lớp và modules chỉ tập trung vào một nhiệm vụ cụ thể
3. **Nguyên tắc đóng mở (Open-closed principle)**: Mở rộng chức năng mà không cần sửa đổi code hiện có
4. **Đảo ngược phụ thuộc (Dependency inversion)**: Phụ thuộc vào abstractions, không phụ thuộc vào các implementation cụ thể

## Cấu trúc dự án

Ứng dụng chat được chia thành các layer rõ ràng:

```
lib/
├── presentation/ (UI Layer)
│   ├── screens/
│   ├── widgets/
│   ├── blocs/
│   └── navigation/
├── domain/ (Domain Layer)
│   ├── entities/
│   ├── repositories/
│   ├── usecases/
│   └── value_objects/
├── data/ (Data Layer)
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   ├── repositories/
│   └── models/
└── core/ (Core Layer)
    ├── di/
    ├── errors/
    ├── utils/
    ├── services/
    └── constants/
```

## Các layer chính

### 1. Presentation Layer

Chịu trách nhiệm hiển thị UI và tương tác với người dùng.

```dart
// Ví dụ về một screen trong Presentation Layer
class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  
  const ChatDetailScreen({Key? key, required this.chatId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<ChatDetailBloc>()..add(LoadChatDetail(chatId)),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ChatDetailBloc, ChatDetailState>(
            buildWhen: (previous, current) => 
                previous.chat?.name != current.chat?.name,
            builder: (context, state) {
              return Text(state.chat?.name ?? 'Chat');
            },
          ),
        ),
        body: BlocBuilder<ChatDetailBloc, ChatDetailState>(
          builder: (context, state) {
            if (state.status == ChatDetailStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.status == ChatDetailStatus.loaded) {
              return MessageList(messages: state.messages);
            } else if (state.status == ChatDetailStatus.error) {
              return ErrorView(message: state.errorMessage);
            }
            return const SizedBox.shrink();
          },
        ),
        bottomSheet: MessageInput(
          onSend: (content) {
            context.read<ChatDetailBloc>().add(
              SendMessage(chatId: chatId, content: content),
            );
          },
        ),
      ),
    );
  }
}
```

### 2. Domain Layer

Chứa các business rules và logic nghiệp vụ. Layer này hoàn toàn độc lập với các framework và thư viện bên ngoài.

```dart
// Entity trong Domain Layer
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final List<Attachment> attachments;
  
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.attachments = const [],
  });
  
  // No dependencies on external frameworks or libraries
}

// Repository Interface trong Domain Layer
abstract class MessageRepository {
  Future<List<Message>> getMessagesByChatId(String chatId, {int limit = 50});
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    List<Attachment> attachments = const [],
  });
  Future<void> markAsRead(String messageId);
  Stream<List<Message>> watchMessages(String chatId);
}

// Usecase trong Domain Layer
class SendMessageUseCase {
  final MessageRepository _messageRepository;
  final ConnectivityRepository _connectivityRepository;
  
  SendMessageUseCase({
    required MessageRepository messageRepository,
    required ConnectivityRepository connectivityRepository,
  }) : _messageRepository = messageRepository,
       _connectivityRepository = connectivityRepository;
  
  Future<SendMessageResult> execute({
    required String chatId,
    required String content,
    required MessageType type,
    List<Attachment> attachments = const [],
  }) async {
    if (content.trim().isEmpty && attachments.isEmpty) {
      return SendMessageResult.error('Message cannot be empty');
    }
    
    try {
      final isConnected = await _connectivityRepository.isConnected();
      
      if (isConnected) {
        final message = await _messageRepository.sendMessage(
          chatId: chatId,
          content: content,
          type: type,
          attachments: attachments,
        );
        return SendMessageResult.success(message);
      } else {
        // Offline logic
        final pendingMessage = await _messageRepository.queueMessageForLaterSending(
          chatId: chatId,
          content: content,
          type: type,
          attachments: attachments,
        );
        return SendMessageResult.pending(pendingMessage);
      }
    } catch (e) {
      return SendMessageResult.error(e.toString());
    }
  }
}
```

### 3. Data Layer

Cung cấp implementation cụ thể cho các repository interfaces được định nghĩa trong Domain Layer.

```dart
// Repository Implementation trong Data Layer
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  
  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required MessageLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;
  
  @override
  Future<List<Message>> getMessagesByChatId(String chatId, {int limit = 50}) async {
    try {
      if (await _networkInfo.isConnected) {
        final remoteMessages = await _remoteDataSource.getMessages(chatId, limit);
        await _localDataSource.cacheMessages(remoteMessages);
        return remoteMessages;
      } else {
        return await _localDataSource.getMessages(chatId, limit);
      }
    } on ServerException {
      return await _localDataSource.getMessages(chatId, limit);
    }
  }
  
  @override
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    List<Attachment> attachments = const [],
  }) async {
    final messageDto = MessageDto(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: await _localDataSource.getCurrentUserId(),
      content: content,
      type: type.toString(),
      timestamp: DateTime.now().toIso8601String(),
      status: MessageStatus.sending.toString(),
      attachments: attachments.map((a) => a.toJson()).toList(),
    );
    
    if (await _networkInfo.isConnected) {
      try {
        final remoteSentMessage = await _remoteDataSource.sendMessage(messageDto);
        await _localDataSource.saveMessage(remoteSentMessage);
        return remoteSentMessage.toDomain();
      } on ServerException {
        final localMessage = await _localDataSource.saveMessage(messageDto);
        return localMessage.toDomain();
      }
    } else {
      final localMessage = await _localDataSource.saveMessage(messageDto);
      return localMessage.toDomain();
    }
  }
  
  @override
  Future<void> markAsRead(String messageId) async {
    await _localDataSource.markMessageAsRead(messageId);
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.markMessageAsRead(messageId);
      } catch (_) {
        // Queue for later sync
      }
    }
  }
  
  @override
  Stream<List<Message>> watchMessages(String chatId) {
    return _localDataSource.watchMessages(chatId).map(
      (messages) => messages.map((m) => m.toDomain()).toList(),
    );
  }
}
```

### 4. Core Layer

Chứa các thành phần chung được sử dụng xuyên suốt ứng dụng như dependency injection, error handling, và utilities.

```dart
// Dependency Injection trong Core Layer
@module
abstract class RepositoryModule {
  @singleton
  MessageRepository provideMessageRepository(
    MessageRemoteDataSource remoteDataSource,
    MessageLocalDataSource localDataSource,
    NetworkInfo networkInfo,
  ) => MessageRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );
  
  @singleton
  ChatRepository provideChatRepository(
    ChatRemoteDataSource remoteDataSource,
    ChatLocalDataSource localDataSource,
    NetworkInfo networkInfo,
  ) => ChatRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );
}

// Error handling trong Core Layer
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException({
    this.message = 'Server error occurred',
    this.statusCode,
  });
  
  @override
  String toString() => 'ServerException: $message (Code: $statusCode)';
}
```

## Luồng dữ liệu

Clean Architecture định nghĩa luồng dữ liệu một chiều:

```
UI > BLoC/ViewModel > Usecase > Repository > DataSource > API/Database
```

1. **User Action**: Người dùng tương tác với UI
2. **Presentation Layer** gọi method trong Domain Layer (thông qua UseCase hoặc trực tiếp qua Repository)
3. **Domain Layer** xử lý business logic và gọi Repository
4. **Data Layer** truy xuất hoặc lưu dữ liệu từ các DataSource
5. **Data Layer** chuyển đổi dữ liệu từ DTO sang Domain Entity
6. **Domain Layer** trả kết quả về Presentation Layer
7. **Presentation Layer** cập nhật UI

## Dependency Injection

Sử dụng GetIt để cung cấp dependencies trong ứng dụng:

```dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Core
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectionChecker: DataConnectionChecker())
  );
  
  // Data sources
  getIt.registerLazySingleton<MessageLocalDataSource>(
    () => MessageLocalDataSourceImpl(
      database: getIt<AppDatabase>(),
      sharedPreferences: getIt<SharedPreferences>(),
    )
  );
  
  getIt.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(
      client: getIt<GraphQLClient>(),
      tokenProvider: getIt<TokenProvider>(),
    )
  );
  
  // Repositories
  getIt.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      remoteDataSource: getIt<MessageRemoteDataSource>(),
      localDataSource: getIt<MessageLocalDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    )
  );
  
  // Use cases
  getIt.registerLazySingleton(
    () => GetMessagesUseCase(repository: getIt<MessageRepository>())
  );
  
  getIt.registerLazySingleton(
    () => SendMessageUseCase(
      messageRepository: getIt<MessageRepository>(),
      connectivityRepository: getIt<ConnectivityRepository>(),
    )
  );
  
  // BLoCs
  getIt.registerFactory(
    () => ChatDetailBloc(
      getMessages: getIt<GetMessagesUseCase>(),
      sendMessage: getIt<SendMessageUseCase>(),
      watchMessages: getIt<WatchMessagesUseCase>(),
    )
  );
}
```

## Đảo ngược phụ thuộc (Dependency Inversion)

Ứng dụng chat sử dụng Repository Pattern để đảo ngược phụ thuộc giữa Domain Layer và Data Layer:

```dart
// Domain Layer định nghĩa interface
abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login({required String email, required String password});
  Future<void> logout();
  Future<User> register({required String email, required String password, required String name});
  Future<void> resetPassword(String email);
}

// Data Layer cung cấp implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  
  @override
  Future<User?> getCurrentUser() async {
    try {
      final userDto = await _localDataSource.getUser();
      if (userDto != null) {
        return userDto.toDomain();
      }
      return null;
    } on Exception {
      return null;
    }
  }
  
  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final userDto = await _remoteDataSource.login(email, password);
      await _localDataSource.saveUser(userDto);
      await _localDataSource.saveToken(userDto.token);
      return userDto.toDomain();
    } on ServerException catch (e) {
      throw AuthException(message: e.message);
    } on Exception catch (e) {
      throw AuthException(message: e.toString());
    }
  }
  
  // Các method khác...
}
```

## Lợi ích của Clean Architecture

1. **Khả năng test cao**: Mỗi layer có thể được test độc lập
2. **Dễ dàng thay đổi**: Backend API thay đổi? Chỉ cần sửa Data Layer
3. **Tách biệt UI và Logic**: UI có thể thay đổi mà không ảnh hưởng đến business logic
4. **Đơn giản hóa phụ thuộc**: Dependency Injection giúp quản lý phụ thuộc hiệu quả
5. **Mở rộng dễ dàng**: Thêm tính năng mới không ảnh hưởng đến code hiện có

## Các pattern đi kèm

Kết hợp Clean Architecture với các pattern khác để tăng hiệu quả:

1. **Repository Pattern**: Tách biệt logic truy xuất dữ liệu khỏi business logic
2. **BLoC Pattern**: Quản lý state và business logic ở Presentation Layer
3. **Use Case Pattern**: Đóng gói business logic thành các use case rõ ràng
4. **Factory Pattern**: Tạo objects mà không cần tiết lộ logic tạo
5. **Adapter Pattern**: Chuyển đổi giữa các interface khác nhau (ví dụ: DTO sang Entity)

## Testing Strategy

Clean Architecture giúp viết test dễ dàng hơn:

```dart
void main() {
  late SendMessageUseCase useCase;
  late MockMessageRepository messageRepository;
  late MockConnectivityRepository connectivityRepository;

  setUp(() {
    messageRepository = MockMessageRepository();
    connectivityRepository = MockConnectivityRepository();
    useCase = SendMessageUseCase(
      messageRepository: messageRepository,
      connectivityRepository: connectivityRepository,
    );
  });

  test('should send message successfully when online', () async {
    // Arrange
    const chatId = 'chat-123';
    const content = 'Hello';
    const type = MessageType.text;
    
    final message = Message(
      id: 'msg-1',
      chatId: chatId,
      senderId: 'user-1',
      content: content,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    
    when(() => connectivityRepository.isConnected())
        .thenAnswer((_) async => true);
    when(() => messageRepository.sendMessage(
      chatId: chatId,
      content: content,
      type: type,
      attachments: [],
    )).thenAnswer((_) async => message);

    // Act
    final result = await useCase.execute(
      chatId: chatId,
      content: content,
      type: type,
    );

    // Assert
    expect(result, isA<SendMessageResult>());
    expect(result.isSuccess, isTrue);
    expect(result.message, equals(message));
    
    verify(() => connectivityRepository.isConnected()).called(1);
    verify(() => messageRepository.sendMessage(
      chatId: chatId,
      content: content,
      type: type,
      attachments: [],
    )).called(1);
    verifyNoMoreInteractions(connectivityRepository);
    verifyNoMoreInteractions(messageRepository);
  });
}
```

## Checklist triển khai Clean Architecture

- [ ] Xác định các Entity trong Domain Layer
- [ ] Thiết kế Repository Interfaces trong Domain Layer
- [ ] Triển khai Use Cases cho các business logic
- [ ] Phát triển Repository Implementations trong Data Layer
- [ ] Xác định và triển khai DataSources (Remote và Local)
- [ ] Thiết lập Dependency Injection
- [ ] Triển khai Presentation Layer (UI và BLoCs)
- [ ] Viết Unit Tests cho từng layer
- [ ] Viết Integration Tests cho luồng dữ liệu giữa các layer

## Tham khảo

- [Clean Architecture by Robert C. Martin](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164)
- [Flutter Clean Architecture Sample](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)
- [Domain Driven Design by Eric Evans](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)
- [Clean Code by Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Flutter BLoC Library](https://bloclibrary.dev/) 