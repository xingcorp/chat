---
inclusion: fileMatch
fileMatchPattern: "flutter_chat_app/lib/**/*{chat,message,conversation}*.dart"
---

# Chat Feature Implementation Guide

> Step-by-step guide to implement chat features following Clean Architecture

## 📁 Directory Structure

```
lib/
├── domain/
│   ├── entities/
│   │   ├── chat/
│   │   │   ├── message.dart
│   │   │   ├── conversation.dart
│   │   │   ├── conversation_member.dart
│   │   │   └── reaction.dart
│   │   └── user.dart
│   ├── repositories/
│   │   ├── message_repository.dart
│   │   └── conversation_repository.dart
│   └── usecases/
│       ├── chat/
│       │   ├── send_message.dart
│       │   ├── get_messages.dart
│       │   ├── mark_as_read.dart
│       │   ├── add_reaction.dart
│       │   ├── edit_message.dart
│       │   └── delete_message.dart
│       └── conversation/
│           ├── get_conversations.dart
│           ├── create_group.dart
│           └── edit_group.dart
├── data/
│   ├── models/
│   │   ├── chat/
│   │   │   ├── message_model.dart
│   │   │   ├── conversation_model.dart
│   │   │   └── reaction_model.dart
│   │   └── user_model.dart
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── message_remote_datasource.dart
│   │   │   ├── conversation_remote_datasource.dart
│   │   │   └── socket_datasource.dart
│   │   └── local/
│   │       ├── message_local_datasource.dart
│   │       └── conversation_local_datasource.dart
│   └── repositories/
│       ├── message_repository_impl.dart
│       └── conversation_repository_impl.dart
└── presentation/
    ├── blocs/
    │   ├── chat/
    │   │   ├── chat_bloc.dart
    │   │   ├── chat_event.dart
    │   │   └── chat_state.dart
    │   ├── conversation/
    │   │   ├── conversation_bloc.dart
    │   │   ├── conversation_event.dart
    │   │   └── conversation_state.dart
    │   └── typing/
    │       ├── typing_cubit.dart
    │       └── typing_state.dart
    ├── pages/
    │   ├── chat/
    │   │   ├── chat_list_page.dart
    │   │   ├── chat_detail_page.dart
    │   │   └── group_create_page.dart
    │   └── conversation/
    │       └── conversation_settings_page.dart
    └── widgets/
        ├── chat/
        │   ├── message_bubble.dart
        │   ├── message_input.dart
        │   ├── typing_indicator.dart
        │   ├── reaction_picker.dart
        │   └── message_reply_preview.dart
        └── conversation/
            ├── conversation_tile.dart
            └── member_list.dart
```

## 🎯 Step 1: Domain Layer

### 1.1 Entities

