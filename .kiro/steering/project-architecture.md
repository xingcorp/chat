---
title: Project Architecture & Guidelines
inclusion: always
priority: high
version: 2.0
lastUpdated: 2025-01-27
---

# Sharitek Office Management - Project Architecture

> **Critical Rules**: This project follows **Clean Architecture** with strict layer separation.
> - Domain layer MUST NOT import Flutter/infrastructure packages
> - Presentation layer MUST NOT import data models directly
> - ALWAYS use `Either<Failure, T>` for error handling
> - NEVER use `print()` - use Logger instead
> - ALWAYS run code generation after model changes

## 🏗️ Project Structure

**Monorepo** với 2 ứng dụng chính:
- **Backend**: NestJS (TypeScript) - `src/`
- **Frontend**: Flutter (Dart) - `flutter_chat_app/`

## 📱 Flutter Chat App

### Architecture Pattern
**Clean Architecture** với 3 tầng:
```
Presentation (BLoC) → Domain (UseCases) → Data (Repositories)
```

### Key Principles
- **Offline-first**: Isar database + sync queue
- **State Management**: BLoC pattern với `Either<Failure, T>` error handling
- **DI**: GetIt + Injectable (`@injectable`, `@singleton`, `@lazySingleton`)
- **Real-time**: Socket.IO với EnhancedSocketManager
- **Multi-platform**: Mobile, Web, Desktop (separate entry points)
- **Multi-flavor**: Staging, Production (FlavorConfig)

### Code Style & Conventions

**File Naming:**
- Files: `snake_case.dart` (e.g., `user_repository.dart`, `login_page.dart`)
- Max 400 lines per file (warning threshold)

**Class Naming:**
- Classes: `PascalCase`
- Repository interfaces: `MessageRepository` (no suffix)
- Repository implementations: `MessageRepositoryImpl` (with `Impl`)
- Use cases: `GetUserMessages`, `SendMessage` (action verb + noun)
- BLoCs: `FeatureNameBloc`
- Widgets: `MessageBubble` (no "Widget" suffix)
- Pages: `ChatDetailPage` (with "Page" suffix)

**Code Patterns:**
```dart
// ✅ CORRECT - Widget with const constructor
class MyWidget extends BaseStatefulWidget {
  const MyWidget({super.key});  // ALWAYS use const
  
  @override
  MyWidgetState createState() => MyWidgetState();
}

// ✅ CORRECT - Package imports only
import 'package:flutter_chat_app/core/...';

// ❌ WRONG - Relative imports
import '../../core/...';

// ✅ CORRECT - Single quotes
final String message = 'Hello';

// ❌ WRONG - Double quotes
final String message = "Hello";

// ✅ CORRECT - Type annotations for public APIs
final String name = 'John';

// ❌ WRONG - Missing type annotation
final name = 'John';

// ✅ CORRECT - Use logger
logger.info('User logged in');

// ❌ WRONG - Using print
print('User logged in');

// ✅ CORRECT - Null-safe operators
final value = nullableValue ?? defaultValue;
final result = nullableObject?.method();

// ❌ WRONG - Null assertion operator
final value = nullableValue!;

// ✅ CORRECT - Type checking with is
if (object is String) {
  // Smart cast works here
}

// ❌ WRONG - Type casting with as
final str = object as String;

// ✅ CORRECT - Prefer final
final count = 10;

// ⚠️ WARNING - Use var only if reassigned
var count = 10;
count = 20;
```

### Directory Structure
```
lib/
├── core/              # Infrastructure (DI, network, storage, services)
├── data/              # Data layer (models, datasources, repositories impl)
├── domain/            # Business logic (entities, usecases, repository interfaces)
├── presentation/      # UI (blocs, pages, widgets)
├── config/            # App configuration
└── main*.dart         # Entry points (staging, production, mobile, web, desktop)
```

### BLoC Pattern

**Event Design (using Freezed):**
```dart
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = AuthLoginRequested;
  
  const factory AuthEvent.logoutRequested() = AuthLogoutRequested;
  
  const factory AuthEvent.checkAuthStatus() = AuthCheckRequested;
}
```

