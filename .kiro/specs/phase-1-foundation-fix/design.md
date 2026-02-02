# Design Document: Phase 1 Foundation Fix

## Overview

This design addresses critical blockers preventing the Flutter chat app from functioning with the NestJS GraphQL backend. The app has excellent Clean Architecture structure but cannot operate due to four critical issues:

1. **GraphQL Operations Mismatch**: Current operations don't exist on backend
2. **UseCase Layer Empty**: Domain layer missing all business logic implementations
3. **Data Models Incomplete**: Missing critical fields from backend schema
4. **Repository Implementations Wrong**: Calling non-existent GraphQL operations

This foundation fix will align the Flutter app with the backend API, implement all required UseCases following Clean Architecture, complete data models, and correct repository implementations. This is a prerequisite for Phase 2 (chat-core-features).

**Timeline**: 2 weeks (10 working days)

**Success Criteria**:
- All 15 UseCases implemented and tested
- All GraphQL operations aligned with backend
- All data models complete with backend fields
- All repositories calling correct operations
- Code generation runs successfully
- App can communicate with backend without errors

## Architecture

### Clean Architecture Layers

The app follows strict Clean Architecture with three layers:

```
┌─────────────────────────────────────────┐
│  Presentation (BLoCs + UI)              │  ← User interaction
├─────────────────────────────────────────┤
│  Domain (Entities + UseCases)           │  ← Business logic
├─────────────────────────────────────────┤
│  Data (Models + Repositories + Sources) │  ← Data access
└─────────────────────────────────────────┘
```

**Data Flow**: `User Action → BLoC Event → UseCase → Repository → DataSource → GraphQL API`

### Layer Responsibilities

**Domain Layer** (`lib/domain/`):
- Entities: Pure business objects (Chat, Message, User, Reaction)
- UseCases: Business logic orchestration
- Repository Interfaces: Abstract data access contracts
- NO dependencies on Flutter, infrastructure, or data layer

**Data Layer** (`lib/data/`):
- Models: JSON serializable data transfer objects
- Repository Implementations: Concrete data access
- DataSources: GraphQL and Socket.IO communication
- Mappers: Convert between models and entities

**Presentation Layer** (`lib/presentation/`):
- BLoCs: State management (MUST extend BaseBloc)
- Pages: Screen components (MUST extend BaseStatefulWidget/BaseStatelessWidget)
- Widgets: Reusable UI components
- Uses domain entities and UseCases only


## Components and Interfaces

### 1. UseCase Layer (Domain)

All UseCases follow the same pattern:

```dart
@injectable
class GetConversationsUseCase {
  final IChatRepository _repository;
  final Logger _logger;
  
  GetConversationsUseCase({
    required IChatRepository repository,
    required Logger logger,
  }) : _repository = repository, _logger = logger;
  
  Future<Either<Failure, List<Chat>>> call({
    int? limit,
    int? offset,
  }) async {
    _logger.i('GetConversationsUseCase: Fetching conversations');
    
    final result = await _repository.getConversations(
      limit: limit,
      offset: offset,
    );
    
    return result.fold(
      (failure) {
        _logger.e('GetConversationsUseCase: Failed', error: failure);
        return Left(failure);
      },
      (conversations) {
        _logger.i('GetConversationsUseCase: Success - ${conversations.length} conversations');
        return Right(conversations);
      },
    );
  }
}
```

**Chat UseCases** (7 total):
- `GetConversationsUseCase`: Fetch conversation list
- `GetConversationDetailUseCase`: Fetch single conversation with details
- `CreateGroupUseCase`: Create new group conversation
- `EditGroupUseCase`: Update group name, avatar, description
- `LeaveConversationUseCase`: Leave a conversation
- `DeleteConversationUseCase`: Delete conversation history
- `SearchConversationsUseCase`: Search conversations by query

**Message UseCases** (8 total):
- `GetMessagesUseCase`: Fetch messages for a conversation
- `SendMessageUseCase`: Send new message
- `EditMessageUseCase`: Edit existing message
- `DeleteMessageUseCase`: Delete message
- `MarkAsReadUseCase`: Mark messages as read
- `AddReactionUseCase`: Add emoji reaction to message
- `RemoveReactionUseCase`: Remove emoji reaction from message
- `SearchMessagesUseCase`: Search messages by query

### 2. Repository Interfaces (Domain)

