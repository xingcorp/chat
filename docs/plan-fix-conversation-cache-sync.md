# Implementation Plan: Fix 9 Conversation Cache/Sync Issues

> Created: 2026-03-05
> Priority: P0 (Critical) → P1 (Medium) → P2 (Medium-Low) → P3 (Low)
> Architecture doc: `docs/architecture-conversation-cache-sync.md`

---

## Tổng Quan

9 đề xuất cải thiện được nhóm thành **4 phases**:

| Phase | Priority | Issues | Effort Est. | Risk |
|---|---|---|---|---|
| Phase 1 | 🔴 P0 | #1 Offline Queue, #2 Fix Stubs | 3–4 days | High — core functionality |
| Phase 2 | 🟡 P1 | #3 Batch saveChats, #4 Fix getChatById | 1 day | Low — performance only |
| Phase 3 | 🟡 P1 | #5 Socket events, #6 Edit/Delete preview | 2 days | Medium — real-time flow |
| Phase 4 | 🟡 P2 | #7 SyncMetadata + GapDetection, #8 Periodic sync, #9 Optimize getChats | 2–3 days | Medium — new infra |

**Total estimated: 8–10 days**

---

## Phase 1: Critical Fixes (P0)

### Issue #1: Implement Offline Queue Processor

**Problem:** `OfflineOperationModel` schema hoàn chỉnh (375 lines, 10 operation types, exponential backoff) nhưng:
- Không code nào enqueue operations
- Không có processor để dequeue và execute
- `saveMessage(needsSync: true)` ignores `needsSync` parameter
- `getPendingMessages()` luôn return `[]`

**Impact:** Tin nhắn gửi khi offline sẽ MẤT. Thao tác offline (edit, delete, reaction) không sync.

**Files to modify/create:**

```
CREATE: lib/core/services/offline_queue_processor.dart
MODIFY: lib/features/chat/data/datasources/chat/chat_local_datasource.dart
MODIFY: lib/features/chat/data/repositories/chat_repository.dart
MODIFY: lib/core/di/injection.dart
MODIFY: lib/core/di/chat_module_injection.dart
```

**Implementation Steps:**

#### Step 1.1: Create `OfflineQueueService`

```
File: lib/core/services/offline_queue_service.dart
Annotation: @lazySingleton

Dependencies:
  - DatabaseService (Isar read/write OfflineOperationModel)
  - ConnectivityService (online/offline detection)
  - AppLogger

Interface: IOfflineQueueService
  - Future<void> enqueue(OfflineOperationModel operation)
  - Future<List<OfflineOperationModel>> getPending()
  - Future<void> markCompleted(String operationId)
  - Future<void> markFailed(String operationId, String error)
  - Future<void> processQueue()
  - Future<void> clearCompleted()
  - Stream<OfflineQueueStatus> get statusStream
  - Future<int> get pendingCount
```

#### Step 1.2: Create `OfflineQueueProcessor`

```
File: lib/core/services/offline_queue_processor.dart
Annotation: @lazySingleton

Dependencies:
  - IOfflineQueueService
  - IChatRemoteDataSource (execute operations)
  - ConnectivityService
  - AppLogger

Logic:
  - processQueue():
    1. Get all pending operations (sorted by timestamp ASC)
    2. For each operation:
       a. Check canRetry && shouldRetry (backoff)
       b. Mark as processing
       c. Switch on operation type → call appropriate remote method
       d. Success → markCompleted, remove from Isar
       e. Failure → markFailed (increment retryCount)
    3. Skip operations that exceeded max retries

  - Operation type mapping:
    sendMessage → _remoteDataSource.sendMessage(...)
    editMessage → _remoteDataSource.editMessage(...)
    deleteMessage → _remoteDataSource.editMessage(act: 'DELETE', ...)
    markAsRead → _remoteDataSource.markAsRead(...)
    addReaction → _remoteDataSource.updateReaction(act: 'ADD', ...)
    removeReaction → _remoteDataSource.updateReaction(act: 'REMOVE', ...)
    createGroup → _remoteDataSource.createGroup(...)
    editGroup → _remoteDataSource.updateGroup(...)
    leaveConversation → _remoteDataSource.leaveConversation(...)
    deleteConversation → _remoteDataSource.deleteConversation(...)

  - Auto-process triggers:
    1. ConnectivityService online → processQueue()
    2. RealtimeService socket connected → processQueue()
    3. Manual trigger from ChatBloc syncChats event
```

