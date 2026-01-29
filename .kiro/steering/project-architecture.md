---
inclusion: always
---

# Project Architecture & Guidelines

## Critical Architecture Rules

**MANDATORY - Clean Architecture with strict layer separation:**

1. **Domain Layer Isolation**: NEVER import Flutter/infrastructure packages in `lib/domain/`
2. **Presentation Layer**: NEVER import data models directly - use domain entities only
3. **Error Handling**: ALWAYS use `Either<Failure, T>` pattern for operations that can fail
4. **Logging**: NEVER use `print()` - ALWAYS use Logger service
5. **Code Generation**: ALWAYS run `dart run build_runner build --delete-conflicting-outputs` after modifying models, BLoCs, or DI annotations
6. **Base Classes**: ALWAYS extend base classes (`BaseBloc`, `BaseState`, `BaseStatefulWidget`, `BaseStatelessWidget`)
7. **Design System**: ALWAYS use design system components (`AppText`, `AppButton`, etc.) - NEVER use Flutter widgets directly
8. **Internationalization**: ALWAYS use `context.l10n` for user-facing text - NEVER hardcode strings

## Mandatory Base Classes

**ALL code MUST use these base classes. NO exceptions.**

### 1. BLoC - MUST Extend BaseBloc

```dart
// ✅ CORRECT
@injectable
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  final IRepository _repository;
  final Logger _logger;
  
  ChatBloc({
    required IRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger,
       super(const ChatState.initial()) {
    on<ChatEvent>(_onEvent);
  }
}

// ❌ FORBIDDEN
class ChatBloc extends Bloc<ChatEvent, ChatState> { }
```

**BaseBloc provides:**
- Automatic error handling and logging
- Performance monitoring and analytics
- Crash reporting integration
- Helper methods: `emitLoading()`, `emitError()`, `emitSuccess()`

### 2. State - MUST Extend BaseState

```dart
// ✅ CORRECT
@freezed
class ChatState extends BaseState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading({String? message}) = ChatLoading;
  const factory ChatState.loaded({required Data data}) = ChatLoaded;
  const factory ChatState.error({required String message}) = ChatError;
}

// ❌ FORBIDDEN
abstract class ChatState extends Equatable { }
```

### 3. StatefulWidget - MUST Extend BaseStatefulWidget

```dart
// ✅ CORRECT
class MyWidget extends BaseStatefulWidget {
  const MyWidget({super.key});
  
  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends BaseState<MyWidget> {
  @override
  void onAppResumed() { }
  
  void _update() {
    safeSetState(() { }); // Use safeSetState, not setState
  }
  
  @override
  Widget build(BuildContext context) => Container();
}

// ❌ FORBIDDEN
class MyWidget extends StatefulWidget { }
```

### 4. StatelessWidget - MUST Extend BaseStatelessWidget

```dart
// ✅ CORRECT
class MyWidget extends BaseStatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget buildContent(BuildContext context) => Container();
}

// ❌ FORBIDDEN
class MyWidget extends StatelessWidget { }
```

### 5. Design System Components - MANDATORY

```dart
// ✅ CORRECT
AppText(context.l10n.title, style: AppTextStyle.headlineLarge)
AppButton(label: context.l10n.save, onPressed: _save)
AppTextField(label: context.l10n.email, controller: _controller)
AppListView(items: items, itemBuilder: (item) => ...)

// ❌ FORBIDDEN
Text('Title')
ElevatedButton(child: Text('Save'), onPressed: _save)
TextField(decoration: InputDecoration(labelText: 'Email'))
ListView.builder(itemBuilder: (context, index) => ...)
```

### 6. Localization - MANDATORY

```dart
// ✅ CORRECT
AppText(context.l10n.welcome)
AppButton(label: context.l10n.save)
errorText: context.l10n.fieldRequired

// ❌ FORBIDDEN
AppText('Welcome')
AppButton(label: 'Save')
errorText: 'This field is required'
```

---

## Project Structure

**Monorepo with 2 applications:**
- **Backend**: NestJS (TypeScript) - `src/`
- **Frontend**: Flutter (Dart) - `flutter_chat_app/`

---