```dart
abstract class IChatRepository {
  Future<Either<Failure, List<Chat>>> getConversations({
    int? limit,
    int? offset,
  });
  
  Future<Either<Failure, Chat>> getConversationDetail(String conversationId);
  
  Future<Either<Failure, Chat>> createGroup({
    required String name,
    required List<String> memberIds,
    String? avatar,
    String? description,
  });
  
  Future<Either<Failure, Chat>> editGroup({
    required String conversationId,
    String? name,
    String? avatar,
    String? description,
  });
  
  Future<Either<Failure, void>> leaveConversation(String conversationId);
  
  Future<Either<Failure, void>> deleteConversation(String conversationId);
  
  Future<Either<Failure, List<Chat>>> searchConversations(String query);
}

abstract class IMessageRepository {
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    int? limit,
    int? offset,
  });
  
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String content,
    String? type,
    List<String>? urls,
    String? fileName,
  });
  
  Future<Either<Failure, Message>> editMessage({
    required String messageId,
    required String content,
  });
  
  Future<Either<Failure, void>> deleteMessage(String messageId);
  
  Future<Either<Failure, void>> markAsRead({
    required String conversationId,
    required List<String> messageIds,
  });
  
  Future<Either<Failure, Message>> addReaction({
    required String messageId,
    required String emoji,
  });
  
  Future<Either<Failure, Message>> removeReaction({
    required String messageId,
    required String emoji,
  });
  
  Future<Either<Failure, List<Message>>> searchMessages(String query);
}
```

### 3. Data Models (Data Layer)

**ChatModel** (complete with all backend fields):

```dart
@freezed
class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String id,
    required String name,
    String? avatar,
    String? description,
    String? groupType,
    UserModel? creator,
    @Default([]) List<UserModel> members,
    MessageModel? lastMessage,
    @Default(0) int unreadCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChatModel;
  
  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);
  
  const ChatModel._();
  
  Chat toEntity() => Chat(
    id: id,
    name: name,
    avatar: avatar,
    description: description,
    groupType: groupType,
    creator: creator?.toEntity(),
    members: members.map((m) => m.toEntity()).toList(),
    lastMessage: lastMessage?.toEntity(),
    unreadCount: unreadCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
  
  factory ChatModel.fromEntity(Chat entity) => ChatModel(
    id: entity.id,
    name: entity.name,
    avatar: entity.avatar,
    description: entity.description,
    groupType: entity.groupType,
    creator: entity.creator != null ? UserModel.fromEntity(entity.creator!) : null,
    members: entity.members.map((m) => UserModel.fromEntity(m)).toList(),
    lastMessage: entity.lastMessage != null 
        ? MessageModel.fromEntity(entity.lastMessage!) 
        : null,
    unreadCount: entity.unreadCount,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}
```

**MessageModel** (complete with all backend fields):

```dart
@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    @Default('text') String type,
    @Default([]) List<String> urls,
    String? fileName,
    @Default([]) List<ReactionModel> reactions,
    @Default(false) bool isRead,
    DateTime? editAt,
    DateTime? deletedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MessageModel;
  
  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
  
  const MessageModel._();
  
  Message toEntity() => Message(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    content: content,
    type: type,
    urls: urls,
    fileName: fileName,
    reactions: reactions.map((r) => r.toEntity()).toList(),
    isRead: isRead,
    editAt: editAt,
    deletedAt: deletedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
  
  factory MessageModel.fromEntity(Message entity) => MessageModel(
    id: entity.id,
    conversationId: entity.conversationId,
    senderId: entity.senderId,
    content: entity.content,
    type: entity.type,
    urls: entity.urls,
    fileName: entity.fileName,
    reactions: entity.reactions.map((r) => ReactionModel.fromEntity(r)).toList(),
    isRead: entity.isRead,
    editAt: entity.editAt,
    deletedAt: entity.deletedAt,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}
```

**ReactionModel** (new model):

```dart
@freezed
class ReactionModel with _$ReactionModel {
  const factory ReactionModel({
    required String id,
    required String emoji,
    required String userId,
    required DateTime createdAt,
  }) = _ReactionModel;
  
  factory ReactionModel.fromJson(Map<String, dynamic> json) =>
      _$ReactionModelFromJson(json);
  
  const ReactionModel._();
  
  Reaction toEntity() => Reaction(
    id: id,
    emoji: emoji,
    userId: userId,
    createdAt: createdAt,
  );
  
  factory ReactionModel.fromEntity(Reaction entity) => ReactionModel(
    id: entity.id,
    emoji: entity.emoji,
    userId: entity.userId,
    createdAt: entity.createdAt,
  );
}
```

### 4. GraphQL Operations (Data Layer)

**Queries**:

