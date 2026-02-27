# Tài liệu Yêu cầu — Conversation Type Tab Filter

## Giới thiệu

Thêm tab filter trên trang danh sách chat để lọc riêng Direct (1-1) và Group conversations. Backend `chatConversationList` đã hỗ trợ filter `type: "Direct" | "Group"`. Flutter chat list page hiện hiển thị tất cả conversations không phân biệt loại.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- `chatConversationList(filters: ChatConversationListFilter)` có field `type: ChatConversationType`
- `ChatConversationType` enum: `Direct`, `Group`
- Filter là optional — không truyền sẽ trả về tất cả

**Flutter app đã có:**
- `ChatListPage` và `ChatListPanel` hiển thị danh sách conversations
- `ChatBloc` (hoặc conversation list BLoC) gọi `chatConversationList` query
- `ChatQueries.getConversationList` GraphQL query đã có field `type` trong filter
- `Chat` entity có field `type` (Direct/Group)

**Cần bổ sung:**
- Tab bar UI: "Tất cả" | "Cá nhân" | "Nhóm"
- Truyền filter `type` khi gọi API
- Giữ nguyên tab khi refresh/pagination
- Badge hiển thị unread count cho mỗi tab (optional)

## Thuật ngữ

- **Conversation_Type_Tab**: Tab bar cho phép lọc conversations theo loại
- **All_Tab**: Tab hiển thị tất cả conversations (không filter)
- **Direct_Tab**: Tab hiển thị chỉ direct (1-1) conversations
- **Group_Tab**: Tab hiển thị chỉ group conversations

## Yêu cầu

### Yêu cầu 1: Hiển thị Tab Bar trên Chat List

**User Story:** Là người dùng, tôi muốn có tab để nhanh chóng lọc giữa tất cả chat, chat cá nhân, và chat nhóm.

#### Tiêu chí chấp nhận

1. THE Chat_List_Page SHALL hiển thị tab bar với 3 tabs: "Tất cả", "Cá nhân", "Nhóm"
2. THE tab bar SHALL đặt dưới AppBar, trên danh sách conversations
3. THE tab bar SHALL sử dụng `AppColors` và `AppDimens` từ design system
4. THE tab "Tất cả" SHALL được chọn mặc định khi mở trang
5. THE tab bar SHALL sử dụng `context.l10n` cho tất cả labels

### Yêu cầu 2: Filter Conversations theo Tab

**User Story:** Là người dùng, tôi muốn danh sách chat thay đổi khi tôi chọn tab khác.

#### Tiêu chí chấp nhận

1. WHEN người dùng chọn "Tất cả", THE system SHALL hiển thị tất cả conversations (không filter type)
2. WHEN người dùng chọn "Cá nhân", THE system SHALL gọi API với `type: "Direct"` và chỉ hiển thị direct conversations
3. WHEN người dùng chọn "Nhóm", THE system SHALL gọi API với `type: "Group"` và chỉ hiển thị group conversations
4. THE system SHALL hiển thị loading indicator khi đang fetch data cho tab mới
5. THE system SHALL cache kết quả cho mỗi tab để chuyển tab nhanh (không fetch lại nếu data còn mới)

### Yêu cầu 3: Pagination và Refresh theo Tab

**User Story:** Là người dùng, tôi muốn pagination và pull-to-refresh hoạt động đúng cho mỗi tab.

#### Tiêu chí chấp nhận

1. THE system SHALL duy trì pagination state riêng cho mỗi tab
2. WHEN người dùng pull-to-refresh, THE system SHALL refresh chỉ tab hiện tại
3. WHEN người dùng scroll đến cuối, THE system SHALL load more cho tab hiện tại
4. THE system SHALL giữ nguyên tab đã chọn sau khi refresh

### Yêu cầu 4: Hiển thị trên Chat List Panel (Tablet/Desktop)

**User Story:** Là người dùng tablet, tôi muốn tab filter cũng hiển thị trên panel view.

#### Tiêu chí chấp nhận

1. THE Chat_List_Panel SHALL hiển thị tab bar giống Chat_List_Page
2. THE tab bar SHALL hoạt động giống nhau trên cả mobile và panel

### Yêu cầu 5: Localization

#### Tiêu chí chấp nhận

1. THE system SHALL có localization keys: `allConversations`, `directConversations`, `groupConversations`
2. THE system SHALL hỗ trợ English và Vietnamese
