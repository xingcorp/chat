# GraphQL Operations Reference

## Overview

This document provides a complete reference for all GraphQL operations available in the Sharitek Office Chat backend API.

**Base URL:** `https://dev-api.sharitek.com/graphql`  
**Authentication:** Bearer token in Authorization header  
**Test Account:** 0989006188abc

---

## Queries

### chatConversationList

**Purpose:** Get paginated list of conversations for the current user

**Parameters:**
- `page: Int!` - Page number (starts at 1)
- `limit: Int!` - Number of items per page
- `sortBy: String` - Field to sort by (default: "updatedAt")
- `sortOrder: String` - Sort order: "ASC" or "DESC" (default: "DESC")

**Returns:** Paginated conversation list with metadata

**Example:**
```graphql
query GetConversations($page: Int!, $limit: Int!) {
  chatConversationList(
    page: $page
    limit: $limit
    sortBy: "updatedAt"
    sortOrder: "DESC"
  ) {
    items {
      id
      type
      name
      avatar
      description
      lastMessage {
        id
        content
        senderId
        createdAt
      }
      unreadCount
      members {
        id
        displayName
        avatar
      }
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
  "page": 1,
  "limit": 20
}
```

---

### chatConversationDetail

**Purpose:** Get detailed information about a specific conversation

**Parameters:**
- `id: ID!` - Conversation ID

**Returns:** Full conversation details including all members

**Example:**
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
      joinedAt
    }
    settings {
      muteNotifications
      pinned
    }
    createdBy
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

---

### chatMessageList

**Purpose:** Get paginated messages for a conversation

**Parameters:**
- `conversationId: ID!` - Conversation ID
- `page: Int!` - Page number (starts at 1)
- `limit: Int!` - Number of messages per page
- `sortBy: String` - Field to sort by (default: "createdAt")
- `sortOrder: String` - Sort order: "ASC" or "DESC" (default: "DESC")

**Returns:** Paginated message list with attachments and reactions