#### Step 1.3: Wire Enqueue into Local DataSource

```
Modify: chat_local_datasource.dart

In saveMessage(chatId, message, {needsSync = false}):
  - If needsSync == true:
    → Create OfflineOperationModel.createSendMessage(...)
    → Save to Isar OfflineOperationModel collection

In getPendingMessages():
  - Query Isar: OfflineOperationModel.where()
      .statusEqualTo(OperationStatus.pending)
      .or()
      .statusEqualTo(OperationStatus.failed)
      .filter()
      .typeEqualTo(OperationType.sendMessage)
      .findAll()
  - Convert to ChatMessage list
```

#### Step 1.4: Wire Processor into Connectivity Flow

```
Modify: chat_bloc.dart

In _onConnectivityChanged (isConnected: true):
  - After _triggerOnlineRefresh()
  - Call _offlineQueueProcessor.processQueue()

Register handler for ChatEvent.syncChats():
  - Call _offlineQueueProcessor.processQueue()
  - Emit result

In constructor:
  - Listen to _connectivityService → trigger processQueue on online
```

#### Step 1.5: Register in DI (BOTH modes)

```
Modify: injection.dart
  - Register IOfflineQueueService, OfflineQueueProcessor

Modify: chat_module_injection.dart
  - Same registrations for package mode
  - Add cleanup in logout() and dispose()
```

#### Testing Checklist:
- [ ] Enqueue sendMessage khi offline
- [ ] Process queue khi online restored
- [ ] Exponential backoff hoạt động đúng
- [ ] Max 5 retries, sau đó stop
- [ ] Queue persistent qua app restart (Isar)
- [ ] Multiple operations processed in order (FIFO)
- [ ] Failed operation không block subsequent operations
- [ ] Package mode: queue service cleanup trong logout/dispose

---

### Issue #2: Fix Stubs (`clearAll`, `deleteChat`, `markChatAsRead`, `getUnreadCount`)

**Problem:** 4 methods trong `ChatLocalDataSourceImpl` là stubs:
- `clearAll()` → `Future.delayed(10ms)` — logout không xóa data
- `deleteChat()` → no-op — leave/delete conversation không xóa khỏi Isar
- `markChatAsRead()` → non-functional loop
- `getUnreadCount()` → luôn return 0

**Impact:**
- Logout: user mới thấy data user cũ
- Delete/Leave: conversations vẫn hiện trong offline cache
- Unread count local không chính xác

**Files to modify:**

```
MODIFY: lib/features/chat/data/datasources/chat/chat_local_datasource.dart
MODIFY: lib/core/services/database_service.dart (nếu cần thêm methods)
```

**Implementation Steps:**

#### Step 2.1: Fix `clearAll()`

```dart
@override
Future<void> clearAll() async {
  try {
    await _databaseService.clearAllData();
    // clearAllData() đã có trong DatabaseService — nó clear tất cả Isar collections
    _logger.i('All local chat data cleared successfully');
  } catch (e) {
    _logger.e('Failed to clear all data: $e');
    rethrow;
  }
}
```

Verify `DatabaseService.clearAllData()` implementation:
- Trong `NativeDatabaseImplementation`: clear tất cả 6 collections
- Trong `WebDatabaseImplementation`: clear tất cả 6 collections

#### Step 2.2: Fix `deleteChat()`

```dart
@override
Future<void> deleteChat(String id) async {
  try {
    // 1. Find chat by serverId
    final chat = await _databaseService.getChatByServerId(id);
    if (chat == null) {
      _logger.w('Chat not found for deletion: $id');
      return;
    }

    // 2. Delete chat from Isar
    await _databaseService.deleteChat(chat.id);

    // 3. Delete associated messages
    // Lấy tất cả messages cho chatId này, xóa hết
    final messages = await _databaseService.getMessagesForChat(id);
    for (final msg in messages) {
      await _databaseService.deleteMessage(msg.id);
    }

    // 4. Delete associated draft
    // TODO: delete from ChatDraftModel where conversationId == id

    // 5. Delete sync metadata
    // TODO: delete from SyncMetadataModel where conversationId == id

    _logger.i('Chat $id deleted with cascade');
  } catch (e) {
    _logger.e('Failed to delete chat $id: $e');
    rethrow;
  }
}
```

