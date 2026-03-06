# Conversation List — Cache, Local Storage & Sync Architecture

> Last updated: 2026-03-05
> Scope: Toàn bộ cơ chế lưu cache/local, sync (đồng bộ) danh sách cuộc trò chuyện trong Flutter app

---

## 1. Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                              │
│                                                                         │
│  ChatBloc (1097 lines)                                                  │
│  ├── 16 Events (9 có handler, 7 dead code)                             │
│  ├── 10 States (6 active, 4 unused)                                    │
│  ├── 6 Stream Subscriptions (message, typing, read, connectivity,      │
│  │                            socket connection state, chatUpdates*)    │
│  ├── Tab Filter Caching (cachedLists per filter)                       │
│  ├── Pagination State (per-filter page tracking)                       │
│  └── Typing Timer Management                                           │
│          * _chatUpdatesSubscription declared but never subscribed       │
└─────────────┬──────────────────────────────────┬────────────────────────┘
              │                                  │
              │ UseCases                         │ Real-time Streams
              ▼                                  ▼
┌─────────────────────────┐    ┌────────────────────────────────────────┐
│   DOMAIN LAYER           │    │   INFRASTRUCTURE SERVICES              │
│                          │    │                                        │
│ GetConversationsUseCase  │    │ RealtimeService (847 lines)            │
│ GetLocalConversations    │    │ ├── 8 BehaviorSubject streams          │
│ GetConversationDetail    │    │ ├── 8 Socket.IO event listeners        │
│ CreateGroupUseCase       │    │ └── Connection state management        │
│ UpdateGroupUseCase       │    │                                        │
│ LeaveConversationUseCase │    │ CacheSyncStrategy (283 lines)          │
│ DeleteConversation       │    │ ├── Dirty flags (4 categories)         │
│ SearchConversations      │    │ ├── TTL-based invalidation (5 min)     │
│ PersistIncomingMessage   │    │ └── Real-time event handlers           │
│ MarkAsReadUseCase        │    │                                        │
│ SearchMessagesUseCase    │    │ ConnectivityService (246 lines)         │
│                          │    │ ├── 2-layer check (transport + inet)   │
│ IChatRepository          │    │ └── Rate limiting (2s min interval)    │
│ (19 methods)             │    │                                        │
└─────────────┬────────────┘    │ ChatModuleEventBus                     │
              │                 │ └── Host app notification streams       │
              │                 └────────────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           DATA LAYER                                    │
│                                                                         │
│  ChatRepositoryImpl (979 lines)                                         │
│  ├── Offline-first pattern (check net → try remote → cache → fallback) │
│  ├── Auto-pagination (getChats fetches ALL pages)                      │
│  ├── Performance monitoring (_executeWithMonitoring)                    │
│  └── Smart cache (getChatById: local đủ? return, thiếu? fetch remote)  │
│                                                                         │
│  ┌──────────────────────────┐    ┌─────────────────────────────────┐   │
│  │ ChatLocalDataSourceImpl  │    │ ChatRemoteDataSourceImpl        │   │
│  │ (496 lines)              │    │ (846 lines)                     │   │
│  │                          │    │                                 │   │
│  │ ├── getChats()           │    │ ├── getConversationList()       │   │
│  │ ├── saveChat()           │    │ │   (GraphQL: chatConversation  │   │
│  │ ├── saveChats()          │    │ │    List, fetchPolicy:         │   │
│  │ ├── getChatById()        │    │ │    networkOnly)               │   │
│  │ ├── searchChats()        │    │ ├── getConversationDetail()     │   │
│  │ ├── deleteChat() ⛔STUB  │    │ ├── createGroup()              │   │
│  │ ├── clearAll()   ⛔STUB  │    │ ├── updateGroup()              │   │
│  │ └── markChatAsRead()     │    │ ├── leaveConversation()        │   │
│  │     ⚠️ Non-functional    │    │ ├── deleteConversation()       │   │
│  │                          │    │ ├── subscribeToChats()          │   │
│  └─────────┬────────────────┘    │ │   ⚠️ listens 'chat_updated'  │   │
│            │                     │ │   (event không tồn tại)       │   │
│            ▼                     │ └── 16 methods total            │   │
│  ┌──────────────────────────┐    └─────────────────────────────────┘   │
│  │ DatabaseService (912 L)  │                                          │
│  │ ├── Web: Isar SQLite     │    ┌─────────────────────────────────┐   │
│  │ │   in-memory + polling  │    │ GraphQL Operations (827 lines)  │   │
│  │ └── Native: Isar native  │    │ ├── ChatQueries (5 queries)    │   │
│  │     + real watch streams │    │ ├── ChatMutations (13 muts)    │   │
│  │                          │    │ └── ChatSubscriptions (4 subs) │   │
│  │ 6 Isar Schemas:          │    │     ⚠️ Use Socket.IO instead   │   │
│  │ ├── ChatModelSchema      │    └─────────────────────────────────┘   │
│  │ ├── ChatDraftModelSchema │                                          │
│  │ ├── MessageModelSchema   │    ┌─────────────────────────────────┐   │
│  │ ├── UserModelSchema      │    │ EnhancedSocketManager (411 L)   │   │
│  │ ├── OfflineOpSchema      │    │ ├── Rate limiting per event     │   │
│  │ └── SyncMetadataSchema   │    │ ├── Offline-first mode          │   │
│  └──────────────────────────┘    │ ├── Auto-sync on reconnect      │   │
│                                  │ └── Network quality monitoring   │   │
│                                  │                                  │   │
│                                  │ SocketManager (391 lines)        │   │
│                                  │ ├── WebSocket-only transport     │   │
│                                  │ ├── JWT auth (query+auth+header)│   │
│                                  │ ├── 5 reconnect attempts         │   │
│                                  │ └── Listener persistence system  │   │
│                                  └─────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Isar Local Database Schema

### 2.1 ChatModel — Bảng chính lưu conversations

**File:** `lib/data/models/chat_model.dart` (556 lines)

```
@collection ChatModel
├── id: int                     @Id() — Isar auto-increment
├── serverId: String            @Index(unique: true) — Server conversation ID
├── name: String?
├── description: String?
├── type: ChatType              @enumValue — direct | group | channel
├── groupType: String?          "Public" | "Private"
├── creatorId: String?
├── membersJson: String?        ⚠️ Members lưu dạng JSON STRING (không phải embedded objects)
├── lastMessageId: String?
├── lastMessagePreview: String?
├── lastMessageTime: DateTime?
├── unreadCount: int            default: 0
├── participantIds: List<String>
├── adminId: String?
├── avatarUrl: String?
├── isMuted: bool               default: false
├── isPinned: bool              default: false
├── createdAt: DateTime         @Index() — cho sorted queries
├── updatedAt: DateTime?
└── metadata: String?           Arbitrary JSON metadata
```

