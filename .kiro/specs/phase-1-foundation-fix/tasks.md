# Implementation Plan: Phase 1 Foundation Fix

## Overview

This implementation plan addresses critical blockers preventing the Flutter chat app from functioning with the backend. The plan follows a systematic approach: fix data models first, then implement UseCases, update repositories, fix GraphQL operations, and finally integrate Socket.IO events. Each task builds incrementally to ensure the app can communicate with the backend successfully.

**Timeline**: 2 weeks (10 working days)

**Key Principles**:
- All BLoCs MUST extend `BaseBloc<Event, State>`
- All States MUST extend `BaseState` with `@freezed`
- All StatefulWidgets MUST extend `BaseStatefulWidget`
- All StatelessWidgets MUST extend `BaseStatelessWidget`
- ALWAYS use `AppConstants` for dimensions/durations
- ALWAYS use `Logger` for logging (NEVER `print()`)
- ALWAYS use `context.l10n` for user-facing strings
- ALWAYS use `@injectable`, `@singleton`, `@lazySingleton` for DI
- ALWAYS use `Either<Failure, T>` for error handling

## Tasks

- [ ] 1. Fix Data Models and Entities
  - [x] 1.1 Add missing fields to Chat entity
    - Add `description`, `groupType`, `creator`, `members` fields to Chat entity
    - Update Equatable props to include new fields
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  
  - [ ] 1.2 Add missing fields to Message entity
    - Add `urls`, `fileName`, `reactions`, `editAt`, `deletedAt` fields to Message entity
    - Update Equatable props to include new fields
    - _Requirements: 3.5, 3.6, 3.7, 3.8, 3.9_
  
  - [ ] 1.3 Create Reaction entity
    - Create `lib/domain/entities/reaction.dart` with fields: `id`, `emoji`, `userId`, `createdAt`
    - Implement Equatable
    - _Requirements: 3.10_
  
  - [ ] 1.4 Update ChatModel with missing fields
    - Add `description`, `groupType`, `creator`, `members` fields to ChatModel
    - Update `fromJson`, `toJson`, `toEntity`, `fromEntity` methods
    - Add `@JsonKey` annotations where needed
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  
  - [ ] 1.5 Update MessageModel with missing fields
    - Add `urls`, `fileName`, `reactions`, `editAt`, `deletedAt` fields to MessageModel
    - Update `fromJson`, `toJson`, `toEntity`, `fromEntity` methods
    - Add `@JsonKey` annotations where needed
    - _Requirements: 3.5, 3.6, 3.7, 3.8, 3.9_
  
  - [ ] 1.6 Create ReactionModel
    - Create `lib/data/models/reaction_model.dart` with Freezed
    - Implement `fromJson`, `toJson`, `toEntity`, `fromEntity` methods
    - _Requirements: 3.10_
  
  - [ ] 1.7 Write property test for model serialization round trip
    - **Property 6: Model Serialization Round Trip**
    - Test ChatModel, MessageModel, ReactionModel, UserModel
    - Generate 100+ random instances per model
    - Verify `toJson()` then `fromJson()` produces equivalent object
    - **Validates: Requirements 3.11, 3.12**
  
  - [ ] 1.8 Write property test for model-entity conversion round trip
    - **Property 7: Model-Entity Conversion Round Trip**
    - Test Chat, Message, Reaction, User entities
    - Generate 100+ random instances per entity
    - Verify `fromEntity()` then `toEntity()` produces equivalent entity
    - **Validates: Requirements 3.13, 3.14**
  
  - [ ] 1.9 Run code generation for models
    - Execute `dart run build_runner build --delete-conflicting-outputs`
    - Verify all `*.g.dart` and `*.freezed.dart` files generated
    - Fix any code generation errors
    - _Requirements: 10.1, 10.5, 10.6, 10.7_

- [ ] 2. Checkpoint - Verify models compile and tests pass
  - Ensure all model tests pass, ask the user if questions arise.


