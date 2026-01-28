# Task 14: Offline Queue Service - Implementation Plan

## Status: IN PROGRESS
**Started:** 2025-01-28
**Assignee:** Senior Flutter Architect

## Current State Analysis

### ✅ Already Implemented
1. **OfflineQueueService** - Core service exists at `lib/core/services/offline_queue_service.dart`
   - Queue management (add, get, process)
   - Status tracking (pending, processing, completed, failed)
   - Retry logic with exponential backoff
   - Network connectivity monitoring
   - Stream-based queue size updates

2. **OfflineOperationModel** - Isar model exists at `lib/data/models/offline_operation_model.dart`
   - Operation types enum
   - Status enum
   - JSON data storage
   - Retry count tracking

3. **IOfflineQueueService** - Interface exists at `lib/domain/services/i_offline_queue_service.dart`

### ❌ Missing Integration
1. **Repository Integration** - Repositories don't use offline queue for write operations
2. **Operation Processors** - No concrete implementation for processing queued operations
3. **Conflict Resolution** - No strategy for handling conflicts when syncing
4. **Error Recovery** - Limited error handling for failed operations

## Implementation Steps

### Step 1: Update MessageRepositoryImpl to Use Offline Queue ✅
**File:** `lib/data/repositories/message_repository_impl.dart`

**Changes:**
```dart
// Inject IOfflineQueueService
final IOfflineQueueService _offlineQueue;

// In sendMessage method:
if (!await networkInfo.isConnected) {
  // Queue operation
  await _offlineQueue.addOperation(
    OfflineOperationModel(
      type: OperationType.sendMessage,
      data: {
        'chatId': chatId,
        'content': content,
        'senderId': senderId,
        'contentType': contentType,
        'attachmentIds': attachmentIds,
        'localId': localId,
      },
      timestamp: DateTime.now(),
    ),
  );
  
  // Return local message with pending status
  return Right(localMessage.toDomain());
}
```

### Step 2: Update ChatRepositoryImpl to Use Offline Queue
**File:** `lib/data/repositories/chat_repository_impl.dart`

**Changes:**
```dart
// Inject IOfflineQueueService
final IOfflineQueueService _offlineQueue;

// In createChat method (for groups):
if (!await networkInfo.isConnected) {
  await _offlineQueue.addOperation(
    OfflineOperationModel(
      type: OperationType.createGroup,
      data: {
        'name': name,
        'participantIds': participantIds,
        'isGroup': isGroup,
      },
      timestamp: DateTime.now(),
    ),
  );
  
  // Return placeholder chat
  return Left(NetworkFailure(message: 'Operation queued'));
}
```

### Step 3: Implement Operation Processor Service
**New File:** `lib/core/services/offline_operation_processor.dart`

**Purpose:** Process queued operations by calling appropriate repositories

```dart
@Singleton()
class OfflineOperationProcessor {
  final IMessageRepository _messageRepository;
  final IChatRepository _chatRepository;
  final AppLogger _logger;
  
  Future<void> processOperation(OfflineOperationModel operation) async {
    switch (operation.type) {
      case OperationType.sendMessage:
        await _processSendMessage(operation);
        break;
      case OperationType.createGroup:
        await _processCreateGroup(operation);
        break;
      // ... other operations
    }
  }
  
  Future<void> _processSendMessage(OfflineOperationModel operation) async {
    final data = operation.dataMap;
    final result = await _messageRepository.sendMessage(
      chatId: data['chatId'],
      content: data['content'],
      senderId: data['senderId'],
      contentType: data['contentType'],
      attachmentIds: List<String>.from(data['attachmentIds'] ?? []),
    );
    
    result.fold(
      (failure) => throw Exception(failure.message),
      (message) => _logger.info('Message sent successfully'),
    );
  }
}
```

### Step 4: Update OfflineQueueService to Use Processor
**File:** `lib/core/services/offline_queue_service.dart`

**Changes:**
```dart
// Inject processor
final OfflineOperationProcessor _processor;

// Update _processOperation method:
Future<void> _processOperation(OfflineOperationModel operation) async {
  await _processor.processOperation(operation);
}
```

### Step 5: Add Conflict Resolution Strategy
**New File:** `lib/core/services/conflict_resolution_service.dart`

**Strategy:** Last-write-wins (simple and predictable)

```dart
@Singleton()
class ConflictResolutionService {
  Future<T> resolveConflict<T>({
    required T local,
    required T remote,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
  }) async {
    // Last-write-wins strategy
    return localTimestamp.isAfter(remoteTimestamp) ? local : remote;
  }
}
```

### Step 6: Update DI Registration
**File:** `lib/core/di/enterprise_injection.dart`

**Add:**
```dart
// Register OfflineOperationProcessor
@singleton
OfflineOperationProcessor get offlineOperationProcessor;

// Register ConflictResolutionService
@singleton
ConflictResolutionService get conflictResolutionService;
```

### Step 7: Run Code Generation
```bash
cd flutter_chat_app
dart run build_runner build --delete-conflicting-outputs
```

### Step 8: Write Unit Tests
**New File:** `test/unit/services/offline_queue_service_test.dart`

**Tests:**
- Add operation to queue
- Get pending operations
- Process queue in FIFO order
- Retry failed operations with exponential backoff
- Mark operations as completed/failed
- Auto-process on network connectivity change

## Success Criteria

- [ ] All write operations queue when offline
- [ ] Operations process automatically when online
- [ ] FIFO order maintained
- [ ] Retry logic works with exponential backoff
- [ ] No data loss during offline operations
- [ ] Conflicts resolved using last-write-wins
- [ ] Unit tests pass with >80% coverage

## Timeline

- **Step 1-2:** 1 hour (Repository updates)
- **Step 3-4:** 1 hour (Processor implementation)
- **Step 5-6:** 30 minutes (Conflict resolution + DI)
- **Step 7:** 10 minutes (Code generation)
- **Step 8:** 1 hour (Unit tests)

**Total:** ~3.5 hours

## Notes

- Existing OfflineQueueService is well-designed
- Main work is integration, not new implementation
- Follow existing patterns in repositories
- Use BaseRepository methods for consistency
- Ensure proper error handling and logging

---

**Next Steps:** Begin Step 1 - Update MessageRepositoryImpl
