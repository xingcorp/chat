# Backend API Testing Guide (Day 2)

## Overview

This guide covers Day 2 tasks (Tasks 7-12) for verifying backend API access, testing GraphQL operations, testing Socket.IO events, and preparing test data.

**Duration:** 8 hours  
**Team:** Backend Integration Team (2 devs), Real-time Team (1 dev), QA/DevOps (0.5 dev)  
**Prerequisites:** Day 1 completed, Git workflow configured, CI/CD pipeline working

## Task 7: Verify Backend API Access and Authentication

### 7.1 Distribute API Credentials

**Test Account Provided:**
- Phone: `0989006188abc`
- Use this account for all API testing

**Backend API URLs:**
- Development: `https://dev-api.sharitek.com` (example)
- Staging: `https://staging-api.sharitek.com` (example)
- GraphQL Endpoint: `/graphql`
- Socket.IO Endpoint: `/socket.io`

**Security Best Practices:**
```bash
# Create .env.local file (never commit this!)
echo "API_URL=https://dev-api.sharitek.com" > .env.local
echo "TEST_PHONE=0989006188abc" >> .env.local
echo "TEST_PASSWORD=your_password_here" >> .env.local

# Add to .gitignore
echo ".env.local" >> .gitignore
```

### 7.2 Test Authentication Endpoint

**Using curl:**
```bash
# Login request
curl -X POST https://dev-api.sharitek.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0989006188abc",
    "password": "your_password"
  }'

# Expected response:
# {
#   "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "refreshToken": "...",
#   "user": { ... }
# }
```

**Using Postman:**
1. Create new request: POST `/auth/login`
2. Set body to JSON:
   ```json
   {
     "phone": "0989006188abc",
     "password": "your_password"
   }
   ```
3. Send request
4. Save `accessToken` for subsequent requests

**Verify Token Format:**
```bash
# Decode JWT token (use jwt.io or jwt-cli)
echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." | jwt decode

# Expected payload:
# {
#   "sub": "user_id",
#   "phone": "0989006188abc",
#   "iat": 1234567890,
#   "exp": 1234567890
# }
```

### 7.3 Verify Network Access

**Each developer should test:**
```bash
# Test connectivity
ping dev-api.sharitek.com

# Test HTTPS access
curl -I https://dev-api.sharitek.com/health

# Expected: HTTP 200 OK
```

**Common Issues:**
- **Connection refused:** Check VPN connection
- **SSL certificate error:** Update CA certificates
- **Timeout:** Check firewall rules

### 7.4 API Access Verification Script

**Already created:** `.kiro/specs/foundation-setup/scripts/verify_api_access.sh`

**Run the script:**
```bash
chmod +x .kiro/specs/foundation-setup/scripts/verify_api_access.sh
./.kiro/specs/foundation-setup/scripts/verify_api_access.sh
```

**Expected output:**
```
✅ API connectivity verified
✅ Authentication successful
✅ Token format valid
✅ GraphQL endpoint accessible
```

## Task 8: Setup and Test GraphQL Playground

### 8.1 Access GraphQL Playground

**Open in browser:**
```
https://dev-api.sharitek.com/graphql
```

**Authenticate:**
1. Click "HTTP HEADERS" at bottom
2. Add authorization header:
   ```json
   {
     "Authorization": "Bearer YOUR_ACCESS_TOKEN"
   }
   ```

### 8.2 Test Conversation Queries

**Query: chatConversationList**
```graphql
query GetConversations {
  chatConversationList(
    page: 1
    limit: 20
    sortBy: "updatedAt"
    sortOrder: "DESC"
  ) {
    items {
      id
      type
      name
      avatar
      lastMessage {
        id
        content
        createdAt
      }
      unreadCount
      updatedAt
    }
    total
    page
    limit
  }
}
```

