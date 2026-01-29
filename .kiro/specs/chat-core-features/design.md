# Design Document: Chat Core Features

## Overview

This document describes the technical design for Phase 2 (Chat Core Features) of the Sharitek Office Chat application. This phase builds upon the foundation established in Phase 1 and implements six essential user-facing features: message reactions, message editing, message deletion, file uploads, message search, and reply/forward functionality.

**Design Philosophy:**
- **Leverage Existing Infrastructure**: Reuse Phase 1 services (OfflineQueueService, RealtimeService, MediaProcessingService, etc.)
- **Clean Architecture**: Maintain strict layer separation established in Phase 1
- **Offline-First**: All operations work offline and sync when online
- **Type-Safe**: Continue using Either<Failure, T> for error handling
- **Testable**: All components are unit testable with clear interfaces
- **Performant**: Optimize for 60fps UI and fast operation completion
- **Maintainable**: Follow established patterns from Phase 1

**Key Design Decisions:**
1. Extend existing repositories rather than create new ones
2. Add new UseCases for each feature operation
3. Extend existing BLoCs with new events/states
4. Reuse offline queue infrastructure for all operations
5. Leverage existing real-time event handling patterns
6. Use existing media processing pipeline for file uploads
7. Implement search as a new repository with caching
8. Use existing conflict resolution (last-write-wins)

**Phase 1 Infrastructure to Leverage:**
- `OfflineQueueService`: Queue operations when offline
- `RealtimeService`: Socket.IO event handling
- `MediaProcessingService`: File compression and thumbnails
- `AttachmentQueueService`: File upload queue management
- `ResourceManagerService`: Media caching
- `ChatMessageService`: Message operations
- `MessageQueueService`: Message queuing
- `DatabaseService`: Isar database access
- `ConnectivityService`: Network status monitoring
- `LocalizationService`: i18n support


## Project Patterns and Standards

### Base Classes and Inheritance

**CRITICAL**: All components MUST extend the project's base classes to ensure consistency, proper lifecycle management, error handling, and monitoring.

#### BLoC Layer Patterns

**All BLoCs MUST extend `BaseBloc`:**
```dart
// ✅ CORRECT - Extend BaseBloc
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  final AddReactionUseCase _addReactionUseCase;
  final RemoveReactionUseCase _removeReactionUseCase;
  final Logger _logger;
  
  ChatBloc({
    required AddReactionUseCase addReactionUseCase,
    required RemoveReactionUseCase removeReactionUseCase,
    required Logger logger,
  }) : _addReactionUseCase = addReactionUseCase,
       _removeReactionUseCase = removeReactionUseCase,
       _logger = logger,
       super(const ChatState.initial()) {
    on<ChatAddReactionEvent>(_onAddReaction);
    on<ChatRemoveReactionEvent>(_onRemoveReaction);
  }
  
  // Use BaseBloc's built-in error handling
  Future<void> _onAddReaction(
    ChatAddReactionEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Use BaseBloc's emitLoading helper
    emitLoading(message: 'Adding reaction...');
    
    final result = await _addReactionUseCase(
      messageId: event.messageId,
      emojiCode: event.emojiCode,
    );
    
    result.fold(
      (failure) {
        // Use BaseBloc's emitError helper
        emitError(
          failure.message,
          error: failure,
          type: _mapFailureToErrorType(failure),
          shouldRetry: true,
        );
      },
      (message) {
        emit(ChatState.messageUpdated(message: message));
      },
    );
  }
  
  ErrorType _mapFailureToErrorType(Failure failure) {
    if (failure is NetworkFailure) return ErrorType.network;
    if (failure is ServerFailure) return ErrorType.server;
    if (failure is ValidationFailure) return ErrorType.validation;
    return ErrorType.general;
  }
}

// ❌ WRONG - Don't extend Bloc directly
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // Missing: error handling, logging, analytics, performance monitoring
}
```

**All States MUST extend `BaseState`:**
```dart
// ✅ CORRECT - Extend BaseState
@freezed
class ChatState extends BaseState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading({String? message, double? progress}) = ChatLoading;
  const factory ChatState.loaded({required List<ChatMessage> messages}) = ChatLoaded;
  const factory ChatState.messageUpdated({required ChatMessage message}) = ChatMessageUpdated;
  const factory ChatState.error({
    required String message,
    dynamic error,
    StackTrace? stackTrace,
    @Default(ErrorType.general) ErrorType type,
    @Default(false) bool shouldRetry,
  }) = ChatError;
}

// ❌ WRONG - Don't create states without BaseState
abstract class ChatState extends Equatable {
  // Missing: error type classification, retry logic, monitoring integration
}
```

#### Widget Layer Patterns

**All StatefulWidgets MUST extend `BaseStatefulWidget`:**
```dart
// ✅ CORRECT - Extend BaseStatefulWidget
class ReactionPickerWidget extends BaseStatefulWidget {
  final String messageId;
  final Function(String emojiCode) onReactionSelected;
  
  const ReactionPickerWidget({
    super.key,
    required this.messageId,
    required this.onReactionSelected,
  });
  
  @override
  ReactionPickerWidgetState createState() => ReactionPickerWidgetState();
}

class ReactionPickerWidgetState extends BaseState<ReactionPickerWidget> {
  // Use BaseState's lifecycle management and safeSetState
  
  @override
  void onAppResumed() {
    // Handle app resume
    _logger.d('ReactionPicker resumed');
  }
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Widget implementation
    );
  }
}

// ❌ WRONG - Don't extend StatefulWidget directly
class ReactionPickerWidget extends StatefulWidget {
  // Missing: lifecycle logging, safe setState, app state monitoring
}
```

**All StatelessWidgets MUST extend `BaseStatelessWidget`:**
```dart
// ✅ CORRECT - Extend BaseStatelessWidget
class MessageReactionDisplay extends BaseStatelessWidget {
  final List<MessageReaction> reactions;
  final Function(String emojiCode) onReactionTap;
  
  const MessageReactionDisplay({
    super.key,
    required this.reactions,
    required this.onReactionTap,
  });
  
  @override
  Widget buildContent(BuildContext context) {
    return Wrap(
      spacing: AppConstants.kSmallPadding,
      children: reactions.map((reaction) {
        return _buildReactionChip(context, reaction);
      }).toList(),
    );
  }
  
  Widget _buildReactionChip(BuildContext context, MessageReaction reaction) {
    return GestureDetector(
      onTap: () => onReactionTap(reaction.code),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.kSmallPadding,
          vertical: AppConstants.kSmallPadding / 2,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.kSmallBorderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reaction.code, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text('${reaction.count}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ❌ WRONG - Don't extend StatelessWidget directly
class MessageReactionDisplay extends StatelessWidget {
  // Missing: consistent build pattern, logging
}
```

### Constants Usage

**ALWAYS use `AppConstants` for UI dimensions, durations, and limits:**

```dart
// ✅ CORRECT - Use AppConstants
Container(
  padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
  margin: const EdgeInsets.symmetric(
    horizontal: AppConstants.kSmallPadding,
    vertical: AppConstants.kSmallPadding / 2,
  ),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.kDefaultBorderRadius),
  ),
  child: AnimatedOpacity(
    duration: AppConstants.kDefaultAnimationDuration,
    opacity: isVisible ? 1.0 : 0.0,
    child: child,
  ),
)

// File size validation
if (file.lengthSync() > AppConstants.kMaxAttachmentSize) {
  return ValidationFailure(message: 'File too large');
}

// Message length validation
if (content.length > AppConstants.kMaxMessageLength) {
  return ValidationFailure(message: 'Message too long');
}

// ❌ WRONG - Hardcoded values
Container(
  padding: const EdgeInsets.all(16.0), // Use AppConstants.kDefaultPadding
  margin: const EdgeInsets.symmetric(horizontal: 8.0), // Use AppConstants.kSmallPadding
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12.0), // Use AppConstants.kDefaultBorderRadius
  ),
)

if (file.lengthSync() > 25 * 1024 * 1024) { // Use AppConstants.kMaxAttachmentSize
  return ValidationFailure(message: 'File too large');
}
```

### Logging Standards

**ALWAYS use `Logger` instead of `print()`:**

```dart
// ✅ CORRECT - Use Logger
class AddReactionUseCase {
  final IMessageRepository _repository;
  final Logger _logger;
  
  AddReactionUseCase({
    required IMessageRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger;
  
  Future<Either<Failure, ChatMessage>> call({
    required String messageId,
    required String emojiCode,
  }) async {
    _logger.i('Adding reaction: $emojiCode to message $messageId');
    
    final result = await _repository.addReaction(
      messageId: messageId,
      emojiCode: emojiCode,
    );
    
    result.fold(
      (failure) => _logger.e('Failed to add reaction', error: failure),
      (message) => _logger.i('Reaction added successfully'),
    );
    
    return result;
  }
}

// ❌ WRONG - Using print()
print('Adding reaction: $emojiCode'); // NEVER use print()
debugPrint('Adding reaction: $emojiCode'); // NEVER use debugPrint()
```

### Localization Standards

**ALWAYS use localization for user-facing strings:**

