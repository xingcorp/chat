# API Reference

## Tổng quan
Tài liệu này mô tả các API endpoints được sử dụng trong ứng dụng chat, bao gồm cả REST API và GraphQL API. Tài liệu này được thiết kế để giúp các nhà phát triển hiểu cách ứng dụng chat giao tiếp với backend.

## Authentication

### Cơ chế xác thực
Ứng dụng sử dụng JWT (JSON Web Token) để xác thực người dùng. Mỗi request đến API đều cần có JWT token được đính kèm trong header.

```dart
// Ví dụ cách đính kèm token vào header trong HTTP request
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/messages'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
```

### Luồng xác thực
1. Người dùng đăng nhập với email/password hoặc phương thức social login
2. Server trả về access token và refresh token
3. Access token được dùng cho các request tiếp theo
4. Khi access token hết hạn, refresh token được sử dụng để lấy access token mới
5. Nếu refresh token hết hạn, người dùng cần đăng nhập lại

### Endpoints xác thực

#### Đăng ký tài khoản
```
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "Nguyen Van A",
  "avatar": "base64-encoded-image" // Optional
}
```

**Response:**
```json
{
  "userId": "user-123",
  "email": "user@example.com",
  "fullName": "Nguyen Van A",
  "avatar": "https://cdn.example.com/avatars/user-123.jpg",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Đăng nhập
```
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "userId": "user-123",
  "email": "user@example.com",
  "fullName": "Nguyen Van A",
  "avatar": "https://cdn.example.com/avatars/user-123.jpg",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Refresh Token
```
POST /auth/refresh
```

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." // Mới nếu token rotation được bật
}
```

## GraphQL API

### Schema
Ứng dụng chat sử dụng GraphQL để tương tác với backend cho các hoạt động phức tạp. Dưới đây là schema chính:

#### Types

```graphql
type User {
  id: ID!
  email: String!
  fullName: String!
  avatar: String
  status: UserStatus!
  lastSeen: DateTime
  createdAt: DateTime!
  updatedAt: DateTime!
}

enum UserStatus {
  ONLINE
  OFFLINE
  AWAY
  DO_NOT_DISTURB
}

type Chat {
  id: ID!
  name: String
  type: ChatType!
  avatarUrl: String
  lastMessage: Message
  participants: [User!]!
  unreadCount: Int!
  createdAt: DateTime!
  updatedAt: DateTime!
}

enum ChatType {
  DIRECT
  GROUP
  CHANNEL
}

type Message {
  id: ID!
  chatId: ID!
  senderId: ID!
  sender: User!
  content: String
  attachments: [Attachment]
  reactions: [Reaction]
  readBy: [ReadReceipt]
  status: MessageStatus!
  replyTo: Message
  createdAt: DateTime!
  updatedAt: DateTime!
}

enum MessageStatus {
  SENDING
  SENT
  DELIVERED
  READ
  FAILED
}

type Attachment {
  id: ID!
  type: AttachmentType!
  url: String!
  name: String
  size: Int
  width: Int
  height: Int
  duration: Int
  thumbnailUrl: String
  createdAt: DateTime!
}

enum AttachmentType {
  IMAGE
  VIDEO
  AUDIO
  FILE
}

type Reaction {
  id: ID!
  messageId: ID!
  userId: ID!
  user: User!
  emoji: String!
  createdAt: DateTime!
}

type ReadReceipt {
  userId: ID!
  user: User!
  readAt: DateTime!
}
```

#### Queries

```graphql
type Query {
  # User Queries
  me: User!
  user(id: ID!): User
  searchUsers(query: String!, limit: Int = 20, offset: Int = 0): [User!]!
  
  # Chat Queries
  chats(limit: Int = 20, offset: Int = 0): [Chat!]!
  chat(id: ID!): Chat
  
  # Message Queries
  messages(
    chatId: ID!,
    limit: Int = 20,
    before: DateTime,
    after: DateTime
  ): [Message!]!
  message(id: ID!): Message
}
```

#### Mutations

```graphql
type Mutation {
  # User Mutations
  updateProfile(input: UpdateProfileInput!): User!
  updateStatus(status: UserStatus!): User!
  
  # Chat Mutations
  createDirectChat(userId: ID!): Chat!
  createGroupChat(name: String!, participantIds: [ID!]!): Chat!
  updateChat(id: ID!, input: UpdateChatInput!): Chat!
  addParticipants(chatId: ID!, userIds: [ID!]!): Chat!
  removeParticipant(chatId: ID!, userId: ID!): Chat!
  leaveChat(chatId: ID!): Boolean!
  
  # Message Mutations
  sendMessage(input: SendMessageInput!): Message!
  editMessage(id: ID!, content: String!): Message!
  deleteMessage(id: ID!): Boolean!
  markAsRead(chatId: ID!, messageId: ID!): Boolean!
  addReaction(messageId: ID!, emoji: String!): Reaction!
  removeReaction(messageId: ID!, reactionId: ID!): Boolean!
}