Need to verify/add `DatabaseService` methods:
- `deleteChat(int isarId)` — exists in extension
- `deleteMessage(int isarId)` — exists in extension
- May need `deleteMessagesForChat(String chatServerId)` batch method

#### Step 2.3: Fix `markChatAsRead()`

```dart
@override
Future<void> markChatAsRead(String chatId) async {
  try {
    final chat = await _databaseService.getChatByServerId(chatId);
    if (chat == null) return;

    final updated = chat.resetUnread(); // copyWith(unreadCount: 0)
    await _databaseService.saveChat(updated);

    _logger.d('Chat $chatId marked as read locally');
  } catch (e) {
    _logger.e('Failed to mark chat as read: $e');
    rethrow;
  }
}
```

#### Step 2.4: Fix `getUnreadCount()`

```dart
@override
Future<int> getUnreadCount(String chatId) async {
  try {
    final chat = await _databaseService.getChatByServerId(chatId);
    return chat?.unreadCount ?? 0;
  } catch (e) {
    _logger.e('Failed to get unread count for $chatId: $e');
    return 0;
  }
}
```

#### Testing Checklist:
- [ ] `clearAll()` xóa tất cả data Isar (6 collections)
- [ ] `deleteChat()` xóa chat + messages + draft + sync metadata
- [ ] `markChatAsRead()` set unreadCount = 0
- [ ] `getUnreadCount()` return giá trị chính xác từ Isar
- [ ] Verify logout flow: clearAll → re-login → no stale data
- [ ] Verify leave chat: deleteChat → conversation biến mất khỏi list
- [ ] Web platform: cùng behavior (SQLite in-memory)

---

## Phase 2: Performance Fixes (P1)

### Issue #3: Batch `saveChats()` — Replace Sequential Writes

**Problem:** `saveChats()` iterates one-by-one: N lookups + N writes.
For 100 conversations: ~100 Isar reads + 100 Isar writes → slow.

**Files to modify:**

```
MODIFY: lib/features/chat/data/datasources/chat/chat_local_datasource.dart
MODIFY: lib/core/services/database_service.dart (thêm batch method nếu chưa có)
```

**Implementation:**

#### Step 3.1: Add Batch Method to DatabaseService

```dart
// In DatabaseServiceExtension:
Future<void> saveChats(List<ChatModel> chats) async {
  await _impl.collection<int, ChatModel>().putAll(chats);
}
```

#### Step 3.2: Optimize `saveChats()` in Local DataSource

```dart
@override
Future<void> saveChats(List<Chat> chats) async {
  if (chats.isEmpty) return;

  try {
    // 1. Batch fetch existing chats by serverIds
    final existingChats = await _databaseService.getChats();
    final existingMap = <String, ChatModel>{};
    for (final existing in existingChats) {
      existingMap[existing.serverId] = existing;
    }

    // 2. Build merged models list
    final mergedModels = <ChatModel>[];
    for (final chat in chats) {
      final existing = existingMap[chat.id];
      final chatModel = _buildMergedChatModel(chat, existing);
      mergedModels.add(chatModel);
    }

    // 3. Batch write
    await _databaseService.saveChats(mergedModels);

    _logger.d('Batch saved ${chats.length} chats');
  } catch (e) {
    _logger.e('Failed to batch save chats: $e');
    rethrow;
  }
}

ChatModel _buildMergedChatModel(Chat chat, ChatModel? existing) {
  // Extract merge logic from current saveChat() into reusable method
  final id = existing?.id ?? chat.id.toIsarId();
  final membersJson = chat.members.isNotEmpty
      ? jsonEncode(chat.members.map((m) => m.toJson()).toList())
      : existing?.membersJson;
  // ... same merge logic as current saveChat()
  return ChatModel(id: id, serverId: chat.id, ...);
}
```

**Performance gain:** 1 Isar query + 1 batch write thay vì N queries + N writes.
**Estimate:** ~10x faster cho 100+ conversations.