```dart
// ✅ CORRECT - Use localization
Text(context.l10n.addReaction)
Text(context.l10n.editMessage)
Text(context.l10n.deleteMessage)
Text(context.l10n.uploadFile)

// Error messages
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(context.l10n.errorAddingReaction)),
);

// ❌ WRONG - Hardcoded strings
Text('Add Reaction') // Use context.l10n.addReaction
Text('Edit Message') // Use context.l10n.editMessage
Text('Error adding reaction') // Use context.l10n.errorAddingReaction
```

### Dependency Injection Standards

**ALWAYS use `@injectable` annotations:**

```dart
// ✅ CORRECT - Use @injectable
@injectable
class AddReactionUseCase {
  final IMessageRepository _repository;
  final Logger _logger;
  
  AddReactionUseCase({
    required IMessageRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger;
}

@LazySingleton(as: ISearchRepository)
class SearchRepositoryImpl implements ISearchRepository {
  final ISearchRemoteDataSource _remoteDataSource;
  final ISearchLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  final Logger _logger;
  
  SearchRepositoryImpl({
    required ISearchRemoteDataSource remoteDataSource,
    required ISearchLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _logger = logger;
}

// ❌ WRONG - Manual instantiation
class AddReactionUseCase {
  final repository = MessageRepositoryImpl(); // Don't instantiate manually
}
```

### Widget Composition Standards

**Reuse existing common widgets:**

```dart
// ✅ CORRECT - Use existing widgets
import 'package:flutter_chat_app/presentation/widgets/common/error_display_widget.dart';
import 'package:flutter_chat_app/presentation/widgets/connection/connection_status_widget.dart';

// Show errors using ErrorDisplayWidget
if (state is ChatError) {
  return ErrorDisplayWidget(
    failure: ServerFailure(message: state.message),
    onRetry: state.shouldRetry ? () => _retry() : null,
  );
}

// Show connection status
return Column(
  children: [
    const ConnectionStatusWidget(showDetails: true),
    Expanded(child: _buildMessageList()),
  ],
);

// ❌ WRONG - Create duplicate error widgets
Widget _buildError(String message) {
  return Container(
    child: Text(message), // Don't recreate error display logic
  );
}
```

### Performance Standards

**Use const constructors wherever possible:**

```dart
// ✅ CORRECT - Use const
const SizedBox(height: AppConstants.kDefaultPadding)
const Divider()
const CircularProgressIndicator()

// Widget with const constructor
class ReactionIcon extends StatelessWidget {
  final String emoji;
  
  const ReactionIcon({super.key, required this.emoji});
  
  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 24));
  }
}

// ❌ WRONG - Missing const
SizedBox(height: AppConstants.kDefaultPadding) // Add const
Divider() // Add const
CircularProgressIndicator() // Add const
```


## Architecture

### Layer Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ ChatBloc │  │SearchBloc│  │ Pages    │  │ Widgets  │   │
│  │(Extended)│  │  (New)   │  │ (New)    │  │ (New)    │   │
│  └────┬─────┘  └────┬──────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│       └─────────────┴──────────────┴─────────────┘          │
└───────────────────────┬─────────────────────────────────────┘
                        │ Events/States
┌───────────────────────┴─────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  New UseCases:                                       │   │
│  │  - AddReactionUseCase                                │   │
│  │  - RemoveReactionUseCase                             │   │
│  │  - EditMessageUseCase                                │   │
│  │  - DeleteMessageUseCase                              │   │
│  │  - UploadFileUseCase                                 │   │
│  │  - SearchMessagesUseCase                             │   │
│  │  - ReplyToMessageUseCase                             │   │
│  │  - ForwardMessageUseCase                             │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Extended Repositories:                              │   │
│  │  - IMessageRepository (add reaction/edit/delete)     │   │
│  │  - IMediaRepository (extend upload)                  │   │
│  │  New Repositories:                                   │   │
│  │  - ISearchRepository                                 │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │ Either<Failure, T>
┌───────────────────────┴─────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Extended Repository Implementations:                │   │
│  │  - MessageRepositoryImpl                             │   │
│  │  - MediaRepositoryImpl                               │   │
│  │  New Repository Implementations:                     │   │
│  │  - SearchRepositoryImpl                              │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Extended DataSources:                               │   │
│  │  - MessageRemoteDataSource (add mutations)           │   │
│  │  - MessageLocalDataSource (add queries)              │   │
│  │  New DataSources:                                    │   │
│  │  - SearchRemoteDataSource                            │   │
│  │  - SearchLocalDataSource (cache)                     │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │ Exceptions
┌───────────────────────┴─────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   GraphQL    │  │  Socket.IO   │  │     Isar     │     │
│  │    Client    │  │   Manager    │  │   Database   │     │
│  │  (Existing)  │  │  (Existing)  │  │  (Existing)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │    Media     │  │   Offline    │  │   Resource   │     │
│  │  Processing  │  │    Queue     │  │   Manager    │     │
│  │  (Existing)  │  │  (Existing)  │  │  (Existing)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Feature-Specific Data Flows

#### 1. Message Reactions Flow

**Add Reaction (Online):**
```
User taps emoji → ChatBloc.addReaction event
                        ↓
              AddReactionUseCase
                        ↓
              MessageRepository.addReaction()
                        ↓
              Check connectivity (online)
                        ↓
        MessageRemoteDataSource.addReaction()
                        ↓
        GraphQL: chatMessageUpdateReaction(act: ADD)
                        ↓
        MessageLocalDataSource.updateReaction()
                        ↓
        Cache reaction in Isar
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits updated state
                        ↓
        UI shows reaction immediately
```

**Add Reaction (Offline):**
```
User taps emoji → ChatBloc.addReaction event
                        ↓
              AddReactionUseCase
                        ↓
              MessageRepository.addReaction()
                        ↓
              Check connectivity (offline)
                        ↓
        OfflineQueueService.enqueue(REACTION_ADD)
                        ↓
        MessageLocalDataSource.updateReaction()
                        ↓
        Cache reaction with pending status
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits updated state
                        ↓
        UI shows reaction with pending indicator
                        ↓
        [When online] OfflineQueueService processes queue
                        ↓
        Send to backend → Update status → Emit success
```

**Real-time Reaction Event:**
```
Backend emits message:reaction event
                        ↓
        RealtimeService receives event
                        ↓
        Parse reaction data
                        ↓
        MessageLocalDataSource.updateReaction()
                        ↓
        Update Isar cache
                        ↓
        ChatBloc.onReactionReceived event
                        ↓
        ChatBloc emits updated state
                        ↓
        UI updates reaction display
```


#### 2. Message Edit Flow

**Edit Message (Online):**
```
User edits message → ChatBloc.editMessage event
                        ↓
              EditMessageUseCase
                        ↓
              Validate: message age < 48h
                        ↓
              Validate: user owns message
                        ↓
              MessageRepository.editMessage()
                        ↓
              Check connectivity (online)
                        ↓
        MessageRemoteDataSource.editMessage()
                        ↓
        GraphQL: chatMessageEdit(act: EDIT)
                        ↓
        MessageLocalDataSource.updateMessage()
                        ↓
        Update Isar with new content + editAt
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits updated state
                        ↓
        UI shows edited message with indicator
```

**Edit Message (Offline):**
```
User edits message → ChatBloc.editMessage event
                        ↓
              EditMessageUseCase
                        ↓
              Validate: message age < 48h
                        ↓
              Validate: user owns message
                        ↓
              MessageRepository.editMessage()
                        ↓
              Check connectivity (offline)
                        ↓
        OfflineQueueService.enqueue(MESSAGE_EDIT)
                        ↓
        MessageLocalDataSource.updateMessage()
                        ↓
        Update Isar with pending status
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits updated state
                        ↓
        UI shows edited message with pending indicator
```

#### 3. Message Delete Flow

**Delete Message (Online):**
```
User deletes message → ChatBloc.deleteMessage event
                        ↓
              DeleteMessageUseCase
                        ↓
              Validate: user owns message OR has permission
                        ↓
              MessageRepository.deleteMessage()
                        ↓
              Check connectivity (online)
                        ↓
        MessageRemoteDataSource.deleteMessage()
                        ↓
        GraphQL: chatMessageEdit(act: DELETE)
                        ↓
        MessageLocalDataSource.softDeleteMessage()
                        ↓
        Update Isar with deletedAt timestamp
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits updated state
                        ↓
        UI shows "Message deleted" placeholder
```

#### 4. File Upload Flow

**Upload File (Online):**
```
User selects file → ChatBloc.uploadFile event
                        ↓
              UploadFileUseCase
                        ↓
              Validate: file type and size
                        ↓
              MediaRepository.uploadFile()
                        ↓
        MediaProcessingService.processFile()
                        ↓
        If image/video: compress
                        ↓
        If image/video: generate thumbnail
                        ↓
        Check connectivity (online)
                        ↓
        MediaRemoteDataSource.uploadFile()
                        ↓
        Socket.IO: message:file:upload event
                        ↓
        Stream file with progress updates
                        ↓
        ChatBloc emits progress states
                        ↓
        UI shows upload progress bar
                        ↓
        Receive file URL from backend
                        ↓
        MessageRepository.sendMessage(urls: [fileUrl])
                        ↓
        Cache file in ResourceManagerService
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits success state
                        ↓
        UI shows message with file
```