**Indexes:**
| Index | Column | Type | Mục đích |
|---|---|---|---|
| 1 | `serverId` | Unique | Lookup by server ID: O(log n) |
| 2 | `createdAt` | Non-unique | Sort by creation time |

**Helper Methods:**
| Method | Mục đích |
|---|---|
| `toDomain()` | Convert → `Chat` entity (parse `membersJson` → `ConversationMember`) |
| `copyWith({...})` | Immutable update (20 params) |
| `withLastMessage({messageId, preview, timestamp})` | Update last message fields |
| `incrementUnread()` | `unreadCount + 1` |
| `resetUnread()` | `unreadCount = 0` |
| `addParticipant(userId)` / `removeParticipant(userId)` | Manage participant list |
| `toggleMuted()` / `togglePinned()` | Toggle flags |
| `isUserAdmin(userId)` / `hasParticipant(userId)` | Query helpers |
| `static createDirectChat(...)` | Factory: validates 2 participants |
| `static createGroupChat(...)` | Factory: validates non-empty + admin in participants |
| `static createChannel(...)` | Factory: channel creation |

**Trade-offs:**
- `membersJson` as JSON string → Đơn giản schema nhưng không query được theo member fields
- Phải parse JSON mỗi lần đọc → overhead cho conversations có nhiều members

### 2.2 SyncMetadataModel — Metadata đồng bộ per-conversation

**File:** `lib/data/models/sync_metadata_model.dart` (52 lines)

```
@collection SyncMetadataModel
├── id: int                     @Id()
├── conversationId: String      @Index(unique: true)
├── lastKnownTimestamp: int     Epoch ms — timestamp message cuối biết
├── lastSyncTime: int           Epoch ms — lần sync cuối
└── updatedAt: int              @Index() — cho TTL cleanup
```

**Trạng thái:** ⛔ **Schema tồn tại nhưng KHÔNG ĐƯỢC SỬ DỤNG** — không có code đọc/ghi collection này.

### 2.3 OfflineOperationModel — Queue thao tác offline

**File:** `lib/data/models/offline_operation_model.dart` (375 lines)

```
@collection OfflineOperationModel
├── id: int                     @Id()
├── operationId: String         @Index(unique: true) — UUID
├── type: OperationType         @enumValue
├── data: String                JSON serialized operation data
├── timestamp: DateTime         @Index() — thời điểm tạo
├── retryCount: int             default: 0 (max: 5)
├── status: OperationStatus     @enumValue — pending | processing | completed | failed
├── errorMessage: String?
└── lastRetryAt: DateTime?

enum OperationType:
  sendMessage, editMessage, deleteMessage, markAsRead,
  addReaction, removeReaction, createGroup, editGroup,
  leaveConversation, deleteConversation

enum OperationStatus:
  pending, processing, completed, failed
```

**Retry Logic (Exponential Backoff):**
```
Retry 0: chờ 1s  (2^0)
Retry 1: chờ 2s  (2^1)
Retry 2: chờ 4s  (2^2)
Retry 3: chờ 8s  (2^3)
Retry 4: chờ 16s (2^4)
Retry 5: STOP — max retries reached
```

**Factory Methods:**
`createSendMessage()`, `createEditMessage()`, `createDeleteMessage()`, `createMarkAsRead()`,
`createAddReaction()`, `createRemoveReaction()`, `createCreateGroup()`, `createEditGroup()`,
`createLeaveConversation()`, `createDeleteConversation()`

**Trạng thái:** ⛔ **Schema + factory methods đầy đủ, nhưng KHÔNG CÓ PROCESSOR** — không code nào enqueue hoặc process operations.

### 2.4 ChatDraftModel — Draft messages

**File:** `lib/data/models/chat_draft_model.dart`

Lưu draft messages per conversation. **Hoạt động đầy đủ.**

---

## 3. Local DataSource — Đọc/Ghi Isar

**File:** `lib/features/chat/data/datasources/chat/chat_local_datasource.dart` (496 lines)
**Class:** `ChatLocalDataSourceImpl` (`@lazySingleton`)
**Dependency:** `DatabaseService`

### Interface: `ChatLocalDataSource` — 14 methods

### Implementation Chi Tiết:

#### `getChats()` — Đọc tất cả conversations
```
DatabaseService.getChats()
    → Isar: chatModels.where().findAll()
    → Sort: lastMessageTime DESC, name ASC (tie-breaker)
    → Map: ChatModel.toDomain() → List<Chat>
```
**Complexity:** O(n log n) cho sort, O(n) cho mapping

#### `saveChat(Chat chat)` — Upsert 1 conversation
```
1. DatabaseService.getChatByServerId(chat.id)  // Check existing
2. Nếu existing → giữ Isar ID, merge data:
   - Preserve membersJson nếu new chat không có members
   - Preserve creatorId nếu không provided
   - Preserve createdAt nếu không provided
3. DatabaseService.saveChat(chatModel)          // Isar put()
```

#### `saveChats(List<Chat> chats)` — Bulk upsert
```
for (chat in chats) {
    getChatByServerId()  // 1 query per chat
    merge data
    saveChat()           // 1 write per chat
}
```
**⛔ Performance Issue:** O(n) individual lookups + O(n) individual writes. Nên dùng batch `putAll()`.

#### `getChatById(String id)` — Tìm theo server ID
```
getChats()       // Load TẤT CẢ chats
.firstWhere()    // Linear search
```
**⛔ Performance Issue:** O(n) thay vì dùng `serverId` unique index (O(log n)).

#### `searchChats(String searchTerm)` — Tìm kiếm
```
getChats()
.where((chat) => chat.name.contains(searchTerm))
```
In-memory search. OK cho < 500 chats.

#### `deleteChat(String id)` — ⛔ STUB
```dart
// TODO: Implement proper cascade delete in database service
debugPrint('deleteChat called for id: $id');
// Không xóa gì cả
```

#### `clearAll()` — ⛔ STUB
```dart
Future.delayed(Duration(milliseconds: 10));
// Không clear gì cả
```

#### `markChatAsRead(String chatId)` — ⚠️ Non-functional
Chứa hardcoded string `'current_user'` và loop không thay đổi data thực tế.

