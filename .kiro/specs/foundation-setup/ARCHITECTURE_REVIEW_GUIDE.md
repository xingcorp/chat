# Architecture Review Guide (Day 3)

## Overview

This guide covers Day 3 tasks (Tasks 13-20) for conducting code walkthrough, documenting patterns, reviewing Clean Architecture principles, establishing code review process, and final verification.

**Duration:** 8 hours  
**Team:** Full team (5-6 developers)  
**Prerequisites:** Day 1 and Day 2 completed, backend API tested

## Task 13: Conduct Code Walkthrough Session

### 13.1 Walkthrough Presentation Layer

**Location:** `flutter_chat_app/lib/presentation/`

**Structure to review:**
```
presentation/
├── blocs/              # BLoC state management
│   ├── auth/
│   ├── chat/
│   ├── conversation/
│   └── message/
├── pages/              # Full-screen pages
│   ├── auth/
│   ├── chat/
│   ├── conversation/
│   └── home/
└── widgets/            # Reusable UI components
    ├── common/
    ├── chat/
    └── message/
```

**Key patterns to identify:**

**1. BLoC Pattern:**
```dart
// Example: AuthBloc
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _repository;
  
  AuthBloc({required IAuthRepository repository})
      : _repository = repository,
        super(const AuthState.initial()) {
    on<AuthLoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await _repository.login(event.email, event.password);
    
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }
}
```

**2. Freezed Events and States:**
```dart
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = AuthLoginRequested;
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated({required User user}) = AuthAuthenticated;
  const factory AuthState.error({required Failure failure}) = AuthError;
}
```

**3. Widget Integration:**
```dart
class LoginPage extends BaseStatefulWidget {
  const LoginPage({super.key});
  
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          error: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          },
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => _buildLoginForm(),
          loading: () => const LoadingIndicator(),
          authenticated: (user) => const HomePage(),
          error: (failure) => _buildLoginForm(),
        );
      },
    );
  }
}
```

**Findings to document:**
- [ ] BLoC implementations follow pattern
- [ ] Events and states use Freezed
- [ ] Widgets use BlocConsumer/BlocBuilder correctly
- [ ] Error handling in listeners
- [ ] Loading states handled
- [ ] Navigation logic placement

### 13.2 Walkthrough Domain Layer

**Location:** `flutter_chat_app/lib/domain/`

**Structure to review:**
```
domain/
├── entities/           # Business entities (pure Dart)
│   ├── user.dart
│   ├── conversation.dart
│   └── message.dart
├── repositories/       # Repository interfaces
│   ├── auth_repository.dart
│   ├── conversation_repository.dart
│   └── message_repository.dart
└── usecases/          # Business logic use cases
    ├── auth/
    ├── conversation/
    └── message/
```

**Key patterns to identify:**

**1. Pure Entities (No Flutter dependencies):**
```dart
// ✅ CORRECT - Pure Dart entity
class User extends Equatable {
  final String id;
  final String phone;
  final String displayName;
  final String? avatar;
  
  const User({
    required this.id,
    required this.phone,
    required this.displayName,
    this.avatar,
  });
  
  @override
  List<Object?> get props => [id, phone, displayName, avatar];
}

// ❌ WRONG - Importing Flutter
import 'package:flutter/material.dart'; // ERROR!
```

**2. Repository Interfaces:**
```dart
// Repository interface (domain layer)
abstract class IAuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, void>> logout();
}
```

**3. UseCase Pattern:**
```dart
// UseCase with single responsibility
@injectable
class GetUserMessages {
  final IMessageRepository _repository;
  
  GetUserMessages({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, List<Message>>> call({
    required String conversationId,
    required int page,
    required int limit,
  }) async {
    return _repository.getMessages(
      conversationId: conversationId,
      page: page,
      limit: limit,
    );
  }
}

// Usage in BLoC
final result = await _getUserMessages(
  conversationId: event.conversationId,
  page: 1,
  limit: 50,
);
```