**Upload File (Offline):**
```
User selects file → ChatBloc.uploadFile event
                        ↓
              UploadFileUseCase
                        ↓
              Validate: file type and size
                        ↓
              MediaRepository.uploadFile()
                        ↓
        MediaProcessingService.processFile()
                        ↓
        Compress and generate thumbnail
                        ↓
        Check connectivity (offline)
                        ↓
        AttachmentQueueService.enqueue()
                        ↓
        Store file locally with pending status
                        ↓
        MessageLocalDataSource.saveMessage()
                        ↓
        Save message with local file path
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits pending state
                        ↓
        UI shows message with pending indicator
                        ↓
        [When online] AttachmentQueueService processes
                        ↓
        Upload file → Update message → Emit success
```

#### 5. Search Messages Flow

**Search (Online):**
```
User enters query → SearchBloc.search event
                        ↓
              SearchMessagesUseCase
                        ↓
              SearchRepository.search()
                        ↓
              Check connectivity (online)
                        ↓
        SearchRemoteDataSource.search()
                        ↓
        GraphQL: chatSearch query
                        ↓
        Parse results
                        ↓
        SearchLocalDataSource.cacheResults()
                        ↓
        Cache in Isar for offline access
                        ↓
        Group results by conversation
                        ↓
        Return Either<Failure, List<SearchResult>>
                        ↓
        SearchBloc emits results state
                        ↓
        UI displays grouped results with highlights
```

**Search (Offline):**
```
User enters query → SearchBloc.search event
                        ↓
              SearchMessagesUseCase
                        ↓
              SearchRepository.search()
                        ↓
              Check connectivity (offline)
                        ↓
        SearchLocalDataSource.searchCache()
                        ↓
        Query Isar for cached messages
                        ↓
        Filter by query text
                        ↓
        Group results by conversation
                        ↓
        Return Either<Failure, List<SearchResult>>
                        ↓
        SearchBloc emits results state
                        ↓
        UI displays results with offline indicator
```

#### 6. Reply and Forward Flow

**Reply to Message:**
```
User taps reply → ChatBloc.replyToMessage event
                        ↓
              ReplyToMessageUseCase
                        ↓
              Load original message context
                        ↓
              ChatBloc emits reply mode state
                        ↓
              UI shows reply context in compose area
                        ↓
User sends reply → ChatBloc.sendMessage event
                        ↓
              SendMessageUseCase
                        ↓
              MessageRepository.sendMessage()
                        ↓
        Include replyMessageId in mutation
                        ↓
        GraphQL: chatMessageAdd(replyMessageId: ...)
                        ↓
        MessageLocalDataSource.saveMessage()
                        ↓
        Link reply to original in Isar
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits success state
                        ↓
        UI shows reply with context
```

**Forward Message:**
```
User taps forward → ChatBloc.forwardMessage event
                        ↓
              ForwardMessageUseCase
                        ↓
              ChatBloc emits conversation picker state
                        ↓
              UI shows conversation picker
                        ↓
User selects conversations → ChatBloc.confirmForward event
                        ↓
              ForwardMessageUseCase
                        ↓
              For each target conversation:
                        ↓
              MessageRepository.sendMessage()
                        ↓
        Include forwardedFromMessageId
                        ↓
        GraphQL: chatMessageAdd(forwardedFromMessageId: ...)
                        ↓
        MessageLocalDataSource.saveMessage()
                        ↓
        Mark as forwarded in Isar
                        ↓
        Return Either<Failure, Message>
                        ↓
        ChatBloc emits progress/success states
                        ↓
        UI shows forwarded messages
```


## Components and Interfaces

### Domain Layer

#### New UseCases

**AddReactionUseCase:**
```dart
@injectable
class AddReactionUseCase {
  final IMessageRepository _repository;
  
  AddReactionUseCase({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, ChatMessage>> call({
    required String messageId,
    required String emojiCode,
  }) async {
    return _repository.addReaction(
      messageId: messageId,
      emojiCode: emojiCode,
    );
  }
}
```

**RemoveReactionUseCase:**
```dart
@injectable
class RemoveReactionUseCase {
  final IMessageRepository _repository;
  
  RemoveReactionUseCase({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, ChatMessage>> call({
    required String messageId,
    required String emojiCode,
  }) async {
    return _repository.removeReaction(
      messageId: messageId,
      emojiCode: emojiCode,
    );
  }
}
```

**EditMessageUseCase:**
```dart
@injectable
class EditMessageUseCase {
  final IMessageRepository _repository;
  
  EditMessageUseCase({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, ChatMessage>> call({
    required String messageId,
    required String newContent,
    required String currentUserId,
  }) async {
    // Validate message age (48 hours)
    final message = await _repository.getMessageById(messageId);
    return message.fold(
      (failure) => Left(failure),
      (msg) {
        final age = DateTime.now().difference(msg.createdAt);
        if (age.inHours > 48) {
          return Left(ValidationFailure(
            message: 'Cannot edit messages older than 48 hours',
          ));
        }
        
        // Validate ownership
        if (msg.senderId != currentUserId) {
          return Left(ValidationFailure(
            message: 'You can only edit your own messages',
          ));
        }
        
        return _repository.editMessage(
          messageId: messageId,
          newContent: newContent,
        );
      },
    );
  }
}
```

**DeleteMessageUseCase:**
```dart
@injectable
class DeleteMessageUseCase {
  final IMessageRepository _repository;
  
  DeleteMessageUseCase({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, ChatMessage>> call({
    required String messageId,
    required String currentUserId,
    required bool deleteForEveryone,
  }) async {
    // Validate ownership
    final message = await _repository.getMessageById(messageId);
    return message.fold(
      (failure) => Left(failure),
      (msg) {
        if (msg.senderId != currentUserId && deleteForEveryone) {
          return Left(ValidationFailure(
            message: 'You can only delete your own messages for everyone',
          ));
        }
        
        return _repository.deleteMessage(
          messageId: messageId,
          deleteForEveryone: deleteForEveryone,
        );
      },
    );
  }
}
```

**UploadFileUseCase:**
```dart
@injectable
class UploadFileUseCase {
  final IMediaRepository _repository;
  
  UploadFileUseCase({required IMediaRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, String>> call({
    required File file,
    required String fileName,
    required ChatMessageType messageType,
    void Function(double progress)? onProgress,
  }) async {
    // Validate file type and size
    final validation = _validateFile(file, messageType);
    if (validation != null) {
      return Left(validation);
    }
    
    return _repository.uploadFile(
      file: file,
      fileName: fileName,
      messageType: messageType,
      onProgress: onProgress,
    );
  }
  
  ValidationFailure? _validateFile(File file, ChatMessageType type) {
    final size = file.lengthSync();
    final extension = path.extension(file.path).toLowerCase();
    
    switch (type) {
      case ChatMessageType.IMAGE:
        if (size > 10 * 1024 * 1024) {
          return ValidationFailure(message: 'Image must be under 10MB');
        }
        if (!['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
          return ValidationFailure(message: 'Invalid image format');
        }
        break;
      case ChatMessageType.VIDEO:
        if (size > 50 * 1024 * 1024) {
          return ValidationFailure(message: 'Video must be under 50MB');
        }
        if (!['.mp4', '.mov', '.avi'].contains(extension)) {
          return ValidationFailure(message: 'Invalid video format');
        }
        break;
      case ChatMessageType.FILE:
        if (size > 20 * 1024 * 1024) {
          return ValidationFailure(message: 'Document must be under 20MB');
        }
        break;
      case ChatMessageType.AUDIO:
        if (size > 10 * 1024 * 1024) {
          return ValidationFailure(message: 'Audio must be under 10MB');
        }
        if (!['.mp3', '.wav', '.aac', '.m4a'].contains(extension)) {
          return ValidationFailure(message: 'Invalid audio format');
        }
        break;
      default:
        return ValidationFailure(message: 'Unsupported file type');
    }
    
    return null;
  }
}
```

**SearchMessagesUseCase:**
```dart
@injectable
class SearchMessagesUseCase {
  final ISearchRepository _repository;
  
  SearchMessagesUseCase({required ISearchRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, List<SearchResult>>> call({
    required String query,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<ChatMessageType>? messageTypes,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 50,
  }) async {
    if (query.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Search query cannot be empty'));
    }
    
    return _repository.search(
      query: query,
      conversationIds: conversationIds,
      senderIds: senderIds,
      messageTypes: messageTypes,
      fromDate: fromDate,
      toDate: toDate,
      page: page,
      size: size,
    );
  }
}
```

**ReplyToMessageUseCase:**
```dart
@injectable
class ReplyToMessageUseCase {
  final IMessageRepository _repository;
  
  ReplyToMessageUseCase({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, ChatMessage>> call({
    required String conversationId,
    required String replyToMessageId,
    required String content,
    ChatMessageType type = ChatMessageType.TEXT,
  }) async {
    return _repository.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      replyToMessageId: replyToMessageId,
    );
  }
}
```

