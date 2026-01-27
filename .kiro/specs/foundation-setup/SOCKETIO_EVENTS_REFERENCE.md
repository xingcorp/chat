# Socket.IO Events Reference

## Overview

This document provides a complete reference for all Socket.IO events available in the Sharitek Office Chat backend.

**Base URL:** `https://dev-api.sharitek.com`  
**Namespace:** `/` (default)  
**Transport:** WebSocket  
**Authentication:** Token in auth object  
**Test Account:** 0989006188abc

---

## Connection

### Establishing Connection

**Client-side (JavaScript):**
```javascript
const io = require('socket.io-client');

const socket = io('https://dev-api.sharitek.com', {
  auth: {
    token: 'YOUR_ACCESS_TOKEN'
  },
  transports: ['websocket'],
  reconnection: true,
  reconnectionDelay: 1000,
  reconnectionAttempts: 5
});
```

**Client-side (Flutter/Dart):**
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io('https://dev-api.sharitek.com', 
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .setAuth({'token': accessToken})
    .enableReconnection()
    .build()
);

socket.connect();
```

### Connection Events

**connect**
- **Direction:** Server → Client
- **Trigger:** When connection is established
- **Payload:** None
- **Example:**
```javascript
socket.on('connect', () => {
  console.log('Connected to server');
  console.log('Socket ID:', socket.id);
});
```

**disconnect**
- **Direction:** Server → Client
- **Trigger:** When connection is lost
- **Payload:** Reason string
- **Example:**
```javascript
socket.on('disconnect', (reason) => {
  console.log('Disconnected:', reason);
  // Reasons: 'io server disconnect', 'io client disconnect', 'ping timeout', 'transport close'
});
```

**connect_error**
- **Direction:** Server → Client
- **Trigger:** When connection fails
- **Payload:** Error object
- **Example:**
```javascript
socket.on('connect_error', (error) => {
  console.error('Connection error:', error.message);
});
```

**reconnect**
- **Direction:** Server → Client
- **Trigger:** When reconnection succeeds
- **Payload:** Attempt number
- **Example:**
```javascript
socket.on('reconnect', (attemptNumber) => {
  console.log('Reconnected after', attemptNumber, 'attempts');
});
```

---

## Client → Server Events

### message:sent

**Purpose:** Send a new message to a conversation

**Payload:**
```typescript
{
  conversationId: string;
  content: string;
  type: 'TEXT' | 'IMAGE' | 'VIDEO' | 'FILE' | 'AUDIO';
  attachments?: Array<{
    url: string;
    type: string;
    name: string;
    size: number;
  }>;
  replyToId?: string;
}
```

**Acknowledgment:** `message:sent:ack`

**Example:**
```javascript
socket.emit('message:sent', {
  conversationId: 'conv_123',
  content: 'Hello, how are you?',
  type: 'TEXT'
}, (ack) => {
  console.log('Message sent:', ack);
});
```

**Acknowledgment Payload:**
```typescript
{
  success: boolean;
  messageId?: string;
  error?: string;
}
```

---

### message:typing

**Purpose:** Indicate that user is typing

**Payload:**
```typescript
{
  conversationId: string;
  isTyping: boolean;
}
```

**Acknowledgment:** None

**Example:**
```javascript
// Start typing
socket.emit('message:typing', {
  conversationId: 'conv_123',
  isTyping: true
});