**Findings to document:**
- [ ] Entities are pure Dart (no Flutter imports)
- [ ] Repository interfaces defined
- [ ] UseCases follow single responsibility
- [ ] Error handling with Either<Failure, T>
- [ ] **CRITICAL:** Identify empty UseCase implementations
- [ ] **CRITICAL:** Identify missing UseCases

**Known Issues (from PROJECT_STATUS_ANALYSIS.md):**
- ⚠️ Many UseCases are empty or incomplete
- ⚠️ Some repository interfaces missing methods
- ⚠️ Need to implement all UseCases in Phase 1

### 13.3 Walkthrough Data Layer

**Location:** `flutter_chat_app/lib/data/`

**Structure to review:**
```
data/
├── models/             # Data models with JSON serialization
│   ├── user_model.dart
│   ├── conversation_model.dart
│   └── message_model.dart
├── datasources/        # Data sources (remote and local)
│   ├── remote/
│   │   ├── auth_remote_datasource.dart
│   │   ├── conversation_remote_datasource.dart
│   │   └── message_remote_datasource.dart
│   └── local/
│       ├── auth_local_datasource.dart
│       ├── conversation_local_datasource.dart
│       └── message_local_datasource.dart
└── repositories/       # Repository implementations
    ├── auth_repository_impl.dart
    ├── conversation_repository_impl.dart
    └── message_repository_impl.dart
```

**Key patterns to identify:**

**1. Data Models with JSON Serialization:**
```dart
@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String phone;
  final String displayName;
  final String? avatar;
  
  const UserModel({
    required this.id,
    required this.phone,
    required this.displayName,
    this.avatar,
  });
  
  // JSON serialization
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
  
  // Convert to domain entity
  User toEntity() => User(
    id: id,
    phone: phone,
    displayName: displayName,
    avatar: avatar,
  );
  
  // Create from domain entity
  factory UserModel.fromEntity(User user) => UserModel(
    id: user.id,
    phone: user.phone,
    displayName: user.displayName,
    avatar: user.avatar,
  );
  
  @override
  List<Object?> get props => [id, phone, displayName, avatar];
}
```

**2. Remote Data Source (GraphQL):**
```dart
@LazySingleton(as: IConversationRemoteDataSource)
class ConversationRemoteDataSource implements IConversationRemoteDataSource {
  final GraphQLClient _client;
  
  ConversationRemoteDataSource({required GraphQLClient client})
      : _client = client;
  
  @override
  Future<List<ConversationModel>> getConversations({
    required int page,
    required int limit,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql('''
          query GetConversations(\$page: Int!, \$limit: Int!) {
            chatConversationList(page: \$page, limit: \$limit) {
              items {
                id
                type
                name
                avatar
                lastMessage {
                  id
                  content
                  createdAt
                }
                updatedAt
              }
            }
          }
        '''),
        variables: {'page': page, 'limit': limit},
      ),
    );
    
    if (result.hasException) {
      throw ServerException(message: result.exception.toString());
    }
    
    final items = result.data?['chatConversationList']['items'] as List;
    return items.map((json) => ConversationModel.fromJson(json)).toList();
  }
}
```

**3. Local Data Source (Isar):**
```dart
@LazySingleton(as: IConversationLocalDataSource)
class ConversationLocalDataSource implements IConversationLocalDataSource {
  final Isar _isar;
  
  ConversationLocalDataSource({required Isar isar}) : _isar = isar;
  
  @override
  Future<List<ConversationModel>> getCachedConversations() async {
    final conversations = await _isar.conversationModels
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
    
    return conversations;
  }
  
  @override
  Future<void> cacheConversations(List<ConversationModel> conversations) async {
    await _isar.writeTxn(() async {
      await _isar.conversationModels.putAll(conversations);
    });
  }
}
```

