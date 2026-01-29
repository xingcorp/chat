# Implementation Plan: Chat Core Features

## Overview

This implementation plan covers Phase 2 of the Sharitek Office Chat application, implementing six essential user-facing features: message reactions, message editing, message deletion, file uploads, message search, and reply/forward functionality. The implementation builds upon the foundation established in Phase 1 and leverages existing infrastructure services.

**Timeline:** 2 weeks (Week 3-4)
- Week 3: Message Reactions, Edit, Delete
- Week 4: File Upload, Search, Reply/Forward

**Key Principles:**
- **Extend Base Classes**: All BLoCs extend `BaseBloc`, all states extend `BaseState`, all widgets extend `BaseStatefulWidget` or `BaseStatelessWidget`
- **Use AppConstants**: All UI dimensions, durations, and limits from `AppConstants`
- **Use Logger**: All logging via `Logger` (never `print()` or `debugPrint()`)
- **Use Localization**: All user-facing strings via `context.l10n`
- **Use DI**: All components use `@injectable` annotations
- **Reuse Existing Widgets**: Use `ErrorDisplayWidget`, `ConnectionStatusWidget`, etc.
- Extend existing components rather than create new ones
- Reuse Phase 1 infrastructure (OfflineQueueService, RealtimeService, etc.)
- Maintain Clean Architecture with strict layer separation
- Implement offline-first with real-time sync
- Comprehensive testing with property-based tests

## Tasks

### Phase 1: Message Reactions (Week 3, Days 1-2)

- [ ] 1. Implement Message Reactions Domain Layer
  - [ ] 1.1 Create AddReactionUseCase
    - Implement UseCase with messageId and emojiCode parameters
    - Call IMessageRepository.addReaction()
    - Handle Either<Failure, ChatMessage> return type
    - _Requirements: 1.1, 1.2_
  
  - [ ] 1.2 Write property test for AddReactionUseCase
    - **Property 1: Reaction Mutation Correctness**
    - **Validates: Requirements 1.1**
    - Generate random messageId and emojiCode
    - Verify repository method called with correct parameters
    - Run 100 iterations
  
  - [ ] 1.3 Create RemoveReactionUseCase
    - Implement UseCase with messageId and emojiCode parameters
    - Call IMessageRepository.removeReaction()
    - Handle Either<Failure, ChatMessage> return type
    - _Requirements: 1.6_
  
  - [ ] 1.4 Write property test for RemoveReactionUseCase
    - **Property 5: Reaction Removal**
    - **Validates: Requirements 1.6**
    - Generate random messageId and emojiCode
    - Verify repository method called with act=REMOVE
    - Run 100 iterations

- [ ] 2. Extend Message Repository for Reactions
  - [ ] 2.1 Add reaction methods to IMessageRepository interface
    - Add addReaction() method signature
    - Add removeReaction() method signature
    - Add getMessageById() method signature
    - _Requirements: 1.1, 1.6_
  
  - [ ] 2.2 Implement reaction methods in MessageRepositoryImpl
    - Implement addReaction() with online/offline handling
    - Implement removeReaction() with online/offline handling
    - Use OfflineQueueService for offline operations
    - Update local cache optimistically
    - _Requirements: 1.1, 1.2, 1.6, 1.7_
  
  - [ ] 2.3 Write property test for reaction persistence
    - **Property 2: Reaction Persistence**
    - **Validates: Requirements 1.2**
    - Generate random reactions
    - Verify database contains added reactions
    - Run 100 iterations
  
  - [ ] 2.4 Write property test for offline reaction queueing
    - **Property 6: Offline Reaction Queueing**
    - **Validates: Requirements 1.7**
    - Simulate offline state
    - Verify operations queued correctly
    - Run 100 iterations
  
  - [ ] 2.5 Write unit tests for reaction repository methods
    - Test online path with mock remote data source
    - Test offline path with mock offline queue
    - Test error handling (ServerException, CacheException)
    - Test optimistic updates

- [ ] 3. Extend Message Data Sources for Reactions
  - [ ] 3.1 Add reaction methods to IMessageRemoteDataSource
    - Add addReaction() method with GraphQL mutation
    - Add removeReaction() method with GraphQL mutation
    - Use chatMessageUpdateReaction mutation
    - Parse response to MessageModel
    - _Requirements: 1.1, 1.6_
  
  - [ ] 3.2 Implement reaction methods in MessageRemoteDataSourceImpl
    - Implement GraphQL mutation for add reaction (act: ADD)
    - Implement GraphQL mutation for remove reaction (act: REMOVE)
    - Handle GraphQL errors
    - _Requirements: 1.1, 1.6_
  
  - [ ] 3.3 Add reaction methods to IMessageLocalDataSource
    - Add updateReaction() method for Isar
    - Query message by ID
    - Update reactions list
    - Save to Isar database
    - _Requirements: 1.2_
  
  - [ ] 3.4 Write unit tests for reaction data sources
    - Test GraphQL mutation calls
    - Test Isar database updates
    - Test error handling

- [ ] 4. Extend ChatBloc for Reactions
  - [ ] 4.1 Add reaction events to ChatEvent
    - Add ChatAddReactionEvent with messageId and emojiCode
    - Add ChatRemoveReactionEvent with messageId and emojiCode
    - Add ChatReactionReceivedEvent for real-time updates
    - Use @freezed for event classes
    - _Requirements: 1.1, 1.3, 1.6_
  
  - [ ] 4.2 Implement reaction event handlers in ChatBloc
    - Implement _onAddReaction handler
    - Implement _onRemoveReaction handler
    - Implement _onReactionReceived handler for real-time
    - Emit loading, success, and error states
    - _Requirements: 1.1, 1.3, 1.6_
  
  - [ ] 4.3 Write property test for real-time reaction updates
    - **Property 3: Real-time Reaction Updates**
    - **Validates: Requirements 1.3**
    - Generate random reaction events
    - Verify state updates correctly
    - Run 100 iterations
  
  - [ ] 4.4 Write unit tests for ChatBloc reaction handlers
    - Test add reaction success path
    - Test remove reaction success path
    - Test error handling
    - Test real-time event handling

