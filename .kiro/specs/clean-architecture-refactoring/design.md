# Clean Architecture Refactoring - Design Document

## Overview

This document defines the detailed architecture design for refactoring the Flutter Chat App from its current state (service-oriented with technical debt) to a proper Clean Architecture implementation.

**Version**: 1.0  
**Last Updated**: 2026-01-28  
**Author**: Senior Flutter/Mobile Architect

---

## Architecture Vision

### Target Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Pages   │  │  Widgets │  │  BLoCs   │  │  States  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Entities │  │ UseCases │  │Repository│  │ Failures │   │
│  │          │  │          │  │Interfaces│  │          │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Models  │  │Repository│  │  Remote  │  │  Local   │   │
│  │          │  │   Impl   │  │DataSource│  │DataSource│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE LAYER                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   API    │  │ Database │  │  Cache   │  │  Network │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer**:
- UI components (Pages, Widgets)
- State management (BLoCs)
- User input handling
- Display logic only

**Domain Layer**:
- Business entities
- Business logic (UseCases)
- Repository interfaces
- Business rules validation
- NO dependencies on other layers

**Data Layer**:
- Data models (with JSON serialization)
- Repository implementations
- Data sources (Remote, Local)
- Data transformation (Model ↔ Entity)

**Infrastructure Layer**:
- External services (API, Database, Cache)
- Platform-specific code
- Third-party integrations

---

## Design Principles

### 1. Dependency Rule
Dependencies point inward. Outer layers depend on inner layers, never the reverse.

```dart
// ✅ CORRECT
class ChatBloc {
  final SendMessageUseCase _useCase; // Domain
}

// ❌ WRONG
class SendMessageUseCase {
  final ChatBloc _bloc; // Presentation
}
```

### 2. Single Responsibility
Each class has one reason to change.

```dart
// ✅ CORRECT - Single responsibility
class SendMessageUseCase {
  Future<Either<Failure, Message>> call(Message message);
}

// ❌ WRONG - Multiple responsibilities
class MessageService {
  Future<void> sendMessage();
  Future<void> syncMessages();
  Future<void> deleteMessage();
  Future<void> uploadMedia();
}
```

### 3. Interface Segregation
Clients should not depend on interfaces they don't use.

```dart
// ✅ CORRECT - Focused interfaces
abstract class IMessageRepository {
  Future<Either<Failure, Message>> sendMessage(Message message);
}

abstract class IMessageSyncRepository {
  Future<Either<Failure, void>> syncMessages();
}

// ❌ WRONG - Fat interface
abstract class IMessageRepository {
  Future<Either<Failure, Message>> sendMessage(Message message);
  Future<Either<Failure, void>> syncMessages();
  Future<Either<Failure, void>> deleteMessage(String id);
  Future<Either<Failure, void>> uploadMedia(File file);
  // ... 20 more methods
}
```


### 4. Dependency Inversion
Depend on abstractions, not concretions.

```dart
// ✅ CORRECT - Depends on abstraction
class SendMessageUseCase {
  final IMessageRepository _repository; // Interface
  
  SendMessageUseCase(this._repository);
}

// ❌ WRONG - Depends on concrete class
class SendMessageUseCase {
  final MessageRepositoryImpl _repository; // Concrete
  
  SendMessageUseCase(this._repository);
}
```

### 5. Open/Closed Principle
Open for extension, closed for modification.

```dart
// ✅ CORRECT - Use decorators for extension
@Decorator()
class MonitoringDecorator<T> implements IMessageRepository {
  final IMessageRepository _repository;
  final PerformanceMonitor _monitor;
  
  @override
  Future<Either<Failure, Message>> sendMessage(Message message) async {
    return _monitor.track(() => _repository.sendMessage(message));
  }
}

// ❌ WRONG - Modify existing class
class MessageRepository {
  Future<Either<Failure, Message>> sendMessage(Message message) async {
    // Original logic
    final result = await _api.send(message);
    
    // Added monitoring (modification!)
    _monitor.track(result);
    
    return result;
  }
}
```

