# API Integration Rules - NestJS Backend Synchronization

**Type**: Always  
**Description**: Critical rules for maintaining data model synchronization between Flutter frontend and NestJS backend

## Backend API Structure Analysis

### GraphQL Schema Mapping

#### User Entity Synchronization
```dart
// Backend: OfficeUser → Flutter: UserModel
class UserModel {
  final String serverId;     // ← OfficeUser.id (UUID)
  final String username;     // ← OfficeUser.username
  final String displayName;  // ← OfficeUser.fullname
  final String? avatarUrl;   // ← OfficeUser.imageUrls[0]
  final String? email;       // ← OfficeUser.email
  final bool isOnline;       // ← OfficeUser.status == ObjectStatus.Active
  final DateTime lastSeen;   // ← OfficeUser.updatedAt
  final String? statusMessage; // ← OfficeUser.note
  final List<String> roles;  // ← OfficeUser.metadata (parsed)
}

// Mapping implementation
class UserMapper {
  static UserModel fromBackendEntity(OfficeUser backendUser) {
    return UserModel(
      serverId: backendUser.id,
      username: backendUser.username ?? backendUser.fullname,
      displayName: backendUser.fullname,
      avatarUrl: backendUser.imageUrls?.isNotEmpty == true 
          ? backendUser.imageUrls!.first 
          : null,
      email: backendUser.email,
      isOnline: backendUser.status == ObjectStatus.Active,
      lastSeen: backendUser.updatedAt ?? DateTime.now(),
      statusMessage: backendUser.note,
      roles: _parseMetadata(backendUser.metadata),
    );
  }
}
```

#### Conversation Entity Synchronization
```dart
// Backend: OfficeChatConversation → Flutter: ChatModel
class ChatModel {
  final String serverId;           // ← OfficeChatConversation.id
  final String? name;              // ← OfficeChatConversation.name
  final ChatType type;             // ← OfficeChatConversation.type
  final String? description;       // ← OfficeChatConversation.description
  final String? avatarUrl;         // ← OfficeChatConversation.imgUrl
  final List<String> participantIds; // ← members[].userId
  final String? adminId;           // ← OfficeChatConversation.creatorId
  final DateTime createdAt;        // ← OfficeChatConversation.createdAt
  final DateTime? lastMessageAt;   // ← OfficeChatConversation.lastMessageAt
  final String? lastMessageId;     // ← OfficeChatConversation.lastMessageId
}

// Type mapping
enum ChatType {
  direct,   // ← ChatConversationType.Direct
  group,    // ← ChatConversationType.Group
  channel,  // Custom type for broadcast channels
}

class ChatMapper {
  static ChatModel fromBackendEntity(OfficeChatConversation conversation) {
    return ChatModel(
      serverId: conversation.id,
      name: conversation.name,
      type: _mapChatType(conversation.type),
      description: conversation.description,
      avatarUrl: conversation.imgUrl,
      participantIds: conversation.members
          ?.map((member) => member.userId)
          .toList() ?? [],
      adminId: conversation.creatorId,
      createdAt: conversation.createdAt,
      lastMessageAt: conversation.lastMessageAt,
      lastMessageId: conversation.lastMessageId,
    );
  }
  
  static ChatType _mapChatType(ChatConversationType backendType) {
    switch (backendType) {
      case ChatConversationType.Direct:
        return ChatType.direct;
      case ChatConversationType.Group:
        return ChatType.group;
      default:
        return ChatType.direct;
    }
  }
}
```

#### Message Entity Synchronization
```dart
// Backend: OfficeChatMessage → Flutter: MessageModel
class MessageModel {
  final String localId;        // ← OfficeChatMessage.id
  final String chatId;         // ← OfficeChatMessage.conversationId
  final String senderId;       // ← OfficeChatMessage.senderId
  final String content;        // ← OfficeChatMessage.message
  final MessageType type;      // ← OfficeChatMessage.type
  final DateTime createdAt;    // ← OfficeChatMessage.createdAt (timestamp)
  final DateTime? editedAt;    // ← OfficeChatMessage.editAt (timestamp)
  final DateTime? deletedAt;   // ← OfficeChatMessage.deletedAt (timestamp)
  final List<String> readBy;   // ← OfficeChatMessage.readerIds
  final List<String> urls;     // ← OfficeChatMessage.urls
  final String? fileName;      // ← OfficeChatMessage.fileName
  final String? replyToId;     // ← OfficeChatMessage.replyMessageId
}

// Message type mapping
enum MessageType {
  text,     // ← ChatMessageType.Text
  image,    // ← ChatMessageType.Image
  file,     // ← ChatMessageType.File
  audio,    // ← ChatMessageType.Audio
  video,    // ← ChatMessageType.Video
}

class MessageMapper {
  static MessageModel fromBackendEntity(OfficeChatMessage backendMessage) {
    return MessageModel(
      localId: backendMessage.id,
      chatId: backendMessage.conversationId,
      senderId: backendMessage.senderId,
      content: backendMessage.message ?? '',
      type: _mapMessageType(backendMessage.type),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (backendMessage.createdAt * 1000).toInt(),
      ),
      editedAt: backendMessage.editAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (backendMessage.editAt! * 1000).toInt(),
            )
          : null,
      deletedAt: backendMessage.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (backendMessage.deletedAt! * 1000).toInt(),
            )
          : null,
      readBy: backendMessage.readerIds ?? [],
      urls: backendMessage.urls ?? [],
      fileName: backendMessage.fileName,
      replyToId: backendMessage.replyMessageId,
    );
  }
}
```