#### Testing Checklist:
- [ ] Batch save 100 chats < 100ms
- [ ] Merge logic preserve existing data (members, creator)
- [ ] Existing chats updated, new chats inserted
- [ ] No duplicate serverId violations

---

### Issue #4: Fix `getChatById()` — Use Index Instead of O(n)

**Problem:** Load TẤT CẢ chats → `firstWhere()` → O(n) scan.
`serverId` đã có unique index → nên dùng index query O(log n).

**Files to modify:**

```
MODIFY: lib/features/chat/data/datasources/chat/chat_local_datasource.dart
```

**Implementation:**

```dart
@override
Future<Chat?> getChatById(String id) async {
  try {
    // Use serverId index directly
    final chatModel = await _databaseService.getChatByServerId(id);
    if (chatModel == null) return null;
    return chatModel.toDomain();
  } catch (e) {
    _logger.e('Failed to get chat by id $id: $e');
    return null;
  }
}
```

`DatabaseService.getChatByServerId()` đã tồn tại trong `DatabaseServiceExtension` — sử dụng Isar index query.

**Performance gain:** O(log n) thay vì O(n). Với 500 chats: ~3 index lookups thay vì 500 iterations.

#### Testing Checklist:
- [ ] getChatById returns correct chat
- [ ] getChatById returns null for non-existent ID
- [ ] Performance: < 5ms cho single lookup

---

## Phase 3: Real-Time Completeness (P1)

### Issue #5: Handle `conversation:joined/leaved` Socket Events

**Problem:** Backend emit `conversation:joined` (khi user được add vào group) và `conversation:leaved` (khi user leave/bị remove). ChatBloc KHÔNG listen → conversation list không tự update.

**Files to modify:**

```
MODIFY: lib/core/services/realtime_service.dart
MODIFY: lib/features/chat/presentation/blocs/chat/chat_bloc.dart
MODIFY: lib/features/chat/presentation/blocs/chat/chat_event.dart
```

**Implementation:**

#### Step 5.1: Add Streams to RealtimeService

```dart
// New BehaviorSubjects:
final _conversationJoinedController = BehaviorSubject<String>(); // conversationId
final _conversationLeavedController = BehaviorSubject<String>(); // conversationId

// New streams:
Stream<String> get conversationJoinedStream => _conversationJoinedController.stream;
Stream<String> get conversationLeavedStream => _conversationLeavedController.stream;

// In _initializeSocketListeners():
_socketManager.on<Map<String, dynamic>>('conversation:joined').listen(
  (data) => _handleConversationJoined(data),
);
_socketManager.on<Map<String, dynamic>>('conversation:leaved').listen(
  (data) => _handleConversationLeaved(data),
);

void _handleConversationJoined(Map<String, dynamic> data) {
  final conversationId = data['conversationId'] as String?;
  if (conversationId != null) {
    _logger.i('Joined conversation: $conversationId');
    _conversationJoinedController.add(conversationId);
  }
}

void _handleConversationLeaved(Map<String, dynamic> data) {
  final conversationId = data['conversationId'] as String?;
  if (conversationId != null) {
    _logger.i('Left conversation: $conversationId');
    _conversationLeavedController.add(conversationId);
  }
}
```

#### Step 5.2: Add Events to ChatBloc

```dart
// In chat_event.dart:
const factory ChatEvent.conversationJoined({required String conversationId}) = _ConversationJoined;
const factory ChatEvent.conversationLeft({required String conversationId}) = _ConversationLeft;
```

#### Step 5.3: Handle Events in ChatBloc