---

## Detailed Component Design

### 1. Dependency Injection System

#### Current State (WRONG)
```dart
// Multiple DI systems
// lib/di/dependency_injection.dart
@module
abstract class AppModule {
  @singleton
  DatabaseService provideLegacyDatabaseService() {
    return DatabaseService.instance; // Manual singleton
  }
}

// lib/core/di/injection.dart
Future<void> initializeDependencies() async {
  configureDependencies(getIt);
}

// Manual singletons everywhere
class EnterpriseIntegrationHub {
  static EnterpriseIntegrationHub? _instance;
  static EnterpriseIntegrationHub get instance => 
    _instance ??= EnterpriseIntegrationHub._();
}
```

#### Target State (CORRECT)
```dart
// Single DI system: lib/core/di/injection.dart
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> initializeDependencies() async {
  final logger = Logger();
  
  // Register external dependencies
  if (!getIt.isRegistered<Logger>()) {
    getIt.registerSingleton<Logger>(logger);
  }
  
  if (!getIt.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
  }
  
  // Initialize auto-generated dependencies
  await getIt.init();
}

// All services use @singleton or @lazySingleton
@singleton
class DatabaseService {
  final SharedPreferences _prefs;
  
  DatabaseService(this._prefs); // Constructor injection
}

// No more manual singletons!
```

#### DI Registration Patterns

**Singleton** - Created once, lives for app lifetime:
```dart
@singleton
class DatabaseService {
  DatabaseService(SharedPreferences prefs);
}
```

**LazySingleton** - Created on first use:
```dart
@lazySingleton
class CacheManager {
  CacheManager(DatabaseService db);
}
```

**Factory** - New instance every time:
```dart
@injectable
class MessageValidator {
  MessageValidator();
}
```

**Named Registration** - Multiple implementations:
```dart
@Named('remote')
@injectable
class RemoteMessageDataSource implements IMessageDataSource {
  // ...
}

@Named('local')
@injectable
class LocalMessageDataSource implements IMessageDataSource {
  // ...
}
```


### 2. Domain Layer Design

#### 2.1 Entities

Entities are pure business objects with no dependencies.

```dart
// lib/domain/entities/message.dart
import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String> attachments;
  
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.attachments = const [],
  });
  
  // Business logic methods
  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isRead => status == MessageStatus.read;
  bool get hasAttachments => attachments.isNotEmpty;
  
  // Validation
  bool get isValid => content.isNotEmpty || attachments.isNotEmpty;
  
  @override
  List<Object?> get props => [
    id, chatId, senderId, content, type, 
    timestamp, status, attachments
  ];
}

enum MessageType { text, image, video, audio, file }
enum MessageStatus { pending, sent, delivered, read, failed }
```

#### 2.2 Repository Interfaces

Repositories define contracts for data operations.

```dart
// lib/domain/repositories/message_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/message.dart';
import '../../core/error/failures.dart';

abstract class IMessageRepository {
  /// Get messages for a specific chat
  /// Returns list of messages or failure
  Future<Either<Failure, List<Message>>> getMessages({
    required String chatId,
    int? limit,
    String? beforeMessageId,
  });
  
  /// Send a new message
  /// Returns sent message with server-generated ID or failure
  Future<Either<Failure, Message>> sendMessage(Message message);
  
  /// Update message status (delivered, read, etc.)
  Future<Either<Failure, Message>> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });
  
  /// Delete a message
  Future<Either<Failure, void>> deleteMessage(String messageId);
  
  /// Stream of new messages for a chat
  Stream<Either<Failure, Message>> watchMessages(String chatId);
}
```

#### 2.3 Use Cases

Use cases encapsulate single business operations.