// Stop typing
socket.emit('message:typing', {
  conversationId: 'conv_123',
  isTyping: false
});
```

**Best Practice:**
- Send `isTyping: true` when user starts typing
- Send `isTyping: false` when user stops typing or sends message
- Debounce typing events (e.g., 500ms)

---

### message:read

**Purpose:** Mark message(s) as read

**Payload:**
```typescript
{
  messageId: string;
  conversationId: string;
}
```

**Acknowledgment:** None

**Example:**
```javascript
socket.emit('message:read', {
  messageId: 'msg_789',
  conversationId: 'conv_123'
});
```

---

### conversation:joined

**Purpose:** Join a conversation room to receive real-time updates

**Payload:**
```typescript
{
  conversationId: string;
}
```

**Acknowledgment:** `conversation:joined:ack`

**Example:**
```javascript
socket.emit('conversation:joined', {
  conversationId: 'conv_123'
}, (ack) => {
  console.log('Joined conversation:', ack);
});
```

**Acknowledgment Payload:**
```typescript
{
  success: boolean;
  conversationId: string;
  error?: string;
}
```

**Important:** Must join conversation room before receiving message events for that conversation.

---

### conversation:leaved

**Purpose:** Leave a conversation room

**Payload:**
```typescript
{
  conversationId: string;
}
```

**Acknowledgment:** `conversation:leaved:ack`

**Example:**
```javascript
socket.emit('conversation:leaved', {
  conversationId: 'conv_123'
}, (ack) => {
  console.log('Left conversation:', ack);
});
```

**Acknowledgment Payload:**
```typescript
{
  success: boolean;
  conversationId: string;
  error?: string;
}
```

---

### user:status:update

**Purpose:** Update user's online status

**Payload:**
```typescript
{
  status: 'ONLINE' | 'AWAY' | 'OFFLINE';
}
```

**Acknowledgment:** None

**Example:**
```javascript
socket.emit('user:status:update', {
  status: 'AWAY'
});
```

---

## Server → Client Events

### message:received

**Purpose:** Notification of a new message in a conversation

**Trigger:** When any user sends a message to a conversation you've joined

**Payload:**
```typescript
{
  id: string;
  conversationId: string;
  senderId: string;
  sender: {
    id: string;
    displayName: string;
    avatar?: string;
  };
  content: string;
  type: 'TEXT' | 'IMAGE' | 'VIDEO' | 'FILE' | 'AUDIO';
  attachments?: Array<{
    id: string;
    url: string;
    type: string;
    name: string;
    size: number;
    thumbnailUrl?: string;
  }>;
  replyTo?: {
    id: string;
    content: string;
    senderId: string;
  };
  status: 'SENT' | 'DELIVERED' | 'READ';
  createdAt: string;
}
```

**Example:**
```javascript
socket.on('message:received', (message) => {
  console.log('New message:', message);
  // Update UI with new message
  addMessageToConversation(message.conversationId, message);
});
```

---

### message:typing

**Purpose:** Notification that a user is typing

**Trigger:** When a user in a conversation starts/stops typing

**Payload:**
```typescript
{
  userId: string;
  user: {
    id: string;
    displayName: string;
    avatar?: string;
  };
  conversationId: string;
  isTyping: boolean;
}
```

**Example:**
```javascript
socket.on('message:typing', (data) => {
  if (data.isTyping) {
    console.log(`${data.user.displayName} is typing...`);
    showTypingIndicator(data.conversationId, data.user);
  } else {
    hideTypingIndicator(data.conversationId, data.userId);
  }
});
```

---

### message:read

**Purpose:** Notification that a message was read

**Trigger:** When a user reads a message

**Payload:**
```typescript
{
  messageId: string;
  conversationId: string;
  userId: string;
  user: {
    id: string;
    displayName: string;
  };
  readAt: string;
}
```

**Example:**
```javascript
socket.on('message:read', (data) => {
  console.log(`Message ${data.messageId} read by ${data.user.displayName}`);
  updateMessageStatus(data.messageId, 'READ', data.readAt);
});
```

---

### message:updated

**Purpose:** Notification that a message was edited

**Trigger:** When a user edits a message

**Payload:**
```typescript
{
  id: string;
  conversationId: string;
  content: string;
  updatedAt: string;
  isEdited: boolean;
}
```

**Example:**
```javascript
socket.on('message:updated', (data) => {
  console.log('Message updated:', data);
  updateMessageContent(data.id, data.content, data.updatedAt);
});
```

---

### message:deleted

**Purpose:** Notification that a message was deleted

**Trigger:** When a user deletes a message

**Payload:**
```typescript
{
  messageId: string;
  conversationId: string;
  deletedBy: string;
  deletedAt: string;
}
```

**Example:**
```javascript
socket.on('message:deleted', (data) => {
  console.log('Message deleted:', data);
  removeMessageFromUI(data.messageId);
});
```

---

### message:reaction

**Purpose:** Notification of a reaction added/removed

**Trigger:** When a user reacts to a message

**Payload:**
```typescript
{
  messageId: string;
  conversationId: string;
  reaction: {
    emoji: string;
    userId: string;
    user: {
      id: string;
      displayName: string;
    };
    action: 'ADD' | 'REMOVE';
    createdAt?: string;
  };
}
```

**Example:**
```javascript
socket.on('message:reaction', (data) => {
  if (data.reaction.action === 'ADD') {
    addReactionToMessage(data.messageId, data.reaction);
  } else {
    removeReactionFromMessage(data.messageId, data.reaction);
  }
});
```

---

### conversation:updated

**Purpose:** Notification that conversation metadata changed

**Trigger:** When conversation name, avatar, or settings change

**Payload:**
```typescript
{
  id: string;
  type: 'DIRECT' | 'GROUP';
  name?: string;
  avatar?: string;
  description?: string;
  updatedAt: string;
  updatedBy: string;
}
```

**Example:**
```javascript
socket.on('conversation:updated', (data) => {
  console.log('Conversation updated:', data);
  updateConversationMetadata(data.id, data);
});
```

---

### conversation:member:added

**Purpose:** Notification that a member was added to a group

**Trigger:** When a user is added to a group conversation

**Payload:**
```typescript
{
  conversationId: string;
  member: {
    id: string;
    displayName: string;
    avatar?: string;
    role: 'ADMIN' | 'MEMBER';
  };
  addedBy: string;
  addedAt: string;
}
```

**Example:**
```javascript
socket.on('conversation:member:added', (data) => {
  console.log(`${data.member.displayName} joined the group`);
  addMemberToConversation(data.conversationId, data.member);
});
```

---

### conversation:member:removed

**Purpose:** Notification that a member was removed from a group

**Trigger:** When a user leaves or is removed from a group

**Payload:**
```typescript
{
  conversationId: string;
  memberId: string;
  removedBy: string;
  removedAt: string;
}
```

**Example:**
```javascript
socket.on('conversation:member:removed', (data) => {
  console.log('Member removed from group');
  removeMemberFromConversation(data.conversationId, data.memberId);
});
```

---

### user:status

**Purpose:** Notification of user online/offline status change

**Trigger:** When a user connects, disconnects, or changes status

**Payload:**
```typescript
{
  userId: string;
  user: {
    id: string;
    displayName: string;
    avatar?: string;
  };
  status: 'ONLINE' | 'OFFLINE' | 'AWAY';
  lastSeen?: string;
}
```

**Example:**
```javascript
socket.on('user:status', (data) => {
  console.log(`${data.user.displayName} is now ${data.status}`);
  updateUserStatus(data.userId, data.status, data.lastSeen);
});
```

---

## Event Flow Examples

### Sending a Message

**Client A:**
```javascript
// 1. Send message
socket.emit('message:sent', {
  conversationId: 'conv_123',
  content: 'Hello!',
  type: 'TEXT'
}, (ack) => {
  console.log('Message sent:', ack.messageId);
});
```

**Server:**
```
// 2. Processes message
// 3. Saves to database
// 4. Broadcasts to conversation room
```

**Client B (in same conversation):**
```javascript
// 5. Receives message
socket.on('message:received', (message) => {
  console.log('New message:', message.content);
  displayMessage(message);
});
```

---

### Typing Indicator

**Client A:**
```javascript
// 1. User starts typing
socket.emit('message:typing', {
  conversationId: 'conv_123',
  isTyping: true
});