```graphql
query ChatConversationList($limit: Int, $offset: Int) {
  chatConversationList(limit: $limit, offset: $offset) {
    id
    name
    avatar
    description
    groupType
    creator {
      id
      username
      displayName
      avatar
    }
    members {
      id
      username
      displayName
      avatar
    }
    lastMessage {
      id
      content
      senderId
      createdAt
    }
    unreadCount
    createdAt
    updatedAt
  }
}

query ChatConversationDetail($conversationId: ID!) {
  chatConversationDetail(conversationId: $conversationId) {
    id
    name
    avatar
    description
    groupType
    creator {
      id
      username
      displayName
      avatar
    }
    members {
      id
      username
      displayName
      avatar
    }
    lastMessage {
      id
      content
      senderId
      createdAt
    }
    unreadCount
    createdAt
    updatedAt
  }
}

query ChatMessageList($conversationId: ID!, $limit: Int, $offset: Int) {
  chatMessageList(conversationId: $conversationId, limit: $limit, offset: $offset) {
    id
    conversationId
    senderId
    content
    type
    urls
    fileName
    reactions {
      id
      emoji
      userId
      createdAt
    }
    isRead
    editAt
    deletedAt
    createdAt
    updatedAt
  }
}

query ChatSearch($query: String!, $type: SearchType!) {
  chatSearch(query: $query, type: $type) {
    ... on Conversation {
      id
      name
      avatar
      description
    }
    ... on Message {
      id
      content
      conversationId
      senderId
      createdAt
    }
  }
}
```

**Mutations**:

```graphql
mutation ChatMessageAdd($conversationId: ID!, $content: String!, $type: String, $urls: [String!], $fileName: String) {
  chatMessageAdd(conversationId: $conversationId, content: $content, type: $type, urls: $urls, fileName: $fileName) {
    id
    conversationId
    senderId
    content
    type
    urls
    fileName
    reactions {
      id
      emoji
      userId
      createdAt
    }
    isRead
    createdAt
    updatedAt
  }
}

mutation ChatGroupAdd($name: String!, $memberIds: [ID!]!, $avatar: String, $description: String) {
  chatGroupAdd(name: $name, memberIds: $memberIds, avatar: $avatar, description: $description) {
    id
    name
    avatar
    description
    groupType
    creator {
      id
      username
      displayName
      avatar
    }
    members {
      id
      username
      displayName
      avatar
    }
    createdAt
    updatedAt
  }
}

mutation ChatGroupEdit($conversationId: ID!, $name: String, $avatar: String, $description: String) {
  chatGroupEdit(conversationId: $conversationId, name: $name, avatar: $avatar, description: $description) {
    id
    name
    avatar
    description
    updatedAt
  }
}

mutation ChatConversationLeave($conversationId: ID!) {
  chatConversationLeave(conversationId: $conversationId)
}

mutation ChatConversationDelete($conversationId: ID!) {
  chatConversationDelete(conversationId: $conversationId)
}

mutation ChatMessageEdit($messageId: ID!, $content: String!) {
  chatMessageEdit(messageId: $messageId, content: $content) {
    id
    content
    editAt
    updatedAt
  }
}

mutation ChatMessageDeleteHistory($messageId: ID!) {
  chatMessageDeleteHistory(messageId: $messageId)
}

mutation ChatMessageUpdateRead($conversationId: ID!, $messageIds: [ID!]!) {
  chatMessageUpdateRead(conversationId: $conversationId, messageIds: $messageIds)
}

mutation ChatMessageUpdateReaction($messageId: ID!, $emoji: String!, $action: ReactionAction!) {
  chatMessageUpdateReaction(messageId: $messageId, emoji: $emoji, action: $action) {
    id
    reactions {
      id
      emoji
      userId
      createdAt
    }
    updatedAt
  }
}
```

### 5. Repository Implementations (Data Layer)

```dart
@LazySingleton(as: IChatRepository)
class ChatRepositoryImpl implements IChatRepository {
  final IChatRemoteDataSource _remoteDataSource;
  final INetworkInfo _networkInfo;
  final Logger _logger;
  
  ChatRepositoryImpl({
    required IChatRemoteDataSource remoteDataSource,
    required INetworkInfo networkInfo,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo,
       _logger = logger;
  
  @override
  Future<Either<Failure, List<Chat>>> getConversations({
    int? limit,
    int? offset,
  }) async {
    if (!await _networkInfo.isConnected) {
      _logger.w('ChatRepository: No network connection');
      return const Left(NetworkFailure());
    }
    
    try {
      _logger.i('ChatRepository: Fetching conversations');
      final models = await _remoteDataSource.getConversations(
        limit: limit,
        offset: offset,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      _logger.i('ChatRepository: Success - ${entities.length} conversations');
      return Right(entities);
    } on ServerException catch (e) {
      _logger.e('ChatRepository: Server error', error: e);
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _logger.e('ChatRepository: Unexpected error', error: e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
  
  // Similar implementation for other methods...
}
```

### 6. Remote Data Sources (Data Layer)