**Expected Response:**
```json
{
  "data": {
    "chatConversationList": {
      "items": [
        {
          "id": "conv_123",
          "type": "DIRECT",
          "name": "John Doe",
          "avatar": "https://...",
          "lastMessage": {
            "id": "msg_456",
            "content": "Hello!",
            "createdAt": "2025-01-27T10:00:00Z"
          },
          "unreadCount": 2,
          "updatedAt": "2025-01-27T10:00:00Z"
        }
      ],
      "total": 15,
      "page": 1,
      "limit": 20
    }
  }
}
```

**Query: chatConversationDetail**
```graphql
query GetConversationDetail($id: ID!) {
  chatConversationDetail(id: $id) {
    id
    type
    name
    avatar
    description
    members {
      id
      displayName
      avatar
      role
    }
    createdAt
    updatedAt
  }
}
```

**Variables:**
```json
{
  "id": "conv_123"
}
```

### 8.3 Test Message Queries

**Query: chatMessageList**
```graphql
query GetMessages($conversationId: ID!, $page: Int!, $limit: Int!) {
  chatMessageList(
    conversationId: $conversationId
    page: $page
    limit: $limit
    sortBy: "createdAt"
    sortOrder: "DESC"
  ) {
    items {
      id
      conversationId
      senderId
      content
      type
      attachments {
        id
        url
        type
        name
        size
      }
      reactions {
        emoji
        userId
        createdAt
      }
      status
      createdAt
      updatedAt
    }
    total
    page
    limit
    hasMore
  }
}
```

**Variables:**
```json
{
  "conversationId": "conv_123",
  "page": 1,
  "limit": 50
}
```

**Test Pagination:**
```graphql
# Page 1
{ "conversationId": "conv_123", "page": 1, "limit": 50 }

# Page 2
{ "conversationId": "conv_123", "page": 2, "limit": 50 }

# Verify hasMore field changes
```

### 8.4 Test Mutations

**Mutation: chatMessageAdd**
```graphql
mutation SendMessage($input: ChatMessageAddInput!) {
  chatMessageAdd(input: $input) {
    id
    conversationId
    senderId
    content
    type
    status
    createdAt
  }
}
```

**Variables:**
```json
{
  "input": {
    "conversationId": "conv_123",
    "content": "Test message from API testing",
    "type": "TEXT"
  }
}
```

**Mutation: chatGroupAdd**
```graphql
mutation CreateGroup($input: ChatGroupAddInput!) {
  chatGroupAdd(input: $input) {
    id
    name
    avatar
    description
    members {
      id
      displayName
      role
    }
    createdAt
  }
}
```

**Variables:**
```json
{
  "input": {
    "name": "Test Group",
    "description": "Testing group creation",
    "memberIds": ["user_1", "user_2", "user_3"]
  }
}
```

### 8.5 Document GraphQL Operations

**Create reference document:**

```markdown
# GraphQL Operations Reference

## Queries

### chatConversationList
- **Purpose:** Get paginated list of conversations
- **Parameters:** page, limit, sortBy, sortOrder
- **Returns:** Paginated conversation list with last message and unread count

### chatConversationDetail
- **Purpose:** Get detailed conversation information
- **Parameters:** id
- **Returns:** Full conversation details with members

### chatMessageList
- **Purpose:** Get paginated messages for a conversation
- **Parameters:** conversationId, page, limit, sortBy, sortOrder
- **Returns:** Paginated message list with attachments and reactions

## Mutations

### chatMessageAdd
- **Purpose:** Send a new message
- **Input:** conversationId, content, type, attachments (optional)
- **Returns:** Created message with ID and status

### chatGroupAdd
- **Purpose:** Create a new group conversation
- **Input:** name, description, memberIds
- **Returns:** Created group with members

### chatMessageReact
- **Purpose:** Add reaction to a message
- **Input:** messageId, emoji
- **Returns:** Updated message with reactions

## Subscriptions

### messageReceived
- **Purpose:** Real-time message updates
- **Parameters:** conversationId
- **Returns:** Stream of new messages

### conversationUpdated
- **Purpose:** Real-time conversation updates
- **Parameters:** userId
- **Returns:** Stream of conversation changes
```

