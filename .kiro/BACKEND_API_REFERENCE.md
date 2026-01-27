# 🔌 BACKEND API REFERENCE - OXII OFFICE CHAT

> **Quick Reference Guide cho Backend Integration**  
> **Ngày tạo:** 2025-01-27  
> **Phiên bản:** 1.0  
> **Mục đích:** Reference nhanh cho developers

---

## 🌐 API ENDPOINTS

### GraphQL Playground

| Environment | URL | Purpose |
|-------------|-----|---------|
| **Staging** | https://oxii-workoffice.smarthiz.com/graphql | Development & Testing |
| **Production** | https://oxii-office-api.oxiitek.com/graphql | Live Production |

### Socket.IO

| Environment | URL | Purpose |
|-------------|-----|---------|
| **Staging** | wss://oxii-workoffice.smarthiz.com | Real-time messaging (STG) |
| **Production** | wss://oxii-office-api.oxiitek.com | Real-time messaging (PROD) |

---

## 🚀 QUICK START

### 1. Access GraphQL Playground

**Staging:**
```
https://oxii-workoffice.smarthiz.com/graphql
```

**Production:**
```
https://oxii-office-api.oxiitek.com/graphql
```

### 2. Authentication

Tất cả requests cần authentication header:

```http
Authorization: Bearer <access_token>
```

### 3. Test Query

```graphql
query TestConnection {
  chatConversationList(filters: {
    size: 10
    page: 0
  }) {
    total
    conversations {
      id
      name
      type
    }
  }
}
```

---

## 📋 CHAT OPERATIONS REFERENCE

### Conversation Operations

#### 1. Get Conversation List

```graphql
query GetConversations($filters: ChatConversationListFilter!) {
  chatConversationList(filters: $filters) {
    total
    conversations {
      id
      name
      type              # Direct | Group
      description
      imgUrl
      groupType         # Public | Private
      createdAt
      lastMessageAt
      lastMessageId
      creator {
        id
        fullname
        avatarUrl
      }
      members {
        id
        userId
        admin
        connected
        hide
        unreadCount
        lastMessageReadId
        user {
          id
          fullname
          avatarUrl
          email
        }
      }
    }
  }
}

# Variables
{
  "filters": {
    "size": 25,
    "page": 0,
    "keyword": "",
    "type": "Group"  # Optional: Direct | Group
  }
}
```

#### 2. Get Conversation Detail

```graphql
query GetConversationDetail(
  $conversationId: String
  $receiverId: String
) {
  chatConversationDetail(
    conversationId: $conversationId
    receiverId: $receiverId
  ) {
    id
    name
    type
    description
    imgUrl
    groupType
    createdAt
    lastMessageAt
    creator {
      id
      fullname
    }
    members {
      id
      userId
      admin
      unreadCount
      user {
        id
        fullname
        avatarUrl
      }
    }
  }
}

# Variables (use one or the other)
{
  "conversationId": "uuid-here"
}
# OR
{
  "receiverId": "user-id-here"  # For direct chat
}
```

#### 3. Create Group

```graphql
mutation CreateGroup($arguments: ChatGroupAddInput!) {
  chatGroupAdd(arguments: $arguments) {
    id
    name
    imgUrl
    description
    groupType
    members {
      userId
      admin
      user {
        fullname
      }
    }
  }
}

# Variables
{
  "arguments": {
    "name": "Project Team",
    "imgUrl": "https://example.com/image.jpg",
    "description": "Team collaboration group",
    "groupType": "Private",  # Public | Private
    "memberIds": ["user-id-1", "user-id-2", "user-id-3"]
  }
}
```

#### 4. Edit Group

```graphql
mutation EditGroup($arguments: ChatGroupEditInput!) {
  chatGroupEdit(arguments: $arguments) {
    id
    name
    imgUrl
    description
    groupType
    members {
      userId
      admin
    }
  }
}

# Variables
{
  "arguments": {
    "conversationId": "group-id-here",
    "name": "Updated Name",
    "imgUrl": "https://example.com/new-image.jpg",
    "description": "Updated description",
    "groupType": "Public",
    "memberIds": ["user-id-1", "user-id-2"],  # Add/remove members
    "adminIds": ["user-id-1"]  # Promote/demote admins
  }
}
```

#### 5. Leave Conversation

