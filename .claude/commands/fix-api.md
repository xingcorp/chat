You are fixing the Flutter app's GraphQL API integration to match the actual NestJS backend.

## Context
The Flutter app currently uses WRONG GraphQL operation names and field mappings.
Read `.kiro/steering/chat-api-integration.md` for the correct backend API contract.

## Task
For the specified feature area, fix the API integration:

### 1. GraphQL Operations (`lib/data/graphql/chat_operations.dart`)
Replace wrong operation names with correct ones:
- `getUserChats` → `chatConversationList`
- `getChatDetails` → `chatConversationDetail`
- `sendMessage` → `chatMessageAdd`
- `getChatById` → `chatConversationDetail`
- etc.

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

### 4. DataSources (`lib/data/datasources/`)
Fix remote datasource methods to call correct GraphQL operations with correct variables.

### 5. Verify
- Run `flutter analyze`
- Run `dart run build_runner build --delete-conflicting-outputs`
- Ensure no type errors or missing field errors

Ask me which area to fix: conversations, messages, groups, or all.
