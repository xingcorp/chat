# Kế hoạch Triển khai: Xác nhận đã đọc tin nhắn (Message Read Receipts)

## Tổng quan

Triển khai theo thứ tự Domain → Data → Presentation → DI → Tích hợp. Tận dụng tối đa các thành phần đã có (`readBy` trên `ChatMessage`, `readReceiptStream`, `AppAvatar`, `ReadReceiptMode`). Chỉ bổ sung: `ReadReceiptCalculator`, `ReadReceiptAvatars` widget, `ReceiveMessageRead` event, debounced mark-as-read, và mở rộng `MessageUIState`/`MessageListTransformer`.

## Tasks

- [x] 1. Tạo `ReaderInfo` entity và `ReadReceiptCalculator` trong Domain layer
  - [x] 1.1 Tạo `ReaderInfo` class tại `flutter_chat_app/lib/domain/entities/reader_info.dart`
    - Class với `userId`, `fullName?`, `avatarUrl?` và `const` constructor
    - _Requirements: 6.4, 1.1_
  - [x] 1.2 Tạo `ReadReceiptCalculator` tại `flutter_chat_app/lib/domain/utils/read_receipt_calculator.dart`
    - Static method `computeLastReadPositions` nhận `List<ChatMessage>`, `currentUserId`, `List<ConversationMember>`
    - Thuật toán O(n): duyệt messages từ mới nhất → cũ nhất, gán mỗi reader vào message cuối cùng do currentUser gửi mà reader đã đọc, dừng sớm khi tất cả reader đã gán
    - Loại trừ currentUser khỏi kết quả, chỉ xét messages do currentUser gửi
    - Map userId → fullName/avatarUrl từ ConversationMember, fallback null nếu không tìm thấy
    - Trả về `Map<String, List<ReaderInfo>>` (messageId → readers)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 6.4, 8.1_
  - [ ]* 1.3 Viết property test cho `ReadReceiptCalculator` — Property 1: Last Read Position chính xác
    - **Property 1: Last Read Position chính xác**
    - **Validates: Requirements 1.1, 1.4, 1.5**
    - Test file: `flutter_chat_app/test/domain/utils/read_receipt_calculator_test.dart`
    - Generator: random messages list + random readBy + random members
  - [ ]* 1.4 Viết property test cho `ReadReceiptCalculator` — Property 2: Lọc kết quả đúng
    - **Property 2: Lọc kết quả đúng**
    - **Validates: Requirements 1.2, 1.3**
    - Test file: `flutter_chat_app/test/domain/utils/read_receipt_calculator_test.dart`
    - Generator: random messages với nhiều sender + random currentUserId
  - [ ]* 1.5 Viết property test cho `ReadReceiptCalculator` — Property 6: Map userId sang thông tin member
    - **Property 6: Map userId sang thông tin member**
    - **Validates: Requirements 6.4**
    - Test file: `flutter_chat_app/test/domain/utils/read_receipt_calculator_test.dart`
    - Generator: random readBy + random ConversationMember lists

- [x] 2. Mở rộng `MessageUIState` và `MessageListTransformer`
  - [x] 2.1 Thêm field `readReceiptReaders` vào `MessageUIState` tại `flutter_chat_app/lib/features/chat/presentation/models/message_ui_state.dart`
    - Thêm `final List<ReaderInfo> readReceiptReaders` với default `const []`
    - Cập nhật constructor và `copyWith` nếu cần
    - _Requirements: 1.1, 6.4_
  - [x] 2.2 Mở rộng `MessageListTransformer.transform()` tại `flutter_chat_app/lib/features/chat/presentation/models/message_list_transformer.dart`
    - Thêm parameter `List<ConversationMember> members`
    - Gọi `ReadReceiptCalculator.computeLastReadPositions()` trong transform
    - Gán kết quả vào `MessageUIState.readReceiptReaders` cho mỗi message
    - Cache kết quả — chỉ tính lại khi readBy thay đổi
    - _Requirements: 1.1, 8.1, 8.2_

- [x] 3. Checkpoint — Đảm bảo domain logic và transformer hoạt động
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

