# Flutter Chat App

> Offline-first chat application using Clean Architecture, BLoC, and Isar local DB.

## ⚠️ CRITICAL: Dual Deployment Mode — ALWAYS Consider Both

This Flutter project runs in **TWO modes**. Every code change MUST work in both:

### Mode 1: Standalone App
- Entry: `main.dart`, `main_staging.dart`, `main_production.dart`
- DI: `configureDependencies()` in `core/di/injection.dart`
- Shell: `ChatAppShell.standalone()` — all BLoCs (AppBloc, AuthBloc, LocaleCubit, ThemeCubit, PermissionsBloc)
- Auth: Full login/register flow with `IAuthRepository`
- Routing: `go_router` with full app navigation
- Config: `FlavorConfig` + env variables

### Mode 2: Package Module (embedded in host app)
- Entry: `ChatModule.initialize(ChatConfig(...))` — called by host app after login
- DI: `ChatModuleInjection.initialize()` in `core/di/chat_module_injection.dart`
- Shell: `ChatAppShell.package()` — minimal BLoCs (AuthBloc.authenticated(), ChatBloc, RealtimeConnectionBloc)
- Auth: Pre-authenticated from host app token, `PackageModeAuthRepository` (no-op)
- Navigation: Host app embeds pages via `ChatModule.chatListPage()`, `ChatModule.chatDetailPage(chatId)`
- Config: `ChatConfig` object (baseUrl, graphqlUrl, socketUrl, accessToken, currentUserId, callbacks)
- Events: `ChatModuleEventBus` streams (unreadCount, newMessage, FCM) for host app integration
- Cleanup: `ChatModule.logout()` (clear user data) / `ChatModule.dispose()` (full cleanup, preserve host)

### Public API (what host apps see)
- Exported via `lib/flutter_chat_module.dart`
- ONLY: `ChatModule`, `ChatConfig`, domain entities, auth abstractions, monitoring interfaces
- NEVER export: Data layer, repositories, datasources, DTOs, mappers, BLoC internals

### Dual-Mode Rules
1. **New service/BLoC** → Register in BOTH `injection.dart` (standalone) AND `chat_module_injection.dart` (package)
2. **New page** → Must work as both a routed page (standalone) AND an embedded widget (package)
3. **Auth usage** → Use `IAuthRepository` interface, never assume full auth flow exists
4. **GetIt usage** → NEVER `getIt.reset()` in package mode (shared with host app)
5. **Callbacks/events** → Wire to `ChatModuleEventBus` for host app in `chat_module_injection.dart`
6. **Public types** → Export in `flutter_chat_module.dart` if host app needs them

## Quick Reference

