# Implementation Plan: Message Loading Architecture (Phase 2 + Phase 3)

## Tổng quan

Triển khai Two-Phase Render và Delta Sync cho MessageBloc, giữ nguyên backward compatibility với Phase 1. Thứ tự: foundational models/utilities → repository layer → BLoC layer → wiring → tests.

**Ngôn ngữ**: Dart (Flutter)
**Lưu ý quan trọng**:
- MessageBloc giữ nguyên `extends Bloc<MessageEvent, MessageState> with BlocErrorMixin` (KHÔNG chuyển sang BaseBloc)
- States giữ nguyên Equatable (KHÔNG dùng Freezed)
- SyncMetadataManager dùng Isar (KHÔNG dùng SharedPreferences)
- Backend đã hỗ trợ đầy đủ — không cần thay đổi backend
- Sử dụng AppLogger (KHÔNG dùng Logger trực tiếp)

## Tasks

- [x] 1. Tạo foundational models và enums
  - [x] 1.1 Tạo `MessageDataSource` enum và mở rộng `MessagesLoaded` state
    - Tạo enum `MessageDataSource { local, server, merged }` trong file `message_state.dart` (part of message_bloc.dart)
    - Mở rộng `MessagesLoaded` với fields mới: `dataSource` (default: `MessageDataSource.server`), `isBackgroundFetching` (default: `false`)
    - Cập nhật `copyWith`, `props` để bao gồm fields mới
    - Đảm bảo backward compatible — tất cả constructor calls hiện tại không cần thay đổi nhờ default values
    - _Requirements: 3.1, 3.2, 10.3_

  - [x] 1.2 Tạo `SyncMetadataModel` Isar collection
    - Tạo file `flutter_chat_app/lib/data/models/sync_metadata_model.dart`
    - Implement `@collection` class với fields: `id`, `conversationId` (@Index unique, replace), `lastKnownTimestamp`, `lastSyncTime`, `updatedAt` (@Index)
    - Chạy `dart run build_runner build --delete-conflicting-outputs` để generate Isar code
    - Register `SyncMetadataModel` trong Isar schema (cập nhật Isar.open call)
    - _Requirements: 4.1_

  - [x] 1.3 Tạo new MessageEvents
    - Thêm vào file `message_event.dart` (part of message_bloc.dart):
      - `_BackgroundFetchCompleted` (internal): chatId, serverMessages
      - `_BackgroundFetchFailed` (internal): chatId, error
      - `_ReconnectionDetected` (internal)
      - `AppResumed` (public)
      - `ReceiveMessageEdited`: editedMessage (ChatMessage)
      - `ReceiveMessageDeleted`: messageId (String)
      - `ReceiveMessageReaction`: messageId, code, userId, userName, isAdd
    - Tất cả extend `MessageEvent` với `Equatable`
    - _Requirements: 5.2, 5.3, 5.4, 6.1, 6.2_

