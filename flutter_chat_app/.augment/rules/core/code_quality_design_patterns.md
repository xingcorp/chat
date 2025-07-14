---
type: "agent_requested"
description: "Example description"
---
# Code Quality & Design Patterns Rules - Enterprise Messaging App

**Type**: Always  
**Description**: Comprehensive code quality standards with SOLID principles, OOP best practices, design patterns, and logical flow guidelines for Flutter messaging app

## Code Quality Standards

### Naming Conventions & Clarity
```dart
// ✅ EXCELLENT: Clear, intention-revealing names
class MessageDeliveryTracker {
  final Map<String, MessageDeliveryStatus> _messageStatusMap = {};
  final StreamController<MessageDeliveryEvent> _deliveryEventController = StreamController.broadcast();
  
  Future<void> trackMessageDelivery(String messageId, String recipientId) async {
    final deliveryStatus = MessageDeliveryStatus.pending(
      messageId: messageId,
      recipientId: recipientId,
      timestamp: DateTime.now(),
    );
    
    _messageStatusMap[messageId] = deliveryStatus;
    await _notifyDeliveryStatusChange(deliveryStatus);
  }
  
  bool hasMessageBeenDelivered(String messageId) {
    return _messageStatusMap[messageId]?.isDelivered ?? false;
  }
}

// ❌ POOR: Unclear, abbreviated names
class MsgTrkr {
  final Map<String, dynamic> _map = {};
  final StreamController _ctrl = StreamController();
  
  Future<void> track(String id, String rid) async {
    final st = {'id': id, 'rid': rid, 't': DateTime.now()};
    _map[id] = st;
    _ctrl.add(st);
  }
  
  bool chk(String id) => _map[id]?['delivered'] ?? false;
}
```

### Function Design & Single Responsibility
```dart
// ✅ EXCELLENT: Small, focused functions with single responsibility
class MessageProcessor {
  Future<ProcessedMessage> processIncomingMessage(RawMessage rawMessage) async {
    final validatedMessage = await _validateMessage(rawMessage);
    final decryptedMessage = await _decryptMessage(validatedMessage);
    final enrichedMessage = await _enrichWithMetadata(decryptedMessage);
    final persistedMessage = await _persistMessage(enrichedMessage);
    
    await _notifyMessageReceived(persistedMessage);
    return persistedMessage;
  }
  
  Future<ValidatedMessage> _validateMessage(RawMessage message) async {
    if (message.content.isEmpty) {
      throw MessageValidationException('Message content cannot be empty');
    }
    
    if (message.senderId.isEmpty) {
      throw MessageValidationException('Sender ID is required');
    }
    
    if (message.content.length > MessageConstants.maxContentLength) {
      throw MessageValidationException('Message content exceeds maximum length');
    }
    
    return ValidatedMessage.fromRaw(message);
  }
  
  Future<DecryptedMessage> _decryptMessage(ValidatedMessage message) async {
    if (!message.isEncrypted) {
      return DecryptedMessage.fromValidated(message);
    }
    
    final decryptionKey = await _getDecryptionKey(message.conversationId);
    final decryptedContent = await _encryptionService.decrypt(
      message.encryptedContent,
      decryptionKey,
    );
    
    return DecryptedMessage(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      content: decryptedContent,
      timestamp: message.timestamp,
    );
  }
}

// ❌ POOR: Large function doing multiple things
class MessageProcessor {
  Future<dynamic> processMessage(dynamic msg) async {
    // Validation, decryption, persistence, notification all in one method
    if (msg['content'] == null || msg['content'].isEmpty) throw Exception('Invalid');
    var key = await getKey(msg['convId']);
    var decrypted = decrypt(msg['content'], key);
    await db.save(decrypted);
    notifyUsers(decrypted);
    updateUI(decrypted);
    logActivity(decrypted);
    return decrypted;
  }
}
```

## SOLID Principles Implementation