```dart
// lib/domain/entities/chat/message.dart
@immutable
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final User sender;
  final MessageType type;
  final String? content;
  final List<String>? mediaUrls;
  final String? fileName;
  final String? replyToId;
  final Message? replyTo;
  final String? forwardedFromId;
  final Message? forwardedFrom;
  final List<Reaction> reactions;
  final List<String> readerIds;
  final List<User> mentions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageStatus status; // local, sending, sent, delivered, read, failed
  
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.sender,
    required this.type,
    this.content,
    this.mediaUrls,
    this.fileName,
    this.replyToId,
    this.replyTo,
    this.forwardedFromId,
    this.forwardedFrom,
    this.reactions = const [],
    this.readerIds = const [],
    this.mentions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.status = MessageStatus.local,
  });
  
  @override
  List<Object?> get props => [
    id,
    conversationId,
    content,
    reactions,
    readerIds,
    status,
    updatedAt,
  ];
  
  Message copyWith({
    String? content,
    List<Reaction>? reactions,
    List<String>? readerIds,
    MessageStatus? status,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      sender: sender,
      type: type,
      content: content ?? this.content,
      mediaUrls: mediaUrls,
      fileName: fileName,
      replyToId: replyToId,
      replyTo: replyTo,
      forwardedFromId: forwardedFromId,
      forwardedFrom: forwardedFrom,
      reactions: reactions ?? this.reactions,
      readerIds: readerIds ?? this.readerIds,
      mentions: mentions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: status ?? this.status,
    );
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  voiceNote,
  sticker,
}

enum MessageStatus {
  local,      // Only in local DB
  sending,    // Being sent to server
  sent,       // Sent to server
  delivered,  // Delivered to recipient
  read,       // Read by recipient
  failed,     // Failed to send
}

// lib/domain/entities/chat/reaction.dart
@immutable
class Reaction extends Equatable {
  final String emoji;
  final List<String> userIds;
  
  const Reaction({
    required this.emoji,
    required this.userIds,
  });
  
  @override
  List<Object> get props => [emoji, userIds];
}

// lib/domain/entities/chat/conversation.dart
@immutable
class Conversation extends Equatable {
  final String id;
  final ConversationType type;
  final String? name;
  final String? avatarUrl;
  final String? description;
  final GroupType? groupType;
  final String creatorId;
  final List<ConversationMember> members;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isHidden;
  final DateTime createdAt;
  
  const Conversation({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.description,
    this.groupType,
    required this.creatorId,
    required this.members,
    this.lastMessageId,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isHidden = false,
    required this.createdAt,
  });
  
  // Get partner in direct conversation
  User? getPartner(String currentUserId) {
    if (type != ConversationType.direct) return null;
    return members
        .firstWhere((m) => m.userId != currentUserId)
        .user;
  }
  
  // Get display name
  String getDisplayName(String currentUserId) {
    if (type == ConversationType.group) {
      return name ?? 'Unnamed Group';
    }
    return getPartner(currentUserId)?.displayName ?? 'Unknown';
  }
  
  // Get display avatar
  String? getDisplayAvatar(String currentUserId) {
    if (type == ConversationType.group) {
      return avatarUrl;
    }
    return getPartner(currentUserId)?.avatarUrl;
  }
  
  @override
  List<Object?> get props => [
    id,
    name,
    lastMessageId,
    lastMessageAt,
    unreadCount,
    isHidden,
  ];
}

enum ConversationType {
  direct,
  group,
}

enum GroupType {
  private,
  public,
}

// lib/domain/entities/chat/conversation_member.dart
@immutable
class ConversationMember extends Equatable {
  final String id;
  final String userId;
  final User user;
  final String conversationId;
  final bool isAdmin;
  final String? lastReadMessageId;
  final DateTime viewMessagesFrom;
  final DateTime joinedAt;
  
  const ConversationMember({
    required this.id,
    required this.userId,
    required this.user,
    required this.conversationId,
    this.isAdmin = false,
    this.lastReadMessageId,
    required this.viewMessagesFrom,
    required this.joinedAt,
  });
  
  @override
  List<Object?> get props => [
    id,
    userId,
    isAdmin,
    lastReadMessageId,
  ];
}
```

### 1.2 Repository Interfaces

```dart
// lib/domain/repositories/message_repository.dart
abstract class IMessageRepository {
  /// Get messages for conversation (paginated)
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    int limit = 50,
    String? lastMessageId,
    DateTime? from,
  });
  
  /// Send new message
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    String? receiverId,
    required MessageType type,
    String? content,
    List<String>? mediaUrls,
    String? fileName,
    String? replyToId,
    String? forwardedFromId,
  });
  
  /// Mark messages as read
  Future<Either<Failure, void>> markAsRead({
    required String conversationId,
    required int count,
  });
  
  /// Add/remove reaction
  Future<Either<Failure, Message>> updateReaction({
    required String messageId,
    required String emoji,
    required bool add,
  });
  
  /// Edit message
  Future<Either<Failure, Message>> editMessage({
    required String messageId,
    required String content,
  });
  
  /// Delete message
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
  });
  
  /// Stream of new messages
  Stream<Message> get messageStream;
  
  /// Stream of message updates (edit, delete, reaction)
  Stream<MessageUpdate> get messageUpdateStream;
}

// lib/domain/repositories/conversation_repository.dart
abstract class IConversationRepository {
  /// Get user's conversations
  Future<Either<Failure, List<Conversation>>> getConversations({
    int page = 0,
    int size = 25,
    String? keyword,
    ConversationType? type,
  });
  
  /// Get conversation details
  Future<Either<Failure, Conversation>> getConversation({
    required String conversationId,
  });
  
  /// Create group
  Future<Either<Failure, Conversation>> createGroup({
    required String name,
    String? avatarUrl,
    String? description,
    GroupType groupType = GroupType.private,
    required List<String> memberIds,
  });
  
  /// Edit group
  Future<Either<Failure, Conversation>> editGroup({
    required String conversationId,
    String? name,
    String? avatarUrl,
    String? description,
    GroupType? groupType,
    List<String>? memberIds,
    List<String>? adminIds,
  });
  
  /// Leave group
  Future<Either<Failure, void>> leaveGroup({
    required String conversationId,
  });
  
  /// Hide conversation
  Future<Either<Failure, void>> hideConversation({
    required String conversationId,
  });
  
  /// Clear chat history
  Future<Either<Failure, void>> clearHistory({
    required String conversationId,
  });
  
  /// Stream of conversation updates
  Stream<ConversationUpdate> get conversationUpdateStream;
}
```

