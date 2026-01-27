# Design Document - Chat Foundation

## Overview

This document describes the technical design for Phase 1 (Chat Foundation) of the Sharitek Office Chat application. The design follows Clean Architecture principles with strict layer separation, implements offline-first capabilities, and establishes the foundation for all future chat features.

**Design Philosophy:**
- **Clean Architecture**: Strict separation between domain, data, and presentation layers
- **Offline-First**: All operations work offline and sync when online
- **Type-Safe**: Use Either<Failure, T> for error handling
- **Testable**: All components are unit testable with clear interfaces
- **Performant**: Optimized for 60fps UI and <2s startup time
- **Maintainable**: Clear patterns, comprehensive documentation, high test coverage

**Key Design Decisions:**
1. Use GraphQL for backend communication (matches existing backend)
2. Use Isar for local database (already integrated in project)
3. Use BLoC for state management (project standard)
4. Use GetIt + Injectable for DI (project standard)
5. Use Socket.IO for real-time events (backend provides this)
6. Implement offline queue with exponential backoff retry
7. Use last-write-wins for conflict resolution (simple and predictable)

## Architecture

### Layer Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ ChatBloc │  │MessageBloc│  │ Pages    │  │ Widgets  │   │
│  └────┬─────┘  └────┬──────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│       └─────────────┴──────────────┴─────────────┘          │
└───────────────────────┬─────────────────────────────────────┘
                        │ Events/States
┌───────────────────────┴─────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  UseCases    │  │  Entities    │  │ Repositories │     │
│  │              │  │              │  │ (Interfaces) │     │
│  └──────┬───────┘  └──────────────┘  └──────┬───────┘     │
│         │                                     │             │
│         └─────────────────────────────────────┘             │
└───────────────────────┬─────────────────────────────────────┘
                        │ Either<Failure, T>
┌───────────────────────┴─────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Repositories │  │  DataSources │  │    Models    │     │
│  │    (Impl)    │  │ Remote/Local │  │              │     │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘     │
│         │                  │                                │
│         └──────────────────┘                                │
└───────────────────────┬─────────────────────────────────────┘
                        │ Exceptions
┌───────────────────────┴─────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   GraphQL    │  │  Socket.IO   │  │     Isar     │     │
│  │    Client    │  │   Manager    │  │   Database   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Read Flow (Load Messages):**
```
User Action → BLoC Event → UseCase → Repository
                                        ↓
                              Check Network Connectivity
                                        ↓
                    ┌───────────────────┴───────────────────┐
                    │                                       │
                 Online                                  Offline
                    │                                       │
            Remote DataSource                      Local DataSource
                    │                                       │
            GraphQL Query                            Isar Query
                    │                                       │
            Parse to Model                          Load from Cache
                    │                                       │
            Cache Locally                                   │
                    │                                       │
                    └───────────────────┬───────────────────┘
                                        ↓
                              Map to Entity
                                        ↓
                          Return Either<Failure, T>
                                        ↓
                              BLoC State Update
                                        ↓
                                   UI Rebuild
```


**Write Flow (Send Message):**
```
User Action → BLoC Event → UseCase → Repository
                                        ↓
                              Check Network Connectivity
                                        ↓
                    ┌───────────────────┴───────────────────┐
                    │                                       │
                 Online                                  Offline
                    │                                       │
            Remote DataSource                      Add to Offline Queue
                    │                                       │
            GraphQL Mutation                        Cache Locally
                    │                                       │
            Parse Response                          Mark as Pending
                    │                                       │
            Cache Locally                                   │
                    │                                       │
            Emit Socket Event                               │
                    │                                       │
                    └───────────────────┬───────────────────┘
                                        ↓
                              Map to Entity
                                        ↓
                          Return Either<Failure, T>
                                        ↓
                              BLoC State Update
                                        ↓
                                   UI Rebuild
```

**Real-time Flow (Receive Message):**
```
Backend Event → Socket.IO Manager → Event Stream
                                        ↓
                                  BLoC Listener
                                        ↓
                              Parse Event Data
                                        ↓
                              Cache Locally
                                        ↓
                              Update BLoC State
                                        ↓
                                   UI Rebuild
```

## Components and Interfaces

### Domain Layer

#### Entities

**Chat Entity:**
```dart
class Chat extends Equatable {
  final String id;
  final String name;
  final ChatType type;  // Direct | Group
  final String? description;
  final String? imgUrl;
  final ChatGroupType? groupType;  // Public | Private
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageId;
  final User creator;
  final List<ConversationMember> members;
  
  const Chat({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.imgUrl,
    this.groupType,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessageId,
    required this.creator,
    required this.members,
  });
  
  @override
  List<Object?> get props => [id, name, type, description, imgUrl, 
                               groupType, createdAt, lastMessageAt, 
                               lastMessageId, creator, members];
}
```

