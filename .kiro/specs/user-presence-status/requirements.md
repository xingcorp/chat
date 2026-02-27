# Tài liệu Yêu cầu — Trạng thái Online/Offline User (User Presence Status)

## Giới thiệu

Tính năng hiển thị trạng thái online/offline real-time của user trong chat. Backend đã có hệ thống Redis-based tracking: khi socket connect → set `UserStatus` = online, disconnect → set offline + `UserOfflineAt` timestamp (TTL 1 tháng). Flutter app có `PresenceIndicator` widget và `LivePresenceIndicator` nhưng chưa kết nối với backend — `LivePresenceIndicator` luôn hiển thị offline.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- `ChatGateway.handleConnection()`: set `RedisKey.UserStatus(userId)` = `'online'`, xoá `UserOfflineAt`
- `ChatGateway.handleDisconnect()`: set `UserStatus` = `'offline'`, set `UserOfflineAt` = timestamp
- Redis TTL 1 tháng (2592000 giây) cho cả status và offline timestamp
- Không có GraphQL query riêng cho user status — cần thêm hoặc dùng Socket.IO

**Flutter app đã có:**
- `PresenceIndicator` widget: hiển thị dot (green/grey) + text (Online/Last seen X ago)
- `AvatarPresenceIndicator` widget: dot overlay trên avatar
- `LivePresenceIndicator` widget: placeholder, luôn hiển thị offline, có TODO comment cho StreamBuilder
- Localization keys: `online`, `offline`, `lastSeenRecently`, `lastSeenMinutesAgo`, `lastSeenHoursAgo`, `lastSeenDaysAgo`
- Socket.IO infrastructure (`EnhancedSocketManager`, `RealtimeService`)

**Cần bổ sung:**
- Backend API/Socket event để query user presence status
- `PresenceService` trong Flutter kết nối với backend
- Cập nhật `LivePresenceIndicator` để dùng real data
- Hiển thị presence trên chat list (avatar dot) và chat detail header
- Cache presence data locally

## Thuật ngữ

- **User_Presence**: Trạng thái online/offline của user, bao gồm `isOnline` và `lastSeen` timestamp
- **Presence_Service**: Service Flutter quản lý và cache trạng thái presence của users
- **Presence_Indicator**: Widget hiển thị dot + text cho trạng thái presence
- **Avatar_Presence_Dot**: Dot nhỏ overlay trên avatar trong chat list

## Yêu cầu

### Yêu cầu 1: Query User Presence từ Backend

**User Story:** Là người dùng, tôi muốn thấy trạng thái online/offline chính xác của người khác.

#### Tiêu chí chấp nhận

1. THE Presence_Service SHALL query trạng thái presence của user từ backend (qua GraphQL query hoặc Socket.IO event)
2. THE Presence_Service SHALL cache kết quả locally với TTL 30 giây để giảm API calls
3. THE Presence_Service SHALL hỗ trợ batch query cho nhiều users cùng lúc (cho chat list)
4. THE Presence_Service SHALL trả về `UserPresence` object gồm `isOnline: bool` và `lastSeen: DateTime?`

### Yêu cầu 2: Real-time Presence Updates qua Socket.IO

**User Story:** Là người dùng, tôi muốn thấy trạng thái online/offline cập nhật real-time khi người khác connect/disconnect.

#### Tiêu chí chấp nhận

1. THE Presence_Service SHALL subscribe Socket.IO events cho presence changes
2. WHEN nhận được presence change event, THE Presence_Service SHALL cập nhật cache và notify listeners
3. THE system SHALL chỉ subscribe presence cho users trong conversations hiện tại (không subscribe tất cả users)

### Yêu cầu 3: Hiển thị Presence trên Chat List

**User Story:** Là người dùng, tôi muốn thấy dot xanh trên avatar của người đang online trong danh sách chat.

#### Tiêu chí chấp nhận

1. THE chat list SHALL hiển thị `AvatarPresenceIndicator` (green dot) trên avatar của user đang online trong direct chat
2. THE presence dot SHALL chỉ hiển thị cho direct chat, không hiển thị cho group chat
3. THE presence dot SHALL sử dụng `AppColors` cho màu sắc (green cho online, grey cho offline)
4. THE presence dot SHALL cập nhật real-time khi user online/offline

### Yêu cầu 4: Hiển thị Presence trên Chat Detail Header

**User Story:** Là người dùng, tôi muốn thấy trạng thái "Online" hoặc "Lần cuối X phút trước" trong header của trang chat detail.

#### Tiêu chí chấp nhận

1. THE chat detail header SHALL hiển thị `PresenceIndicator` với text cho direct chat
2. THE text SHALL hiển thị "Online" khi user đang online
3. THE text SHALL hiển thị "Lần cuối X phút/giờ/ngày trước" khi user offline, sử dụng `lastSeen` timestamp
4. THE text SHALL sử dụng `context.l10n` cho tất cả chuỗi (đã có keys)
5. THE presence SHALL cập nhật real-time

### Yêu cầu 5: Kết nối LivePresenceIndicator với Backend

**User Story:** Là nhà phát triển, tôi muốn `LivePresenceIndicator` widget hoạt động với dữ liệu thật từ backend.

#### Tiêu chí chấp nhận

1. THE `LivePresenceIndicator` SHALL sử dụng `StreamBuilder` kết nối `Presence_Service.getUserPresenceStream(userId)`
2. THE widget SHALL hiển thị loading state khi chưa có data
3. THE widget SHALL hiển thị offline mặc định khi không có kết nối
4. THE widget SHALL tự động dispose subscription khi unmount
