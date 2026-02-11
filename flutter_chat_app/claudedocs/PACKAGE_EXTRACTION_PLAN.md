# Flutter Chat Package Extraction Plan

## Objective
Tach `flutter_chat_app` thanh reusable package (`flutter_chat_module`) de host app khac co the tich hop chat bang cach chi truyen token.

## Host App Interface (Target)
```dart
// Host app chi can:
await ChatModule.initialize(ChatConfig(
  baseUrl: 'https://api.example.com',
  graphqlUrl: 'https://api.example.com/graphql',
  graphqlWsUrl: 'wss://api.example.com/graphql',
  socketUrl: 'wss://api.example.com/socket',
  accessToken: userToken,
  currentUserId: userId,
  onTokenRefresh: () => authService.refreshToken(),
  onAuthExpired: () => navigator.pushLogin(),
));

// Navigate to chat
Navigator.push(context, ChatModule.chatListRoute());
Navigator.push(context, ChatModule.chatDetailRoute(chatId));
```

---

## Phase 1: Resolve Inconsistencies (Foundation)

### 1.1 Unify Either Type
**Problem**: 10 files use `dartz` Either, 33 files use custom `core/utils/either.dart`. Incompatible types.
**Solution**: Migrate 10 dartz files -> custom Either (fewer changes, custom Either is simpler).
**Files to change**:
- `domain/usecases/message/send_message_usecase.dart`
- `domain/usecases/message/get_messages_usecase.dart`
- `domain/usecases/message/search_messages_usecase.dart`
- `domain/usecases/message/remove_reaction_usecase.dart`
- `domain/usecases/message/add_reaction_usecase.dart`
- `domain/usecases/message/delete_message_usecase.dart`
- `domain/usecases/message/mark_as_read_usecase.dart`
- `domain/usecases/message/edit_message_usecase.dart`
- `data/repositories/media_repository_impl.dart`
- `domain/repositories/i_media_repository.dart`

### 1.2 Abstract PerformanceMonitor
**Problem**: `BaseRepository` hard-depends on `PerformanceMonitor` which imports `firebase_performance`.
**Solution**: Extract `IPerformanceMonitor` interface. Package uses interface, Firebase impl is optional.
**Files to change**:
- `core/monitoring/performance_monitor.dart` -> extract interface
- `core/base/base_repository.dart` -> depend on interface
- `core/di/injection.dart` -> register interface

### 1.3 Abstract Error Localization
**Problem**: `failures.dart` directly imports `ErrorMessagesVi` (Vietnamese hardcoded).
**Solution**: Create `ErrorMessageProvider` interface. Default impl = Vietnamese. Package consumer can override.
**Files to change**:
- `core/localization/error_messages_vi.dart` -> keep as default impl
- `core/error/failures.dart` -> use `ErrorMessageProvider` interface
- New: `core/localization/error_message_provider.dart`

### 1.4 Add `mapLeft` and `getOrElse` to Custom Either
**Problem**: Custom Either lacks utility methods that dartz provides.
**Solution**: Add commonly used methods to custom Either.
**Files to change**:
- `core/utils/either.dart`

---

## Phase 2: Create Token Abstraction Layer

### 2.1 Create `TokenProvider` Interface
- Interface: `getAccessToken()`, `getRefreshToken()`, `onTokenRefresh(callback)`, `refreshToken()`
- Package uses this interface, does NOT manage auth flow
- Host app implements `TokenProvider`

### 2.2 Adapt `TokenRepository`
- `TokenRepository` implements `TokenProvider`
- GraphQL client and Socket.IO use `TokenProvider` instead of concrete `TokenRepository`

### 2.3 Create `AuthDelegate`
- Interface for auth-expired callbacks
- Package calls `onAuthExpired()` when 401 received
- Host app handles re-login flow

**Files to change**:
- New: `core/network/auth/token_provider.dart`
- New: `core/network/auth/auth_delegate.dart`
- `core/network/auth/token_repository.dart` -> implements TokenProvider
- `core/network/graphql_client.dart` -> use TokenProvider
- `core/network/socket_manager.dart` -> use TokenProvider
- `core/di/injection.dart` -> register TokenProvider

---

## Phase 3: Create `ChatConfig` and Module Entry Point

### 3.1 Create `ChatConfig`
```dart
class ChatConfig {
  final String baseUrl;
  final String graphqlUrl;
  final String graphqlWsUrl;
  final String socketUrl;
  final String accessToken;
  final String? refreshToken;
  final String currentUserId;
  final Future<String> Function()? onTokenRefresh;
  final void Function(String userId)? onUserProfileTap;
  final void Function()? onAuthExpired;
  final Locale? locale;
  final ThemeData? theme;
  final IPerformanceMonitor? performanceMonitor;
  final ErrorMessageProvider? errorMessageProvider;
}
```