**ChatMessage Entity:**
```dart
class ChatMessage extends Equatable {
  final String id;
  final String message;
  final List<String>? urls;
  final ChatMessageType type;  // TEXT | IMAGE | VIDEO | AUDIO | FILE | LOCATION
  final DateTime createdAt;
  final DateTime? editAt;
  final DateTime? deletedAt;
  final String? replyMessageId;
  final ChatMessage? replyMessage;
  final String? forwardedFromMessageId;
  final String? fileName;
  final String senderId;
  final User sender;
  final String conversationId;
  final List<String> readerIds;
  final List<MessageReaction> reactions;
  final List<User> mentionTo;
  
  const ChatMessage({
    required this.id,
    required this.message,
    this.urls,
    required this.type,
    required this.createdAt,
    this.editAt,
    this.deletedAt,
    this.replyMessageId,
    this.replyMessage,
    this.forwardedFromMessageId,
    this.fileName,
    required this.senderId,
    required this.sender,
    required this.conversationId,
    required this.readerIds,
    required this.reactions,
    required this.mentionTo,
  });
  
  bool get isEdited => editAt != null;
  bool get isDeleted => deletedAt != null;
  bool get hasReactions => reactions.isNotEmpty;
  
  @override
  List<Object?> get props => [id, message, urls, type, createdAt, editAt,
                               deletedAt, replyMessageId, forwardedFromMessageId,
                               fileName, senderId, sender, conversationId,
                               readerIds, reactions, mentionTo];
}
```


**ConversationMember Entity:**
```dart
class ConversationMember extends Equatable {
  final String id;
  final String userId;
  final String conversationId;
  final bool admin;
  final bool connected;
  final bool hide;
  final int unreadCount;
  final String? lastMessageReadId;
  final DateTime? viewMessagesFrom;
  final User user;
  
  const ConversationMember({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.admin,
    required this.connected,
    required this.hide,
    required this.unreadCount,
    this.lastMessageReadId,
    this.viewMessagesFrom,
    required this.user,
  });
  
  @override
  List<Object?> get props => [id, userId, conversationId, admin, connected,
                               hide, unreadCount, lastMessageReadId,
                               viewMessagesFrom, user];
}
```

**MessageReaction Entity:**
```dart
class MessageReaction extends Equatable {
  final String code;  // Emoji code
  final String userId;
  final User user;
  final DateTime createdAt;
  
  const MessageReaction({
    required this.code,
    required this.userId,
    required this.user,
    required this.createdAt,
  });
  
  @override
  List<Object> get props => [code, userId, user, createdAt];
}
```

#### Repository Interfaces

**IChatRepository:**
```dart
abstract class IChatRepository {
  /// Get list of conversations with pagination
  Future<Either<Failure, List<Chat>>> getConversations({
    int page = 0,
    int size = 25,
    String? keyword,
    ChatType? type,
  });
  
  /// Get conversation detail by ID or receiver ID
  Future<Either<Failure, Chat>> getConversationDetail({
    String? conversationId,
    String? receiverId,
  });
  
  /// Create a new group conversation
  Future<Either<Failure, Chat>> createGroup({
    required String name,
    required List<String> memberIds,
    String? imgUrl,
    String? description,
    ChatGroupType groupType = ChatGroupType.private,
  });
  
  /// Edit an existing group
  Future<Either<Failure, Chat>> editGroup({
    required String conversationId,
    String? name,
    String? imgUrl,
    String? description,
    ChatGroupType? groupType,
    List<String>? memberIds,
    List<String>? adminIds,
  });
  
  /// Leave a conversation
  Future<Either<Failure, void>> leaveConversation({
    required String conversationId,
  });
  
  /// Delete a conversation
  Future<Either<Failure, void>> deleteConversation({
    required String conversationId,
  });
}
```

**IMessageRepository:**
```dart
abstract class IMessageRepository {
  /// Get messages for a conversation with pagination
  Future<Either<Failure, MessageListResult>> getMessages({
    required String conversationId,
    int size = 100,
    LastKey? lastKey,
    ChatMessageType? type,
    OrderBy order = OrderBy.desc,
    DateTime? from,
  });
  
  /// Send a new message
  Future<Either<Failure, ChatMessage>> sendMessage({
    String? conversationId,
    String? receiverId,
    required String message,
    ChatMessageType type = ChatMessageType.text,
    List<String>? urls,
    String? fileName,
    String? replyMessageId,
    String? forwardedFromMessageId,
    List<String>? mentionTo,
  });
  
  /// Edit an existing message
  Future<Either<Failure, ChatMessage>> editMessage({
    required String messageId,
    required String message,
  });
  
  /// Mark messages as read
  Future<Either<Failure, void>> markAsRead({
    required String conversationId,
    required int readCount,
  });
  
  /// Add reaction to a message
  Future<Either<Failure, ChatMessage>> addReaction({
    required String messageId,
    required String code,
  });
  
  /// Remove reaction from a message
  Future<Either<Failure, ChatMessage>> removeReaction({
    required String messageId,
    required String code,
  });
}
```


#### UseCases