- [x] 2. Implement core utilities (pure functions và managers)
  - [x] 2.1 Implement `MessageMergeStrategy`
    - Tạo file `flutter_chat_app/lib/data/strategies/message_merge_strategy.dart`
    - Implement static method `merge({localMessages, serverMessages})` theo design:
      - Deduplicate bằng message ID, server wins
      - Loại bỏ tin nhắn có `deletedAt` từ server
      - Bảo toàn tin nhắn sending/pending (match by `clientId`)
      - Sort descending by `createdAt`
    - Pure function, không side effects
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ]* 2.2 Property tests cho `MessageMergeStrategy` — Properties 1, 2, 3, 15
    - **Property 1: Merge deduplication with server priority and ordering**
    - **Validates: Requirements 2.1, 2.3, 2.4**
    - **Property 2: Merge removes deleted messages**
    - **Validates: Requirements 2.2**
    - **Property 3: Merge preserves sending/pending messages**
    - **Validates: Requirements 2.5**
    - **Property 15: Optimistic messages preserved during background fetch merge**
    - **Validates: Requirements 3.5, 9.1**
    - Tạo file `flutter_chat_app/test/unit/data/merge_strategy_test.dart`
    - Thêm dependency `dart_check` (hoặc `glados`) vào `dev_dependencies` nếu chưa có
    - Implement random generators cho `ChatMessage` (random ID, chatId, content, createdAt, localStatus, clientId, deletedAt)
    - Mỗi property là một test case riêng biệt với ≥100 iterations

  - [x] 2.3 Implement `SyncMetadataManager`
    - Tạo file `flutter_chat_app/lib/data/managers/sync_metadata_manager.dart`
    - Annotate `@lazySingleton`, inject `Isar`
    - Implement methods: `getLastKnownTimestamp`, `setLastKnownTimestamp`, `getLastSyncTime`, `setLastSyncTime`, `clearMetadata`, `updateFromMessages`, `cleanupStaleMetadata`, `getTrackedConversationCount`
    - `updateFromMessages` chỉ tăng timestamp (monotonic — never decrease)
    - TTL cleanup: 60 ngày
    - Wrap Isar writes trong try/catch, log warning nếu fail (không throw)
    - _Requirements: 4.1, 4.4, 5.5_

  - [ ]* 2.4 Property tests cho `SyncMetadataManager` — Properties 6, 7
    - **Property 6: SyncMetadata round-trip**
    - **Validates: Requirements 4.1**
    - **Property 7: SyncMetadata timestamp monotonic update**
    - **Validates: Requirements 4.4, 5.5**
    - Tạo file `flutter_chat_app/test/unit/data/sync_metadata_manager_test.dart`
    - Sử dụng Isar test instance (in-memory)
    - Property 6: set → get round-trip consistency
    - Property 7: updateFromMessages chỉ tăng, không giảm timestamp

  - [x] 2.5 Implement `GapDetectionLogic`
    - Tạo file `flutter_chat_app/lib/data/strategies/gap_detection_logic.dart`
    - Implement static method `hasGap({deltaCount, pageSize})` → `deltaCount >= pageSize`
    - _Requirements: 6.3, 6.5_

  - [ ]* 2.6 Property test cho `GapDetectionLogic` — Property 11
    - **Property 11: Gap detection heuristic**
    - **Validates: Requirements 6.3, 6.5**
    - Tạo file `flutter_chat_app/test/unit/data/gap_detection_test.dart`
    - Verify: `hasGap` returns true iff `deltaCount >= pageSize` cho mọi giá trị random

  - [x] 2.7 Implement `SocketEventBuffer`
    - Tạo file `flutter_chat_app/lib/presentation/blocs/message/socket_event_buffer.dart`
    - Implement: `startBuffering()`, `bufferIfNeeded(event)`, `stopBuffering()`, `isBuffering` getter
    - `stopBuffering` trả về events theo thứ tự nhận, clear buffer
    - _Requirements: 9.2_

  - [ ]* 2.8 Property test cho `SocketEventBuffer` — Property 13
    - **Property 13: Socket event buffering during background fetch**
    - **Validates: Requirements 9.2**
    - Tạo file `flutter_chat_app/test/unit/presentation/socket_event_buffer_test.dart`
    - Verify: events buffered khi `isBuffering == true`, trả về đúng thứ tự, buffer empty sau `stopBuffering`

- [x] 3. Checkpoint — Đảm bảo tất cả tests pass
  - Tất cả files compile clean (0 errors, 0 warnings liên quan)
  - build_runner đã generate thành công cho SyncMetadataModel
  - Verified: 2026-02-26

