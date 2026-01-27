# Task 5 Complete: Implement Domain Layer UseCases

**Status**: ✅ COMPLETE  
**Date**: 2025-01-27  
**Task**: Implement Domain Layer UseCases for Chat and Message operations

---

## 📋 Summary

Successfully implemented 12 domain layer UseCases following Clean Architecture principles. All UseCases use the project's Result<T> pattern, include comprehensive input validation, and are properly registered with @injectable for dependency injection.

---

## ✅ UseCases Implemented

### Chat UseCases (7 files)

1. **GetConversationsUseCase** (`get_conversations_usecase.dart`)
   - Retrieves list of all conversations
   - No parameters required
   - Returns `Result<List<Chat>>`
   - Uses offline-first strategy

2. **GetConversationDetailUseCase** (`get_conversation_detail_usecase.dart`)
   - Retrieves detailed information for a specific conversation
   - Parameters: `conversationId`
   - Returns `Result<Chat?>`
   - Validates conversation ID is not empty

3. **CreateGroupUseCase** (`create_group_usecase.dart`)
   - Creates a new group conversation
   - Parameters: `name`, `memberIds`, `description?`, `imageUrl?`
   - Returns `Result<Chat>`
   - Validates:
     - Name: 3-100 characters
     - Members: 1-256 members, no duplicates
     - All required fields present

4. **UpdateGroupUseCase** (`update_group_usecase.dart`)
   - Updates group information
   - Parameters: `conversationId`, `name?`, `imageUrl?`, `description?`
   - Returns `Result<Chat>`
   - Validates:
     - At least one field must be provided
     - Name: 3-100 characters if provided
     - Conversation ID not empty

5. **LeaveConversationUseCase** (`leave_conversation_usecase.dart`)
   - Allows user to leave a group
   - Parameters: `conversationId`
   - Returns `Result<bool>`
   - Validates conversation ID not empty

6. **DeleteConversationUseCase** (`delete_conversation_usecase.dart`)
   - Permanently deletes a conversation
   - Parameters: `conversationId`
   - Returns `Result<bool>`
   - Validates conversation ID not empty

7. **SearchConversationsUseCase** (`search_conversations_usecase.dart`)
   - Searches conversations by keyword
   - Parameters: `keyword`, `limit` (default: 20)
   - Returns `Result<List<Chat>>`
   - Validates:
     - Keyword: minimum 2 characters
     - Limit: 1-100

### Message UseCases (5 files)

1. **GetMessagesUseCase** (`get_messages_usecase.dart`)
   - Retrieves messages for a conversation
   - Parameters: `conversationId`, `limit` (default: 20), `cursor?`
   - Returns `Result<List<ChatMessage>>`
   - Validates:
     - Conversation ID not empty
     - Limit: 1-100
   - Supports pagination with cursor

2. **SendMessageUseCase** (`send_message_usecase.dart`)
   - Sends a new message
   - Parameters: `conversationId`, `content`, `senderId`, `contentType`, `attachmentIds`
   - Returns `Result<ChatMessage>`
   - Validates:
     - Conversation ID and sender ID not empty
     - Content or attachments must be present
     - Content max 10,000 characters
     - Content type must be valid (text, image, video, audio, file, location)

3. **EditMessageUseCase** (`edit_message_usecase.dart`)
   - Edits an existing message
   - Parameters: `messageId`, `newContent`
   - Returns `Result<bool>`
   - Validates:
     - Message ID not empty
     - New content not empty
     - Content max 10,000 characters

4. **DeleteMessageUseCase** (`delete_message_usecase.dart`)
   - Deletes a message
   - Parameters: `messageId`
   - Returns `Result<bool>`
   - Validates message ID not empty

5. **MarkAsReadUseCase** (`mark_as_read_usecase.dart`)
   - Marks all messages in a conversation as read
   - Parameters: `conversationId`
   - Returns `Result<void>`
   - Validates conversation ID not empty

---

## 🏗️ Architecture Pattern

### UseCase Structure

All UseCases follow this pattern:

```dart
@injectable
class SomeUseCase implements UseCase<ReturnType, ParamsType> {
  final IRepository _repository;

  const SomeUseCase(this._repository);

  @override
  Future<Result<ReturnType>> call(ParamsType params) async {
    // 1. Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // 2. Call repository
    final result = await _repository.someMethod(params);

    // 3. Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (data) => Result.success(data),
    );
  }

  ValidationFailure? _validateParams(ParamsType params) {
    // Validation logic
  }
}
```

### Key Design Decisions

1. **Result Pattern**: All UseCases return `Result<T>` instead of `Either<Failure, T>`
   - Consistent with project standards
   - Easier to work with in BLoCs
   - Better error handling

2. **Parameter Classes**: Each UseCase with parameters has a dedicated Params class
   - Extends Equatable for value equality
   - Immutable with const constructor
   - Clear parameter documentation

3. **Validation**: Input validation happens in UseCases, not repositories
   - Business logic validation (e.g., name length, member count)
   - Prevents invalid data from reaching repositories
   - Returns ValidationFailure for clear error messages

4. **Dependency Injection**: All UseCases use @injectable
   - Automatically registered with GetIt
   - Constructor injection for repositories
   - Testable with mock repositories

