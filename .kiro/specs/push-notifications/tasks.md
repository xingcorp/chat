# Kế hoạch Triển khai: Push Notification qua chatNotifyUser

## Tổng quan

Triển khai: GraphQL operation → Data layer → Domain layer → Tích hợp MessageBloc → Deep link handling → DI.

## Tasks

- [x] 1. Thêm GraphQL operation
  - [x] 1.1 Thêm `notifyUser` mutation vào `ChatMutations` trong `flutter_chat_app/lib/data/graphql/chat_operations.dart`
    - Mutation `chatNotifyUser(arguments: ChatNotifyUserData!)` trả về `Boolean`
    - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Tạo Data layer
  - [x] 2.1 Tạo `PushNotificationRemoteDataSource` tại `flutter_chat_app/lib/data/datasources/notification/push_notification_remote_datasource.dart`
    - `@lazySingleton`, inject `GraphQLClientWrapper`
    - `notifyUsers(receiverIds, title, content, metadata)` — gọi GraphQL mutation
    - _Requirements: 2.2_
  - [x] 2.2 Tạo `PushNotificationRepositoryImpl` tại `flutter_chat_app/lib/data/repositories/push_notification_repository_impl.dart`
    - `@LazySingleton(as: IPushNotificationRepository)`
    - Wrap trong try/catch, return `Either<Failure, bool>`
    - _Requirements: 2.4_

- [x] 3. Tạo Domain layer
  - [x] 3.1 Tạo `IPushNotificationRepository` interface tại `flutter_chat_app/lib/domain/repositories/i_push_notification_repository.dart`
    - `notifyUsers(receiverIds, title, content, metadata)` → `Either<Failure, bool>`
    - _Requirements: 2.1_
  - [x] 3.2 Tạo `SendPushNotificationUseCase` tại `flutter_chat_app/lib/domain/usecases/notification/send_push_notification_usecase.dart`
    - `@injectable`, inject `IPushNotificationRepository`, `AppLogger`
    - Truncate content > 100 chars
    - Skip nếu receiverIds rỗng
    - Fire-and-forget: log error, không throw
    - _Requirements: 2.3, 3.2, 3.3_

- [x] 4. Tích hợp vào MessageBloc
  - [x] 4.1 Inject `SendPushNotificationUseCase` vào `MessageBloc`
  - [x] 4.2 Sau khi send message thành công có mentions, gọi `sendPushNotification`
    - `receiverIds` = mention user IDs
    - `title` = conversation name
    - `content` = message content (truncated)
    - `metadata` = `{conversationId, messageId, type: 'mention'}`
    - Non-blocking: không await, fire-and-forget
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 5. Cập nhật Deep Link Handling
  - [x] 5.1 Cập nhật notification tap handler hiện có để parse `metadata.conversationId`
  - [x] 5.2 Navigate đến `ChatDetailsPage` khi tap notification có conversationId
  - [x] 5.3 Xử lý trường hợp conversation không tồn tại — hiển thị `AppSnackBar`
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 6. DI Registration và Code Generation
  - [x] 6.1 Đảm bảo `PushNotificationRemoteDataSource`, `PushNotificationRepositoryImpl`, `SendPushNotificationUseCase` đăng ký trong DI
  - [x] 6.2 Chạy `dart run build_runner build --delete-conflicting-outputs`

- [x] 7. Final checkpoint
  - Đảm bảo push notification gửi thành công khi mention user

## Ghi chú

- Push notification là non-critical — không block UX khi fail
- Backend API đã sẵn sàng (`chatNotifyUser`)
- Firebase Messaging setup đã có trong app
- Tuân thủ Clean Architecture, base classes, DI annotations