**ForwardMessageUseCase:**
```dart
@injectable
class ForwardMessageUseCase {
  final IMessageRepository _repository;
  
  ForwardMessageUseCase({required IMessageRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, List<ChatMessage>>> call({
    required String messageId,
    required List<String> targetConversationIds,
  }) async {
    // Load original message
    final originalResult = await _repository.getMessageById(messageId);
    
    return originalResult.fold(
      (failure) => Left(failure),
      (original) async {
        final results = <ChatMessage>[];
        
        // Forward to each conversation
        for (final conversationId in targetConversationIds) {
          final result = await _repository.sendMessage(
            conversationId: conversationId,
            content: original.message,
            type: original.type,
            urls: original.urls,
            fileName: original.fileName,
            forwardedFromMessageId: messageId,
          );
          
          result.fold(
            (failure) => null, // Continue with other conversations
            (message) => results.add(message),
          );
        }
        
        if (results.isEmpty) {
          return Left(ServerFailure(message: 'Failed to forward message'));
        }
        
        return Right(results);
      },
    );
  }
}
```

#### Extended Repository Interfaces

**IMessageRepository (Extended):**
```dart
abstract class IMessageRepository {
  // Existing methods from Phase 1...
  
  // New methods for Phase 2
  Future<Either<Failure, ChatMessage>> addReaction({
    required String messageId,
    required String emojiCode,
  });
  
  Future<Either<Failure, ChatMessage>> removeReaction({
    required String messageId,
    required String emojiCode,
  });
  
  Future<Either<Failure, ChatMessage>> editMessage({
    required String messageId,
    required String newContent,
  });
  
  Future<Either<Failure, ChatMessage>> deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  });
  
  Future<Either<Failure, ChatMessage>> getMessageById(String messageId);
}
```

**ISearchRepository (New):**
```dart
abstract class ISearchRepository {
  Future<Either<Failure, List<SearchResult>>> search({
    required String query,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<ChatMessageType>? messageTypes,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 50,
  });
  
  Future<Either<Failure, void>> clearSearchCache();
}
```

**IMediaRepository (Extended):**
```dart
abstract class IMediaRepository {
  // Existing methods from Phase 1...
  
  // Enhanced upload with progress
  Future<Either<Failure, String>> uploadFile({
    required File file,
    required String fileName,
    required ChatMessageType messageType,
    void Function(double progress)? onProgress,
  });
}
```

#### New Entities

**SearchResult Entity:**
```dart
class SearchResult extends Equatable {
  final ChatMessage message;
  final String conversationId;
  final String conversationName;
  final List<TextHighlight> highlights;
  
  const SearchResult({
    required this.message,
    required this.conversationId,
    required this.conversationName,
    required this.highlights,
  });
  
  @override
  List<Object?> get props => [message, conversationId, conversationName, highlights];
}

class TextHighlight extends Equatable {
  final int start;
  final int end;
  final String matchedText;
  
  const TextHighlight({
    required this.start,
    required this.end,
    required this.matchedText,
  });
  
  @override
  List<Object?> get props => [start, end, matchedText];
}
```


### Data Layer

#### Extended Repository Implementations

**MessageRepositoryImpl (Extended):**
```dart
@LazySingleton(as: IMessageRepository)
class MessageRepositoryImpl implements IMessageRepository {
  final IMessageRemoteDataSource _remoteDataSource;
  final IMessageLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  final OfflineQueueService _offlineQueue;
  final Logger _logger;
  
  MessageRepositoryImpl({
    required IMessageRemoteDataSource remoteDataSource,
    required IMessageLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
    required OfflineQueueService offlineQueue,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _offlineQueue = offlineQueue,
       _logger = logger;
  
  // Existing methods from Phase 1...
  
  @override
  Future<Either<Failure, ChatMessage>> addReaction({
    required String messageId,
    required String emojiCode,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        // Online: send to backend
        final model = await _remoteDataSource.addReaction(
          messageId: messageId,
          emojiCode: emojiCode,
        );
        
        // Cache locally
        await _localDataSource.updateMessage(model);
        
        _logger.i('Reaction added successfully: $emojiCode on message $messageId');
        return Right(model.toEntity());
      } else {
        // Offline: queue operation
        await _offlineQueue.enqueue(OfflineOperation(
          type: OfflineOperationType.REACTION_ADD,
          data: {
            'messageId': messageId,
            'emojiCode': emojiCode,
          },
          timestamp: DateTime.now(),
        ));
        
        // Update local cache optimistically
        final message = await _localDataSource.getMessageById(messageId);
        final updatedModel = message.copyWith(
          reactions: [...message.reactions, MessageReactionModel(
            code: emojiCode,
            userId: _getCurrentUserId(),
          )],
        );
        await _localDataSource.updateMessage(updatedModel);
        
        _logger.i('Reaction queued for offline sync: $emojiCode on message $messageId');
        return Right(updatedModel.toEntity());
      }
    } on ServerException catch (e) {
      _logger.e('Server error adding reaction', error: e);
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      _logger.e('Cache error adding reaction', error: e);
      return Left(CacheFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e('Unexpected error adding reaction', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure(message: '$e'));
    }
  }
  
  @override
  Future<Either<Failure, ChatMessage>> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        final model = await _remoteDataSource.editMessage(
          messageId: messageId,
          newContent: newContent,
        );
        
        await _localDataSource.updateMessage(model);
        
        _logger.i('Message edited successfully: $messageId');
        return Right(model.toEntity());
      } else {
        await _offlineQueue.enqueue(OfflineOperation(
          type: OfflineOperationType.MESSAGE_EDIType.MESSAGE_EDIT,
          data: {
            'messageId': messageId,
            'newContent': newContent,
          },
          timestamp: DateTime.now(),
        ));
        
        final message = await _localDataSource.getMessageById(messageId);
        final updatedModel = message.copyWith(
          message: newContent,
          editAt: DateTime.now(),
        );
        await _localDataSource.updateMessage(updatedModel);
        
        return Right(updatedModel.toEntity());
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }
  
  @override
  Future<Either<Failure, ChatMessage>> deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        final model = await _remoteDataSource.deleteMessage(
          messageId: messageId,
          deleteForEveryone: deleteForEveryone,
        );
        
        await _localDataSource.softDeleteMessage(messageId);
        
        return Right(model.toEntity());
      } else {
        await _offlineQueue.enqueue(OfflineOperation(
          type: OfflineOperationType.MESSAGE_DELETE,
          data: {
            'messageId': messageId,
            'deleteForEveryone': deleteForEveryone,
          },
          timestamp: DateTime.now(),
        ));
        
        await _localDataSource.softDeleteMessage(messageId);
        
        final message = await _localDataSource.getMessageById(messageId);
        return Right(message.toEntity());
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }
}
```

**SearchRepositoryImpl (New):**
```dart
@LazySingleton(as: ISearchRepository)
class SearchRepositoryImpl implements ISearchRepository {
  final ISearchRemoteDataSource _remoteDataSource;
  final ISearchLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  
  SearchRepositoryImpl({
    required ISearchRemoteDataSource remoteDataSource,
    required ISearchLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;
  
  @override
  Future<Either<Failure, List<SearchResult>>> search({
    required String query,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<ChatMessageType>? messageTypes,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 50,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        // Online: search backend
        final results = await _remoteDataSource.search(
          query: query,
          conversationIds: conversationIds,
          senderIds: senderIds,
          messageTypes: messageTypes,
          fromDate: fromDate,
          toDate: toDate,
          page: page,
          size: size,
        );
        
        // Cache results
        await _localDataSource.cacheSearchResults(query, results);
        
        return Right(results.map((m) => m.toEntity()).toList());
      } else {
        // Offline: search local cache
        final cachedResults = await _localDataSource.searchLocal(
          query: query,
          conversationIds: conversationIds,
          senderIds: senderIds,
          messageTypes: messageTypes,
          fromDate: fromDate,
          toDate: toDate,
        );
        
        return Right(cachedResults.map((m) => m.toEntity()).toList());
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }
  
  @override
  Future<Either<Failure, void>> clearSearchCache() async {
    try {
      await _localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: '$e'));
    }
  }
}
```

#### Extended DataSources