## Flutter Application Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│  Presentation (UI + BLoC)               │  ← User interaction
├─────────────────────────────────────────┤
│  Domain (Entities + UseCases)           │  ← Business logic
├─────────────────────────────────────────┤
│  Data (Models + Repositories + Sources) │  ← Data access
└─────────────────────────────────────────┘
```

**Data Flow**: `User Action → BLoC Event → UseCase → Repository → DataSource → API`

### Core Principles

- **Offline-First**: Isar database with sync queue for offline operations
- **State Management**: BLoC pattern with `Either<Failure, T>` error handling
- **Dependency Injection**: GetIt + Injectable (`@injectable`, `@singleton`, `@lazySingleton`)
- **Real-time Communication**: Socket.IO with EnhancedSocketManager
- **Multi-Platform**: Separate entry points for Mobile, Web, Desktop
- **Multi-Flavor**: Staging and Production configurations via FlavorConfig

### Directory Structure

```
flutter_chat_app/lib/
├── core/              # Infrastructure (DI, network, storage, base classes)
├── data/              # Data layer (models, datasources, repository implementations)
├── domain/            # Business logic (entities, usecases, repository interfaces)
├── presentation/      # UI layer (blocs, pages, widgets)
├── config/            # App configuration (routes, themes, constants)
└── main*.dart         # Entry points (main.dart, main_staging.dart, main_production.dart)
```

### Naming Conventions

**Flutter (Dart):**
- Files: `snake_case.dart` (e.g., `user_repository.dart`, `chat_page.dart`)
- Classes: `PascalCase` (e.g., `UserRepository`, `ChatBloc`)
- Variables/Methods: `camelCase` (e.g., `getUserMessages`, `isLoading`)
- Constants: `camelCase` or `SCREAMING_SNAKE_CASE` (e.g., `kDefaultPadding`, `API_KEY`)
- Private members: `_prefixWithUnderscore` (e.g., `_repository`, `_handleEvent`)
- Repository interfaces: No suffix (e.g., `IAuthRepository`)
- Repository implementations: `Impl` suffix (e.g., `AuthRepositoryImpl`)
- Use cases: Action verb + noun (e.g., `GetUserMessages`, `SendMessage`)
- BLoCs: Feature + `Bloc` (e.g., `AuthBloc`, `ChatBloc`)
- Widgets: Descriptive name, no suffix (e.g., `MessageBubble`, `UserAvatar`)
- Pages: Feature + `Page` (e.g., `ChatDetailPage`, `LoginPage`)

**Backend (TypeScript):**
- Files: `kebab-case.ts` (e.g., `user.service.ts`, `auth.module.ts`)
- Classes: `PascalCase` (e.g., `UserService`, `AuthModule`)
- Variables/Methods: `camelCase` (e.g., `findUserById`, `isAuthenticated`)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `MAX_RETRY_ATTEMPTS`)
- Private members: `private` keyword (e.g., `private readonly userRepo`)

### Flutter Code Style Rules

**MANDATORY BASE CLASSES:**
- **BLoCs**: MUST extend `BaseBloc<Event, State>`, NOT `Bloc`
- **States**: MUST extend `BaseState` with `@freezed`
- **StatefulWidgets**: MUST extend `BaseStatefulWidget`
- **StatelessWidgets**: MUST extend `BaseStatelessWidget`
- **Cubits**: MUST extend `BaseCubit<State>`

**ALWAYS:**
- Use `const` constructors wherever possible for performance
- Use package imports: `import 'package:flutter_chat_app/core/...'`
- Use single quotes for strings: `'Hello'`
- Annotate types for public APIs: `final String name = 'John'`
- Use Logger service: `logger.i('User logged in')`
- Use null-safe operators: `value ?? defaultValue`, `object?.method()`
- Use type checking with `is`: `if (object is String) { }`
- Prefer `final` over `var` for immutable variables
- Dispose resources in `close()` or `dispose()` methods
- Use design system components: `AppText`, `AppButton`, `AppTextField`
- Use localization: `context.l10n.keyName` for ALL user-facing text

**NEVER:**
- Use relative imports: `import '../../core/...'`
- Use double quotes for strings: `"Hello"`
- Use `print()` or `debugPrint()` - use Logger instead
- Use null assertion operator `!` - use null-safe operators
- Use type casting with `as` - use `is` checks with smart casts
- Use `var` for variables that won't be reassigned
- Extend `Bloc` directly - use `BaseBloc`
- Extend `StatefulWidget` directly - use `BaseStatefulWidget`
- Extend `StatelessWidget` directly - use `BaseStatelessWidget`
- Use `Text` widget - use `AppText`
- Use Flutter widgets directly - use design system components
- Hardcode strings - use `context.l10n`

**Example:**
```dart
// ✅ CORRECT
class MyWidget extends BaseStatefulWidget {
  const MyWidget({super.key});
  
