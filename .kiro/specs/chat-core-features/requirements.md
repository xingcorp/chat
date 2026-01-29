# Requirements Document: Chat Core Features

## Introduction

This document specifies the requirements for Phase 2 of the Sharitek Office Chat application, focusing on essential user-facing chat features that provide competitive parity with modern messaging apps (WhatsApp, Telegram baseline). This phase builds upon the foundation established in Phase 1 (chat-foundation) and implements six core features: message reactions, message editing, message deletion, file uploads, message search, and reply/forward functionality.

The implementation follows Clean Architecture principles with strict layer separation, leverages existing infrastructure services, and maintains offline-first capabilities with real-time synchronization.

## Glossary

- **Chat_System**: The Sharitek Office Chat application (Flutter frontend)
- **Backend**: The NestJS GraphQL API server with Socket.IO support
- **Message**: A chat message entity with text, attachments, metadata, and relationships
- **Reaction**: An emoji response to a message with associated user information
- **Conversation**: A chat thread between users (direct or group)
- **Offline_Queue**: Local queue for operations performed while offline
- **Real_Time_Service**: Socket.IO-based service for real-time event handling
- **UseCase**: Domain layer business logic component
- **Repository**: Data layer abstraction for data access
- **BLoC**: Business Logic Component for state management
- **Isar**: Local NoSQL database for offline storage
- **GraphQL**: Query language for API communication
- **Socket.IO**: Real-time bidirectional event-based communication
- **Media_Processing_Service**: Service for file compression and thumbnail generation
- **Attachment_Queue_Service**: Service for managing file upload queue
- **Resource_Manager_Service**: Service for media caching and resource management

## Requirements

### Requirement 1: Message Reactions

**User Story:** As a user, I want to add emoji reactions to messages, so that I can express quick responses without sending a new message.

#### Acceptance Criteria

1. WHEN a user selects an emoji for a message, THE Chat_System SHALL send the reaction to the Backend via `chatMessageUpdateReaction` mutation
2. WHEN a reaction is added successfully, THE Chat_System SHALL update the local Isar database immediately
3. WHEN the Backend broadcasts a `message:reaction` event, THE Chat_System SHALL update the message reactions in real-time
4. WHEN a user views a message with reactions, THE Chat_System SHALL display all unique emoji reactions with their counts
5. WHEN a user taps on a reaction count, THE Chat_System SHALL display a list of users who reacted with that emoji
6. WHEN a user removes their reaction, THE Chat_System SHALL send the removal to the Backend and update locally
7. WHEN the Chat_System is offline, THE Chat_System SHALL queue the reaction operation and sync when connectivity is restored
8. WHEN multiple users react simultaneously, THE Chat_System SHALL handle concurrent reactions without data loss
9. THE Chat_System SHALL support at least 50 different emoji reactions per message
10. THE Chat_System SHALL complete reaction operations within 100ms for optimal user experience

### Requirement 2: Message Editing

**User Story:** As a user, I want to edit my sent messages, so that I can correct mistakes or update information.

#### Acceptance Criteria

1. WHEN a user edits their own message, THE Chat_System SHALL send the edit to the Backend via `chatMessageEdit` mutation
2. WHEN a message is edited successfully, THE Chat_System SHALL update the local Isar database with the new content and edit timestamp
3. WHEN the Backend broadcasts a `message:edit` event, THE Chat_System SHALL update the message content in real-time
4. WHEN a user views an edited message, THE Chat_System SHALL display an "edited" indicator with the edit timestamp
5. WHEN a user attempts to edit a message older than 48 hours, THE Chat_System SHALL prevent the edit and display an error message
6. WHEN a user attempts to edit another user's message, THE Chat_System SHALL prevent the edit and display an error message
7. WHEN the Chat_System is offline, THE Chat_System SHALL queue the edit operation and sync when connectivity is restored
8. THE Chat_System SHALL preserve the original message ID when editing
9. THE Chat_System SHALL maintain message ordering after edits
10. THE Chat_System SHALL complete edit operations within 100ms for optimal user experience

### Requirement 3: Message Deletion

**User Story:** As a user, I want to delete messages, so that I can remove unwanted or incorrect content from conversations.

#### Acceptance Criteria