**MessageRemoteDataSource (Extended):**
```dart
abstract class IMessageRemoteDataSource {
  // Existing methods...
  
  Future<MessageModel> addReaction({
    required String messageId,
    required String emojiCode,
  });
  
  Future<MessageModel> removeReaction({
    required String messageId,
    required String emojiCode,
  });
  
  Future<MessageModel> editMessage({
    required String messageId,
    required String newContent,
  });
  
  Future<MessageModel> deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  });
}

@LazySingleton(as: IMessageRemoteDataSource)
class MessageRemoteDataSourceImpl implements IMessageRemoteDataSource {
  final GraphQLClient _client;
  
  // Existing methods...
  
  @override
  Future<MessageModel> addReaction({
    required String messageId,
    required String emojiCode,
  }) async {
    const mutation = r'''
      mutation AddReaction($args: ChatMessageUpdateReactionArgs!) {
        chatMessageUpdateReaction(arguments: $args) {
          id
          reactions {
            code
            userId
            user {
              id
              fullname
              avatarUrl
            }
          }
        }
      }
    ''';
    
    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'args': {
            'messageId': messageId,
            'code': emojiCode,
            'act': 'ADD',
          },
        },
      ),
    );
    
    if (result.hasException) {
      throw ServerException(message: result.exception.toString());
    }
    
    return MessageModel.fromJson(result.data!['chatMessageUpdateReaction']);
  }
  
  @override
  Future<MessageModel> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    const mutation = r'''
      mutation EditMessage($args: ChatMessageUpdateArgs!) {
        chatMessageEdit(arguments: $args) {
          id
          message
          editAt
        }
      }
    ''';
    
    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'args': {
            'messageId': messageId,
            'act': 'EDIT',
            'message': newContent,
          },
        },
      ),
    );
    
    if (result.hasException) {
      throw ServerException(message: result.exception.toString());
    }
    
    return MessageModel.fromJson(result.data!['chatMessageEdit']);
  }
}
```

**SearchRemoteDataSource (New):**
```dart
abstract class ISearchRemoteDataSource {
  Future<List<SearchResultModel>> search({
    required String query,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<ChatMessageType>? messageTypes,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 50,
  });
}

@LazySingleton(as: ISearchRemoteDataSource)
class SearchRemoteDataSourceImpl implements ISearchRemoteDataSource {
  final GraphQLClient _client;
  
  SearchRemoteDataSourceImpl({required GraphQLClient client})
      : _client = client;
  
  @override
  Future<List<SearchResultModel>> search({
    required String query,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<ChatMessageType>? messageTypes,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 50,
  }) async {
    const queryStr = r'''
      query SearchMessages($filters: ChatSearchArgs!) {
        chatSearch(filters: $filters) {
          id
          message
          fileName
          type
          createdAt
          senderId
          sender {
            id
            fullname
            avatarUrl
          }
          conversationId
        }
      }
    ''';
    
    final result = await _client.query(
      QueryOptions(
        document: gql(queryStr),
        variables: {
          'filters': {
            'keyword': query,
            if (conversationIds != null) 'conversationIds': conversationIds,
            if (senderIds != null) 'senderIds': senderIds,
            if (messageTypes != null) 'messageTypes': messageTypes.map((t) => t.name).toList(),
            if (fromDate != null) 'from': fromDate.millisecondsSinceEpoch,
            if (toDate != null) 'to': toDate.millisecondsSinceEpoch,
            'page': page,
            'size': size,
          },
        },
      ),
    );
    
    if (result.hasException) {
      throw ServerException(message: result.exception.toString());
    }
    
    final messages = result.data!['chatSearch'] as List;
    return messages.map((json) => SearchResultModel.fromJson(json)).toList();
  }
}
```


### Presentation Layer

#### Extended BLoC Events and States

**ChatBloc Events (Extended):**
```dart
@freezed
class ChatEvent with _$ChatEvent {
  // Existing events from Phase 1...
  
  // New events for Phase 2
  const factory ChatEvent.addReaction({
    required String messageId,
    required String emojiCode,
  }) = ChatAddReactionEvent;
  
  const factory ChatEvent.removeReaction({
    required String messageId,
    required String emojiCode,
  }) = ChatRemoveReactionEvent;
  
  const factory ChatEvent.editMessage({
    required String messageId,
    required String newContent,
  }) = ChatEditMessageEvent;
  
  const factory ChatEvent.deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  }) = ChatDeleteMessageEvent;
  
  const factory ChatEvent.uploadFile({
    required File file,
    required String fileName,
    required ChatMessageType messageType,
  }) = ChatUploadFileEvent;
  
  const factory ChatEvent.replyToMessage({
    required String messageId,
  }) = ChatReplyToMessageEvent;
  
  const factory ChatEvent.cancelReply() = ChatCancelReplyEvent;
  
  const factory ChatEvent.forwardMessage({
    required String messageId,
    required List<String> targetConversationIds,
  }) = ChatForwardMessageEvent;
  
  // Real-time events
  const factory ChatEvent.reactionReceived({
    required String messageId,
    required String emojiCode,
    required String userId,
    required String action, // ADD | REMOVE
  }) = ChatReactionReceivedEvent;
  
  const factory ChatEvent.messageEdited({
    required ChatMessage message,
  }) = ChatMessageEditedEvent;
  
  const factory ChatEvent.messageDeleted({
    required String messageId,
  }) = ChatMessageDeletedEvent;
}
```

**ChatBloc States (Extended):**
```dart
@freezed
class ChatState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  
  const factory ChatState.loading({
    String? operation,
  }) = ChatLoading;
  
  const factory ChatState.loaded({
    required List<ChatMessage> messages,
    required bool hasMore,
    ChatMessage? replyingTo,
    FileUploadProgress? uploadProgress,
  }) = ChatLoaded;
  
  const factory ChatState.error({
    required Failure failure,
    required String operation,
    VoidCallback? retryAction,
  }) = ChatError;
}

class FileUploadProgress {
  final String fileName;
  final double progress; // 0.0 to 1.0
  final FileUploadStatus status;
  
  const FileUploadProgress({
    required this.fileName,
    required this.progress,
    required this.status,
  });
}

enum FileUploadStatus {
  processing,
  uploading,
  completed,
  failed,
}
```

**SearchBloc (New):**
```dart
@freezed
class SearchEvent with _$SearchEvent {
  const factory SearchEvent.search({
    required String query,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<ChatMessageType>? messageTypes,
    DateTime? fromDate,
    DateTime? toDate,
  }) = SearchQueryEvent;
  
  const factory SearchEvent.clearResults() = SearchClearEvent;
  
  const factory SearchEvent.applyFilter({
    List<String>? conversationIds,
    List<String>? senderIds,
    List<ChatMessageType>? messageTypes,
    DateTime? fromDate,
    DateTime? toDate,
  }) = SearchApplyFilterEvent;
}

@freezed
class SearchState with _$SearchState {
  const factory SearchState.initial() = SearchInitial;
  
  const factory SearchState.loading() = SearchLoading;
  
  const factory SearchState.loaded({
    required String query,
    required List<SearchResult> results,
    required Map<String, List<SearchResult>> groupedResults,
  }) = SearchLoaded;
  
  const factory SearchState.empty({
    required String query,
  }) = SearchEmpty;
  
  const factory SearchState.error({
    required Failure failure,
    VoidCallback? retryAction,
  }) = SearchError;
}

@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchMessagesUseCase _searchUseCase;
  
  SearchBloc({
    required SearchMessagesUseCase searchUseCase,
  }) : _searchUseCase = searchUseCase,
       super(const SearchState.initial()) {
    on<SearchQueryEvent>(_onSearch);
    on<SearchClearEvent>(_onClear);
    on<SearchApplyFilterEvent>(_onApplyFilter);
  }
  
  Future<void> _onSearch(
    SearchQueryEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchState.loading());
    
    final result = await _searchUseCase(
      query: event.query,
      conversationIds: event.conversationIds,
      senderIds: event.senderIds,
      messageTypes: event.messageTypes,
      fromDate: event.fromDate,
      toDate: event.toDate,
    );
    
    result.fold(
      (failure) => emit(SearchState.error(
        failure: failure,
        retryAction: () => add(event),
      )),
      (results) {
        if (results.isEmpty) {
          emit(SearchState.empty(query: event.query));
        } else {
          // Group results by conversation
          final grouped = <String, List<SearchResult>>{};
          for (final result in results) {
            grouped.putIfAbsent(result.conversationId, () => []).add(result);
          }
          
          emit(SearchState.loaded(
            query: event.query,
            results: results,
            groupedResults: grouped,
          ));
        }
      },
    );
  }
}
```

#### New UI Components

**ReactionPicker Widget:**
```dart
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;
  
  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });
  
  static const commonEmojis = [
    '👍', '❤️', '😂', '😮', '😢', '🙏',
    '👏', '🔥', '🎉', '💯', '✅', '❌',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: commonEmojis.map((emoji) {
          return InkWell(
            onTap: () => onEmojiSelected(emoji),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

**MessageReactionDisplay Widget:**
```dart
class MessageReactionDisplay extends StatelessWidget {
  final List<MessageReaction> reactions;
  final Function(String emoji) onReactionTap;
  final Function(String emoji) onReactionLongPress;
  