### Single Responsibility Principle (SRP)
```dart
// ✅ EXCELLENT: Each class has one reason to change
class MessageValidator {
  ValidationResult validateMessage(Message message) {
    final errors = <String>[];
    
    if (message.content.isEmpty) {
      errors.add('Message content cannot be empty');
    }
    
    if (message.content.length > MessageConstants.maxLength) {
      errors.add('Message content exceeds maximum length');
    }
    
    if (!_isValidSenderId(message.senderId)) {
      errors.add('Invalid sender ID format');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class MessageEncryptor {
  Future<EncryptedMessage> encryptMessage(Message message, String encryptionKey) async {
    final encryptedContent = await _aesEncryption.encrypt(
      message.content,
      encryptionKey,
    );
    
    return EncryptedMessage(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      encryptedContent: encryptedContent,
      timestamp: message.timestamp,
    );
  }
}

class MessagePersistence {
  Future<void> saveMessage(Message message) async {
    await _database.insert('messages', message.toMap());
    await _updateConversationLastMessage(message.conversationId, message);
  }
}
```

### Open/Closed Principle (OCP)
```dart
// ✅ EXCELLENT: Open for extension, closed for modification
abstract class MessageNotificationStrategy {
  Future<void> sendNotification(Message message, User recipient);
}

class PushNotificationStrategy implements MessageNotificationStrategy {
  final PushNotificationService _pushService;
  
  PushNotificationStrategy(this._pushService);
  
  @override
  Future<void> sendNotification(Message message, User recipient) async {
    final notification = PushNotification(
      title: 'New message from ${message.senderName}',
      body: message.content,
      data: {'messageId': message.id, 'conversationId': message.conversationId},
    );
    
    await _pushService.send(notification, recipient.deviceToken);
  }
}

class EmailNotificationStrategy implements MessageNotificationStrategy {
  final EmailService _emailService;
  
  EmailNotificationStrategy(this._emailService);
  
  @override
  Future<void> sendNotification(Message message, User recipient) async {
    final email = Email(
      to: recipient.email,
      subject: 'New message from ${message.senderName}',
      body: _generateEmailBody(message),
    );
    
    await _emailService.send(email);
  }
}

class MessageNotificationManager {
  final List<MessageNotificationStrategy> _strategies;
  
  MessageNotificationManager(this._strategies);
  
  Future<void> notifyRecipient(Message message, User recipient) async {
    for (final strategy in _strategies) {
      try {
        await strategy.sendNotification(message, recipient);
      } catch (e) {
        _logger.error('Notification strategy failed: $e');
      }
    }
  }
}
```

### Liskov Substitution Principle (LSP)
```dart
// ✅ EXCELLENT: Subtypes are substitutable for base types
abstract class MessageStorage {
  Future<void> saveMessage(Message message);
  Future<Message?> getMessage(String messageId);
  Future<List<Message>> getMessages(String conversationId, {int limit = 20});
}

class LocalMessageStorage implements MessageStorage {
  final Database _database;
  
  LocalMessageStorage(this._database);
  
  @override
  Future<void> saveMessage(Message message) async {
    await _database.insert('messages', message.toMap());
  }
  
  @override
  Future<Message?> getMessage(String messageId) async {
    final result = await _database.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
    
    return result.isNotEmpty ? Message.fromMap(result.first) : null;
  }
  
  @override
  Future<List<Message>> getMessages(String conversationId, {int limit = 20}) async {
    final results = await _database.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return results.map((map) => Message.fromMap(map)).toList();
  }
}

class CloudMessageStorage implements MessageStorage {
  final ApiClient _apiClient;
  
  CloudMessageStorage(this._apiClient);
  
  @override
  Future<void> saveMessage(Message message) async {
    await _apiClient.post('/messages', message.toJson());
  }
  
  @override
  Future<Message?> getMessage(String messageId) async {
    try {
      final response = await _apiClient.get('/messages/$messageId');
      return Message.fromJson(response.data);
    } on NotFoundException {
      return null;
    }
  }
  
  @override
  Future<List<Message>> getMessages(String conversationId, {int limit = 20}) async {
    final response = await _apiClient.get(
      '/conversations/$conversationId/messages',
      queryParameters: {'limit': limit},
    );
    
    return (response.data as List)
        .map((json) => Message.fromJson(json))
        .toList();
  }
}
```