- [ ] 5. Implement Reaction UI Components
  - [ ] 5.1 Create ReactionPicker widget
    - Display common emoji grid
    - Handle emoji selection
    - Use const constructor
    - Apply theme styling
    - _Requirements: 1.1_
  
  - [ ] 5.2 Create MessageReactionDisplay widget
    - Group reactions by emoji code
    - Display emoji with count
    - Handle tap to add/remove reaction
    - Handle long press to show users
    - Use const constructor where possible
    - _Requirements: 1.4, 1.5_
  
  - [ ] 5.3 Write property test for reaction display
    - **Property 4: Reaction Display Correctness**
    - **Validates: Requirements 1.4**
    - Generate random reaction lists
    - Verify all unique emojis displayed with correct counts
    - Run 100 iterations
  
  - [ ] 5.4 Write widget tests for reaction components
    - Test ReactionPicker displays emojis
    - Test MessageReactionDisplay groups correctly
    - Test tap and long press interactions

- [ ] 6. Integrate Reactions with Real-time Service
  - [ ] 6.1 Add message:reaction event handler to RealtimeService
    - Listen for message:reaction Socket.IO events
    - Parse event data (messageId, code, userId, act)
    - Emit to ChatBloc via event stream
    - _Requirements: 1.3_
  
  - [ ] 6.2 Update OfflineOperationType enum
    - Add REACTION_ADD type
    - Add REACTION_REMOVE type
    - _Requirements: 1.7_
  
  - [ ] 6.3 Write integration test for reaction flow
    - Test end-to-end reaction add flow
    - Test end-to-end reaction remove flow
    - Test offline queueing and sync
    - Test real-time event handling

- [ ] 7. Add Reaction Localization
  - [ ] 7.1 Add reaction strings to app_en.arb
    - Add "addReaction" string
    - Add "removeReaction" string
    - Add "reactedBy" string
    - _Requirements: 8.1_
  
  - [ ] 7.2 Add reaction strings to app_vi.arb
    - Add Vietnamese translations for all reaction strings
    - _Requirements: 8.2_
  
  - [ ] 7.3 Generate localization files
    - Run flutter gen-l10n
    - Verify generated files

- [ ] 8. Checkpoint - Reactions Complete
  - Ensure all reaction tests pass
  - Verify reactions work online and offline
  - Verify real-time updates work
  - Test with multiple users
  - Ask user if questions arise


### Phase 2: Message Editing (Week 3, Days 3-4)

- [ ] 9. Implement Message Edit Domain Layer
  - [ ] 9.1 Create EditMessageUseCase
    - Implement UseCase with messageId, newContent, currentUserId
    - Validate message age (<48 hours)
    - Validate message ownership
    - Call IMessageRepository.editMessage()
    - Return ValidationFailure for invalid edits
    - _Requirements: 2.1, 2.5, 2.6_
  
  - [ ] 9.2 Write property test for edit time validation
    - **Property 12: Edit Time Validation**
    - **Validates: Requirements 2.5**
    - Generate messages with various ages
    - Verify messages >48h rejected
    - Run 100 iterations
  
  - [ ] 9.3 Write property test for edit ownership validation
    - **Property 13: Edit Ownership Validation**
    - **Validates: Requirements 2.6**
    - Generate messages with different owners
    - Verify non-owned messages rejected
    - Run 100 iterations
  
  - [ ] 9.4 Write unit tests for EditMessageUseCase
    - Test successful edit
    - Test age validation
    - Test ownership validation
    - Test error handling

- [ ] 10. Extend Message Repository for Editing
  - [ ] 10.1 Add editMessage() to IMessageRepository interface
    - Add method signature with messageId and newContent
    - Return Either<Failure, ChatMessage>
    - _Requirements: 2.1_
  
  - [ ] 10.2 Implement editMessage() in MessageRepositoryImpl
    - Implement online path with remote data source
    - Implement offline path with queue
    - Update local cache with editAt timestamp
    - Handle errors appropriately
    - _Requirements: 2.1, 2.2, 2.7_
  
  - [ ] 10.3 Write property test for edit persistence
    - **Property 9: Edit Persistence**
    - **Validates: Requirements 2.2**
    - Generate random edits
    - Verify database contains new content and editAt
    - Run 100 iterations
  
  - [ ] 10.4 Write property test for edit invariants
    - **Property 15: Edit Invariants**
    - **Validates: Requirements 2.8, 2.9**
    - Generate random edits
    - Verify message ID and position unchanged
    - Run 100 iterations
  
  - [ ] 10.5 Write unit tests for edit repository methods
    - Test online edit path
    - Test offline edit path
    - Test error handling

- [ ] 11. Extend Message Data Sources for Editing
  - [ ] 11.1 Add editMessage() to IMessageRemoteDataSource
    - Add method with GraphQL mutation
    - Use chatMessageEdit mutation with act: EDIT
    - Parse response to MessageModel
    - _Requirements: 2.1_
  
  - [ ] 11.2 Implement editMessage() in MessageRemoteDataSourceImpl
    - Implement GraphQL mutation
    - Pass messageId, act: EDIT, message: newContent
    - Handle GraphQL errors
    - _Requirements: 2.1_
  
  - [ ] 11.3 Add updateMessage() to IMessageLocalDataSource
    - Query message by ID
    - Update message content
    - Set editAt timestamp
    - Save to Isar
    - _Requirements: 2.2_
  
  - [ ] 11.4 Write unit tests for edit data sources
    - Test GraphQL mutation calls
    - Test Isar database updates
    - Test error handling