```dart
// Register handlers:
on<_ConversationJoined>(_onConversationJoined);
on<_ConversationLeft>(_onConversationLeft);

// Subscribe in _subscribeToRealTimeUpdates():
_conversationJoinedSubscription = _realtimeService.conversationJoinedStream.listen(
  (conversationId) => add(ChatEvent.conversationJoined(conversationId: conversationId)),
);
_conversationLeavedSubscription = _realtimeService.conversationLeavedStream.listen(
  (conversationId) => add(ChatEvent.conversationLeft(conversationId: conversationId)),
);

// Handler: conversationJoined
Future<void> _onConversationJoined(_ConversationJoined event, Emitter emit) async {
  // Fetch conversation detail from remote
  final result = await _getConversationDetail.call(event.conversationId);
  result.fold(
    (failure) => _logger.e('Failed to load joined conversation: ${failure.message}'),
    (chat) {
      if (chat == null) return;
      state.maybeMap(
        loaded: (loaded) {
          // Prepend new conversation to list
          final updatedChats = [chat, ...loaded.chats];
          emit(loaded.copyWith(chats: updatedChats));
          // Save locally
          _localDataSource.saveChat(chat);
          // Invalidate tab caches
          _cacheSyncStrategy.markChatListDirty();
        },
        orElse: () {},
      );
    },
  );
}

// Handler: conversationLeft
Future<void> _onConversationLeft(_ConversationLeft event, Emitter emit) async {
  state.maybeMap(
    loaded: (loaded) {
      final updatedChats = loaded.chats.where((c) => c.id != event.conversationId).toList();
      // Also remove from all tab caches
      final updatedCachedLists = Map<ConversationTypeFilter, List<Chat>>.from(loaded.cachedLists);
      updatedCachedLists.forEach((key, value) {
        updatedCachedLists[key] = value.where((c) => c.id != event.conversationId).toList();
      });
      emit(loaded.copyWith(chats: updatedChats, cachedLists: updatedCachedLists));
      // Delete locally
      _localDataSource.deleteChat(event.conversationId);
      _cacheSyncStrategy.markChatListDirty();
    },
    orElse: () {},
  );
}
```

#### Testing Checklist:
- [ ] User được add vào group → conversation xuất hiện trong list
- [ ] User leave group → conversation biến mất khỏi list
- [ ] Tab caches được invalidate đúng
- [ ] Local Isar cập nhật
- [ ] Cancel subscriptions trong close()

---

### Issue #6: Update `lastMessagePreview` khi `message:edit/delete`

**Problem:** Khi ai đó edit/delete tin nhắn cuối cùng, conversation list preview không thay đổi.

**Files to modify:**

```
MODIFY: lib/features/chat/presentation/blocs/chat/chat_bloc.dart
MODIFY: lib/features/chat/presentation/blocs/chat/chat_event.dart
```

**Implementation:**

#### Step 6.1: Add Events

```dart
// In chat_event.dart:
const factory ChatEvent.messageEdited(ChatMessage message) = _MessageEdited;
const factory ChatEvent.messageDeleted(ChatMessage message) = _MessageDeleted;
```

#### Step 6.2: Subscribe in ChatBloc

```dart
// In _subscribeToRealTimeUpdates():
_messageEditedSubscription = _realtimeService.messageEditedStream.listen(
  (message) => add(ChatEvent.messageEdited(message)),
);
_messageDeletedSubscription = _realtimeService.messageDeletedStream.listen(
  (message) => add(ChatEvent.messageDeleted(message)),
);
```

#### Step 6.3: Handle Events

```dart
// Handler: messageEdited
Future<void> _onMessageEdited(_MessageEdited event, Emitter emit) async {
  state.maybeMap(
    loaded: (loaded) {
      final message = event.message;
      final chatIndex = loaded.chats.indexWhere((c) => c.id == message.chatId);
      if (chatIndex == -1) return;

      final chat = loaded.chats[chatIndex];
      // Only update if this IS the last message
      if (chat.lastMessageId == message.id) {
        final preview = _formatMessagePreview(message, chat.members);
        final updatedChat = chat.copyWith(lastMessagePreview: preview);
        final updatedChats = List<Chat>.from(loaded.chats);
        updatedChats[chatIndex] = updatedChat;
        emit(loaded.copyWith(chats: updatedChats));

        // Persist
        _localDataSource.saveChat(updatedChat);
      }
    },
    orElse: () {},
  );
}

// Handler: messageDeleted
Future<void> _onMessageDeleted(_MessageDeleted event, Emitter emit) async {
  state.maybeMap(
    loaded: (loaded) {
      final message = event.message;
      final chatIndex = loaded.chats.indexWhere((c) => c.id == message.chatId);
      if (chatIndex == -1) return;

      final chat = loaded.chats[chatIndex];
      if (chat.lastMessageId == message.id) {
        // Last message was deleted — show placeholder or previous message
        final updatedChat = chat.copyWith(
          lastMessagePreview: context.l10n.messageDeleted, // "Tin nhắn đã bị xóa"
        );
        final updatedChats = List<Chat>.from(loaded.chats);
        updatedChats[chatIndex] = updatedChat;
        emit(loaded.copyWith(chats: updatedChats));

        // Persist
        _localDataSource.saveChat(updatedChat);
      }
    },
    orElse: () {},
  );
}
```