### 1.3 Use Cases

```dart
// lib/domain/usecases/chat/send_message.dart
@injectable
class SendMessage implements UseCase<Message, SendMessageParams> {
  final IMessageRepository _repository;
  
  SendMessage(this._repository);
  
  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) {
    return _repository.sendMessage(
      conversationId: params.conversationId,
      receiverId: params.receiverId,
      type: params.type,
      content: params.content,
      mediaUrls: params.mediaUrls,
      fileName: params.fileName,
      replyToId: params.replyToId,
      forwardedFromId: params.forwardedFromId,
    );
  }
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String? receiverId;
  final MessageType type;
  final String? content;
  final List<String>? mediaUrls;
  final String? fileName;
  final String? replyToId;
  final String? forwardedFromId;
  
  const SendMessageParams({
    required this.conversationId,
    this.receiverId,
    required this.type,
    this.content,
    this.mediaUrls,
    this.fileName,
    this.replyToId,
    this.forwardedFromId,
  });
  
  @override
  List<Object?> get props => [
    conversationId,
    receiverId,
    type,
    content,
    mediaUrls,
    fileName,
    replyToId,
    forwardedFromId,
  ];
}

// lib/domain/usecases/chat/get_messages.dart
@injectable
class GetMessages implements UseCase<List<Message>, GetMessagesParams> {
  final IMessageRepository _repository;
  
  GetMessages(this._repository);
  
  @override
  Future<Either<Failure, List<Message>>> call(GetMessagesParams params) {
    return _repository.getMessages(
      conversationId: params.conversationId,
      limit: params.limit,
      lastMessageId: params.lastMessageId,
      from: params.from,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String conversationId;
  final int limit;
  final String? lastMessageId;
  final DateTime? from;
  
  const GetMessagesParams({
    required this.conversationId,
    this.limit = 50,
    this.lastMessageId,
    this.from,
  });
  
  @override
  List<Object?> get props => [conversationId, limit, lastMessageId, from];
}
```

## 🎯 Step 2: Data Layer

### 2.1 Models

```dart
// lib/data/models/chat/message_model.dart
@collection
class MessageModel {
  @Id()
  late int id;
  
  @Index()
  late String serverId;
  
  @Index()
  late String conversationId;
  
  late String senderId;
  
  @Enumerated(EnumType.name)
  late MessageType type;
  
  String? content;
  List<String>? mediaUrls;
  String? fileName;
  String? replyToId;
  String? forwardedFromId;
  List<ReactionModel>? reactions;
  List<String>? readerIds;
  List<String>? mentionIds;
  
  @Index()
  late DateTime createdAt;
  
  late DateTime updatedAt;
  
  @Enumerated(EnumType.name)
  late MessageStatus status;
  
  // Convert to entity
  Message toEntity({
    required User sender,
    Message? replyTo,
    Message? forwardedFrom,
    List<User> mentions = const [],
  }) {
    return Message(
      id: serverId,
      conversationId: conversationId,
      senderId: senderId,
      sender: sender,
      type: type,
      content: content,
      mediaUrls: mediaUrls,
      fileName: fileName,
      replyToId: replyToId,
      replyTo: replyTo,
      forwardedFromId: forwardedFromId,
      forwardedFrom: forwardedFrom,
      reactions: reactions?.map((r) => r.toEntity()).toList() ?? [],
      readerIds: readerIds ?? [],
      mentions: mentions,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
    );
  }
  
  // Create from entity
  static MessageModel fromEntity(Message entity) {
    return MessageModel()
      ..serverId = entity.id
      ..conversationId = entity.conversationId
      ..senderId = entity.senderId
      ..type = entity.type
      ..content = entity.content
      ..mediaUrls = entity.mediaUrls
      ..fileName = entity.fileName
      ..replyToId = entity.replyToId
      ..forwardedFromId = entity.forwardedFromId
      ..reactions = entity.reactions.map((r) => ReactionModel.fromEntity(r)).toList()
      ..readerIds = entity.readerIds
      ..mentionIds = entity.mentions.map((u) => u.id).toList()
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..status = entity.status;
  }
  
  // Create from GraphQL response
  static MessageModel fromJson(Map<String, dynamic> json) {
    return MessageModel()
      ..serverId = json['id']
      ..conversationId = json['conversationId']
      ..senderId = json['senderId']
      ..type = MessageType.values.byName(json['type'].toString().toLowerCase())
      ..content = json['message']
      ..mediaUrls = (json['urls'] as List?)?.cast<String>()
      ..fileName = json['fileName']
      ..replyToId = json['replyMessageId']
      ..forwardedFromId = json['forwardedFromMessageId']
      ..reactions = (json['reactions'] as List?)
          ?.map((r) => ReactionModel.fromJson(r))
          .toList()
      ..readerIds = (json['readerIds'] as List?)?.cast<String>()
      ..mentionIds = (json['mentionTo'] as List?)
          ?.map((u) => u['id'] as String)
          .toList()
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt'])
      ..status = MessageStatus.sent;
  }
}

@embedded
class ReactionModel {
  late String emoji;
  late List<String> userIds;
  
  Reaction toEntity() {
    return Reaction(emoji: emoji, userIds: userIds);
  }
  
  static ReactionModel fromEntity(Reaction entity) {
    return ReactionModel()
      ..emoji = entity.emoji
      ..userIds = entity.userIds;
  }
  
  static ReactionModel fromJson(Map<String, dynamic> json) {
    return ReactionModel()
      ..emoji = json['code']
      ..userIds = (json['reactorIds'] as List).cast<String>();
  }
}
```