- [ ] 3. Implement Chat UseCases (7 total)
  - [ ] 3.1 Implement GetConversationsUseCase
    - Create `lib/domain/usecases/chat/get_conversations_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IChatRepository` and `Logger`
    - Implement `call()` method returning `Either<Failure, List<Chat>>`
    - Log operation start, success, and failure
    - _Requirements: 2.1, 2.16, 2.17, 2.18_
  
  - [ ] 3.2 Write unit tests for GetConversationsUseCase
    - Test success case with mock repository
    - Test failure case (NetworkFailure, ServerFailure)
    - Verify logging calls
    - Verify repository method called with correct parameters
    - _Requirements: 2.1_
  
  - [ ] 3.3 Implement GetConversationDetailUseCase
    - Create `lib/domain/usecases/chat/get_conversation_detail_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IChatRepository` and `Logger`
    - Implement `call()` method with `conversationId` parameter
    - Log operation start, success, and failure
    - _Requirements: 2.2, 2.16, 2.17, 2.18_
  
  - [ ] 3.4 Write unit tests for GetConversationDetailUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.2_
  
  - [ ] 3.5 Implement CreateGroupUseCase
    - Create `lib/domain/usecases/chat/create_group_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IChatRepository` and `Logger`
    - Implement `call()` method with parameters: `name`, `memberIds`, `avatar`, `description`
    - Log operation start, success, and failure
    - _Requirements: 2.3, 2.16, 2.17, 2.18_
  
  - [ ] 3.6 Write unit tests for CreateGroupUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.3_
  
  - [ ] 3.7 Implement EditGroupUseCase
    - Create `lib/domain/usecases/chat/edit_group_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IChatRepository` and `Logger`
    - Implement `call()` method with parameters: `conversationId`, `name`, `avatar`, `description`
    - Log operation start, success, and failure
    - _Requirements: 2.4, 2.16, 2.17, 2.18_
  
  - [ ] 3.8 Write unit tests for EditGroupUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.4_
  
  - [ ] 3.9 Implement LeaveConversationUseCase
    - Create `lib/domain/usecases/chat/leave_conversation_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IChatRepository` and `Logger`
    - Implement `call()` method with `conversationId` parameter
    - Log operation start, success, and failure
    - _Requirements: 2.5, 2.16, 2.17, 2.18_
  
  - [ ] 3.10 Write unit tests for LeaveConversationUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.5_
  
  - [ ] 3.11 Implement DeleteConversationUseCase
    - Create `lib/domain/usecases/chat/delete_conversation_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IChatRepository` and `Logger`
    - Implement `call()` method with `conversationId` parameter
    - Log operation start, success, and failure
    - _Requirements: 2.6, 2.16, 2.17, 2.18_
  
  - [ ] 3.12 Write unit tests for DeleteConversationUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.6_
  
  - [ ] 3.13 Implement SearchConversationsUseCase
    - Create `lib/domain/usecases/chat/search_conversations_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IChatRepository` and `Logger`
    - Implement `call()` method with `query` parameter
    - Log operation start, success, and failure
    - _Requirements: 2.7, 2.16, 2.17, 2.18_
  
  - [ ] 3.14 Write unit tests for SearchConversationsUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.7_
  
  - [ ] 3.15 Write property test for UseCase return types
    - **Property 3: All UseCases Return Either Type**
    - Verify all chat UseCases return `Either<Failure, T>`
    - **Validates: Requirements 2.16**
  
  - [ ] 3.16 Write property test for UseCase error logging
    - **Property 4: UseCases Log Errors on Failure**
    - Trigger failures in UseCases and verify `logger.e()` is called
    - **Validates: Requirements 2.17**

- [ ] 4. Checkpoint - Verify chat UseCases compile and tests pass
  - Ensure all chat UseCase tests pass, ask the user if questions arise.

