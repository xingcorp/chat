# Requirements Document: Phase 1 Foundation Fix

## Introduction

This spec addresses critical blockers preventing the Flutter chat app from functioning with the backend. The app has excellent Clean Architecture structure but cannot operate due to GraphQL operation mismatches, missing UseCase implementations, incomplete data models, and incorrect repository implementations. This foundation fix is a prerequisite for Phase 2 (chat-core-features) implementation.

## Glossary

- **System**: The Flutter chat application
- **Backend**: The NestJS GraphQL API server
- **UseCase**: Domain layer business logic component that orchestrates data flow
- **Repository**: Data layer component that abstracts data sources
- **DataSource**: Component that communicates with external APIs
- **GraphQL_Operation**: Named query or mutation in the GraphQL schema
- **Socket_Event**: Real-time event transmitted via Socket.IO
- **Clean_Architecture**: Layered architecture pattern with domain, data, and presentation layers
- **BaseBloc**: Foundation BLoC class providing error handling, logging, and analytics
- **BaseState**: Foundation state class for Freezed state management
- **Conversation**: Chat conversation (direct message or group chat)
- **Message**: Individual message within a conversation
- **Reaction**: Emoji reaction to a message

## Requirements

### Requirement 1: GraphQL Operations Alignment

**User Story:** As a developer, I want all GraphQL operations to match the backend API, so that the app can successfully communicate with the server.

#### Acceptance Criteria

1. WHEN the System queries conversations, THE System SHALL use `chatConversationList` operation
2. WHEN the System queries conversation details, THE System SHALL use `chatConversationDetail` operation
3. WHEN the System sends a message, THE System SHALL use `chatMessageAdd` operation
4. WHEN the System queries messages, THE System SHALL use `chatMessageList` operation
5. WHEN the System creates a group, THE System SHALL use `chatGroupAdd` operation
6. WHEN the System edits a group, THE System SHALL use `chatGroupEdit` operation
7. WHEN the System leaves a conversation, THE System SHALL use `chatConversationLeave` operation
8. WHEN the System deletes a conversation, THE System SHALL use `chatConversationDelete` operation
9. WHEN the System edits a message, THE System SHALL use `chatMessageEdit` operation
10. WHEN the System deletes a message, THE System SHALL use `chatMessageDeleteHistory` operation
11. WHEN the System marks messages as read, THE System SHALL use `chatMessageUpdateRead` operation
12. WHEN the System adds a reaction, THE System SHALL use `chatMessageUpdateReaction` operation with `action: ADD`
13. WHEN the System removes a reaction, THE System SHALL use `chatMessageUpdateReaction` operation with `action: REMOVE`
14. WHEN the System searches conversations, THE System SHALL use `chatSearch` operation with `type: CONVERSATION`
15. WHEN the System searches messages, THE System SHALL use `chatSearch` operation with `type: MESSAGE`

### Requirement 2: Complete UseCase Layer Implementation

**User Story:** As a developer, I want all required UseCases implemented, so that the domain layer correctly orchestrates business logic following Clean Architecture principles.

#### Acceptance Criteria

