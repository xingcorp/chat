# Data Layer Rules
# Applies to: flutter_chat_app/lib/data/**/*.dart

## DTO Rules

1. **Use `@freezed` + `@JsonSerializable`**
   ```dart
   @freezed
   class MessageDto with _$MessageDto {
     const factory MessageDto({
       required String id,
       @JsonKey(name: 'message') required String content,
       @JsonKey(name: 'urls') List<String>? mediaUrls,
       @JsonKey(name: 'senderId') required String senderId,
       // ...
     }) = _MessageDto;

     factory MessageDto.fromJson(Map<String, dynamic> json) =>
         _$MessageDtoFromJson(json);
   }
   ```

2. **Use `@JsonKey(name: 'backendField')` for field mapping**
   - Backend `message` → DTO field `content`
   - Backend `urls` → DTO field `mediaUrls`
   - Backend `imgUrl` → DTO field `avatarUrl`
   - Backend `admin` → DTO field `isAdmin`

## GraphQL Operations

3. **Use correct backend operation names**
   - ✅ `chatConversationList`, `chatMessageAdd`, `chatMessageEdit`
   - ❌ `getUserChats`, `sendMessage`, `getChatDetails`

4. **Include all response fields needed by the app**

## Repository Implementation

5. **Annotate with `@LazySingleton(as: IRepository)`**
   ```dart
   @LazySingleton(as: IMessageRepository)
   class MessageRepositoryImpl implements IMessageRepository { ... }
   ```

6. **Follow offline-first pattern**
   ```
   Check connectivity → Try remote → Cache locally → Return Right(data)
   On error → Return Left(Failure)
   Offline → Return cached data from Isar
   ```

7. **Use `RepositoryErrorMixin`** for consistent error handling

## Mapper Rules

8. **Mappers handle DTO ↔ Entity conversion**
   - `toEntity()` — converts DTO/model to domain entity
   - `fromEntity()` — converts domain entity to DTO/model
   - Handle null fields gracefully
   - Map backend field names to domain field names

## DataSource Rules

9. **Remote datasources** call GraphQL via `graphql_client.dart`
10. **Local datasources** use Isar for offline storage
11. **Never import Presentation layer**