**4. Repository Implementation:**
```dart
@LazySingleton(as: IConversationRepository)
class ConversationRepositoryImpl implements IConversationRepository {
  final IConversationRemoteDataSource _remoteDataSource;
  final IConversationLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  
  ConversationRepositoryImpl({
    required IConversationRemoteDataSource remoteDataSource,
    required IConversationLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;
  
  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
    required int page,
    required int limit,
  }) async {
    try {
      // Try remote first if online
      if (await _networkInfo.isConnected) {
        final conversations = await _remoteDataSource.getConversations(
          page: page,
          limit: limit,
        );
        
        // Cache for offline use
        await _localDataSource.cacheConversations(conversations);
        
        return Right(conversations.map((m) => m.toEntity()).toList());
      } else {
        // Use cached data if offline
        final cachedConversations = await _localDataSource.getCachedConversations();
        return Right(cachedConversations.map((m) => m.toEntity()).toList());
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }
}
```

**Findings to document:**
- [ ] Models have JSON serialization
- [ ] Models have toEntity() and fromEntity() methods
- [ ] Remote data sources use GraphQL
- [ ] Local data sources use Isar
- [ ] Repository implements offline-first pattern
- [ ] **CRITICAL:** Identify GraphQL operation mismatches
- [ ] **CRITICAL:** Identify missing data source methods

**Known Issues (from PROJECT_STATUS_ANALYSIS.md):**
- ⚠️ GraphQL operations don't match backend schema
- ⚠️ Some models missing fields
- ⚠️ Need to update GraphQL queries in Phase 1

### 13.4 Walkthrough Core Infrastructure

**Location:** `flutter_chat_app/lib/core/`

**Structure to review:**
```
core/
├── di/                 # Dependency injection
│   └── enterprise_injection.dart
├── network/            # Network layer
│   ├── graphql_client.dart
│   └── network_info.dart
├── storage/            # Local storage
│   ├── isar_service.dart
│   └── secure_storage.dart
├── services/           # Infrastructure services
│   ├── socket_service.dart
│   ├── logger_service.dart
│   └── performance_service.dart
└── error/              # Error handling
    ├── failures.dart
    └── exceptions.dart
```

**Key patterns to identify:**

**1. Dependency Injection (GetIt + Injectable):**
```dart
// enterprise_injection.dart
final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
}

// Usage in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

// Injectable annotations
@injectable
class MyService { }

@lazySingleton
class MySingleton { }

@singleton
class MyGlobalSingleton { }
```

**2. GraphQL Client Setup:**
```dart
@lazySingleton
class GraphQLClientService {
  late GraphQLClient _client;
  
  GraphQLClientService() {
    final httpLink = HttpLink('https://api.example.com/graphql');
    
    final authLink = AuthLink(
      getToken: () async {
        final token = await SecureStorage().getToken();
        return token != null ? 'Bearer $token' : null;
      },
    );
    
    final link = authLink.concat(httpLink);
    
    _client = GraphQLClient(
      cache: GraphQLCache(),
      link: link,
    );
  }
  
  GraphQLClient get client => _client;
}
```

**3. Socket.IO Service:**
```dart
@lazySingleton
class SocketService {
  late IO.Socket _socket;
  
  Future<void> connect(String token) async {
    _socket = IO.io(
      'https://api.example.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );
    
    _socket.connect();
    
    _socket.on('connect', (_) {
      logger.i('Socket connected');
    });
    
    _socket.on('disconnect', (_) {
      logger.w('Socket disconnected');
    });
  }
  
  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }
  
  void on(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }
}
```

**4. Offline Sync Queue:**
```dart
@lazySingleton
class SyncQueueService {
  final Isar _isar;
  
  SyncQueueService({required Isar isar}) : _isar = isar;
  
  Future<void> addToQueue(SyncOperation operation) async {
    await _isar.writeTxn(() async {
      await _isar.syncOperations.put(operation);
    });
  }
  
  Future<void> processQueue() async {
    final operations = await _isar.syncOperations
        .where()
        .filter()
        .statusEqualTo(SyncStatus.pending)
        .findAll();
    
    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        operation.status = SyncStatus.completed;
        await _isar.writeTxn(() async {
          await _isar.syncOperations.put(operation);
        });
      } catch (e) {
        operation.status = SyncStatus.failed;
        operation.error = e.toString();
        await _isar.writeTxn(() async {
          await _isar.syncOperations.put(operation);
        });
      }
    }
  }
}
```