#### `getPendingMessages()` — ⛔ STUB
Luôn return `[]`. Comment: "would need proper flag in real implementation".

#### `saveMessage()` — needsSync bị ignore
```dart
// TODO: If needsSync is true, we would add to a sync queue
```
Parameter `needsSync` được nhận nhưng không sử dụng.

#### `getUnreadCount(String chatId)` — ⛔ STUB
Luôn return `0`.

---

## 4. Remote DataSource — GraphQL API

**File:** `lib/features/chat/data/datasources/chat/chat_remote_datasource.dart` (846 lines)
**Class:** `ChatRemoteDataSourceImpl` (`@LazySingleton(as: IChatRemoteDataSource)`)
**Dependencies:** `GraphQLClientWrapper`, `EnhancedSocketManager`

### GraphQL Operations sử dụng:

| Method | GraphQL Operation | Response Key | FetchPolicy |
|---|---|---|---|
| `getConversationList()` | `chatConversationList(filters:)` | `chatConversationList` | `networkOnly` |
| `getConversationDetail()` | `chatConversationDetail(conversationId:, receiverId:)` | `chatConversationDetail` | `networkOnly` |
| `getConversationMembers()` | `chatConversationDetail(conversationId:)` | `chatConversationDetail` | `networkOnly` |
| `createGroup()` | `chatGroupAdd(arguments:)` | `chatGroupAdd` | — |
| `updateGroup()` | `chatGroupEdit(arguments:)` | `chatGroupEdit` | — |
| `leaveConversation()` | `chatConversationLeave(arguments:)` | `chatConversationLeave` | — |
| `deleteConversation()` | `chatConversationDelete(arguments:)` | `chatConversationDelete` | — |
| `sendMessage()` | `chatMessageAdd(arguments:)` | `chatMessageAdd` | — |
| `editMessage()` | `chatMessageEdit(arguments:)` | `chatMessageEdit` | — |
| `markAsRead()` | `chatMessageUpdateRead(arguments:)` | `chatMessageUpdateRead` | — |
| `updateReaction()` | `chatMessageUpdateReaction(arguments:)` | `chatMessageUpdateReaction` | — |
| `deleteHistory()` | `chatMessageDeleteHistory(arguments:)` | `chatMessageDeleteHistory` | — |
| `searchMessages()` | `chatSearch(filters:)` | `chatSearch` | — |

### Pagination Parameters:
```dart
variables = {
  'filters': {
    'size': 25,       // items per page
    'page': 0,        // 0-indexed page number
    'keyword': ...,   // optional search term
    'type': ...,      // optional: "Direct" | "Group"
  }
};
```

### GraphQL Response Fields (getConversationList):
```graphql
chatConversationList(filters: $filters) {
  total
  conversations {
    id, groupType, lastMessageAt, lastMessageId, name, type, description, imgUrl, createdAt
    lastMessage {
      id, message, fileName, type
      sender { id, fullname }
      mentionTo { id, fullname }
    }
    personalConversation { lastMessageReadId, unreadCount }
    creator { id, fullname, imageUrls }
    members {
      id, userId, admin, connected, hide, unreadCount, lastMessageReadId, viewMessagesFrom
      user { id, fullname, imageUrls, statusActive, offlineAt }
    }
  }
}
```

### Field Mapping (Backend → DTO → Domain):

| Backend Field | DTO Field | Domain Entity Field |
|---|---|---|
| `imgUrl` | `imageUrl` (`@JsonKey(name: 'imgUrl')`) | `avatarUrl` |
| `fullname` | `fullName` (`@JsonKey(name: 'fullname')`) | `fullName` |
| `personalConversation.unreadCount` | nested DTO | `unreadCount` |
| `statusActive` | `"online"/"offline"` string | `isConnected` (bool) |
| `lastMessageAt` | epoch timestamp (num) | `lastMessageTime` (DateTime) |
| `admin` | bool | `isAdmin` |

### `subscribeToChats()` — ⚠️ Dead Code
```dart
Stream<ChatDto> subscribeToChats() {
  _socketManager.connect();
  return _socketManager
      .on<Map<String, dynamic>>('chat_updated')  // ⛔ Event không tồn tại trên backend
      .map((data) => ChatDto.fromJson(data));
}
```
Backend emit: `message:sent`, `conversation:joined`, `conversation:leaved` — KHÔNG có `chat_updated`.

---

## 5. DTO to Domain Mapping

**File:** `lib/data/dtos/chat_dto.dart` (425 lines)

### DTO Class Hierarchy:
```
ChatListResponseDto
├── total: int
└── conversations: List<ChatDto>

ChatDto
├── id, name, type, description, imageUrl, groupType
├── createdAt, lastMessageAt, lastMessageId
├── lastMessage: LastMessageDto?
│   ├── id, message, fileName, type
│   ├── sender: UserBriefDto?
│   └── mentionTo: MentionToDto?
├── personalConversation: PersonalConversationDto?
│   ├── lastMessageReadId
│   └── unreadCount
├── creator: CreatorDto?
│   ├── id, fullName, imageUrls
└── members: List<MemberDto>
    ├── id, userId, admin, connected, hide, unreadCount
    ├── lastMessageReadId, viewMessagesFrom
    └── user: UserDto?
        ├── id, fullName, imageUrls, email
        ├── statusActive, offlineAt
        └── departments: List<UserDepartmentDto>
```

### `ChatDto.toDomain()` — Conversion Logic:
```
1. Map MemberDto[] → ConversationMember[]
   - Resolve nested user object
   - Map statusActive string → isConnected bool
2. Build mentionNameById: Map<String, String>
   - From members (userId → fullName)
   - From lastMessage.mentionTo
3. Format lastMessagePreview:
   - System events → "Thong bao he thong" (hardcoded Vietnamese ⚠️)
   - Image → "Photo"
   - File → filename
   - Text → resolve @mentions to display names
4. Map type string → ChatType enum
5. Extract unreadCount from personalConversation or first member
6. Return Chat entity
```

---

## 6. Repository — Offline-First Pattern

**File:** `lib/features/chat/data/repositories/chat_repository.dart` (979 lines)
**Class:** `ChatRepositoryImpl` (`@LazySingleton(as: IChatRepository)`)
**Dependencies:** `ChatLocalDataSource`, `IChatRemoteDataSource`, `INetworkInfo`, `AppLogger`

### 6.1 `getChats()` — Full list, auto-paginate tất cả pages