  const MessageReactionDisplay({
    super.key,
    required this.reactions,
    required this.onReactionTap,
    required this.onReactionLongPress,
  });
  
  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    
    // Group reactions by emoji
    final grouped = <String, List<MessageReaction>>{};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.code, () => []).add(reaction);
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: grouped.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value.length;
        
        return InkWell(
          onTap: () => onReactionTap(emoji),
          onLongPress: () => onReactionLongPress(emoji),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

**SearchResultItem Widget:**
```dart
class SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;
  
  const SearchResultItem({
    super.key,
    required this.result,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: result.message.sender.avatarUrl != null
            ? NetworkImage(result.message.sender.avatarUrl!)
            : null,
        child: result.message.sender.avatarUrl == null
            ? Text(result.message.sender.fullname[0])
            : null,
      ),
      title: Text(result.conversationName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.message.sender.fullname,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          _buildHighlightedText(context),
        ],
      ),
      trailing: Text(
        _formatDate(result.message.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
  
  Widget _buildHighlightedText(BuildContext context) {
    final text = result.message.message;
    final highlights = result.highlights;
    
    if (highlights.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final spans = <TextSpan>[];
    int lastIndex = 0;
    
    for (final highlight in highlights) {
      // Add text before highlight
      if (highlight.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, highlight.start)));
      }
      
      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(highlight.start, highlight.end),
        style: TextStyle(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = highlight.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return DateFormat.Hm().format(date);
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}
```


## Data Models

### Extended Models

**MessageModel (Already exists, confirm fields):**
```dart
@collection
class MessageModel {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String messageId;
  late String message;
  List<String>? urls;
  @Enumerated(EnumType.name)
  late ChatMessageType type;
  late DateTime createdAt;
  DateTime? editAt;
  DateTime? deletedAt;
  String? replyMessageId;
  String? forwardedFromMessageId;
  String? fileName;
  late String senderId;
  late String conversationId;
  List<String>? readerIds;
  
  // Reactions stored as embedded objects
  List<MessageReactionModel> reactions = [];
  
  // Sync status
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.synced;
  
  // Mappers
  ChatMessage toEntity() {
    return ChatMessage(
      id: messageId,
      message: message,
      urls: urls,
      type: type,
      createdAt: createdAt,
      editAt: editAt,
      deletedAt: deletedAt,
      replyMessageId: replyMessageId,
      forwardedFromMessageId: forwardedFromMessageId,
      fileName: fileName,
      senderId: senderId,
      conversationId: conversationId,
      readerIds: readerIds ?? [],
      reactions: reactions.map((r) => r.toEntity()).toList(),
      sender: User(id: senderId, fullname: '', email: ''), // Populated separately
    );
  }
  
  factory MessageModel.fromEntity(ChatMessage entity) {
    return MessageModel()
      ..messageId = entity.id
      ..message = entity.message
      ..urls = entity.urls
      ..type = entity.type
      ..createdAt = entity.createdAt
      ..editAt = entity.editAt
      ..deletedAt = entity.deletedAt
      ..replyMessageId = entity.replyMessageId
      ..forwardedFromMessageId = entity.forwardedFromMessageId
      ..fileName = entity.fileName
      ..senderId = entity.senderId
      ..conversationId = entity.conversationId
      ..readerIds = entity.readerIds
      ..reactions = entity.reactions.map((r) => MessageReactionModel.fromEntity(r)).toList();
  }
}
```

**MessageReactionModel (Already exists):**
```dart
@embedded
class MessageReactionModel {
  late String code;
  late String userId;
  
  MessageReaction toEntity() {
    return MessageReaction(
      code: code,
      userId: userId,
    );
  }
  
  factory MessageReactionModel.fromEntity(MessageReaction entity) {
    return MessageReactionModel()
      ..code = entity.code
      ..userId = entity.userId;
  }
}
```

**SearchResultModel (New):**
```dart
@collection
class SearchResultModel {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String searchQuery;
  late String messageId;
  late String conversationId;
  late String conversationName;
  late DateTime searchedAt;
  
  // Embedded message data
  late String messageContent;
  late String senderName;
  late DateTime messageCreatedAt;
  
  // Highlight positions
  List<int> highlightStarts = [];
  List<int> highlightEnds = [];
  
  SearchResult toEntity(ChatMessage message) {
    final highlights = <TextHighlight>[];
    for (int i = 0; i < highlightStarts.length; i++) {
      highlights.add(TextHighlight(
        start: highlightStarts[i],
        end: highlightEnds[i],
        matchedText: messageContent.substring(highlightStarts[i], highlightEnds[i]),
      ));
    }
    
    return SearchResult(
      message: message,
      conversationId: conversationId,
      conversationName: conversationName,
      highlights: highlights,
    );
  }
  
  factory SearchResultModel.fromEntity(SearchResult entity, String query) {
    return SearchResultModel()
      ..searchQuery = query
      ..messageId = entity.message.id
      ..conversationId = entity.conversationId
      ..conversationName = entity.conversationName
      ..searchedAt = DateTime.now()
      ..messageContent = entity.message.message
      ..senderName = entity.message.sender.fullname
      ..messageCreatedAt = entity.message.createdAt
      ..highlightStarts = entity.highlights.map((h) => h.start).toList()
      ..highlightEnds = entity.highlights.map((h) => h.end).toList();
  }
}
```

**OfflineOperationType (Extended):**
```dart
enum OfflineOperationType {
  // Existing from Phase 1
  MESSAGE_SEND,
  MESSAGE_READ,
  CONVERSATION_JOIN,
  CONVERSATION_LEAVE,
  
  // New for Phase 2
  REACTION_ADD,
  REACTION_REMOVE,
  MESSAGE_EDIT,
  MESSAGE_DELETE,
  FILE_UPLOAD,
  MESSAGE_REPLY,
  MESSAGE_FORWARD,
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, I identified the following testable properties and performed reflection to eliminate redundancy:

**Redundancy Analysis:**
- Properties 1.2 and 1.3 (reaction persistence and real-time updates) are complementary, not redundant
- Properties 2.2 and 2.3 (edit persistence and real-time updates) are complementary, not redundant
- Properties 2.8 and 2.9 (ID preservation and ordering) can be combined into a single invariant property
- Properties 3.3 and 3.4 (delete persistence and real-time updates) are complementary, not redundant
- Properties 3.8 and 3.9 (ID preservation and conversation continuity) can be combined
- Properties 4.2 and 4.3 (compression and thumbnail) are separate concerns, keep both
- Properties 6.3 and 6.4 (reply linking and display) are complementary, not redundant

**Result:** Most properties provide unique validation value. Combined 2 pairs of properties for cleaner design.

### Message Reactions Properties

**Property 1: Reaction Mutation Correctness**
*For any* message and emoji code, when a user adds a reaction, the system should call the `chatMessageUpdateReaction` mutation with the correct messageId, code, and act=ADD parameters.
**Validates: Requirements 1.1**

**Property 2: Reaction Persistence**
*For any* message and reaction, when a reaction is added successfully, querying the local database should return the message with that reaction included.
**Validates: Requirements 1.2**

**Property 3: Real-time Reaction Updates**
*For any* `message:reaction` event received, the system should update the message's reactions in the local database and emit a state update.
**Validates: Requirements 1.3**

**Property 4: Reaction Display Correctness**
*For any* message with reactions, the rendered output should contain all unique emoji codes with their correct counts.
**Validates: Requirements 1.4**

**Property 5: Reaction Removal**
*For any* message with a user's reaction, removing that reaction should call the mutation with act=REMOVE and remove it from the local database.
**Validates: Requirements 1.6**

**Property 6: Offline Reaction Queueing**
*For any* reaction operation performed while offline, the operation should be added to the offline queue and processed when connectivity is restored.
**Validates: Requirements 1.7**

**Property 7: Concurrent Reaction Handling**
*For any* set of concurrent reaction operations on the same message, all reactions should be preserved in the final state without data loss.
**Validates: Requirements 1.8**

### Message Editing Properties

**Property 8: Edit Mutation Correctness**
*For any* message owned by the current user, when editing the message, the system should call the `chatMessageEdit` mutation with the correct messageId, act=EDIT, and new content.
**Validates: Requirements 2.1**

**Property 9: Edit Persistence**
*For any* edited message, querying the local database should return the message with the new content and a non-null editAt timestamp.
**Validates: Requirements 2.2**

**Property 10: Real-time Edit Updates**
*For any* `message:edit` event received, the system should update the message content in the local database and emit a state update.
**Validates: Requirements 2.3**

**Property 11: Edit Indicator Display**
*For any* message with a non-null editAt timestamp, the rendered output should contain an "edited" indicator.
**Validates: Requirements 2.4**

**Property 12: Edit Time Validation**
*For any* message older than 48 hours, attempting to edit should return a ValidationFailure.
**Validates: Requirements 2.5**

**Property 13: Edit Ownership Validation**
*For any* message not owned by the current user, attempting to edit should return a ValidationFailure.
**Validates: Requirements 2.6**

**Property 14: Offline Edit Queueing**
*For any* edit operation performed while offline, the operation should be added to the offline queue and processed when connectivity is restored.
**Validates: Requirements 2.7**

**Property 15: Edit Invariants**
*For any* message edit operation, the message ID and position in the conversation should remain unchanged.
**Validates: Requirements 2.8, 2.9**

### Message Deletion Properties

**Property 16: Delete Mutation Correctness**
*For any* message, when deleting, the system should call the `chatMessageEdit` mutation with act=DELETE and the correct deleteForEveryone flag.
**Validates: Requirements 3.1, 3.2**

**Property 17: Delete Persistence**
*For any* deleted message, querying the local database should return the message with a non-null deletedAt timestamp.
**Validates: Requirements 3.3**

**Property 18: Real-time Delete Updates**
*For any* `message:delete` event received, the system should update the message status in the local database and emit a state update.
**Validates: Requirements 3.4**

**Property 19: Delete Placeholder Display**
*For any* message with a non-null deletedAt timestamp, the rendered output should show a "Message deleted" placeholder instead of the original content.
**Validates: Requirements 3.5**

**Property 20: Delete Ownership Validation**
*For any* message not owned by the current user, attempting to delete for everyone should return a ValidationFailure.
**Validates: Requirements 3.6**

**Property 21: Offline Delete Queueing**
*For any* delete operation performed while offline, the operation should be added to the offline queue and processed when connectivity is restored.
**Validates: Requirements 3.7**

**Property 22: Delete Invariants**
*For any* message deletion, the message ID and metadata should be preserved in the database (soft delete).
**Validates: Requirements 3.8, 3.9**

### File Upload Properties

**Property 23: File Validation**
*For any* file, the system should validate type and size constraints before processing, rejecting invalid files with a ValidationFailure.
**Validates: Requirements 4.1, 4.13**

**Property 24: Image/Video Compression**
*For any* valid image or video file, the system should apply compression before upload.
**Validates: Requirements 4.2**

**Property 25: Thumbnail Generation**
*For any* valid image or video file, the system should generate a thumbnail before upload.
**Validates: Requirements 4.3**

**Property 26: File Upload via Socket.IO**
*For any* processed file, the system should send it to the backend via the `message:file:upload` Socket.IO event.
**Validates: Requirements 4.4**

**Property 27: Upload Progress Tracking**
*For any* file being uploaded, the system should emit progress updates with values between 0.0 and 1.0.
**Validates: Requirements 4.5**

**Property 28: Upload Success Handling**
*For any* successfully uploaded file, the message should be updated with the file URL and metadata.
**Validates: Requirements 4.6**

**Property 29: Upload Failure Queueing**
*For any* failed file upload, the operation should be added to the AttachmentQueueService for retry.
**Validates: Requirements 4.7**

**Property 30: Offline Upload Queueing**
*For any* file upload performed while offline, the operation should be queued and processed when connectivity is restored.
**Validates: Requirements 4.8**

### Message Search Properties

**Property 31: Search Query Execution**
*For any* non-empty search query, the system should call the `chatSearch` GraphQL query with the correct parameters.
**Validates: Requirements 5.1**

**Property 32: Search Result Grouping**
*For any* search results, they should be grouped by conversationId with all messages from the same conversation together.
**Validates: Requirements 5.2**

**Property 33: Search Text Highlighting**
*For any* search result, the matched text should be identified with highlight positions (start, end).
**Validates: Requirements 5.3**

**Property 34: Conversation Filter**
*For any* search with conversation filter, all results should have conversationId matching one of the filtered conversation IDs.
**Validates: Requirements 5.5**

**Property 35: Sender Filter**
*For any* search with sender filter, all results should have senderId matching one of the filtered sender IDs.
**Validates: Requirements 5.6**

**Property 36: Message Type Filter**
*For any* search with message type filter, all results should have type matching one of the filtered types.
**Validates: Requirements 5.7**

**Property 37: Date Range Filter**
*For any* search with date range filter, all results should have createdAt within the specified range.
**Validates: Requirements 5.8**

**Property 38: Full-text Search**
*For any* text present in a message, searching for that text should return the message in the results.
**Validates: Requirements 5.9**

**Property 39: Search Result Limiting**
*For any* search query, the number of results returned should not exceed 50.
**Validates: Requirements 5.11**

### Reply and Forward Properties

**Property 40: Reply Mutation Correctness**
*For any* reply message, the system should call the `chatMessageAdd` mutation with the replyMessageId field set to the original message ID.
**Validates: Requirements 6.2**

**Property 41: Reply Linking**
*For any* successfully sent reply, querying the local database should return the reply message linked to the original message via replyMessageId.
**Validates: Requirements 6.3**

**Property 42: Reply Context Display**
*For any* message with a non-null replyMessageId, the rendered output should include the original message context.
**Validates: Requirements 6.4**

**Property 43: Forward Mutation Correctness**
*For any* forwarded message, the system should call the `chatMessageAdd` mutation with the forwardedFromMessageId field set to the original message ID.
**Validates: Requirements 6.7**

**Property 44: Forward Content Preservation**
*For any* forwarded message, the content, type, urls, and fileName should match the original message.
**Validates: Requirements 6.8**

**Property 45: Forward Indicator Display**
*For any* message with a non-null forwardedFromMessageId, the rendered output should include a "Forwarded" indicator.
**Validates: Requirements 6.9**

**Property 46: Multi-conversation Forward**
*For any* forward operation with N target conversations, the system should successfully send the message to all N conversations.
**Validates: Requirements 6.10**

**Property 47: Forward with Attachments**
*For any* message with non-null urls or fileName, forwarding should preserve these fields in the forwarded message.
**Validates: Requirements 6.11**

**Property 48: Offline Reply/Forward Queueing**
*For any* reply or forward operation performed while offline, the operation should be added to the offline queue and processed when connectivity is restored.
**Validates: Requirements 6.12**


## Error Handling

### Error Types

All errors follow the `Either<Failure, T>` pattern established in Phase 1:

**ValidationFailure:**
- File size exceeds limits
- Invalid file type
- Message age > 48 hours for edit
- User doesn't own message
- Empty search query
- Invalid emoji code

**NetworkFailure:**
- No internet connection
- Connection timeout
- WebSocket disconnected

**ServerFailure:**
- GraphQL mutation errors
- Backend validation errors
- File upload errors
- Search query errors

**CacheFailure:**
- Isar database errors
- Failed to save/update local data
- Failed to cache search results

**UnexpectedFailure:**
- Unhandled exceptions
- Parsing errors
- Unknown errors

### Error Handling Patterns

**UseCase Level:**
```dart
Future<Either<Failure, T>> call(...) async {
  try {
    // Validate inputs
    final validation = _validate(...);
    if (validation != null) {
      return Left(validation);
    }
    
    // Call repository
    return await _repository.operation(...);
  } catch (e) {
    logger.e('UseCase error', error: e);
    return Left(UnexpectedFailure(message: '$e'));
  }
}
```

**Repository Level:**
```dart
Future<Either<Failure, T>> operation(...) async {
  try {
    if (await _networkInfo.isConnected) {
      // Online path
      final result = await _remoteDataSource.operation(...);
      await _localDataSource.cache(result);
      return Right(result.toEntity());
    } else {
      // Offline path
      await _offlineQueue.enqueue(...);
      final result = await _localDataSource.operation(...);
      return Right(result.toEntity());
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(message: e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message));
  } catch (e) {
    logger.e('Repository error', error: e);
    return Left(UnexpectedFailure(message: '$e'));
  }
}
```

**BLoC Level:**
```dart
Future<void> _onEvent(Event event, Emitter<State> emit) async {
  emit(State.loading(operation: 'operation_name'));
  
  try {
    final result = await _useCase(...);
    
    result.fold(
      (failure) {
        logger.e('Operation failed', error: failure);
        emit(State.error(
          failure: failure,
          operation: 'operation_name',
          retryAction: () => add(event),
        ));
      },
      (data) {
        logger.i('Operation succeeded');
        emit(State.success(data: data));
      },
    );
  } catch (e, stackTrace) {
    logger.e('Unexpected BLoC error', error: e, stackTrace: stackTrace);
    emit(State.error(
      failure: UnexpectedFailure(message: '$e'),
      operation: 'operation_name',
      retryAction: () => add(event),
    ));
  }
}
```

**UI Level:**
```dart
BlocListener<ChatBloc, ChatState>(
  listener: (context, state) {
    state.whenOrNull(
      error: (failure, operation, retry) {
        final message = _getLocalizedErrorMessage(context, failure);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: retry != null
                ? SnackBarAction(
                    label: context.l10n.retry,
                    onPressed: retry,
                  )
                : null,
          ),
        );
      },
    );
  },
  child: ...,
)