input UpdateProfileInput {
  fullName: String
  avatar: Upload
}

input UpdateChatInput {
  name: String
  avatar: Upload
}

input SendMessageInput {
  chatId: ID!
  content: String
  attachments: [Upload]
  replyToId: ID
}
```

#### Subscriptions

```graphql
type Subscription {
  messageAdded(chatId: ID): Message!
  messageUpdated(chatId: ID): Message!
  messageDeleted(chatId: ID): ID!
  chatUpdated: Chat!
  userStatusChanged(userId: ID): User!
  typingIndicator(chatId: ID!): TypingEvent!
}

type TypingEvent {
  chatId: ID!
  userId: ID!
  user: User!
  isTyping: Boolean!
}
```

### Sử dụng trong code

```dart
// Ví dụ query lấy danh sách chat
final QueryOptions options = QueryOptions(
  document: gql(r'''
    query GetChats($limit: Int, $offset: Int) {
      chats(limit: $limit, offset: $offset) {
        id
        name
        type
        avatarUrl
        lastMessage {
          id
          content
          createdAt
        }
        unreadCount
      }
    }
  '''),
  variables: {
    'limit': 20,
    'offset': 0,
  },
);

final QueryResult result = await client.query(options);

if (result.hasException) {
  // Xử lý lỗi
} else {
  final List<Chat> chats = result.data!['chats']
      .map((chat) => Chat.fromJson(chat))
      .toList();
}
```

## REST API Endpoints

Bên cạnh GraphQL, ứng dụng cũng sử dụng một số REST endpoints cho các hoạt động đơn giản.

### User Endpoints

#### Lấy thông tin người dùng hiện tại
```
GET /users/me
```

**Response:**
```json
{
  "id": "user-123",
  "email": "user@example.com",
  "fullName": "Nguyen Van A",
  "avatar": "https://cdn.example.com/avatars/user-123.jpg",
  "status": "ONLINE",
  "lastSeen": "2023-04-06T12:34:56Z",
  "createdAt": "2023-01-15T09:30:00Z",
  "updatedAt": "2023-04-06T12:34:56Z"
}
```

#### Cập nhật trạng thái người dùng
```
PUT /users/status
```

**Request Body:**
```json
{
  "status": "AWAY" // ONLINE, OFFLINE, AWAY, DO_NOT_DISTURB
}
```

**Response:**
```json
{
  "id": "user-123",
  "status": "AWAY",
  "lastSeen": "2023-04-06T12:45:30Z"
}
```

### Chat Endpoints

#### Lấy danh sách chat
```
GET /chats?limit=20&offset=0
```

**Response:**
```json
{
  "totalCount": 50,
  "chats": [
    {
      "id": "chat-123",
      "name": "Team Project",
      "type": "GROUP",
      "avatarUrl": "https://cdn.example.com/avatars/group-123.jpg",
      "lastMessage": {
        "id": "msg-456",
        "content": "Let's meet tomorrow at 9AM",
        "senderId": "user-789",
        "createdAt": "2023-04-06T11:30:00Z"
      },
      "unreadCount": 5
    },
    // ... các chat khác
  ]
}
```

#### Lấy thông tin chi tiết chat
```
GET /chats/{chatId}
```

**Response:**
```json
{
  "id": "chat-123",
  "name": "Team Project",
  "type": "GROUP",
  "avatarUrl": "https://cdn.example.com/avatars/group-123.jpg",
  "participants": [
    {
      "id": "user-123",
      "fullName": "Nguyen Van A",
      "avatar": "https://cdn.example.com/avatars/user-123.jpg",
      "status": "ONLINE"
    },
    // ... các thành viên khác
  ],
  "lastMessage": {
    "id": "msg-456",
    "content": "Let's meet tomorrow at 9AM",
    "senderId": "user-789",
    "createdAt": "2023-04-06T11:30:00Z"
  },
  "unreadCount": 5,
  "createdAt": "2023-01-20T13:45:00Z",
  "updatedAt": "2023-04-06T11:30:00Z"
}
```

### Message Endpoints

#### Lấy danh sách tin nhắn trong chat
```
GET /chats/{chatId}/messages?limit=20&before=2023-04-06T11:30:00Z
```

**Response:**
```json
{
  "totalCount": 100,
  "messages": [
    {
      "id": "msg-456",
      "chatId": "chat-123",
      "senderId": "user-789",
      "sender": {
        "id": "user-789",
        "fullName": "Tran Thi B",
        "avatar": "https://cdn.example.com/avatars/user-789.jpg"
      },
      "content": "Let's meet tomorrow at 9AM",
      "attachments": [],
      "reactions": [
        {
          "emoji": "👍",
          "count": 2,
          "users": ["user-123", "user-456"]
        }
      ],
      "readBy": [
        {
          "userId": "user-123",
          "readAt": "2023-04-06T11:31:00Z"
        }
      ],
      "status": "DELIVERED",
      "createdAt": "2023-04-06T11:30:00Z",
      "updatedAt": "2023-04-06T11:30:00Z"
    },
    // ... các tin nhắn khác
  ]
}
```

#### Gửi tin nhắn mới
```
POST /chats/{chatId}/messages
```

**Request Body:**
```json
{
  "content": "Hello everyone!",
  "replyToId": "msg-123", // Optional
  "attachments": [] // Optional
}
```

**Response:**
```json
{
  "id": "msg-789",
  "chatId": "chat-123",
  "senderId": "user-123",
  "content": "Hello everyone!",
  "replyTo": {
    "id": "msg-123",
    "content": "Previous message"
  },
  "status": "SENT",
  "createdAt": "2023-04-06T15:45:00Z",
  "updatedAt": "2023-04-06T15:45:00Z"
}
```

## Cách xử lý lỗi

### HTTP Status Codes
- `200 OK`: Request thành công
- `201 Created`: Tạo mới tài nguyên thành công
- `400 Bad Request`: Dữ liệu đầu vào không hợp lệ
- `401 Unauthorized`: Thiếu hoặc token không hợp lệ
- `403 Forbidden`: Không có quyền truy cập
- `404 Not Found`: Không tìm thấy tài nguyên
- `500 Internal Server Error`: Lỗi từ server

### Error Response Format

```json
{
  "error": {
    "code": "AUTH_INVALID_CREDENTIALS",
    "message": "Invalid email or password",
    "details": {
      "field": "password",
      "reason": "incorrect_password"
    }
  }
}
```

### GraphQL Errors

```json
{
  "errors": [
    {
      "message": "Chat not found",
      "extensions": {
        "code": "NOT_FOUND",
        "path": "chat"
      }
    }
  ],
  "data": null
}
```

## Mô hình đồng bộ hóa offline

Ứng dụng sử dụng cơ chế đồng bộ hóa offline để cho phép người dùng sử dụng ứng dụng ngay cả khi không có kết nối internet.

### Quy trình đồng bộ hóa

1. Khi người dùng gửi tin nhắn trong trạng thái offline:
   - Tin nhắn được lưu vào cơ sở dữ liệu local với trạng thái `SENDING`
   - Được hiển thị trong UI với chỉ báo "đang gửi"
   - Được thêm vào hàng đợi tin nhắn cần đồng bộ

2. Khi có kết nối internet:
   - Service đồng bộ hóa sẽ lấy tin nhắn từ hàng đợi
   - Gửi lên server theo thứ tự FIFO
   - Cập nhật trạng thái tin nhắn trong DB local và UI

3. Xử lý xung đột:
   - Nếu có xung đột, ưu tiên dữ liệu mới nhất từ server
   - Áp dụng chiến lược merge cho các hoạt động không xung đột

Chi tiết về đồng bộ hóa offline có thể được tìm thấy trong tài liệu [Offline Sync](../core/offline_sync.md).

## Rate Limiting

Các API endpoints có giới hạn số lượng request:
- `/auth/*`: 10 requests/phút
- `/users/*`: 60 requests/phút
- `/chats/*`: 120 requests/phút
- `/messages/*`: 300 requests/phút

Khi vượt quá giới hạn, server sẽ trả về status code `429 Too Many Requests` với header `Retry-After` chỉ định thời gian (giây) cần chờ trước khi gửi request tiếp theo.

## Bảo mật API

### Mã hóa dữ liệu nhạy cảm
Tất cả dữ liệu nhạy cảm (password, token) được mã hóa sử dụng HTTPS và không bao giờ được lưu trữ dưới dạng plain text.

### Giới hạn phạm vi truy cập
API tokens được cấp với phạm vi truy cập (scopes) cụ thể, giới hạn những hành động mà client có thể thực hiện.

### Xác thực hai yếu tố (2FA)
Ứng dụng hỗ trợ xác thực hai yếu tố thông qua:
- Mã OTP gửi qua SMS
- Mã xác thực từ ứng dụng Authenticator

## API Versioning

API sử dụng versioning để đảm bảo khả năng tương thích ngược:
- Các REST API có prefix `/api/v1/`
- GraphQL API có endpoints `/graphql/v1` và `/graphql/v2`

## Công cụ kiểm thử API

### Postman Collection
Các endpoints API được tài liệu hóa trong Postman Collection: [Tải xuống](https://example.com/postman/collection)

### GraphQL Playground
GraphQL API có thể được khám phá và thử nghiệm tại: `https://api.example.com/graphql/playground` 