### 2.2 Remote Data Source

```dart
// lib/data/datasources/remote/message_remote_datasource.dart
@injectable
class MessageRemoteDataSource {
  final GraphQLClient _client;
  final SocketDataSource _socket;
  
  MessageRemoteDataSource(this._client, this._socket);
  
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 50,
    String? lastMessageId,
    DateTime? from,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql('''
          query MessageList(\$filter: ChatMessageGetListFilter!) {
            messageList(filter: \$filter) {
              messages {
                id
                conversationId
                senderId
                sender {
                  id
                  fullname
                  imageUrls
                }
                type
                message
                urls
                fileName
                replyMessageId
                replyMessage {
                  id
                  message
                  sender {
                    id
                    fullname
                  }
                }
                reactions {
                  code
                  reactorIds
                }
                readerIds
                mentionTo {
                  id
                  fullname
                }
                createdAt
                updatedAt
              }
            }
          }
        '''),
        variables: {
          'filter': {
            'conversationId': conversationId,
            'size': limit,
            'order': 'DESC',
            if (lastMessageId != null && from != null)
              'lastKey': {
                'conversationId': conversationId,
                'createdAt': from.millisecondsSinceEpoch,
              },
            if (from != null) 'from': from.millisecondsSinceEpoch,
          },
        },
      ),
    );
    
    if (result.hasException) {
      throw ServerException(message: result.exception.toString());
    }
    
    final messages = result.data?['messageList']['messages'] as List;
    return messages.map((json) => MessageModel.fromJson(json)).toList();
  }
  
  Future<MessageModel> sendMessage({
    required String conversationId,
    String? receiverId,
    required MessageType type,
    String? content,
    List<String>? mediaUrls,
    String? fileName,
    String? replyToId,
    String? forwardedFromId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql('''
          mutation MessageAdd(\$input: ChatAddMessageInput!) {
            messageAdd(input: \$input) {
              id
              conversationId
              senderId
              sender {
                id
                fullname
                imageUrls
              }
              type
              message
              urls
              fileName
              replyMessageId
              reactions {
                code
                reactorIds
              }
              readerIds
              createdAt
              updatedAt
            }
          }
        '''),
        variables: {
          'input': {
            if (conversationId.isNotEmpty) 'conversationId': conversationId,
            if (receiverId != null) 'receiverId': receiverId,
            'type': type.name.toUpperCase(),
            if (content != null) 'message': content,
            if (mediaUrls != null) 'urls': mediaUrls,
            if (fileName != null) 'fileName': fileName,
            if (replyToId != null) 'replyMessageId': replyToId,
            if (forwardedFromId != null) 'forwardedFromMessageId': forwardedFromId,
          },
        },
      ),
    );
    
    if (result.hasException) {
      throw ServerException(message: result.exception.toString());
    }
    
    return MessageModel.fromJson(result.data!['messageAdd']);
  }
  
  // Stream of new messages from Socket.IO
  Stream<MessageModel> get messageStream {
    return _socket.on<Map<String, dynamic>>('message:sent').map((data) {
      return MessageModel.fromJson(data['message']);
    });
  }
}

// lib/data/datasources/remote/socket_datasource.dart
@singleton
class SocketDataSource {
  late IO.Socket _socket;
  final _controllers = <String, StreamController<dynamic>>{};
  
  Future<void> connect(String token) async {
    _socket = IO.io(
      AppConfig.socketUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .setReconnection(true)
        .build(),
    );
    
    _socket.connect();
  }
  
  Stream<T> on<T>(String event) {
    if (!_controllers.containsKey(event)) {
      _controllers[event] = StreamController<T>.broadcast();
      _socket.on(event, (data) {
        _controllers[event]!.add(data as T);
      });
    }
    return _controllers[event]!.stream as Stream<T>;
  }
  
  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }
  
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _socket.disconnect();
  }
}
```