- [x] 4. Thêm `ReceiveMessageRead` event và xử lý socket trong `MessageBloc`
  - [x] 4.1 Thêm `ReceiveMessageRead` event vào `flutter_chat_app/lib/presentation/blocs/message/message_event.dart`
    - Event với `messageId` và `readerId`, theo pattern của `ReceiveMessageEdited`/`ReceiveMessageReaction`
    - _Requirements: 4.1, 4.3_
  - [x] 4.2 Thêm handler `_onReceiveMessageRead` trong `flutter_chat_app/lib/presentation/blocs/message/message_bloc.dart`
    - Buffer nếu đang background fetch (dùng `SocketEventBuffer`)
    - Tìm message trong state, thêm readerId vào readBy nếu chưa có (idempotent)
    - Bỏ qua nếu messageId không tồn tại trong state (log warning, không emit)
    - Re-transform messages → emit state mới
    - _Requirements: 4.1, 4.3, 4.4_
  - [x] 4.3 Subscribe `readReceiptStream` trong `MessageBloc`
    - Thêm subscription trong method subscribe socket events (cùng chỗ với edit/delete/reaction)
    - Filter theo chatId, map sang `ReceiveMessageRead` event
    - Dispose subscription trong `close()`
    - _Requirements: 4.1, 4.2_
  - [ ]* 4.4 Viết property test — Property 3: Cập nhật readBy idempotent từ socket event
    - **Property 3: Cập nhật readBy idempotent từ socket event**
    - **Validates: Requirements 4.1, 4.3**
    - Test file: `flutter_chat_app/test/presentation/blocs/message/message_bloc_read_receipt_test.dart`
    - Generator: random message state + random ReceiveMessageRead events

- [x] 5. Triển khai debounced mark-as-read trong `MessageBloc`
  - [x] 5.1 Mở rộng handler `MarkChatAsRead` trong `flutter_chat_app/lib/presentation/blocs/message/message_bloc.dart`
    - Thêm `_markAsReadDebouncer` (Timer 500ms)
    - Chỉ gọi mutation `chatMessageUpdateRead` sau khi debounce hoàn tất
    - Retry tối đa 2 lần với backoff 1 giây khi thất bại
    - Log lỗi nếu retry vẫn thất bại, không hiển thị lỗi cho user
    - Dispose timer trong `close()`
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ]* 5.2 Viết property test — Property 5: Debounce mark-as-read
    - **Property 5: Debounce mark-as-read**
    - **Validates: Requirements 5.3**
    - Test file: `flutter_chat_app/test/presentation/blocs/message/message_bloc_debounce_test.dart`
    - Generator: random sequences of mark-as-read calls

- [x] 6. Checkpoint — Đảm bảo BLoC logic hoạt động đúng
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

- [x] 7. Tạo widget `ReadReceiptAvatars` và `ReadReceiptBottomSheet`
  - [x] 7.1 Thêm localization keys vào ARB files
    - Thêm keys vào `flutter_chat_app/lib/l10n/app_en.arb`: `readByCount` (pluralized), `readByNames` (parameterized), `readReceiptTitle`
    - Thêm keys tương ứng vào `flutter_chat_app/lib/l10n/app_vi.arb`
    - Chạy `flutter gen-l10n`
    - _Requirements: 7.2_
  - [x] 7.2 Tạo `ReadReceiptAvatars` widget tại `flutter_chat_app/lib/presentation/widgets/design_system/chat/read_receipt_avatars.dart`
    - Extends `BaseStatelessWidget`, sử dụng `AppAvatar` với kích thước 16dp
    - Direct chat: hiển thị 1 avatar
    - Group chat: hiển thị tối đa 4 avatar + badge "+N" khi > 5 readers
    - `AnimatedSize` cho smooth transition khi avatar xuất hiện/biến mất
    - `GestureDetector` + `onTap` callback cho group chat
    - `Semantics` label mô tả danh sách người đã đọc dùng `context.l10n`
    - Touch target tối thiểu 24dp khi có thể nhấn
    - Sử dụng `AppColors`, `AppDimens`, `const` constructor
    - Căn phải, khoảng cách `AppDimens.spacingXSmall` từ bubble
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.4, 6.1, 6.2, 7.1, 7.2, 7.3, 8.3_
  - [x] 7.3 Tạo `ReadReceiptBottomSheet` tại `flutter_chat_app/lib/presentation/widgets/design_system/chat/read_receipt_bottom_sheet.dart`
    - Sử dụng `AppModalBottomSheet` để hiển thị danh sách đầy đủ readers
    - Mỗi item: `AppAvatar` + `AppText` với tên reader
    - Sắp xếp theo thứ tự thời gian đọc
    - Sử dụng `context.l10n` cho title và strings
    - _Requirements: 3.3_
  - [ ]* 7.4 Viết property test — Property 4: Truncation avatar trong group chat
    - **Property 4: Truncation avatar trong group chat**
    - **Validates: Requirements 3.2**
    - Test file: `flutter_chat_app/test/presentation/widgets/read_receipt_avatars_test.dart`
    - Generator: random ReaderInfo lists với length 0..20
  - [ ]* 7.5 Viết unit tests cho `ReadReceiptAvatars` widget
    - Test direct chat: 1 reader → hiển thị 1 avatar
    - Test direct chat: 0 reader → không hiển thị
    - Test group chat: 3 readers → hiển thị 3 avatar
    - Test group chat: 6 readers → 4 avatar + badge "+2"
    - Test semantics label
    - _Requirements: 2.1, 2.2, 3.1, 3.2, 7.2_