1. WHEN a user deletes a message for themselves, THE Chat_System SHALL send the delete request to the Backend via `chatMessageEdit` mutation with DELETE action
2. WHEN a user deletes a message for everyone, THE Chat_System SHALL send the delete request to the Backend and mark the message as deleted for all participants
3. WHEN a message is deleted successfully, THE Chat_System SHALL update the local Isar database with the deletion timestamp
4. WHEN the Backend broadcasts a `message:delete` event, THE Chat_System SHALL update the message status in real-time
5. WHEN a user views a deleted message, THE Chat_System SHALL display a "Message deleted" placeholder instead of the original content
6. WHEN a user attempts to delete another user's message without permission, THE Chat_System SHALL prevent the deletion and display an error message
7. WHEN the Chat_System is offline, THE Chat_System SHALL queue the delete operation and sync when connectivity is restored
8. THE Chat_System SHALL preserve the message ID and metadata after soft deletion
9. THE Chat_System SHALL maintain conversation continuity after message deletion
10. THE Chat_System SHALL complete delete operations within 100ms for optimal user experience

### Requirement 4: File Upload

**User Story:** As a user, I want to upload files (images, videos, documents, audio) in messages, so that I can share rich content with other users.

#### Acceptance Criteria

1. WHEN a user selects a file to upload, THE Chat_System SHALL validate the file type and size before processing
2. WHEN a file is valid, THE Chat_System SHALL compress images and videos using Media_Processing_Service
3. WHEN a file is an image or video, THE Chat_System SHALL generate a thumbnail using Media_Processing_Service
4. WHEN a file is ready for upload, THE Chat_System SHALL send it to the Backend via Socket.IO `message:file:upload` event
5. WHEN a file is uploading, THE Chat_System SHALL display real-time progress percentage to the user
6. WHEN a file upload completes successfully, THE Chat_System SHALL update the message with the file URL and metadata
7. WHEN a file upload fails, THE Chat_System SHALL add the operation to Attachment_Queue_Service for retry
8. WHEN the Chat_System is offline, THE Chat_System SHALL queue the file upload and process when connectivity is restored
9. THE Chat_System SHALL support image files (JPEG, PNG, GIF, WebP) up to 10MB
10. THE Chat_System SHALL support video files (MP4, MOV, AVI) up to 50MB
11. THE Chat_System SHALL support document files (PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX) up to 20MB
12. THE Chat_System SHALL support audio files (MP3, WAV, AAC, M4A) up to 10MB
13. WHEN a file exceeds size limits, THE Chat_System SHALL display an error message and prevent upload
14. THE Chat_System SHALL use streaming upload for memory efficiency
15. THE Chat_System SHALL complete file upload operations within 500ms for files under 1MB

### Requirement 5: Message Search

**User Story:** As a user, I want to search for messages across conversations, so that I can quickly find specific information or past discussions.

#### Acceptance Criteria

1. WHEN a user enters a search query, THE Chat_System SHALL send the query to the Backend via `chatSearch` GraphQL query
2. WHEN search results are returned, THE Chat_System SHALL display them grouped by conversation
3. WHEN a user views search results, THE Chat_System SHALL highlight the matched text within each message
4. WHEN a user taps on a search result, THE Chat_System SHALL navigate to the conversation and scroll to the specific message
5. WHEN a user applies a conversation filter, THE Chat_System SHALL return results only from the selected conversation
6. WHEN a user applies a sender filter, THE Chat_System SHALL return results only from the selected sender
7. WHEN a user applies a message type filter, THE Chat_System SHALL return results matching the selected type (text, image, video, document, audio)
8. WHEN a user applies a date range filter, THE Chat_System SHALL return results within the specified date range
9. THE Chat_System SHALL support full-text search across message content
10. THE Chat_System SHALL return search results within 500ms for optimal user experience
11. THE Chat_System SHALL display a maximum of 50 results per search query
12. WHEN no results are found, THE Chat_System SHALL display a "No results found" message

### Requirement 6: Reply and Forward

**User Story:** As a user, I want to reply to specific messages and forward messages to other conversations, so that I can maintain context and share information efficiently.

#### Acceptance Criteria