```
┌─────────────────────────────────────────────┐
│ 1. Load local cache ngay lập tức            │
│    _localDataSource.getChats()              │
├─────────────────────────────────────────────┤
│ 2. Check network                            │
│    _networkInfo.isConnected                 │
├──────────────┬──────────────────────────────┤
│ OFFLINE      │ ONLINE                       │
│ return local │ 3. Auto-paginate ALL pages:  │
│              │    while (true) {            │
│              │      fetch page (size=25)    │
│              │      accumulate allDtos      │
│              │      break when done         │
│              │    }                         │
│              │ 4. Convert DTOs → entities   │
│              │ 5. Save ALL → Isar           │
│              │ 6. Re-read from local        │
│              │ 7. Return Right(updated)     │
│              │                              │
│              │ On Error → fallback local    │
└──────────────┴──────────────────────────────┘
```

### 6.2 `getChatsPage(PageRequest, typeFilter?)` — Single page

```
┌─────────────────────────────────────────────┐
│ 1. Load local cache                         │
├──────────────┬──────────────────────────────┤
│ OFFLINE      │ ONLINE                       │
│ Paginated    │ 2. Fetch 1 page remote       │
│ slice of     │ 3. Save page → Isar          │
│ local cache  │ 4. Return PagedResult        │
│              │                              │
│              │ On Error → slice of local    │
└──────────────┴──────────────────────────────┘
```

### 6.3 `getChatById(id)` — Smart cache strategy

```
┌─────────────────────────────────────────────┐
│ 1. Try local first                          │
│    _localDataSource.getChatById(id)         │
├─────────────────────────────────────────────┤
│ 2. Local có + đủ data (members + creator)?  │
│    → Return Right(local) ngay               │
├─────────────────────────────────────────────┤
│ 3. Local có nhưng thiếu data?               │
│    → Fall through to remote                 │
├──────────────┬──────────────────────────────┤
│ OFFLINE      │ ONLINE                       │
│ Return local │ 4. Fetch remote detail       │
│ (dù thiếu)  │ 5. Save → Isar              │
│              │ 6. Return Right(remote)      │
└──────────────┴──────────────────────────────┘
```

### 6.4 Performance Monitoring

Mỗi method được wrap trong `_executeWithMonitoring()`:
```dart
Future<Either<Failure, T>> _executeWithMonitoring<T>(
  String operationName,
  Future<Either<Failure, T>> Function() operation,
) async {
  final stopwatch = Stopwatch()..start();
  final result = await operation();
  stopwatch.stop();
  _recordOperation(operationName, stopwatch.elapsed);
  if (stopwatch.elapsedMilliseconds > 500) {
    _logger.w('Slow operation: $operationName took ${stopwatch.elapsedMilliseconds}ms');
  }
  return result;
}
```

---

## 7. ChatBloc — State Management

**File:** `lib/features/chat/presentation/blocs/chat/chat_bloc.dart` (1097 lines)
**Class:** `ChatBloc extends Bloc<ChatEvent, ChatState> with BlocErrorMixin`
**DI:** `@injectable` (factory — new instance each time)
**Dependencies:** 16 constructor parameters

> ⚠️ **Violations:** Extends `Bloc` thay vì `BaseBloc`; `ChatState` không extends `BaseState`

### 7.1 Dependencies

| Dependency | Type | Mục đích |
|---|---|---|
| `_getConversations` | `GetConversationsUseCase` | Fetch paginated from remote |
| `_getLocalConversations` | `GetLocalConversationsUseCase` | Fetch from local Isar |
| `_getConversationDetail` | `GetConversationDetailUseCase` | Single conversation detail |
| `_createGroup` | `CreateGroupUseCase` | Create group conversation |
| `_updateGroup` | `UpdateGroupUseCase` | Edit group info |
| `_leaveConversation` | `LeaveConversationUseCase` | Leave a conversation |
| `_deleteConversation` | `DeleteConversationUseCase` | ⚠️ Injected nhưng KHÔNG SỬ DỤNG |
| `_searchConversations` | `SearchConversationsUseCase` | Search conversations |
| `_connectivityService` | `ConnectivityService` | Online/offline detection |
| `_cacheSyncStrategy` | `CacheSyncStrategy` | Dirty flag management |
| `_mediaCacheManager` | `MediaCacheManager` | Avatar pre-fetching |
| `_realtimeService` | `RealtimeService` | Socket.IO streams |
| `_markAsRead` | `MarkAsReadUseCase` | Mark messages as read |
| `_currentUserProvider` | `CurrentUserProvider` | Current user ID |
| `_persistIncomingMessage` | `PersistIncomingMessageUseCase` | Save incoming messages |
| `_eventBus` | `ChatModuleEventBus` | Host app notifications |

### 7.2 Events (20 total)

| Event | Handler | Trạng thái |
|---|---|---|
| `loadChats({bool forceRefresh})` | `_onLoadChats` | ✅ Active |
| `loadMoreChats()` | `_onLoadMoreChats` | ✅ Active |
| `loadChatDetails({chatId})` | `_onLoadChatDetails` | ✅ Active |
| `createChat({type, name, desc, participantIds})` | `_onCreateChat` | ✅ Active |
| `updateChat({chatId, name, desc, avatar})` | `_onUpdateChat` | ✅ Active |
| `leaveChat({chatId})` | `_onLeaveChat` | ✅ Active |
| `markMessagesAsRead({chatId, messageIds})` | `_onMarkMessagesAsRead` | ✅ Active |
| `newMessageReceived(ChatMessage)` | `_onNewMessageReceived` | ✅ Active |
| `connectivityChanged(bool)` | `_onConnectivityChanged` | ✅ Active |
| `chatUpdated({Chat})` | `_onChatUpdated` | ✅ Active |
| `searchChats({keyword})` | `_onSearchChats` | ✅ Active |
| `clearSearch()` | `_onClearSearch` | ✅ Active |
| `changeConversationTypeFilter({filter})` | `_onChangeConversationTypeFilter` | ✅ Active |
| `loadMessages({chatId, limit, offset})` | — | ⛔ NO HANDLER |
| `sendMessage({chatId, content, type, attachmentIds})` | — | ⛔ NO HANDLER |
| `addUsersToChat({chatId, userIds})` | — | ⛔ NO HANDLER |
| `removeUsersFromChat({chatId, userIds})` | — | ⛔ NO HANDLER |
| `syncChats()` | — | ⛔ NO HANDLER |
| `syncMessages({chatId})` | — | ⛔ NO HANDLER |
| `messageStatusUpdated(QueuedMessage)` | — | ⛔ NO HANDLER |