1. THE System SHALL implement `GetConversationsUseCase` in `lib/domain/usecases/chat/get_conversations_usecase.dart`
2. THE System SHALL implement `GetConversationDetailUseCase` in `lib/domain/usecases/chat/get_conversation_detail_usecase.dart`
3. THE System SHALL implement `CreateGroupUseCase` in `lib/domain/usecases/chat/create_group_usecase.dart`
4. THE System SHALL implement `EditGroupUseCase` in `lib/domain/usecases/chat/edit_group_usecase.dart`
5. THE System SHALL implement `LeaveConversationUseCase` in `lib/domain/usecases/chat/leave_conversation_usecase.dart`
6. THE System SHALL implement `DeleteConversationUseCase` in `lib/domain/usecases/chat/delete_conversation_usecase.dart`
7. THE System SHALL implement `SearchConversationsUseCase` in `lib/domain/usecases/chat/search_conversations_usecase.dart`
8. THE System SHALL implement `GetMessagesUseCase` in `lib/domain/usecases/message/get_messages_usecase.dart`
9. THE System SHALL implement `SendMessageUseCase` in `lib/domain/usecases/message/send_message_usecase.dart`
10. THE System SHALL implement `EditMessageUseCase` in `lib/domain/usecases/message/edit_message_usecase.dart`
11. THE System SHALL implement `DeleteMessageUseCase` in `lib/domain/usecases/message/delete_message_usecase.dart`
12. THE System SHALL implement `MarkAsReadUseCase` in `lib/domain/usecases/message/mark_as_read_usecase.dart`
13. THE System SHALL implement `AddReactionUseCase` in `lib/domain/usecases/message/add_reaction_usecase.dart`
14. THE System SHALL implement `RemoveReactionUseCase` in `lib/domain/usecases/message/remove_reaction_usecase.dart`
15. THE System SHALL implement `SearchMessagesUseCase` in `lib/domain/usecases/message/search_messages_usecase.dart`
16. WHEN any UseCase is invoked, THE UseCase SHALL return `Either<Failure, T>` for error handling
17. WHEN any UseCase encounters an error, THE UseCase SHALL log the error using Logger service
18. WHEN any UseCase is created, THE UseCase SHALL use `@injectable` annotation for dependency injection

### Requirement 3: Complete Data Models

**User Story:** As a developer, I want data models to include all backend fields, so that the app can correctly serialize and deserialize API responses.

#### Acceptance Criteria

1. THE ChatModel SHALL include `description` field of type `String?`
2. THE ChatModel SHALL include `groupType` field of type `String?`
3. THE ChatModel SHALL include `creator` field of type `UserModel?`
4. THE ChatModel SHALL include `members` field of type `List<UserModel>`
5. THE MessageModel SHALL include `urls` field of type `List<String>`
6. THE MessageModel SHALL include `fileName` field of type `String?`
7. THE MessageModel SHALL include `reactions` field of type `List<ReactionModel>`
8. THE MessageModel SHALL include `editAt` field of type `DateTime?`
9. THE MessageModel SHALL include `deletedAt` field of type `DateTime?`
10. THE ReactionModel SHALL be created with fields: `id`, `emoji`, `userId`, `createdAt`
11. WHEN any model is serialized, THE System SHALL use `toJson()` method
12. WHEN any model is deserialized, THE System SHALL use `fromJson()` factory constructor
13. WHEN any model is converted to entity, THE System SHALL use `toEntity()` method
14. WHEN any model is created from entity, THE System SHALL use `fromEntity()` factory constructor

### Requirement 4: Correct Repository Implementations

**User Story:** As a developer, I want repositories to call correct GraphQL operations, so that data layer correctly communicates with the backend.

#### Acceptance Criteria