**Example:**
```graphql
query GetMessages(
  $conversationId: ID!
  $page: Int!
  $limit: Int!
) {
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
      sender {
        id
        displayName
        avatar
      }
      content
      type
      attachments {
        id
        url
        type
        name
        size
        thumbnailUrl
      }
      reactions {
        emoji
        userId
        user {
          id
          displayName
        }
        createdAt
      }
      replyTo {
        id
        content
        senderId
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

---

### chatUserSearch

**Purpose:** Search for users to start conversations

**Parameters:**
- `query: String!` - Search query (name, email, phone)
- `limit: Int` - Maximum results (default: 10)

**Returns:** List of matching users

**Example:**
```graphql
query SearchUsers($query: String!, $limit: Int) {
  chatUserSearch(query: $query, limit: $limit) {
    id
    displayName
    avatar
    phone
    email
    status
  }
}
```

**Variables:**
```json
{
  "query": "john",
  "limit": 10
}
```

---

## Mutations

### chatMessageAdd

**Purpose:** Send a new message to a conversation

**Input:**
- `conversationId: ID!` - Target conversation
- `content: String!` - Message content
- `type: MessageType!` - Message type: TEXT, IMAGE, VIDEO, FILE, AUDIO
- `attachments: [AttachmentInput!]` - Optional attachments
- `replyToId: ID` - Optional message to reply to

**Returns:** Created message with ID and status

**Example:**
```graphql
mutation SendMessage($input: ChatMessageAddInput!) {
  chatMessageAdd(input: $input) {
    id
    conversationId
    senderId
    content
    type
    attachments {
      id
      url
      type
    }
    status
    createdAt
  }
}
```

**Variables (Text Message):**
```json
{
  "input": {
    "conversationId": "conv_123",
    "content": "Hello, how are you?",
    "type": "TEXT"
  }
}
```

**Variables (With Attachment):**
```json
{
  "input": {
    "conversationId": "conv_123",
    "content": "Check out this image",
    "type": "IMAGE",
    "attachments": [
      {
        "url": "https://storage.example.com/image.jpg",
        "type": "IMAGE",
        "name": "image.jpg",
        "size": 1024000
      }
    ]
  }
}
```

**Variables (Reply):**
```json
{
  "input": {
    "conversationId": "conv_123",
    "content": "Thanks for the info!",
    "type": "TEXT",
    "replyToId": "msg_456"
  }
}
```

---

### chatGroupAdd

**Purpose:** Create a new group conversation

**Input:**
- `name: String!` - Group name
- `description: String` - Optional group description
- `memberIds: [ID!]!` - List of member user IDs
- `avatar: String` - Optional group avatar URL

**Returns:** Created group conversation

**Example:**
```graphql
mutation CreateGroup($input: ChatGroupAddInput!) {
  chatGroupAdd(input: $input) {
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
    createdBy
    createdAt
  }
}
```

**Variables:**
```json
{
  "input": {
    "name": "Project Team",
    "description": "Discussion for Project X",
    "memberIds": ["user_1", "user_2", "user_3"],
    "avatar": "https://storage.example.com/group-avatar.jpg"
  }
}
```

---

### chatMessageReact

**Purpose:** Add or remove a reaction to a message

**Input:**
- `messageId: ID!` - Target message
- `emoji: String!` - Emoji reaction (e.g., "👍", "❤️", "😂")
- `action: ReactionAction!` - Action: ADD or REMOVE

**Returns:** Updated message with reactions

**Example:**
```graphql
mutation ReactToMessage($input: ChatMessageReactInput!) {
  chatMessageReact(input: $input) {
    id
    reactions {
      emoji
      userId
      user {
        id
        displayName
      }
      createdAt
    }
  }
}
```

**Variables (Add Reaction):**
```json
{
  "input": {
    "messageId": "msg_789",
    "emoji": "👍",
    "action": "ADD"
  }
}
```

**Variables (Remove Reaction):**
```json
{
  "input": {
    "messageId": "msg_789",
    "emoji": "👍",
    "action": "REMOVE"
  }
}
```

---

### chatMessageUpdate

**Purpose:** Edit an existing message

**Input:**
- `messageId: ID!` - Message to edit
- `content: String!` - New content

**Returns:** Updated message

**Example:**
```graphql
mutation EditMessage($input: ChatMessageUpdateInput!) {
  chatMessageUpdate(input: $input) {
    id
    content
    updatedAt
    isEdited
  }
}
```

**Variables:**
```json
{
  "input": {
    "messageId": "msg_789",
    "content": "Updated message content"
  }
}
```

---

### chatMessageDelete

**Purpose:** Delete a message

**Input:**
- `messageId: ID!` - Message to delete

**Returns:** Success status

**Example:**
```graphql
mutation DeleteMessage($messageId: ID!) {
  chatMessageDelete(messageId: $messageId) {
    success
    message
  }
}
```

**Variables:**
```json
{
  "messageId": "msg_789"
}
```

---

### chatConversationUpdate

**Purpose:** Update conversation settings

**Input:**
- `conversationId: ID!` - Conversation to update
- `name: String` - New name (groups only)
- `avatar: String` - New avatar URL
- `description: String` - New description

**Returns:** Updated conversation

**Example:**
```graphql
mutation UpdateConversation($input: ChatConversationUpdateInput!) {
  chatConversationUpdate(input: $input) {
    id
    name
    avatar
    description
    updatedAt
  }
}
```

**Variables:**
```json
{
  "input": {
    "conversationId": "conv_123",
    "name": "Updated Group Name",
    "description": "Updated description"
  }
}
```

---

### chatConversationLeave

**Purpose:** Leave a group conversation

**Input:**
- `conversationId: ID!` - Conversation to leave

**Returns:** Success status

**Example:**
```graphql
mutation LeaveConversation($conversationId: ID!) {
  chatConversationLeave(conversationId: $conversationId) {
    success
    message
  }
}
```

**Variables:**
```json
{
  "conversationId": "conv_123"
}
```

---

## Subscriptions

### messageReceived

**Purpose:** Real-time notification of new messages

**Parameters:**
- `conversationId: ID!` - Conversation to subscribe to

**Returns:** Stream of new messages

**Example:**
```graphql
subscription OnMessageReceived($conversationId: ID!) {
  messageReceived(conversationId: $conversationId) {
    id
    conversationId
    senderId
    sender {
      id
      displayName
      avatar
    }
    content
    type
    attachments {
      id
      url
      type
    }
    createdAt
  }
}
```

**Variables:**
```json
{
  "conversationId": "conv_123"
}
```

---

### conversationUpdated

**Purpose:** Real-time notification of conversation changes

**Parameters:**
- `userId: ID!` - User ID to subscribe for

**Returns:** Stream of conversation updates

**Example:**
```graphql
subscription OnConversationUpdated($userId: ID!) {
  conversationUpdated(userId: $userId) {
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
}
```

**Variables:**
```json
{
  "userId": "user_123"
}
```

---

## Types Reference

### ConversationType
```graphql
enum ConversationType {
  DIRECT    # 1-on-1 conversation
  GROUP     # Group conversation
}
```

### MessageType
```graphql
enum MessageType {
  TEXT      # Text message
  IMAGE     # Image attachment
  VIDEO     # Video attachment
  FILE      # File attachment
  AUDIO     # Audio/voice message
}
```

### MessageStatus
```graphql
enum MessageStatus {
  SENDING   # Message being sent
  SENT      # Message sent to server
  DELIVERED # Message delivered to recipient
  READ      # Message read by recipient
  FAILED    # Message failed to send
}
```

### UserStatus
```graphql
enum UserStatus {
  ONLINE    # User is online
  OFFLINE   # User is offline
  AWAY      # User is away
}
```

### ReactionAction
```graphql
enum ReactionAction {
  ADD       # Add reaction
  REMOVE    # Remove reaction
}
```

---

## Error Handling

### Common Error Codes

**Authentication Errors (401):**
- `UNAUTHORIZED` - No token provided
- `INVALID_TOKEN` - Token is invalid or expired
- `TOKEN_EXPIRED` - Token has expired

**Validation Errors (400):**
- `VALIDATION_ERROR` - Input validation failed
- `INVALID_INPUT` - Invalid input format
- `MISSING_FIELD` - Required field missing

**Not Found Errors (404):**
- `NOT_FOUND` - Resource not found
- `CONVERSATION_NOT_FOUND` - Conversation doesn't exist
- `MESSAGE_NOT_FOUND` - Message doesn't exist
- `USER_NOT_FOUND` - User doesn't exist

**Permission Errors (403):**
- `FORBIDDEN` - No permission to access resource
- `NOT_MEMBER` - Not a member of conversation
- `INSUFFICIENT_PERMISSIONS` - Insufficient permissions

**Server Errors (500):**
- `INTERNAL_ERROR` - Internal server error
- `DATABASE_ERROR` - Database operation failed

### Error Response Format

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

---

## Best Practices

### Pagination
- Always use pagination for lists
- Recommended page size: 20-50 items
- Use `hasMore` field to check for more pages

### Caching
- Cache conversation lists locally
- Cache messages for offline access
- Invalidate cache on updates

### Error Handling
- Always handle GraphQL errors
- Map error codes to user-friendly messages
- Implement retry logic for network errors

### Performance
- Request only needed fields
- Use fragments for reusable field sets
- Batch multiple queries when possible

---

**Last Updated:** 2025-01-27  
**API Version:** 1.0  
**Backend:** NestJS + GraphQL
