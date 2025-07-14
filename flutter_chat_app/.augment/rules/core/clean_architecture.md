---
type: "always_apply"
---

# Clean Architecture Rules - Flutter Chat App

**Type**: Always  
**Description**: Enforce Clean Architecture principles with proper layer separation and dependency flow for enterprise messaging app

## Architecture Overview

### Layer Structure
```
lib/
├── domain/           # Business logic layer (pure Dart)
│   ├── entities/     # Core business objects
│   ├── repositories/ # Abstract interfaces
│   └── usecases/     # Business operations
├── data/            # Data access layer
│   ├── models/      # Data transfer objects
│   ├── repositories/# Repository implementations
│   └── datasources/ # Local/Remote data sources
└── presentation/    # UI layer
    ├── blocs/       # State management
    ├── screens/     # UI screens
    └── widgets/     # Reusable UI components
```

### Dependency Rules
- **Domain layer**: No dependencies on other layers
- **Data layer**: Can depend on domain layer only
- **Presentation layer**: Can depend on domain and data layers
- **Dependency flow**: Presentation → Domain ← Data

## Implementation Standards

### Domain Layer Rules
```dart
// ✅ Correct: Pure business entity
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String chatId,
    required String content,
    required MessageType type,
    required User sender,
    required DateTime createdAt,
    @Default([]) List<String> readBy,
  }) = _ChatMessage;
}

// ❌ Wrong: Domain entity with UI dependencies
class ChatMessage {
  final Color backgroundColor; // UI concern in domain
  final Widget avatar;         // Flutter dependency
}
```

### Repository Pattern
```dart
// Domain layer - Abstract repository
abstract class MessageRepository {
  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId);
  Future<Either<Failure, ChatMessage>> sendMessage(SendMessageParams params);
  Stream<ChatMessage> watchNewMessages(String chatId);
}

// Data layer - Implementation
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;
  final MessageLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  // Implementation with proper error handling
}
```

### Use Case Pattern
```dart
// Domain layer - Business operation
class SendMessageUseCase {
  final MessageRepository repository;
  final UserRepository userRepository;
  
  SendMessageUseCase({
    required this.repository,
    required this.userRepository,
  });
  
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    // Validate business rules
    if (params.content.trim().isEmpty) {
      return Left(ValidationFailure('Message cannot be empty'));
    }
    
    // Execute business logic
    return await repository.sendMessage(params);
  }
}
```

## API Integration Mapping

### Backend to Flutter Model Mapping
```dart
// Backend: OfficeChatMessage → Flutter: ChatMessage
class MessageMapper {
  static ChatMessage fromBackendModel(OfficeChatMessage backendMessage) {
    return ChatMessage(
      id: backendMessage.id,
      chatId: backendMessage.conversationId,
      content: backendMessage.message ?? '',
      type: _mapMessageType(backendMessage.type),
      sender: UserMapper.fromBackendModel(backendMessage.sender),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        backendMessage.createdAt.toInt() * 1000,
      ),
      readBy: backendMessage.readerIds ?? [],
    );
  }
  
  static MessageType _mapMessageType(ChatMessageType backendType) {
    switch (backendType) {
      case ChatMessageType.Text:
        return MessageType.text;
      case ChatMessageType.Image:
        return MessageType.image;
      case ChatMessageType.File:
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}
```

## Error Handling Strategy

### Failure Classes
```dart
@freezed
class Failure with _$Failure {
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.server(String message, int statusCode) = ServerFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.authentication(String message) = AuthFailure;
}
```

### Repository Error Handling
```dart
class MessageRepositoryImpl implements MessageRepository {
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteMessages = await remoteDataSource.getMessages(chatId);
        await localDataSource.cacheMessages(remoteMessages);
        return Right(remoteMessages.map((m) => m.toDomain()).toList());
      } else {
        final cachedMessages = await localDataSource.getCachedMessages(chatId);
        return Right(cachedMessages.map((m) => m.toDomain()).toList());
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: $e'));
    }
  }
}
```

## Performance Considerations

### Entity Optimization
- Keep domain entities lightweight and immutable
- Use value objects for validated primitives
- Avoid deep object hierarchies
- Implement proper equality and hashCode

### Repository Caching
```dart
class MessageRepositoryWithCache implements MessageRepository {
  final MessageRepository _repository;
  final CacheManager _cacheManager;
  
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId) async {
    // Check cache first
    final cachedResult = await _cacheManager.get<List<ChatMessage>>(
      'messages_$chatId',
    );
    
    if (cachedResult != null && !_shouldRefresh(chatId)) {
      return Right(cachedResult);
    }
    
    // Fetch from repository and cache
    final result = await _repository.getMessages(chatId);
    result.fold(
      (failure) => null,
      (messages) => _cacheManager.put('messages_$chatId', messages),
    );
    
    return result;
  }
}
```

## Testing Guidelines

### Domain Layer Testing
```dart
group('SendMessageUseCase', () {
  late SendMessageUseCase useCase;
  late MockMessageRepository mockRepository;
  
  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = SendMessageUseCase(repository: mockRepository);
  });
  
  test('should return ChatMessage when message is sent successfully', () async {
    // Arrange
    final params = SendMessageParams(
      chatId: 'chat-123',
      content: 'Hello world',
      senderId: 'user-456',
    );
    final expectedMessage = ChatMessage(/* ... */);
    
    when(() => mockRepository.sendMessage(params))
        .thenAnswer((_) async => Right(expectedMessage));
    
    // Act
    final result = await useCase(params);
    
    // Assert
    expect(result, Right(expectedMessage));
    verify(() => mockRepository.sendMessage(params)).called(1);
  });
});
```

## Migration Strategy

### From Current Implementation
1. **Audit existing code** for architecture violations
2. **Create domain entities** from existing models
3. **Extract business logic** into use cases
4. **Implement repository interfaces** in domain layer
5. **Refactor data layer** to implement interfaces
6. **Update presentation layer** to use use cases
7. **Add comprehensive tests** for each layer
