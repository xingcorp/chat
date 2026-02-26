---
inclusion: fileMatch
fileMatchPattern: "flutter_chat_app/lib/**/*chat*.dart"
---

# Chat API Integration Guide

> **Backend API**: NestJS GraphQL + Socket.IO
> **Real-time**: Socket.IO events for messages, typing, reactions
> **Offline**: Isar database with sync queue

## 🔌 API Endpoints Overview

### GraphQL Mutations
- `messageAdd` - Send new message
- `messageUpdate` - Edit/delete message
- `messageUpdateReaction` - Add/remove reaction
- `messageUpdateRead` - Mark messages as read
- `groupCreate` - Create group chat
- `groupEdit` - Edit group (name, members, admins)
- `leaveConversation` - Leave group
- `deleteConversation` - Hide conversation
- `deleteHistory` - Clear chat history

### GraphQL Queries
- `messageList` - Get messages for conversation (paginated)
- `conversationList` - Get user's conversations
- `conversationDetail` - Get conversation details

### Socket.IO Events

**Client → Server:**
- `message:typing` - User is typing
- `message:file:upload` - Upload file
- `conversation:joined` - Join conversation room
- `conversation:leaved` - Leave conversation room

**Server → Client:**
- `message:sent` - New message received
- `message:read` - Message read by someone
- `message:reaction` - Reaction added/removed
- `message:edit` - Message edited
- `message:delete` - Message deleted
- `message:typing` - Someone is typing
- `conversation:joined` - Added to conversation
- `conversation:leaved` - Removed from conversation

## 📊 Data Models

### Message Types
```dart
enum ChatMessageType {
  text,      // TEXT
  image,     // IMAGE
  video,     // VIDEO
  location,  // LOCATION
  call,      // CALL
  voiceNote, // VOICE_NOTE
  doc,       // DOC
  audio,     // AUDIO
  sticker,   // STICKER
}
```

### Message Structure
```dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final User sender;
  final ChatMessageType type;
  final String? message;          // Text content
  final List<String>? urls;       // Media URLs
  final String? fileName;         // File name
  final String? replyMessageId;   // Reply to message
  final Message? replyMessage;    // Populated reply
  final String? forwardedFromMessageId;
  final Message? forwardedFromMessage;
  final List<Reaction>? reactions; // Message reactions
  final List<String>? readerIds;   // Who read this
  final List<User>? mentionTo;     // Mentioned users
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Reaction {
  final String code;              // Emoji code
  final List<String> reactorIds;  // User IDs who reacted
}
```

### Conversation Structure
```dart
enum ChatConversationType {
  direct,  // Direct message (1-1)
  group,   // Group chat
}

enum ChatConversationGroupType {
  private, // Private group
  public,  // Public group
}

class Conversation {
  final String id;
  final ChatConversationType type;
  final String? name;             // Group name (null for direct)
  final String? imgUrl;           // Group avatar
  final String? description;      // Group description
  final ChatConversationGroupType? groupType;
  final String creatorId;
  final User creator;
  final List<ConversationMember> members;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Personal data (from member)
  final ConversationMember? personalConversation;
}

class ConversationMember {
  final String id;
  final String userId;
  final User user;
  final String conversationId;
  final bool admin;               // Is admin (for groups)
  final int unreadCount;          // Unread message count
  final String? lastMessageReadId;
  final bool hide;                // Conversation hidden
  final DateTime viewMessagesFrom; // Can only see messages after this
  final DateTime createdAt;
}
```

## 🔄 GraphQL Operations

### Send Message
```graphql
mutation MessageAdd($input: ChatAddMessageInput!) {
  messageAdd(input: $input) {
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
    forwardedFromMessageId
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

# Variables
{
  "input": {
    "conversationId": "uuid",      # OR receiverId for direct
    "receiverId": "uuid",          # For new direct message
    "type": "TEXT",
    "message": "Hello @[userId] world",
    "urls": ["https://..."],       # For media messages
    "fileName": "document.pdf",    # For file messages
    "replyMessageId": "uuid",      # Optional
    "forwardedFromMessageId": "uuid" # Optional
  }
}
```

### Get Messages (Paginated)
```graphql
query MessageList($filter: ChatMessageGetListFilter!) {
  messageList(filter: $filter) {
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
    }
    lastKey {
      conversationId
      createdAt
    }
  }
}

# Variables
{
  "filter": {
    "conversationId": "uuid",
    "size": 50,
    "order": "DESC",               # DESC = newest first
    "lastKey": {                   # For pagination
      "conversationId": "uuid",
      "createdAt": 1234567890
    },
    "type": "TEXT",                # Optional filter
    "from": 1234567890             # Only messages after this timestamp
  }
}
```

