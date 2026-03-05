---
name: api-integration
description: Fix Flutter data layer to correctly integrate with the NestJS GraphQL backend — operations, DTOs, mappers, datasources
---

# API Integration Skill

Use this skill when connecting Flutter code to the backend GraphQL API, fixing mismatched operations, creating/updating DTOs, or fixing field mapping.

Do NOT use for backend (NestJS) code changes, UI-only changes, or offline/local-only features.

## CRITICAL: Dual Deployment Mode

API integration code must work in BOTH:
- **Standalone App**: GraphQL client configured via `FlavorConfig`
- **Package Module**: GraphQL client configured via `ChatConfig` (URLs, token from host app)

Ensure `TokenProvider` and `AuthDelegate` abstractions are used, not concrete auth implementations.

## Step 1: Verify Backend Contract

Read `.kiro/steering/chat-api-integration.md` for:
- Correct GraphQL operation names
- Input/output types
- Field names and types
- Pagination approach

## Step 2: GraphQL Operations

Update `lib/data/graphql/chat_operations.dart`:
- Use exact backend operation names: `chatConversationList`, `chatMessageAdd`, etc.
- Use exact input type names: `ChatConversationListFilter`, `ChatAddMessageInput`, etc.
- Include all required response fields

Wrong → Correct mapping:
- `getUserChats` → `chatConversationList`
- `getChatDetails` → `chatConversationDetail`
- `sendMessage` → `chatMessageAdd`
- `getChatById` → `chatConversationDetail`

## Step 3: DTOs

Update DTOs in `lib/data/dtos/`:
- Match backend response structure exactly
- Use `@JsonKey(name: 'backendField')` when Dart name differs
- Handle nullable fields properly
- Include ALL backend fields

## Step 4: Mappers

Update mappers in `lib/data/mappers/`:

| Backend | Domain | Notes |
|---|---|---|
| `message` | `content` | Text content |
| `urls` | `mediaUrls` | Media URLs list |
| `imgUrl` | `avatarUrl` | Conversation avatar |
| `admin` | `isAdmin` | Member role |
| `hide` | `isHidden` | Visibility |
| `reactions[].code` | `reactions[].emoji` | Emoji string |
| `reactions[].reactorIds` | `reactions[].userIds` | Reactor IDs |
| `mentionTo` | `mentions` | User objects |
| `replyMessageId` | `replyToId` | Reply ref |
| `forwardedFromMessageId` | `forwardedFromId` | Forward ref |

## Step 5: DataSources

Update remote datasources:
- Correct GraphQL client calls
- Correct variable names matching backend input types
- Handle pagination:
  - Messages: cursor-based with `lastKey: {conversationId, createdAt}`
  - Conversations: offset-based with `page` + `size`

## Step 6: Verify

```bash
cd flutter_chat_app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

## Key Business Rules

- Direct messages: use `receiverId` for first message (backend auto-creates conversation)
- Subsequent messages: use `conversationId`
- Reactions: `act: 1` = add, `act: 0` = revoke
- Message edit/delete: `act: 1` = edit, `act: 0` = delete
- File upload: via Socket.IO `message:file:upload`, returns path, then include in `urls`
- Read receipt: `readCount` param, use `1000000` to mark all as read