- [ ] 12. Extend ChatBloc for Editing
  - [ ] 12.1 Add edit events to ChatEvent
    - Add ChatEditMessageEvent with messageId and newContent
    - Add ChatMessageEditedEvent for real-time updates
    - Use @freezed for event classes
    - _Requirements: 2.1, 2.3_
  
  - [ ] 12.2 Implement edit event handlers in ChatBloc
    - Implement _onEditMessage handler
    - Implement _onMessageEdited handler for real-time
    - Emit loading, success, and error states
    - _Requirements: 2.1, 2.3_
  
  - [ ] 12.3 Write property test for real-time edit updates
    - **Property 10: Real-time Edit Updates**
    - **Validates: Requirements 2.3**
    - Generate random edit events
    - Verify state updates correctly
    - Run 100 iterations
  
  - [ ] 12.4 Write unit tests for ChatBloc edit handlers
    - Test edit success path
    - Test validation errors
    - Test real-time event handling

- [ ] 13. Implement Edit UI Components
  - [ ] 13.1 Add edit mode to message bubble
    - Show edit icon for own messages
    - Handle edit icon tap
    - Show edit dialog/bottom sheet
    - Pre-fill with current content
    - _Requirements: 2.1_
  
  - [ ] 13.2 Add edited indicator to message display
    - Show "edited" text for edited messages
    - Display edit timestamp on long press
    - Use localized strings
    - _Requirements: 2.4_
  
  - [ ] 13.3 Write property test for edit indicator display
    - **Property 11: Edit Indicator Display**
    - **Validates: Requirements 2.4**
    - Generate messages with editAt timestamps
    - Verify indicator displayed
    - Run 100 iterations
  
  - [ ] 13.4 Write widget tests for edit UI
    - Test edit icon appears for own messages
    - Test edit dialog functionality
    - Test edited indicator display

- [ ] 14. Integrate Editing with Real-time Service
  - [ ] 14.1 Add message:edit event handler to RealtimeService
    - Listen for message:edit Socket.IO events
    - Parse event data (message object)
    - Emit to ChatBloc via event stream
    - _Requirements: 2.3_
  
  - [ ] 14.2 Update OfflineOperationType enum
    - Add MESSAGE_EDIT type
    - _Requirements: 2.7_
  
  - [ ] 14.3 Write integration test for edit flow
    - Test end-to-end edit flow
    - Test validation errors
    - Test offline queueing and sync
    - Test real-time event handling

- [ ] 15. Add Edit Localization
  - [ ] 15.1 Add edit strings to app_en.arb
    - Add "editMessage" string
    - Add "edited" string
    - Add "editTimeExpired" error string
    - Add "cannotEditOthersMessage" error string
    - _Requirements: 8.1_
  
  - [ ] 15.2 Add edit strings to app_vi.arb
    - Add Vietnamese translations for all edit strings
    - _Requirements: 8.2_
  
  - [ ] 15.3 Generate localization files
    - Run flutter gen-l10n
    - Verify generated files

- [ ] 16. Checkpoint - Editing Complete
  - Ensure all edit tests pass
  - Verify edits work online and offline
  - Verify validation works correctly
  - Verify real-time updates work
  - Ask user if questions arise

### Phase 3: Message Deletion (Week 3, Days 5-6)

- [ ] 17. Implement Message Delete Domain Layer
  - [ ] 17.1 Create DeleteMessageUseCase
    - Implement UseCase with messageId, currentUserId, deleteForEveryone
    - Validate message ownership for deleteForEveryone
    - Call IMessageRepository.deleteMessage()
    - Return ValidationFailure for invalid deletes
    - _Requirements: 3.1, 3.2, 3.6_
  
  - [ ] 17.2 Write property test for delete ownership validation
    - **Property 20: Delete Ownership Validation**
    - **Validates: Requirements 3.6**
    - Generate messages with different owners
    - Verify non-owned messages rejected for deleteForEveryone
    - Run 100 iterations
  
  - [ ] 17.3 Write unit tests for DeleteMessageUseCase
    - Test successful delete for self
    - Test successful delete for everyone
    - Test ownership validation
    - Test error handling

- [ ] 18. Extend Message Repository for Deletion
  - [ ] 18.1 Add deleteMessage() to IMessageRepository interface
    - Add method signature with messageId and deleteForEveryone
    - Return Either<Failure, ChatMessage>
    - _Requirements: 3.1, 3.2_
  
  - [ ] 18.2 Implement deleteMessage() in MessageRepositoryImpl
    - Implement online path with remote data source
    - Implement offline path with queue
    - Call softDeleteMessage() on local data source
    - Handle errors appropriately
    - _Requirements: 3.1, 3.2, 3.3, 3.7_
  
  - [ ] 18.3 Write property test for delete persistence
    - **Property 17: Delete Persistence**
    - **Validates: Requirements 3.3**
    - Generate random deletes
    - Verify database contains deletedAt timestamp
    - Run 100 iterations
  
  - [ ] 18.4 Write property test for delete invariants
    - **Property 22: Delete Invariants**
    - **Validates: Requirements 3.8, 3.9**
    - Generate random deletes
    - Verify message ID and metadata preserved
    - Run 100 iterations
  
  - [ ] 18.5 Write unit tests for delete repository methods
    - Test online delete path
    - Test offline delete path
    - Test error handling

- [ ] 19. Extend Message Data Sources for Deletion
  - [ ] 19.1 Add deleteMessage() to IMessageRemoteDataSource
    - Add method with GraphQL mutation
    - Use chatMessageEdit mutation with act: DELETE
    - Parse response to MessageModel
    - _Requirements: 3.1_
  
  - [ ] 19.2 Implement deleteMessage() in MessageRemoteDataSourceImpl
    - Implement GraphQL mutation
    - Pass messageId, act: DELETE
    - Handle GraphQL errors
    - _Requirements: 3.1_
  
  - [ ] 19.3 Add softDeleteMessage() to IMessageLocalDataSource
    - Query message by ID
    - Set deletedAt timestamp
    - Keep message ID and metadata
    - Save to Isar
    - _Requirements: 3.3, 3.8_
  
  - [ ] 19.4 Write unit tests for delete data sources
    - Test GraphQL mutation calls
    - Test Isar soft delete
    - Test error handling

