# Tài liệu Yêu cầu — Hệ thống Sticker (Sticker System)

## Giới thiệu

Tính năng gửi và hiển thị sticker trong cuộc trò chuyện. Backend đã hỗ trợ `ChatMessageType.STICKER` đầy đủ. Flutter app có enum `MessageType.sticker` nhưng thiếu hoàn toàn: sticker picker UI, sticker pack management, và flow gửi sticker.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- `ChatMessageType.STICKER` trong enum
- `chatMessageAdd` mutation nhận `type: "STICKER"`, `message: stickerCode/stickerUrl`
- Message list query trả về message type STICKER

**Flutter app đã có:**
- `MessageType.sticker` trong enum
- `AppEmojiPicker` widget (emoji picker) — có thể mở rộng hoặc đặt cạnh
- `ChatInput` widget có nút attachment

**Cần bổ sung:**
- Sticker picker UI (grid hiển thị sticker packs)
- Sticker pack data (built-in packs hoặc từ server)
- Flow gửi sticker qua `chatMessageAdd` type STICKER
- Hiển thị sticker trong message bubble (image lớn hơn emoji)
- Nút sticker trong ChatInput (cạnh emoji picker)

## Thuật ngữ

- **Sticker**: Hình ảnh biểu cảm lớn hơn emoji, gửi như một tin nhắn riêng biệt
- **Sticker_Pack**: Bộ sưu tập sticker theo chủ đề (ví dụ: "Mèo vui", "Cảm xúc")
- **Sticker_Picker**: UI cho phép duyệt và chọn sticker để gửi
- **Sticker_Code**: Mã định danh duy nhất của sticker (ví dụ: `pack_01_sticker_03`)
- **Sticker_URL**: URL hình ảnh của sticker

## Yêu cầu

### Yêu cầu 1: Hiển thị nút Sticker trong ChatInput

**User Story:** Là người dùng, tôi muốn thấy nút sticker trong thanh input để truy cập nhanh sticker picker.

#### Tiêu chí chấp nhận

1. THE ChatInput SHALL hiển thị nút sticker (icon) cạnh nút emoji hoặc trong attachment menu
2. WHEN người dùng nhấn nút sticker, THE system SHALL hiển thị Sticker_Picker
3. THE nút sticker SHALL sử dụng `AppIconButton` từ design system

### Yêu cầu 2: Sticker Picker UI

**User Story:** Là người dùng, tôi muốn duyệt sticker theo pack và chọn sticker để gửi.

#### Tiêu chí chấp nhận

1. THE Sticker_Picker SHALL hiển thị dạng bottom sheet hoặc panel (giống emoji picker)
2. THE Sticker_Picker SHALL hiển thị tab bar cho các Sticker_Pack
3. THE Sticker_Picker SHALL hiển thị grid sticker (4-5 cột) cho pack đang chọn
4. WHEN người dùng nhấn vào sticker, THE system SHALL gửi sticker đó ngay lập tức (không cần confirm)
5. THE Sticker_Picker SHALL hiển thị tab "Gần đây" (recently used) ở đầu
6. THE Sticker_Picker SHALL sử dụng `AppColors`, `AppDimens`, `context.l10n` từ design system

### Yêu cầu 3: Gửi Sticker

**User Story:** Là người dùng, tôi muốn gửi sticker và thấy nó xuất hiện ngay trong cuộc trò chuyện.

#### Tiêu chí chấp nhận

1. WHEN người dùng chọn sticker, THE system SHALL gửi mutation `chatMessageAdd` với `type: "STICKER"`, `message: stickerCode`
2. THE system SHALL hiển thị sticker tạm (optimistic update) ngay lập tức
3. THE system SHALL đóng Sticker_Picker sau khi gửi
4. THE system SHALL lưu sticker vào danh sách "Gần đây" (local storage)

### Yêu cầu 4: Hiển thị Sticker trong Message Bubble

**User Story:** Là người dùng, tôi muốn thấy sticker hiển thị dạng hình ảnh lớn trong message bubble.

#### Tiêu chí chấp nhận

1. WHEN message type là STICKER, THE message bubble SHALL hiển thị hình ảnh sticker với kích thước lớn (120-150dp)
2. THE sticker message SHALL không có background bubble (hiển thị trực tiếp hình ảnh)
3. THE sticker SHALL sử dụng `AppImage` với cache và placeholder loading
4. IF sticker image không load được, THE system SHALL hiển thị placeholder icon

### Yêu cầu 5: Built-in Sticker Packs

**User Story:** Là người dùng, tôi muốn có sẵn một số bộ sticker để sử dụng ngay.

#### Tiêu chí chấp nhận

1. THE system SHALL cung cấp ít nhất 2 built-in Sticker_Pack
2. Mỗi Sticker_Pack SHALL có: tên, icon thumbnail, và danh sách sticker (code + URL)
3. THE sticker data SHALL được bundle trong app (assets) hoặc load từ CDN config
4. THE system SHALL cache sticker images để sử dụng offline