```dart
@LazySingleton(as: IChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements IChatRemoteDataSource {
  final GraphQLClient _client;
  final Logger _logger;
  
  ChatRemoteDataSourceImpl({
    required GraphQLClient client,
    required Logger logger,
  }) : _client = client, _logger = logger;
  
  @override
  Future<List<ChatModel>> getConversations({
    int? limit,
    int? offset,
  }) async {
    _logger.d('ChatRemoteDataSource: Executing chatConversationList query');
    
    final result = await _client.query(
      QueryOptions(
        document: gql(ChatQueries.conversationList),
        variables: {
          'limit': limit,
          'offset': offset,
        },
      ),
    );
    
    if (result.hasException) {
      _logger.e('ChatRemoteDataSource: Query failed', error: result.exception);
      throw ServerException(
        message: result.exception?.graphqlErrors.first.message ?? 'Unknown error',
      );
    }
    
    final data = result.data?['chatConversationList'] as List<dynamic>;
    return data.map((json) => ChatModel.fromJson(json)).toList();
  }
  
  // Similar implementation for other methods...
}
```

### 7. Socket.IO Event Handling

```dart
@singleton
class SocketService {
  final EnhancedSocketManager _socketManager;
  final Logger _logger;
  
  final _messageStreamController = StreamController<Message>.broadcast();
  final _reactionStreamController = StreamController<MessageReaction>.broadcast();
  final _typingStreamController = StreamController<TypingEvent>.broadcast();
  
  Stream<Message> get messageStream => _messageStreamController.stream;
  Stream<MessageReaction> get reactionStream => _reactionStreamController.stream;
  Stream<TypingEvent> get typingStream => _typingStreamController.stream;
  
  SocketService({
    required EnhancedSocketManager socketManager,
    required Logger logger,
  }) : _socketManager = socketManager,
       _logger = logger {
    _setupListeners();
  }
  
  void _setupListeners() {
    _socketManager.on('message:sent', (data) {
      _logger.d('Socket: message:sent event received');
      final message = MessageModel.fromJson(data).toEntity();
      _messageStreamController.add(message);
    });
    
    _socketManager.on('message:reaction', (data) {
      _logger.d('Socket: message:reaction event received');
      final reaction = MessageReaction.fromJson(data);
      _reactionStreamController.add(reaction);
    });
    
    _socketManager.on('message:typing', (data) {
      _logger.d('Socket: message:typing event received');
      final typing = TypingEvent.fromJson(data);
      _typingStreamController.add(typing);
    });
    
    // Additional event listeners...
  }
  
  void dispose() {
    _messageStreamController.close();
    _reactionStreamController.close();
    _typingStreamController.close();
  }
}
```


## Data Models

### Entity Layer (Domain)

**Chat Entity**:
```dart
class Chat extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final String? description;
  final String? groupType;
  final User? creator;
  final List<User> members;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Chat({
    required this.id,
    required this.name,
    this.avatar,
    this.description,
    this.groupType,
    this.creator,
    this.members = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });
  
  @override
  List<Object?> get props => [
    id, name, avatar, description, groupType, creator,
    members, lastMessage, unreadCount, createdAt, updatedAt,
  ];
}
```

**Message Entity**:
```dart
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type;
  final List<String> urls;
  final String? fileName;
  final List<Reaction> reactions;
  final bool isRead;
  final DateTime? editAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.urls = const [],
    this.fileName,
    this.reactions = const [],
    this.isRead = false,
    this.editAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  @override
  List<Object?> get props => [
    id, conversationId, senderId, content, type, urls,
    fileName, reactions, isRead, editAt, deletedAt,
    createdAt, updatedAt,
  ];
}
```

**Reaction Entity**:
```dart
class Reaction extends Equatable {
  final String id;
  final String emoji;
  final String userId;
  final DateTime createdAt;
  
  const Reaction({
    required this.id,
    required this.emoji,
    required this.userId,
    required this.createdAt,
  });
  
  @override
  List<Object> get props => [id, emoji, userId, createdAt];
}
```

### Model-Entity Mapping

All models implement bidirectional mapping:
- `toEntity()`: Convert model to domain entity
- `fromEntity()`: Create model from domain entity
- `fromJson()`: Deserialize from JSON
- `toJson()`: Serialize to JSON

This ensures clean separation between data layer (models) and domain layer (entities).


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: GraphQL Query Operations Use Correct Names

*For any* conversation query operation (list, detail, search), the GraphQL operation name used SHALL match the backend schema operation name (`chatConversationList`, `chatConversationDetail`, or `chatSearch`).

**Validates: Requirements 1.1, 1.2, 1.14**

### Property 2: GraphQL Mutation Operations Use Correct Names

*For any* mutation operation (message add/edit/delete, group add/edit, conversation leave/delete, reaction update, read update), the GraphQL operation name used SHALL match the backend schema operation name (`chatMessageAdd`, `chatMessageEdit`, `chatMessageDeleteHistory`, `chatGroupAdd`, `chatGroupEdit`, `chatConversationLeave`, `chatConversationDelete`, `chatMessageUpdateReaction`, `chatMessageUpdateRead`).

**Validates: Requirements 1.3, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11, 1.12, 1.13, 1.15**