String _getLocalizedErrorMessage(BuildContext context, Failure failure) {
  if (failure is NetworkFailure) {
    return context.l10n.errorNoInternet;
  } else if (failure is ServerFailure) {
    return context.l10n.errorServer;
  } else if (failure is ValidationFailure) {
    return failure.message; // Already user-friendly
  } else if (failure is CacheFailure) {
    return context.l10n.errorCache;
  } else {
    return context.l10n.errorUnexpected;
  }
}
```

### Retry Strategies

**Immediate Retry:**
- User-initiated retry via UI button
- Used for: reactions, edits, deletes, search

**Exponential Backoff:**
- Automatic retry for offline queue operations
- Used for: file uploads, queued mutations
- Backoff: 1s, 2s, 4s, 8s, 16s, max 32s
- Max retries: 5 attempts

**No Retry:**
- Validation errors (user must fix input)
- Authorization errors (user lacks permission)

## Testing Strategy

### Dual Testing Approach

**Unit Tests:**
- Test specific examples and edge cases
- Test error conditions
- Test validation logic
- Mock external dependencies
- Fast execution (<1s per test)

**Property-Based Tests:**
- Test universal properties across all inputs
- Generate random test data
- Verify correctness properties
- Run minimum 100 iterations per property
- Tag with property reference

**Integration Tests:**
- Test end-to-end flows
- Test offline-to-online sync
- Test real-time event handling
- Test file upload pipeline
- Use real Isar database (in-memory)

### Test Coverage Goals

- **Overall Coverage:** >70%
- **UseCases:** 100% (critical business logic)
- **Repositories:** >80% (data layer)
- **BLoCs:** >80% (state management)
- **Widgets:** >60% (UI components)

### Property-Based Test Configuration

**Library:** Use `test` package with custom property test helpers

**Configuration:**
```dart
// Property test helper
Future<void> propertyTest<T>({
  required String description,
  required T Function() generator,
  required Future<bool> Function(T) property,
  int iterations = 100,
  String? featureName,
  int? propertyNumber,
}) async {
  test(description, () async {
    for (int i = 0; i < iterations; i++) {
      final input = generator();
      final result = await property(input);
      expect(result, isTrue, reason: 'Property failed for input: $input');
    }
  });
}
```

**Tag Format:**
```dart
// Feature: chat-core-features, Property 1: Reaction Mutation Correctness
propertyTest<ReactionTestData>(
  description: 'Property 1: Reaction Mutation Correctness',
  generator: () => generateRandomReactionData(),
  property: (data) async {
    // Test property
    return true;
  },
  iterations: 100,
  featureName: 'chat-core-features',
  propertyNumber: 1,
);
```

### Test Organization

```
test/
├── unit/
│   ├── usecases/
│   │   ├── add_reaction_usecase_test.dart
│   │   ├── edit_message_usecase_test.dart
│   │   ├── delete_message_usecase_test.dart
│   │   ├── upload_file_usecase_test.dart
│   │   ├── search_messages_usecase_test.dart
│   │   ├── reply_to_message_usecase_test.dart
│   │   └── forward_message_usecase_test.dart
│   ├── repositories/
│   │   ├── message_repository_impl_test.dart
│   │   ├── search_repository_impl_test.dart
│   │   └── media_repository_impl_test.dart
│   └── blocs/
│       ├── chat_bloc_test.dart
│       └── search_bloc_test.dart
├── property/
│   ├── reaction_properties_test.dart
│   ├── edit_properties_test.dart
│   ├── delete_properties_test.dart
│   ├── upload_properties_test.dart
│   ├── search_properties_test.dart
│   └── reply_forward_properties_test.dart
├── integration/
│   ├── reaction_flow_test.dart
│   ├── edit_flow_test.dart
│   ├── delete_flow_test.dart
│   ├── upload_flow_test.dart
│   ├── search_flow_test.dart
│   └── reply_forward_flow_test.dart
└── widget/
    ├── reaction_picker_test.dart
    ├── message_reaction_display_test.dart
    └── search_result_item_test.dart
