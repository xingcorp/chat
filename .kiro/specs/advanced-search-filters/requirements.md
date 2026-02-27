# Tài liệu Yêu cầu — Advanced Search Filters UI

## Giới thiệu

Thêm UI filter nâng cao cho tìm kiếm tin nhắn. Backend `chatSearch` đã hỗ trợ đầy đủ: `senderIds`, `conversationTypes`, `messageTypes`, date range (`from`/`to`). Flutter app hiện chỉ dùng `keyword` trong `MessageSearchBloc` và `message_search_panel.dart`. Cần thêm UI cho các filter bổ sung.

### Phân tích hiện trạng

**Backend đã hỗ trợ (ChatSearchArgs):**
- `keyword: String` — từ khoá tìm kiếm ✅ (Flutter đã dùng)
- `senderIds: [String]` — lọc theo người gửi ❌ (Flutter chưa dùng)
- `conversationIds: [String]` — lọc theo conversation ❌
- `conversationTypes: [ChatConversationType]` — lọc Direct/Group ❌
- `messageTypes: [ChatMessageType]` — lọc theo loại tin nhắn ❌
- `from: Float` — timestamp bắt đầu ❌
- `to: Float` — timestamp kết thúc ❌
- `page: Int`, `size: Int` — pagination ✅

**Flutter app đã có:**
- `MessageSearchBloc` với `_onSearch` chỉ truyền `keyword` và `conversationId`
- `SearchMessagesUseCase` gọi repository với `keyword`, `conversationId`, `limit`
- `message_search_panel.dart` UI chỉ có search text field
- `ChatQueries.searchMessages` GraphQL query đã có đầy đủ filter fields

**Cần bổ sung:**
- UI filter panel: sender picker, message type chips, date range picker
- Mở rộng `MessageSearchBloc` và `SearchMessagesUseCase` để truyền filters
- Mở rộng search remote datasource để gửi filters trong GraphQL variables

## Thuật ngữ

- **Search_Filter_Panel**: UI panel chứa các filter options (sender, type, date)
- **Sender_Filter**: Filter theo người gửi, chọn từ danh sách members
- **Type_Filter**: Filter theo loại tin nhắn (text, image, video, file, etc.)
- **Date_Range_Filter**: Filter theo khoảng thời gian (từ ngày — đến ngày)
- **Active_Filters**: Các filter đang được áp dụng, hiển thị dạng chips

## Yêu cầu

### Yêu cầu 1: Search Filter Panel UI

**User Story:** Là người dùng, tôi muốn có panel filter để thu hẹp kết quả tìm kiếm tin nhắn.

#### Tiêu chí chấp nhận

1. THE message_search_panel SHALL hiển thị nút "Bộ lọc" (filter icon) cạnh search field
2. WHEN người dùng nhấn nút filter, THE system SHALL hiển thị/ẩn Search_Filter_Panel bên dưới search field
3. THE Search_Filter_Panel SHALL chứa: Sender_Filter, Type_Filter, Date_Range_Filter
4. THE Search_Filter_Panel SHALL có nút "Áp dụng" và "Xoá bộ lọc"
5. THE Search_Filter_Panel SHALL sử dụng `AppColors`, `AppDimens`, `context.l10n`

### Yêu cầu 2: Sender Filter

**User Story:** Là người dùng, tôi muốn lọc tin nhắn theo người gửi cụ thể.

#### Tiêu chí chấp nhận

1. THE Sender_Filter SHALL hiển thị danh sách members của conversation hiện tại
2. THE Sender_Filter SHALL cho phép chọn nhiều sender (multi-select)
3. THE Sender_Filter SHALL hiển thị avatar + tên cho mỗi member, sử dụng `AppAvatar` và `AppText`
4. THE Sender_Filter SHALL hiển thị `AppCheckbox` cho mỗi member
5. WHEN không có conversation cụ thể (search toàn bộ), THE Sender_Filter SHALL ẩn

### Yêu cầu 3: Message Type Filter

**User Story:** Là người dùng, tôi muốn lọc tin nhắn theo loại (text, ảnh, video, file, etc.).

#### Tiêu chí chấp nhận

1. THE Type_Filter SHALL hiển thị danh sách message types dạng `AppChip` (chips)
2. THE Type_Filter SHALL hỗ trợ multi-select
3. THE types hiển thị SHALL bao gồm: Văn bản, Hình ảnh, Video, File, Voice Note, Sticker
4. THE Type_Filter SHALL map display names sang backend enum values (TEXT, IMAGE, VIDEO, DOC, VOICE_NOTE, STICKER)

### Yêu cầu 4: Date Range Filter

**User Story:** Là người dùng, tôi muốn lọc tin nhắn trong khoảng thời gian cụ thể.

#### Tiêu chí chấp nhận

1. THE Date_Range_Filter SHALL hiển thị 2 `AppDatePicker`: "Từ ngày" và "Đến ngày"
2. THE Date_Range_Filter SHALL validate: "Từ ngày" không được sau "Đến ngày"
3. THE Date_Range_Filter SHALL convert dates sang timestamps (milliseconds) cho backend API
4. THE Date_Range_Filter SHALL cho phép chọn riêng "Từ ngày" hoặc "Đến ngày" (không bắt buộc cả hai)

### Yêu cầu 5: Hiển thị Active Filters

**User Story:** Là người dùng, tôi muốn thấy các filter đang áp dụng và có thể xoá từng filter.

#### Tiêu chí chấp nhận

1. THE system SHALL hiển thị Active_Filters dạng `AppChip` row bên dưới search field
2. Mỗi active filter chip SHALL có nút xoá (x)
3. WHEN người dùng xoá một filter chip, THE system SHALL tự động tìm kiếm lại với filters còn lại
4. THE active filter chips SHALL hiển thị: tên sender, loại tin nhắn, khoảng ngày

### Yêu cầu 6: Mở rộng Search Logic

**User Story:** Là nhà phát triển, tôi muốn search logic hỗ trợ tất cả filter parameters.

#### Tiêu chí chấp nhận

1. THE `MessageSearchBloc` SHALL nhận thêm parameters: `senderIds`, `messageTypes`, `fromDate`, `toDate`
2. THE `SearchMessagesUseCase` SHALL truyền tất cả filter parameters đến repository
3. THE search remote datasource SHALL gửi filters trong GraphQL variables cho `chatSearch`
4. THE system SHALL giữ nguyên filters khi load more (pagination)

### Yêu cầu 7: Localization

#### Tiêu chí chấp nhận

1. THE system SHALL có localization keys cho: `filters`, `applyFilters`, `clearFilters`, `filterBySender`, `filterByType`, `filterByDate`, `fromDate`, `toDate`, `noFiltersApplied`, message type display names