**GetConversationsUseCase:**
```dart
@injectable
class GetConversationsUseCase {
  final IChatRepository _repository;
  
  GetConversationsUseCase({required IChatRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, List<Chat>>> call({
    int page = 0,
    int size = 25,
    String? keyword,
    ChatType? type,
  }) async {
    // Validation
    if (size <= 0 || size > 100) {
      return const Left(ValidationFailure(
        message: 'Size must be between 1 and 100',
      ));
    }
    
    if (page < 0) {
      return const Left(ValidationFailure(
        message: 'Page must be non-negative',
      ));
    }
    
    // Call repository
    return await _repository.getConversations(
      page: page,
      size: size,
      keyword: keyword,
      type: type,
    );
  }
}
```

**SendMessageUseCase:**
```dart
@injectable
class SendMessageUseCase {
  final IMessageRepository _repository;
  
  SendMessageUseCase({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, ChatMessage>> call({
    String? conversationId,
    String? receiverId,
    required String message,
    ChatMessageType type = ChatMessageType.text,
    List<String>? urls,
    String? fileName,
    String? replyMessageId,
  }) async {
    // Validation
    if (conversationId == null && receiverId == null) {
      return const Left(ValidationFailure(
        message: 'Either conversationId or receiverId must be provided',
      ));
    }
    
    if (message.trim().isEmpty && (urls == null || urls.isEmpty)) {
      return const Left(ValidationFailure(
        message: 'Message cannot be empty',
      ));
    }
    
    // Call repository
    return await _repository.sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      message: message,
      type: type,
      urls: urls,
      fileName: fileName,
      replyMessageId: replyMessageId,
    );
  }
}
```

### Data Layer

#### Models

**ChatModel:**
```dart
@collection
class ChatModel {
  Id? isarId;
  
  @Index(unique: true)
  late String id;
  
  late String name;
  
  @Enumerated(EnumType.name)
  late ChatType type;
  
  String? description;
  String? imgUrl;
  
  @Enumerated(EnumType.name)
  ChatGroupType? groupType;
  
  late DateTime createdAt;
  DateTime? lastMessageAt;
  String? lastMessageReadId;
  
  // Relationships
  late String creatorId;
  final creator = IsarLink<UserModel>();
  final members = IsarLinks<ConversationMemberModel>();
  
  // JSON serialization
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel()
      ..id = json['id'] as String
      ..name = json['name'] as String
      ..type = ChatType.values.byName(json['type'] as String)
      ..description = json['description'] as String?
      ..imgUrl = json['imgUrl'] as String?
      ..groupType = json['groupType'] != null
          ? ChatGroupType.values.byName(json['groupType'] as String)
          : null
      ..createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
      ..lastMessageAt = json['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageAt'] as int)
          : null
      ..lastMessageReadId = json['lastMessageId'] as String?
      ..creatorId = json['creator']['id'] as String;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description,
      'imgUrl': imgUrl,
      'groupType': groupType?.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageAt': lastMessageAt?.millisecondsSinceEpoch,
      'lastMessageId': lastMessageReadId,
      'creatorId': creatorId,
    };
  }
  
  // Map to entity
  Chat toEntity() {
    return Chat(
      id: id,
      name: name,
      type: type,
      description: description,
      imgUrl: imgUrl,
      groupType: groupType,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      lastMessageId: lastMessageReadId,
      creator: creator.value!.toEntity(),
      members: members.map((m) => m.toEntity()).toList(),
    );
  }
}
```


#### DataSources

**IChatRemoteDataSource:**
```dart
abstract class IChatRemoteDataSource {
  Future<List<ChatModel>> getConversations({
    int page = 0,
    int size = 25,
    String? keyword,
    ChatType? type,
  });
  
  Future<ChatModel> getConversationDetail({
    String? conversationId,
    String? receiverId,
  });
  
  Future<ChatModel> createGroup({
    required String name,
    required List<String> memberIds,
    String? imgUrl,
    String? description,
    ChatGroupType groupType = ChatGroupType.private,
  });
  
  Future<ChatModel> editGroup({
    required String conversationId,
    String? name,
    String? imgUrl,
    String? description,
    ChatGroupType? groupType,
    List<String>? memberIds,
    List<String>? adminIds,
  });
  
  Future<void> leaveConversation({required String conversationId});
  Future<void> deleteConversation({required String conversationId});
}
```

**ChatRemoteDataSourceImpl:**
```dart
@LazySingleton(as: IChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements IChatRemoteDataSource {
  final GraphQLClient _client;
  final Logger _logger;
  
  ChatRemoteDataSourceImpl({
    required GraphQLClient client,
    required Logger logger,
  }) : _client = client,
       _logger = logger;
  
  @override
  Future<List<ChatModel>> getConversations({
    int page = 0,
    int size = 25,
    String? keyword,
    ChatType? type,
  }) async {
    try {
      _logger.d('Fetching conversations: page=$page, size=$size');
      
      final result = await _client.query(
        QueryOptions(
          document: gql(BackendOperations.chatConversationList),
          variables: {
            'filters': {
              'page': page,
              'size': size,
              if (keyword != null) 'keyword': keyword,
              if (type != null) 'type': type.name,
            },
          },
        ),
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Unknown error',
        );
      }
      
      final conversations = result.data?['chatConversationList']['conversations'] as List;
      return conversations.map((json) => ChatModel.fromJson(json)).toList();
      
    } catch (e) {
      _logger.e('Error fetching conversations', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
```

