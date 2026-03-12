# Plan: Desktop Input Area — Zalo-style Layout

## Phân tích hiện trạng

### Giao diện Zalo Desktop (từ screenshot)
- **Toolbar phía trên**: Hàng icon ngang gồm: Sticker/Emoji, Hình ảnh, Screenshot, File đính kèm, v.v.
- **Vùng soạn thảo ở giữa**: Multi-line text editor, chiều cao tự mở rộng
- **Nút gửi góc dưới-phải**: Nút Send (hoặc Like/thumbs-up khi trống)
- Layout tổng thể: `Toolbar → Editor → Send button`

### Giao diện hiện tại của app
- File: `chat_details_page.dart:2536` — method `_buildMessageInputArea()`
- Layout: `AppCard.outlined` chứa 1 Row đơn: `[Attach, MentionTextField, Sticker, Send/Mic]`
- Đây là layout mobile-first, tất cả nằm trên 1 hàng ngang
- Không có phân biệt desktop vs mobile cho input area

### Hệ thống composer Quill (đã có nhưng chưa dùng)
- `composer/quill_composer_widget.dart` — Rich text editor với Quill
- `composer/toolbar_orchestrator.dart` — 2-layer toolbar (ActionRow + FormattingPanel)
- `composer/action_row.dart` — Emoji, Attach, Format toggle
- Hệ thống này chưa được tích hợp vào `chat_details_page.dart`

## Thiết kế giải pháp

### Nguyên tắc
1. **Không ảnh hưởng mobile** — Dùng `PlatformUtils.isDesktopDevice` để phân nhánh
2. **Tái sử dụng tối đa** — Dùng lại MentionTextField, các callback hiện có
3. **Tuân thủ design system** — AppColors, AppDimens, AppIconButton, AppCard
4. **Minimal changes** — Chỉ thay đổi layout, không thay đổi logic gửi tin nhắn

### Layout Desktop mới (Zalo-style)

```
┌─────────────────────────────────────────────────┐
│ [😊 Emoji] [📎 Attach] [🖼 Sticker] [Aa Format] │  ← Desktop Action Toolbar
├─────────────────────────────────────────────────┤
│                                                 │
│  MentionTextField (multi-line, min 3 lines)     │  ← Editor area (taller)
│                                                 │
│                                        [Send ➤] │  ← Send button bottom-right
└─────────────────────────────────────────────────┘
```

### Layout Mobile (giữ nguyên)
```
┌─────────────────────────────────────────────────┐
│ [+] [  MentionTextField  ] [Sticker] [Send/Mic] │
└─────────────────────────────────────────────────┘
```

## Kế hoạch triển khai

### Bước 1: Tạo widget `DesktopComposerToolbar`
- File mới: `flutter_chat_app/lib/features/chat/presentation/widgets/composer/desktop_composer_toolbar.dart`
- Hàng icon ngang: Emoji, Attach file, Sticker, Format toggle (tương lai)
- Dùng `AppIconButton` + `AppColors` + `AppDimens`
- Nhận callbacks từ parent: `onEmojiPressed`, `onAttachPressed`, `onStickerPressed`, `onFormatToggle`

### Bước 2: Tạo widget `DesktopMessageInputArea`
- File mới: `flutter_chat_app/lib/features/chat/presentation/widgets/composer/desktop_message_input_area.dart`
- Layout Column: `[DesktopComposerToolbar] → [Expanded MentionTextField] → [Row: spacer + Send]`
- Wrap trong `AppCard.outlined` giống mobile
- MentionTextField với `minLines: 3`, `maxLines: 8` (taller cho desktop)
- Send button ở góc dưới-phải, chỉ hiện khi có text hoặc attachments

### Bước 3: Cập nhật `_buildMessageInputArea()` trong `chat_details_page.dart`
- Thêm check `PlatformUtils.isDesktopDevice`
- Desktop → return `DesktopMessageInputArea(...)` với cùng callbacks
- Mobile → giữ nguyên code hiện tại, không thay đổi gì

### Bước 4: Cập nhật `ComposerConstants` (nếu cần)
- Thêm constants cho desktop: `desktopEditorMinHeight`, `desktopToolbarHeight`
- Giữ nguyên constants mobile hiện có

## Files sẽ thay đổi

| File | Thay đổi |
|---|---|
| `widgets/composer/desktop_composer_toolbar.dart` | **MỚI** — Toolbar hàng icon |
| `widgets/composer/desktop_message_input_area.dart` | **MỚI** — Desktop layout wrapper |
| `pages/chat/chat_details_page.dart` | **SỬA** — Phân nhánh desktop/mobile trong `_buildMessageInputArea()` |
| `widgets/composer/composer_constants.dart` | **SỬA** — Thêm desktop constants |

## Không thay đổi (đảm bảo mobile không bị ảnh hưởng)
- `ChatInput` widget — không đụng
- `MentionTextField` — tái sử dụng, không sửa
- Logic gửi tin nhắn, typing indicator, voice recording — giữ nguyên
- Keyboard shortcuts — giữ nguyên (đã có cho desktop)
- File attachment flow — giữ nguyên