- [ ] 5. Implement Message UseCases (8 total)
  - [ ] 5.1 Implement GetMessagesUseCase
    - Create `lib/domain/usecases/message/get_messages_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with parameters: `conversationId`, `limit`, `offset`
    - Log operation start, success, and failure
    - _Requirements: 2.8, 2.16, 2.17, 2.18_
  
  - [ ] 5.2 Write unit tests for GetMessagesUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.8_
  
  - [ ] 5.3 Implement SendMessageUseCase
    - Create `lib/domain/usecases/message/send_message_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with parameters: `conversationId`, `content`, `type`, `urls`, `fileName`
    - Log operation start, success, and failure
    - _Requirements: 2.9, 2.16, 2.17, 2.18_
  
  - [ ] 5.4 Write unit tests for SendMessageUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.9_
  
  - [ ] 5.5 Implement EditMessageUseCase
    - Create `lib/domain/usecases/message/edit_message_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with parameters: `messageId`, `content`
    - Log operation start, success, and failure
    - _Requirements: 2.10, 2.16, 2.17, 2.18_
  
  - [ ] 5.6 Write unit tests for EditMessageUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.10_
  
  - [ ] 5.7 Implement DeleteMessageUseCase
    - Create `lib/domain/usecases/message/delete_message_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with `messageId` parameter
    - Log operation start, success, and failure
    - _Requirements: 2.11, 2.16, 2.17, 2.18_
  
  - [ ] 5.8 Write unit tests for DeleteMessageUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.11_
  
  - [ ] 5.9 Implement MarkAsReadUseCase
    - Create `lib/domain/usecases/message/mark_as_read_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with parameters: `conversationId`, `messageIds`
    - Log operation start, success, and failure
    - _Requirements: 2.12, 2.16, 2.17, 2.18_
  
  - [ ] 5.10 Write unit tests for MarkAsReadUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.12_
  
  - [ ] 5.11 Implement AddReactionUseCase
    - Create `lib/domain/usecases/message/add_reaction_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with parameters: `messageId`, `emoji`
    - Log operation start, success, and failure
    - _Requirements: 2.13, 2.16, 2.17, 2.18_
  
  - [ ] 5.12 Write unit tests for AddReactionUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.13_
  
  - [ ] 5.13 Implement RemoveReactionUseCase
    - Create `lib/domain/usecases/message/remove_reaction_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with parameters: `messageId`, `emoji`
    - Log operation start, success, and failure
    - _Requirements: 2.14, 2.16, 2.17, 2.18_
  
  - [ ] 5.14 Write unit tests for RemoveReactionUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.14_
  
  - [ ] 5.15 Implement SearchMessagesUseCase
    - Create `lib/domain/usecases/message/search_messages_usecase.dart`
    - Use `@injectable` annotation
    - Inject `IMessageRepository` and `Logger`
    - Implement `call()` method with `query` parameter
    - Log operation start, success, and failure
    - _Requirements: 2.15, 2.16, 2.17, 2.18_
  
  - [ ] 5.16 Write unit tests for SearchMessagesUseCase
    - Test success and failure cases
    - Verify logging and repository calls
    - _Requirements: 2.15_

- [ ] 6. Checkpoint - Verify message UseCases compile and tests pass
  - Ensure all message UseCase tests pass, ask the user if questions arise.


- [ ] 7. Define GraphQL Operations
  - [ ] 7.1 Create GraphQL query definitions file
    - Create `lib/data/datasources/graphql/queries/chat_queries.dart`
    - Define `conversationList` query with all required fields
    - Define `conversationDetail` query with all required fields
    - Define `messageList` query with all required fields
    - Define `search` query with union type handling
    - _Requirements: 7.1, 7.2, 7.3, 7.13_
  
  - [ ] 7.2 Create GraphQL mutation definitions file
    - Create `lib/data/datasources/graphql/mutations/chat_mutations.dart`
    - Define `messageAdd` mutation with all required fields
    - Define `groupAdd` mutation with all required fields
    - Define `groupEdit` mutation with all required fields
    - Define `conversationLeave` mutation
    - Define `conversationDelete` mutation
    - Define `messageEdit` mutation with all required fields
    - Define `messageDeleteHistory` mutation
    - Define `messageUpdateRead` mutation
    - Define `messageUpdateReaction` mutation with all required fields
    - _Requirements: 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11, 7.12_
  
  - [ ] 7.3 Update ChatRemoteDataSource to use correct operations
    - Update `getConversations()` to use `chatConversationList` query
    - Update `getConversationDetail()` to use `chatConversationDetail` query
    - Update `createGroup()` to use `chatGroupAdd` mutation
    - Update `editGroup()` to use `chatGroupEdit` mutation
    - Update `leaveConversation()` to use `chatConversationLeave` mutation
    - Update `deleteConversation()` to use `chatConversationDelete` mutation
    - Update `searchConversations()` to use `chatSearch` query with `type: CONVERSATION`
    - Add logging for all operations
    - _Requirements: 1.1, 1.2, 1.5, 1.6, 1.7, 1.8, 1.14_
  
  - [ ] 7.4 Update MessageRemoteDataSource to use correct operations
    - Update `getMessages()` to use `chatMessageList` query
    - Update `sendMessage()` to use `chatMessageAdd` mutation
    - Update `editMessage()` to use `chatMessageEdit` mutation
    - Update `deleteMessage()` to use `chatMessageDeleteHistory` mutation
    - Update `markAsRead()` to use `chatMessageUpdateRead` mutation
    - Update `addReaction()` to use `chatMessageUpdateReaction` mutation with `action: ADD`
    - Update `removeReaction()` to use `chatMessageUpdateReaction` mutation with `action: REMOVE`
    - Update `searchMessages()` to use `chatSearch` query with `type: MESSAGE`
    - Add logging for all operations
    - _Requirements: 1.3, 1.4, 1.9, 1.10, 1.11, 1.12, 1.13, 1.15_
  
  - [ ] 7.5 Write property test for GraphQL operation names
    - **Property 1: GraphQL Query Operations Use Correct Names**
    - **Property 2: GraphQL Mutation Operations Use Correct Names**
    - Verify all query and mutation strings contain correct operation names
    - **Validates: Requirements 1.1-1.15**

- [ ] 8. Update Repository Implementations
  - [ ] 8.1 Update ChatRepositoryImpl methods
    - Update `getConversations()` to call correct data source method
    - Update `getConversationDetail()` to call correct data source method
    - Update `createGroup()` to call correct data source method
    - Update `editGroup()` to call correct data source method
    - Update `leaveConversation()` to call correct data source method
    - Update `deleteConversation()` to call correct data source method
    - Update `searchConversations()` to call correct data source method
    - Ensure all methods check network connectivity first
    - Ensure all methods convert exceptions to failures
    - Add comprehensive logging
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.16, 4.17, 4.18_
  
  - [ ] 8.2 Write unit tests for ChatRepositoryImpl
    - Test network connectivity check for all methods
    - Test NetworkFailure when offline
    - Test success cases with mock data source
    - Test exception to failure conversion (ServerException, ValidationException)
    - Verify logging calls
    - _Requirements: 4.1-4.7, 4.16-4.18_
  
  - [ ] 8.3 Write property tests for ChatRepository
    - **Property 8: Repository Methods Check Network First**
    - **Property 9: Repository Returns NetworkFailure When Offline**
    - **Property 10: Repository Converts Exceptions to Failures**
    - **Property 11: Chat Repository Calls Correct Operations**
    - **Validates: Requirements 4.1-4.7, 4.16-4.18**
  
  - [ ] 8.4 Update MessageRepositoryImpl methods
    - Update `getMessages()` to call correct data source method
    - Update `sendMessage()` to call correct data source method
    - Update `editMessage()` to call correct data source method
    - Update `deleteMessage()` to call correct data source method
    - Update `markAsRead()` to call correct data source method
    - Update `addReaction()` to call correct data source method
    - Update `removeReaction()` to call correct data source method
    - Update `searchMessages()` to call correct data source method
    - Ensure all methods check network connectivity first
    - Ensure all methods convert exceptions to failures
    - Add comprehensive logging
    - _Requirements: 4.8, 4.9, 4.10, 4.11, 4.12, 4.13, 4.14, 4.15, 4.16, 4.17, 4.18_
  
  - [ ] 8.5 Write unit tests for MessageRepositoryImpl
    - Test network connectivity check for all methods
    - Test NetworkFailure when offline
    - Test success cases with mock data source
    - Test exception to failure conversion
    - Verify logging calls
    - _Requirements: 4.8-4.15, 4.16-4.18_
  
  - [ ] 8.6 Write property tests for MessageRepository
    - **Property 12: Message Repository Calls Correct Operations**
    - Verify all repository methods call correct data source methods
    - **Validates: Requirements 4.8-4.15**

- [ ] 9. Checkpoint - Verify repositories compile and tests pass
  - Ensure all repository tests pass, ask the user if questions arise.

- [ ] 10. Implement Socket.IO Event Handling
  - [ ] 10.1 Update SocketService with correct event listeners
    - Add listener for `message:sent` event
    - Add listener for `message:read` event
    - Add listener for `message:typing` event
    - Add listener for `message:reaction` event
    - Add listener for `message:edit` event
    - Add listener for `message:delete` event
    - Add listener for `conversation:joined` event
    - Add listener for `conversation:leaved` event
    - Add logging for all events using `logger.d()` or `logger.i()`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9_
  
  - [ ] 10.2 Create stream controllers for events
    - Create `_messageStreamController` for message events
    - Create `_reactionStreamController` for reaction events
    - Create `_typingStreamController` for typing events
    - Create `_conversationStreamController` for conversation events
    - Expose streams as public getters
    - Implement proper disposal in `dispose()` method
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_
  
  - [ ] 10.3 Add error handling for socket connection
    - Add listener for connection errors
    - Log errors using `logger.e()`
    - Implement reconnection logic
    - _Requirements: 5.10_
  
  - [ ] 10.4 Write unit tests for SocketService
    - Test event listener registration
    - Test stream emission when events received
    - Test logging for all events
    - Test error handling and reconnection
    - _Requirements: 5.1-5.10_
  
  - [ ] 10.5 Write property test for socket event handling
    - **Property 13: Socket Events Trigger Correct Handlers**
    - **Property 14: Socket Events Are Logged**
    - Emit various socket events and verify handlers called
    - Verify logging for all events
    - **Validates: Requirements 5.1-5.9**

- [ ] 11. Register Dependencies in DI Container
  - [ ] 11.1 Register all chat UseCases
    - Verify `@injectable` annotations on all chat UseCases
    - Run code generation to update DI configuration
    - _Requirements: 8.1_
  
  - [ ] 11.2 Register all message UseCases
    - Verify `@injectable` annotations on all message UseCases
    - Run code generation to update DI configuration
    - _Requirements: 8.1_
  
  - [ ] 11.3 Verify repository registrations
    - Verify `@LazySingleton(as: IChatRepository)` on ChatRepositoryImpl
    - Verify `@LazySingleton(as: IMessageRepository)` on MessageRepositoryImpl
    - _Requirements: 8.2_
  
  - [ ] 11.4 Verify data source registrations
    - Verify `@LazySingleton(as: IChatRemoteDataSource)` on ChatRemoteDataSourceImpl
    - Verify `@LazySingleton(as: IMessageRemoteDataSource)` on MessageRemoteDataSourceImpl
    - _Requirements: 8.3_
  
  - [ ] 11.5 Run code generation for DI
    - Execute `dart run build_runner build --delete-conflicting-outputs`
    - Verify `injection.config.dart` updated with all new dependencies
    - Fix any DI registration errors
    - _Requirements: 8.5, 10.1, 10.5, 10.8_
  
  - [ ] 11.6 Write property test for DI annotations
    - **Property 5: UseCases Use Injectable Annotation**
    - **Property 21: DI Annotations Present**
    - Verify all UseCases, Repositories, DataSources have correct DI annotations
    - **Validates: Requirements 2.18, 8.1-8.4**

- [ ] 12. Checkpoint - Verify DI registration and code generation
  - Ensure code generation completes successfully, ask the user if questions arise.


- [ ] 13. Add Localization Strings
  - [ ] 13.1 Add error message strings to ARB files
    - Add `errorNoInternet`, `errorServer`, `errorUnexpected` to `app_en.arb` and `app_vi.arb`
    - Add `errorLoadingConversations`, `errorSendingMessage`, `errorCreatingGroup` to both ARB files
    - Add `errorEditingMessage`, `errorDeletingMessage`, `errorAddingReaction` to both ARB files
    - Add `retry`, `cancel`, `ok` to both ARB files
    - _Requirements: 6.6, 9.8_
  
  - [ ] 13.2 Add success message strings to ARB files
    - Add `messageSent`, `groupCreated`, `groupEdited` to both ARB files
    - Add `conversationLeft`, `conversationDeleted`, `messageEdited` to both ARB files
    - Add `messageDeleted`, `reactionAdded`, `reactionRemoved` to both ARB files
    - _Requirements: 6.6_
  
  - [ ] 13.3 Add loading message strings to ARB files
    - Add `loadingConversations`, `sendingMessage`, `creatingGroup` to both ARB files
    - Add `editingGroup`, `leavingConversation`, `deletingConversation` to both ARB files
    - Add `editingMessage`, `deletingMessage`, `addingReaction` to both ARB files
    - _Requirements: 6.6_
  
  - [ ] 13.4 Generate localization files
    - Execute `flutter gen-l10n`
    - Verify `app_localizations.dart` generated with all new strings
    - Fix any localization errors
    - _Requirements: 10.4_
  
  - [ ] 13.5 Write property test for no hardcoded strings
    - **Property 19: No Hardcoded Strings**
    - Scan all presentation layer files for hardcoded user-facing strings
    - Verify all strings use `context.l10n`
    - **Validates: Requirements 6.6**

- [ ] 14. Verify Base Class Usage
  - [ ] 14.1 Write property test for BLoC base class usage
    - **Property 15: BLoCs Extend BaseBloc**
    - Scan all BLoC files and verify they extend `BaseBloc<Event, State>`
    - Verify no BLoCs extend `Bloc` directly
    - **Validates: Requirements 6.1**
  
  - [ ] 14.2 Write property test for State base class usage
    - **Property 16: States Extend BaseState**
    - Scan all State files and verify they extend `BaseState`
    - Verify all States use `@freezed` annotation
    - **Validates: Requirements 6.2**
  
  - [ ] 14.3 Write property test for Widget base class usage
    - **Property 17: Widgets Extend Base Widget Classes**
    - Scan all widget files and verify StatefulWidgets extend `BaseStatefulWidget`
    - Verify all StatelessWidgets extend `BaseStatelessWidget`
    - **Validates: Requirements 6.3, 6.4**
  
  - [ ] 14.4 Write property test for logging usage
    - **Property 18: No Print Statements**
    - Scan all files for `print()` or `debugPrint()` calls
    - Verify all logging uses Logger service
    - **Validates: Requirements 6.5**
  
  - [ ] 14.5 Write property test for AppConstants usage
    - **Property 20: Use AppConstants for Dimensions**
    - Scan UI files for hardcoded numeric literals
    - Verify all dimensions and durations use `AppConstants`
    - **Validates: Requirements 6.7, 6.8**
  
  - [ ] 14.6 Write property test for Either usage
    - **Property 22: Error Handling Uses Either**
    - Verify all UseCase and Repository methods return `Either<Failure, T>`
    - **Validates: Requirements 6.10**

- [ ] 15. Verify Logging Implementation
  - [ ] 15.1 Write property test for UseCase logging
    - **Property 23: UseCases Log Operation Start and Result**
    - Verify all UseCases log operation start with `logger.i()`
    - Verify all UseCases log result (success or failure)
    - **Validates: Requirements 9.1, 9.2, 9.3**
  
  - [ ] 15.2 Write property test for Repository logging
    - **Property 24: Repositories Log Operations**
    - Verify all repository methods log operations
    - **Validates: Requirements 9.4, 9.5**
  
  - [ ] 15.3 Write property test for user-friendly error messages
    - **Property 25: User-Friendly Error Messages**
    - Verify all error messages displayed to users come from `context.l10n`
    - Verify no raw exception messages shown to users
    - **Validates: Requirements 9.8, 9.9, 9.10**

- [ ] 16. Integration Testing
  - [ ] 16.1 Write integration test for conversation flow
    - Test fetching conversations with real GraphQL client (mock server)
    - Test creating group conversation
    - Test editing group conversation
    - Verify correct GraphQL operations called
    - Verify response parsing works correctly
    - _Requirements: 1.1, 1.2, 1.5, 1.6_
  
  - [ ] 16.2 Write integration test for message flow
    - Test fetching messages with real GraphQL client (mock server)
    - Test sending message
    - Test editing message
    - Test adding reaction
    - Verify correct GraphQL operations called
    - Verify response parsing works correctly
    - _Requirements: 1.3, 1.4, 1.9, 1.12_
  
  - [ ] 16.3 Write integration test for Socket.IO events
    - Test socket connection
    - Test emitting and receiving `message:sent` event
    - Test emitting and receiving `message:reaction` event
    - Verify event handlers invoked correctly
    - Verify streams emit correct data
    - _Requirements: 5.1, 5.4_

- [ ] 17. Final Checkpoint - Run all tests and verify build
  - [ ] 17.1 Run all unit tests
    - Execute `flutter test test/unit/`
    - Verify all tests pass
    - Fix any failing tests
  
  - [ ] 17.2 Run all property tests
    - Execute `flutter test test/property/`
    - Verify all property tests pass (100+ iterations each)
    - Fix any failing property tests
  
  - [ ] 17.3 Run all integration tests
    - Execute `flutter test test/integration/`
    - Verify all integration tests pass
    - Fix any failing integration tests
  
  - [ ] 17.4 Run code analysis
    - Execute `flutter analyze`
    - Fix all errors and warnings
    - Ensure no linting issues
  
  - [ ] 17.5 Verify code generation
    - Execute `dart run build_runner build --delete-conflicting-outputs`
    - Verify all generated files up-to-date
    - Verify no code generation errors
  
  - [ ] 17.6 Test app startup
    - Run app in debug mode
    - Verify no runtime errors
    - Verify DI container initializes correctly
    - Verify all dependencies resolve
  
  - [ ] 17.7 Test basic API communication
    - Attempt to fetch conversations from backend
    - Verify GraphQL request sent with correct operation name
    - Verify response parsed correctly
    - Verify no network or serialization errors

## Success Criteria Summary

**Phase 1 Complete When**:
- ✅ All 15 UseCases implemented and tested
- ✅ All data models complete with backend fields
- ✅ All GraphQL operations aligned with backend
- ✅ All repositories calling correct operations
- ✅ All Socket.IO events handled correctly
- ✅ All mandatory base classes used correctly
- ✅ All logging using Logger service (no `print()`)
- ✅ All user-facing strings using `context.l10n`
- ✅ All dimensions/durations using `AppConstants`
- ✅ All dependencies registered in DI container
- ✅ Code generation runs successfully
- ✅ All tests pass (unit, property, integration)
- ✅ App can communicate with backend without errors

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (100+ iterations)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end flows with real components
- All code MUST follow mandatory base class patterns
- All code MUST use Logger, context.l10n, AppConstants, and @injectable
