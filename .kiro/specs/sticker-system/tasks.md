# Kế hoạch Triển khai: Hệ thống Sticker (Sticker System)

## Tổng quan

Triển khai theo thứ tự: Domain entities → Data (local datasource + repository) → Presentation (picker + message widget) → Tích hợp ChatInput + MessageBloc → DI + Code gen.

## Tasks

- [ ] 1. Tạo Domain layer — Entities và Repository interface
  - [ ] 1.1 Tạo `Sticker` và `StickerPack` entities tại `flutter_chat_app/lib/domain/entities/sticker.dart`
    - `Sticker`: `code`, `imageUrl`
    - `StickerPack`: `id`, `name`, `thumbnailUrl`, `List<Sticker> stickers`
    - _Requirements: 5.2_
  - [ ] 1.2 Tạo `IStickerRepository` interface tại `flutter_chat_app/lib/domain/repositories/i_sticker_repository.dart`
    - `getAvailablePacks()`, `getRecentlyUsed()`, `addToRecentlyUsed(sticker)`, `resolveSticker(code)`
    - _Requirements: 2.5, 3.4, 5.1_

- [ ] 2. Tạo Data layer — Sticker packs và local datasource
  - [ ] 2.1 Tạo sticker pack JSON tại `flutter_chat_app/assets/stickers/sticker_packs.json`
    - Ít nhất 2 packs với sticker URLs (có thể dùng placeholder URLs ban đầu)
    - _Requirements: 5.1, 5.2_
  - [ ] 2.2 Đăng ký assets folder trong `pubspec.yaml`
  - [ ] 2.3 Tạo `StickerLocalDataSource` tại `flutter_chat_app/lib/data/datasources/sticker/sticker_local_datasource.dart`
    - Load packs từ assets JSON
    - Recently used: SharedPreferences
    - Cache sticker map cho resolve by code
    - `@lazySingleton`
    - _Requirements: 5.3, 5.4_
  - [ ] 2.4 Tạo `StickerRepositoryImpl` tại `flutter_chat_app/lib/data/repositories/sticker_repository_impl.dart`
    - `@LazySingleton(as: IStickerRepository)`
    - Wrap trong try/catch, return `Either<Failure, T>`
    - _Requirements: 2.5, 3.4_

- [ ] 3. Tạo Presentation — Sticker Picker
  - [ ] 3.1 Thêm localization keys vào ARB files
    - `app_en.arb`: `stickers`, `recentStickers`, `noStickersAvailable`
    - `app_vi.arb`: `stickers` → "Sticker", `recentStickers` → "Gần đây", `noStickersAvailable` → "Không có sticker"
    - Chạy `flutter gen-l10n`
    - _Requirements: 2.6_
  - [ ] 3.2 Tạo `StickerPickerBottomSheet` tại `flutter_chat_app/lib/presentation/widgets/design_system/chat/sticker_picker.dart`
    - Extends `BaseStatefulWidget`
    - Tab bar: "Gần đây" + pack tabs
    - Grid 4 cột với `AppImage` + `GestureDetector`
    - Callback `onStickerSelected`
    - Sử dụng `AppColors`, `AppDimens`, `context.l10n`
    - Static `show()` method
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 4. Tạo Presentation — Sticker Message Widget
  - [ ] 4.1 Tạo `StickerMessageWidget` tại `flutter_chat_app/lib/presentation/widgets/design_system/chat/sticker_message.dart`
    - Extends `BaseStatelessWidget`
    - Resolve sticker code → URL qua `IStickerRepository`
    - `AppImage` kích thước 120dp, không bubble background
    - Placeholder loading, error icon khi fail
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 5. Mở rộng MessageBloc — SendSticker event
  - [ ] 5.1 Thêm `SendSticker` event vào `flutter_chat_app/lib/presentation/blocs/message/message_event.dart`
    - Field: `stickerCode`
  - [ ] 5.2 Thêm handler `_onSendSticker` trong `MessageBloc`
    - Optimistic update: temp message type sticker
    - Gọi `chatMessageAdd` với type STICKER, message = stickerCode
    - Replace temp message on success
    - _Requirements: 3.1, 3.2_

- [ ] 6. Tích hợp vào ChatInput và Message Bubble
  - [ ] 6.1 Thêm nút sticker icon vào `ChatInput`
    - `AppIconButton` cạnh emoji/attachment
    - Tap → `StickerPickerBottomSheet.show()`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 6.2 Trong message bubble builder, khi `message.type == MessageType.sticker`, render `StickerMessageWidget`
    - Truyền `stickerCode` từ `message.content`
    - _Requirements: 4.1_
  - [ ] 6.3 Kết nối `onStickerSelected` callback → `MessageBloc.add(SendSticker(code))`
    - Đóng picker sau khi gửi
    - Lưu vào recently used
    - _Requirements: 3.3, 3.4_

- [ ] 7. DI Registration và Code Generation
  - [ ] 7.1 Đảm bảo `StickerLocalDataSource`, `StickerRepositoryImpl` đăng ký trong DI
  - [ ] 7.2 Chạy `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 7.3 Chạy `flutter gen-l10n`

- [ ] 8. Final checkpoint
  - Đảm bảo sticker picker hiển thị, gửi sticker thành công, hiển thị trong bubble đúng

## Ghi chú

- Sticker packs ban đầu dùng placeholder URLs — có thể thay bằng CDN URLs thật sau
- Pattern gửi sticker giống gửi text message, chỉ khác type = STICKER
- Tái sử dụng `AppImage` với cache cho hiển thị sticker
- Tuân thủ Clean Architecture, base classes, design system