```graphql
mutation LeaveConversation($arguments: ChatGroupLeaveArgs!) {
  chatConversationLeave(arguments: $arguments) {
    id
  }
}

# Variables
{
  "arguments": {
    "conversationId": "conversation-id-here"
  }
}
```

#### 6. Delete Conversation

```graphql
mutation DeleteConversation($arguments: ChatGroupLeaveArgs!) {
  chatConversationDelete(arguments: $arguments) {
    id
    userId
    conversationId
  }
}

# Variables
{
  "arguments": {
    "conversationId": "conversation-id-here"
  }
}
```

---

### Message Operations

#### 1. Get Messages

```graphql
query GetMessages($filters: ChatMessageGetListFilter!) {
  chatMessageList(filters: $filters) {
    lastKey {
      conversationId
      createdAt
    }
    messages {
      id
      message
      urls
      type              # TEXT | IMAGE | VIDEO | AUDIO | FILE | LOCATION
      createdAt
      editAt
      deletedAt
      replyMessageId
      replyMessage {
        id
        message
        sender {
          fullname
        }
      }
      forwardedFromMessageId
      fileName
      senderId
      sender {
        id
        fullname
        avatarUrl
      }
      conversationId
      readerIds
      reactions {
        code
        userId
        user {
          fullname
        }
      }
      mentionTo {
        id
        fullname
      }
    }
  }
}

# Variables
{
  "filters": {
    "conversationId": "conversation-id-here",
    "size": 100,
    "lastKey": null,  # For pagination
    "type": null,     # Optional: filter by type
    "order": "DESC",  # DESC | ASC
    "from": null      # Optional: timestamp filter
  }
}

# For pagination (next page)
{
  "filters": {
    "conversationId": "conversation-id-here",
    "size": 100,
    "lastKey": {
      "conversationId": "conversation-id-here",
      "createdAt": 1706342400000  # From previous response
    }
  }
}
```

#### 2. Send Message

```graphql
mutation SendMessage($arguments: ChatAddMessageInput!) {
  chatMessageAdd(arguments: $arguments) {
    id
    message
    urls
    type
    createdAt
    senderId
    sender {
      fullname
      avatarUrl
    }
    conversationId
  }
}

# Variables - Text Message
{
  "arguments": {
    "conversationId": "conversation-id-here",
    "type": "TEXT",
    "message": "Hello, world!",
    "createdAt": 1706342400000  # Current timestamp
  }
}

# Variables - Direct Message (no conversation yet)
{
  "arguments": {
    "receiverId": "user-id-here",
    "type": "TEXT",
    "message": "Hello!",
    "createdAt": 1706342400000
  }
}

# Variables - Reply to Message
{
  "arguments": {
    "conversationId": "conversation-id-here",
    "type": "TEXT",
    "message": "Replying to your message",
    "replyMessageId": "message-id-to-reply",
    "createdAt": 1706342400000
  }
}

# Variables - Image/File Message
{
  "arguments": {
    "conversationId": "conversation-id-here",
    "type": "IMAGE",  # IMAGE | VIDEO | AUDIO | FILE
    "message": "Check this out",
    "urls": ["https://example.com/image.jpg"],
    "fileName": "image.jpg",
    "createdAt": 1706342400000
  }
}

# Variables - Forward Message
{
  "arguments": {
    "conversationId": "conversation-id-here",
    "type": "TEXT",
    "message": "Forwarded message",
    "forwardedFromMessageId": "original-message-id",
    "createdAt": 1706342400000
  }
}
```

#### 3. Edit Message

```graphql
mutation EditMessage($arguments: ChatMessageUpdateArgs!) {
  chatMessageEdit(arguments: $arguments) {
    id
    message
    editAt
  }
}

# Variables
{
  "arguments": {
    "messageId": "message-id-here",
    "act": "EDIT",  # EDIT | DELETE
    "message": "Updated message text"
  }
}
```

#### 4. Mark as Read

```graphql
mutation MarkAsRead($arguments: ChatMessageUpdateReadArgs!) {
  chatMessageUpdateRead(arguments: $arguments) {
    conversationId
  }
}

# Variables
{
  "arguments": {
    "conversationId": "conversation-id-here",
    "readCount": 5  # Number of messages read
  }
}
```

#### 5. Add/Remove Reaction

