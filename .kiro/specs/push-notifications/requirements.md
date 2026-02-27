# Tài liệu Yêu cầu — Push Notification qua chatNotifyUser

## Giới thiệu

Tích hợp mutation `chatNotifyUser` từ backend để trigger push notification từ app đến danh sách users. Backend có `ChatNotifyResolver` nhận `receiverIds`, `title`, `content`, `metadata` và gửi push notification qua Firebase. Flutter app có Firebase setup nhưng chưa tích hợp mutation này.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- Mutation `chatNotifyUser(arguments: ChatNotifyUserData)` trả về `Boolean`
- `ChatNotifyUserData`: `receiverIds: [String!]`, `title: String!`, `content: String!`, `metadata: JSON`
- `ChatNotifyService.sendToUsers()` xử lý gửi push notification

**Flutter app đã có:**
- Firebase Messaging setup (FCM token registration)
- Push notification handling (foreground/background)
- Notification display logic

**Cần bổ sung:**
- GraphQL operation cho `chatNotifyUser`
- Service/UseCase gọi mutation
- Tích hợp vào các flow cần trigger push: mention user, important message, etc.
- Xử lý khi app ở background (notification đã nhận qua FCM)

## Thuật ngữ

- **Push_Notification**: Thông báo đẩy gửi đến thiết bị user qua Firebase Cloud Messaging
- **chatNotifyUser**: Backend mutation trigger push notification đến danh sách users
- **Notification_Metadata**: Dữ liệu bổ sung đính kèm notification (conversationId, messageId, etc.)

## Yêu cầu

### Yêu cầu 1: GraphQL Operation cho chatNotifyUser

**User Story:** Là nhà phát triển, tôi muốn có GraphQL operation để gọi mutation chatNotifyUser.

#### Tiêu chí chấp nhận

1. THE system SHALL có GraphQL mutation string cho `chatNotifyUser` với đầy đủ parameters
2. THE mutation SHALL nhận `receiverIds`, `title`, `content`, `metadata`
3. THE mutation SHALL trả về `Boolean` (success/failure)

### Yêu cầu 2: Notification Service trong Flutter

**User Story:** Là nhà phát triển, tôi muốn có service để gọi chatNotifyUser từ Flutter app.

#### Tiêu chí chấp nhận

1. THE system SHALL có `IPushNotificationRepository` interface trong domain layer
2. THE system SHALL có `PushNotificationRemoteDataSource` gọi GraphQL mutation
3. THE system SHALL có `SendPushNotificationUseCase` trong domain layer
4. THE service SHALL xử lý lỗi gracefully — log error, không crash app

### Yêu cầu 3: Tích hợp Push Notification khi Mention User

**User Story:** Là người dùng, tôi muốn người được mention nhận push notification ngay cả khi họ không đang mở app.

#### Tiêu chí chấp nhận

1. WHEN user gửi tin nhắn có mention (@user), THE system SHALL gọi `chatNotifyUser` với `receiverIds` là danh sách user được mention
2. THE notification title SHALL là tên conversation
3. THE notification content SHALL là nội dung tin nhắn (truncated 100 ký tự)
4. THE notification metadata SHALL chứa `conversationId` và `messageId` để deep link khi tap

### Yêu cầu 4: Xử lý Notification khi Tap

**User Story:** Là người dùng, tôi muốn tap vào push notification để mở đúng cuộc trò chuyện.

#### Tiêu chí chấp nhận

1. WHEN user tap push notification có metadata `conversationId`, THE system SHALL navigate đến chat detail page của conversation đó
2. IF app đang đóng, THE system SHALL mở app và navigate đến conversation
3. IF conversation không tồn tại (đã bị xoá), THE system SHALL hiển thị thông báo lỗi