## GraphQL Integration Patterns

### Query Implementation
```dart
class ChatRemoteDataSource {
  final GraphQLClient _client;
  
  Future<List<ChatModel>> getChats() async {
    const query = '''
      query GetChats(\$limit: Int, \$offset: Int) {
        conversations(limit: \$limit, offset: \$offset) {
          id
          name
          type
          description
          imgUrl
          createdAt
          lastMessageAt
          lastMessageId
          creator {
            id
            fullname
          }
          members {
            userId
            user {
              id
              fullname
              imageUrls
            }
          }
        }
      }
    ''';
    
    final result = await _client.query(QueryOptions(
      document: gql(query),
      variables: {'limit': 50, 'offset': 0},
    ));
    
    if (result.hasException) {
      throw ServerException(
        message: result.exception?.toString() ?? 'Unknown error',
        statusCode: 500,
      );
    }
    
    final conversations = result.data?['conversations'] as List<dynamic>?;
    return conversations
        ?.map((json) => ChatMapper.fromBackendEntity(
              OfficeChatConversation.fromJson(json),
            ))
        .toList() ?? [];
  }
}
```

### Mutation Implementation
```dart
class MessageRemoteDataSource {
  Future<MessageModel> sendMessage(SendMessageParams params) async {
    const mutation = '''
      mutation SendMessage(
        \$conversationId: String!,
        \$message: String!,
        \$type: ChatMessageType!,
        \$urls: [String!],
        \$fileName: String
      ) {
        sendMessage(
          conversationId: \$conversationId,
          message: \$message,
          type: \$type,
          urls: \$urls,
          fileName: \$fileName
        ) {
          id
          conversationId
          senderId
          message
          type
          createdAt
          urls
          fileName
          sender {
            id
            fullname
            imageUrls
          }
        }
      }
    ''';
    
    final result = await _client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {
        'conversationId': params.chatId,
        'message': params.content,
        'type': _mapToBackendType(params.type),
        'urls': params.urls,
        'fileName': params.fileName,
      },
    ));
    
    if (result.hasException) {
      throw ServerException(
        message: result.exception?.toString() ?? 'Failed to send message',
        statusCode: 500,
      );
    }
    
    final messageData = result.data?['sendMessage'];
    return MessageMapper.fromBackendEntity(
      OfficeChatMessage.fromJson(messageData),
    );
  }
}
```

## Error Handling & Status Codes

### API Error Response Mapping
```dart
class ApiErrorHandler {
  static Failure handleGraphQLError(OperationException exception) {
    final graphQLErrors = exception.graphqlErrors;
    final linkException = exception.linkException;
    
    if (graphQLErrors.isNotEmpty) {
      final error = graphQLErrors.first;
      final extensions = error.extensions;
      
      if (extensions != null) {
        final statusCode = extensions['statusCode'] as int?;
        
        switch (statusCode) {
          case 401:
            return AuthFailure('Authentication required');
          case 403:
            return AuthFailure('Access denied');
          case 404:
            return ServerFailure('Resource not found', 404);
          case 429:
            return ServerFailure('Rate limit exceeded', 429);
          default:
            return ServerFailure(error.message, statusCode ?? 500);
        }
      }
      
      return ServerFailure(error.message, 500);
    }
    
    if (linkException != null) {
      if (linkException is NetworkException) {
        return NetworkFailure('Network connection failed');
      }
      if (linkException is ServerException) {
        return ServerFailure(
          'Server error: ${linkException.response.statusCode}',
          linkException.response.statusCode ?? 500,
        );
      }
    }
    
    return ServerFailure('Unknown error occurred', 500);
  }
}
```

## Authentication & Authorization

### JWT Token Management
```dart
class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request
        final clonedRequest = await _retryRequest(err.requestOptions);
        handler.resolve(clonedRequest);
        return;
      }
    }
    handler.next(err);
  }
}
```

## Real-time Synchronization

### WebSocket Event Mapping
```dart
class WebSocketService {
  void _handleIncomingMessage(Map<String, dynamic> data) {
    final eventType = data['type'] as String;
    
    switch (eventType) {
      case 'message_received':
        final messageData = data['data'];
        final message = MessageMapper.fromBackendEntity(
          OfficeChatMessage.fromJson(messageData),
        );
        _messageController.add(message);
        break;
        
      case 'message_read':
        final readData = data['data'];
        _messageReadController.add(MessageReadEvent(
          messageId: readData['messageId'],
          userId: readData['userId'],
          readAt: DateTime.parse(readData['readAt']),
        ));
        break;
        
      case 'user_typing':
        final typingData = data['data'];
        _typingController.add(TypingEvent(
          conversationId: typingData['conversationId'],
          userId: typingData['userId'],
          isTyping: typingData['isTyping'],
        ));
        break;
    }
  }
}
```

## Validation & Data Integrity

### Model Validation
```dart
extension MessageModelValidation on MessageModel {
  bool get isValid {
    return localId.isNotEmpty &&
           chatId.isNotEmpty &&
           senderId.isNotEmpty &&
           content.isNotEmpty &&
           createdAt.isBefore(DateTime.now().add(Duration(minutes: 1)));
  }
  
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (localId.isEmpty) errors.add('Message ID cannot be empty');
    if (chatId.isEmpty) errors.add('Chat ID cannot be empty');
    if (senderId.isEmpty) errors.add('Sender ID cannot be empty');
    if (content.isEmpty && type == MessageType.text) {
      errors.add('Text message content cannot be empty');
    }
    
    return errors;
  }
}
```
