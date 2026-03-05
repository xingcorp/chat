---
name: fix-api
description: Fix Flutter GraphQL API integration to match the actual NestJS backend — operation names, DTOs, field mappings, datasources
---

# Fix GraphQL API Integration

Use this skill to fix the Flutter app's GraphQL API integration to match the actual NestJS backend.

## Context

The Flutter app currently uses WRONG GraphQL operation names and field mappings.
Read `.kiro/steering/chat-api-integration.md` for the correct backend API contract.

## CRITICAL: Dual Deployment Mode

API code must work in both:
- **Standalone**: GraphQL configured via `FlavorConfig`
- **Package Module**: GraphQL configured via `ChatConfig` from host app

Use `TokenProvider` and `AuthDelegate` abstractions.

## Task

For the specified feature area, fix the API integration:

### 1. GraphQL Operations (`lib/data/graphql/chat_operations.dart`)

Replace wrong operation names with correct ones:
- `getUserChats` → `chatConversationList`
- `getChatDetails` → `chatConversationDetail`
- `sendMessage` → `chatMessageAdd`
- `getChatById` → `chatConversationDetail`

### 2. DTOs (`lib/data/dtos/`)

Update DTOs to match backend response structure:
- Add missing fields (description, groupType, reactions, editAt, deletedAt, urls, fileName)
- Use correct backend field names in `@JsonKey`

### 3. Mappers (`lib/data/mappers/`)

Update field mapping:
- `message` → `content`
- `urls` → `mediaUrls`
- `imgUrl` → `avatarUrl`
- `admin` → `isAdmin`
- `reactions[].code` → `reactions[].emoji`
- `reactions[].reactorIds` → `reactions[].userIds`
- `mentionTo` → `mentions`
- `replyMessageId` → `replyToId`
- `forwardedFromMessageId` → `forwardedFromId`

### 4. DataSources (`lib/data/datasources/`)

Fix remote datasource methods to call correct GraphQL operations with correct variables.

Handle pagination:
- Messages: cursor-based with `lastKey: {conversationId, createdAt}`
- Conversations: offset-based with `page` + `size`

### 5. Verify

```bash
cd flutter_chat_app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Ensure no type errors or missing field errors.

## Key Business Rules

- Direct messages: use `receiverId` for first message (backend auto-creates conversation)
- Subsequent messages: use `conversationId`
- Reactions: `act: 1` = add, `act: 0` = revoke
- Message edit/delete: `act: 1` = edit, `act: 0` = delete
- File upload: via Socket.IO `message:file:upload`, returns path, then include in `urls`
- Read receipt: `readCount` param, use `1000000` to mark all as read