  @override
  MyWidgetState createState() => MyWidgetState();
}

import 'package:flutter_chat_app/core/base/base_widget.dart';

final String message = 'Hello';
final value = nullableValue ?? defaultValue;

if (object is String) {
  print(object.toUpperCase()); // Smart cast works
}

logger.i('Operation completed');

// ❌ WRONG
class MyWidget extends StatefulWidget { } // Use BaseStatefulWidget

import '../../core/base/base_widget.dart'; // Use package imports

final String message = "Hello"; // Use single quotes

final value = nullableValue!; // Avoid null assertion

final str = object as String; // Use 'is' check instead

print('Operation completed'); // Use logger
```

---

## State Management with BLoC Pattern

### MANDATORY Base Classes

**CRITICAL: All BLoCs MUST extend `BaseBloc`, NOT `Bloc` directly.**

```dart
// ✅ CORRECT - Extend BaseBloc
@injectable
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  final IMessageRepository _repository;
  final Logger _logger;
  
  ChatBloc({
    required IMessageRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger,
       super(const ChatState.initial()) {
    on<ChatMessageSent>(_onMessageSent);
  }
  
  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    // Use BaseBloc helper methods
    emitLoading(message: 'Sending message...');
    
    final result = await _repository.sendMessage(event.message);
    
    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (message) => emit(ChatState.messageSent(message)),
    );
  }
}

// ❌ WRONG - Don't extend Bloc directly
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // Missing: error handling, logging, analytics, performance monitoring
}
```

**BaseBloc provides:**
- Automatic error handling and logging
- Performance monitoring
- Analytics integration
- Crash reporting
- Lifecycle management
- Helper methods: `emitLoading()`, `emitError()`, `emitSuccess()`

### MANDATORY State Pattern

**CRITICAL: All States MUST extend `BaseState` and use Freezed.**

```dart
// ✅ CORRECT - Extend BaseState with Freezed
@freezed
class ChatState extends BaseState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading({String? message}) = ChatLoading;
  const factory ChatState.loaded({
    required List<Message> messages,
  }) = ChatLoaded;
  const factory ChatState.messageSent({
    required Message message,
  }) = ChatMessageSent;
  const factory ChatState.error({
    required String message,
    Object? error,
    VoidCallback? retryAction,
  }) = ChatError;
}

// ❌ WRONG - Don't use Equatable or plain classes
abstract class ChatState extends Equatable {
  const ChatState();
}

class ChatInitial extends ChatState {
  @override
  List<Object> get props => [];
}
```

### When to Use BLoC vs Cubit

**Use BLoC when:**
- Complex business logic with multiple event types
- Need to track/transform events
- Multiple events can lead to the same state
- Need event history or debugging
- **MUST extend `BaseBloc`**

**Use Cubit when:**
- Simple state changes (counters, toggles)
- Direct state mutations without events
- Less boilerplate needed
- **MUST extend `BaseCubit`**

### BLoC Event Pattern (Freezed)

**Events define user actions and system events:**

```dart
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = AuthLoginRequested;
  
  const factory AuthEvent.logoutRequested() = AuthLogoutRequested;
  const factory AuthEvent.checkAuthStatus() = AuthCheckRequested;
  const factory AuthEvent.tokenRefreshed({
    required String token,
  }) = AuthTokenRefreshed;
}
```

### BLoC State Pattern (Freezed)

**States MUST extend BaseState:**

```dart
@freezed
class AuthState extends BaseState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading({String? operation}) = AuthLoading;
  const factory AuthState.authenticated({
    required User user,
    required bool isOnboarded,
  }) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error({
    required Failure failure,
    required String operation,
    VoidCallback? retryAction,
  }) = AuthError;
}
```

### BLoC Implementation Pattern

**MUST extend BaseBloc:**

```dart
@injectable
class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  final IAuthRepository _repository;
  final Logger _logger;
  
  AuthBloc({
    required IAuthRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger,
       super(const AuthState.initial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckAuthStatus);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Use BaseBloc helper method
    emitLoading(message: 'Logging in...');
    
    _logger.i('Login attempt for: ${event.email}');
    
    final result = await _repository.login(event.email, event.password);
    
    result.fold(
      (failure) {
        _logger.e('Login failed', error: failure);
        emitError(
          failure.message,
          error: failure,
          retryAction: () => add(event),
        );
      },
      (user) {
        _logger.i('Login successful', data: {'userId': user.id});
        emit(AuthState.authenticated(user: user, isOnboarded: true));
      },
    );
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emitLoading(message: 'Logging out...');
    
    final result = await _repository.logout();
    
    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }
  
  @override
  Future<void> close() {
    // Cleanup resources
    _logger.d('AuthBloc closed');
    return super.close();
  }
}
```

### Cubit Pattern (Simpler Alternative)

**MUST extend BaseCubit:**

```dart
@injectable
class CounterCubit extends BaseCubit<int> {
  final Logger _logger;
  