### Property 3: All UseCases Return Either Type

*For any* UseCase implementation, calling the UseCase SHALL return a value of type `Either<Failure, T>` where T is the expected success type.

**Validates: Requirements 2.16**

### Property 4: UseCases Log Errors on Failure

*For any* UseCase that encounters an error, the UseCase SHALL call `logger.e()` with error details before returning the failure.

**Validates: Requirements 2.17**

### Property 5: UseCases Use Injectable Annotation

*For any* UseCase class, the class SHALL be annotated with `@injectable` for dependency injection registration.

**Validates: Requirements 2.18**

### Property 6: Model Serialization Round Trip

*For any* valid data model (ChatModel, MessageModel, ReactionModel, UserModel), serializing to JSON then deserializing from JSON SHALL produce an equivalent model object.

**Validates: Requirements 3.11, 3.12**

### Property 7: Model-Entity Conversion Round Trip

*For any* valid domain entity (Chat, Message, Reaction, User), converting to model then back to entity SHALL produce an equivalent entity object.

**Validates: Requirements 3.13, 3.14**

### Property 8: Repository Methods Check Network First

*For any* repository method call, the repository SHALL check network connectivity via `INetworkInfo.isConnected` before attempting remote data source operations.

**Validates: Requirements 4.16**

### Property 9: Repository Returns NetworkFailure When Offline

*For any* repository method call when network is unavailable, the repository SHALL return `Left(NetworkFailure())` without calling the remote data source.

**Validates: Requirements 4.17**

### Property 10: Repository Converts Exceptions to Failures

*For any* repository method that catches an exception, the repository SHALL convert the exception to an appropriate Failure type (ServerFailure, CacheFailure, ValidationFailure, or UnexpectedFailure) and return it wrapped in Left.

**Validates: Requirements 4.18**

### Property 11: Chat Repository Calls Correct Operations

*For any* chat repository method (getConversations, getConversationDetail, createGroup, editGroup, leaveConversation, deleteConversation, searchConversations), the repository SHALL call the corresponding remote data source method which invokes the correct GraphQL operation.

**Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7**

### Property 12: Message Repository Calls Correct Operations

*For any* message repository method (getMessages, sendMessage, editMessage, deleteMessage, markAsRead, addReaction, removeReaction, searchMessages), the repository SHALL call the corresponding remote data source method which invokes the correct GraphQL operation.

**Validates: Requirements 4.8, 4.9, 4.10, 4.11, 4.12, 4.13, 4.14, 4.15**

### Property 13: Socket Events Trigger Correct Handlers

*For any* Socket.IO event received (`message:sent`, `message:read`, `message:typing`, `message:reaction`, `message:edit`, `message:delete`, `conversation:joined`, `conversation:leaved`), the system SHALL invoke the corresponding event handler and update the appropriate stream.

**Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8**

### Property 14: Socket Events Are Logged

*For any* Socket.IO event received, the system SHALL log the event using `logger.d()` or `logger.i()` before processing.

**Validates: Requirements 5.9**

### Property 15: BLoCs Extend BaseBloc

*For any* BLoC class in the presentation layer, the class SHALL extend `BaseBloc<Event, State>` and NOT extend `Bloc` directly.

**Validates: Requirements 6.1**

### Property 16: States Extend BaseState

*For any* State class used with BLoCs, the class SHALL extend `BaseState` and be annotated with `@freezed`.

**Validates: Requirements 6.2**

### Property 17: Widgets Extend Base Widget Classes

*For any* StatefulWidget, the class SHALL extend `BaseStatefulWidget`, and for any StatelessWidget, the class SHALL extend `BaseStatelessWidget`.

**Validates: Requirements 6.3, 6.4**

### Property 18: No Print Statements

*For any* logging operation, the code SHALL use Logger service methods (`logger.i()`, `logger.e()`, `logger.w()`, `logger.d()`) and SHALL NOT use `print()` or `debugPrint()`.

**Validates: Requirements 6.5**

### Property 19: No Hardcoded Strings

*For any* user-facing text, the code SHALL use `context.l10n.keyName` and SHALL NOT use hardcoded string literals.

**Validates: Requirements 6.6**

### Property 20: Use AppConstants for Dimensions

*For any* UI dimension or duration value, the code SHALL use `AppConstants` constants and SHALL NOT use hardcoded numeric literals.

**Validates: Requirements 6.7, 6.8**

### Property 21: DI Annotations Present

*For any* injectable class (UseCase, Repository, DataSource, Service), the class SHALL be annotated with `@injectable`, `@singleton`, or `@lazySingleton`.

**Validates: Requirements 6.9, 8.1, 8.2, 8.3, 8.4**

### Property 22: Error Handling Uses Either

*For any* operation that can fail, the return type SHALL be `Either<Failure, T>` and the implementation SHALL handle errors by returning Left(failure).

**Validates: Requirements 6.10**