```dart
// lib/domain/usecases/message/send_message.dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../entities/message.dart';
import '../../repositories/message_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

@injectable
class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  final IMessageRepository _repository;
  
  SendMessageUseCase(this._repository);
  
  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    // Validate message
    if (!params.message.isValid) {
      return const Left(ValidationFailure(
        message: 'Message must have content or attachments',
      ));
    }
    
    // Send message
    return await _repository.sendMessage(params.message);
  }
}

class SendMessageParams {
  final Message message;
  
  const SendMessageParams({required this.message});
}
```

```dart
// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
```


### 3. Data Layer Design

#### 3.1 Models

Models are data transfer objects with JSON serialization.

```dart
// lib/data/models/message_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const MessageModel._();
  
  const factory MessageModel({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    required String type,
    required DateTime timestamp,
    required String status,
    @Default([]) List<String> attachments,
  }) = _MessageModel;
  
  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
  
  // Convert to domain entity
  Message toEntity() {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: _parseMessageType(type),
      timestamp: timestamp,
      status: _parseMessageStatus(status),
      attachments: attachments,
    );
  }
  
  // Create from domain entity
  factory MessageModel.fromEntity(Message entity) {
    return MessageModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      content: entity.content,
      type: entity.type.name,
      timestamp: entity.timestamp,
      status: entity.status.name,
      attachments: entity.attachments,
    );
  }
  
  static MessageType _parseMessageType(String type) {
    return MessageType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MessageType.text,
    );
  }
  
  static MessageStatus _parseMessageStatus(String status) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => MessageStatus.pending,
    );
  }
}
```

#### 3.2 Data Sources

Data sources handle specific data operations.

```dart
// lib/data/datasources/message/message_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../models/message_model.dart';
import '../../../core/network/graphql_client.dart';
import '../../../core/error/exceptions.dart';

abstract class IMessageRemoteDataSource {
  Future<List<MessageModel>> getMessages({
    required String chatId,
    int? limit,
    String? beforeMessageId,
  });
  
  Future<MessageModel> sendMessage(MessageModel message);
  
  Future<MessageModel> updateMessageStatus({
    required String messageId,
    required String status,
  });
  
  Future<void> deleteMessage(String messageId);
  
  Stream<MessageModel> watchMessages(String chatId);
}

@Named('remote')
@LazySingleton(as: IMessageRemoteDataSource)
class MessageRemoteDataSource implements IMessageRemoteDataSource {
  final GraphQLClient _client;
  
  MessageRemoteDataSource(this._client);
  
  @override
  Future<List<MessageModel>> getMessages({
    required String chatId,
    int? limit,
    String? beforeMessageId,
  }) async {
    try {
      const query = '''
        query GetMessages(\$chatId: ID!, \$limit: Int, \$before: ID) {
          messages(chatId: \$chatId, limit: \$limit, before: \$before) {
            id
            chatId
            senderId
            content
            type
            timestamp
            status
            attachments
          }
        }
      ''';
      
      final result = await _client.query(
        query,
        variables: {
          'chatId': chatId,
          'limit': limit,
          'before': beforeMessageId,
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception.toString(),
          statusCode: 500,
        );
      }
      
      final messages = result.data?['messages'] as List<dynamic>?;
      if (messages == null) {
        throw ServerException(message: 'No messages data');
      }
      
      return messages
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      const mutation = '''
        mutation SendMessage(\$input: SendMessageInput!) {
          sendMessage(input: \$input) {
            id
            chatId
            senderId
            content
            type
            timestamp
            status
            attachments
          }
        }
      ''';
      
      final result = await _client.mutate(
        mutation,
        variables: {
          'input': message.toJson(),
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception.toString(),
          statusCode: 500,
        );
      }
      
      final data = result.data?['sendMessage'] as Map<String, dynamic>?;
      if (data == null) {
        throw ServerException(message: 'No message data returned');
      }
      
      return MessageModel.fromJson(data);
      
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  Stream<MessageModel> watchMessages(String chatId) {
    const subscription = '''
      subscription WatchMessages(\$chatId: ID!) {
        messageAdded(chatId: \$chatId) {
          id
          chatId
          senderId
          content
          type
          timestamp
          status
          attachments
        }
      }
    ''';
    
    return _client
        .subscribe(subscription, variables: {'chatId': chatId})
        .map((result) {
          if (result.hasException) {
            throw ServerException(message: result.exception.toString());
          }
          
          final data = result.data?['messageAdded'] as Map<String, dynamic>?;
          if (data == null) {
            throw ServerException(message: 'No message data');
          }
          
          return MessageModel.fromJson(data);
        });
  }
  
  @override
  Future<MessageModel> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    // Implementation similar to sendMessage
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteMessage(String messageId) async {
    // Implementation similar to sendMessage
    throw UnimplementedError();
  }
}
```