Save this to: `.kiro/specs/foundation-setup/GRAPHQL_OPERATIONS_REFERENCE.md`

## Task 9: Test Socket.IO Connection and Events

### 9.1 Test Socket.IO Connection

**Using Node.js test script:**
```javascript
// test_socket.js
const io = require('socket.io-client');

const socket = io('https://dev-api.sharitek.com', {
  auth: {
    token: 'YOUR_ACCESS_TOKEN'
  },
  transports: ['websocket']
});

socket.on('connect', () => {
  console.log('✅ Connected to Socket.IO server');
  console.log('Socket ID:', socket.id);
});

socket.on('disconnect', () => {
  console.log('❌ Disconnected from Socket.IO server');
});

socket.on('connect_error', (error) => {
  console.error('❌ Connection error:', error.message);
});

// Keep connection alive for 30 seconds
setTimeout(() => {
  socket.disconnect();
  console.log('Test complete');
}, 30000);
```

**Run the test:**
```bash
npm install socket.io-client
node test_socket.js
```

**Expected output:**
```
✅ Connected to Socket.IO server
Socket ID: abc123xyz
Test complete
```

### 9.2 Test Message Events

**Emit message:sent event:**
```javascript
socket.emit('message:sent', {
  conversationId: 'conv_123',
  content: 'Test message via Socket.IO',
  type: 'TEXT'
});

socket.on('message:sent:ack', (data) => {
  console.log('✅ Message sent acknowledged:', data);
});
```

**Listen for message:received event:**
```javascript
socket.on('message:received', (message) => {
  console.log('📨 New message received:', message);
  // Expected payload:
  // {
  //   id: 'msg_789',
  //   conversationId: 'conv_123',
  //   senderId: 'user_456',
  //   content: 'Hello!',
  //   type: 'TEXT',
  //   createdAt: '2025-01-27T10:00:00Z'
  // }
});
```

**Test typing indicator:**
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

// Listen for typing events
socket.on('message:typing', (data) => {
  console.log('⌨️ User typing:', data);
  // { userId: 'user_456', conversationId: 'conv_123', isTyping: true }
});
```

**Test read receipts:**
```javascript
// Mark message as read
socket.emit('message:read', {
  messageId: 'msg_789',
  conversationId: 'conv_123'
});

// Listen for read events
socket.on('message:read', (data) => {
  console.log('✓✓ Message read:', data);
  // { messageId: 'msg_789', userId: 'user_456', readAt: '...' }
});
```

### 9.3 Test Conversation Events

**Join conversation:**
```javascript
socket.emit('conversation:joined', {
  conversationId: 'conv_123'
});

socket.on('conversation:joined:ack', (data) => {
  console.log('✅ Joined conversation:', data);
});
```

**Leave conversation:**
```javascript
socket.emit('conversation:leaved', {
  conversationId: 'conv_123'
});

socket.on('conversation:leaved:ack', (data) => {
  console.log('✅ Left conversation:', data);
});
```

**User status updates:**
```javascript
socket.on('user:status', (data) => {
  console.log('👤 User status changed:', data);
  // { userId: 'user_456', status: 'online', lastSeen: '...' }
});
```

### 9.4 Document Socket.IO Events

**Create reference document:**
```markdown
# Socket.IO Events Reference

## Client → Server Events

### message:sent
- **Purpose:** Send a new message
- **Payload:** { conversationId, content, type, attachments }
- **Acknowledgment:** message:sent:ack

### message:typing
- **Purpose:** Indicate typing status
- **Payload:** { conversationId, isTyping }
- **No acknowledgment**

### message:read
- **Purpose:** Mark message as read
- **Payload:** { messageId, conversationId }
- **No acknowledgment**

### conversation:joined
- **Purpose:** Join a conversation room
- **Payload:** { conversationId }
- **Acknowledgment:** conversation:joined:ack

### conversation:leaved
- **Purpose:** Leave a conversation room
- **Payload:** { conversationId }
- **Acknowledgment:** conversation:leaved:ack