### Get Conversations
```graphql
query ConversationList($filter: ChatConversationListFilter!) {
  conversationList(filter: $filter) {
    conversations {
      id
      type
      name
      imgUrl
      description
      groupType
      creator {
        id
        fullname
      }
      members {
        id
        userId
        user {
          id
          fullname
          imageUrls
        }
        admin
        unreadCount
        lastMessageReadId
        hide
        viewMessagesFrom
      }
      lastMessageId
      lastMessageAt
      personalConversation {
        unreadCount
        lastMessageReadId
        hide
      }
    }
    total
  }
}

# Variables
{
  "filter": {
    "page": 0,
    "size": 25,
    "keyword": "search term",      # Optional
    "type": "Group"                # Optional: Direct or Group
  }
}
```

### Mark as Read
```graphql
mutation MessageUpdateRead($args: ChatMessageUpdateReadArgs!) {
  messageUpdateRead(args: $args) {
    conversationId
    readCount
  }
}

# Variables
{
  "args": {
    "conversationId": "uuid",
    "readCount": 5                 # Number of messages to mark as read
                                   # Use 1000000 to mark all as read
  }
}
```

### Add/Remove Reaction
```graphql
mutation MessageUpdateReaction($args: ChatMessageUpdateReactionArgs!) {
  messageUpdateReaction(args: $args) {
    id
    reactions {
      code
      reactorIds
    }
  }
}

# Variables
{
  "args": {
    "messageId": "uuid",
    "code": "👍",                  # Emoji
    "act": 1                       # 1 = ADD, 0 = REVOKE
  }
}
```

### Edit/Delete Message
```graphql
mutation MessageUpdate($args: ChatMessageUpdateArgs!) {
  messageUpdate(args: $args) {
    id
    message
    updatedAt
  }
}

# Variables
{
  "args": {
    "messageId": "uuid",
    "act": 1,                      # 1 = EDIT, 0 = DELETE
    "message": "Updated text"      # For EDIT only
  }
}
```

### Create Group
```graphql
mutation GroupCreate($input: ChatGroupAddInput!) {
  groupCreate(input: $input) {
    id
    name
    imgUrl
    description
    groupType
    members {
      userId
      user {
        id
        fullname
      }
      admin
    }
  }
}

# Variables
{
  "input": {
    "name": "Group Name",
    "imgUrl": "https://...",       # Optional
    "description": "Description",  # Optional
    "groupType": "Private",        # Private or Public
    "memberIds": ["uuid1", "uuid2"]
  }
}
```

### Edit Group
```graphql
mutation GroupEdit($input: ChatGroupEditInput!) {
  groupEdit(input: $input) {
    id
    name
    imgUrl
    description
    members {
      userId
      admin
    }
  }
}

# Variables
{
  "input": {
    "conversationId": "uuid",
    "name": "New Name",            # Optional
    "imgUrl": "https://...",       # Optional
    "description": "New desc",     # Optional
    "groupType": "Public",         # Optional
    "memberIds": ["uuid1", "uuid2"], # Optional: Update members
    "adminIds": ["uuid1"]          # Optional: Update admins
  }
}
```

## 🔌 Socket.IO Integration