```dart
// lib/data/datasources/message/message_local_datasource.dart
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import '../../models/message_model.dart';
import '../../../core/database/isar_service.dart';
import '../../../core/error/exceptions.dart';

abstract class IMessageLocalDataSource {
  Future<List<MessageModel>> getCachedMessages({
    required String chatId,
    int? limit,
  });
  
  Future<void> cacheMessages(List<MessageModel> messages);
  
  Future<void> cacheMessage(MessageModel message);
  
  Future<void> deleteMessage(String messageId);
  
  Future<void> clearCache(String chatId);
}

@Named('local')
@LazySingleton(as: IMessageLocalDataSource)
class MessageLocalDataSource implements IMessageLocalDataSource {
  final IsarService _isar;
  
  MessageLocalDataSource(this._isar);
  
  @override
  Future<List<MessageModel>> getCachedMessages({
    required String chatId,
    int? limit,
  }) async {
    try {
      final isar = await _isar.db;
      
      var query = isar.messageModels
          .filter()
          .chatIdEqualTo(chatId)
          .sortByTimestampDesc();
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final messages = await query.findAll();
      return messages;
      
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<void> cacheMessages(List<MessageModel> messages) async {
    try {
      final isar = await _isar.db;
      
      await isar.writeTxn(() async {
        await isar.messageModels.putAll(messages);
      });
      
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<void> cacheMessage(MessageModel message) async {
    try {
      final isar = await _isar.db;
      
      await isar.writeTxn(() async {
        await isar.messageModels.put(message);
      });
      
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final isar = await _isar.db;
      
      await isar.writeTxn(() async {
        await isar.messageModels.delete(messageId.hashCode);
      });
      
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<void> clearCache(String chatId) async {
    try {
      final isar = await _isar.db;
      
      await isar.writeTxn(() async {
        await isar.messageModels
            .filter()
            .chatIdEqualTo(chatId)
            .deleteAll();
      });
      
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
```

#### 3.3 Repository Implementation

Repository implements the domain interface and coordinates data sources.