## Server → Client Events

### message:received
- **Purpose:** New message notification
- **Payload:** Full message object
- **Trigger:** When any user sends a message

### message:typing
- **Purpose:** Typing indicator
- **Payload:** { userId, conversationId, isTyping }
- **Trigger:** When user starts/stops typing

### message:read
- **Purpose:** Read receipt notification
- **Payload:** { messageId, userId, readAt }
- **Trigger:** When user reads a message

### user:status
- **Purpose:** User online/offline status
- **Payload:** { userId, status, lastSeen }
- **Trigger:** When user connects/disconnects

### conversation:updated
- **Purpose:** Conversation metadata changed
- **Payload:** Updated conversation object
- **Trigger:** When conversation is modified
```

Save this to: `.kiro/specs/foundation-setup/SOCKETIO_EVENTS_REFERENCE.md`

### 9.5 Complete Socket.IO Test Script

**Create comprehensive test script:**
```javascript
// .kiro/specs/foundation-setup/scripts/test_socketio.js
const io = require('socket.io-client');

const API_URL = process.env.API_URL || 'https://dev-api.sharitek.com';
const ACCESS_TOKEN = process.env.ACCESS_TOKEN;

if (!ACCESS_TOKEN) {
  console.error('❌ ACCESS_TOKEN environment variable required');
  process.exit(1);
}

console.log('🔌 Connecting to Socket.IO server...');

const socket = io(API_URL, {
  auth: { token: ACCESS_TOKEN },
  transports: ['websocket']
});

let testsPassed = 0;
let testsFailed = 0;

// Test 1: Connection
socket.on('connect', () => {
  console.log('✅ Test 1: Connection successful');
  console.log('   Socket ID:', socket.id);
  testsPassed++;
  
  // Test 2: Join conversation
  socket.emit('conversation:joined', { conversationId: 'test_conv' });
});

socket.on('conversation:joined:ack', (data) => {
  console.log('✅ Test 2: Joined conversation');
  testsPassed++;
  
  // Test 3: Send message
  socket.emit('message:sent', {
    conversationId: 'test_conv',
    content: 'Test message',
    type: 'TEXT'
  });
});

socket.on('message:sent:ack', (data) => {
  console.log('✅ Test 3: Message sent acknowledged');
  testsPassed++;
  
  // Test 4: Typing indicator
  socket.emit('message:typing', {
    conversationId: 'test_conv',
    isTyping: true
  });
  
  setTimeout(() => {
    socket.emit('message:typing', {
      conversationId: 'test_conv',
      isTyping: false
    });
    console.log('✅ Test 4: Typing indicator sent');
    testsPassed++;
    
    // Complete tests
    completeTests();
  }, 1000);
});

// Listen for events
socket.on('message:received', (message) => {
  console.log('📨 Received message:', message.content);
});

socket.on('message:typing', (data) => {
  console.log('⌨️ User typing:', data.userId);
});

socket.on('user:status', (data) => {
  console.log('👤 User status:', data.userId, data.status);
});

socket.on('connect_error', (error) => {
  console.error('❌ Connection error:', error.message);
  testsFailed++;
  completeTests();
});

socket.on('disconnect', () => {
  console.log('🔌 Disconnected');
});

function completeTests() {
  console.log('\n📊 Test Results:');
  console.log(`   Passed: ${testsPassed}`);
  console.log(`   Failed: ${testsFailed}`);
  
  socket.disconnect();
  process.exit(testsFailed > 0 ? 1 : 0);
}

// Timeout after 30 seconds
setTimeout(() => {
  console.error('❌ Tests timed out');
  testsFailed++;
  completeTests();
}, 30000);
```

**Run the test:**
```bash
npm install socket.io-client
ACCESS_TOKEN="your_token" node .kiro/specs/foundation-setup/scripts/test_socketio.js
```

## Task 10: Prepare Test Data and Test Accounts

### 10.1 Create Test User Accounts

**Test accounts to create:**
```
User 1: 0989006188abc (provided)
User 2: 0989006189test
User 3: 0989006190test
User 4: 0989006191test
User 5: 0989006192test
```

**Document in `.env.test`:**
```bash
TEST_USER_1_PHONE=0989006188abc
TEST_USER_1_PASSWORD=password123