**IChatLocalDataSource:**
```dart
abstract class IChatLocalDataSource {
  Future<List<ChatModel>> getCachedConversations({
    int page = 0,
    int size = 25,
    String? keyword,
    ChatType? type,
  });
  
  Future<ChatModel?> getCachedConversation(String id);
  Future<void> cacheConversation(ChatModel conversation);
  Future<void> cacheConversations(List<ChatModel> conversations);
  Future<void> clearCache();
}
```

**ChatLocalDataSourceImpl:**
```dart
@LazySingleton(as: IChatLocalDataSource)
class ChatLocalDataSourceImpl implements IChatLocalDataSource {
  final Isar _isar;
  final Logger _logger;
  
  ChatLocalDataSourceImpl({
    required Isar isar,
    required Logger logger,
  }) : _isar = isar,
       _logger = logger;
  
  @override
  Future<List<ChatModel>> getCachedConversations({
    int page = 0,
    int size = 25,
    String? keyword,
    ChatType? type,
  }) async {
    try {
      _logger.d('Loading cached conversations');
      
      var query = _isar.chatModels.where();
      
      if (type != null) {
        query = query.filter().typeEqualTo(type);
      }
      
      if (keyword != null && keyword.isNotEmpty) {
        query = query.filter().nameContains(keyword, caseSensitive: false);
      }
      
      final conversations = await query
          .sortByLastMessageAtDesc()
          .offset(page * size)
          .limit(size)
          .findAll();
      
      return conversations;
      
    } catch (e) {
      _logger.e('Error loading cached conversations', error: e);
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<void> cacheConversation(ChatModel conversation) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.chatModels.put(conversation);
      });
    } catch (e) {
      _logger.e('Error caching conversation', error: e);
      throw CacheException(message: e.toString());
    }
  }
}
```


#### Repository Implementation

**ChatRepositoryImpl:**
```dart
@LazySingleton(as: IChatRepository)
class ChatRepositoryImpl implements IChatRepository {
  final IChatRemoteDataSource _remoteDataSource;
  final IChatLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  final IOfflineQueueService _offlineQueue;
  final Logger _logger;
  
  ChatRepositoryImpl({
    required IChatRemoteDataSource remoteDataSource,
    required IChatLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
    required IOfflineQueueService offlineQueue,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _offlineQueue = offlineQueue,
       _logger = logger;
  
  @override
  Future<Either<Failure, List<Chat>>> getConversations({
    int page = 0,
    int size = 25,
    String? keyword,
    ChatType? type,
  }) async {
    try {
      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      
      if (isConnected) {
        // Fetch from remote
        final conversations = await _remoteDataSource.getConversations(
          page: page,
          size: size,
          keyword: keyword,
          type: type,
        );
        
        // Cache locally
        await _localDataSource.cacheConversations(conversations);
        
        // Map to entities
        return Right(conversations.map((m) => m.toEntity()).toList());
        
      } else {
        // Fetch from cache
        final conversations = await _localDataSource.getCachedConversations(
          page: page,
          size: size,
          keyword: keyword,
          type: type,
        );
        
        // Map to entities
        return Right(conversations.map((m) => m.toEntity()).toList());
      }
      
    } on ServerException catch (e) {
      _logger.e('Server error getting conversations', error: e);
      return Left(ServerFailure(message: e.message));
      
    } on NetworkException catch (e) {
      _logger.e('Network error getting conversations', error: e);
      return Left(NetworkFailure(message: e.message));
      
    } on CacheException catch (e) {
      _logger.e('Cache error getting conversations', error: e);
      return Left(CacheFailure(message: e.message));
      
    } catch (e) {
      _logger.e('Unexpected error getting conversations', error: e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Chat>> createGroup({
    required String name,
    required List<String> memberIds,
    String? imgUrl,
    String? description,
    ChatGroupType groupType = ChatGroupType.private,
  }) async {
    try {
      final isConnected = await _networkInfo.isConnected;
      
      if (isConnected) {
        // Create on remote
        final conversation = await _remoteDataSource.createGroup(
          name: name,
          memberIds: memberIds,
          imgUrl: imgUrl,
          description: description,
          groupType: groupType,
        );
        
        // Cache locally
        await _localDataSource.cacheConversation(conversation);
        
        return Right(conversation.toEntity());
        
      } else {
        // Queue for later
        await _offlineQueue.addOperation(
          OfflineOperation(
            type: OperationType.createGroup,
            data: {
              'name': name,
              'memberIds': memberIds,
              'imgUrl': imgUrl,
              'description': description,
              'groupType': groupType.name,
            },
            timestamp: DateTime.now(),
          ),
        );
        
        return const Left(NetworkFailure(
          message: 'Operation queued for when online',
        ));
      }
      
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
```