```dart
// lib/data/repositories/message_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/network_info.dart';
import '../datasources/message/message_remote_datasource.dart';
import '../datasources/message/message_local_datasource.dart';
import '../models/message_model.dart';

@LazySingleton(as: IMessageRepository)
class MessageRepositoryImpl implements IMessageRepository {
  final IMessageRemoteDataSource _remoteDataSource;
  final IMessageLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  
  MessageRepositoryImpl({
    @Named('remote') required IMessageRemoteDataSource remoteDataSource,
    @Named('local') required IMessageLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;
  
  @override
  Future<Either<Failure, List<Message>>> getMessages({
    required String chatId,
    int? limit,
    String? beforeMessageId,
  }) async {
    // Check network connectivity
    if (!await _networkInfo.isConnected) {
      // Return cached data when offline
      try {
        final cachedModels = await _localDataSource.getCachedMessages(
          chatId: chatId,
          limit: limit,
        );
        final messages = cachedModels.map((m) => m.toEntity()).toList();
        return Right(messages);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
    
    // Fetch from remote when online
    try {
      final models = await _remoteDataSource.getMessages(
        chatId: chatId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );
      
      // Cache the fetched messages
      await _localDataSource.cacheMessages(models);
      
      // Convert to entities
      final messages = models.map((m) => m.toEntity()).toList();
      return Right(messages);
      
    } on ServerException catch (e) {
      // On server error, try to return cached data
      try {
        final cachedModels = await _localDataSource.getCachedMessages(
          chatId: chatId,
          limit: limit,
        );
        final messages = cachedModels.map((m) => m.toEntity()).toList();
        return Right(messages);
      } on CacheException {
        return Left(ServerFailure(message: e.message));
      }
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Message>> sendMessage(Message message) async {
    // Check network connectivity
    if (!await _networkInfo.isConnected) {
      // Queue for later sync when offline
      try {
        final model = MessageModel.fromEntity(message);
        await _localDataSource.cacheMessage(model);
        // TODO: Add to offline queue
        return Right(message);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
    
    // Send to server when online
    try {
      final model = MessageModel.fromEntity(message);
      final sentModel = await _remoteDataSource.sendMessage(model);
      
      // Cache the sent message
      await _localDataSource.cacheMessage(sentModel);
      
      return Right(sentModel.toEntity());
      
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
  
  @override
  Stream<Either<Failure, Message>> watchMessages(String chatId) {
    try {
      return _remoteDataSource.watchMessages(chatId).map((model) {
        // Cache incoming messages
        _localDataSource.cacheMessage(model);
        return Right<Failure, Message>(model.toEntity());
      }).handleError((error) {
        if (error is ServerException) {
          return Left<Failure, Message>(ServerFailure(message: error.message));
        }
        return Left<Failure, Message>(UnexpectedFailure(message: error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(UnexpectedFailure(message: e.toString())));
    }
  }
  
  @override
  Future<Either<Failure, Message>> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    // Implementation similar to sendMessage
    throw UnimplementedError();
  }
  
  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    // Implementation similar to sendMessage
    throw UnimplementedError();
  }
}
```


### 4. Presentation Layer Design

#### 4.1 BLoC with Use Cases

```dart
// lib/presentation/blocs/chat/chat_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/message.dart';

part 'chat_event.freezed.dart';

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.loadMessages({
    required String chatId,
    int? limit,
  }) = ChatLoadMessagesEvent;
  
  const factory ChatEvent.sendMessage({
    required Message message,
  }) = ChatSendMessageEvent;
  
  const factory ChatEvent.messageReceived({
    required Message message,
  }) = ChatMessageReceivedEvent;
  
  const factory ChatEvent.deleteMessage({
    required String messageId,
  }) = ChatDeleteMessageEvent;
  
  const factory ChatEvent.retryFailed() = ChatRetryFailedEvent;
}
```

```dart
// lib/presentation/blocs/chat/chat_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/message.dart';
import '../../../core/error/failures.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  
  const factory ChatState.loading({
    String? operation,
  }) = ChatLoading;
  
  const factory ChatState.loaded({
    required List<Message> messages,
    required String chatId,
    @Default(false) bool hasMore,
  }) = ChatLoaded;
  
  const factory ChatState.error({
    required Failure failure,
    required String operation,
    VoidCallback? retryAction,
  }) = ChatError;
}
```