### Connection Setup
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  
  Future<void> connect(String token) async {
    socket = IO.io(
      'wss://api.example.com',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .setReconnection(true)
        .setReconnectionDelay(2000)
        .setReconnectionAttempts(5)
        .build(),
    );
    
    socket.onConnect((_) {
      logger.i('Socket connected');
      _joinUserRoom();
      _joinConversationRooms();
    });
    
    socket.onDisconnect((_) {
      logger.w('Socket disconnected');
    });
    
    socket.onError((error) {
      logger.e('Socket error', error: error);
    });
    
    _setupEventListeners();
    
    socket.connect();
  }
  
  void _setupEventListeners() {
    // New message received
    socket.on('message:sent', (data) {
      final message = Message.fromJson(data['message']);
      final conversationId = data['conversationId'];
      _handleNewMessage(message, conversationId);
    });
    
    // Message read
    socket.on('message:read', (data) {
      final message = Message.fromJson(data['message']);
      final reader = User.fromJson(data['reader']);
      _handleMessageRead(message, reader);
    });
    
    // Reaction added/removed
    socket.on('message:reaction', (data) {
      final reactor = User.fromJson(data['reactor']);
      final reactionData = data['data'];
      _handleReaction(reactor, reactionData);
    });
    
    // Message edited
    socket.on('message:edit', (data) {
      final message = Message.fromJson(data['message']);
      _handleMessageEdit(message);
    });
    
    // Message deleted
    socket.on('message:delete', (data) {
      final message = Message.fromJson(data['message']);
      _handleMessageDelete(message);
    });
    
    // Someone typing
    socket.on('message:typing', (data) {
      final userId = data['userId'];
      final fullName = data['fullName'];
      final isTyping = data['isTyping'];
      final conversationId = data['conversationId'];
      _handleTyping(userId, fullName, isTyping, conversationId);
    });
    
    // Added to conversation
    socket.on('conversation:joined', (data) {
      final conversationId = data['conversationId'];
      _handleJoinedConversation(conversationId);
    });
    
    // Removed from conversation
    socket.on('conversation:leaved', (data) {
      final conversationId = data['conversationId'];
      _handleLeavedConversation(conversationId);
    });
  }
  
  // Emit typing indicator
  void emitTyping(String conversationId, bool isTyping) {
    socket.emit('message:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }
  
  // Join conversation room
  void joinConversation(String conversationId) {
    socket.emit('conversation:joined', {
      'conversationId': conversationId,
    });
  }
  
  // Leave conversation room
  void leaveConversation(String conversationId) {
    socket.emit('conversation:leaved', {
      'conversationId': conversationId,
    });
  }
  
  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
```

## 🎯 Implementation Checklist

### Data Layer
- [ ] Create GraphQL queries/mutations
- [ ] Create Socket.IO event handlers
- [ ] Implement message repository
- [ ] Implement conversation repository
- [ ] Setup Isar models for offline storage
- [ ] Implement sync queue for offline messages

### Domain Layer
- [ ] Create message entity
- [ ] Create conversation entity
- [ ] Create user entity
- [ ] Define repository interfaces
- [ ] Create use cases:
  - [ ] SendMessage
  - [ ] GetMessages
  - [ ] GetConversations
  - [ ] MarkAsRead
  - [ ] AddReaction
  - [ ] EditMessage
  - [ ] DeleteMessage
  - [ ] CreateGroup
  - [ ] EditGroup

### Presentation Layer
- [ ] Create ChatBloc
- [ ] Create ConversationBloc
- [ ] Create TypingBloc
- [ ] Create chat list page
- [ ] Create chat detail page
- [ ] Create message bubble widget
- [ ] Create message input widget
- [ ] Create typing indicator
- [ ] Create reaction picker
- [ ] Create group creation page
- [ ] Create group settings page

### Features
- [ ] Real-time messaging
- [ ] Offline message queue
- [ ] Message pagination
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Reactions
- [ ] Reply to message
- [ ] Forward message
- [ ] Edit message
- [ ] Delete message
- [ ] Mentions (@user)
- [ ] Media messages (image, video, file)
- [ ] Voice messages
- [ ] Group chat
- [ ] Group admin features
- [ ] Search messages
- [ ] Clear chat history

## ⚠️ Important Notes

### Mentions
- Format: `@[userId]` in message text
- Backend extracts user IDs automatically
- Use `@[all]` to mention everyone
- `mentionTo` field contains mentioned users

### Pagination
- Use `lastKey` for cursor-based pagination
- `lastKey.createdAt` is timestamp of last message
- Always sort by `createdAt DESC` for newest first

### Unread Count
- Managed by backend automatically
- Use `readCount` to mark messages as read
- Use `1000000` to mark all as read
- `personalConversation.unreadCount` has current count

### Direct Messages
- Use `receiverId` for first message
- Backend creates conversation automatically
- Subsequent messages use `conversationId`
- Conversation name = partner's fullname

### Group Messages
- Must use `conversationId`
- Only admins can edit group
- Only admins can remove members
- Creator is automatically admin
- When last admin leaves, oldest member becomes admin

### Message Deletion
- Soft delete (not removed from DB)
- Indexed in OpenSearch for search
- Socket event notifies all members

### File Upload
- Use Socket.IO `message:file:upload` event
- Returns file path
- Then send message with `urls` field

---

**Next Steps**: Implement data layer → domain layer → presentation layer