---

## 📊 Code Metrics

### Files Created: 12
- Chat UseCases: 7 files
- Message UseCases: 5 files

### Lines of Code: ~1,200
- Average per UseCase: ~100 lines
- Includes comprehensive validation
- Includes documentation

### Validation Rules: 30+
- Input validation rules across all UseCases
- Prevents invalid data from reaching backend
- Clear error messages for users

---

## 🔍 Validation

### Syntax Check:
```bash
✅ All 12 UseCase files: No diagnostics found
```

### Pattern Compliance:
- ✅ All UseCases implement UseCase<T, P> interface
- ✅ All UseCases use @injectable annotation
- ✅ All UseCases convert Either to Result
- ✅ All UseCases include input validation
- ✅ All parameter classes extend Equatable
- ✅ All UseCases follow project naming conventions

---

## 🎯 Benefits Achieved

1. **Clean Architecture**: Clear separation between domain and data layers
2. **Type Safety**: Strong typing with Result<T> pattern
3. **Testability**: Easy to mock repositories for unit testing
4. **Validation**: Business logic validation at domain layer
5. **Maintainability**: Consistent pattern across all UseCases
6. **Documentation**: Comprehensive inline documentation
7. **DI Ready**: All UseCases registered with @injectable

---

## 📝 Usage Example

### In BLoC:

```dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationsUseCase _getConversations;
  final SendMessageUseCase _sendMessage;

  ChatBloc(
    this._getConversations,
    this._sendMessage,
  ) : super(const ChatState.initial()) {
    on<ChatLoadRequested>(_onLoadRequested);
    on<ChatMessageSent>(_onMessageSent);
  }

  Future<void> _onLoadRequested(
    ChatLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatState.loading());
    
    final result = await _getConversations();
    
    result.fold(
      (failure) => emit(ChatState.error(failure)),
      (conversations) => emit(ChatState.loaded(conversations)),
    );
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final params = SendMessageParams(
      conversationId: event.conversationId,
      content: event.content,
      senderId: event.senderId,
      contentType: 'text',
    );
    
    final result = await _sendMessage(params);
    
    result.fold(
      (failure) => emit(ChatState.error(failure)),
      (message) => emit(ChatState.messageSent(message)),
    );
  }
}
```

---

## 🚀 Next Steps

### Task 6: Update/Create BLoCs
- Create ChatBloc for conversation management
- Create MessageBloc for message operations
- Update existing BLoCs to use new UseCases
- Implement proper state management with Freezed

### Task 7: Implement Real-time Integration
- Update Socket.IO manager to use new architecture
- Connect real-time events to BLoCs
- Implement typing indicators
- Implement online/offline status

### Task 8: Update UI
- Update conversation list page
- Update chat detail page
- Update message input widget
- Implement proper error handling in UI

---

## 📚 Files Created

### Chat UseCases:
1. ✅ `flutter_chat_app/lib/domain/usecases/chat/get_conversations_usecase.dart`
2. ✅ `flutter_chat_app/lib/domain/usecases/chat/get_conversation_detail_usecase.dart`
3. ✅ `flutter_chat_app/lib/domain/usecases/chat/create_group_usecase.dart`
4. ✅ `flutter_chat_app/lib/domain/usecases/chat/update_group_usecase.dart`
5. ✅ `flutter_chat_app/lib/domain/usecases/chat/leave_conversation_usecase.dart`
6. ✅ `flutter_chat_app/lib/domain/usecases/chat/delete_conversation_usecase.dart`
7. ✅ `flutter_chat_app/lib/domain/usecases/chat/search_conversations_usecase.dart`

### Message UseCases:
1. ✅ `flutter_chat_app/lib/domain/usecases/message/get_messages_usecase.dart`
2. ✅ `flutter_chat_app/lib/domain/usecases/message/send_message_usecase.dart`
3. ✅ `flutter_chat_app/lib/domain/usecases/message/edit_message_usecase.dart`
4. ✅ `flutter_chat_app/lib/domain/usecases/message/delete_message_usecase.dart`
5. ✅ `flutter_chat_app/lib/domain/usecases/message/mark_as_read_usecase.dart`

---

## ✅ Task Completion Checklist

- [x] Create GetConversationsUseCase
- [x] Create GetConversationDetailUseCase
- [x] Create CreateGroupUseCase
- [x] Create UpdateGroupUseCase
- [x] Create LeaveConversationUseCase
- [x] Create DeleteConversationUseCase
- [x] Create SearchConversationsUseCase
- [x] Create GetMessagesUseCase
- [x] Create SendMessageUseCase
- [x] Create EditMessageUseCase
- [x] Create DeleteMessageUseCase
- [x] Create MarkAsReadUseCase
- [x] Add @injectable annotations
- [x] Implement input validation
- [x] Convert Either to Result
- [x] Add comprehensive documentation
- [x] Verify no syntax errors
- [x] Follow project patterns

---

**Task 5 Status**: ✅ **COMPLETE**

**Ready for**: Task 6 - Update/Create BLoCs for Presentation Layer

---

**Completed by**: Senior Flutter/Mobile Architect  
**Date**: 2025-01-27  
**Quality**: Production-ready, follows Clean Architecture and project standards