```dart
// lib/presentation/blocs/chat/chat_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/usecases/message/get_messages.dart';
import '../../../domain/usecases/message/send_message.dart';
import '../../../domain/usecases/message/delete_message.dart';
import '../../../domain/usecases/message/watch_messages.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final WatchMessagesUseCase _watchMessagesUseCase;
  
  StreamSubscription<Message>? _messageSubscription;
  
  ChatBloc({
    required GetMessagesUseCase getMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required WatchMessagesUseCase watchMessagesUseCase,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _sendMessageUseCase = sendMessageUseCase,
        _deleteMessageUseCase = deleteMessageUseCase,
        _watchMessagesUseCase = watchMessagesUseCase,
        super(const ChatState.initial()) {
    on<ChatLoadMessagesEvent>(_onLoadMessages);
    on<ChatSendMessageEvent>(_onSendMessage);
    on<ChatMessageReceivedEvent>(_onMessageReceived);
    on<ChatDeleteMessageEvent>(_onDeleteMessage);
    on<ChatRetryFailedEvent>(_onRetryFailed);
  }
  
  Future<void> _onLoadMessages(
    ChatLoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatState.loading(operation: 'load_messages'));
    
    // Get messages
    final result = await _getMessagesUseCase(GetMessagesParams(
      chatId: event.chatId,
      limit: event.limit,
    ));
    
    result.fold(
      (failure) => emit(ChatState.error(
        failure: failure,
        operation: 'load_messages',
        retryAction: () => add(event),
      )),
      (messages) {
        emit(ChatState.loaded(
          messages: messages,
          chatId: event.chatId,
          hasMore: messages.length == (event.limit ?? 50),
        ));
        
        // Start watching for new messages
        _startWatchingMessages(event.chatId);
      },
    );
  }
  
  Future<void> _onSendMessage(
    ChatSendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistically add message to UI
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(
        messages: [...currentState.messages, event.message],
      ));
    }
    
    // Send message
    final result = await _sendMessageUseCase(SendMessageParams(
      message: event.message,
    ));
    
    result.fold(
      (failure) {
        // Remove optimistic message and show error
        if (currentState is ChatLoaded) {
          emit(currentState.copyWith(
            messages: currentState.messages
                .where((m) => m.id != event.message.id)
                .toList(),
          ));
        }
        
        emit(ChatState.error(
          failure: failure,
          operation: 'send_message',
          retryAction: () => add(event),
        ));
      },
      (sentMessage) {
        // Update with server-confirmed message
        if (currentState is ChatLoaded) {
          final updatedMessages = currentState.messages
              .map((m) => m.id == event.message.id ? sentMessage : m)
              .toList();
          
          emit(currentState.copyWith(messages: updatedMessages));
        }
      },
    );
  }
  
  void _onMessageReceived(
    ChatMessageReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      // Add new message if not already in list
      final messageExists = currentState.messages
          .any((m) => m.id == event.message.id);
      
      if (!messageExists) {
        emit(currentState.copyWith(
          messages: [...currentState.messages, event.message],
        ));
      }
    }
  }
  
  Future<void> _onDeleteMessage(
    ChatDeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _deleteMessageUseCase(DeleteMessageParams(
      messageId: event.messageId,
    ));
    
    result.fold(
      (failure) => emit(ChatState.error(
        failure: failure,
        operation: 'delete_message',
        retryAction: () => add(event),
      )),
      (_) {
        final currentState = state;
        if (currentState is ChatLoaded) {
          emit(currentState.copyWith(
            messages: currentState.messages
                .where((m) => m.id != event.messageId)
                .toList(),
          ));
        }
      },
    );
  }
  
  void _onRetryFailed(
    ChatRetryFailedEvent event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatError && currentState.retryAction != null) {
      currentState.retryAction!();
    }
  }
  
  void _startWatchingMessages(String chatId) {
    _messageSubscription?.cancel();
    
    final stream = _watchMessagesUseCase(WatchMessagesParams(
      chatId: chatId,
    ));
    
    _messageSubscription = stream.listen((result) {
      result.fold(
        (failure) {
          // Handle stream error
          add(ChatEvent.error(
            failure: failure,
            operation: 'watch_messages',
          ));
        },
        (message) {
          add(ChatEvent.messageReceived(message: message));
        },
      );
    });
  }
  
  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
```