### Property 23: UseCases Log Operation Start and Result

*For any* UseCase execution, the UseCase SHALL log operation start using `logger.i()` and SHALL log the result (success or failure) before returning.

**Validates: Requirements 9.1, 9.2, 9.3**

### Property 24: Repositories Log Operations

*For any* repository method execution, the repository SHALL log the operation using Logger service.

**Validates: Requirements 9.4, 9.5**

### Property 25: User-Friendly Error Messages

*For any* error displayed to users, the error message SHALL come from `context.l10n` localization keys and SHALL NOT be raw exception messages.

**Validates: Requirements 9.8, 9.9, 9.10**


## Error Handling

### Error Flow Architecture

```
Exception (Data Layer) → Failure (Domain Layer) → User Message (Presentation Layer)
```

### Exception Types (Data Layer)

```dart
// lib/core/error/exceptions.dart

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  const ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException({this.message = 'No internet connection'});
}

class CacheException implements Exception {
  final String message;
  
  const CacheException({required this.message});
}

class ValidationException implements Exception {
  final String message;
  
  const ValidationException({required this.message});
}
```

### Failure Types (Domain Layer)

```dart
// lib/core/error/failures.dart

abstract class Failure extends Equatable {
  final String message;
  final String code;
  
  const Failure({required this.message, required this.code});
  
  @override
  List<Object> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String code = 'server_error',
  }) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'No internet connection',
    String code = 'network_error',
  }) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String code = 'cache_error',
  }) : super(message: message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String code = 'validation_error',
  }) : super(message: message, code: code);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required String message,
    String code = 'unexpected_error',
  }) : super(message: message, code: code);
}
```

### Error Handling Pattern

**Repository Layer**:
1. Check network connectivity first
2. Try remote data source operation
3. Catch exceptions and convert to failures
4. Log all errors
5. Return `Either<Failure, T>`

```dart
@override
Future<Either<Failure, Chat>> createGroup({
  required String name,
  required List<String> memberIds,
  String? avatar,
  String? description,
}) async {
  // Step 1: Check network
  if (!await _networkInfo.isConnected) {
    _logger.w('ChatRepository.createGroup: No network connection');
    return const Left(NetworkFailure());
  }
  
  try {
    // Step 2: Call remote data source
    _logger.i('ChatRepository.createGroup: Creating group "$name"');
    final model = await _remoteDataSource.createGroup(
      name: name,
      memberIds: memberIds,
      avatar: avatar,
      description: description,
    );
    
    // Step 3: Convert to entity and return success
    final entity = model.toEntity();
    _logger.i('ChatRepository.createGroup: Success - group ${entity.id}');
    return Right(entity);
  } on ServerException catch (e) {
    // Step 4: Convert exception to failure
    _logger.e('ChatRepository.createGroup: Server error', error: e);
    return Left(ServerFailure(message: e.message));
  } on ValidationException catch (e) {
    _logger.e('ChatRepository.createGroup: Validation error', error: e);
    return Left(ValidationFailure(message: e.message));
  } catch (e) {
    // Step 5: Handle unexpected errors
    _logger.e('ChatRepository.createGroup: Unexpected error', error: e);
    return Left(UnexpectedFailure(message: e.toString()));
  }
}
```

**UseCase Layer**:
1. Log operation start
2. Call repository
3. Handle result with fold
4. Log success or failure
5. Return result

```dart
Future<Either<Failure, Chat>> call({
  required String name,
  required List<String> memberIds,
  String? avatar,
  String? description,
}) async {
  _logger.i('CreateGroupUseCase: Creating group "$name" with ${memberIds.length} members');
  
  final result = await _repository.createGroup(
    name: name,
    memberIds: memberIds,
    avatar: avatar,
    description: description,
  );
  
  return result.fold(
    (failure) {
      _logger.e('CreateGroupUseCase: Failed', error: failure);
      return Left(failure);
    },
    (chat) {
      _logger.i('CreateGroupUseCase: Success - group ${chat.id}');
      return Right(chat);
    },
  );
}
```

**BLoC Layer**:
1. Emit loading state
2. Call UseCase
3. Handle result with fold
4. Emit success or error state
5. Use BaseBloc helper methods

```dart
Future<void> _onCreateGroup(
  ChatCreateGroupEvent event,
  Emitter<ChatState> emit,
) async {
  emitLoading(message: 'Creating group...');
  
  final result = await _createGroupUseCase(
    name: event.name,
    memberIds: event.memberIds,
    avatar: event.avatar,
    description: event.description,
  );
  
  result.fold(
    (failure) => emitError(
      failure.message,
      error: failure,
      retryAction: () => add(event),
    ),
    (chat) => emit(ChatState.groupCreated(chat: chat)),
  );
}
```

**UI Layer**:
1. Listen to BLoC state
2. Display user-friendly error messages
3. Provide retry actions
4. Use localized strings