### Factory Pattern
```dart
// ✅ EXCELLENT: Factory pattern for message creation
abstract class MessageFactory {
  Message createMessage(MessageType type, Map<String, dynamic> data);
}

class MessageFactoryImpl implements MessageFactory {
  @override
  Message createMessage(MessageType type, Map<String, dynamic> data) {
    switch (type) {
      case MessageType.text:
        return TextMessage(
          id: data['id'],
          conversationId: data['conversationId'],
          senderId: data['senderId'],
          content: data['content'],
          timestamp: DateTime.parse(data['timestamp']),
        );

      case MessageType.image:
        return ImageMessage(
          id: data['id'],
          conversationId: data['conversationId'],
          senderId: data['senderId'],
          imageUrl: data['imageUrl'],
          caption: data['caption'],
          timestamp: DateTime.parse(data['timestamp']),
        );

      case MessageType.file:
        return FileMessage(
          id: data['id'],
          conversationId: data['conversationId'],
          senderId: data['senderId'],
          fileName: data['fileName'],
          fileUrl: data['fileUrl'],
          fileSize: data['fileSize'],
          timestamp: DateTime.parse(data['timestamp']),
        );

      default:
        throw UnsupportedMessageTypeException('Unsupported message type: $type');
    }
  }
}

// Usage with dependency injection
class MessageProcessor {
  final MessageFactory _messageFactory;

  MessageProcessor(this._messageFactory);

  Future<Message> processIncomingMessage(Map<String, dynamic> rawData) async {
    final messageType = MessageType.values.firstWhere(
      (type) => type.name == rawData['type'],
    );

    return _messageFactory.createMessage(messageType, rawData);
  }
}
```

### Observer Pattern (Enhanced)
```dart
// ✅ EXCELLENT: Observer pattern for real-time updates
abstract class MessageObserver {
  void onMessageReceived(Message message);
  void onMessageStatusChanged(String messageId, MessageStatus status);
  void onTypingStatusChanged(String conversationId, String userId, bool isTyping);
}

class MessageSubject {
  final List<MessageObserver> _observers = [];

  void addObserver(MessageObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(MessageObserver observer) {
    _observers.remove(observer);
  }

  void notifyMessageReceived(Message message) {
    for (final observer in _observers) {
      try {
        observer.onMessageReceived(message);
      } catch (e) {
        _logger.error('Observer notification failed: $e');
      }
    }
  }

  void notifyMessageStatusChanged(String messageId, MessageStatus status) {
    for (final observer in _observers) {
      try {
        observer.onMessageStatusChanged(messageId, status);
      } catch (e) {
        _logger.error('Observer notification failed: $e');
      }
    }
  }
}

// Concrete observer implementations
class UIMessageObserver implements MessageObserver {
  final MessageBloc _messageBloc;

  UIMessageObserver(this._messageBloc);

  @override
  void onMessageReceived(Message message) {
    _messageBloc.add(MessageEvent.receiveMessage(message: message));
  }

  @override
  void onMessageStatusChanged(String messageId, MessageStatus status) {
    _messageBloc.add(MessageEvent.updateStatus(
      messageId: messageId,
      status: status,
    ));
  }

  @override
  void onTypingStatusChanged(String conversationId, String userId, bool isTyping) {
    _messageBloc.add(MessageEvent.updateTypingStatus(
      conversationId: conversationId,
      userId: userId,
      isTyping: isTyping,
    ));
  }
}

class NotificationObserver implements MessageObserver {
  final NotificationService _notificationService;

  NotificationObserver(this._notificationService);

  @override
  void onMessageReceived(Message message) {
    _notificationService.showMessageNotification(message);
  }

  @override
  void onMessageStatusChanged(String messageId, MessageStatus status) {
    // Handle status change notifications if needed
  }

  @override
  void onTypingStatusChanged(String conversationId, String userId, bool isTyping) {
    // Handle typing notifications if needed
  }
}
```

