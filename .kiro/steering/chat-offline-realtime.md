---
inclusion: fileMatch
fileMatchPattern: "flutter_chat_app/lib/**/*{offline,sync,socket,realtime,queue}*.dart"
---

# Chat Offline-First & Real-time

> Patterns for offline queue, sync, and Socket.IO real-time features.

## Key Source Files

- Socket manager: #[[file:flutter_chat_app/lib/core/network/enhanced_socket_manager.dart]]
- Socket manager (base): #[[file:flutter_chat_app/lib/core/network/socket_manager.dart]]
- Offline queue: #[[file:flutter_chat_app/lib/core/offline/offline_message_queue.dart]]
- Offline queue service: #[[file:flutter_chat_app/lib/core/services/offline_queue_service.dart]]
- Background sync: #[[file:flutter_chat_app/lib/core/services/background_sync_service.dart]]
- Realtime service: #[[file:flutter_chat_app/lib/core/services/realtime_messaging_service.dart]]
- Connectivity service: #[[file:flutter_chat_app/lib/core/services/connectivity_service.dart]]
- Message queue BLoC: #[[file:flutter_chat_app/lib/presentation/blocs/message_queue/message_queue_bloc.dart]]
- Realtime message BLoC: #[[file:flutter_chat_app/lib/presentation/blocs/realtime/realtime_message_bloc.dart]]
- Sync metadata: #[[file:flutter_chat_app/lib/data/managers/sync_metadata_manager.dart]]
- Network info: #[[file:flutter_chat_app/lib/core/network/network_info.dart]]

## Offline-First Flow

```
User Action → Save to Local DB (Isar) → Add to Sync Queue → Update UI (optimistic)
  → When online: Process Queue → Send to Server → Update Local with Server Response → Remove from Queue
```

- Always save locally first, then sync
- Queue items have retry logic (max 3 retries)
- Process queue immediately when connectivity restored
- Periodic sync as fallback (every 30s)

## Real-time Socket.IO Events

**Client → Server:**
| Event | Purpose |
|---|---|
| `message:typing` | Typing indicator |
| `message:file:upload` | File upload |
| `conversation:joined` | Join room |
| `conversation:leaved` | Leave room |

**Server → Client:**
| Event | Purpose |
|---|---|
| `message:sent` | New message (data: `{message, conversationId}`) |
| `message:read` | Read receipt (data: `{message, reader}`) |
| `message:reaction` | Reaction change (data: `{reactor, data: {messageId, code, act}}`) |
| `message:edit` | Message edited (data: `{message}`) |
| `message:delete` | Message deleted (data: `{message}`) |
| `message:typing` | Typing (data: `{userId, fullName, isTyping, conversationId}`) |
| `conversation:joined` | Added to conversation |
| `conversation:leaved` | Removed from conversation |

## Socket Connection Rules

- Transport: `websocket` only
- Auth: `{token: jwt}` in socket auth
- Auto-reconnect enabled with exponential backoff
- Join conversation rooms on connect
- Buffer socket events during message loading to prevent race conditions
- Always update local DB when receiving socket events before emitting to streams

## Typing Indicator Rules

- Emit `message:typing` with `{conversationId, isTyping}` 
- Auto-stop after 3 seconds of inactivity
- Clear typing state when receiving `isTyping: false` or after 3s timeout

## Conflict Resolution

- Last-write-wins for message edits
- Server timestamp is source of truth
- On reconnect: fetch latest messages and merge with local using gap detection logic
- Gap detection: #[[file:flutter_chat_app/lib/data/strategies/gap_detection_logic.dart]]