**Findings to document:**
- [ ] Dependency injection configured correctly
- [ ] GraphQL client setup with authentication
- [ ] Socket.IO service implemented
- [ ] Offline sync queue implemented
- [ ] Logger service used throughout
- [ ] Performance monitoring setup

### 13.5 Document Findings from Walkthrough

**Create architecture findings document:**

```markdown
# Architecture Walkthrough Findings

## Date: [Date]
## Participants: [Team members]

### Presentation Layer Findings

**Strengths:**
- ✅ BLoC pattern consistently used
- ✅ Freezed for events and states
- ✅ Proper widget separation
- ✅ Error handling in listeners

**Issues:**
- ⚠️ [List any issues found]
- ⚠️ [List any issues found]

**Action Items:**
- [ ] [Action item 1]
- [ ] [Action item 2]

### Domain Layer Findings

**Strengths:**
- ✅ Pure Dart entities (no Flutter dependencies)
- ✅ Repository interfaces defined
- ✅ Either<Failure, T> error handling

**Issues:**
- ⚠️ Many UseCases are empty or incomplete
- ⚠️ Some repository interfaces missing methods
- ⚠️ [List any other issues]

**Action Items:**
- [ ] Implement all empty UseCases (Phase 1 priority)
- [ ] Add missing repository methods
- [ ] [Action item 3]

### Data Layer Findings

**Strengths:**
- ✅ Models with JSON serialization
- ✅ toEntity() and fromEntity() methods
- ✅ Offline-first repository pattern
- ✅ Isar for local storage

**Issues:**
- ⚠️ GraphQL operations don't match backend schema
- ⚠️ Some models missing fields (e.g., unreadCount)
- ⚠️ [List any other issues]

**Action Items:**
- [ ] Update GraphQL queries to match backend (Phase 1 priority)
- [ ] Add missing model fields
- [ ] [Action item 3]

### Core Infrastructure Findings

**Strengths:**
- ✅ Dependency injection with GetIt + Injectable
- ✅ GraphQL client configured
- ✅ Socket.IO service implemented
- ✅ Offline sync queue implemented

**Issues:**
- ⚠️ [List any issues found]
- ⚠️ [List any issues found]

**Action Items:**
- [ ] [Action item 1]
- [ ] [Action item 2]

### Overall Assessment

**Architecture Compliance:** [Good/Fair/Needs Improvement]

**Critical Issues:** [Number]

**Priority Actions:**
1. [Highest priority action]
2. [Second priority action]
3. [Third priority action]

**Readiness for Phase 1:** [Yes/No/With Conditions]
```

Save this to: `.kiro/specs/foundation-setup/ARCHITECTURE_FINDINGS.md`

## Task 14: Document Existing Patterns and Conventions

### 14.1 File Naming Conventions

**Already documented in project-architecture.md, but summarize here:**

```markdown
# File Naming Conventions

## Dart Files
- **Format:** `snake_case.dart`
- **Examples:**
  - `user_repository.dart`
  - `login_page.dart`
  - `message_bubble.dart`
  - `auth_bloc.dart`

## Classes
- **Format:** `PascalCase`
- **Examples:**
  - `UserRepository`
  - `LoginPage`
  - `MessageBubble`
  - `AuthBloc`

## Variables and Methods
- **Format:** `camelCase`
- **Examples:**
  - `userName`
  - `getUserMessages()`
  - `isLoggedIn`
  - `sendMessage()`

## Constants
- **Format:** `camelCase` or `SCREAMING_SNAKE_CASE`
- **Examples:**
  - `const maxMessageLength = 1000;`
  - `const API_TIMEOUT = 30;`

## Private Members
- **Format:** Prefix with underscore `_`
- **Examples:**
  - `_repository`
  - `_handleLogin()`
  - `_isInitialized`

## Repository Naming
- **Interface:** `IMessageRepository` (with `I` prefix)
- **Implementation:** `MessageRepositoryImpl` (with `Impl` suffix)

## UseCase Naming
- **Format:** Action verb + noun
- **Examples:**
  - `GetUserMessages`
  - `SendMessage`
  - `DeleteConversation`
  - `UpdateUserProfile`

## BLoC Naming
- **BLoC:** `FeatureNameBloc` (e.g., `AuthBloc`, `ChatBloc`)
- **Event:** `FeatureNameEvent` (e.g., `AuthEvent`, `ChatEvent`)
- **State:** `FeatureNameState` (e.g., `AuthState`, `ChatState`)

## Widget Naming
- **Pages:** `FeatureNamePage` (e.g., `LoginPage`, `ChatDetailPage`)
- **Widgets:** Descriptive name, no suffix (e.g., `MessageBubble`, `UserAvatar`)

## File Size Limit
- **Warning threshold:** 400 lines
- **Action:** Split into multiple files if exceeded
```