- [ ] 20. Extend ChatBloc for Deletion
  - [ ] 20.1 Add delete events to ChatEvent
    - Add ChatDeleteMessageEvent with messageId and deleteForEveryone
    - Add ChatMessageDeletedEvent for real-time updates
    - Use @freezed for event classes
    - _Requirements: 3.1, 3.2, 3.4_
  
  - [ ] 20.2 Implement delete event handlers in ChatBloc
    - Implement _onDeleteMessage handler
    - Implement _onMessageDeleted handler for real-time
    - Emit loading, success, and error states
    - _Requirements: 3.1, 3.2, 3.4_
  
  - [ ] 20.3 Write property test for real-time delete updates
    - **Property 18: Real-time Delete Updates**
    - **Validates: Requirements 3.4**
    - Generate random delete events
    - Verify state updates correctly
    - Run 100 iterations
  
  - [ ] 20.4 Write unit tests for ChatBloc delete handlers
    - Test delete success path
    - Test validation errors
    - Test real-time event handling

- [ ] 21. Implement Delete UI Components
  - [ ] 21.1 Add delete option to message menu
    - Show delete icon for own messages
    - Show "Delete for me" option
    - Show "Delete for everyone" option (if owner)
    - Handle delete confirmation dialog
    - _Requirements: 3.1, 3.2_
  
  - [ ] 21.2 Add deleted message placeholder
    - Show "Message deleted" text for deleted messages
    - Hide original content
    - Keep message position in conversation
    - Use localized strings
    - _Requirements: 3.5, 3.9_
  
  - [ ] 21.3 Write property test for delete placeholder display
    - **Property 19: Delete Placeholder Display**
    - **Validates: Requirements 3.5**
    - Generate messages with deletedAt timestamps
    - Verify placeholder displayed
    - Run 100 iterations
  
  - [ ] 21.4 Write widget tests for delete UI
    - Test delete menu options
    - Test confirmation dialog
    - Test deleted placeholder display

- [ ] 22. Integrate Deletion with Real-time Service
  - [ ] 22.1 Add message:delete event handler to RealtimeService
    - Listen for message:delete Socket.IO events
    - Parse event data (message object)
    - Emit to ChatBloc via event stream
    - _Requirements: 3.4_
  
  - [ ] 22.2 Update OfflineOperationType enum
    - Add MESSAGE_DELETE type
    - _Requirements: 3.7_
  
  - [ ] 22.3 Write integration test for delete flow
    - Test end-to-end delete flow
    - Test delete for me vs everyone
    - Test offline queueing and sync
    - Test real-time event handling

- [ ] 23. Add Delete Localization
  - [ ] 23.1 Add delete strings to app_en.arb
    - Add "deleteMessage" string
    - Add "deleteForMe" string
    - Add "deleteForEveryone" string
    - Add "messageDeleted" string
    - Add "confirmDelete" string
    - Add "cannotDeleteOthersMessage" error string
    - _Requirements: 8.1_
  
  - [ ] 23.2 Add delete strings to app_vi.arb
    - Add Vietnamese translations for all delete strings
    - _Requirements: 8.2_
  
  - [ ] 23.3 Generate localization files
    - Run flutter gen-l10n
    - Verify generated files

- [ ] 24. Checkpoint - Deletion Complete
  - Ensure all delete tests pass
  - Verify deletes work online and offline
  - Verify validation works correctly
  - Verify real-time updates work
  - Test Week 3 features together
  - Ask user if questions arise


### Phase 4: File Upload (Week 4, Days 1-3)

- [ ] 25. Implement File Upload Domain Layer
  - [ ] 25.1 Create UploadFileUseCase
    - Implement UseCase with file, fileName, messageType, onProgress
    - Validate file type and size
    - Call IMediaRepository.uploadFile()
    - Return ValidationFailure for invalid files
    - _Requirements: 4.1, 4.9, 4.10, 4.11, 4.12, 4.13_
  
  - [ ] 25.2 Write property test for file validation
    - **Property 23: File Validation**
    - **Validates: Requirements 4.1, 4.13**
    - Generate files with various types and sizes
    - Verify invalid files rejected
    - Run 100 iterations
  
  - [ ] 25.3 Write unit tests for UploadFileUseCase
    - Test successful upload
    - Test file type validation
    - Test file size validation
    - Test error handling

- [ ] 26. Extend Media Repository for File Upload
  - [ ] 26.1 Add uploadFile() to IMediaRepository interface
    - Add method signature with file, fileName, messageType, onProgress
    - Return Either<Failure, String> (file URL)
    - _Requirements: 4.4_
  
  - [ ] 26.2 Implement uploadFile() in MediaRepositoryImpl
    - Process file with MediaProcessingService
    - Compress images/videos
    - Generate thumbnails for images/videos
    - Implement online path with Socket.IO upload
    - Implement offline path with AttachmentQueueService
    - Emit progress updates
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.7, 4.8_
  
  - [ ] 26.3 Write property test for compression
    - **Property 24: Image/Video Compression**
    - **Validates: Requirements 4.2**
    - Generate random image/video files
    - Verify compression applied
    - Run 100 iterations
  
  - [ ] 26.4 Write property test for thumbnail generation
    - **Property 25: Thumbnail Generation**
    - **Validates: Requirements 4.3**
    - Generate random image/video files
    - Verify thumbnail created
    - Run 100 iterations
  
  - [ ] 26.5 Write unit tests for upload repository methods
    - Test online upload path
    - Test offline upload path
    - Test progress callbacks
    - Test error handling

- [ ] 27. Extend Media Data Sources for File Upload
  - [ ] 27.1 Enhance MediaRemoteDataSource for Socket.IO upload
    - Implement streaming upload via message:file:upload event
    - Emit progress events during upload
    - Handle upload response with file URL
    - Handle upload errors
    - _Requirements: 4.4, 4.5_
  
  - [ ] 27.2 Add file caching to MediaLocalDataSource
    - Store uploaded files locally
    - Cache file metadata
    - Store pending uploads
    - _Requirements: 4.8_
  
  - [ ] 27.3 Write property test for upload via Socket.IO
    - **Property 26: File Upload via Socket.IO**
    - **Validates: Requirements 4.4**
    - Generate random files
    - Verify Socket.IO event emitted
    - Run 100 iterations
  
  - [ ] 27.4 Write unit tests for upload data sources
    - Test Socket.IO upload
    - Test progress tracking
    - Test error handling