- [x] 4. Mở rộng Repository layer
  - [x] 4.1 Mở rộng `IMessageRepository` interface
    - Đã thêm `getMessagesFromLocal` và `getMessagesDelta` vào `i_message_repository.dart`
    - Không thay đổi methods hiện có — chỉ mở rộng
    - _Requirements: 10.2_

  - [x] 4.2 Implement `getMessagesFromLocal` trong `MessageRepositoryImpl`
    - Đọc tin nhắn từ `MessageLocalDataSource` (Isar) cho chatId
    - Trả về `Right(messages)` hoặc `Right([])` nếu không có data
    - Không throw exception — trả về empty list nếu local read fail
    - _Requirements: 1.1, 1.4_

  - [x] 4.3 Implement `getMessagesDelta` trong `MessageRepositoryImpl`
    - Gọi `_remoteDataSource` với tham số `from: fromTimestamp`
    - Merge delta messages với local messages bằng `MessageMergeStrategy.merge`
    - Lưu merged result vào local storage (Isar)
    - Cập nhật cache keys và invalidate cache cũ
    - Enforce cache limit: giữ tối đa 500 tin nhắn mới nhất trong cache
    - _Requirements: 4.2, 4.3, 7.1, 7.2, 7.5_

  - [ ]* 4.4 Unit tests cho repository delta methods — Properties 16, 18
    - **Property 16: Cache limit enforces 500 message maximum**
    - **Validates: Requirements 7.5**
    - **Property 18: Dirty flag reset after successful sync**
    - **Validates: Requirements 7.3**
    - Tạo file `flutter_chat_app/test/unit/data/message_repository_delta_test.dart`
    - Mock local/remote datasources, cache manager, cache sync strategy
    - Verify cache limit enforcement và dirty flag reset

- [x] 5. Cập nhật MessageBloc — Two-Phase Render + Delta Sync
  - [x] 5.1 Thêm dependencies mới vào MessageBloc constructor
    - `SyncMetadataManager` injected via constructor (DI)
    - `SocketEventBuffer` created internally
    - `CancelableOperation<void>?` for background fetch
    - `StreamSubscription?` cho connection state, message edited, deleted, reaction
    - `DateTime? _lastBackgroundedAt` cho app resume threshold
    - All 7 new event handlers registered
    - Connection state subscription with rxdart `pairwise()` for reconnection detection
    - _Requirements: 6.1, 10.1_

  - [x] 5.2 Cập nhật `_onLoadMessages` — Two-Phase Render path
    - Local data check → emit local immediately → background fetch
    - First-time load path giữ nguyên Phase 1 behavior
    - Sync metadata updated after successful load
    - Edit/delete/reaction streams subscribed
    - _Requirements: 1.1, 1.2, 1.4, 3.3_

  - [x] 5.3 Implement background fetch methods
    - `_startBackgroundFetch`: start buffering, cancel previous, create CancelableOperation
    - `_performBackgroundFetch`: delta sync or full load, gap detection
    - `_onBackgroundFetchCompleted`: chatId guard, merge, update sync metadata, flush buffer
    - `_onBackgroundFetchFailed`: keep local data, turn off fetching flag, flush buffer
    - _Requirements: 1.3, 1.5, 2.6, 3.4, 3.5, 4.2, 4.3, 4.4, 4.5, 6.5, 9.1, 9.2, 9.4, 9.5_

  - [x] 5.4 Implement socket event handlers (edit/delete/reaction)
    - `_subscribeToEditDeleteReaction`: subscribes to 3 streams from RealtimeService
    - `_onReceiveMessageEdited`: buffer check → update message, update sync metadata
    - `_onReceiveMessageDeleted`: buffer check → remove message
    - `_onReceiveMessageReaction`: buffer check → add/remove reaction
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 5.5 Implement reconnection và app resume handlers
    - `_onReconnectionDetected`: triggers background fetch for active conversation
    - `_onAppResumed`: 30-second threshold check before delta sync
    - `setBackgroundedAt(DateTime)`: public method for Page
    - _Requirements: 6.1, 6.2_

  - [x] 5.6 Cập nhật `close()` — cleanup resources
    - Cancels `_backgroundFetchOperation`
    - Cancels all Phase 2+3 subscriptions
    - Keeps existing Phase 1 cleanup
    - _Requirements: 9.3_