  CounterCubit({required Logger logger})
      : _logger = logger,
        super(0);
  
  void increment() {
    _logger.d('Counter incremented');
    emit(state + 1);
  }
  
  void decrement() {
    _logger.d('Counter decremented');
    emit(state - 1);
  }
  
  void reset() {
    _logger.d('Counter reset');
    emit(0);
  }
}
```

### Widget Integration Patterns

**1. BlocProvider - Provides BLoC to widget tree:**

```dart
BlocProvider(
  create: (context) => getIt<AuthBloc>()..add(const AuthEvent.checkAuthStatus()),
  child: const AuthPage(),
)
```

**2. BlocBuilder - Rebuilds UI on state changes:**

```dart
```dart
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (prev, current) => prev != current,
  builder: (context, state) {
    return state.when(
      initial: () => const LoadingIndicator(),
      loading: (operation) => const LoadingIndicator(),
      authenticated: (user, isOnboarded) => HomePage(user: user),
      unauthenticated: () => const LoginPage(),
      error: (failure, operation, retry) => ErrorView(
        message: failure.message,
        onRetry: retry,
      ),
    );
  },
)
```

**3. BlocListener - For side effects (navigation, snackbars):**

```dart
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    state.whenOrNull(
      error: (failure, operation, retry) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
    );
  },
  child: const AuthPage(),
)
```

**4. BlocConsumer - Combines Builder + Listener:**

```dart
```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    // Handle side effects
  },
  builder: (context, state) {
    // Build UI
  },
)
```

**5. BlocSelector - Rebuild only when specific value changes:**

```dart
```dart
BlocSelector<ChatBloc, ChatState, bool>(
  selector: (state) => state.isLoading,
  builder: (context, isLoading) {
    return isLoading ? const LoadingIndicator() : const SizedBox();
  },
)
```

### Stream Integration with BLoC

**Handle real-time streams in BLoC:**

```dart
@injectable
class MessageBloc extends BaseBloc<MessageEvent, MessageState> {
  final IChatService _chatService;
  final Logger _logger;
  late final StreamSubscription<Message> _messageSubscription;
  
  MessageBloc({
    required IChatService chatService,
    required Logger logger,
  }) : _chatService = chatService,
       _logger = logger,
       super(const MessageState.initial()) {
    // Subscribe to real-time message stream
    _messageSubscription = _chatService.messageStream.listen(
      (message) {
        _logger.d('New message received', data: {'messageId': message.id});
        add(MessageEvent.received(message));
      },
      onError: (error) {
        _logger.e('Message stream error', error: error);
        emitError('Failed to receive messages', error: error);
      },
    );
    
    on<MessageReceivedEvent>(_onMessageReceived);
  }
  
  Future<void> _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;
    if (currentState is MessageLoaded) {
      emit(MessageLoaded(
        messages: [...currentState.messages, event.message],
      ));
    }
  }
  
  @override
  Future<void> close() {
    _messageSubscription.cancel(); // CRITICAL: Always cleanup
    _logger.d('MessageBloc closed, subscription cancelled');
    return super.close();
  }
}
```

---

## Error Handling Pattern

### Failure Classes (Domain Layer)

Define failures in `lib/core/error/failures.dart`:
```dart
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
```

### Exception Classes (Data Layer)

Define exceptions in `lib/core/error/exceptions.dart`:
```dart
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
```

### Repository Error Handling Pattern

**Key Steps:**
1. Check network connectivity first
2. Try remote data source
3. Cache successful results locally
4. Convert exceptions to failures
5. Return `Either<Failure, T>`