- [ ] 28. Extend ChatBloc for File Upload
  - [ ] 28.1 Add upload events to ChatEvent
    - Add ChatUploadFileEvent with file, fileName, messageType
    - Use @freezed for event classes
    - _Requirements: 4.4_
  
  - [ ] 28.2 Extend ChatState for upload progress
    - Add FileUploadProgress class
    - Add uploadProgress field to ChatLoaded state
    - Track fileName, progress, status
    - _Requirements: 4.5_
  
  - [ ] 28.3 Implement upload event handler in ChatBloc
    - Implement _onUploadFile handler
    - Call UploadFileUseCase with progress callback
    - Emit progress states during upload
    - Send message with file URL on success
    - Emit error state on failure
    - _Requirements: 4.4, 4.5, 4.6, 4.7_
  
  - [ ] 28.4 Write property test for upload progress tracking
    - **Property 27: Upload Progress Tracking**
    - **Validates: Requirements 4.5**
    - Generate random upload scenarios
    - Verify progress values between 0.0 and 1.0
    - Run 100 iterations
  
  - [ ] 28.5 Write property test for upload success handling
    - **Property 28: Upload Success Handling**
    - **Validates: Requirements 4.6**
    - Generate random successful uploads
    - Verify message updated with file URL
    - Run 100 iterations
  
  - [ ] 28.6 Write unit tests for ChatBloc upload handlers
    - Test upload success path
    - Test upload failure path
    - Test progress updates
    - Test offline queueing

- [ ] 29. Implement File Upload UI Components
  - [ ] 29.1 Add file picker integration
    - Integrate file_picker package
    - Support image, video, document, audio selection
    - Show file type picker dialog
    - _Requirements: 4.1_
  
  - [ ] 29.2 Create upload progress indicator
    - Show circular progress during upload
    - Display percentage text
    - Show file name
    - Show cancel button
    - _Requirements: 4.5_
  
  - [ ] 29.3 Add file message display
    - Show thumbnail for images/videos
    - Show file icon for documents/audio
    - Show file name and size
    - Handle tap to open/download
    - _Requirements: 4.6_
  
  - [ ] 29.4 Write widget tests for upload UI
    - Test file picker dialog
    - Test progress indicator
    - Test file message display

- [ ] 30. Integrate File Upload with Services
  - [ ] 30.1 Enhance MediaProcessingService
    - Ensure compression works for all image formats
    - Ensure compression works for all video formats
    - Ensure thumbnail generation works
    - Add file size validation
    - _Requirements: 4.2, 4.3_
  
  - [ ] 30.2 Enhance AttachmentQueueService
    - Add file upload operations to queue
    - Implement retry logic with exponential backoff
    - Track upload status
    - _Requirements: 4.7, 4.8_
  
  - [ ] 30.3 Update OfflineOperationType enum
    - Add FILE_UPLOAD type
    - _Requirements: 4.8_
  
  - [ ] 30.4 Write property test for upload failure queueing
    - **Property 29: Upload Failure Queueing**
    - **Validates: Requirements 4.7**
    - Generate random upload failures
    - Verify operations queued for retry
    - Run 100 iterations
  
  - [ ] 30.5 Write property test for offline upload queueing
    - **Property 30: Offline Upload Queueing**
    - **Validates: Requirements 4.8**
    - Simulate offline state
    - Verify uploads queued correctly
    - Run 100 iterations
  
  - [ ] 30.6 Write integration test for file upload flow
    - Test end-to-end upload flow
    - Test compression and thumbnail generation
    - Test progress tracking
    - Test offline queueing and sync
    - Test error handling

- [ ] 31. Add File Upload Localization
  - [ ] 31.1 Add upload strings to app_en.arb
    - Add "selectFile" string
    - Add "uploadingFile" string
    - Add "uploadFailed" string
    - Add "fileTooLarge" error string
    - Add "invalidFileType" error string
    - _Requirements: 8.1_
  
  - [ ] 31.2 Add upload strings to app_vi.arb
    - Add Vietnamese translations for all upload strings
    - _Requirements: 8.2_
  
  - [ ] 31.3 Generate localization files
    - Run flutter gen-l10n
    - Verify generated files

- [ ] 32. Checkpoint - File Upload Complete
  - Ensure all upload tests pass
  - Verify uploads work online and offline
  - Verify compression and thumbnails work
  - Verify progress tracking works
  - Ask user if questions arise

### Phase 5: Message Search (Week 4, Days 4-5)

- [ ] 33. Implement Message Search Domain Layer
  - [ ] 33.1 Create SearchResult entity
    - Define SearchResult class with message, conversationId, conversationName, highlights
    - Define TextHighlight class with start, end, matchedText
    - Implement Equatable
    - _Requirements: 5.3_
  
  - [ ] 33.2 Create ISearchRepository interface
    - Define search() method with query and filters
    - Define clearSearchCache() method
    - Return Either<Failure, List<SearchResult>>
    - _Requirements: 5.1_
  
  - [ ] 33.3 Create SearchMessagesUseCase
    - Implement UseCase with query and filter parameters
    - Validate query is not empty
    - Call ISearchRepository.search()
    - Return ValidationFailure for empty query
    - _Requirements: 5.1, 5.5, 5.6, 5.7, 5.8_
  
  - [ ] 33.4 Write property test for search query execution
    - **Property 31: Search Query Execution**
    - **Validates: Requirements 5.1**
    - Generate random search queries
    - Verify GraphQL query called
    - Run 100 iterations
  
  - [ ] 33.5 Write unit tests for SearchMessagesUseCase
    - Test successful search
    - Test empty query validation
    - Test filter application
    - Test error handling