```dart
BlocListener<ChatBloc, ChatState>(
  listener: (context, state) {
    state.whenOrNull(
      error: (message, error, retryAction) {
        final userMessage = _getUserFriendlyMessage(context, error);
        
        AppSnackBar.show(
          context,
          message: userMessage,
          type: SnackBarType.error,
          action: retryAction != null
              ? SnackBarAction(
                  label: context.l10n.retry,
                  onPressed: retryAction,
                )
              : null,
        );
      },
    );
  },
  child: const ChatPage(),
)

String _getUserFriendlyMessage(BuildContext context, Object? error) {
  if (error is NetworkFailure) {
    return context.l10n.errorNoInternet;
  } else if (error is ServerFailure) {
    return context.l10n.errorServer;
  } else if (error is ValidationFailure) {
    return error.message; // Already user-friendly
  } else {
    return context.l10n.errorUnexpected;
  }
}
```

### Logging Strategy

**Log Levels**:
- `logger.d()`: Debug information (development only)
- `logger.i()`: Informational messages (operation start/success)
- `logger.w()`: Warnings (network unavailable, deprecated usage)
- `logger.e()`: Errors (operation failures, exceptions)

**What to Log**:
- UseCase: Operation start, parameters, result
- Repository: Operation start, network status, result
- DataSource: GraphQL operation name, variables, response status
- BLoC: Event received, state transitions, errors
- Socket: Event received, connection status, errors

**What NOT to Log**:
- Sensitive data (passwords, tokens, personal information)
- Large payloads (use summary instead)
- Redundant information (already logged at lower layer)


## Testing Strategy

### Dual Testing Approach

This project uses both **unit tests** and **property-based tests** for comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs
- Both are complementary and necessary for comprehensive coverage

### Property-Based Testing Configuration

**Library**: Use `test` package with custom property test helpers (or `dart_check` if available)

**Configuration**:
- Minimum 100 iterations per property test
- Each property test references its design document property
- Tag format: `@Tags(['property-test', 'feature:phase-1-foundation-fix', 'property-N'])`

**Example Property Test**:

```dart
import 'package:test/test.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';

// Feature: phase-1-foundation-fix, Property 6: Model Serialization Round Trip
void main() {
  group('ChatModel Serialization', () {
    test('round trip serialization preserves data', () {
      // Run 100 iterations with different data
      for (var i = 0; i < 100; i++) {
        // Generate random chat model
        final original = _generateRandomChatModel(seed: i);
        
        // Serialize to JSON
        final json = original.toJson();
        
        // Deserialize from JSON
        final deserialized = ChatModel.fromJson(json);
        
        // Verify equivalence
        expect(deserialized, equals(original));
      }
    });
  });
}

ChatModel _generateRandomChatModel({required int seed}) {
  final random = Random(seed);
  return ChatModel(
    id: 'chat_${random.nextInt(1000)}',
    name: 'Chat ${random.nextInt(100)}',
    avatar: random.nextBool() ? 'https://example.com/avatar.jpg' : null,
    description: random.nextBool() ? 'Description ${random.nextInt(100)}' : null,
    groupType: random.nextBool() ? 'group' : 'direct',
    members: List.generate(
      random.nextInt(10) + 1,
      (i) => _generateRandomUserModel(seed: seed + i),
    ),
    unreadCount: random.nextInt(50),
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    updatedAt: DateTime.now(),
  );
}
```

### Unit Testing Patterns

**UseCase Tests**:

```dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockChatRepository extends Mock implements IChatRepository {}
class MockLogger extends Mock implements Logger {}

void main() {
  late GetConversationsUseCase useCase;
  late MockChatRepository mockRepository;
  late MockLogger mockLogger;
  
  setUp(() {
    mockRepository = MockChatRepository();
    mockLogger = MockLogger();
    useCase = GetConversationsUseCase(
      repository: mockRepository,
      logger: mockLogger,
    );
  });
  
  group('GetConversationsUseCase', () {
    test('should return conversations when repository succeeds', () async {
      // Arrange
      final conversations = [
        Chat(
          id: '1',
          name: 'Chat 1',
          members: [],
          unreadCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      when(() => mockRepository.getConversations(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(conversations));
      
      // Act
      final result = await useCase(limit: 20);
      
      // Assert
      expect(result, Right(conversations));
      verify(() => mockLogger.i(any())).called(2); // Start and success
      verify(() => mockRepository.getConversations(limit: 20)).called(1);
    });
    
    test('should return failure when repository fails', () async {
      // Arrange
      const failure = NetworkFailure();
      when(() => mockRepository.getConversations(limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(failure));
      
      // Act
      final result = await useCase(limit: 20);
      
      // Assert
      expect(result, const Left(failure));
      verify(() => mockLogger.e(any(), error: any(named: 'error'))).called(1);
    });
  });
}
```