1. WHEN a user selects "Reply" on a message, THE Chat_System SHALL display the original message context in the compose area
2. WHEN a user sends a reply, THE Chat_System SHALL include the `replyMessageId` field in the `chatMessageAdd` mutation
3. WHEN a reply message is sent successfully, THE Chat_System SHALL link it to the original message in the local Isar database
4. WHEN a user views a reply message, THE Chat_System SHALL display the original message context above the reply
5. WHEN a user taps on the reply context, THE Chat_System SHALL scroll to the original message in the conversation
6. WHEN a user selects "Forward" on a message, THE Chat_System SHALL display a conversation picker
7. WHEN a user selects target conversations for forwarding, THE Chat_System SHALL send the message to each conversation via `chatMessageAdd` mutation with `forwardedFromMessageId` field
8. WHEN a forwarded message is sent successfully, THE Chat_System SHALL preserve the original message content and metadata
9. WHEN a user views a forwarded message, THE Chat_System SHALL display a "Forwarded" indicator
10. THE Chat_System SHALL support forwarding messages to multiple conversations simultaneously
11. THE Chat_System SHALL support forwarding messages with attachments
12. WHEN the Chat_System is offline, THE Chat_System SHALL queue reply and forward operations and sync when connectivity is restored
13. THE Chat_System SHALL complete reply operations within 100ms for optimal user experience
14. THE Chat_System SHALL complete forward operations within 200ms per target conversation

### Requirement 7: Error Handling and Resilience

**User Story:** As a user, I want the chat system to handle errors gracefully, so that I have a reliable and predictable experience.

#### Acceptance Criteria

1. WHEN a network error occurs during any operation, THE Chat_System SHALL display a user-friendly error message
2. WHEN an operation fails, THE Chat_System SHALL provide a retry action to the user
3. WHEN the Backend returns a validation error, THE Chat_System SHALL display the specific validation message
4. WHEN the Backend returns a server error, THE Chat_System SHALL display a generic error message and log the details
5. WHEN the Chat_System is offline, THE Chat_System SHALL inform the user and queue operations automatically
6. WHEN connectivity is restored, THE Chat_System SHALL process queued operations in order
7. WHEN a queued operation fails after retry, THE Chat_System SHALL notify the user and provide manual retry option
8. THE Chat_System SHALL use `Either<Failure, T>` pattern for all error handling
9. THE Chat_System SHALL log all errors with appropriate severity levels
10. THE Chat_System SHALL never crash due to unhandled exceptions

### Requirement 8: Localization Support

**User Story:** As a user, I want the chat features to support multiple languages, so that I can use the application in my preferred language.

#### Acceptance Criteria

1. THE Chat_System SHALL support English localization for all user-facing strings
2. THE Chat_System SHALL support Vietnamese localization for all user-facing strings
3. WHEN a user changes the language setting, THE Chat_System SHALL update all UI text immediately
4. THE Chat_System SHALL use the `l10n` system for all user-facing strings
5. THE Chat_System SHALL never display hardcoded English strings in the UI
6. THE Chat_System SHALL format dates and times according to the selected locale
7. THE Chat_System SHALL format file sizes according to the selected locale

### Requirement 9: Performance and Resource Management

**User Story:** As a user, I want the chat features to perform smoothly, so that I have a responsive and efficient experience.

#### Acceptance Criteria

1. THE Chat_System SHALL maintain 60fps UI rendering during all chat operations
2. THE Chat_System SHALL complete reaction operations within 100ms
3. THE Chat_System SHALL complete edit operations within 100ms
4. THE Chat_System SHALL complete delete operations within 100ms
5. THE Chat_System SHALL complete search operations within 500ms
6. THE Chat_System SHALL use memory-efficient streaming for file uploads
7. THE Chat_System SHALL cache thumbnails using Resource_Manager_Service
8. THE Chat_System SHALL limit memory usage to under 150MB during normal operation
9. THE Chat_System SHALL dispose of resources properly to prevent memory leaks
10. THE Chat_System SHALL optimize database queries for fast message retrieval

### Requirement 10: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive test coverage, so that I can ensure the reliability and correctness of the chat features.

#### Acceptance Criteria

1. THE Chat_System SHALL have unit tests for all UseCases with >70% coverage
2. THE Chat_System SHALL have property-based tests for critical operations
3. THE Chat_System SHALL have integration tests for end-to-end flows
4. THE Chat_System SHALL have widget tests for UI components
5. THE Chat_System SHALL pass all tests before deployment
6. THE Chat_System SHALL use mock objects for external dependencies in unit tests
7. THE Chat_System SHALL test offline scenarios with queued operations
8. THE Chat_System SHALL test real-time event handling with simulated Socket.IO events
9. THE Chat_System SHALL test error handling with simulated failures
10. THE Chat_System SHALL test concurrent operations with race condition scenarios