- [ ] 34. Implement Search Repository
  - [ ] 34.1 Create SearchRepositoryImpl
    - Implement search() method
    - Check network connectivity
    - Call remote data source if online
    - Call local data source if offline
    - Cache results locally
    - Group results by conversation
    - _Requirements: 5.1, 5.2_
  
  - [ ] 34.2 Write property test for search result grouping
    - **Property 32: Search Result Grouping**
    - **Validates: Requirements 5.2**
    - Generate random search results
    - Verify grouped by conversationId
    - Run 100 iterations
  
  - [ ] 34.3 Write property test for conversation filter
    - **Property 34: Conversation Filter**
    - **Validates: Requirements 5.5**
    - Generate random searches with conversation filter
    - Verify all results match filter
    - Run 100 iterations
  
  - [ ] 34.4 Write property test for sender filter
    - **Property 35: Sender Filter**
    - **Validates: Requirements 5.6**
    - Generate random searches with sender filter
    - Verify all results match filter
    - Run 100 iterations
  
  - [ ] 34.5 Write property test for message type filter
    - **Property 36: Message Type Filter**
    - **Validates: Requirements 5.7**
    - Generate random searches with type filter
    - Verify all results match filter
    - Run 100 iterations
  
  - [ ] 34.6 Write property test for date range filter
    - **Property 37: Date Range Filter**
    - **Validates: Requirements 5.8**
    - Generate random searches with date filter
    - Verify all results within range
    - Run 100 iterations
  
  - [ ] 34.7 Write property test for result limiting
    - **Property 39: Search Result Limiting**
    - **Validates: Requirements 5.11**
    - Generate searches with >50 results
    - Verify max 50 returned
    - Run 100 iterations
  
  - [ ] 34.8 Write unit tests for SearchRepositoryImpl
    - Test online search path
    - Test offline search path
    - Test result caching
    - Test error handling

- [ ] 35. Implement Search Data Sources
  - [ ] 35.1 Create ISearchRemoteDataSource interface
    - Define search() method with GraphQL query
    - Return List<SearchResultModel>
    - _Requirements: 5.1_
  
  - [ ] 35.2 Create SearchRemoteDataSourceImpl
    - Implement chatSearch GraphQL query
    - Pass query and filter parameters
    - Parse response to SearchResultModel list
    - Handle GraphQL errors
    - _Requirements: 5.1_
  
  - [ ] 35.3 Create ISearchLocalDataSource interface
    - Define cacheSearchResults() method
    - Define searchLocal() method
    - Define clearCache() method
    - _Requirements: 5.2_
  
  - [ ] 35.4 Create SearchLocalDataSourceImpl
    - Implement Isar-based search cache
    - Store search results with query key
    - Implement local full-text search
    - Implement cache expiration (7 days)
    - _Requirements: 5.2, 5.9_
  
  - [ ] 35.5 Create SearchResultModel
    - Define Isar collection for search results
    - Add fields: searchQuery, messageId, conversationId, conversationName
    - Add highlight positions (starts, ends)
    - Implement toEntity() and fromEntity() mappers
    - _Requirements: 5.2, 5.3_
  
  - [ ] 35.6 Write property test for full-text search
    - **Property 38: Full-text Search**
    - **Validates: Requirements 5.9**
    - Generate random messages with text
    - Verify search finds matching text
    - Run 100 iterations
  
  - [ ] 35.7 Write unit tests for search data sources
    - Test GraphQL query execution
    - Test Isar cache operations
    - Test local search
    - Test error handling

- [ ] 36. Implement Search BLoC
  - [ ] 36.1 Create SearchEvent classes
    - Create SearchQueryEvent with query and filters
    - Create SearchClearEvent
    - Create SearchApplyFilterEvent
    - Use @freezed for event classes
    - _Requirements: 5.1, 5.5, 5.6, 5.7, 5.8_
  
  - [ ] 36.2 Create SearchState classes
    - Create SearchInitial state
    - Create SearchLoading state
    - Create SearchLoaded state with results and groupedResults
    - Create SearchEmpty state
    - Create SearchError state
    - Use @freezed for state classes
    - _Requirements: 5.1, 5.2, 5.12_
  
  - [ ] 36.3 Create SearchBloc
    - Implement _onSearch handler
    - Implement _onClear handler
    - Implement _onApplyFilter handler
    - Group results by conversation
    - Emit appropriate states
    - _Requirements: 5.1, 5.2_
  
  - [ ] 36.4 Write unit tests for SearchBloc
    - Test search success path
    - Test empty results
    - Test filter application
    - Test error handling

- [ ] 37. Implement Search UI Components
  - [ ] 37.1 Create SearchPage
    - Add search bar with text input
    - Add filter chips (conversation, sender, type, date)
    - Show loading indicator during search
    - Show grouped results
    - Show empty state
    - _Requirements: 5.1, 5.2, 5.5, 5.6, 5.7, 5.8, 5.12_
  
  - [ ] 37.2 Create SearchResultItem widget
    - Display conversation name
    - Display sender name and avatar
    - Display message content with highlights
    - Display timestamp
    - Handle tap to navigate to message
    - _Requirements: 5.3, 5.4_
  
  - [ ] 37.3 Write property test for text highlighting
    - **Property 33: Search Text Highlighting**
    - **Validates: Requirements 5.3**
    - Generate random search results
    - Verify matched text highlighted
    - Run 100 iterations
  
  - [ ] 37.4 Write widget tests for search UI
    - Test search bar input
    - Test filter chips
    - Test result display
    - Test navigation on tap

- [ ] 38. Add Search Localization
  - [ ] 38.1 Add search strings to app_en.arb
    - Add "search" string
    - Add "searchMessages" string
    - Add "noResultsFound" string
    - Add "filterByConversation" string
    - Add "filterBySender" string
    - Add "filterByType" string
    - Add "filterByDate" string
    - _Requirements: 8.1_
  
  - [ ] 38.2 Add search strings to app_vi.arb
    - Add Vietnamese translations for all search strings
    - _Requirements: 8.2_
  
  - [ ] 38.3 Generate localization files
    - Run flutter gen-l10n
    - Verify generated files

- [ ] 39. Checkpoint - Search Complete
  - Ensure all search tests pass
  - Verify search works online and offline
  - Verify filters work correctly
  - Verify highlighting works
  - Ask user if questions arise