1. WHEN `ChatRepository.getConversations()` is called, THE Repository SHALL invoke `chatConversationList` GraphQL operation
2. WHEN `ChatRepository.getConversationDetail()` is called, THE Repository SHALL invoke `chatConversationDetail` GraphQL operation
3. WHEN `ChatRepository.createGroup()` is called, THE Repository SHALL invoke `chatGroupAdd` GraphQL operation
4. WHEN `ChatRepository.editGroup()` is called, THE Repository SHALL invoke `chatGroupEdit` GraphQL operation
5. WHEN `ChatRepository.leaveConversation()` is called, THE Repository SHALL invoke `chatConversationLeave` GraphQL operation
6. WHEN `ChatRepository.deleteConversation()` is called, THE Repository SHALL invoke `chatConversationDelete` GraphQL operation
7. WHEN `ChatRepository.searchConversations()` is called, THE Repository SHALL invoke `chatSearch` operation with `type: CONVERSATION`
8. WHEN `MessageRepository.getMessages()` is called, THE Repository SHALL invoke `chatMessageList` GraphQL operation
9. WHEN `MessageRepository.sendMessage()` is called, THE Repository SHALL invoke `chatMessageAdd` GraphQL operation
10. WHEN `MessageRepository.editMessage()` is called, THE Repository SHALL invoke `chatMessageEdit` GraphQL operation
11. WHEN `MessageRepository.deleteMessage()` is called, THE Repository SHALL invoke `chatMessageDeleteHistory` GraphQL operation
12. WHEN `MessageRepository.markAsRead()` is called, THE Repository SHALL invoke `chatMessageUpdateRead` GraphQL operation
13. WHEN `MessageRepository.addReaction()` is called, THE Repository SHALL invoke `chatMessageUpdateReaction` operation with `action: ADD`
14. WHEN `MessageRepository.removeReaction()` is called, THE Repository SHALL invoke `chatMessageUpdateReaction` operation with `action: REMOVE`
15. WHEN `MessageRepository.searchMessages()` is called, THE Repository SHALL invoke `chatSearch` operation with `type: MESSAGE`
16. WHEN any repository method is called, THE Repository SHALL check network connectivity first
17. WHEN network is unavailable, THE Repository SHALL return `NetworkFailure`
18. WHEN GraphQL operation fails, THE Repository SHALL convert exception to appropriate Failure type

### Requirement 5: Socket.IO Event Handling

**User Story:** As a developer, I want Socket.IO events to be properly handled, so that the app receives real-time updates from the backend.

#### Acceptance Criteria

1. WHEN the Backend emits `message:sent` event, THE System SHALL update the message list
2. WHEN the Backend emits `message:read` event, THE System SHALL update message read status
3. WHEN the Backend emits `message:typing` event, THE System SHALL display typing indicator
4. WHEN the Backend emits `message:reaction` event, THE System SHALL update message reactions
5. WHEN the Backend emits `message:edit` event, THE System SHALL update the edited message
6. WHEN the Backend emits `message:delete` event, THE System SHALL remove or mark the deleted message
7. WHEN the Backend emits `conversation:joined` event, THE System SHALL update conversation member list
8. WHEN the Backend emits `conversation:leaved` event, THE System SHALL update conversation member list
9. WHEN any Socket event is received, THE System SHALL log the event using Logger service
10. WHEN Socket connection fails, THE System SHALL log the error and attempt reconnection

### Requirement 6: Mandatory Base Class Usage

**User Story:** As a developer, I want all code to use mandatory base classes, so that the app has consistent error handling, logging, and lifecycle management.

#### Acceptance Criteria

1. WHEN creating a BLoC, THE System SHALL extend `BaseBloc<Event, State>` not `Bloc`
2. WHEN creating a State, THE System SHALL extend `BaseState` with `@freezed` annotation
3. WHEN creating a StatefulWidget, THE System SHALL extend `BaseStatefulWidget`
4. WHEN creating a StatelessWidget, THE System SHALL extend `BaseStatelessWidget`
5. WHEN logging information, THE System SHALL use Logger service not `print()` or `debugPrint()`
6. WHEN displaying user-facing text, THE System SHALL use `context.l10n` not hardcoded strings
7. WHEN using UI dimensions, THE System SHALL use `AppConstants` not hardcoded numbers
8. WHEN using UI durations, THE System SHALL use `AppConstants` not hardcoded durations
9. WHEN registering dependencies, THE System SHALL use `@injectable`, `@singleton`, or `@lazySingleton` annotations
10. WHEN handling errors, THE System SHALL use `Either<Failure, T>` pattern

### Requirement 7: GraphQL Query and Mutation Definitions

**User Story:** As a developer, I want all GraphQL queries and mutations defined correctly, so that the app can parse backend responses.

#### Acceptance Criteria