### Strategy Pattern
```dart
// ✅ EXCELLENT: Strategy pattern for message processing
abstract class MessageProcessingStrategy {
  Future<ProcessedMessage> processMessage(RawMessage message);
}

class TextMessageProcessingStrategy implements MessageProcessingStrategy {
  final MessageValidator _validator;
  final ProfanityFilter _profanityFilter;

  TextMessageProcessingStrategy(this._validator, this._profanityFilter);

  @override
  Future<ProcessedMessage> processMessage(RawMessage message) async {
    // Validate text message
    final validationResult = await _validator.validateTextMessage(message);
    if (!validationResult.isValid) {
      throw MessageValidationException(validationResult.errors.first);
    }

    // Filter profanity
    final filteredContent = await _profanityFilter.filter(message.content);

    return ProcessedMessage(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      content: filteredContent,
      type: MessageType.text,
      timestamp: message.timestamp,
    );
  }
}

class ImageMessageProcessingStrategy implements MessageProcessingStrategy {
  final ImageValidator _imageValidator;
  final ImageCompressor _imageCompressor;
  final ImageModerationService _moderationService;

  ImageMessageProcessingStrategy(
    this._imageValidator,
    this._imageCompressor,
    this._moderationService,
  );

  @override
  Future<ProcessedMessage> processMessage(RawMessage message) async {
    // Validate image
    final validationResult = await _imageValidator.validateImage(message.imageData!);
    if (!validationResult.isValid) {
      throw MessageValidationException(validationResult.errors.first);
    }

    // Compress image
    final compressedImage = await _imageCompressor.compress(
      message.imageData!,
      quality: 0.8,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    // Content moderation
    final moderationResult = await _moderationService.moderateImage(compressedImage);
    if (!moderationResult.isApproved) {
      throw ContentModerationException('Image contains inappropriate content');
    }

    return ProcessedMessage(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      imageData: compressedImage,
      type: MessageType.image,
      timestamp: message.timestamp,
    );
  }
}

class MessageProcessor {
  final Map<MessageType, MessageProcessingStrategy> _strategies;

  MessageProcessor(this._strategies);

  Future<ProcessedMessage> processMessage(RawMessage message) async {
    final strategy = _strategies[message.type];
    if (strategy == null) {
      throw UnsupportedMessageTypeException('No strategy for message type: ${message.type}');
    }

    return await strategy.processMessage(message);
  }
}
```

### Command Pattern
```dart
// ✅ EXCELLENT: Command pattern for message operations
abstract class MessageCommand {
  Future<void> execute();
  Future<void> undo();
}

class SendMessageCommand implements MessageCommand {
  final Message _message;
  final MessageRepository _repository;
  final NotificationService _notificationService;

  SendMessageCommand(this._message, this._repository, this._notificationService);

  @override
  Future<void> execute() async {
    await _repository.saveMessage(_message);
    await _notificationService.notifyMessageSent(_message);
  }

  @override
  Future<void> undo() async {
    await _repository.deleteMessage(_message.id);
    await _notificationService.notifyMessageDeleted(_message.id);
  }
}

class DeleteMessageCommand implements MessageCommand {
  final String _messageId;
  final MessageRepository _repository;
  Message? _deletedMessage;

  DeleteMessageCommand(this._messageId, this._repository);

  @override
  Future<void> execute() async {
    _deletedMessage = await _repository.getMessage(_messageId);
    await _repository.deleteMessage(_messageId);
  }

  @override
  Future<void> undo() async {
    if (_deletedMessage != null) {
      await _repository.saveMessage(_deletedMessage!);
    }
  }
}

class MessageCommandInvoker {
  final List<MessageCommand> _history = [];
  int _currentIndex = -1;

  Future<void> executeCommand(MessageCommand command) async {
    // Remove any commands after current index (for redo functionality)
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    await command.execute();
    _history.add(command);
    _currentIndex++;
  }

  Future<void> undo() async {
    if (_currentIndex >= 0) {
      await _history[_currentIndex].undo();
      _currentIndex--;
    }
  }

  Future<void> redo() async {
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
      await _history[_currentIndex].execute();
    }
  }
}
```