### 14.2 Architectural Patterns

```markdown
# Architectural Patterns

## Clean Architecture

### Layer Structure
```
Presentation → Domain ← Data
     ↓           ↓        ↓
   BLoCs    UseCases  Repositories
     ↓           ↓        ↓
  Widgets   Entities   Models
```

### Dependency Rule
- **Inner layers** (Domain) don't know about **outer layers** (Presentation, Data)
- **Outer layers** depend on **inner layers**
- **Domain** is pure Dart (no Flutter, no infrastructure)

### Layer Responsibilities

**Presentation Layer:**
- UI components (widgets, pages)
- State management (BLoCs)
- User interaction handling
- Navigation

**Domain Layer:**
- Business entities
- Business logic (UseCases)
- Repository interfaces
- Pure Dart only

**Data Layer:**
- Data models (with JSON serialization)
- Data sources (remote and local)
- Repository implementations
- API integration

**Core Layer:**
- Infrastructure services
- Dependency injection
- Network configuration
- Storage configuration

## Repository Pattern

### Interface (Domain)
```dart
abstract class IMessageRepository {
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    required int page,
    required int limit,
  });
  
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String content,
  });
}
```

### Implementation (Data)
```dart
@LazySingleton(as: IMessageRepository)
class MessageRepositoryImpl implements IMessageRepository {
  final IMessageRemoteDataSource _remoteDataSource;
  final IMessageLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  
  // Implementation with offline-first logic
}
```

## BLoC Pattern

### Event-Driven State Management
```dart
// Event
@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.messageReceived(Message message) = ChatMessageReceived;
  const factory ChatEvent.messageSent(String content) = ChatMessageSent;
}

// State
@freezed
class ChatState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading() = ChatLoading;
  const factory ChatState.loaded(List<Message> messages) = ChatLoaded;
  const factory ChatState.error(Failure failure) = ChatError;
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(const ChatState.initial()) {
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMessageSent>(_onMessageSent);
  }
}
```

## Offline-First Pattern

### Data Flow
```
1. Check network connectivity
2. If online:
   - Fetch from remote
   - Cache locally
   - Return data
3. If offline:
   - Return cached data
   - Queue operations for sync
4. When back online:
   - Process sync queue
   - Update cache
```

### Implementation
```dart
Future<Either<Failure, List<Message>>> getMessages() async {
  if (await _networkInfo.isConnected) {
    // Online: fetch from remote and cache
    final messages = await _remoteDataSource.getMessages();
    await _localDataSource.cacheMessages(messages);
    return Right(messages.map((m) => m.toEntity()).toList());
  } else {
    // Offline: return cached data
    final cachedMessages = await _localDataSource.getCachedMessages();
    return Right(cachedMessages.map((m) => m.toEntity()).toList());
  }
}
```

## Dependency Injection

### GetIt + Injectable
```dart
// Register dependencies
@injectable
class MyService { }

@lazySingleton
class MySingleton { }

// Configure
@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
}

// Use
final service = getIt<MyService>();
```

### Constructor Injection
```dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final IMessageRepository _repository;
  final IConversationRepository _conversationRepository;
  
  ChatBloc({
    required IMessageRepository repository,
    required IConversationRepository conversationRepository,
  }) : _repository = repository,
       _conversationRepository = conversationRepository,
       super(const ChatState.initial());
}
```
```

### 14.3 Code Organization Patterns