### 3.2 Create `ChatModule` Entry Point
- `ChatModule.initialize(ChatConfig)` -> setup internal DI
- `ChatModule.chatListPage()` -> return ChatListPage widget
- `ChatModule.chatDetailPage(chatId)` -> return ChatDetailsPage widget
- `ChatModule.dispose()` -> cleanup

### 3.3 Create `ChatModuleInjection`
- Separate DI setup for package mode
- Receives external deps from ChatConfig
- Registers all internal deps

**Files to create**:
- `lib/chat_module.dart` (public API)
- `lib/chat_config.dart`
- `lib/core/di/chat_module_injection.dart`

---

## Phase 4: Decouple Firebase

### 4.1 Make Firebase Optional
- `PerformanceMonitor` -> use `IPerformanceMonitor` (can be no-op)
- `CrashReporter` -> pluggable interface
- `AnalyticsManager` -> pluggable interface
- Remove `firebase_performance` import from base classes

### 4.2 Conditional Dependencies
- Firebase packages become optional/dev dependencies
- Package consumer decides if Firebase is used

**Files to change**:
- `core/monitoring/performance_monitor.dart` -> impl of IPerformanceMonitor
- `core/monitoring/crash_reporter.dart` -> extract interface
- `core/monitoring/analytics_manager.dart` -> extract interface
- `core/initialization/service_initializer.dart` -> conditional init

---

## Phase 5: Package Structure

### 5.1 Create Package
```
flutter_chat_module/
  lib/
    flutter_chat_module.dart          # Public barrel export
    src/
      chat_module.dart                # Entry point
      chat_config.dart                # Configuration
      core/                           # Core infrastructure
      features/                       # Feature modules
      shared/                         # Shared entities
      domain/                         # Domain layer
      data/                           # Data layer
      presentation/                   # Presentation layer
  pubspec.yaml
```

### 5.2 Public API Surface
Only export:
- `ChatModule`, `ChatConfig`
- Domain entities (`User`, `Chat`, `ChatMessage`)
- `IPerformanceMonitor`, `ErrorMessageProvider` (for customization)
- `TokenProvider`, `AuthDelegate` (for host app implementation)

### 5.3 Backward Compatibility
- Original app uses package as dependency
- `injection.dart` creates `ChatConfig` from existing env/dotenv
- All existing functionality preserved

---

## Phase 6: Testing & Migration

### 6.1 Integration Tests
- Package initializes correctly with ChatConfig
- Token refresh flow works through TokenProvider
- Auth expiry triggers onAuthExpired
- UI renders correctly in isolation

### 6.2 Migrate Original App
- Add `flutter_chat_module` as path dependency
- Replace direct imports with package imports
- `injection.dart` creates ChatConfig from env
- Verify all existing features work

---

## Dependency Tier Map

```
Tier 0 (No deps - extract first):
  Either, Failure, Exception types, Domain entities, UseCase base

Tier 1 (Light deps):
  NetworkInfo, SecureStorage, LocalStorage, TokenProvider

Tier 2 (Medium deps):
  IPerformanceMonitor, BaseRepository, GraphQLClient, SocketManager

Tier 3 (Heavy deps):
  EnhancedSocketManager, DatabaseService, OfflineMessageQueue, CacheSync

Tier 4 (Feature layer):
  DataSources, Repositories, BLoCs, UseCases, UI Pages/Widgets
```

## Risk Mitigation

| Risk | Strategy |
|------|----------|
| Breaking existing app | Package wraps existing code; app becomes thin shell |
| Isar codegen | `.g.dart` files stay in package, not host app |
| Firebase coupling | Interface abstraction + no-op default |
| DI complexity | Separate `ChatModuleInjection` for package mode |
| Two Either types | Phase 1 unifies to single type |

## Estimated Scope Per Phase

| Phase | Files Changed | New Files | Complexity |
|-------|--------------|-----------|------------|
| Phase 1 | ~15 | 2 | Low-Medium |
| Phase 2 | ~8 | 3 | Medium |
| Phase 3 | ~5 | 4 | Medium |
| Phase 4 | ~6 | 3 | Low |
| Phase 5 | ~50 (moves) | 3 | High (restructure) |
| Phase 6 | ~10 | 5 | Medium |
