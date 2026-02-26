---
inclusion: fileMatch
fileMatchPattern: "flutter_chat_app/lib/**/*{chat,message,conversation}*.dart"
---

# Chat API Integration

> Backend API contract reference for NestJS GraphQL + Socket.IO.

## Key Source Files

- GraphQL operations: #[[file:flutter_chat_app/lib/data/graphql/chat_operations.dart]]
- GraphQL client: #[[file:flutter_chat_app/lib/core/network/graphql_client.dart]]
- Message remote datasource: #[[file:flutter_chat_app/lib/data/datasources/message/message_remote_datasource.dart]]
- Chat DTOs: #[[file:flutter_chat_app/lib/data/dtos/chat_dto.dart]]
- Message DTOs: #[[file:flutter_chat_app/lib/data/dtos/message_dto.dart]]
- Socket event mapper: #[[file:flutter_chat_app/lib/data/mappers/socket_io_event_mapper.dart]]

## GraphQL Operations

| Operation | Type | Purpose |
|---|---|---|
| `messageAdd` | Mutation | Send message |
| `messageUpdate` | Mutation | Edit (`act:1`) or delete (`act:0`) |
| `messageUpdateReaction` | Mutation | Add (`act:1`) or remove (`act:0`) reaction |
| `messageUpdateRead` | Mutation | Mark as read (`readCount`, use `1000000` for all) |
| `messageList` | Query | Paginated messages (cursor: `lastKey{conversationId, createdAt}`) |
| `conversationList` | Query | User's conversations (page/size pagination) |
| `conversationDetail` | Query | Single conversation details |
| `groupCreate` | Mutation | Create group chat |
| `groupEdit` | Mutation | Edit group (name, members, admins) |
| `leaveConversation` | Mutation | Leave group |
| `deleteConversation` | Mutation | Hide conversation |
| `deleteHistory` | Mutation | Clear chat history |

## Message Types (Backend Enum)

`TEXT`, `IMAGE`, `VIDEO`, `LOCATION`, `CALL`, `VOICE_NOTE`, `DOC`, `AUDIO`, `STICKER`

## API Field Mapping

Backend field names differ from domain entities:

| Backend Field | Domain Field | Notes |
|---|---|---|
| `message` | `content` | Text content |
| `urls` | `mediaUrls` | Media URLs list |
| `replyMessageId` | `replyToId` | |
| `forwardedFromMessageId` | `forwardedFromId` | |
| `reactions[].code` | `reactions[].emoji` | Emoji string |
| `reactions[].reactorIds` | `reactions[].userIds` | |
| `mentionTo` | `mentions` | List of User objects |
| `imgUrl` | `avatarUrl` | Conversation avatar |
| `admin` | `isAdmin` | Member role |
| `hide` | `isHidden` | Conversation visibility |

## Pagination Rules

- Messages: cursor-based with `lastKey: {conversationId, createdAt(ms timestamp)}`, order `DESC`
- Conversations: offset-based with `page` (0-indexed) and `size` (default 25)
- Filter by `type` (optional): `"Direct"` or `"Group"`

## Key Business Rules

- Direct messages: use `receiverId` for first message, backend auto-creates conversation
- Subsequent messages: use `conversationId`
- Mentions format: `@[userId]` in text, `@[all]` for everyone
- Reactions: `act: 1` = add, `act: 0` = revoke
- Message edit/delete: `act: 1` = edit, `act: 0` = delete (soft delete)
- Group admins: only admins can edit group or remove members
- Last admin leaving: oldest member auto-promoted to admin
- File upload: via Socket.IO `message:file:upload`, returns path, then send message with `urls`
- Unread count: managed by backend, `personalConversation.unreadCount`
