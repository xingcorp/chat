# Tài liệu Yêu cầu — Frequently Used Reactions

## Giới thiệu

Tính năng hiển thị top emoji reactions mà user hay dùng nhất, lấy từ backend API `chatReactionFrequentlyUsed`. Backend trả về top 10 emoji codes từ Redis sorted set. Flutter app có emoji picker nhưng chưa fetch/hiển thị frequently used reactions từ backend.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- Mutation `chatReactionFrequentlyUsed` trả về `[String]` — top 10 emoji codes từ Redis `zrevrange`
- Redis sorted set `MemberReactionUsed(userId)` tự động cập nhật khi user react
- Authenticated endpoint (cần JWT token)

**Flutter app đã có:**
- `AppEmojiPicker` widget với tab "Recent" (local recent emojis từ `emoji_picker_flutter`)
- Reaction bar trên message bubble (quick reaction buttons)
- `updateReaction` mutation để add/remove reaction
- `MessageBloc` xử lý reaction events

**Cần bổ sung:**
- Gọi API `chatReactionFrequentlyUsed` để lấy top reactions
- Hiển thị frequently used reactions trong quick reaction bar
- Cache kết quả locally
- Cập nhật khi user react (optimistic hoặc refetch)

## Thuật ngữ

- **Frequently_Used_Reactions**: Top 10 emoji mà user hay dùng nhất, từ backend Redis
- **Quick_Reaction_Bar**: Thanh reaction nhanh hiển thị khi long press/swipe message
- **Reaction_Service**: Service quản lý frequently used reactions data

## Yêu cầu

### Yêu cầu 1: Fetch Frequently Used Reactions từ Backend

**User Story:** Là người dùng, tôi muốn thấy các emoji tôi hay dùng nhất hiển thị đầu tiên khi react tin nhắn.

#### Tiêu chí chấp nhận

1. THE system SHALL gọi mutation `chatReactionFrequentlyUsed` khi user mở app hoặc lần đầu mở reaction picker
2. THE system SHALL cache kết quả locally với TTL 5 phút
3. THE system SHALL trả về danh sách mặc định (👍 ❤️ 😂 😮 😢 😡) nếu API thất bại hoặc trả về rỗng

### Yêu cầu 2: Hiển thị trong Quick Reaction Bar

**User Story:** Là người dùng, tôi muốn thấy emoji hay dùng trong thanh reaction nhanh trên message.

#### Tiêu chí chấp nhận

1. THE Quick_Reaction_Bar SHALL hiển thị tối đa 6 emoji từ frequently used reactions
2. THE Quick_Reaction_Bar SHALL luôn có nút "+" ở cuối để mở full emoji picker
3. THE Quick_Reaction_Bar SHALL cập nhật khi frequently used data thay đổi
4. THE Quick_Reaction_Bar SHALL sử dụng `AppColors`, `AppDimens` từ design system

### Yêu cầu 3: Cập nhật sau khi React

**User Story:** Là người dùng, tôi muốn danh sách frequently used tự động cập nhật khi tôi dùng emoji mới.

#### Tiêu chí chấp nhận

1. AFTER user react với emoji, THE system SHALL refetch frequently used reactions (debounced 10 giây)
2. THE system SHALL không block UI khi refetch — hiển thị data cũ cho đến khi có data mới