**Note:** `_onMessageDeleted` dùng placeholder. Lý tưởng: fetch previous message từ local Isar, nhưng đó là improvement sau.

#### Step 6.4: Fix Parsing Inconsistency in RealtimeService

```dart
// In realtime_service.dart, _handleMessageDelete:
// BEFORE (inconsistent):
void _handleMessageDelete(Map<String, dynamic> data) {
  final messageData = data['message'] ?? data;
  final message = ChatMessage.fromJson(messageData); // ⛔ Wrong

// AFTER (consistent with other handlers):
void _handleMessageDelete(Map<String, dynamic> data) {
  final messageData = data['message'] ?? data;
  final dto = MessageDto.fromJson(messageData as Map<String, dynamic>);
  final message = dto.toDomain(); // ✅ Consistent
  _messageDeletedController.add(message);
}
```

#### Testing Checklist:
- [ ] Edit last message → preview updates
- [ ] Delete last message → preview shows placeholder
- [ ] Edit non-last message → no preview change
- [ ] Parsing consistent across all handlers
- [ ] Cancel subscriptions trong close()

---

## Phase 4: Infrastructure Improvements (P2)

### Issue #7: Wire SyncMetadata + GapDetection

**Problem:**
- `SyncMetadataModel` (52 lines, per-conversation timestamps) schema tồn tại nhưng không ai đọc/ghi
- `GapDetectionLogic.hasGap()` tồn tại nhưng không được gọi
- Kết quả: không có delta sync, luôn full refresh

**Files to modify/create:**

```
CREATE: lib/core/services/conversation_sync_service.dart
MODIFY: lib/features/chat/data/datasources/chat/chat_local_datasource.dart
MODIFY: lib/features/chat/data/repositories/chat_repository.dart
MODIFY: lib/data/strategies/gap_detection_logic.dart
MODIFY: lib/core/di/injection.dart
MODIFY: lib/core/di/chat_module_injection.dart
```

**Implementation:**

#### Step 7.1: Create `ConversationSyncService`

```
File: lib/core/services/conversation_sync_service.dart
Annotation: @lazySingleton

Dependencies:
  - DatabaseService (read/write SyncMetadataModel)
  - IChatRemoteDataSource
  - ChatLocalDataSource
  - AppLogger

Methods:
  - Future<SyncResult> syncConversations():
    1. Get SyncMetadata for conversation list (global entry)
    2. If no metadata → first sync → full fetch
    3. If has metadata:
       a. Fetch remote since lastKnownTimestamp
       b. deltaCount = remote.length
       c. GapDetectionLogic.hasGap(deltaCount, pageSize)?
          → YES: full refresh (gap too large)
          → NO: merge delta into local
    4. Update SyncMetadata with new timestamp

  - Future<void> updateSyncTimestamp(String conversationId, int timestamp):
    → Write/update SyncMetadataModel to Isar

  - Future<SyncMetadataModel?> getSyncMetadata(String conversationId):
    → Read from Isar by conversationId index

  - Future<void> clearSyncMetadata():
    → Clear all SyncMetadataModel entries
```

#### Step 7.2: Enhance GapDetectionLogic

```dart
class GapDetectionLogic {
  static bool hasGap({required int deltaCount, required int pageSize}) {
    return deltaCount >= pageSize;
  }

  // New: Determine sync strategy
  static SyncStrategy determineSyncStrategy({
    required int deltaCount,
    required int pageSize,
    required Duration timeSinceLastSync,
  }) {
    if (timeSinceLastSync.inHours > 24) return SyncStrategy.fullRefresh;
    if (hasGap(deltaCount: deltaCount, pageSize: pageSize)) return SyncStrategy.fullRefresh;
    return SyncStrategy.deltaSync;
  }
}

enum SyncStrategy { deltaSync, fullRefresh }
```