### 7.3 States

| State | Fields | Trạng thái sử dụng |
|---|---|---|
| `initial()` | — | ✅ |
| `loading()` | — | ✅ |
| `loaded(...)` | 11 fields (xem dưới) | ✅ Primary |
| `chatDetailsLoaded({Chat})` | chat | ✅ |
| `offline()` | — | ✅ |
| `error({String message})` | message | ✅ |
| `messagesLoading({List<Chat>?})` | chats | ⛔ Unused |
| `messagesLoaded({chats, chatId, messages})` | 3 fields | ⛔ Unused |
| `messageSending({chatId, localId})` | 2 fields | ⛔ Unused |
| `messageStatusChanged({chatId, localId, status, serverId?})` | 4 fields | ⛔ Unused |
| `syncing()` | — | ⛔ Unused |

**`loaded` state chi tiết:**
```dart
factory ChatState.loaded({
  required List<Chat> chats,
  @Default(true) bool hasMore,
  @Default(false) bool isLoadingMore,
  @Default(0) int page,
  @Default(25) int pageSize,
  @Default(0) int total,
  @Default(ConversationTypeFilter.all) ConversationTypeFilter activeFilter,
  @Default({}) Map<ConversationTypeFilter, List<Chat>> cachedLists,
  @Default({}) Map<ConversationTypeFilter, int> filterPages,
  @Default({}) Map<ConversationTypeFilter, bool> filterHasMore,
  @Default(false) bool isSyncing,
})
```

### 7.4 Cache-First Loading Pattern (`_onLoadChats`)

```
╔══════════════════════════════════════════════════════════════╗
║  Phase 1: INSTANT UI (< 50ms)                               ║
║                                                              ║
║  GetLocalConversationsUseCase.call()                         ║
║    → ChatRepositoryImpl.getChatsFromLocalStorage()           ║
║      → ChatLocalDataSourceImpl.getChats()                    ║
║        → Isar query → sort → toDomain()                     ║
║                                                              ║
║  Có data + không forceRefresh?                               ║
║  ├── YES → Emit loaded(chats: localChats, isSyncing: true)  ║
║  │         _prefetchAvatars(localChats)                      ║
║  │         _subscribeToRealTimeUpdates()                     ║
║  └── NO  → Emit loading() (shimmer skeleton)                ║
╠══════════════════════════════════════════════════════════════╣
║  Phase 2: BACKGROUND SYNC                                    ║
║                                                              ║
║  _cacheSyncStrategy.shouldRefreshChatList()?                 ║
║  ├── dirty flag == true? → YES                              ║
║  ├── last update > 5 min? → YES                             ║
║  └── otherwise → NO                                         ║
║                                                              ║
║  GetConversationsUseCase.call(PageRequest.first(size: 25))   ║
║    → ChatRepositoryImpl.getChatsPage()                       ║
║      → Remote fetch → Save to Isar → Return PagedResult     ║
║                                                              ║
║  Success:                                                    ║
║  ├── _cacheSyncStrategy.resetChatListDirtyFlag()             ║
║  ├── Update cachedLists[activeFilter]                        ║
║  ├── Calculate total unread → EventBus.emitUnreadCount()     ║
║  └── Emit loaded(chats: remoteChats, isSyncing: false)       ║
║                                                              ║
║  Failure:                                                    ║
║  ├── Có local cache? → Giữ cache, clear isSyncing           ║
║  └── Không cache? → Emit error(message)                      ║
╚══════════════════════════════════════════════════════════════╝
```

### 7.5 Tab Filter Caching

```dart
// BLoC state duy trì cache riêng cho mỗi tab:
Map<ConversationTypeFilter, List<Chat>> cachedLists = {
  ConversationTypeFilter.all:    [...],  // Tất cả
  ConversationTypeFilter.direct: [...],  // Tin nhắn trực tiếp
  ConversationTypeFilter.group:  [...],  // Nhóm
};
Map<ConversationTypeFilter, int> filterPages = {
  ConversationTypeFilter.all:    0,
  ConversationTypeFilter.direct: 1,
  ...
};
Map<ConversationTypeFilter, bool> filterHasMore = {
  ConversationTypeFilter.all:    true,
  ...
};
```

**Khi chuyển tab:**
```
1. Cache list hiện tại vào cachedLists[currentFilter]
2. Kiểm tra cachedLists[newFilter] có data?
   ├── YES → Hiển thị ngay (zero latency tab switch)
   └── NO  → Fetch remote với type filter, save cache
```

### 7.6 Pagination (Infinite Scroll)

```
_onLoadMoreChats:
  Guard: !isLoadingMore && hasMore
  1. Emit isLoadingMore: true
  2. GetConversationsUseCase(page: currentPage + 1, typeFilter)
  3. Merge new items vào existing list (dedup by ID)
  4. Update cachedLists, filterPages, filterHasMore
  5. Emit updated loaded state
```

### 7.7 Stream Subscriptions

| Stream | Source | Handler | Mục đích |
|---|---|---|---|
| `_messageSubscription` | `_realtimeService.messageStream` | `ChatEvent.newMessageReceived()` | Tin nhắn mới |
| `_typingSubscription` | `_realtimeService.typingStream` | `_applyTypingIndicator()` | Typing indicator |
| `_readReceiptSubscription` | `_realtimeService.readReceiptStream` | `_applyReadReceipt()` | Read receipts |
| `_connectivitySubscription` | `_connectivityService.onConnectivityChanged` | `ChatEvent.connectivityChanged()` | Online/offline |
| `_connectionStateSubscription` | `_realtimeService.connectionState` | `_triggerOnlineRefresh()` | Socket reconnect |
| `_chatUpdatesSubscription` | — | — | ⛔ Declared nhưng NEVER subscribed |

### 7.8 Typing Indicator Management

```
_typingTimers: Map<String, Timer>
  Key: "chatId:userId"
  Value: Timer (5 second timeout)

Flow:
  Socket 'message:typing' → RealtimeService → TypingIndicator
    → ChatBloc._applyTypingIndicator()
      → isTyping: true → Start/reset timer → Update state
      → isTyping: false → Cancel timer → Clear state
      → Timer expires (5s) → Auto-clear
```

---

## 8. Real-Time Updates via Socket.IO

**File:** `lib/core/services/realtime_service.dart` (847 lines)
**Class:** `RealtimeService` (`@lazySingleton`)
**Dependency:** `EnhancedSocketManager`