TEST_USER_2_PHONE=0989006189test
TEST_USER_2_PASSWORD=password123

TEST_USER_3_PHONE=0989006190test
TEST_USER_3_PASSWORD=password123

TEST_USER_4_PHONE=0989006191test
TEST_USER_4_PASSWORD=password123

TEST_USER_5_PHONE=0989006192test
TEST_USER_5_PASSWORD=password123
```

**Verify accounts:**
```bash
# Test each account login
for phone in 0989006188abc 0989006189test 0989006190test 0989006191test 0989006192test; do
  echo "Testing $phone..."
  curl -X POST https://dev-api.sharitek.com/auth/login \
    -H "Content-Type: application/json" \
    -d "{\"phone\":\"$phone\",\"password\":\"password123\"}"
  echo ""
done
```

### 10.2 Create Test Conversations

**1-on-1 conversations:**
- User 1 ↔ User 2
- User 1 ↔ User 3
- User 2 ↔ User 3

**Group conversations:**
- "Test Group 1": Users 1, 2, 3
- "Test Group 2": Users 1, 2, 3, 4, 5
- "Large Group": Users 1-5 + more

**Create via GraphQL:**
```graphql
mutation CreateTestConversations {
  group1: chatGroupAdd(input: {
    name: "Test Group 1"
    description: "Testing group with 3 members"
    memberIds: ["user_1", "user_2", "user_3"]
  }) {
    id
    name
  }
  
  group2: chatGroupAdd(input: {
    name: "Test Group 2"
    description: "Testing group with 5 members"
    memberIds: ["user_1", "user_2", "user_3", "user_4", "user_5"]
  }) {
    id
    name
  }
}
```

### 10.3 Prepare Test Data Scenarios

**Scenario 1: Empty Conversation**
- Create new conversation
- No messages
- Test: Initial load, empty state UI

**Scenario 2: Conversation with Many Messages (Pagination)**
- Create conversation
- Add 150+ messages
- Test: Pagination, scroll loading, performance

**Scenario 3: Conversation with Media**
- Create conversation
- Add messages with:
  - Images
  - Videos
  - Documents
  - Audio files
- Test: Media upload, download, preview

**Scenario 4: Conversation with Reactions**
- Create conversation
- Add messages
- Add various reactions (👍, ❤️, 😂, 😮, 😢, 🙏)
- Test: Reaction UI, reaction counts

**Scenario 5: Real-time Updates**
- Open conversation in 2 devices
- Send messages from one device
- Test: Real-time delivery, typing indicators, read receipts

**Document scenarios:**

```markdown
# Test Data Scenarios

| Scenario | Conversation ID | Messages | Special Features | Test Purpose |
|----------|----------------|----------|------------------|--------------|
| Empty | test_empty_001 | 0 | None | Empty state UI |
| Pagination | test_paginate_001 | 150+ | None | Pagination, scroll |
| Media | test_media_001 | 20 | Images, videos, docs | Media handling |
| Reactions | test_reactions_001 | 30 | Multiple reactions | Reaction UI |
| Real-time | test_realtime_001 | Varies | Live updates | Socket.IO events |
```

Save this to: `.kiro/specs/foundation-setup/TEST_DATA_SCENARIOS.md`

### 10.4 Verify Test Environment Isolation

**Check environment separation:**
```bash
# Development environment
echo "Dev API: https://dev-api.sharitek.com"
echo "Dev Database: dev_sharitek_chat"

# Staging environment
echo "Staging API: https://staging-api.sharitek.com"
echo "Staging Database: staging_sharitek_chat"

