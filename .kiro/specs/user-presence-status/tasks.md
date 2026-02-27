# Kế hoạch Triển khai: Trạng thái Online/Offline User (User Presence Status)

## Tổng quan

Triển khai theo thứ tự: Domain entity → Data layer → Core service → Presentation (cập nhật widgets) → Tích hợp. **Lưu ý:** Cần coordinate với backend team để thêm GraphQL query và Socket.IO event cho presence.

## Tasks

- [ ] 1. Coordinate với Backend Team
  - [ ] 1.1 Yêu cầu backend thêm GraphQL query `chatUserPresence(userIds: [String!]!)` đọc từ Redis `UserStatus` và `UserOfflineAt`
  - [ ] 1.2 Yêu cầu backend thêm Socket.IO emit `user:presence` event trong `handleConnection` và `handleDisconnect` của `ChatGateway`
  - [ ] 1.3 Xác nhận response format: `{ userId, isOnline, lastSeen }`

- [ ] 2. Tạo Domain layer
  - [ ] 2.1 Tạo `UserPresence` entity tại `flutter_chat_app/lib/domain/entities/user_presence.dart`
    - Fields: `userId`, `isOnline`, `lastSeen?`
    - Static `offline` factory
    - _Requirements: 1.4_
  - [ ] 2.2 Tạo `IPresenceRepository` interface tại `flutter_chat_app/lib/domain/repositories/i_presence_repository.dart`
    - `getUsersPresence(List<String> userIds)` → `Either<Failure, List<UserPresence>>`
    - _Requirements: 1.1, 1.3_

- [ ] 3. Tạo Data layer
  - [ ] 3.1 Tạo `PresenceQueries` GraphQL operations tại `flutter_chat_app/lib/data/graphql/presence_operations.dart`
    - Query `getUserPresence` với `userIds` parameter
    - _Requirements: 1.1_
  - [ ] 3.2 Tạo `UserPresenceModel` DTO tại `flutter_chat_app/lib/data/models/user_presence_model.dart`
    - `fromJson` factory, `toEntity()` mapper
  - [ ] 3.3 Tạo `PresenceRemoteDataSource` tại `flutter_chat_app/lib/data/datasources/presence/presence_remote_datasource.dart`
    - `@lazySingleton`, inject `GraphQLClientWrapper`
    - `getUsersPresence(userIds)` — gọi GraphQL query
    - _Requirements: 1.1, 1.3_
  - [ ] 3.4 Tạo `PresenceRepositoryImpl` tại `flutter_chat_app/lib/data/repositories/presence_repository_impl.dart`
    - `@LazySingleton(as: IPresenceRepository)`
    - Wrap trong try/catch, return `Either`
    - _Requirements: 1.1_

- [ ] 4. Tạo `PresenceService` (Core)
  - [ ] 4.1 Tạo `PresenceService` tại `flutter_chat_app/lib/core/services/presence_service.dart`
    - `@lazySingleton`, inject `IPresenceRepository`, `RealtimeService`, `AppLogger`
    - In-memory cache `Map<String, _CachedPresence>` với TTL 30s
    - `getUserPresenceStream(userId)` → `Stream<UserPresence>` via `BehaviorSubject`
    - `fetchPresenceForUsers(userIds)` — batch fetch, chỉ fetch stale IDs
    - Subscribe `RealtimeService.presenceStream` cho real-time updates
    - Update cache + notify subjects khi nhận socket event
    - `dispose()` — close tất cả subjects
    - _Requirements: 1.2, 1.3, 1.4, 2.1, 2.2, 2.3_

- [ ] 5. Mở rộng `RealtimeService` — thêm presence stream
  - [ ] 5.1 Thêm `presenceStream` vào `RealtimeService` (hoặc `EnhancedSocketManager`)
    - Subscribe Socket.IO event `user:presence`
    - Parse thành `UserPresence` object
    - _Requirements: 2.1, 2.2_

- [ ] 6. Checkpoint — Verify service layer hoạt động

- [ ] 7. Cập nhật Presentation widgets
  - [ ] 7.1 Cập nhật `LivePresenceIndicator` tại `flutter_chat_app/lib/features/chat/presentation/widgets/chat/presence_indicator.dart`
    - Thay thế TODO placeholder bằng `StreamBuilder` kết nối `PresenceService`
    - Inject `PresenceService` qua `getIt`
    - Hiển thị offline mặc định khi chưa có data
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 7.2 Cập nhật `PresenceIndicator` và `AvatarPresenceIndicator` sử dụng `AppColors` thay vì `Colors.green`/`Colors.grey`
    - _Requirements: 3.3_

- [ ] 8. Tích hợp vào Chat List
  - [ ] 8.1 Trong chat list page, gọi `presenceService.fetchPresenceForUsers(memberIds)` khi load danh sách
  - [ ] 8.2 Trong chat list item (direct chat), wrap avatar với `AvatarPresenceIndicator` kết nối `PresenceService`
    - Chỉ hiển thị cho direct chat
    - _Requirements: 3.1, 3.2, 3.4_

- [ ] 9. Tích hợp vào Chat Detail Header
  - [ ] 9.1 Trong chat detail header (direct chat), thêm `LivePresenceIndicator(userId: otherUserId)` dưới tên user
    - Hiển thị "Online" hoặc "Lần cuối X trước"
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 10. DI Registration và Code Generation
  - [ ] 10.1 Đảm bảo `PresenceService`, `PresenceRemoteDataSource`, `PresenceRepositoryImpl` đăng ký trong DI
  - [ ] 10.2 Chạy `dart run build_runner build --delete-conflicting-outputs`

- [ ] 11. Final checkpoint
  - Đảm bảo presence hiển thị đúng trên chat list và chat detail

## Ghi chú

- **BLOCKER:** Backend cần thêm GraphQL query và Socket.IO event. Task 1 phải hoàn thành trước khi test end-to-end.
- **Fallback:** Nếu backend chưa sẵn sàng, app vẫn hoạt động bình thường — tất cả hiển thị offline (graceful degradation)
- Localization keys đã có sẵn (`online`, `offline`, `lastSeenMinutesAgo`, etc.)
- `PresenceIndicator` và `AvatarPresenceIndicator` widgets đã có — chỉ cần kết nối data
- Tuân thủ Clean Architecture, base classes, design system
