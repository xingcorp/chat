# Socket.IO & Offline Rules
# Applies to: flutter_chat_app/lib/**/*{socket,offline,sync,realtime,queue}*.dart

## Socket.IO Connection
- Transport: `websocket` only (no polling)
- Auth: `{token: jwt}` in socket auth
- Auto-reconnect with exponential backoff
- Join conversation rooms on connect
- Buffer socket events during message loading (prevent race conditions)
- Always update local DB when receiving socket events BEFORE emitting to streams

## Socket Events (Server → Client)
| Event | Data Structure |
|---|---|
| `message:sent` | `{message, conversationId}` |
| `message:read` | `{message, reader}` |
| `message:reaction` | `{reactor, data: {messageId, code, act: 'ADD'\|'REMOVE'}}` |
| `message:edit` | `{message, conversationId}` |
| `message:delete` | `{message, conversationId}` |
| `message:typing` | `{userId, fullName, isTyping, conversationId}` |
| `conversation:joined` | `{conversationId}` |
| `conversation:leaved` | `{conversationId}` |

## Socket Events (Client → Server)
| Event | Data Structure |
|---|---|
| `message:typing` | `{conversationId, isTyping}` |
| `message:file:upload` | `{file, fileName}` |
| `conversation:joined` | `{conversationId}` |
| `conversation:leaved` | `{conversationId}` |

## Offline Queue Pattern
```
Save locally (Isar) → Add to sync queue → Update UI (optimistic)
When online: Process queue → Send to server → Update local → Remove from queue
```
- Max 3 retries per queued item
- Process immediately on connectivity restored
- Periodic sync fallback every 30s
- Temp message IDs: `temp_{timestamp}`

## Typing Indicator
- Emit `message:typing` with `{conversationId, isTyping}`
- Auto-stop after 3 seconds of inactivity
- Clear typing state on `isTyping: false` or after 3s timeout

## Conflict Resolution
- Last-write-wins for message edits
- Server timestamp is source of truth
- On reconnect: fetch latest messages + merge with local using gap detection
- Gap detection: `lib/data/strategies/gap_detection_logic.dart`

## Message Status Flow
`local → sending → sent → delivered → read → failed`