```bash
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Directory Structure

```
lib/
├── core/              # DI, network, storage, base classes, error handling, theme, constants
│   ├── base/          # BaseWidget, BaseState, BaseUseCase, BaseRepository
│   ├── config/        # FlavorConfig (staging/production)
│   ├── constants/     # AppConstants, AppDimens
│   ├── di/            # GetIt + Injectable setup, chat_module_injection
│   ├── error/         # Failures, Exceptions, RepositoryErrorMixin
│   ├── network/       # GraphQL client, SocketManager, EnhancedSocketManager, NetworkInfo
│   ├── offline/       # OfflineMessageQueue
│   ├── services/      # ConnectivityService, RealtimeMessagingService, BackgroundSyncService
│   ├── theme/         # AppColors, AppTextStyles, AppTheme
│   └── utils/         # Logger
├── data/              # Models, DTOs, mappers, datasources, repository implementations
│   ├── datasources/   # Remote (GraphQL) + Local (Isar) datasources
│   ├── dtos/          # Freezed DTOs with JsonSerializable
│   ├── graphql/       # GraphQL operation strings (⚠️ needs fixing)
│   ├── managers/      # SyncMetadataManager
│   ├── mappers/       # DTO ↔ Entity mappers, SocketIOEventMapper
│   ├── repositories/  # Repository implementations
│   └── strategies/    # MessageMergeStrategy, GapDetectionLogic
├── domain/            # Pure Dart — entities, use cases, repository interfaces
│   ├── entities/      # Chat, ChatMessage, User
│   ├── repositories/  # IMessageRepository, IChatRepository (interfaces)
│   └── usecases/      # ⚠️ MOSTLY EMPTY — needs 15+ use cases
├── presentation/      # BLoCs, pages, widgets
│   ├── blocs/         # Feature BLoCs (auth, chat, message, typing, connection, realtime, message_queue)
│   ├── pages/         # Login, ChatList, ChatDetails, CreateGroup, etc.
│   └── widgets/       # Reusable widgets (MessageBubble, InputField, ConnectionStatus)
├── features/          # Feature-specific modules
├── config/            # Routes, themes, app constants
├── l10n/              # ARB localization files (app_en.arb, app_vi.arb)
└── main*.dart         # Entry points (staging, production)
```

## Core Patterns (MANDATORY)

### 1. BLoC — extend BaseBloc (NEVER raw Bloc)

```dart
@injectable
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  ChatBloc({required ISomeRepository repository, required Logger logger})
      : super(const ChatState.initial()) {
    on<LoadChats>(_onLoadChats);
  }

  Future<void> _onLoadChats(LoadChats event, Emitter<ChatState> emit) async {
    emitLoading(message: 'Loading...');
    final result = await _useCase(params);
    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (data) => emit(ChatState.loaded(data: data)),
    );
  }
}
```

### 2. State — @freezed + extend BaseState

```dart
@freezed
class ChatState extends BaseState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading({String? message}) = ChatLoading;
  const factory ChatState.loaded({required List<Chat> data}) = ChatLoaded;
  const factory ChatState.error({required String message}) = ChatError;
}
```

### 3. Widget — extend BaseStatefulWidget / BaseStatelessWidget

```dart
class MyWidget extends BaseStatefulWidget {
  const MyWidget({super.key});
  @override
  MyWidgetState createState() => MyWidgetState();
}
class MyWidgetState extends BaseState<MyWidget> {
  void _update() { safeSetState(() { }); } // NOT setState
  @override
  Widget build(BuildContext context) => Container();
}
```

### 4. UI — App* widgets ONLY

```dart
// ❌ FORBIDDEN          → ✅ REQUIRED
Text('Hello')            → AppText(context.l10n.hello)
ElevatedButton(...)      → AppButton(label: context.l10n.save, onPressed: _save)
TextField(...)           → AppTextField(label: context.l10n.email, controller: _ctrl)
AlertDialog(...)         → AppAlertDialog.show(context, title: context.l10n.alert)
SnackBar(...)            → AppSnackBar.show(context, message: context.l10n.success)
Colors.white             → AppColors.textPrimaryDarkMode
EdgeInsets.all(16.0)     → EdgeInsets.all(AppDimens.paddingMedium)
```

### 5. DI — @injectable annotations

```dart
@injectable class MyUseCase { MyUseCase({required IRepo repo}); }
@LazySingleton(as: IRepo) class RepoImpl implements IRepo { }
// Register in: lib/core/di/injection.dart or chat_module_injection.dart
```

### 6. Error Handling — Either<Failure, T>

```dart
// Repository
@override
Future<Either<Failure, List<Chat>>> getChats() async {
  if (await networkInfo.isConnected) {
    try {
      final remote = await remoteDataSource.getChats();
      await localDataSource.cacheChats(remote);
      return Right(remote.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    final local = await localDataSource.getCachedChats();
    return Right(local.map((m) => m.toEntity()).toList());
  }
}
```

## Backend API Contract (⚠️ CRITICAL)

### GraphQL Operations (Backend uses these names)

| Operation | Type | Flutter File Status |
|---|---|---|
| `chatConversationList(filters)` | Query | ⚠️ Flutter uses WRONG name `getUserChats` |
| `chatConversationDetail(conversationId)` | Query | ⚠️ Flutter uses WRONG name `getChatDetails` |
| `chatMessageList(filters)` | Query | ⚠️ Needs fixing |
| `chatMessageAdd(arguments)` | Mutation | ⚠️ Flutter uses WRONG name `sendMessage` |
| `chatMessageEdit(arguments)` | Mutation | ❌ Not implemented |
| `chatMessageUpdateReaction(arguments)` | Mutation | ❌ Not implemented |
| `chatMessageUpdateRead(arguments)` | Mutation | ⚠️ Needs fixing |
| `chatGroupAdd(arguments)` | Mutation | ⚠️ Needs fixing |
| `chatGroupEdit(arguments)` | Mutation | ❌ Not implemented |
| `chatConversationLeave(arguments)` | Mutation | ❌ Not implemented |
| `chatConversationDelete(arguments)` | Mutation | ❌ Not implemented |
| `chatSearch(filters)` | Query | ❌ Not implemented |

### Field Mapping (Backend → Flutter Domain)

| Backend Field | Domain Field | Notes |
|---|---|---|
| `message` | `content` | Text content |
| `urls` | `mediaUrls` | Media URLs list |
| `replyMessageId` | `replyToId` | Reply reference |
| `forwardedFromMessageId` | `forwardedFromId` | Forward reference |
| `reactions[].code` | `reactions[].emoji` | Emoji string |
| `reactions[].reactorIds` | `reactions[].userIds` | Reactor user IDs |
| `mentionTo` | `mentions` | List of User objects |
| `imgUrl` | `avatarUrl` | Conversation avatar |
| `admin` | `isAdmin` | Member role boolean |
| `hide` | `isHidden` | Conversation visibility |

### Pagination Rules

- Messages: cursor-based → `lastKey: {conversationId, createdAt (ms timestamp)}`, order `DESC`
- Conversations: offset-based → `page` (0-indexed) + `size` (default 25)

### Socket.IO Events

| Event | Direction | Status |
|---|---|---|
| `message:sent` | Server→Client | ✅ Implemented |
| `message:read` | Server→Client | ✅ Implemented |
| `message:typing` | Bidirectional | ✅ Implemented |
| `conversation:joined` | Bidirectional | ✅ Implemented |
| `message:reaction` | Server→Client | ❌ Missing |
| `message:edit` | Server→Client | ❌ Missing |
| `message:delete` | Server→Client | ❌ Missing |
| `conversation:leaved` | Bidirectional | ❌ Missing |
| `message:file:upload` | Client→Server | ❌ Missing |

### Message Types (Backend Enum)

`TEXT`, `IMAGE`, `VIDEO`, `LOCATION`, `CALL`, `VOICE_NOTE`, `DOC`, `AUDIO`, `STICKER`

### Key Business Rules

- Direct messages: use `receiverId` for first message, backend auto-creates conversation
- Subsequent messages: use `conversationId`
- Mentions format: `@[userId]` in text, `@[all]` for everyone
- Reactions: `act: 1` = add, `act: 0` = revoke
- Message edit/delete: `act: 1` = edit, `act: 0` = delete (soft delete)
- File upload: via Socket.IO `message:file:upload`, returns path, then send message with `urls`
- Unread count: managed by backend, `personalConversation.unreadCount`

## Offline-First Flow

```
User Action → Save to Local DB (Isar) → Add to Sync Queue → Update UI (optimistic)
  → When online: Process Queue → Send to Server → Update Local with Server Response → Remove from Queue
```

- Always save locally first, then sync
- Queue items: max 3 retries, exponential backoff
- Process queue immediately when connectivity restored
- Periodic sync fallback: every 30s
- Temp message IDs: `temp_{timestamp}`
- Message statuses: `local → sending → sent → delivered → read → failed`

## Message-Specific Patterns

- Messages ordered by `createdAt DESC` (newest first)
- Cursor pagination with `lastKey` (conversationId + createdAt timestamp)
- Optimistic updates: show temp message → replace on server response
- Merge strategy: `lib/data/strategies/message_merge_strategy.dart`
- Socket event buffering during loading: `lib/presentation/blocs/message/socket_event_buffer.dart`
- Gap detection: `lib/data/strategies/gap_detection_logic.dart`

## Gotchas

- `FlavorConfig` must be initialized before any network call
- Isar DB schemas must be registered in order — check `core/di/injection.dart`
- After any `@freezed` or `@JsonSerializable` change, MUST run build_runner
- GraphQL client requires valid JWT token — check auth state before API calls
- Socket.IO uses `websocket` transport only (no polling fallback)
- Socket auth: `{token: jwt}` in socket auth options