### 8.1 Socket Event Listeners

| Socket Event | Handler | Output Stream | ChatBloc listens? |
|---|---|---|---|
| `message:sent` | `_handleNewMessage` | `messageStream` | ✅ YES |
| `message:edit` | `_handleMessageEdit` | `messageEditedStream` | ❌ NO (ChatBloc doesn't subscribe) |
| `message:delete` | `_handleMessageDelete` | `messageDeletedStream` | ❌ NO |
| `message:reaction` | `_handleMessageReaction` | `messageReactionStream` | ❌ NO |
| `message:typing` | `_handleTypingIndicator` | `typingStream` | ✅ YES |
| `message:read` | `_handleReadReceipt` | `readReceiptStream` | ✅ YES |
| `user:presence` | `_handleUserPresence` | `presenceStream` | ❌ NO |
| `user:status` | `_handleUserStatus` | `userStatusStream` | ❌ NO |

### 8.2 Data Flow: Tin Nhắn Mới → Conversation List Update

```
Backend emits 'message:sent' → {message: {...}, conversationId: ...}
    │
    ▼
EnhancedSocketManager.on<Map>('message:sent')
    │
    ▼
RealtimeService._handleNewMessage(Map data)
    ├── Extract messageData = data['message'] ?? data
    ├── MessageDto.fromJson(messageData)
    ├── messageDto.toDomain() → ChatMessage
    └── _messageController.add(chatMessage)  // BehaviorSubject
    │
    ▼
ChatBloc._messageSubscription.listen()
    └── add(ChatEvent.newMessageReceived(message))
    │
    ▼
ChatBloc._onNewMessageReceived(message, emit)
    │
    ├── 1. Tìm conversation:
    │   state.chats.firstWhere(c => c.id == message.chatId)
    │
    ├── 2. Format preview:
    │   _formatMessagePreview(message, chat.members)
    │   - Image → "Photo"
    │   - File → fileName
    │   - Text → resolve @mentions
    │
    ├── 3. Update chat object:
    │   chat.copyWith(
    │     lastMessageTime: message.createdAt,
    │     lastMessagePreview: preview,
    │     lastMessageId: message.id,
    │     unreadCount: isIncoming ? chat.unreadCount + 1 : chat.unreadCount,
    │   )
    │
    ├── 4. Re-sort list:
    │   updatedChats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime))
    │   // Chat mới nhất bubble lên đầu
    │
    ├── 5. Emit state:
    │   emit(loaded(chats: updatedChats, ...))
    │
    ├── 6. Async persist (fire-and-forget):
    │   _persistIncomingMessage.call(PersistIncomingMessageParams(
    │     chatId: message.chatId,
    │     message: message,
    │     chat: updatedChat,
    │   ))
    │
    └── 7. Notify host app:
        _eventBus.emitNewMessage(message)
        _eventBus.emitUnreadCount(totalUnread)
```

### 8.3 Parsing Inconsistency

| Handler | Parsing Method |
|---|---|
| `_handleNewMessage` | `MessageDto.fromJson(data) → .toDomain()` ✅ |
| `_handleMessageEdit` | `MessageDto.fromJson(data) → .toDomain()` ✅ |
| `_handleMessageDelete` | `ChatMessage.fromJson(data)` ⛔ **Inconsistent** |

### 8.4 Socket Events CHƯA Xử Lý Cho Conversation List

| Backend Event | Ảnh hưởng conversation list | Xử lý hiện tại |
|---|---|---|
| `conversation:joined` | Conversation mới xuất hiện | ⛔ Không xử lý |
| `conversation:leaved` | Conversation bị xóa khỏi list | ⛔ Không xử lý |
| `message:edit` | lastMessagePreview thay đổi | ⛔ Không update preview |
| `message:delete` | lastMessagePreview thay đổi | ⛔ Không update preview |

---

## 9. Cache Sync Strategy (Dirty Flags)

**File:** `lib/core/cache/cache_sync_strategy.dart` (283 lines)
**Class:** `CacheSyncStrategy` (`@lazySingleton`)

> ⚠️ **Conflicting DI:** Cả manual singleton (`_instance` + factory) VÀ `@lazySingleton` annotation

### 9.1 Dirty Flags

| Flag | Type | Ảnh hưởng |
|---|---|---|
| `_chatListDirty` | `bool` | Toàn bộ conversation list |
| `_userDataDirty` | `bool` | User profile data |
| `_chatDetailsDirty` | `Map<String, bool>` | Per-conversation detail |
| `_chatMessagesDirty` | `Map<String, bool>` | Per-conversation messages |
| `_lastChatListUpdate` | `DateTime?` | TTL tracking |

### 9.2 TTL-Based Invalidation

```dart
bool shouldRefreshChatList() {
  if (_chatListDirty) return true;
  if (_lastChatListUpdate == null) return true;
  final elapsed = DateTime.now().difference(_lastChatListUpdate!);
  return elapsed.inMinutes >= 5;  // 5 phút TTL
}
```

### 9.3 Real-Time Event Handling

```
handleRealTimeEvent(eventType, data):
  switch (eventType):
    'new_message' / 'message_updated' / 'message_deleted':
      → markChatMessagesDirty(chatId)
      → markChatListDirty()           // lastMessage thay đổi
      → _invalidateMessageCache(...)

    'chat_created' / 'chat_updated' / 'chat_deleted':
      → markChatListDirty()
      → markChatDetailsDirty(chatId)
      → _invalidateChatCache(chatId)

    'user_updated' / 'user_status_changed':
      → markUserDataDirty()
      → _invalidateUserCache(userId)
```

> ⚠️ Event type strings (`'new_message'`, `'chat_created'`) **KHÔNG match** Socket.IO events (`message:sent`, `conversation:joined`). Cần mapping layer.

### 9.4 Flow: Connectivity Restored → Cache Invalidation → Reload

```
ConnectivityService: offline → online
    │
    ▼
ChatBloc._connectivitySubscription
    │
    ▼
_triggerOnlineRefresh() (cooldown 2 giây dedup)
    ├── _cacheSyncStrategy.markChatListDirty()
    └── add(ChatEvent.loadChats())  // SOFT reload
    │
    ▼
_onLoadChats():
    ├── Hiện cache cũ ngay (KHÔNG shimmer) + isSyncing: true
    ├── shouldRefreshChatList() → true (dirty flag)
    ├── Fetch remote
    └── Update UI silently
```

---

## 10. Socket Connection & Room Management

### 10.1 Connection Stack

```
SocketManager (391 lines, @injectable)
  ├── WebSocket-only transport (no polling)
  ├── JWT auth: query.token + auth.token + headers.Authorization
  ├── Reconnection: 5 attempts, 1s–5s delay, exponential backoff
  └── Listener persistence: re-attaches listeners on reconnect
    │
    ▼
EnhancedSocketManager (411 lines, @lazySingleton)
  ├── Rate limiting per event type
  ├── Offline-first mode (queue events khi disconnect)
  ├── Auto-sync pending messages on reconnect
  ├── Network quality monitoring
  └── Analytics tracking (messageSent/messageReceived)
    │
    ▼
RealtimeService (847 lines, @lazySingleton)
  ├── High-level API: connect, disconnect, joinRoom, leaveRoom
  ├── 8 typed BehaviorSubject streams
  ├── Converts raw socket data → domain objects
  └── Connection health monitoring
```

### 10.2 Room Management

```
ChatBloc joins room → RealtimeService.joinChatRoom(chatId)
    → EnhancedSocketManager.emit('conversation:joined', {conversationId})
    → _joinedChats.add(chatId)

Socket disconnects:
    → _joinedChats.clear()  // Server mất tất cả room memberships

Socket reconnects:
    → Re-join tất cả rooms: joinChatRoom(chatId) for each

_onLoadChats → _subscribeToRealTimeUpdates():
    → Không auto-join rooms (rooms được join khi user mở conversation)
```

---

## 11. Gap Detection Logic

**File:** `lib/data/strategies/gap_detection_logic.dart` (15 lines)

```dart
class GapDetectionLogic {
  static bool hasGap({required int deltaCount, required int pageSize}) {
    return deltaCount >= pageSize;
  }
}
```

**Logic:** Nếu delta sync trả về `>= pageSize` items → có thể còn missed messages → trigger full refresh.

**Trạng thái:** ⛔ **Tồn tại nhưng KHÔNG được kết nối** — không code nào gọi `GapDetectionLogic.hasGap()`.

---

## 12. DI Registration Chain

### Standalone Mode (`injection.dart`)

```
DatabaseService (manual, core_module.dart)
    ↓
ChatLocalDataSourceImpl (@lazySingleton)
  depends on: DatabaseService
    ↓
ChatRemoteDataSourceImpl (@LazySingleton as IChatRemoteDataSource)
  depends on: GraphQLClientWrapper, EnhancedSocketManager
    ↓
ChatRepositoryImpl (@LazySingleton as IChatRepository)
  depends on: ChatLocalDataSource, IChatRemoteDataSource, INetworkInfo, AppLogger
    ↓
UseCases (all @injectable factory):
  GetConversationsUseCase, GetLocalConversationsUseCase,
  GetConversationDetailUseCase, CreateGroupUseCase, UpdateGroupUseCase,
  EditGroupUseCase, LeaveConversationUseCase, DeleteConversationUseCase,
  SearchConversationsUseCase, SearchMessagesUseCase, PersistIncomingMessageUseCase
    ↓
ChatBloc (@injectable factory, 16 deps)
  depends on: all use cases + ConnectivityService + CacheSyncStrategy
              + MediaCacheManager + RealtimeService + MarkAsReadUseCase
              + CurrentUserProvider + PersistIncomingMessageUseCase + ChatModuleEventBus
```

### Package Mode (`chat_module_injection.dart`)

Sử dụng CÙNG `injection.config.dart` với `environment: 'package'`.
Conversation-related registrations **không có environment filter** → registered trong CẢ HAI modes.

**Đặc biệt trong logout:**
```dart
// Unregister explicitly for fresh recreation on re-login:
_tryUnregister<IChatRepository>();
_tryUnregister<ChatLocalDataSource>();
```

---

## 13. Tổng Hợp Vấn Đề

### 🔴 Critical (Ảnh hưởng chức năng core)

| # | Vấn đề | File | Dòng |
|---|---|---|---|
| C1 | Offline queue processor CHƯA implement | `chat_local_datasource.dart` | L296 |
| C2 | `clearAll()` là STUB (không xóa gì) | `chat_local_datasource.dart` | L486–494 |
| C3 | `deleteChat()` là STUB (không xóa gì) | `chat_local_datasource.dart` | L203–206 |

### 🟡 Medium (Ảnh hưởng performance hoặc UX)

| # | Vấn đề | File | Dòng |
|---|---|---|---|
| M1 | `saveChats()` sequential, không batch | `chat_local_datasource.dart` | saveChats() |
| M2 | `getChatById()` là O(n) | `chat_local_datasource.dart` | getChatById() |
| M3 | `SyncMetadataModel` không được sử dụng | `sync_metadata_model.dart` | entire file |
| M4 | Gap detection không kết nối | `gap_detection_logic.dart` | entire file |
| M5 | Socket events `conversation:joined/leaved` không xử lý | `realtime_service.dart` | _initializeSocketListeners |
| M6 | `message:edit/delete` không update list preview | `chat_bloc.dart` | _subscribeToRealTimeUpdates |
| M7 | `getChats()` repo fetch ALL pages | `chat_repository.dart` | getChats() |
| M8 | Không có periodic background sync (30s) | Không file nào | — |
| M9 | `subscribeToChats()` listen event không tồn tại | `chat_remote_datasource.dart` | subscribeToChats() |
| M10 | CacheSyncStrategy event names không match socket | `cache_sync_strategy.dart` | handleRealTimeEvent() |

### 🟠 Low (Code quality, conventions)

| # | Vấn đề | File |
|---|---|---|
| L1 | `ChatBloc` extends `Bloc` thay vì `BaseBloc` | `chat_bloc.dart` |
| L2 | `ChatState` không extends `BaseState` | `chat_state.dart` |
| L3 | 7 events không có handler (dead code) | `chat_event.dart` |
| L4 | 4 states không được sử dụng (dead code) | `chat_state.dart` |
| L5 | Pervasive `debugPrint()` thay vì Logger | `chat_repository.dart` |
| L6 | Hardcoded Vietnamese strings | `chat_bloc.dart`, `chat_dto.dart` |
| L7 | Inconsistent parsing trong `_handleMessageDelete` | `realtime_service.dart` |
| L8 | Conflicting singleton pattern trong CacheSyncStrategy | `cache_sync_strategy.dart` |
| L9 | `_deleteConversation` usecase injected nhưng unused | `chat_bloc.dart` |
| L10 | `_chatUpdatesSubscription` declared nhưng never subscribed | `chat_bloc.dart` |

---

## 14. Data Flow Diagrams

### A. App Launch → Conversation List

```
User mở app
    │
    ├─ Phase 1: INSTANT ─────────────────────────────────────────────────────┐
    │  ChatBloc.add(loadChats())                                             │
    │    → GetLocalConversationsUseCase                                      │
    │      → ChatRepositoryImpl.getChatsFromLocalStorage()                   │
    │        → ChatLocalDataSourceImpl.getChats()                            │
    │          → DatabaseService.getChats() → Isar query                     │
    │          → Sort lastMessageTime DESC                                   │
    │          → ChatModel.toDomain() → List<Chat>                           │
    │    → emit loaded(chats: localChats, isSyncing: true)  ← <50ms         │
    │    → _prefetchAvatars(localChats)                                      │
    │    → _subscribeToRealTimeUpdates()                                     │
    │                                                                        │
    ├─ Phase 2: BACKGROUND SYNC ────────────────────────────────────────────┐│
    │  CacheSyncStrategy.shouldRefreshChatList()                            ││
    │    → dirty || >5min → YES                                             ││
    │  GetConversationsUseCase(PageRequest.first(25), typeFilter)            ││
    │    → ChatRepositoryImpl.getChatsPage()                                ││
    │      → INetworkInfo.isConnected?                                      ││
    │        → YES → Remote fetch: chatConversationList(size:25, page:0)    ││
    │          → Parse → ChatDto.toDomain() → List<Chat>                    ││
    │          → ChatLocalDataSourceImpl.saveChats(chats) → Isar           ││
    │          → Return PagedResult(items, total, hasMore)                   ││
    │    → CacheSyncStrategy.resetChatListDirtyFlag()                       ││
    │    → Calculate unread → EventBus.emitUnreadCount()                    ││
    │    → emit loaded(chats: remoteChats, isSyncing: false)  ← silent     ││
    └────────────────────────────────────────────────────────────────────────┘│
                                                                             │
    UI luôn responsive: cache hiện ngay, remote update background            │
    └────────────────────────────────────────────────────────────────────────┘
```

### B. Real-Time: Tin Nhắn Mới

```
Server → Socket.IO 'message:sent' → {message, conversationId}
    │
    ▼
EnhancedSocketManager (rate limit check, analytics)
    → RealtimeService._handleNewMessage()
       → MessageDto.fromJson() → .toDomain() → ChatMessage
       → _messageController.add(chatMessage)
    │
    ▼
ChatBloc._messageSubscription
    → newMessageReceived(message)
    → _onNewMessageReceived():
       1. Tìm chat trong list
       2. Format preview (mentions, media type labels)
       3. Update: lastMessageTime, preview, unreadCount++
       4. Sort: newest first
       5. EMIT → UI update tức thì
       6. ASYNC: persist message + chat → Isar
       7. EventBus: notify host app
```

### C. Offline → Online Transition

```
Mất mạng ────────────────────────────── Có mạng lại
    │                                        │
    ▼                                        ▼
ConnectivityService                    ConnectivityService
  emit false                             emit true
    │                                        │
    ▼                                        ▼
ChatBloc._onConnectivityChanged        ChatBloc._onConnectivityChanged
  emit offline()                         _triggerOnlineRefresh()
                                           │
                                    ┌──────┴──────┐
                                    │ Cooldown 2s  │
                                    │ (dedup)      │
                                    └──────┬──────┘
                                           │
                            CacheSyncStrategy.markChatListDirty()
                            add(ChatEvent.loadChats())  ← SOFT
                                           │
                                           ▼
                            _onLoadChats (Phase 1 + 2):
                              Show cache (no shimmer)
                              + isSyncing: true
                              Background fetch remote
                              Silent update
```

### D. Tab Switch (Filter Change)

```
User taps "Groups" tab
    │
    ▼
ChatEvent.changeConversationTypeFilter(filter: .group)
    │
    ▼
_onChangeConversationTypeFilter():
    1. Cache current tab: cachedLists[oldFilter] = currentChats
    2. Check cachedLists[.group]?
       ├── HAS CACHE → emit loaded(chats: cached, ...) ← INSTANT
       │              → Background: shouldRefresh? → fetch & update
       └── NO CACHE  → emit loading
                     → Fetch remote(type: "Group", page: 0)
                     → cachedLists[.group] = result
                     → emit loaded(chats: result, ...)
```

---

## 15. File Reference

| File | Lines | Vai trò |
|---|---|---|
| `lib/data/models/chat_model.dart` | 556 | Isar schema cho conversations |
| `lib/data/models/sync_metadata_model.dart` | 52 | Sync timestamps (unused) |
| `lib/data/models/offline_operation_model.dart` | 375 | Offline queue schema (no processor) |
| `lib/data/dtos/chat_dto.dart` | 425 | DTO + toDomain() mapper |
| `lib/data/graphql/chat_operations.dart` | 827 | GraphQL queries/mutations |
| `lib/data/strategies/gap_detection_logic.dart` | 15 | Gap detection (unwired) |
| `lib/features/chat/data/datasources/chat/chat_local_datasource.dart` | 496 | Isar CRUD |
| `lib/features/chat/data/datasources/chat/chat_remote_datasource.dart` | 846 | GraphQL + Socket |
| `lib/features/chat/data/repositories/chat_repository.dart` | 979 | Offline-first pattern |
| `lib/features/chat/presentation/blocs/chat/chat_bloc.dart` | 1097 | State management |
| `lib/features/chat/presentation/blocs/chat/chat_event.dart` | 105 | BLoC events |
| `lib/features/chat/presentation/blocs/chat/chat_state.dart` | 69 | BLoC states |
| `lib/core/services/realtime_service.dart` | 847 | Socket.IO wrapper |
| `lib/core/services/connectivity_service.dart` | 246 | Network detection |
| `lib/core/services/database_service.dart` | 912 | Isar abstraction |
| `lib/core/cache/cache_sync_strategy.dart` | 283 | Dirty flags + TTL |
| `lib/core/network/enhanced_socket_manager.dart` | 411 | Socket rate limit + offline |
| `lib/core/network/socket_manager.dart` | 391 | Raw Socket.IO client |
| `lib/core/di/injection.dart` | 599 | Standalone DI |
| `lib/core/di/chat_module_injection.dart` | 746 | Package mode DI |

**Total: ~8,982 lines across 20 files**