**Repository Tests**:

```dart
void main() {
  late ChatRepositoryImpl repository;
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockLogger mockLogger;
  
  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockLogger = MockLogger();
    repository = ChatRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
      logger: mockLogger,
    );
  });
  
  group('ChatRepository.getConversations', () {
    test('should check network connectivity first', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getConversations(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      )).thenAnswer((_) async => []);
      
      // Act
      await repository.getConversations(limit: 20);
      
      // Assert
      verify(() => mockNetworkInfo.isConnected).called(1);
    });
    
    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      
      // Act
      final result = await repository.getConversations(limit: 20);
      
      // Assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.getConversations(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ));
    });
    
    test('should return conversations when remote source succeeds', () async {
      // Arrange
      final models = [
        ChatModel(
          id: '1',
          name: 'Chat 1',
          members: [],
          unreadCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getConversations(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      )).thenAnswer((_) async => models);
      
      // Act
      final result = await repository.getConversations(limit: 20);
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversations) {
          expect(conversations.length, 1);
          expect(conversations[0].id, '1');
        },
      );
    });
    
    test('should return ServerFailure when remote source throws ServerException', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getConversations(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      )).thenThrow(const ServerException(message: 'Server error'));
      
      // Act
      final result = await repository.getConversations(limit: 20);
      
      // Assert
      expect(result, const Left(ServerFailure(message: 'Server error')));
    });
  });
}
```

**BLoC Tests** (using bloc_test):

```dart
import 'package:bloc_test/bloc_test.dart';

void main() {
  late ChatBloc chatBloc;
  late MockGetConversationsUseCase mockGetConversationsUseCase;
  late MockLogger mockLogger;
  
  setUp(() {
    mockGetConversationsUseCase = MockGetConversationsUseCase();
    mockLogger = MockLogger();
    chatBloc = ChatBloc(
      getConversationsUseCase: mockGetConversationsUseCase,
      logger: mockLogger,
    );
  });
  
  tearDown(() {
    chatBloc.close();
  });
  
  group('ChatBloc', () {
    blocTest<ChatBloc, ChatState>(
      'emits [loading, loaded] when GetConversations succeeds',
      build: () {
        when(() => mockGetConversationsUseCase(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right([testChat]));
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatEvent.getConversations(limit: 20)),
      expect: () => [
        const ChatState.loading(message: 'Loading conversations...'),
        ChatState.loaded(conversations: [testChat]),
      ],
      verify: (_) {
        verify(() => mockGetConversationsUseCase(limit: 20)).called(1);
      },
    );
    
    blocTest<ChatBloc, ChatState>(
      'emits [loading, error] when GetConversations fails',
      build: () {
        when(() => mockGetConversationsUseCase(limit: any(named: 'limit')))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatEvent.getConversations(limit: 20)),
      expect: () => [
        const ChatState.loading(message: 'Loading conversations...'),
        isA<ChatError>()
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
      ],
    );
  });
}
```

### Test Coverage Goals

- **UseCase Layer**: 100% coverage (all methods, all branches)
- **Repository Layer**: 100% coverage (all methods, all error paths)
- **DataSource Layer**: 90%+ coverage (focus on error handling)
- **Model Layer**: 100% coverage (serialization, entity conversion)
- **BLoC Layer**: 90%+ coverage (all events, all state transitions)

### Integration Testing

**GraphQL Integration Tests**:
- Test actual GraphQL queries against mock server
- Verify request structure matches backend schema
- Verify response parsing works correctly

**Socket.IO Integration Tests**:
- Test socket connection and reconnection
- Test event emission and reception
- Test event handler invocation

### Test Organization

```
test/
├── unit/
│   ├── domain/
│   │   └── usecases/
│   │       ├── chat/
│   │       │   ├── get_conversations_usecase_test.dart
│   │       │   ├── create_group_usecase_test.dart
│   │       │   └── ...
│   │       └── message/
│   │           ├── send_message_usecase_test.dart
│   │           └── ...
│   ├── data/
│   │   ├── models/
│   │   │   ├── chat_model_test.dart
│   │   │   ├── message_model_test.dart
│   │   │   └── reaction_model_test.dart
│   │   └── repositories/
│   │       ├── chat_repository_impl_test.dart
│   │       └── message_repository_impl_test.dart
│   └── presentation/
│       └── blocs/
│           ├── chat_bloc_test.dart
│           └── message_bloc_test.dart
├── property/
│   ├── model_serialization_test.dart
│   ├── repository_error_handling_test.dart
│   └── usecase_logging_test.dart
└── integration/
    ├── graphql_operations_test.dart
    └── socket_events_test.dart
```

### Running Tests

```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/unit/

# Run property tests only
flutter test test/property/

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/domain/usecases/chat/get_conversations_usecase_test.dart
```