- [x] 8. Tích hợp `ReadReceiptAvatars` vào Message List
  - [x] 8.1 Tích hợp widget vào message bubble item trong `ChatDetailsPage`
    - Thêm `ReadReceiptAvatars` bên dưới message bubble cho tin nhắn do currentUser gửi
    - Truyền `readReceiptReaders` từ `MessageUIState`
    - Truyền `isGroupChat` flag
    - Kết nối `onTap` với `ReadReceiptBottomSheet.show()` cho group chat
    - Đảm bảo không ảnh hưởng pagination và vị trí scroll
    - _Requirements: 6.1, 6.2, 6.3, 6.5_
  - [x] 8.2 Cập nhật các call sites của `MessageListTransformer.transform()` để truyền `members` parameter
    - Cập nhật trong `MessageBloc._transformMessages()`
    - Cập nhật trong `OptimizedChatScreen` và `OptimizedMessageList` nếu gọi trực tiếp
    - _Requirements: 6.4_
  - [x] 8.3 Trigger `MarkChatAsRead` khi mở chat và khi cuộn tới tin nhắn chưa đọc
    - Gọi khi mở cuộc trò chuyện có tin nhắn chưa đọc
    - Gọi khi cuộn tới tin nhắn chưa đọc mới (debounced bởi BLoC)
    - _Requirements: 5.1, 5.2_

- [x] 9. Chạy code generation và kiểm tra tích hợp
  - [x] 9.1 Chạy `dart run build_runner build --delete-conflicting-outputs` và `flutter gen-l10n`
    - Đảm bảo freezed/injectable code gen thành công
    - Đảm bảo localization gen thành công
  - [ ]* 9.2 Viết unit tests cho tích hợp end-to-end
    - Test socket event → BLoC update → transformer → UI state có readReceiptReaders đúng
    - Test empty members list → graceful handling
    - Test userId không có trong members → avatar mặc định
    - _Requirements: 4.1, 6.4, 6.5_

- [x] 10. Final checkpoint — Đảm bảo tất cả tests pass
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

## Ghi chú

- Tasks đánh dấu `*` là optional, có thể bỏ qua cho MVP nhanh hơn
- Mỗi task tham chiếu requirements cụ thể để truy vết
- Checkpoints đảm bảo kiểm tra tăng dần
- Property tests kiểm chứng tính đúng đắn phổ quát, unit tests kiểm tra ví dụ cụ thể và edge cases
- Tuân thủ Clean Architecture: Domain → Data → Presentation
- Tất cả UI code sử dụng design system (`AppAvatar`, `AppText`, `AppColors`, `AppDimens`, `context.l10n`)
- Tất cả widgets extend `BaseStatelessWidget`/`BaseStatefulWidget`, BLoC extend `BaseBloc`