```

### Example Property Test

```dart
// test/property/reaction_properties_test.dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Reaction Properties', () {
    // Feature: chat-core-features, Property 1: Reaction Mutation Correctness
    propertyTest<ReactionTestData>(
      description: 'Property 1: For any message and emoji, adding reaction calls mutation correctly',
      generator: () => ReactionTestData(
        messageId: generateRandomId(),
        emojiCode: generateRandomEmoji(),
      ),
      property: (data) async {
        // Arrange
        final mockRepo = MockMessageRepository();
        final useCase = AddReactionUseCase(repository: mockRepo);
        
        when(mockRepo.addReaction(
          messageId: data.messageId,
          emojiCode: data.emojiCode,
        )).thenAnswer((_) async => Right(mockMessage));
        
        // Act
        await useCase(
          messageId: data.messageId,
          emojiCode: data.emojiCode,
        );
        
        // Assert
        verify(mockRepo.addReaction(
          messageId: data.messageId,
          emojiCode: data.emojiCode,
        )).called(1);
        
        return true;
      },
      iterations: 100,
      featureName: 'chat-core-features',
      propertyNumber: 1,
    );
    
    // Feature: chat-core-features, Property 2: Reaction Persistence
    propertyTest<ReactionTestData>(
      description: 'Property 2: For any reaction added, database contains that reaction',
      generator: () => ReactionTestData(
        messageId: generateRandomId(),
        emojiCode: generateRandomEmoji(),
      ),
      property: (data) async {
        // Arrange
        final isar = await openTestIsar();
        final localDataSource = MessageLocalDataSourceImpl(isar: isar);
        
        // Act
        await localDataSource.addReaction(
          messageId: data.messageId,
          emojiCode: data.emojiCode,
          userId: 'test-user',
        );
        
        // Assert
        final message = await localDataSource.getMessageById(data.messageId);
        final hasReaction = message.reactions.any(
          (r) => r.code == data.emojiCode && r.userId == 'test-user',
        );
        
        await isar.close();
        return hasReaction;
      },
      iterations: 100,
      featureName: 'chat-core-features',
      propertyNumber: 2,
    );
  });
}
```

### Performance Testing

**Benchmarks:**
- Reaction operations: <100ms
- Edit operations: <100ms
- Delete operations: <100ms
- Search operations: <500ms
- File upload (1MB): <500ms
- UI rendering: 60fps (16.67ms per frame)

**Load Testing:**
- 1000 messages with reactions
- 100 concurrent file uploads
- 50 search queries per second
- Memory usage <150MB

### Localization Testing

**Test Coverage:**
- All error messages in English and Vietnamese
- All UI strings in English and Vietnamese
- Date/time formatting for both locales
- File size formatting for both locales

**Test Approach:**
```dart
testWidgets('Error message displays in Vietnamese', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ErrorWidget(failure: NetworkFailure()),
    ),
  );
  
  expect(find.text('Không có kết nối internet'), findsOneWidget);
});
```

## Performance Optimizations

### Database Optimizations

**Indexes:**
```dart
@Index()
late String messageId;

@Index()
late String conversationId;

@Index()
late String searchQuery; // For search cache
```

**Query Optimization:**
- Use `.where()` with indexed fields
- Limit query results with `.limit()`
- Use `.findFirst()` for single results
- Batch operations with `.writeTxn()`

### UI Optimizations

**Widget Optimization:**
- Use `const` constructors everywhere possible
- Implement `shouldRebuild` in custom widgets
- Use `ListView.builder` for long lists
- Cache expensive computations

**Image Optimization:**
- Use `CachedNetworkImage` for remote images
- Generate thumbnails for large images
- Compress images before upload
- Use appropriate image formats (WebP)

**State Management Optimization:**
- Use `BlocSelector` for granular rebuilds
- Implement `buildWhen` in `BlocBuilder`
- Debounce search input (300ms)
- Throttle scroll events

### Network Optimizations

**GraphQL:**
- Batch mutations when possible
- Use query fragments for reusable fields
- Implement query caching
- Use persisted queries for production

**Socket.IO:**
- Reuse existing connection from Phase 1
- Implement event batching for high-frequency events
- Use binary protocol for file uploads
- Implement reconnection with exponential backoff

### Memory Optimizations

**File Handling:**
- Stream large files instead of loading into memory
- Dispose of file handles after use
- Clear thumbnail cache periodically
- Limit attachment queue size

**Cache Management:**
- Implement LRU cache for search results
- Clear old search cache (>7 days)
- Limit message cache size (last 1000 messages per conversation)
- Compress cached data when possible

## Security Considerations

### Input Validation

- Sanitize all user inputs
- Validate file types and sizes
- Validate emoji codes (prevent injection)
- Validate search queries (prevent SQL injection in backend)

### Authorization

- Verify message ownership before edit/delete
- Check user permissions for group operations
- Validate file upload permissions
- Implement rate limiting for operations

### Data Protection

- Encrypt sensitive data in Isar
- Use HTTPS for all network requests
- Use WSS for Socket.IO connections
- Implement token refresh for expired sessions

### Privacy

- Respect delete for everyone operations
- Don't cache deleted message content
- Clear search history on logout
- Implement data retention policies

## Deployment Considerations

### Feature Flags

```dart
class FeatureFlags {
  static const bool enableReactions = true;
  static const bool enableMessageEdit = true;
  static const bool enableMessageDelete = true;
  static const bool enableFileUpload = true;
  static const bool enableSearch = true;
  static const bool enableReplyForward = true;
}
```

### Rollout Strategy

**Phase 2.1 (Week 3):**
- Deploy reactions, edit, delete
- Monitor performance and errors
- Gather user feedback

**Phase 2.2 (Week 4):**
- Deploy file upload, search, reply/forward
- Monitor performance and errors
- Gather user feedback

### Monitoring

**Metrics to Track:**
- Operation success/failure rates
- Average operation latency
- Offline queue size
- File upload success rate
- Search query performance
- Memory usage
- Crash rate

**Logging:**
- Log all errors with context
- Log performance metrics
- Log offline queue operations
- Log file upload progress
- Use structured logging

### Rollback Plan

**If Critical Issues:**
1. Disable feature via feature flag
2. Roll back to Phase 1 version
3. Investigate and fix issues
4. Re-deploy with fixes

**Rollback Triggers:**
- Crash rate >1%
- Operation failure rate >10%
- Performance degradation >50%
- Data corruption detected