```markdown
# Code Organization Patterns

## Feature-Based Structure

### Group by Feature, Not by Type
```
✅ GOOD:
lib/
├── presentation/
│   ├── auth/
│   │   ├── blocs/
│   │   ├── pages/
│   │   └── widgets/
│   └── chat/
│       ├── blocs/
│       ├── pages/
│       └── widgets/

❌ BAD:
lib/
├── blocs/
│   ├── auth_bloc.dart
│   └── chat_bloc.dart
├── pages/
│   ├── login_page.dart
│   └── chat_page.dart
```

## Separation of Concerns

### Single Responsibility Principle
```dart
// ✅ GOOD: Each class has one responsibility
class GetUserMessages {
  Future<Either<Failure, List<Message>>> call() { }
}

class SendMessage {
  Future<Either<Failure, Message>> call() { }
}

// ❌ BAD: One class doing too much
class MessageService {
  Future<List<Message>> getMessages() { }
  Future<Message> sendMessage() { }
  Future<void> deleteMessage() { }
  Future<void> editMessage() { }
  // Too many responsibilities!
}
```

## Interface-Based Abstractions

### Depend on Abstractions, Not Implementations
```dart
// ✅ GOOD: Depend on interface
class ChatBloc {
  final IMessageRepository _repository; // Interface
  
  ChatBloc({required IMessageRepository repository})
      : _repository = repository;
}

// ❌ BAD: Depend on implementation
class ChatBloc {
  final MessageRepositoryImpl _repository; // Implementation
  
  ChatBloc({required MessageRepositoryImpl repository})
      : _repository = repository;
}
```

## Error Handling with Either

### Functional Error Handling
```dart
// ✅ GOOD: Use Either<Failure, T>
Future<Either<Failure, User>> login(String email, String password) async {
  try {
    final user = await _remoteDataSource.login(email, password);
    return Right(user.toEntity());
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message));
  }
}

// ❌ BAD: Throw exceptions
Future<User> login(String email, String password) async {
  final user = await _remoteDataSource.login(email, password);
  return user.toEntity(); // What if it fails?
}
```
```

### 14.4 Anti-Patterns to Avoid

```markdown
# Anti-Patterns to Avoid

## 1. Relative Imports

```dart
// ❌ BAD: Relative imports
import '../../domain/entities/user.dart';
import '../../../core/error/failures.dart';

// ✅ GOOD: Package imports
import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
```

## 2. Using print() for Logging

```dart
// ❌ BAD: Using print()
print('User logged in');
print('Error: $error');

// ✅ GOOD: Using Logger
logger.info('User logged in');
logger.error('Error occurred', error: error);
```

## 3. Hardcoded Strings

```dart
// ❌ BAD: Hardcoded UI strings
Text('Welcome to the app');
Text('Login failed');

// ✅ GOOD: Localized strings
Text(context.l10n.welcomeMessage);
Text(context.l10n.loginFailed);
```

## 4. Null Assertion Operator (!)

```dart
// ❌ BAD: Null assertion
final value = nullableValue!; // Can crash!

// ✅ GOOD: Null-safe operators
final value = nullableValue ?? defaultValue;
final result = nullableObject?.method();
```

## 5. Type Casting with 'as'

```dart
// ❌ BAD: Type casting
final str = object as String; // Can crash!

// ✅ GOOD: Type checking
if (object is String) {
  final str = object; // Smart cast
}
```

## 6. setState in Presentation Layer

```dart
// ❌ BAD: Using setState for business logic
setState(() {
  messages.add(newMessage);
});

// ✅ GOOD: Using BLoC
context.read<ChatBloc>().add(ChatEvent.messageReceived(newMessage));
```

## 7. Layer Violations

```dart
// ❌ BAD: Domain importing Flutter
// lib/domain/entities/user.dart
import 'package:flutter/material.dart'; // ERROR!

// ❌ BAD: Presentation importing Data models
// lib/presentation/pages/home_page.dart
import 'package:flutter_chat_app/data/models/user_model.dart'; // ERROR!