**State Design (using Freezed):**
```dart
@freezed
class AuthState with _$AuthState {
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

**BLoC Implementation:**
```dart
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> with BlocErrorMixin {
  final IAuthRepository _repository;
  
  AuthBloc({required IAuthRepository repository})
      : _repository = repository,
        super(const AuthState.initial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading(operation: 'login'));
    
    final result = await _repository.login(event.email, event.password);
    
    result.fold(
      (failure) => emit(AuthState.error(
        failure: failure,
        operation: 'login',
        retryAction: () => add(event),
      )),
      (user) => emit(AuthState.authenticated(
        user: user,
        isOnboarded: true,
      )),
    );
  }
}
```

**Cubit for Simple State (Alternative):**
```dart
@injectable
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

// Use Cubit when:
// - State changes are simple and direct
// - No need for explicit events
// - Less boilerplate needed

// Use BLoC when:
// - Complex business logic
// - Need to track/transform events
// - Multiple events → same state
```

**Widget Integration:**
```dart
// BlocProvider
BlocProvider(
  create: (context) => getIt<AuthBloc>()
    ..add(const AuthEvent.checkAuthStatus()),
  child: const AuthPage(),
)

// BlocBuilder - rebuilds on state change
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (prev, current) => prev != current, // Optional optimization
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

// BlocListener - for side effects (navigation, snackbars)
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

// BlocConsumer - combines Builder + Listener
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    // Side effects
  },
  builder: (context, state) {
    // UI
  },
)

// BlocSelector - rebuild only when specific value changes
BlocSelector<ChatBloc, ChatState, bool>(
  selector: (state) => state.isLoading,
  builder: (context, isLoading) {
    return isLoading ? const LoadingIndicator() : const SizedBox();
  },
)
```

**Stream Integration:**
```dart
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final ChatService _chatService;
  late final StreamSubscription<Message> _messageSubscription;
  
  MessageBloc({required ChatService chatService}) 
      : _chatService = chatService,
        super(const MessageState.initial()) {
    // Subscribe to real-time stream
    _messageSubscription = _chatService.messageStream.listen(
      (message) => add(MessageEvent.received(message)),
    );
    
    on<MessageReceivedEvent>(_onMessageReceived);
  }
  
  @override
  Future<void> close() {
    _messageSubscription.cancel(); // ALWAYS cleanup
    return super.close();
  }
}
```

### Error Handling Pattern

**Failure Classes (Domain Layer):**
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

**Exception Classes (Data Layer):**
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

**Repository Error Handling:**
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
    // Check network connectivity
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    
    try {
      // Try remote data source
      final userModel = await _remoteDataSource.login(email, password);
      
      // Cache user data
      await _localDataSource.cacheUser(userModel);
      
      // Return success
      return Right(userModel.toEntity());
      
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
      
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
      
    } catch (e) {
      return Left(UnexpectedFailure(
        message: 'Unexpected error: $e',
      ));
    }
  }
}
```

**BLoC Error Handling:**
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

### Code Style
```typescript
// ✅ CORRECT
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

// File naming: kebab-case
// user.service.ts, auth.module.ts

// Path aliases
import { OfficeUser } from '@models/entities';  // ✅
import { RedisService } from '@core/common/redis.service';  // ✅
```