### Presentation Layer

#### BLoC

**ChatBloc:**
```dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationsUseCase _getConversations;
  final CreateGroupUseCase _createGroup;
  final Logger _logger;
  
  ChatBloc({
    required GetConversationsUseCase getConversations,
    required CreateGroupUseCase createGroup,
    required Logger logger,
  }) : _getConversations = getConversations,
       _createGroup = createGroup,
       _logger = logger,
       super(const ChatState.initial()) {
    on<ChatLoadConversationsEvent>(_onLoadConversations);
    on<ChatCreateGroupEvent>(_onCreateGroup);
  }
  
  Future<void> _onLoadConversations(
    ChatLoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatState.loading(operation: 'load_conversations'));
    
    final result = await _getConversations(
      page: event.page,
      size: event.size,
      keyword: event.keyword,
      type: event.type,
    );
    
    result.fold(
      (failure) {
        _logger.e('Failed to load conversations', error: failure);
        emit(ChatState.error(
          failure: failure,
          operation: 'load_conversations',
          retryAction: () => add(event),
        ));
      },
      (conversations) {
        _logger.i('Loaded ${conversations.length} conversations');
        emit(ChatState.loaded(conversations: conversations));
      },
    );
  }
  
  @override
  Future<void> close() {
    _logger.d('ChatBloc closed');
    return super.close();
  }
}
```


## Data Models

### GraphQL Operations

All GraphQL operations are defined in `lib/data/graphql/backend_operations.dart`:

```dart
class BackendOperations {
  // Conversation Operations
  static const String chatConversationList = '''
    query GetConversations(\$filters: ChatConversationListFilter!) {
      chatConversationList(filters: \$filters) {
        total
        conversations {
          id
          name
          type
          description
          imgUrl
          groupType
          createdAt
          lastMessageAt
          lastMessageId
          creator {
            id
            fullname
            avatarUrl
          }
          members {
            id
            userId
            admin
            connected
            hide
            unreadCount
            lastMessageReadId
            user {
              id
              fullname
              avatarUrl
              email
            }
          }
        }
      }
    }
  ''';
  
  static const String chatConversationDetail = '''
    query GetConversationDetail(\$conversationId: String, \$receiverId: String) {
      chatConversationDetail(conversationId: \$conversationId, receiverId: \$receiverId) {
        id
        name
        type
        description
        imgUrl
        groupType
        createdAt
        lastMessageAt
        creator {
          id
          fullname
        }
        members {
          id
          userId
          admin
          unreadCount
          user {
            id
            fullname
            avatarUrl
          }
        }
      }
    }
  ''';
  
  static const String chatGroupAdd = '''
    mutation CreateGroup(\$arguments: ChatGroupAddInput!) {
      chatGroupAdd(arguments: \$arguments) {
        id
        name
        imgUrl
        description
        groupType
        members {
          userId
          admin
          user {
            fullname
          }
        }
      }
    }
  ''';
  
  static const String chatMessageList = '''
    query GetMessages(\$filters: ChatMessageGetListFilter!) {
      chatMessageList(filters: \$filters) {
        lastKey {
          conversationId
          createdAt
        }
        messages {
          id
          message
          urls
          type
          createdAt
          editAt
          deletedAt
          replyMessageId
          replyMessage {
            id
            message
            sender {
              fullname
            }
          }
          forwardedFromMessageId
          fileName
          senderId
          sender {
            id
            fullname
            avatarUrl
          }
          conversationId
          readerIds
          reactions {
            code
            userId
            user {
              fullname
            }
          }
          mentionTo {
            id
            fullname
          }
        }
      }
    }
  ''';
  
  static const String chatMessageAdd = '''
    mutation SendMessage(\$arguments: ChatAddMessageInput!) {
      chatMessageAdd(arguments: \$arguments) {
        id
        message
        urls
        type
        createdAt
        senderId
        sender {
          fullname
          avatarUrl
        }
        conversationId
      }
    }
  ''';
}
```

### Offline Queue

**OfflineOperation Model:**
```dart
@collection
class OfflineOperation {
  Id? id;
  
  @Enumerated(EnumType.name)
  late OperationType type;
  
  late String data;  // JSON string
  late DateTime timestamp;
  late int retryCount;
  late DateTime? lastRetryAt;
  
  @Enumerated(EnumType.name)
  late OperationStatus status;
  
  OfflineOperation({
    required this.type,
    required Map<String, dynamic> dataMap,
    required this.timestamp,
    this.retryCount = 0,
    this.lastRetryAt,
    this.status = OperationStatus.pending,
  }) : data = jsonEncode(dataMap);
  
  Map<String, dynamic> get dataMap => jsonDecode(data);
}

enum OperationType {
  sendMessage,
  editMessage,
  deleteMessage,
  createGroup,
  editGroup,
  leaveConversation,
  markAsRead,
  addReaction,
}

enum OperationStatus {
  pending,
  processing,
  completed,
  failed,
}
```

