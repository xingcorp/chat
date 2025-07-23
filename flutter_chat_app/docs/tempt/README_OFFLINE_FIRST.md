# Offline-First Architecture with Isar

## Overview

This project implements an offline-first data architecture using [Isar Database](https://isar.dev), a high-performance NoSQL database for Flutter applications. The offline-first approach prioritizes local data storage and operations, ensuring the application works seamlessly regardless of network connectivity.

## Key Components

### 1. Database Service (`DatabaseService`)

The `DatabaseService` class provides a central interface for all database operations:

- Initializes and manages the Isar database instance
- Provides methods for CRUD operations on all collections
- Handles database transactions and backup operations
- Manages database lifecycle (initialization, closing)

### 2. Data Models

The application uses Isar-annotated models for all entities:

- `UserModel`: User profile information
- `ChatModel`: Chat conversation details
- `MessageModel`: Individual messages with status tracking

All models support:
- Local and server IDs for synchronization
- Serialization from/to JSON for API communication
- Copy methods for immutability
- Helper methods for common operations

### 3. Offline-First Repository (`OfflineFirstRepository`)

The `OfflineFirstRepository` implements the offline-first pattern:

- All data operations prioritize local storage first
- Changes are synchronized with the server when connectivity is available
- Implements a queue system for operations when offline
- Provides streams for real-time local data updates
- Handles conflict resolution during synchronization

## Using the Offline-First System

### Setup Requirements

1. Add Isar dependencies to your `pubspec.yaml`:
   ```yaml
   dependencies:
     isar: ^3.1.0+1
     isar_flutter_libs: ^3.1.0+1
     path_provider: ^2.1.1

   dev_dependencies:
     isar_generator: ^3.1.0+1
     build_runner: ^2.4.7
   ```

2. Run code generation to create the schema files:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Basic Usage

1. **Saving Data**
   ```dart
   final repository = getIt<OfflineFirstRepository>();
   
   // Creating a new message (stored locally first)
   final message = MessageModel(
     localId: uuid.v4(),
     chatId: 'chat123',
     senderId: 'user456',
     content: 'Hello world',
     type: MessageType.text,
     createdAt: DateTime.now(),
   );
   
   // Save locally (will sync when online)
   await repository.saveMessage(message);
   ```

2. **Reading Data**
   ```dart
   // Get a stream of all chats (updates in real-time)
   final chatStream = repository.getChatStream();
   
   // Build widget with StreamBuilder
   StreamBuilder<List<ChatModel>>(
     stream: chatStream,
     builder: (context, snapshot) {
       if (snapshot.hasData) {
         final chats = snapshot.data!;
         return ListView.builder(
           itemCount: chats.length,
           itemBuilder: (context, index) => ChatListItem(chat: chats[index]),
         );
       }
       return CircularProgressIndicator();
     },
   );
   ```

3. **Handling Synchronization**
   ```dart
   // Manual synchronization (typically not needed as it happens automatically)
   await repository.synchronize();
   
   // Listen for synchronization status
   final syncStatusStream = (repository as OfflineFirstRepositoryImpl).syncStream;
   
   // Show sync indicator
   StreamBuilder<bool>(
     stream: syncStatusStream,
     builder: (context, snapshot) {
       final isSyncing = snapshot.data ?? false;
       return isSyncing ? CircularProgressIndicator() : SizedBox();
     },
   );
   ```

## Architecture Benefits

1. **Performance**: Data operations are fast because they happen locally first
2. **Reliability**: App works regardless of network conditions
3. **Battery Efficiency**: Reduces constant server communication
4. **User Experience**: No loading states or network errors during normal usage
5. **Data Integrity**: Ensures data is never lost even if sent while offline

## Future Enhancements

- Implement bidirectional synchronization with conflict resolution
- Add data encryption for sensitive information
- Optimize storage with selective data retention policies
- Implement background synchronization service 