### Phase 6: Reply and Forward (Week 4, Day 6)

- [ ] 40. Implement Reply Domain Layer
  - [ ] 40.1 Create ReplyToMessageUseCase
    - Implement UseCase with conversationId, replyToMessageId, content, type
    - Call IMessageRepository.sendMessage() with replyToMessageId
    - Return Either<Failure, ChatMessage>
    - _Requirements: 6.2_
  
  - [ ] 40.2 Write property test for reply mutation correctness
    - **Property 40: Reply Mutation Correctness**
    - **Validates: Requirements 6.2**
    - Generate random reply messages
    - Verify replyMessageId included in mutation
    - Run 100 iterations
  
  - [ ] 40.3 Write unit tests for ReplyToMessageUseCase
    - Test successful reply
    - Test error handling

- [ ] 41. Implement Forward Domain Layer
  - [ ] 41.1 Create ForwardMessageUseCase
    - Implement UseCase with messageId and targetConversationIds
    - Load original message
    - Send to each target conversation with forwardedFromMessageId
    - Return Either<Failure, List<ChatMessage>>
    - _Requirements: 6.7, 6.10_
  
  - [ ] 41.2 Write property test for forward mutation correctness
    - **Property 43: Forward Mutation Correctness**
    - **Validates: Requirements 6.7**
    - Generate random forward messages
    - Verify forwardedFromMessageId included in mutation
    - Run 100 iterations
  
  - [ ] 41.3 Write property test for forward content preservation
    - **Property 44: Forward Content Preservation**
    - **Validates: Requirements 6.8**
    - Generate random messages to forward
    - Verify content, type, urls, fileName preserved
    - Run 100 iterations
  
  - [ ] 41.4 Write property test for multi-conversation forward
    - **Property 46: Multi-conversation Forward**
    - **Validates: Requirements 6.10**
    - Generate random target conversation lists
    - Verify message sent to all targets
    - Run 100 iterations
  
  - [ ] 41.5 Write property test for forward with attachments
    - **Property 47: Forward with Attachments**
    - **Validates: Requirements 6.11**
    - Generate messages with attachments
    - Verify attachments preserved in forward
    - Run 100 iterations
  
  - [ ] 41.6 Write unit tests for ForwardMessageUseCase
    - Test successful forward to single conversation
    - Test successful forward to multiple conversations
    - Test forward with attachments
    - Test error handling

- [ ] 42. Extend Message Repository for Reply/Forward
  - [ ] 42.1 Update sendMessage() in IMessageRepository
    - Add optional replyToMessageId parameter
    - Add optional forwardedFromMessageId parameter
    - _Requirements: 6.2, 6.7_
  
  - [ ] 42.2 Update sendMessage() in MessageRepositoryImpl
    - Pass replyToMessageId to remote data source
    - Pass forwardedFromMessageId to remote data source
    - Link reply/forward in local database
    - _Requirements: 6.2, 6.3, 6.7, 6.8_
  
  - [ ] 42.3 Write property test for reply linking
    - **Property 41: Reply Linking**
    - **Validates: Requirements 6.3**
    - Generate random replies
    - Verify database links reply to original
    - Run 100 iterations
  
  - [ ] 42.4 Write property test for offline reply/forward queueing
    - **Property 48: Offline Reply/Forward Queueing**
    - **Validates: Requirements 6.12**
    - Simulate offline state
    - Verify operations queued correctly
    - Run 100 iterations
  
  - [ ] 42.5 Write unit tests for reply/forward repository methods
    - Test online reply path
    - Test online forward path
    - Test offline queueing
    - Test error handling

- [ ] 43. Extend Message Data Sources for Reply/Forward
  - [ ] 43.1 Update sendMessage() in MessageRemoteDataSource
    - Add replyMessageId field to chatMessageAdd mutation
    - Add forwardedFromMessageId field to chatMessageAdd mutation
    - _Requirements: 6.2, 6.7_
  
  - [ ] 43.2 Update saveMessage() in MessageLocalDataSource
    - Store replyMessageId in Isar
    - Store forwardedFromMessageId in Isar
    - Create relationship links
    - _Requirements: 6.3, 6.8_
  
  - [ ] 43.3 Write unit tests for reply/forward data sources
    - Test GraphQL mutation with reply field
    - Test GraphQL mutation with forward field
    - Test Isar relationship storage

- [ ] 44. Extend ChatBloc for Reply/Forward
  - [ ] 44.1 Add reply/forward events to ChatEvent
    - Add ChatReplyToMessageEvent with messageId
    - Add ChatCancelReplyEvent
    - Add ChatForwardMessageEvent with messageId and targetConversationIds
    - Use @freezed for event classes
    - _Requirements: 6.1, 6.2, 6.6, 6.7_
  
  - [ ] 44.2 Extend ChatState for reply mode
    - Add replyingTo field to ChatLoaded state
    - Store original message for reply context
    - _Requirements: 6.1_
  
  - [ ] 44.3 Implement reply/forward event handlers in ChatBloc
    - Implement _onReplyToMessage handler
    - Implement _onCancelReply handler
    - Implement _onForwardMessage handler
    - Emit appropriate states
    - _Requirements: 6.1, 6.2, 6.7_
  
  - [ ] 44.4 Write unit tests for ChatBloc reply/forward handlers
    - Test reply mode activation
    - Test reply mode cancellation
    - Test forward to single conversation
    - Test forward to multiple conversations
    - Test error handling