**IOfflineQueueService:**
```dart
abstract class IOfflineQueueService {
  Future<void> addOperation(OfflineOperation operation);
  Future<List<OfflineOperation>> getPendingOperations();
  Future<void> processQueue();
  Future<void> markAsCompleted(int operationId);
  Future<void> markAsFailed(int operationId);
  Stream<int> get queueSizeStream;
}
```

### Real-time Events

**Socket.IO Event Handlers:**
```dart
@singleton
class RealtimeService {
  final SocketManager _socketManager;
  final Logger _logger;
  
  final _messageReceivedController = StreamController<ChatMessage>.broadcast();
  final _messageReadController = StreamController<MessageReadEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  
  Stream<ChatMessage> get messageReceived => _messageReceivedController.stream;
  Stream<MessageReadEvent> get messageRead => _messageReadController.stream;
  Stream<TypingEvent> get typing => _typingController.stream;
  
  RealtimeService({
    required SocketManager socketManager,
    required Logger logger,
  }) : _socketManager = socketManager,
       _logger = logger {
    _setupEventListeners();
  }
  
  void _setupEventListeners() {
    _socketManager.on('message:sent').listen((data) {
      _logger.d('Received message:sent event');
      final message = ChatMessage.fromJson(data['message']);
      _messageReceivedController.add(message);
    });
    
    _socketManager.on('message:read').listen((data) {
      _logger.d('Received message:read event');
      final event = MessageReadEvent.fromJson(data);
      _messageReadController.add(event);
    });
    
    _socketManager.on('message:typing').listen((data) {
      _logger.d('Received message:typing event');
      final event = TypingEvent.fromJson(data);
      _typingController.add(event);
    });
  }
  
  void dispose() {
    _messageReceivedController.close();
    _messageReadController.close();
    _typingController.close();
  }
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: GraphQL Operation Success

*For any* valid GraphQL query or mutation, when sent to the Backend_API, the response should have the expected structure and all required fields should be present.

**Validates: Requirements 1.1, 1.2**

### Property 2: GraphQL Error Handling

*For any* GraphQL operation that fails, the System should return a Failure with a descriptive error message, never throwing an uncaught exception.

**Validates: Requirements 1.3**

### Property 3: Data Model Serialization Round-trip

*For any* valid JSON response from the Backend_API, deserializing to a model then serializing back to JSON should produce equivalent data (ignoring field order).

**Validates: Requirements 2.5**

### Property 4: Data Model Deserialization Round-trip

*For any* valid data model, serializing to JSON then deserializing back to a model should produce an equivalent model.

**Validates: Requirements 2.6**

### Property 5: Repository Either Pattern

*For all* repository methods, the return type should be Either<Failure, T>, never returning null or throwing uncaught exceptions to the caller.

**Validates: Requirements 4.7**

### Property 6: UseCase Input Validation

*For any* invalid input to a UseCase, the UseCase should return a ValidationFailure with specific error details, not proceeding with the operation.

**Validates: Requirements 5.8**

### Property 7: UseCase Error Propagation

*For any* Either<Failure, T> result from a Repository, the UseCase should propagate it unchanged (not wrapping or transforming the Failure type).

**Validates: Requirements 5.9**

### Property 8: BLoC Success State Transition

*For any* successful UseCase result (Right value), the BLoC should emit a success state containing the result data.

**Validates: Requirements 6.6**

### Property 9: BLoC Error State Transition

*For any* failed UseCase result (Left value), the BLoC should emit an error state containing the Failure and a retry action.

**Validates: Requirements 6.7**

### Property 10: Real-time Event Processing

*For any* message:sent event received from Socket.IO, the System should update the local message list and emit a state update within 100ms.

**Validates: Requirements 7.4**

### Property 11: Offline Queue Addition

*For any* write operation (send message, create group, etc.) performed while offline, the operation should be added to the Offline_Queue with status pending.

**Validates: Requirements 8.3**

### Property 12: Offline Queue Processing Order

*For any* set of queued operations, when the System comes online, operations should be processed in FIFO order (first queued, first processed).

**Validates: Requirements 8.4**

### Property 13: Cache-Backend Consistency

*For any* successful sync operation, the local Cache should contain the same data as the Backend_API for the synced entities (within eventual consistency bounds).

**Validates: Requirements 8.7**

### Property 14: Error Handling Pattern Consistency

*For all* operations that can fail, the System should use Either<Failure, T> pattern, never throwing exceptions to the presentation layer.

**Validates: Requirements 9.1**


## Error Handling

### Failure Hierarchy

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

### Exception Hierarchy

```dart
// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  const ServerException({
    required this.message,
    this.statusCode,
  });
  
  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException({this.message = 'No internet connection'});
  
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  
  const CacheException({required this.message});
  
  @override
  String toString() => 'CacheException: $message';
}
```

### Error Flow

```
DataSource Operation
        ↓
   Throws Exception
        ↓