- [x] 6. Checkpoint — Đảm bảo tất cả code compile thành công
  - `flutter analyze`: 0 errors trên tất cả Phase 2+3 files
  - `build_runner` đã generate thành công (injection.config.dart, sync_metadata_model.g.dart)
  - Verified: 2026-02-26

- [x] 7. DI Registration và wiring
  - [x] 7.1 Register `SyncMetadataManager` trong DI
    - `@lazySingleton` annotation trên `SyncMetadataManager` — Injectable detect OK
    - Isar schema registration includes `SyncMetadataModelSchema` trong `database_service.dart`
    - `injection.config.dart` đã generate: `gh.lazySingleton<SyncMetadataManager>(...)`
    - _Requirements: 4.1_

  - [x] 7.2 Cập nhật MessageBloc DI registration
    - `SyncMetadataManager` đã có trong constructor parameters của `MessageBloc`
    - `async` package đã có trong `pubspec.yaml` (^2.11.0)
    - `rxdart` package đã có trong `pubspec.yaml` (^0.28.0)
    - Injectable generate đúng: `gh.factory<MessageBloc>(() => MessageBloc(... syncMetadataManager: gh<SyncMetadataManager>() ...))`
    - _Requirements: 10.1_

- [ ] 8. BLoC và State tests
  - [ ]* 8.1 Property tests cho MessageBloc Two-Phase Render — Properties 4, 5, 14, 17
    - **Property 4: Background fetch failure preserves local data**
    - **Validates: Requirements 1.5, 3.4**
    - **Property 5: Two-phase render emits local data with fetching flag**
    - **Validates: Requirements 1.1, 1.2, 3.3**
    - **Property 14: Conversation ID guard for stale responses**
    - **Validates: Requirements 9.4**
    - **Property 17: Backward compatible default values**
    - **Validates: Requirements 10.3**
    - Tạo file `flutter_chat_app/test/unit/presentation/message_bloc_two_phase_test.dart`
    - Mock repository, sync metadata manager, realtime service, use cases
    - Sử dụng `bloc_test` package cho BLoC testing

  - [ ]* 8.2 Property tests cho socket event handlers — Properties 8, 9, 10
    - **Property 8: Socket edit updates message in state**
    - **Validates: Requirements 5.2**
    - **Property 9: Socket delete removes message from state**
    - **Validates: Requirements 5.3**
    - **Property 10: Socket reaction updates reactions correctly**
    - **Validates: Requirements 5.4**
    - Tạo file `flutter_chat_app/test/unit/presentation/message_bloc_socket_test.dart`

  - [ ]* 8.3 Property test cho app resume threshold — Property 12
    - **Property 12: App resume threshold**
    - **Validates: Requirements 6.2**
    - Tạo file `flutter_chat_app/test/unit/presentation/message_bloc_reconnect_test.dart`
    - Verify: delta sync triggered iff background duration > 30 seconds

- [x] 9. Final checkpoint — Đảm bảo tất cả code compile thành công
  - Tất cả core files compile clean (getDiagnostics: 0 errors)
  - DI wiring verified trong injection.config.dart
  - Isar schema registered trong database_service.dart
  - Optional tests (tasks đánh dấu `*`) skipped cho MVP
  - Verified: 2026-02-26

## Notes

- Tasks đánh dấu `*` là optional và có thể skip cho MVP nhanh hơn
- Mỗi task reference cụ thể requirements từ requirements.md
- Checkpoints đảm bảo incremental validation
- Property tests validate 18 correctness properties từ design.md
- MessageBloc giữ nguyên `Bloc` + `BlocErrorMixin` — KHÔNG chuyển sang `BaseBloc` (đây là quyết định thiết kế có chủ đích)
- States giữ nguyên `Equatable` — KHÔNG dùng `Freezed` (đây là quyết định thiết kế có chủ đích)