- [ ] 45. Implement Reply/Forward UI Components
  - [ ] 45.1 Add reply UI to message bubble
    - Show reply icon in message menu
    - Handle reply icon tap
    - Show reply context in compose area
    - Show cancel reply button
    - _Requirements: 6.1_
  
  - [ ] 45.2 Add reply context display to messages
    - Show original message above reply
    - Display sender name and content preview
    - Handle tap to scroll to original
    - Use localized strings
    - _Requirements: 6.4, 6.5_
  
  - [ ] 45.3 Write property test for reply context display
    - **Property 42: Reply Context Display**
    - **Validates: Requirements 6.4**
    - Generate messages with replyMessageId
    - Verify original context displayed
    - Run 100 iterations
  
  - [ ] 45.4 Add forward UI to message menu
    - Show forward icon in message menu
    - Handle forward icon tap
    - Show conversation picker dialog
    - Support multi-select conversations
    - Show forward progress
    - _Requirements: 6.6, 6.10_
  
  - [ ] 45.5 Add forwarded indicator to messages
    - Show "Forwarded" label for forwarded messages
    - Use localized strings
    - _Requirements: 6.9_
  
  - [ ] 45.6 Write property test for forward indicator display
    - **Property 45: Forward Indicator Display**
    - **Validates: Requirements 6.9**
    - Generate messages with forwardedFromMessageId
    - Verify indicator displayed
    - Run 100 iterations
  
  - [ ] 45.7 Write widget tests for reply/forward UI
    - Test reply icon and context display
    - Test forward dialog
    - Test conversation picker
    - Test forwarded indicator

- [ ] 46. Update OfflineOperationType for Reply/Forward
  - [ ] 46.1 Add reply/forward types to enum
    - Add MESSAGE_REPLY type
    - Add MESSAGE_FORWARD type
    - _Requirements: 6.12_
  
  - [ ] 46.2 Write integration test for reply/forward flow
    - Test end-to-end reply flow
    - Test end-to-end forward flow
    - Test forward to multiple conversations
    - Test offline queueing and sync
    - Test navigation to original message

- [ ] 47. Add Reply/Forward Localization
  - [ ] 47.1 Add reply/forward strings to app_en.arb
    - Add "reply" string
    - Add "replyTo" string
    - Add "cancelReply" string
    - Add "forward" string
    - Add "forwardTo" string
    - Add "forwarded" string
    - Add "selectConversations" string
    - _Requirements: 8.1_
  
  - [ ] 47.2 Add reply/forward strings to app_vi.arb
    - Add Vietnamese translations for all reply/forward strings
    - _Requirements: 8.2_
  
  - [ ] 47.3 Generate localization files
    - Run flutter gen-l10n
    - Verify generated files

- [ ] 48. Checkpoint - Reply/Forward Complete
  - Ensure all reply/forward tests pass
  - Verify reply works online and offline
  - Verify forward works to single and multiple conversations
  - Verify context display and navigation work
  - Ask user if questions arise

### Phase 7: Final Integration and Testing (Week 4, Day 7)

- [ ] 49. Integration Testing
  - [ ] 49.1 Write comprehensive integration tests
    - Test all 6 features working together
    - Test feature interactions (e.g., forward message with reactions)
    - Test offline-to-online sync for all features
    - Test real-time updates for all features
    - Test error recovery scenarios
  
  - [ ] 49.2 Write performance tests
    - Test reaction operations <100ms
    - Test edit operations <100ms
    - Test delete operations <100ms
    - Test search operations <500ms
    - Test file upload (1MB) <500ms
    - Test UI rendering at 60fps
  
  - [ ] 49.3 Write memory tests
    - Test memory usage <150MB during normal operation
    - Test memory usage during file uploads
    - Test memory usage with large search results
    - Test for memory leaks

- [ ] 50. Code Quality and Documentation
  - [ ] 50.1 Run code analysis
    - Run flutter analyze
    - Fix all errors and warnings
    - Ensure no linting violations
  
  - [ ] 50.2 Verify test coverage
    - Run flutter test --coverage
    - Ensure overall coverage >70%
    - Ensure UseCase coverage 100%
    - Ensure Repository coverage >80%
    - Ensure BLoC coverage >80%
  
  - [ ] 50.3 Update documentation
    - Add inline code comments for complex logic
    - Update README if needed
    - Document any breaking changes
  
  - [ ] 50.4 Code review checklist
    - Verify Clean Architecture maintained
    - Verify no layer violations
    - Verify all errors use Either<Failure, T>
    - Verify all strings use localization
    - Verify no hardcoded values
    - Verify proper null safety
    - Verify resource disposal

- [ ] 51. User Acceptance Testing
  - [ ] 51.1 Manual testing checklist
    - Test reactions on various messages
    - Test editing recent and old messages
    - Test deleting messages for self and everyone
    - Test uploading various file types
    - Test search with different filters
    - Test reply and forward functionality
    - Test offline mode for all features
    - Test real-time updates with multiple devices
  
  - [ ] 51.2 Edge case testing
    - Test with poor network conditions
    - Test with large files
    - Test with many reactions on one message
    - Test with long search queries
    - Test with many forwarded conversations
    - Test concurrent operations
  
  - [ ] 51.3 Localization testing
    - Test all features in English
    - Test all features in Vietnamese
    - Verify all error messages localized
    - Verify date/time formatting correct

- [ ] 52. Final Checkpoint - Phase 2 Complete
  - All 6 features fully functional
  - All tests passing (unit, property, integration, widget)
  - Test coverage >70%
  - No high-priority bugs
  - Performance targets met
  - Memory usage within limits
  - Localization complete
  - Code quality verified
  - Ready for deployment

## Success Criteria

**Phase 2 Complete When:**
- [ ] All 52 tasks completed
- [ ] All property-based tests passing (48 properties)
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All widget tests passing
- [ ] Test coverage >70%
- [ ] No critical or high-priority bugs
- [ ] Performance benchmarks met:
  - Reaction operations <100ms
  - Edit operations <100ms
  - Delete operations <100ms
  - Search operations <500ms
  - File upload (1MB) <500ms
  - UI rendering at 60fps
- [ ] Memory usage <150MB
- [ ] All features work offline and sync when online
- [ ] All features work with real-time updates
- [ ] All user-facing strings localized (English + Vietnamese)
- [ ] Code analysis passes with no errors
- [ ] User acceptance testing completed
- [ ] Ready for Phase 3 deployment

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties (100 iterations each)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end flows
- Checkpoints ensure incremental validation
- All features build on Phase 1 infrastructure
- Maintain Clean Architecture throughout implementation
- Follow project coding standards and best practices
- Use existing patterns from Phase 1 for consistency