## 🎯 Step 3: Presentation Layer

### 3.1 BLoC

```dart
// lib/presentation/blocs/chat/chat_bloc.dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessages _getMessages;
  final SendMessage _sendMessage;
  final MarkAsRead _markAsRead;
  final IMessageRepository _repository;
  
  StreamSubscription? _messageSubscription;
  
  ChatBloc({
    required GetMessages getMessages,
    required SendMessage sendMessage,
    required MarkAsRead markAsRead,
    required IMessageRepository repository,
  }) : _getMessages = getMessages,
       _sendMessage = sendMessage,
       _markAsRead = markAsRead,
       _repository = repository,
       super(const ChatState.initial()) {
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatNewMessageReceived>(_onNewMessageReceived);
    
    // Listen to real-time messages
    _messageSubscription = _repository.messageStream.listen(
      (message) => add(ChatEvent.newMessageReceived(message)),
    );
  }
  
  Future<void> _onLoadMessages(
    ChatLoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (event.loadMore) {
      emit(state.copyWith(isLoadingMore: true));
    } else {
      emit(const ChatState.loading());
    }
    
    final result = await _getMessages(GetMessagesParams(
      conversationId: event.conversationId,
      limit: event.limit,
      lastMessageId: event.lastMessageId,
    ));
    
    result.fold(
      (failure) => emit(ChatState.error(failure: failure)),
      (messages) {
        final allMessages = event.loadMore
            ? [...state.messages, ...messages]
            : messages;
        
        emit(ChatState.loaded(
          messages: allMessages,
          hasMore: messages.length >= event.limit,
        ));
      },
    );
  }
  
  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistic update
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: event.conversationId,
      senderId: event.senderId,
      sender: event.sender,
      type: event.type,
      content: event.content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    emit(state.copyWith(
      messages: [tempMessage, ...state.messages],
    ));
    
    final result = await _sendMessage(SendMessageParams(
      conversationId: event.conversationId,
      type: event.type,
      content: event.content,
      mediaUrls: event.mediaUrls,
      replyToId: event.replyToId,
    ));
    
    result.fold(
      (failure) {
        // Update temp message to failed
        final updatedMessages = state.messages.map((m) {
          if (m.id == tempMessage.id) {
            return m.copyWith(status: MessageStatus.failed);
          }
          return m;
        }).toList();
        
        emit(state.copyWith(messages: updatedMessages));
      },
      (message) {
        // Replace temp message with real one
        final updatedMessages = state.messages.map((m) {
          if (m.id == tempMessage.id) {
            return message;
          }
          return m;
        }).toList();
        
        emit(state.copyWith(messages: updatedMessages));
      },
    );
  }
  
  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
```

### 3.2 UI

```dart
// lib/presentation/pages/chat/chat_detail_page.dart
class ChatDetailPage extends StatelessWidget {
  final String conversationId;
  
  const ChatDetailPage({
    super.key,
    required this.conversationId,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChatBloc>()
        ..add(ChatEvent.loadMessages(conversationId: conversationId)),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ConversationBloc, ConversationState>(
            builder: (context, state) {
              return state.maybeWhen(
                loaded: (conversation) => Text(
                  conversation.getDisplayName(currentUserId),
                ),
                orElse: () => const Text('Chat'),
              );
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const SizedBox(),
                    loading: () => const LoadingIndicator(),
                    loaded: (messages, hasMore) => MessageList(
                      messages: messages,
                      hasMore: hasMore,
                      onLoadMore: () {
                        context.read<ChatBloc>().add(
                          ChatEvent.loadMessages(
                            conversationId: conversationId,
                            loadMore: true,
                            lastMessageId: messages.last.id,
                          ),
                        );
                      },
                    ),
                    error: (failure) => ErrorView(
                      message: failure.message,
                      onRetry: () {
                        context.read<ChatBloc>().add(
                          ChatEvent.loadMessages(conversationId: conversationId),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const MessageInput(),
          ],
        ),
      ),
    );
  }
}
```

---

**Next**: Implement offline sync, typing indicators, reactions, and media handling