### GraphQL Pattern
```typescript
// ObjectType
@ObjectType()
export class User {
  @Field(() => ID)
  id: string;
  
  @Field()
  email: string;
  
  @Field({ nullable: true })
  displayName?: string;
}

// InputType
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
```typescript
@common/*      → src/common/*
@helpers/*     → src/helpers/*
@models/*      → src/models/*
@utils/*       → src/utils/*
@services/*    → src/services/*
@core/*        → src/modules/core/*
@modules/*     → src/modules/*
@middlewares/* → src/middlewares/*
@decorators/*  → src/decorators/*
```

## 🔄 Communication Flow

### Flutter → Backend
1. **GraphQL**: Queries/Mutations qua HTTP
2. **Socket.IO**: Real-time events
3. **Firebase**: Shared services (Auth, Storage, Messaging)

### Data Flow
```
User Action → BLoC Event → UseCase → Repository → DataSource → API
                ↓
            State Update → UI Rebuild
```

### Offline-first Flow
```
1. Check connectivity
2. If offline: Save to Isar DB + Queue for sync
3. When online: Sync queued operations
4. Handle conflicts if needed
```

## 🎯 Common Tasks

### Add New Feature (Flutter)
```bash
# 1. Create domain entities
lib/domain/entities/my_feature.dart

# 2. Create repository interface
lib/domain/repositories/my_feature_repository.dart

# 3. Create use cases
lib/domain/usecases/my_feature/get_my_feature.dart

# 4. Create data models
lib/data/models/my_feature_model.dart

# 5. Create data sources
lib/data/datasources/my_feature_remote_datasource.dart
lib/data/datasources/my_feature_local_datasource.dart

# 6. Implement repository
lib/data/repositories/my_feature_repository_impl.dart

# 7. Create BLoC
lib/presentation/blocs/my_feature/my_feature_bloc.dart
lib/presentation/blocs/my_feature/my_feature_event.dart
lib/presentation/blocs/my_feature/my_feature_state.dart

# 8. Create UI
lib/presentation/pages/my_feature/my_feature_page.dart

# 9. Register in DI
lib/core/di/enterprise_injection.dart

# 10. Generate code
dart run build_runner build --delete-conflicting-outputs
```

### Add New Module (Backend)
```bash
# 1. Create module directory
src/modules/my-feature/

# 2. Create files
my-feature.module.ts
my-feature.service.ts
my-feature.resolver.ts
my-feature.args.ts
my-feature.response.ts

# 3. Register in app.module.ts
imports: [MyFeatureModule]
```

## 🚨 Important Notes

### Flutter
- **ALWAYS** use `const` constructors where possible
- **NEVER** use relative imports (use package imports)
- **ALWAYS** annotate public API types
- **NEVER** use `print()` (use Logger)
- **ALWAYS** handle errors with `Either<Failure, T>`
- **ALWAYS** dispose resources (StreamSubscriptions, Controllers)
- **ALWAYS** run code generation after model changes

### Backend
- **ALWAYS** use path aliases (@common, @modules, etc.)
- **ALWAYS** validate inputs with class-validator
- **ALWAYS** use dependency injection
- **ALWAYS** handle errors properly
- **ALWAYS** log important operations
- **NEVER** expose sensitive data in responses

## 🔍 Debugging

### Flutter
```bash
# Run with logs
flutter run --verbose

# Check performance
# Enable overlay in PerformanceService

# Analyze code
flutter analyze

# Check dependencies
flutter pub outdated
```

### Backend
```bash
# Run in dev mode
npm run start:dev

# Check logs
# Logger automatically logs to console

# Test GraphQL
# Open http://localhost:5000/graphql
```

## 📚 Key Files

### Flutter
- `lib/main.dart` - Main entry point
- `lib/core/di/enterprise_injection.dart` - DI setup
- `lib/config/route/app_router.dart` - Routing
- `pubspec.yaml` - Dependencies
- `analysis_options.yaml` - Linting rules

### Backend
- `src/main.ts` - Main entry point
- `src/app.module.ts` - Root module
- `package.json` - Dependencies
- `tsconfig.json` - TypeScript config

## 🎨 Naming Conventions

### Flutter
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/Methods: `camelCase`
- Constants: `camelCase` or `SCREAMING_SNAKE_CASE`
- Private: `_prefixWithUnderscore`

### Backend
- Files: `kebab-case.ts`
- Classes: `PascalCase`
- Variables/Methods: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private: `private` keyword

---

**Last Updated**: 2025-01-27
**Maintainer**: Senior Flutter/Mobile Architect


### Repository Pattern

**Domain Interface:**
```dart
// lib/domain/repositories/auth_repository.dart
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

**Data Implementation:**
```dart
// lib/data/repositories/auth_repository_impl.dart
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

## 🚨 Critical Rules & Warnings

### Layer Separation (ENFORCED)
```dart
// ❌ FORBIDDEN - Domain importing Flutter
// lib/domain/entities/user.dart
import 'package:flutter/material.dart'; // ERROR!

// ❌ FORBIDDEN - Presentation importing Data Models
// lib/presentation/pages/home_page.dart
import 'package:flutter_chat_app/data/models/user_model.dart'; // ERROR!

// ✅ CORRECT - Presentation importing Domain Entities
import 'package:flutter_chat_app/domain/entities/user.dart';

// ❌ FORBIDDEN - Domain importing infrastructure
// lib/domain/usecases/get_user.dart
import 'package:http/http.dart'; // ERROR!
import 'package:sqflite/sqflite.dart'; // ERROR!
```

### Hardcoded Strings (WARNING)
```dart
// ❌ WARNING - Hardcoded UI strings
Text('Welcome to the app'); // Use localization!

// ✅ CORRECT - Localized strings
Text(context.l10n.welcomeMessage);

// ✅ OK - Non-UI strings (constants, keys)
const String apiKey = 'API_KEY';
const String cacheKey = 'user_cache';
```

### RTL Support (INFO)
```dart
// ⚠️ INFO - Use start/end instead of left/right
Padding(
  padding: EdgeInsets.only(left: 16), // Consider RTL!
);

// ✅ BETTER - RTL-aware
Padding(
  padding: EdgeInsets.only(start: 16),
);
```

### State Management (WARNING)
```dart
// ❌ WARNING - setState in presentation layer
// lib/presentation/pages/chat_page.dart
setState(() {
  messages.add(newMessage);
});

// ✅ CORRECT - Use BLoC
context.read<ChatBloc>().add(ChatEvent.messageReceived(newMessage));
```

### Code Quality Rules
```dart
// ❌ WARNING - Broad exception catch
try {
  await someOperation();
} catch (e) { // Too broad!
  // Handle
}

// ✅ CORRECT - Specific exception handling
try {
  await someOperation();
} on ServerException catch (e) {
  // Handle server error
} on NetworkException catch (e) {
  // Handle network error
} catch (e) {
  // Handle unexpected error
  logger.e('Unexpected error', error: e);
}

// ⚠️ INFO - Prefer final for locals
var count = 10; // Consider using final

// ✅ BETTER
final count = 10;

// ✅ OK - Only if reassigned
var count = 10;
count = 20;
```

### Documentation (INFO)
```dart
// ⚠️ INFO - Add doc comments for public APIs
class UserRepository {
  Future<User> getUser(String id) async {
    // Implementation
  }
}

// ✅ BETTER - With documentation
/// Repository for managing user data.
///
/// Provides methods to fetch, create, update, and delete users.
class UserRepository {
  /// Fetches a user by their unique [id].
  ///
  /// Returns [User] if found, throws [UserNotFoundException] otherwise.
  Future<User> getUser(String id) async {
    // Implementation
  }
}
```

### TODO Comments (INFO)
```dart
// ⚠️ INFO - Add context to TODOs
// TODO: Fix this

// ✅ BETTER - With context
// TODO(john): Implement retry logic for failed requests (#123)
// TODO(#456): Add pagination support
```

## 🔧 Code Generation

### When to Run
```bash
# After creating/modifying:
# - Isar models (@collection)
# - Freezed classes (@freezed)
# - Injectable services (@injectable)
# - JSON serializable classes (@JsonSerializable)

dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild)
dart run build_runner watch --delete-conflicting-outputs

# Clean before build
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Localization Generation
```bash
# After modifying ARB files
flutter gen-l10n

# Or run with app
flutter run # Auto-generates
```

## 🧪 Testing Patterns

### BLoC Testing
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
- [ ] Run `dart run build_runner build` if models changed
- [ ] Run tests: `flutter test`
- [ ] Check for `print()` statements - use Logger
- [ ] Check for hardcoded strings - use l10n
- [ ] Check for `!` null assertions - use null-safe operators
- [ ] Check for `as` type casts - use `is` checks
- [ ] Verify layer separation - no forbidden imports
- [ ] Add/update tests for new features
- [ ] Update documentation if needed

### Adding New Feature
- [ ] Create domain entities
- [ ] Create repository interface in domain
- [ ] Create use cases
- [ ] Create data models with mappers
- [ ] Create data sources (remote + local)
- [ ] Implement repository
- [ ] Create BLoC/Cubit with events/states
- [ ] Create UI pages/widgets
- [ ] Register dependencies in DI
- [ ] Run code generation
- [ ] Write tests (unit + widget)
- [ ] Add localization strings
- [ ] Update routing if needed

### Code Review Checklist
- [ ] Follows Clean Architecture
- [ ] No layer violations
- [ ] Proper error handling with Either<Failure, T>
- [ ] Uses dependency injection
- [ ] Has unit tests
- [ ] Uses localization for UI strings
- [ ] No hardcoded values
- [ ] Proper null safety
- [ ] Performance optimized
- [ ] Documented public APIs

---

**Version**: 2.0
**Last Updated**: 2025-01-27
**Maintainer**: Senior Flutter/Mobile Architect
**Based on**: Cursor Rules + Clean Architecture + BLoC Pattern
