# API Integration Skill

Use this skill when:
- Connecting Flutter code to backend GraphQL API
- Fixing mismatched GraphQL operations
- Creating or updating DTOs to match backend response
- Implementing new API endpoints in Flutter
- Fixing field mapping between backend and Flutter domain entities

Do NOT use this skill for:
- Backend (NestJS) code changes
- UI-only changes
- Offline/local-only features

## What this skill does

Ensures Flutter data layer correctly integrates with the NestJS GraphQL backend.

### Step 1: Verify Backend Contract
Read `.kiro/steering/chat-api-integration.md` to understand:
- Correct GraphQL operation names
- Input/output types
- Field names and types
- Pagination approach

### Step 2: GraphQL Operations
Update `lib/data/graphql/chat_operations.dart`:
- Use exact backend operation names: `chatConversationList`, `chatMessageAdd`, etc.
- Use exact input type names: `ChatConversationListFilter`, `ChatAddMessageInput`, etc.
- Include all required response fields

### Step 3: DTOs
Update DTOs in `lib/data/dtos/`:
- Match backend response structure exactly
- Use `@JsonKey(name: 'backendField')` when Dart name differs
- Handle nullable fields properly
- Include ALL backend fields (don't skip any)

### Step 4: Mappers
Update mappers in `lib/data/mappers/`:
- Backend `message` → Domain `content`
- Backend `urls` → Domain `mediaUrls`
- Backend `imgUrl` → Domain `avatarUrl`
- Backend `admin` → Domain `isAdmin`
- Backend `hide` → Domain `isHidden`
- Backend `reactions[].code` → Domain `reactions[].emoji`
- Backend `reactions[].reactorIds` → Domain `reactions[].userIds`
- Backend `mentionTo` → Domain `mentions`
- Backend `replyMessageId` → Domain `replyToId`
- Backend `forwardedFromMessageId` → Domain `forwardedFromId`

### Step 5: DataSources
Update remote datasources:
- Correct GraphQL client calls
- Correct variable names matching backend input types
- Handle pagination correctly:
  - Messages: cursor-based with `lastKey: {conversationId, createdAt}`
  - Conversations: offset-based with `page` + `size`

### Step 6: Verify
```bash
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