## OOP Best Practices

### Encapsulation & Data Hiding
```dart
// ✅ EXCELLENT: Proper encapsulation with controlled access
class ConversationManager {
  final Map<String, Conversation> _conversations = {};
  final StreamController<ConversationEvent> _eventController = StreamController.broadcast();

  // Public read-only access
  Stream<ConversationEvent> get conversationEvents => _eventController.stream;

  // Controlled access with validation
  Conversation? getConversation(String conversationId) {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }
    return _conversations[conversationId];
  }

  // Business logic encapsulated within the class
  Future<void> addParticipant(String conversationId, String userId) async {
    final conversation = _conversations[conversationId];
    if (conversation == null) {
      throw ConversationNotFoundException('Conversation not found: $conversationId');
    }

    if (conversation.participants.contains(userId)) {
      throw ParticipantAlreadyExistsException('User already in conversation');
    }

    if (conversation.participants.length >= conversation.maxParticipants) {
      throw ConversationFullException('Conversation has reached maximum participants');
    }

    final updatedConversation = conversation.copyWith(
      participants: [...conversation.participants, userId],
    );

    _conversations[conversationId] = updatedConversation;
    _eventController.add(ConversationEvent.participantAdded(
      conversationId: conversationId,
      userId: userId,
    ));
  }

  // Private helper methods
  bool _isUserAuthorizedToModify(String conversationId, String userId) {
    final conversation = _conversations[conversationId];
    return conversation?.adminId == userId || conversation?.moderators.contains(userId) == true;
  }
}
```

### Inheritance & Polymorphism
```dart
// ✅ EXCELLENT: Proper inheritance hierarchy with polymorphism
abstract class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final DateTime timestamp;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.timestamp,
    required this.status,
  });

  // Template method pattern
  Map<String, dynamic> toJson() {
    final baseJson = {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'type': messageType.name,
    };

    // Let subclasses add their specific data
    baseJson.addAll(getSpecificData());
    return baseJson;
  }

  // Abstract methods for subclasses to implement
  MessageType get messageType;
  Map<String, dynamic> getSpecificData();
  Widget buildMessageWidget(BuildContext context);

  // Common behavior
  bool get isFromCurrentUser => senderId == CurrentUser.id;
  bool get canBeEdited => status == MessageStatus.sent && isFromCurrentUser;
}

class TextMessage extends Message {
  final String content;

  const TextMessage({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.timestamp,
    required super.status,
    required this.content,
  });

  @override
  MessageType get messageType => MessageType.text;

  @override
  Map<String, dynamic> getSpecificData() => {'content': content};

  @override
  Widget buildMessageWidget(BuildContext context) {
    return TextMessageWidget(message: this);
  }
}

class ImageMessage extends Message {
  final String imageUrl;
  final String? caption;
  final int width;
  final int height;

  const ImageMessage({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.timestamp,
    required super.status,
    required this.imageUrl,
    this.caption,
    required this.width,
    required this.height,
  });

  @override
  MessageType get messageType => MessageType.image;

  @override
  Map<String, dynamic> getSpecificData() => {
    'imageUrl': imageUrl,
    'caption': caption,
    'width': width,
    'height': height,
  };

  @override
  Widget buildMessageWidget(BuildContext context) {
    return ImageMessageWidget(message: this);
  }
}

// Polymorphic usage
class MessageRenderer {
  Widget renderMessage(Message message, BuildContext context) {
    // Polymorphism in action - each message type renders itself
    return message.buildMessageWidget(context);
  }

  List<Widget> renderMessages(List<Message> messages, BuildContext context) {
    return messages.map((message) => renderMessage(message, context)).toList();
  }
}
```