```dart
```dart
@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;
  final IAuthLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  
  AuthRepositoryImpl({
    required IAuthRemoteDataSource remoteDataSource,
    required IAuthLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;
  
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    
    try {
      final userModel = await _remoteDataSource.login(email, password);
      await _localDataSource.cacheUser(userModel);
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }
}
```

### BLoC Error Handling Pattern
```dart
Future<void> _onLoginRequested(
  AuthLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthState.loading(operation: 'login'));
  
  try {
    final result = await _repository.login(event.email, event.password);
    
    result.fold(
      (failure) {
        // Log error for analytics
        logger.e('Login failed', error: failure);
        
        // Emit error state with retry action
        emit(AuthState.error(
          failure: failure,
          operation: 'login',
          retryAction: () => add(event),
        ));
      },
      (user) {
        // Log success
        logger.i('Login successful', data: {'userId': user.id});
        
        emit(AuthState.authenticated(
          user: user,
          isOnboarded: true,
        ));
      },
    );
  } catch (exception, stackTrace) {
    // Catch unexpected errors
    logger.e('Unexpected login error', error: exception, stackTrace: stackTrace);
    
    emit(AuthState.error(
      failure: UnexpectedFailure(
        message: 'An unexpected error occurred',
        code: 'unexpected_login_error',
      ),
      operation: 'login',
      retryAction: () => add(event),
    ));
  }
}
```

**UI Error Display:**
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    state.whenOrNull(
      error: (failure, operation, retry) {
        // Show user-friendly error message
        final message = _getUserFriendlyMessage(failure);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: retry != null
                ? SnackBarAction(
                    label: 'Retry',
                    onPressed: retry,
                  )
                : null,
          ),
        );
      },
    );
  },
  child: const AuthPage(),
)

String _getUserFriendlyMessage(Failure failure) {
  if (failure is NetworkFailure) {
    return context.l10n.errorNoInternet;
  } else if (failure is ServerFailure) {
    return context.l10n.errorServer;
  } else if (failure is ValidationFailure) {
    return failure.message; // Already user-friendly
  } else {
    return context.l10n.errorUnexpected;
  }
}
```
```dart
// Domain interface
abstract class IAuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, bool>> isLoggedIn();
}

// Data implementation
@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;
  final IAuthLocalDataSource _localDataSource;
  
  AuthRepositoryImpl({
    required IAuthRemoteDataSource remoteDataSource,
    required IAuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final userModel = await _remoteDataSource.login(email, password);
      await _localDataSource.cacheUser(userModel);
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

### Code Generation
```bash
# Generate code for Isar, Injectable, Freezed
dart run build_runner build --delete-conflicting-outputs

# Generate localization
flutter gen-l10n
```

### Performance Targets
- Startup time: **<2s**
- Memory usage: **<150MB**
- Auth operations: **<100ms**
- Message delivery: **<100ms**
- 60fps UI rendering

## 🔧 Backend NestJS

### Architecture Pattern
**Module-based** với GraphQL-first API

### Key Principles
- **GraphQL**: Code-first với decorators
- **DI**: NestJS built-in (`@Injectable()`)
- **Real-time**: Socket.IO với Redis adapter
- **Multi-database**: PostgreSQL (TypeORM), DynamoDB, Redis
- **Queue**: Bull for background jobs
- **Validation**: class-validator decorators

---

## Backend (NestJS) Architecture

### Key Principles

- **GraphQL-First**: Code-first approach with decorators
- **Dependency Injection**: NestJS built-in `@Injectable()`
- **Real-time**: Socket.IO with Redis adapter
- **Multi-Database**: PostgreSQL (TypeORM), DynamoDB, Redis
- **Background Jobs**: Bull queue system
- **Validation**: class-validator decorators

### Code Style

```typescript
// Service pattern
@Injectable()
export class UserService {
  constructor(
    private readonly userRepo: UserRepository,
    private readonly logger: LoggerService,
  ) {}
  
  async findById(id: string): Promise<User> {
    return this.userRepo.findOne({ where: { id } });
  }
}

// File naming: kebab-case (user.service.ts, auth.module.ts)
// Path aliases: @models/*, @common/*, @core/*, @modules/*
```

### GraphQL Patterns

```typescript
// ObjectType
@ObjectType()
export class User {
  @Field(() => ID)
  id: string;
  
  @Field()
  email: string;
}

// InputType with validation
@InputType()
export class CreateUserInput {
  @Field()
  @IsEmail()
  email: string;
  
  @Field()
  @MinLength(8)
  password: string;
}

// Resolver
@Resolver(() => User)
export class UserResolver {
  constructor(private readonly userService: UserService) {}
  
  @Query(() => User)
  async user(@Args('id') id: string): Promise<User> {
    return this.userService.findById(id);
  }
  