// ✅ GOOD: Proper layer separation
// lib/presentation/pages/home_page.dart
import 'package:flutter_chat_app/domain/entities/user.dart'; // OK!
```

## 8. Broad Exception Catching

```dart
// ❌ BAD: Catching all exceptions
try {
  await someOperation();
} catch (e) {
  // Too broad!
}

// ✅ GOOD: Specific exception handling
try {
  await someOperation();
} on ServerException catch (e) {
  // Handle server error
} on NetworkException catch (e) {
  // Handle network error
} catch (e) {
  // Handle unexpected error
  logger.error('Unexpected error', error: e);
}
```

## 9. Missing const Constructors

```dart
// ❌ BAD: Missing const
class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key);
}

// ✅ GOOD: Using const
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
}
```

## 10. Mutable State in Entities

```dart
// ❌ BAD: Mutable entity
class User {
  String id;
  String name;
  
  User({required this.id, required this.name});
}

// ✅ GOOD: Immutable entity
class User {
  final String id;
  final String name;
  
  const User({required this.id, required this.name});
  
  User copyWith({String? id, String? name}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
```
```

### 14.5 Pattern Examples

**Create example implementations for common patterns:**

1. **BLoC Example:** `.kiro/specs/foundation-setup/examples/bloc_example.dart`
2. **UseCase Example:** `.kiro/specs/foundation-setup/examples/usecase_example.dart`
3. **Repository Example:** `.kiro/specs/foundation-setup/examples/repository_example.dart`
4. **Widget Example:** `.kiro/specs/foundation-setup/examples/widget_example.dart`

These examples should be created as reference implementations that follow all best practices.

## Task 15: Review Clean Architecture Principles

### 15.1 Explain Layer Dependencies

**The Dependency Rule:**

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (BLoCs, Pages, Widgets)           │
│         Depends on ↓                │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│          Domain Layer               │
│  (Entities, UseCases, Interfaces)  │
│      Pure Dart - No Dependencies    │
└─────────────────────────────────────┘
              ↑
┌─────────────────────────────────────┐
│           Data Layer                │
│  (Models, DataSources, Repos)      │
│         Depends on ↑                │
└─────────────────────────────────────┘
```

**Key Principles:**
1. **Inner layers** don't know about **outer layers**
2. **Domain** is the core - pure business logic
3. **Presentation** and **Data** depend on **Domain**
4. **Domain** has no dependencies on infrastructure

**Example:**
```dart
// ✅ CORRECT: Presentation depends on Domain
// lib/presentation/blocs/auth/auth_bloc.dart
import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:flutter_chat_app/domain/repositories/auth_repository.dart';

// ✅ CORRECT: Data depends on Domain
// lib/data/repositories/auth_repository_impl.dart
import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:flutter_chat_app/domain/repositories/auth_repository.dart';

// ❌ WRONG: Domain depends on Presentation
// lib/domain/entities/user.dart
import 'package:flutter/material.dart'; // ERROR!

// ❌ WRONG: Domain depends on Data
// lib/domain/usecases/get_user.dart
import 'package:flutter_chat_app/data/models/user_model.dart'; // ERROR!
```

### 15.2 Review Layer Responsibilities

**Presentation Layer:**
- **Purpose:** User interface and user interaction
- **Components:**
  - BLoCs (state management)
  - Pages (full-screen views)
  - Widgets (reusable UI components)
- **Responsibilities:**
  - Display data to user
  - Handle user input
  - Manage UI state
  - Navigate between screens
- **Dependencies:** Domain layer only
- **No:** Business logic, data fetching, storage

**Domain Layer:**
- **Purpose:** Business logic and rules
- **Components:**
  - Entities (business objects)
  - UseCases (business operations)
  - Repository interfaces (data contracts)
- **Responsibilities:**
  - Define business entities
  - Implement business logic
  - Define data contracts
- **Dependencies:** None (pure Dart)
- **No:** UI code, database code, network code

**Data Layer:**
- **Purpose:** Data management and persistence
- **Components:**
  - Models (data transfer objects)
  - Data sources (remote and local)
  - Repository implementations
- **Responsibilities:**
  - Fetch data from API
  - Store data locally
  - Implement repository interfaces
  - Handle data serialization
- **Dependencies:** Domain layer only
- **No:** UI code, business logic

**Core Layer:**
- **Purpose:** Infrastructure and cross-cutting concerns
- **Components:**
  - Dependency injection
  - Network configuration
  - Storage configuration
  - Services (logger, analytics, etc.)
- **Responsibilities:**
  - Configure infrastructure
  - Provide shared services
  - Manage dependencies
- **Dependencies:** Can depend on all layers
- **No:** Business logic, UI code

### 15.3 Identify Layer Violations

**Common violations to check:**

```bash
# Check for Flutter imports in domain layer
grep -r "import 'package:flutter" flutter_chat_app/lib/domain/

# Check for data model imports in presentation layer
grep -r "import.*data/models" flutter_chat_app/lib/presentation/

# Check for relative imports
grep -r "import '\.\." flutter_chat_app/lib/
```

**Document violations:**
```markdown
# Layer Violations Found

## Violation 1: Domain importing Flutter
- **File:** `lib/domain/entities/user.dart`
- **Line:** 3
- **Issue:** `import 'package:flutter/material.dart';`
- **Fix:** Remove Flutter import, use pure Dart

## Violation 2: Presentation importing Data model
- **File:** `lib/presentation/pages/home_page.dart`
- **Line:** 5
- **Issue:** `import 'package:flutter_chat_app/data/models/user_model.dart';`
- **Fix:** Import domain entity instead: `import 'package:flutter_chat_app/domain/entities/user.dart';`

## Total Violations: [Number]
```

### 15.4 Quiz Team on Clean Architecture

**Quiz questions for team members:**

1. **What are the three main layers in Clean Architecture?**
   - Answer: Presentation, Domain, Data

2. **Which layer contains business logic?**
   - Answer: Domain layer

3. **Can the Domain layer import Flutter packages?**
   - Answer: No, Domain must be pure Dart

4. **What is the Dependency Rule?**
   - Answer: Inner layers don't know about outer layers

5. **Where do BLoCs belong?**
   - Answer: Presentation layer

6. **Where do Entities belong?**
   - Answer: Domain layer

7. **Where do Models belong?**
   - Answer: Data layer

8. **Can Presentation layer import Data models directly?**
   - Answer: No, should import Domain entities

9. **What is the purpose of repository interfaces?**
   - Answer: Define data contracts in Domain, implemented in Data

10. **Why do we use Clean Architecture?**
    - Answer: Separation of concerns, testability, maintainability, scalability

**Conduct quiz:**
- Each team member answers questions
- Discuss answers as a team
- Clarify any misunderstandings
- Document quiz results

## Task 16: Establish Code Review Process

### 16.1 Define Code Review Workflow

```markdown
# Code Review Workflow

## Step 1: Developer Creates Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/phase-1-implement-usecases
```

## Step 2: Developer Implements Feature
- Write code following patterns
- Add unit tests
- Run linting and tests locally
- Commit with descriptive messages

## Step 3: Developer Creates Pull Request
- Push branch to remote
- Create PR on GitHub/GitLab
- Fill out PR template:
  - Description of changes
  - Related issue/task
  - Testing performed
  - Screenshots (if UI changes)

## Step 4: CI/CD Runs Automatically
- `flutter analyze` (linting)
- `flutter test` (unit tests)
- Build verification
- PR cannot be merged if CI fails

## Step 5: Reviewer(s) Review Code
- Check code quality
- Check architecture compliance
- Check test coverage
- Leave comments and suggestions
- Request changes if needed

## Step 6: Developer Addresses Feedback
- Make requested changes
- Push updates to same branch
- Respond to comments
- Request re-review

## Step 7: Reviewer Approves
- Verify all feedback addressed
- Approve PR
- PR is ready to merge

## Step 8: Code is Merged
- Merge to develop branch
- Delete feature branch
- Close related issue/task
```

### 16.2 Create Code Review Checklist

**Already created comprehensive checklist in project-architecture.md, but create PR template:**