## Logical Flow & Code Clarity

### Clear Control Flow
```dart
// ✅ EXCELLENT: Clear, readable control flow with early returns
class MessageSender {
  Future<SendMessageResult> sendMessage(SendMessageRequest request) async {
    // Early validation and returns
    final validationResult = _validateRequest(request);
    if (!validationResult.isValid) {
      return SendMessageResult.failure(validationResult.errors);
    }

    final user = await _getCurrentUser();
    if (user == null) {
      return SendMessageResult.failure(['User not authenticated']);
    }

    if (!await _hasPermissionToSend(user, request.conversationId)) {
      return SendMessageResult.failure(['User lacks permission to send messages']);
    }

    // Main processing logic
    try {
      final message = await _createMessage(request, user);
      final processedMessage = await _processMessage(message);
      final savedMessage = await _saveMessage(processedMessage);

      await _notifyRecipients(savedMessage);
      await _updateConversationMetadata(savedMessage);

      return SendMessageResult.success(savedMessage);

    } on NetworkException catch (e) {
      return SendMessageResult.failure(['Network error: ${e.message}']);
    } on ValidationException catch (e) {
      return SendMessageResult.failure(['Validation error: ${e.message}']);
    } catch (e) {
      _logger.error('Unexpected error sending message: $e');
      return SendMessageResult.failure(['An unexpected error occurred']);
    }
  }

  // Clear, focused helper methods
  ValidationResult _validateRequest(SendMessageRequest request) {
    final errors = <String>[];

    if (request.content.trim().isEmpty) {
      errors.add('Message content cannot be empty');
    }

    if (request.content.length > MessageConstants.maxContentLength) {
      errors.add('Message content exceeds maximum length');
    }

    if (request.conversationId.isEmpty) {
      errors.add('Conversation ID is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
```

### Error Handling & Resource Management
```dart
// ✅ EXCELLENT: Comprehensive error handling with proper resource management
class MessageFileUploader {
  Future<UploadResult> uploadMessageFile(File file, String conversationId) async {
    FileInputStream? inputStream;
    HttpClient? httpClient;

    try {
      // Validate file
      final validationResult = await _validateFile(file);
      if (!validationResult.isValid) {
        return UploadResult.failure(validationResult.errors);
      }

      // Prepare upload
      inputStream = FileInputStream(file);
      httpClient = HttpClient();

      final uploadUrl = await _getUploadUrl(conversationId);
      final request = await httpClient.postUrl(Uri.parse(uploadUrl));

      // Set headers
      request.headers.set('Content-Type', 'application/octet-stream');
      request.headers.set('Content-Length', file.lengthSync().toString());

      // Upload with progress tracking
      final response = await _uploadWithProgress(request, inputStream);

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final uploadData = json.decode(responseBody);

        return UploadResult.success(
          fileUrl: uploadData['url'],
          fileId: uploadData['id'],
        );
      } else {
        return UploadResult.failure(['Upload failed with status: ${response.statusCode}']);
      }

    } on FileSystemException catch (e) {
      return UploadResult.failure(['File system error: ${e.message}']);
    } on SocketException catch (e) {
      return UploadResult.failure(['Network error: ${e.message}']);
    } on TimeoutException catch (e) {
      return UploadResult.failure(['Upload timeout: ${e.message}']);
    } catch (e) {
      _logger.error('Unexpected upload error: $e');
      return UploadResult.failure(['An unexpected error occurred during upload']);
    } finally {
      // Ensure resources are properly cleaned up
      await inputStream?.close();
      httpClient?.close();
    }
  }
}
```

