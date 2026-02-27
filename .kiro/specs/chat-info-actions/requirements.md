# Tài liệu Yêu cầu — Block/Unblock User, Report Chat, Notification Settings

## Giới thiệu

Triển khai các chức năng quản lý chat: block/unblock user, report chat, và cài đặt thông báo. Flutter app đã có đầy đủ interface (`IChatInfoRepository`) và remote datasource (`ChatInfoRemoteDataSource`), nhưng tất cả implementation đều là `// TODO: Implement API call` trả về giá trị mặc định. Cần kết nối với backend API thực tế.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- User management: block/unblock user APIs (cần xác nhận endpoint cụ thể)
- Notification service: mute/unmute conversation
- Report system: report chat/user

**Flutter app đã có:**
- `IChatInfoRepository` interface đầy đủ: `blockUser`, `unblockUser`, `isUserBlocked`, `reportChat`, `getNotificationSettings`, `updateNotificationSettings`
- `ChatInfoRemoteDataSource` implementation với tất cả TODO stubs
- `NotificationSettingsModel` và `NotificationSettings` entity
- `ChatInfoRepositoryImpl` (cần verify)
- Chat info page UI (cần verify có hiển thị các nút action không)

**Cần bổ sung:**
- Implement API calls thực tế trong `ChatInfoRemoteDataSource`
- GraphQL operations cho block/unblock/report/notification
- UI cho block/unblock button, report dialog, notification toggle
- BLoC xử lý các actions
- Xác nhận dialog trước khi block/report

## Thuật ngữ

- **Block_User**: Chặn user, không nhận tin nhắn từ user đó trong direct chat
- **Unblock_User**: Bỏ chặn user đã block
- **Report_Chat**: Báo cáo cuộc trò chuyện vi phạm với lý do
- **Notification_Settings**: Cài đặt thông báo cho cuộc trò chuyện (mute/unmute)
- **Chat_Info_Page**: Trang thông tin chi tiết cuộc trò chuyện

## Yêu cầu

### Yêu cầu 1: Block User

**User Story:** Là người dùng, tôi muốn block user trong direct chat để không nhận tin nhắn từ họ nữa.

#### Tiêu chí chấp nhận

1. THE Chat_Info_Page SHALL hiển thị nút "Chặn người dùng" cho direct chat
2. WHEN người dùng nhấn nút block, THE system SHALL hiển thị `AppConfirmDialog` xác nhận
3. WHEN người dùng xác nhận block, THE system SHALL gọi API block user
4. AFTER block thành công, THE system SHALL cập nhật UI hiển thị trạng thái "Đã chặn" và đổi nút thành "Bỏ chặn"
5. AFTER block thành công, THE system SHALL hiển thị `AppSnackBar` thông báo thành công
6. THE nút block SHALL chỉ hiển thị trong direct chat, không hiển thị trong group chat

### Yêu cầu 2: Unblock User

**User Story:** Là người dùng, tôi muốn bỏ chặn user đã block để nhận lại tin nhắn từ họ.

#### Tiêu chí chấp nhận

1. WHEN user đã bị block, THE Chat_Info_Page SHALL hiển thị nút "Bỏ chặn"
2. WHEN người dùng nhấn unblock, THE system SHALL gọi API unblock user (không cần confirm dialog)
3. AFTER unblock thành công, THE system SHALL cập nhật UI đổi nút thành "Chặn người dùng"
4. AFTER unblock thành công, THE system SHALL hiển thị `AppSnackBar` thông báo thành công

### Yêu cầu 3: Report Chat

**User Story:** Là người dùng, tôi muốn báo cáo cuộc trò chuyện vi phạm.

#### Tiêu chí chấp nhận

1. THE Chat_Info_Page SHALL hiển thị nút "Báo cáo" cho cả direct và group chat
2. WHEN người dùng nhấn report, THE system SHALL hiển thị dialog với danh sách lý do báo cáo (spam, quấy rối, nội dung không phù hợp, khác)
3. WHEN người dùng chọn "Khác", THE system SHALL hiển thị `AppTextArea` để nhập lý do tùy chỉnh
4. WHEN người dùng xác nhận report, THE system SHALL gọi API report chat với lý do đã chọn
5. AFTER report thành công, THE system SHALL hiển thị `AppSnackBar` cảm ơn đã báo cáo
6. THE system SHALL disable nút report trong 24h sau khi đã report (tránh spam)

### Yêu cầu 4: Notification Settings (Mute/Unmute)

**User Story:** Là người dùng, tôi muốn tắt/bật thông báo cho cuộc trò chuyện cụ thể.

#### Tiêu chí chấp nhận

1. THE Chat_Info_Page SHALL hiển thị `AppSwitch` toggle cho "Tắt thông báo"
2. THE system SHALL load trạng thái mute hiện tại khi mở Chat_Info_Page
3. WHEN người dùng toggle switch, THE system SHALL gọi API cập nhật notification settings
4. THE system SHALL hiển thị trạng thái loading trên switch khi đang gọi API
5. IF API thất bại, THE system SHALL revert switch về trạng thái cũ và hiển thị `AppSnackBar` lỗi

### Yêu cầu 5: Kiểm tra trạng thái Block khi mở Chat

**User Story:** Là người dùng, tôi muốn biết user đã bị block hay chưa khi mở thông tin chat.

#### Tiêu chí chấp nhận

1. WHEN mở Chat_Info_Page cho direct chat, THE system SHALL gọi API kiểm tra trạng thái block
2. THE system SHALL hiển thị loading indicator khi đang kiểm tra
3. THE system SHALL hiển thị nút block/unblock phù hợp dựa trên kết quả

### Yêu cầu 6: Localization

**User Story:** Là nhà phát triển, tôi muốn tất cả chuỗi được localize.

#### Tiêu chí chấp nhận

1. THE system SHALL có localization keys cho: blockUser, unblockUser, blockConfirmTitle, blockConfirmMessage, userBlocked, userUnblocked, reportChat, reportReasonSpam, reportReasonHarassment, reportReasonInappropriate, reportReasonOther, reportSubmitted, muteNotifications, notificationSettings
2. THE system SHALL hỗ trợ cả English và Vietnamese
