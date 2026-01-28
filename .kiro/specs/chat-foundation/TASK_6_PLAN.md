# Task 6 Plan: Update BLoCs to Use UseCases and Core Components

**Status**: 🔄 IN PROGRESS  
**Date**: 2025-01-27  
**Task**: Update ChatBloc and MessageBloc to use new UseCases and existing core components

---

## 📋 Analysis Summary

### Current State

**Existing Core Components (MUST USE):**
1. ✅ `BaseBloc<EventType, StateType>` - Base class with error handling, analytics, performance monitoring
2. ✅ `BlocErrorMixin` - Mixin for Either<Failure, T> error handling
3. ✅ `BaseState` - Base state classes (BaseInitial, BaseLoading, BaseSuccess, BaseError, BaseEmpty)

**Existing BLoCs:**
1. ✅ `ChatBloc` - Uses Freezed events/states, directly calls repositories, doesn't use BaseBloc
2. ✅ `MessageBloc` - Uses Equatable events/states, directly calls repositories, doesn't use BaseBloc

**New UseCases (Created in Task 5):**
1. ✅ Chat UseCases: GetConversationsUseCase, CreateGroupUseCase, etc. (7 total)
2. ✅ Message UseCases: GetMessagesUseCase, SendMessageUseCase, etc. (5 total)

---

## 🎯 Implementation Strategy

### Architecture Flow

**Current (Incorrect):**
```
BLoC → Repository (Either<Failure, T>) → DataSource
```

**Target (Clean Architecture):**
```
BLoC → UseCase (Result<T>) → Repository (Either<Failure, T>) → DataSource
```

### Key Decisions

1. **Use BaseBloc**: Both ChatBloc and MessageBloc should extend BaseBloc
   - Provides error handling, analytics, performance monitoring
   - Provides executeWithRetry() for resilient operations
   - Provides emitLoading(), emitError() helpers

2. **Handle Result<T> Pattern**: UseCases return Result<T>, not Either<Failure, T>
   - Need to handle Result.success() and Result.failure()
   - Convert Result to appropriate states

3. **Keep Existing Event/State Patterns**:
   - ChatBloc: Keep Freezed events/states
   - MessageBloc: Keep Equatable events/states
   - Don't break existing UI code

4. **Use @injectable**: Both BLoCs should inject UseCases, not repositories

---

## 📝 Implementation Tasks

### Task 6.1: Update ChatBloc

**Changes Required:**
1. ✅ Extend BaseBloc instead of Bloc
2. ✅ Add BlocErrorMixin
3. ✅ Inject UseCases instead of repositories:
   - GetConversationsUseCase
   - GetConversationDetailUseCase
   - CreateGroupUseCase
   - UpdateGroupUseCase
   - LeaveConversationUseCase
   - DeleteConversationUseCase
   - SearchConversationsUseCase
4. ✅ Update event handlers to use UseCases
5. ✅ Handle Result<T> pattern properly
6. ✅ Keep Freezed events/states unchanged
7. ✅ Add proper error handling with BaseBloc methods

**Example Pattern:**
```dart
@injectable
class ChatBloc extends BaseBloc<ChatEvent, ChatState> with BlocErrorMixin {
  final GetConversationsUseCase _getConversations;
  final CreateGroupUseCase _createGroup;
  // ... other usecases

  ChatBloc(
    this._getConversations,
    this._createGroup,
    // ... other usecases
  ) : super(const ChatState.initial()) {
    on<_LoadChats>(_onLoadChats);
    // ... other handlers
  }

  Future<void> _onLoadChats(_LoadChats event, Emitter<ChatState> emit) async {
    emit(const ChatState.loading());
    
    final result = await _getConversations();
    
    result.fold(
      (failure) => emit(ChatState.error(message: getUserErrorMessage(failure))),
      (chats) => emit(ChatState.loaded(chats: chats)),
    );
  }
}
```

### Task 6.2: Update MessageBloc

**Changes Required:**
1. ✅ Extend BaseBloc instead of Bloc
2. ✅ Add BlocErrorMixin
3. ✅ Inject UseCases instead of repositories:
   - GetMessagesUseCase
   - SendMessageUseCase
   - EditMessageUseCase
   - DeleteMessageUseCase
   - MarkAsReadUseCase
4. ✅ Update event handlers to use UseCases
5. ✅ Handle Result<T> pattern properly
6. ✅ Keep Equatable events/states unchanged
7. ✅ Add proper error handling with BaseBloc methods

---

## 🔍 Technical Considerations

### Result<T> vs Either<Failure, T>

**Result<T> API:**
```dart
sealed class Result<T> {
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = Failed<T>;
  
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  );
}
```

**Usage in BLoC:**
```dart
final result = await useCase(params);

result.fold(
  (failure) {
    // Handle failure
    emit(ErrorState(message: getUserErrorMessage(failure)));
  },
  (data) {
    // Handle success
    emit(SuccessState(data: data));
  },
);
```

### BaseBloc Integration

**Available Methods:**
- `emitLoading({String? message, double? progress})` - Emit loading state
- `emitError(String message, {...})` - Emit error state
- `executeWithRetry<T>(Future<T> Function() operation, {...})` - Execute with retry
- `handleError(Object error, StackTrace stackTrace)` - Handle errors
- `addSubscription(StreamSubscription subscription)` - Track subscriptions

**Usage:**
```dart
Future<void> _onSomeEvent(SomeEvent event, Emitter<State> emit) async {
  emitLoading(message: 'Loading data...');
  
  final result = await executeWithRetry(
    () => useCase(params),
    maxRetries: 3,
    emitLoadingState: false, // Already emitted above
  );
  
  if (result != null) {
    result.fold(
      (failure) => emitError(getUserErrorMessage(failure)),
      (data) => emit(SuccessState(data: data)),
    );
  }
}
```

---

## ✅ Success Criteria

1. ✅ ChatBloc extends BaseBloc and uses BlocErrorMixin
2. ✅ MessageBloc extends BaseBloc and uses BlocErrorMixin
3. ✅ Both BLoCs use UseCases instead of repositories
4. ✅ Both BLoCs handle Result<T> pattern correctly
5. ✅ Existing Freezed/Equatable patterns preserved
6. ✅ No syntax errors
7. ✅ Proper error handling with user-friendly messages
8. ✅ Performance monitoring integrated
9. ✅ All subscriptions properly managed
10. ✅ @injectable annotations updated

---

## 🚀 Next Steps After Task 6

1. **Task 7**: Implement Real-time Integration
   - Update Socket.IO manager
   - Connect real-time events to BLoCs
   - Implement typing indicators

2. **Task 8**: Update UI Components
   - Update conversation list page
   - Update chat detail page
   - Update message input widget

3. **Task 9**: Testing
   - Unit tests for UseCases
   - Unit tests for BLoCs
   - Integration tests

---

**Plan Created by**: Senior Flutter/Mobile Architect  
**Date**: 2025-01-27  
**Ready for**: Implementation