// 2. User stops typing after 3 seconds
setTimeout(() => {
  socket.emit('message:typing', {
    conversationId: 'conv_123',
    isTyping: false
  });
}, 3000);
```

**Client B:**
```javascript
// 3. Receives typing event
socket.on('message:typing', (data) => {
  if (data.isTyping) {
    showTypingIndicator(data.user.displayName);
  } else {
    hideTypingIndicator();
  }
});
```

---

### Read Receipts

**Client A:**
```javascript
// 1. User opens conversation and reads messages
socket.emit('message:read', {
  messageId: 'msg_789',
  conversationId: 'conv_123'
});
```

**Client B (message sender):**
```javascript
// 2. Receives read receipt
socket.on('message:read', (data) => {
  console.log('Message read by', data.user.displayName);
  updateMessageStatus(data.messageId, 'READ');
});
```

---

## Best Practices

### Connection Management

**Reconnection:**
```javascript
socket.on('disconnect', (reason) => {
  if (reason === 'io server disconnect') {
    // Server disconnected, manually reconnect
    socket.connect();
  }
  // Otherwise, socket will automatically try to reconnect
});
```

**Heartbeat:**
```javascript
// Server sends ping every 25 seconds
// Client responds with pong automatically
// Connection times out after 60 seconds of no pong
```

### Room Management

**Join conversations on app start:**
```javascript
socket.on('connect', () => {
  // Rejoin all active conversations
  activeConversations.forEach(conv => {
    socket.emit('conversation:joined', {
      conversationId: conv.id
    });
  });
});
```

**Leave conversations when navigating away:**
```javascript
// When leaving conversation screen
socket.emit('conversation:leaved', {
  conversationId: currentConversationId
});
```

### Error Handling

**Handle acknowledgment errors:**
```javascript
socket.emit('message:sent', messageData, (ack) => {
  if (!ack.success) {
    console.error('Failed to send message:', ack.error);
    showErrorToUser(ack.error);
  }
});
```

**Handle connection errors:**
```javascript
socket.on('connect_error', (error) => {
  console.error('Connection error:', error);
  showOfflineIndicator();
});
```

### Performance

**Debounce typing events:**
```javascript
let typingTimeout;
function handleTyping() {
  clearTimeout(typingTimeout);
  
  socket.emit('message:typing', {
    conversationId: currentConversationId,
    isTyping: true
  });
  
  typingTimeout = setTimeout(() => {
    socket.emit('message:typing', {
      conversationId: currentConversationId,
      isTyping: false
    });
  }, 3000);
}
```

**Batch read receipts:**
```javascript
// Instead of sending read receipt for each message
// Batch them and send periodically
let readMessages = [];
setInterval(() => {
  if (readMessages.length > 0) {
    readMessages.forEach(msgId => {
      socket.emit('message:read', {
        messageId: msgId,
        conversationId: currentConversationId
      });
    });
    readMessages = [];
  }
}, 1000);
```

---

## Testing

### Test Connection
```javascript
const socket = io('https://dev-api.sharitek.com', {
  auth: { token: 'YOUR_TOKEN' }
});

socket.on('connect', () => {
  console.log('✅ Connected');
});

socket.on('connect_error', (error) => {
  console.error('❌ Connection failed:', error);
});
```

### Test Message Flow
```javascript
// Join conversation
socket.emit('conversation:joined', { conversationId: 'test_conv' });

// Send message
socket.emit('message:sent', {
  conversationId: 'test_conv',
  content: 'Test message',
  type: 'TEXT'
});

// Listen for message
socket.on('message:received', (msg) => {
  console.log('✅ Message received:', msg);
});
```

---

**Last Updated:** 2025-01-27  
**API Version:** 1.0  
**Backend:** NestJS + Socket.IO