# Production environment (DO NOT USE FOR TESTING!)
echo "Production API: https://api.sharitek.com"
echo "Production Database: prod_sharitek_chat"
```

**Verify data isolation:**
- Test data only in dev/staging
- No production data access during testing
- Separate databases confirmed
- Separate API endpoints confirmed

**Document environment URLs:**
```markdown
# Environment Configuration

## Development
- API URL: https://dev-api.sharitek.com
- GraphQL: https://dev-api.sharitek.com/graphql
- Socket.IO: https://dev-api.sharitek.com/socket.io
- Database: dev_sharitek_chat
- Purpose: Active development and testing

## Staging
- API URL: https://staging-api.sharitek.com
- GraphQL: https://staging-api.sharitek.com/graphql
- Socket.IO: https://staging-api.sharitek.com/socket.io
- Database: staging_sharitek_chat
- Purpose: Pre-production testing

## Production
- API URL: https://api.sharitek.com
- GraphQL: https://api.sharitek.com/graphql
- Socket.IO: https://api.sharitek.com/socket.io
- Database: prod_sharitek_chat
- Purpose: Live production (DO NOT USE FOR TESTING!)
```

### 10.5 Setup Test Data Reset Mechanism

**Create reset script:**
```bash
#!/bin/bash
# .kiro/specs/foundation-setup/scripts/reset_test_data.sh

echo "🔄 Resetting test data..."

# Get access token
ACCESS_TOKEN=$(curl -s -X POST https://dev-api.sharitek.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"0989006188abc","password":"password123"}' \
  | jq -r '.accessToken')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to authenticate"
  exit 1
fi

# Delete test conversations
echo "Deleting test conversations..."
curl -X POST https://dev-api.sharitek.com/graphql \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { deleteTestConversations { success } }"
  }'

# Recreate test data
echo "Creating fresh test data..."
curl -X POST https://dev-api.sharitek.com/graphql \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { seedTestData { success } }"
  }'