1. THE System SHALL define `chatConversationList` query with correct response structure
2. THE System SHALL define `chatConversationDetail` query with correct response structure
3. THE System SHALL define `chatMessageList` query with correct response structure
4. THE System SHALL define `chatMessageAdd` mutation with correct input and response structure
5. THE System SHALL define `chatGroupAdd` mutation with correct input and response structure
6. THE System SHALL define `chatGroupEdit` mutation with correct input and response structure
7. THE System SHALL define `chatConversationLeave` mutation with correct response structure
8. THE System SHALL define `chatConversationDelete` mutation with correct response structure
9. THE System SHALL define `chatMessageEdit` mutation with correct input and response structure
10. THE System SHALL define `chatMessageDeleteHistory` mutation with correct response structure
11. THE System SHALL define `chatMessageUpdateRead` mutation with correct input and response structure
12. THE System SHALL define `chatMessageUpdateReaction` mutation with correct input and response structure
13. THE System SHALL define `chatSearch` query with correct input and response structure
14. WHEN any GraphQL operation is defined, THE System SHALL include all required fields from backend schema
15. WHEN any GraphQL operation is defined, THE System SHALL use correct field types matching backend schema

### Requirement 8: Dependency Injection Registration

**User Story:** As a developer, I want all new components registered in DI container, so that they can be injected and used throughout the app.

#### Acceptance Criteria

1. WHEN any UseCase is created, THE System SHALL register it with `@injectable` annotation
2. WHEN any Repository is created, THE System SHALL register it with `@LazySingleton` annotation
3. WHEN any DataSource is created, THE System SHALL register it with `@LazySingleton` annotation
4. WHEN any Service is created, THE System SHALL register it with appropriate DI annotation
5. WHEN DI registration changes, THE System SHALL run `dart run build_runner build --delete-conflicting-outputs`
6. WHEN any component requires dependencies, THE System SHALL inject them via constructor
7. WHEN any component is registered, THE System SHALL use interface binding where applicable (e.g., `@LazySingleton(as: IRepository)`)

### Requirement 9: Error Handling and Logging

**User Story:** As a developer, I want comprehensive error handling and logging, so that issues can be diagnosed and fixed quickly.

#### Acceptance Criteria

1. WHEN any UseCase executes, THE UseCase SHALL log the operation start using `logger.i()`
2. WHEN any UseCase succeeds, THE UseCase SHALL log the success using `logger.i()`
3. WHEN any UseCase fails, THE UseCase SHALL log the error using `logger.e()` with error details
4. WHEN any Repository method executes, THE Repository SHALL log the operation
5. WHEN any Repository method fails, THE Repository SHALL convert exceptions to Failure objects
6. WHEN any DataSource method fails, THE DataSource SHALL throw appropriate exception types
7. WHEN any BLoC handles an event, THE BLoC SHALL use `emitLoading()`, `emitError()`, or `emitSuccess()` helper methods
8. WHEN any error occurs, THE System SHALL provide user-friendly error messages via `context.l10n`
9. WHEN network is unavailable, THE System SHALL return `NetworkFailure` with localized message
10. WHEN server returns error, THE System SHALL return `ServerFailure` with error details

### Requirement 10: Code Generation and Build

**User Story:** As a developer, I want code generation to run successfully, so that all generated files are up-to-date.

#### Acceptance Criteria

1. WHEN models are modified, THE System SHALL run `dart run build_runner build --delete-conflicting-outputs`
2. WHEN DI annotations are added, THE System SHALL run `dart run build_runner build --delete-conflicting-outputs`
3. WHEN Freezed classes are modified, THE System SHALL run `dart run build_runner build --delete-conflicting-outputs`
4. WHEN localization strings are added, THE System SHALL run `flutter gen-l10n`
5. WHEN code generation completes, THE System SHALL have no build errors
6. WHEN code generation completes, THE System SHALL have all `*.g.dart` files generated
7. WHEN code generation completes, THE System SHALL have all `*.freezed.dart` files generated
8. WHEN code generation completes, THE System SHALL have all DI configuration files generated