```graphql
mutation UpdateReaction($arguments: ChatMessageUpdateReactionArgs!) {
  chatMessageUpdateReaction(arguments: $arguments) {
    id
    reactions {
      code
      userId
    }
  }
}

# Variables - Add Reaction
{
  "arguments": {
    "messageId": "message-id-here",
    "code": "👍",  # Emoji code
    "act": "ADD"   # ADD | REMOVE
  }
}

# Variables - Remove Reaction
{
  "arguments": {
    "messageId": "message-id-here",
    "code": "👍",
    "act": "REMOVE"
  }
}
```

#### 6. Delete Message History

```graphql
mutation DeleteHistory($arguments: DeleteHistoryArgs!) {
  chatMessageDeleteHistory(arguments: $arguments) {
    id
    conversationId
    viewMessagesFrom
  }
}

# Variables
{
  "arguments": {
    "conversationId": "conversation-id-here"
  }
}
```

---

### Search Operations

#### Search Messages

```graphql
query SearchMessages($filters: ChatSearchArgs!) {
  chatSearch(filters: $filters) {
    id
    message
    fileName
    type
    createdAt
    senderId
    sender {
      fullname
      avatarUrl
    }
    conversationId
  }
}

# Variables
{
  "filters": {
    "keyword": "search term",
    "conversationIds": ["conv-id-1", "conv-id-2"],  # Optional
    "senderIds": ["user-id-1"],  # Optional
    "messageTypes": ["TEXT", "IMAGE"],  # Optional
    "from": 1706342400000,  # Optional: start timestamp
    "to": 1706428800000,    # Optional: end timestamp
    "page": 0,
    "size": 100
  }
}
```

---

## 🔄 SOCKET.IO EVENTS

### Connection

```typescript
// Connect to Socket.IO
const socket = io('wss://oxii-workoffice.smarthiz.com', {
  transports: ['websocket'],
  auth: {
    token: 'Bearer <access_token>'
  }
});

socket.on('connect', () => {
  console.log('Connected to Socket.IO');
});
```

### Client → Server Events

#### 1. Join Conversation

```typescript
socket.emit('conversation:joined', {
  conversationId: 'conversation-id-here'
});
```

#### 2. Leave Conversation

```typescript
socket.emit('conversation:leaved', {
  conversationId: 'conversation-id-here'
});
```

#### 3. Typing Indicator

```typescript
socket.emit('message:typing', {
  conversationId: 'conversation-id-here',
  isTyping: true  // or false
});
```

#### 4. File Upload

```typescript
socket.emit('message:file:upload', {
  file: fileBuffer,  // Buffer
  fileName: 'document.pdf'
});

// Response
socket.on('message:file:upload', (response) => {
  if (response.success) {
    console.log('File uploaded:', response.filePath);
  }
});
```

### Server → Client Events

#### 1. New Message

```typescript
socket.on('message:sent', (data) => {
  console.log('New message:', data.message);
  console.log('Conversation:', data.conversationId);
  // Update UI with new message
});
```

#### 2. Message Read

```typescript
socket.on('message:read', (data) => {
  console.log('Message read by:', data.reader);
  console.log('Message:', data.message);
  // Update read status in UI
});
```

#### 3. Message Reaction

```typescript
socket.on('message:reaction', (data) => {
  console.log('Reaction by:', data.reactor);
  console.log('Reaction data:', data.data);
  // data.data = { messageId, code, act: 'ADD' | 'REMOVE' }
  // Update reaction in UI
});
```

#### 4. Message Edit

```typescript
socket.on('message:edit', (data) => {
  console.log('Message edited:', data.message);
  console.log('Conversation:', data.conversationId);
  // Update message in UI
});
```

#### 5. Message Delete

```typescript
socket.on('message:delete', (data) => {
  console.log('Message deleted:', data.message);
  console.log('Conversation:', data.conversationId);
  // Remove or mark message as deleted in UI
});
```

#### 6. Typing Indicator

```typescript
socket.on('message:typing', (data) => {
  console.log('User typing:', data.fullName);
  console.log('Is typing:', data.isTyping);
  console.log('Conversation:', data.conversationId);
  // Show/hide typing indicator
});
```

#### 7. Conversation Joined

```typescript
socket.on('conversation:joined', (data) => {
  console.log('Joined conversation:', data.conversationId);
  // Update UI
});
```

#### 8. Conversation Left

```typescript
socket.on('conversation:leaved', (data) => {
  console.log('Left conversation:', data.conversationId);
  // Update UI
});
```

---

## 🔐 AUTHENTICATION

### Get Access Token