echo "✅ Test data reset complete"
```

**Run reset:**
```bash
chmod +x .kiro/specs/foundation-setup/scripts/reset_test_data.sh
./.kiro/specs/foundation-setup/scripts/reset_test_data.sh
```

## Task 11: Deep Dive into API Documentation

### 11.1 Review Backend API Structure

**Backend modules to review:**
```
src/
├── modules/
│   ├── auth/           # Authentication
│   ├── chat/           # Chat features
│   │   ├── conversation/
│   │   ├── message/
│   │   └── gateway/    # Socket.IO
│   ├── user/           # User management
│   └── file/           # File uploads
```

**Key files to review:**
- `src/modules/chat/conversation/conversation.resolver.ts`
- `src/modules/chat/message/message.resolver.ts`
- `src/modules/chat/gateway/chat.gateway.ts`
- `src/models/entities/*.ts` (Entity definitions)

### 11.2 Map Backend Entities to Frontend Models

**Create mapping document:**
```markdown
# Backend ↔ Frontend Model Mapping

## Conversation Entity

### Backend (NestJS)
```typescript
class Conversation {
  id: string;
  type: ConversationType; // 'DIRECT' | 'GROUP'
  name?: string;
  avatar?: string;
  description?: string;
  members: ConversationMember[];
  lastMessage?: Message;
  lastMessageAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

### Frontend (Flutter)
```dart
class Conversation {
  final String id;
  final ConversationType type;
  final String? name;
  final String? avatar;
  final String? description;
  final List<ConversationMember> members;
  final Message? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Mapping Notes
- ✅ Field names match exactly
- ✅ Types are compatible
- ⚠️ Frontend needs `unreadCount` field (not in backend entity)
- ⚠️ Frontend needs `isTyping` field (real-time only)

## Message Entity

### Backend (NestJS)
```typescript
class Message {
  id: string;
  conversationId: string;
  senderId: string;
  sender: User;
  content: string;
  type: MessageType; // 'TEXT' | 'IMAGE' | 'VIDEO' | 'FILE' | 'AUDIO'
  attachments: Attachment[];
  reactions: Reaction[];
  replyTo?: Message;
  status: MessageStatus; // 'SENDING' | 'SENT' | 'DELIVERED' | 'READ'
  createdAt: Date;
  updatedAt: Date;
}
```

### Frontend (Flutter)
```dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final User sender;
  final String content;
  final MessageType type;
  final List<Attachment> attachments;
  final List<Reaction> reactions;
  final Message? replyTo;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Mapping Notes
- ✅ Field names match exactly
- ✅ Types are compatible
- ✅ Nested objects supported
- ⚠️ Frontend needs `localId` for offline messages
- ⚠️ Frontend needs `syncStatus` for offline sync

## User Entity

### Backend (NestJS)
```typescript
class User {
  id: string;
  phone: string;
  email?: string;
  displayName: string;
  avatar?: string;
  status: UserStatus; // 'ONLINE' | 'OFFLINE' | 'AWAY'
  lastSeen?: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

### Frontend (Flutter)
```dart
class User {
  final String id;
  final String phone;
  final String? email;
  final String displayName;
  final String? avatar;
  final UserStatus status;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Mapping Notes
- ✅ Field names match exactly
- ✅ Types are compatible
- ✅ All fields present

## Field Name Mismatches

| Backend Field | Frontend Field | Action Required |
|--------------|----------------|-----------------|
| `lastMessageAt` | `updatedAt` | ⚠️ Use `lastMessageAt` consistently |
| `sender` (object) | `senderId` (string) | ✅ Both supported |
| - | `unreadCount` | ⚠️ Add to backend response |
| - | `localId` | ✅ Frontend-only (offline) |
| - | `syncStatus` | ✅ Frontend-only (offline) |

## Missing Fields in Frontend

1. **Conversation.unreadCount** - Need to add to GraphQL response
2. **Conversation.isTyping** - Real-time only, not persisted
3. **Message.localId** - Frontend-only for offline messages
4. **Message.syncStatus** - Frontend-only for offline sync

## Action Items

- [ ] Add `unreadCount` to backend Conversation response
- [ ] Verify `lastMessageAt` vs `updatedAt` usage
- [ ] Document real-time-only fields
- [ ] Document offline-only fields
```

Save this to: `.kiro/specs/foundation-setup/BACKEND_FRONTEND_MAPPING.md`

### 11.3 Review Backend Error Responses

**Standard error format:**
```json
{
  "errors": [
    {
      "message": "User-friendly error message",
      "extensions": {
        "code": "ERROR_CODE",
        "statusCode": 400,
        "details": {
          "field": "email",
          "constraint": "isEmail"
        }
      }
    }
  ]
}
```

**Common error codes:**
```markdown
# Backend Error Codes

## Authentication Errors (401)
- `UNAUTHORIZED`: No token provided
- `INVALID_TOKEN`: Token is invalid or expired
- `TOKEN_EXPIRED`: Token has expired

## Validation Errors (400)
- `VALIDATION_ERROR`: Input validation failed
- `INVALID_INPUT`: Invalid input format
- `MISSING_FIELD`: Required field missing

## Not Found Errors (404)
- `NOT_FOUND`: Resource not found
- `CONVERSATION_NOT_FOUND`: Conversation doesn't exist
- `MESSAGE_NOT_FOUND`: Message doesn't exist
- `USER_NOT_FOUND`: User doesn't exist

## Permission Errors (403)
- `FORBIDDEN`: No permission to access resource
- `NOT_MEMBER`: Not a member of conversation
- `INSUFFICIENT_PERMISSIONS`: Insufficient permissions

## Server Errors (500)
- `INTERNAL_ERROR`: Internal server error
- `DATABASE_ERROR`: Database operation failed
- `EXTERNAL_SERVICE_ERROR`: External service failed
```

**Frontend error handling mapping:**
```dart
// Map backend error codes to frontend Failures
Failure mapErrorToFailure(GraphQLError error) {
  final code = error.extensions?['code'] as String?;
  final message = error.message;
  
  switch (code) {
    case 'UNAUTHORIZED':
    case 'INVALID_TOKEN':
    case 'TOKEN_EXPIRED':
      return AuthenticationFailure(message: message);
    
    case 'VALIDATION_ERROR':
    case 'INVALID_INPUT':
    case 'MISSING_FIELD':
      return ValidationFailure(message: message);
    
    case 'NOT_FOUND':
    case 'CONVERSATION_NOT_FOUND':
    case 'MESSAGE_NOT_FOUND':
      return NotFoundFailure(message: message);
    
    case 'FORBIDDEN':
    case 'NOT_MEMBER':
    case 'INSUFFICIENT_PERMISSIONS':
      return PermissionFailure(message: message);
    
    case 'INTERNAL_ERROR':
    case 'DATABASE_ERROR':
    default:
      return ServerFailure(message: message);
  }
}
```

### 11.4 Create API Integration Checklist

**Phase 1 API Operations:**
- [ ] Authentication
  - [ ] Login
  - [ ] Logout
  - [ ] Token refresh
  - [ ] Get current user

- [ ] Conversations
  - [ ] List conversations (paginated)
  - [ ] Get conversation detail
  - [ ] Create group conversation
  - [ ] Update conversation
  - [ ] Delete conversation
  - [ ] Leave conversation

- [ ] Messages
  - [ ] List messages (paginated)
  - [ ] Send message
  - [ ] Edit message
  - [ ] Delete message
  - [ ] React to message
  - [ ] Reply to message

- [ ] Real-time Events
  - [ ] Connect to Socket.IO
  - [ ] Join conversation room
  - [ ] Leave conversation room
  - [ ] Listen for new messages
  - [ ] Listen for typing indicators
  - [ ] Listen for read receipts
  - [ ] Listen for user status

**Phase 2 API Operations:**
- [ ] File uploads
- [ ] Voice messages
- [ ] Video calls
- [ ] Search messages
- [ ] Archive conversations

**Phase 3 API Operations:**
- [ ] Message forwarding
- [ ] Polls
- [ ] Mentions
- [ ] Push notifications

**Phase 4 API Operations:**
- [ ] Message encryption
- [ ] Backup/restore
- [ ] Export chat history

## Task 12: Checkpoint - Day 2 Complete

### Verification Checklist

**Backend API Access:**
- [ ] All developers can access API
- [ ] Authentication working for all
- [ ] Test accounts created and verified
- [ ] API credentials documented securely

**GraphQL Testing:**
- [ ] GraphQL playground accessible
- [ ] All conversation queries tested
- [ ] All message queries tested
- [ ] All mutations tested
- [ ] Pagination verified working
- [ ] GraphQL operations documented

**Socket.IO Testing:**
- [ ] Socket.IO connection successful
- [ ] Message events tested
- [ ] Conversation events tested
- [ ] Typing indicators tested
- [ ] Read receipts tested
- [ ] Socket.IO events documented

**Test Data:**
- [ ] 5 test accounts created
- [ ] Test conversations created
- [ ] Test messages added
- [ ] Test scenarios documented
- [ ] Test data reset mechanism working

**Documentation:**
- [ ] GraphQL operations reference created
- [ ] Socket.IO events reference created
- [ ] Backend-Frontend mapping documented
- [ ] Error codes documented
- [ ] API integration checklist created

### Issues and Blockers

**Document any issues:**
```markdown
# Day 2 Issues Log

## Issue 1: [Title]
- **Description:** ...
- **Impact:** ...
- **Status:** Open/Resolved
- **Resolution:** ...

## Issue 2: [Title]
- **Description:** ...
- **Impact:** ...
- **Status:** Open/Resolved
- **Resolution:** ...
```

### Day 2 Sign-off

**Team Lead Approval:**
- [ ] All Day 2 tasks completed
- [ ] All verification checks passed
- [ ] Documentation complete
- [ ] No blocking issues
- [ ] Team ready for Day 3

**Signature:** ________________  
**Date:** ________________

---

**Next:** Day 3 - Architecture Review (Tasks 13-20)