Repository catches Exception
        ↓
Maps to Failure
        ↓
Returns Either<Failure, T>
        ↓
UseCase propagates Either
        ↓
BLoC handles Failure
        ↓
Emits Error State
        ↓
UI displays error message
```

### User-Friendly Error Messages

```dart
// lib/core/error/error_messages.dart
class ErrorMessages {
  static String getUserFriendlyMessage(Failure failure, BuildContext context) {
    if (failure is NetworkFailure) {
      return context.l10n.errorNoInternet;
    } else if (failure is ServerFailure) {
      return context.l10n.errorServer;
    } else if (failure is CacheFailure) {
      return context.l10n.errorCache;
    } else if (failure is ValidationFailure) {
      return failure.message;  // Already user-friendly
    } else {
      return context.l10n.errorUnexpected;
    }
  }
}
```

## Testing Strategy

### Dual Testing Approach

Phase 1 requires both unit tests and property-based tests:

**Unit Tests:**
- Verify specific examples and edge cases
- Test error conditions
- Test integration points between components
- Fast execution, deterministic results

**Property-Based Tests:**
- Verify universal properties across all inputs
- Test with randomly generated data
- Catch edge cases not thought of manually
- Minimum 100 iterations per test

Both approaches are complementary and necessary for comprehensive coverage.

### Unit Testing

**UseCase Tests:**
```dart
// test/domain/usecases/get_conversations_usecase_test.dart
void main() {
  late GetConversationsUseCase useCase;
  late MockChatRepository mockRepository;
  
  setUp(() {
    mockRepository = MockChatRepository();
    useCase = GetConversationsUseCase(repository: mockRepository);
  });
  
  group('GetConversationsUseCase', () {
    test('should return conversations when repository succeeds', () async {
      // Arrange
      final tConversations = [testChat1, testChat2];
      when(() => mockRepository.getConversations(
        page: any(named: 'page'),
        size: any(named: 'size'),
      )).thenAnswer((_) async => Right(tConversations));
      
      // Act
      final result = await useCase(page: 0, size: 25);
      
      // Assert
      expect(result, Right(tConversations));
      verify(() => mockRepository.getConversations(page: 0, size: 25)).called(1);
    });
    
    test('should return ValidationFailure when size is invalid', () async {
      // Act
      final result = await useCase(page: 0, size: 0);
      
      // Assert
      expect(result, isA<Left<ValidationFailure, List<Chat>>>());
      verifyNever(() => mockRepository.getConversations(
        page: any(named: 'page'),
        size: any(named: 'size'),
      ));
    });
  });
}
```

**Repository Tests:**
```dart
// test/data/repositories/chat_repository_impl_test.dart
void main() {
  late ChatRepositoryImpl repository;
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockChatLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  
  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockLocalDataSource = MockChatLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ChatRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });
  
  group('getConversations', () {
    test('should check network connectivity', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getConversations(
        page: any(named: 'page'),
        size: any(named: 'size'),
      )).thenAnswer((_) async => [testChatModel]);
      when(() => mockLocalDataSource.cacheConversations(any()))
          .thenAnswer((_) async => Future.value());
      
      // Act
      await repository.getConversations(page: 0, size: 25);
      
      // Assert
      verify(() => mockNetworkInfo.isConnected).called(1);
    });
    
    test('should return NetworkFailure when offline and cache is empty', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getCachedConversations(
        page: any(named: 'page'),
        size: any(named: 'size'),
      )).thenThrow(CacheException(message: 'No cached data'));
      
      // Act
      final result = await repository.getConversations(page: 0, size: 25);
      
      // Assert
      expect(result, isA<Left<CacheFailure, List<Chat>>>());
    });
  });
}
```


### Property-Based Testing

**Test Configuration:**
- Use `test` package with custom property test helpers
- Minimum 100 iterations per property test
- Each test references its design document property
- Tag format: `Feature: chat-foundation, Property {number}: {property_text}`

**Property Test Example:**
```dart
// test/data/models/chat_model_property_test.dart
import 'package:test/test.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';

void main() {
  group('ChatModel Property Tests', () {
    test(
      'Feature: chat-foundation, Property 3: Data Model Serialization Round-trip',
      () {
        // Run 100 iterations with random data
        for (var i = 0; i < 100; i++) {
          // Generate random valid JSON
          final json = generateRandomChatJson();
          
          // Deserialize then serialize
          final model = ChatModel.fromJson(json);
          final serialized = model.toJson();
          
          // Verify equivalence (ignoring field order)
          expect(serialized['id'], json['id']);
          expect(serialized['name'], json['name']);
          expect(serialized['type'], json['type']);
          // ... verify all fields
        }
      },
    );
    
    test(
      'Feature: chat-foundation, Property 4: Data Model Deserialization Round-trip',
      () {
        for (var i = 0; i < 100; i++) {
          // Generate random valid model
          final model = generateRandomChatModel();
          
          // Serialize then deserialize
          final json = model.toJson();
          final deserialized = ChatModel.fromJson(json);
          
          // Verify equivalence
          expect(deserialized.id, model.id);
          expect(deserialized.name, model.name);
          expect(deserialized.type, model.type);
          // ... verify all fields
        }
      },
    );
  });
}