```graphql
mutation Login($email: String!, $password: String!) {
  login(email: $email, password: $password) {
    accessToken
    refreshToken
    user {
      id
      fullname
      email
      avatarUrl
    }
  }
}

# Variables
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Use Token in Requests

**GraphQL:**
```http
POST /graphql
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "query": "...",
  "variables": {...}
}
```

**Socket.IO:**
```typescript
const socket = io(url, {
  auth: {
    token: 'Bearer <access_token>'
  }
});
```

---

## 📊 DATA TYPES

### Enums

```typescript
// ChatConversationType
enum ChatConversationType {
  Direct = 'Direct',
  Group = 'Group'
}

// ChatConversationGroupType
enum ChatConversationGroupType {
  Public = 'Public',
  Private = 'Private'
}

// ChatMessageType
enum ChatMessageType {
  TEXT = 'TEXT',
  IMAGE = 'IMAGE',
  VIDEO = 'VIDEO',
  AUDIO = 'AUDIO',
  FILE = 'FILE',
  LOCATION = 'LOCATION'
}

// ChatMessageAct
enum ChatMessageAct {
  EDIT = 'EDIT',
  DELETE = 'DELETE'
}

// ChatMessageReactionAct
enum ChatMessageReactionAct {
  ADD = 'ADD',
  REMOVE = 'REMOVE'
}

// OrderBy
enum OrderBy {
  ASC = 'ASC',
  DESC = 'DESC'
}
```

---

## 🧪 TESTING CHECKLIST

### Phase 1: Basic Operations

- [ ] Connect to GraphQL playground
- [ ] Test authentication
- [ ] Get conversation list
- [ ] Get conversation detail
- [ ] Get messages
- [ ] Send message
- [ ] Connect to Socket.IO
- [ ] Receive real-time message

### Phase 2: Advanced Operations

- [ ] Create group
- [ ] Edit group
- [ ] Leave conversation
- [ ] Delete conversation
- [ ] Edit message
- [ ] Mark as read
- [ ] Add reaction
- [ ] Remove reaction
- [ ] Search messages

### Phase 3: Real-time Events

- [ ] Typing indicator
- [ ] Message sent event
- [ ] Message read event
- [ ] Message reaction event
- [ ] Message edit event
- [ ] Message delete event
- [ ] File upload

---

## 🐛 TROUBLESHOOTING

### Common Issues

**1. Authentication Failed**
```
Error: Unauthorized
Solution: Check if access token is valid and not expired
```

**2. GraphQL Query Error**
```
Error: Cannot query field "..." on type "..."
Solution: Check field names match backend schema exactly
```

**3. Socket.IO Connection Failed**
```
Error: Connection timeout
Solution: 
- Check WebSocket URL
- Verify authentication token
- Check network/firewall
```

**4. Message Not Received**
```
Issue: Sent message but not appearing
Solution:
- Check if conversation:joined was called
- Verify Socket.IO connection is active
- Check message:sent event listener
```

### Debug Tips

**Enable GraphQL Logging:**
```typescript
const client = new GraphQLClient(url, {
  headers: {
    authorization: `Bearer ${token}`
  },
  fetch: (url, options) => {
    console.log('GraphQL Request:', options.body);
    return fetch(url, options).then(res => {
      console.log('GraphQL Response:', res);
      return res;
    });
  }
});
```

**Enable Socket.IO Logging:**
```typescript
const socket = io(url, {
  auth: { token },
  transports: ['websocket'],
  debug: true  // Enable debug logs
});

socket.onAny((event, ...args) => {
  console.log('Socket Event:', event, args);
});
```

---

## 📚 ADDITIONAL RESOURCES

**Documentation:**
- [PROJECT_STATUS_ANALYSIS.md](.kiro/PROJECT_STATUS_ANALYSIS.md)
- [IMPLEMENTATION_MASTER_PLAN.md](.kiro/IMPLEMENTATION_MASTER_PLAN.md)
- [project-architecture.md](.kiro/steering/project-architecture.md)

**Backend Code:**
- GraphQL Resolvers: `src/modules/chat/*/resolvers/`
- DTOs: `src/modules/chat/*/dto/`
- Entities: `src/models/entities/chat/`
- Gateway: `src/modules/chat/chat-gateway/`

**Support:**
- Backend Team: [Contact Info]
- API Issues: [Issue Tracker]
- Documentation: [Wiki Link]

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-27  
**Maintained By:** Backend Integration Team  
**Next Review:** Weekly during Phase 1