#### Step 7.3: Integrate into Repository

```
In ChatRepositoryImpl.getChatsPage():
  Before fetching remote:
    1. Get sync metadata
    2. Determine sync strategy
    3. Full refresh → fetch all pages
    4. Delta sync → fetch only since lastKnownTimestamp
    5. After success → update sync metadata

In ChatRepositoryImpl.getChats():
  Same integration
```

#### Testing Checklist:
- [ ] First sync: SyncMetadata created
- [ ] Delta sync: only new conversations fetched
- [ ] Gap detected: falls back to full refresh
- [ ] SyncMetadata persists across app restarts
- [ ] clearSyncMetadata works in logout flow

---

### Issue #8: Add Periodic Background Sync (30s Timer)

**Problem:** CLAUDE.md mentions "Periodic sync fallback every 30s" nhưng không có timer.
Chỉ có reactive sync khi connectivity thay đổi hoặc socket reconnect.

**Files to modify:**

```
MODIFY: lib/features/chat/presentation/blocs/chat/chat_bloc.dart
```

**Implementation:**

```dart
// In ChatBloc:
Timer? _periodicSyncTimer;
static const _periodicSyncInterval = Duration(seconds: 30);

// Start in constructor or after first successful load:
void _startPeriodicSync() {
  _periodicSyncTimer?.cancel();
  _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
    _onPeriodicSync();
  });
}

void _onPeriodicSync() {
  // Only sync if:
  // 1. Currently in loaded state
  // 2. Not already syncing
  // 3. Cache is dirty OR TTL expired
  state.maybeMap(
    loaded: (loaded) {
      if (loaded.isSyncing) return;
      if (_cacheSyncStrategy.shouldRefreshChatList()) {
        _logger.d('Periodic sync triggered');
        add(const ChatEvent.loadChats()); // Soft reload
      }
    },
    orElse: () {},
  );
}

// Cancel in close():
@override
Future<void> close() {
  _periodicSyncTimer?.cancel();
  // ... existing cleanup
  return super.close();
}

// Pause when app goes background (important for battery):
void _onAppLifecycleChange(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _periodicSyncTimer?.cancel();
  } else if (state == AppLifecycleState.resumed) {
    _startPeriodicSync();
  }
}
```

**Important considerations:**
- Timer chỉ trigger khi dirty/TTL → không spam requests
- Pause khi app background → tiết kiệm battery
- 30s interval phù hợp cho chat app (balance freshness vs resource)

#### Testing Checklist:
- [ ] Timer triggers every 30s
- [ ] Only fetches khi shouldRefresh() = true
- [ ] Timer pauses khi app background
- [ ] Timer resumes khi app foreground
- [ ] Timer cancelled trong close()
- [ ] Không overlap với manual refresh

---

### Issue #9: Optimize `getChats()` — Stop Fetching ALL Pages

**Problem:** Repository `getChats()` loops through ALL pages until total reached.
User 500+ conversations → nhiều round trips, chậm, tốn bandwidth.

**Files to modify:**

```
MODIFY: lib/features/chat/data/repositories/chat_repository.dart
```

**Implementation:**

```dart
// Option A: Replace getChats() full fetch with getChatsPage() single page
// Ưu tiên option này vì ChatBloc đã dùng getChatsPage()

@override
Future<Either<Failure, List<Chat>>> getChats() async {
  return _executeWithMonitoring('getChats', () async {
    try {
      // 1. Always return local first
      final localChats = await _localDataSource.getChats();

      // 2. If offline, return local
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        return Right(localChats);
      }

      // 3. Fetch ONLY first 2 pages (50 conversations) — enough for most users
      const maxInitialPages = 2;
      const pageSize = 25;
      final allChats = <Chat>[];
      var page = 0;

      while (page < maxInitialPages) {
        final response = await _remoteDataSource.getConversationList(
          size: pageSize,
          page: page,
        );
        final chats = response.conversations.map((dto) => dto.toDomain()).toList();
        allChats.addAll(chats);

        if (allChats.length >= response.total || chats.isEmpty) break;
        page++;
      }

      // 4. Save and return
      await _localDataSource.saveChats(allChats);
      final updatedChats = await _localDataSource.getChats();
      return Right(updatedChats);
    } on ServerException catch (e) {
      final localChats = await _localDataSource.getChats();
      if (localChats.isNotEmpty) return Right(localChats);
      return Left(ServerFailure(e.message));
    }
  });
}
```