// Helper to generate random valid chat JSON
Map<String, dynamic> generateRandomChatJson() {
  final random = Random();
  return {
    'id': 'chat-${random.nextInt(10000)}',
    'name': 'Chat ${random.nextInt(100)}',
    'type': random.nextBool() ? 'Direct' : 'Group',
    'createdAt': DateTime.now().millisecondsSinceEpoch,
    'creator': {
      'id': 'user-${random.nextInt(100)}',
      'fullname': 'User ${random.nextInt(100)}',
    },
    'members': [],
  };
}
```

**BLoC State Transition Property Test:**
```dart
// test/presentation/blocs/chat_bloc_property_test.dart
void main() {
  group('ChatBloc Property Tests', () {
    test(
      'Feature: chat-foundation, Property 8: BLoC Success State Transition',
      () async {
        for (var i = 0; i < 100; i++) {
          // Setup
          final mockUseCase = MockGetConversationsUseCase();
          final bloc = ChatBloc(getConversations: mockUseCase);
          
          // Generate random success result
          final conversations = generateRandomConversations();
          when(() => mockUseCase(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => Right(conversations));
          
          // Act
          bloc.add(const ChatLoadConversationsEvent(page: 0, size: 25));
          
          // Assert - should emit success state
          await expectLater(
            bloc.stream,
            emitsInOrder([
              isA<ChatLoadingState>(),
              isA<ChatLoadedState>()
                  .having((s) => s.conversations, 'conversations', conversations),
            ]),
          );
          
          await bloc.close();
        }
      },
    );
    
    test(
      'Feature: chat-foundation, Property 9: BLoC Error State Transition',
      () async {
        for (var i = 0; i < 100; i++) {
          // Setup
          final mockUseCase = MockGetConversationsUseCase();
          final bloc = ChatBloc(getConversations: mockUseCase);
          
          // Generate random failure
          final failure = generateRandomFailure();
          when(() => mockUseCase(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => Left(failure));
          
          // Act
          bloc.add(const ChatLoadConversationsEvent(page: 0, size: 25));
          
          // Assert - should emit error state with retry action
          await expectLater(
            bloc.stream,
            emitsInOrder([
              isA<ChatLoadingState>(),
              isA<ChatErrorState>()
                  .having((s) => s.failure, 'failure', failure)
                  .having((s) => s.retryAction, 'retryAction', isNotNull),
            ]),
          );
          
          await bloc.close();
        }
      },
    );
  });
}
```

### Integration Testing

**End-to-End Data Flow Test:**
```dart
// test/integration/chat_flow_integration_test.dart
void main() {
  group('Chat Flow Integration Tests', () {
    late Isar isar;
    late ChatRepositoryImpl repository;
    late GetConversationsUseCase useCase;
    late ChatBloc bloc;
    
    setUp(() async {
      // Setup real Isar database (in-memory)
      isar = await Isar.open([ChatModelSchema], directory: '');
      
      // Setup real components
      final localDataSource = ChatLocalDataSourceImpl(isar: isar);
      final remoteDataSource = MockChatRemoteDataSource();
      final networkInfo = MockNetworkInfo();
      
      repository = ChatRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        networkInfo: networkInfo,
      );
      
      useCase = GetConversationsUseCase(repository: repository);
      bloc = ChatBloc(getConversations: useCase);
    });
    
    tearDown(() async {
      await isar.close();
      await bloc.close();
    });
    
    test('should load conversations from API and cache locally', () async {
      // Arrange
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getConversations(
        page: any(named: 'page'),
        size: any(named: 'size'),
      )).thenAnswer((_) async => [testChatModel1, testChatModel2]);
      
      // Act
      bloc.add(const ChatLoadConversationsEvent(page: 0, size: 25));
      
      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ChatLoadingState>(),
          isA<ChatLoadedState>()
              .having((s) => s.conversations.length, 'length', 2),
        ]),
      );
      
      // Verify cached locally
      final cached = await isar.chatModels.where().findAll();
      expect(cached.length, 2);
    });
  });
}
```

### Test Coverage Goals

**Phase 1 Target: >60% coverage**

Coverage breakdown:
- Domain Layer (UseCases): >90%
- Data Layer (Repositories, DataSources): >80%
- Presentation Layer (BLoCs): >70%
- Models (Serialization): >90%
- Overall: >60%

**Coverage Commands:**
```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

---

**Document Version:** 1.0  
**Created:** 2025-01-27  
**Status:** Draft - Awaiting Review  
**Next Step:** User review and approval before proceeding to tasks phase