  @Mutation(() => User)
  async createUser(@Args('input') input: CreateUserInput): Promise<User> {
    return this.userService.create(input);
  }
}
```

### Path Aliases

```
@common/*      → src/common/*
@models/*      → src/models/*
@core/*        → src/modules/core/*
@modules/*     → src/modules/*
@services/*    → src/services/*
```

---

## Communication & Data Flow

### Flutter ↔ Backend Communication

1. **GraphQL**: HTTP queries/mutations for data operations
2. **Socket.IO**: Real-time bidirectional events
3. **Firebase**: Shared services (Auth, Storage, Push Notifications)

### Data Flow Pattern

```
User Action → BLoC Event → UseCase → Repository → DataSource → API
                ↓
            State Update → UI Rebuild
```

### Offline-First Flow

```
1. Check network connectivity
2. If offline: Save to Isar DB + Add to sync queue
3. When online: Process sync queue
4. Handle conflicts with last-write-wins or custom strategy
```

---

## Adding New Features

### Flutter Feature Checklist

**Follow this order:**

1. **Domain Layer** (Business logic - no dependencies on Flutter/infrastructure)
   - Create entity: `lib/domain/entities/my_feature.dart`
   - Create repository interface: `lib/domain/repositories/i_my_feature_repository.dart`
   - Create use cases: `lib/domain/usecases/my_feature/get_my_feature.dart`

2. **Data Layer** (Implementation details)
   - Create model with mapper: `lib/data/models/my_feature_model.dart`
   - Create remote data source: `lib/data/datasources/my_feature_remote_datasource.dart`
   - Create local data source: `lib/data/datasources/my_feature_local_datasource.dart`
   - Implement repository: `lib/data/repositories/my_feature_repository_impl.dart`

3. **Presentation Layer** (UI and state management)
   - Create BLoC: `lib/presentation/blocs/my_feature/my_feature_bloc.dart`
   - Create events: `lib/presentation/blocs/my_feature/my_feature_event.dart`
   - Create states: `lib/presentation/blocs/my_feature/my_feature_state.dart`
   - Create page: `lib/presentation/pages/my_feature/my_feature_page.dart`
   - Create widgets: `lib/presentation/widgets/my_feature/`

4. **Configuration**
   - Register in DI: `lib/core/di/enterprise_injection.dart`
   - Add localization strings: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
   - Update routing if needed: `lib/config/route/app_router.dart`

5. **Code Generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   flutter gen-l10n
   ```

6. **Testing**
   - Unit tests for use cases and repositories
   - BLoC tests with bloc_test package
   - Widget tests for UI components

### Backend Module Checklist

1. Create module directory: `src/modules/my-feature/`
2. Create files:
   - `my-feature.module.ts` - Module definition
   - `my-feature.service.ts` - Business logic
   - `my-feature.resolver.ts` - GraphQL resolver
   - `my-feature.args.ts` - Input types
   - `my-feature.response.ts` - Output types
3. Register in `src/app.module.ts`: `imports: [MyFeatureModule]`

---

## Code Generation

### When to Run

Run code generation after modifying:
- Isar models (`@collection`)
- Freezed classes (`@freezed`)
- Injectable services (`@injectable`, `@singleton`, `@lazySingleton`)
- JSON serializable classes (`@JsonSerializable`)

```bash
# Standard build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild on changes)
dart run build_runner watch --delete-conflicting-outputs

# Clean and rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# Localization
flutter gen-l10n
```

---

## Performance Targets

- **Startup time**: < 2 seconds
- **Memory usage**: < 150MB baseline
- **Auth operations**: < 100ms
- **Message delivery**: < 100ms
- **UI rendering**: 60fps (16ms per frame)

---

## Critical Layer Separation Rules

### FORBIDDEN Imports

```dart
// ❌ Domain layer importing Flutter
// lib/domain/entities/user.dart
import 'package:flutter/material.dart'; // FORBIDDEN

// ❌ Domain layer importing infrastructure
// lib/domain/usecases/get_user.dart
import 'package:http/http.dart'; // FORBIDDEN
import 'package:isar/isar.dart'; // FORBIDDEN

// ❌ Presentation importing data models
// lib/presentation/pages/home_page.dart
import 'package:flutter_chat_app/data/models/user_model.dart'; // FORBIDDEN

// ✅ Presentation importing domain entities
import 'package:flutter_chat_app/domain/entities/user.dart'; // CORRECT
```

### Allowed Imports by Layer

**Domain Layer** (`lib/domain/`):
- ✅ Other domain files
- ✅ `dartz` (for `Either`)
- ✅ `equatable` (for value equality)
- ❌ Flutter packages
- ❌ Data layer
- ❌ Presentation layer
- ❌ Infrastructure (http, database, etc.)

**Data Layer** (`lib/data/`):
- ✅ Domain layer (entities, repository interfaces)
- ✅ Infrastructure packages (http, isar, etc.)
- ✅ JSON serialization packages
- ❌ Flutter UI packages
- ❌ Presentation layer

**Presentation Layer** (`lib/presentation/`):
- ✅ Domain layer (entities, use cases, repository interfaces)
- ✅ Flutter packages
- ✅ BLoC packages
- ❌ Data layer (models, data sources)

---

### Repository Pattern Example

**Domain Interface** (`lib/domain/repositories/i_auth_repository.dart`):
```dart
abstract class IAuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, void>> logout();
}
```

**Data Implementation** (`lib/data/repositories/auth_repository_impl.dart`):
```dart
@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;
  final IAuthLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  
  AuthRepositoryImpl({
    required IAuthRemoteDataSource remoteDataSource,
    required IAuthLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;
  
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    
    try {
      final userModel = await _remoteDataSource.login(email, password);
      await _localDataSource.cacheUser(userModel);
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }
}
```

---

## Testing Patterns

### BLoC Testing with bloc_test
```dart
import 'package:bloc_test/bloc_test.dart';

void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(repository: mockRepository);
  });
  
  tearDown(() {
    authBloc.close();
  });
  
  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when login succeeds',
      build: () {
        when(() => mockRepository.login(any(), any()))
            .thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.loginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthState.loading(operation: 'login'),
        AuthState.authenticated(user: testUser, isOnboarded: true),
      ],
      verify: (_) {
        verify(() => mockRepository.login('test@example.com', 'password123'))
            .called(1);
      },
    );
    
    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when login fails',
      build: () {
        when(() => mockRepository.login(any(), any()))
            .thenAnswer((_) async => const Left(ServerFailure(
              message: 'Invalid credentials',
            )));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.loginRequested(
        email: 'test@example.com',
        password: 'wrong',
      )),
      expect: () => [
        const AuthState.loading(operation: 'login'),
        isA<AuthError>()
            .having((s) => s.failure, 'failure', isA<ServerFailure>())
            .having((s) => s.operation, 'operation', 'login'),
      ],
    );
  });
}
```

### Repository Testing
```dart
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  
  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });
  
  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    final tUserModel = UserModel(id: '1', email: tEmail);
    final tUser = tUserModel.toEntity();
    
    test('should check if device is online', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(any(), any()))
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async => Future.value());
      
      // Act
      await repository.login(tEmail, tPassword);
      
      // Assert
      verify(() => mockNetworkInfo.isConnected).called(1);
    });
    
    test('should return NetworkFailure when device is offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      
      // Act
      final result = await repository.login(tEmail, tPassword);
      
      // Assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.login(any(), any()));
    });
    
    test('should return User when login succeeds', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(any(), any()))
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async => Future.value());
      
      // Act
      final result = await repository.login(tEmail, tPassword);
      
      // Assert
      expect(result, Right(tUser));
      verify(() => mockRemoteDataSource.login(tEmail, tPassword)).called(1);
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });
  });
}
```

### Widget Testing
```dart
void main() {
  testWidgets('LoginPage displays email and password fields', 
      (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => MockAuthBloc(),
          child: const LoginPage(),
        ),
      ),
    );
    
    // Assert
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
  
  testWidgets('LoginPage shows loading indicator when logging in',
      (WidgetTester tester) async {
    // Arrange
    final mockBloc = MockAuthBloc();
    whenListen(
      mockBloc,
      Stream.fromIterable([
        const AuthState.loading(operation: 'login'),
      ]),
      initialState: const AuthState.initial(),
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockBloc,
          child: const LoginPage(),
        ),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

## 📋 Checklists

### Before Committing
- [ ] Run `flutter analyze` - no errors
---

## Pre-Commit Checklist

### Before Committing Code
- [ ] Run `flutter analyze` - no errors
- [ ] Run `dart run build_runner build` if models/BLoCs/DI changed
- [ ] Run tests: `flutter test`
- [ ] No `print()` statements - use Logger
- [ ] No hardcoded UI strings - use `context.l10n`
- [ ] No `!` null assertions - use null-safe operators (`??`, `?.`)
- [ ] No `as` type casts - use `is` checks
- [ ] Verify layer separation - no forbidden imports
- [ ] **All BLoCs extend `BaseBloc`, NOT `Bloc`**
- [ ] **All States extend `BaseState`**
- [ ] **All StatefulWidgets extend `BaseStatefulWidget`**
- [ ] **All StatelessWidgets extend `BaseStatelessWidget`**
- [ ] **All text uses `AppText`, NOT `Text`**
- [ ] **All UI components use design system (`App*`), NOT Flutter widgets**
- [ ] Add/update tests for new features
- [ ] Update documentation if needed

### Code Review Checklist
- [ ] Follows Clean Architecture (domain → data → presentation)
- [ ] No layer violations (check imports)
- [ ] Proper error handling with `Either<Failure, T>`
- [ ] Uses dependency injection (`@injectable`, `@singleton`, `@lazySingleton`)
- [ ] **BLoCs extend `BaseBloc<Event, State>`** ← CRITICAL
- [ ] **States extend `BaseState`** ← CRITICAL
- [ ] **Widgets extend `BaseStatefulWidget` or `BaseStatelessWidget`** ← CRITICAL
- [ ] **Uses `AppText` instead of `Text`** ← CRITICAL
- [ ] **Uses design system components (`App*`)** ← CRITICAL
- [ ] **Uses `context.l10n` for ALL user-facing text** ← CRITICAL
- [ ] **Uses `AppColors` for colors** ← CRITICAL
- [ ] **Uses `AppDimens` for dimensions** ← CRITICAL
- [ ] Has unit tests (use cases, repositories)
- [ ] Has BLoC tests (with `bloc_test` package)
- [ ] Proper null safety
- [ ] Performance optimized (const constructors, efficient rebuilds)
- [ ] Documented public APIs (doc comments)

---

## Quick Reference

### Key Commands

```bash
# Flutter
flutter analyze                                              # Check for errors
flutter test                                                 # Run tests
dart run build_runner build --delete-conflicting-outputs    # Generate code
flutter gen-l10n                                            # Generate localizations
flutter run --flavor staging                                # Run staging flavor
flutter run --flavor production                             # Run production flavor

# Backend
npm run start:dev                                           # Run in development
npm run test                                                # Run tests
npm run build                                               # Build for production
```

### Key Directories

```
flutter_chat_app/lib/
├── core/          # Base classes, DI, network, storage, constants
├── domain/        # Entities, use cases, repository interfaces (NO Flutter imports)
├── data/          # Models, data sources, repository implementations
├── presentation/  # BLoCs, pages, widgets (UI layer)
└── config/        # Routes, themes, app configuration

src/
├── common/        # Shared utilities, constants
├── models/        # TypeORM entities
├── modules/       # Feature modules (GraphQL resolvers, services)
└── services/      # External services (AWS, Redis, etc.)
```

### Key Patterns

**Base Classes (MANDATORY)**:
- BLoCs: `extends BaseBloc<Event, State>` (NOT `Bloc`)
- States: `extends BaseState` with `@freezed`
- StatefulWidgets: `extends BaseStatefulWidget`
- StatelessWidgets: `extends BaseStatelessWidget`
- Cubits: `extends BaseCubit<State>`

**Design System (MANDATORY)**:
- Text: `AppText(context.l10n.text, style: AppTextStyle.bodyMedium)`
- Buttons: `AppButton(label: context.l10n.save, onPressed: _save)`
- Inputs: `AppTextField(label: context.l10n.email, controller: _controller)`
- Lists: `AppListView(items: items, itemBuilder: ...)`
- Cards: `AppCard(child: ...)`

**Error Handling**: `Either<Failure, T>` → `result.fold((failure) => ..., (success) => ...)`

**Localization (MANDATORY)**: `context.l10n.keyName` (NO hardcoded strings)

**Logging**: `logger.i()`, `logger.e()`, `logger.w()` (NO `print()`)

**Colors**: `AppColors.textPrimaryDarkMode`, `AppColors.backgroundDarkMode` (NO `Colors.*`)

**Dimensions**: `AppDimens.paddingMedium`, `AppDimens.spaceSmall` (NO hardcoded numbers)

**DI Annotations**: `@injectable`, `@singleton`, `@lazySingleton`

---

**Document Version**: 2.2  
**Last Updated**: 2025-01-29  
**Maintained By**: Senior Flutter/Mobile Architect