### Interface Segregation Principle (ISP)
```dart
// ✅ EXCELLENT: Specific, focused interfaces
abstract class MessageReader {
  Future<Message?> getMessage(String messageId);
  Future<List<Message>> getMessages(String conversationId);
}

abstract class MessageWriter {
  Future<void> saveMessage(Message message);
  Future<void> updateMessage(String messageId, Message updatedMessage);
  Future<void> deleteMessage(String messageId);
}

abstract class MessageSearcher {
  Future<List<Message>> searchMessages(String query);
  Future<List<Message>> searchMessagesInConversation(String conversationId, String query);
}

// Implementations can choose which interfaces to implement
class ReadOnlyMessageRepository implements MessageReader {
  final ApiClient _apiClient;
  
  ReadOnlyMessageRepository(this._apiClient);
  
  @override
  Future<Message?> getMessage(String messageId) async {
    // Implementation
  }
  
  @override
  Future<List<Message>> getMessages(String conversationId) async {
    // Implementation
  }
}

class FullMessageRepository implements MessageReader, MessageWriter, MessageSearcher {
  // Implements all interfaces for full functionality
}
```

### Dependency Inversion Principle (DIP)
```dart
// ✅ EXCELLENT: Depend on abstractions, not concretions
abstract class MessageEncryptionService {
  Future<String> encrypt(String content, String key);
  Future<String> decrypt(String encryptedContent, String key);
}

abstract class MessageNotificationService {
  Future<void> notifyMessageReceived(Message message, List<User> recipients);
}

class MessageService {
  final MessageStorage _storage;
  final MessageEncryptionService _encryption;
  final MessageNotificationService _notification;
  
  MessageService({
    required MessageStorage storage,
    required MessageEncryptionService encryption,
    required MessageNotificationService notification,
  }) : _storage = storage,
       _encryption = encryption,
       _notification = notification;
  
  Future<Message> sendMessage(SendMessageRequest request) async {
    // Validate message
    final validationResult = MessageValidator.validate(request);
    if (!validationResult.isValid) {
      throw MessageValidationException(validationResult.errors.first);
    }
    
    // Create message
    final message = Message(
      id: _generateMessageId(),
      conversationId: request.conversationId,
      senderId: request.senderId,
      content: request.content,
      timestamp: DateTime.now(),
    );
    
    // Encrypt if needed
    final finalMessage = request.shouldEncrypt
        ? await _encryptMessage(message, request.encryptionKey!)
        : message;
    
    // Save message
    await _storage.saveMessage(finalMessage);
    
    // Notify recipients
    final recipients = await _getConversationRecipients(request.conversationId);
    await _notification.notifyMessageReceived(finalMessage, recipients);
    
    return finalMessage;
  }
}
```

## Design Patterns Implementation

### Repository Pattern (Enhanced)
```dart
// ✅ EXCELLENT: Complete repository pattern with caching and error handling
abstract class MessageRepository {
  Future<Either<Failure, Message>> getMessage(String messageId);
  Future<Either<Failure, List<Message>>> getMessages(String conversationId);
  Future<Either<Failure, Message>> sendMessage(SendMessageParams params);
  Stream<Message> watchNewMessages(String conversationId);
}

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final CacheManager _cacheManager;
  
  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required MessageLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _cacheManager = cacheManager;
  
  @override
  Future<Either<Failure, List<Message>>> getMessages(String conversationId) async {
    try {
      // Check cache first
      final cachedMessages = await _cacheManager.get<List<Message>>(
        'messages_$conversationId',
      );
      
      if (cachedMessages != null && !await _shouldRefreshCache(conversationId)) {
        return Right(cachedMessages);
      }
      
      if (await _networkInfo.isConnected) {
        // Fetch from remote
        final remoteMessages = await _remoteDataSource.getMessages(conversationId);
        
        // Cache the results
        await _cacheManager.put('messages_$conversationId', remoteMessages);
        
        // Update local storage
        await _localDataSource.cacheMessages(remoteMessages);
        
        return Right(remoteMessages);
      } else {
        // Fallback to local storage
        final localMessages = await _localDataSource.getCachedMessages(conversationId);
        return Right(localMessages);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
```