**Alternative (Option B):** Nếu cần tất cả data cho search/filter:
- Background full sync sau khi hiện page 1
- Hoặc dùng server-side search thay vì local

#### Testing Checklist:
- [ ] Initial load chỉ fetch 2 pages max
- [ ] Pagination (loadMore) vẫn hoạt động cho các pages sau
- [ ] Offline fallback vẫn đúng
- [ ] Search vẫn hoạt động (server-side)

---

## Dependencies Between Issues

```
         ┌──────────────────────┐
         │ Phase 1: P0 Critical │
         │ #1 Offline Queue     │──────┐
         │ #2 Fix Stubs         │      │ #2.deleteChat required by
         └──────────┬───────────┘      │ #5.conversationLeft handler
                    │                  │
         ┌──────────▼───────────┐      │
         │ Phase 2: Performance │      │
         │ #3 Batch saveChats   │      │
         │ #4 Fix getChatById   │      │
         └──────────┬───────────┘      │
                    │                  │
         ┌──────────▼───────────┐◄─────┘
         │ Phase 3: Real-Time   │
         │ #5 Socket events     │
         │ #6 Edit/Delete prev  │
         └──────────┬───────────┘
                    │
         ┌──────────▼───────────┐
         │ Phase 4: Infra       │
         │ #7 SyncMetadata+Gap  │
         │ #8 Periodic sync     │
         │ #9 Optimize getChats │
         └──────────────────────┘
```

**Key dependency:** Issue #2 (`deleteChat` fix) phải xong trước Issue #5 (`conversation:leaved` handler) vì handler gọi `_localDataSource.deleteChat()`.

---

## Code Generation Required

Sau mỗi phase, chạy:

```bash
cd flutter_chat_app
dart run build_runner build --delete-conflicting-outputs  # freezed, json, injectable
flutter gen-l10n                                          # nếu thêm localization strings
```

Cụ thể:
- Phase 1: build_runner (nếu thêm @injectable classes)
- Phase 3: build_runner (thêm freezed events), gen-l10n (thêm `messageDeleted` string)
- Phase 4: build_runner (nếu thêm @injectable ConversationSyncService)

---

## DI Registration Checklist (Dual Mode)

Mỗi service mới cần register trong CẢ HAI:

| New Class | `injection.dart` | `chat_module_injection.dart` | Cleanup |
|---|---|---|---|
| `IOfflineQueueService` | ✅ Register | ✅ Register | logout + dispose |
| `OfflineQueueProcessor` | ✅ Register | ✅ Register | dispose |
| `ConversationSyncService` | ✅ Register | ✅ Register | logout + dispose |

Nếu dùng `@lazySingleton` annotation, verify trong `injection.config.dart` rằng:
- Không có `@Environment('standalone')` hoặc `@Environment('package')` filter
- Hoặc có cả hai environment markers

---

## Rollback Strategy

Mỗi phase được implement trong branch riêng:

```
feature/conversation-offline-queue     ← Phase 1
feature/conversation-perf-fixes        ← Phase 2
feature/conversation-realtime-events   ← Phase 3
feature/conversation-sync-infra        ← Phase 4
```

Nếu phase nào gây regression → revert branch mà không ảnh hưởng phases khác.

---

## Success Metrics

| Metric | Before | After | Target |
|---|---|---|---|
| Offline message delivery | ❌ Lost | ✅ Queued + retried | 100% delivery |
| Logout data cleanup | ❌ Stale data | ✅ Full clear | 0 stale entries |
| `saveChats(100)` | ~500ms | ~50ms | < 100ms |
| `getChatById()` | O(n) | O(log n) | < 5ms |
| Conversation list real-time | 60% events | 90% events | All critical events |
| Background sync interval | Never | Every 30s (when dirty) | 30s |
| First page load | All pages | 2 pages max | < 1s |
