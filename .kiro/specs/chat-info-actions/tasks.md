# Kế hoạch Triển khai: Block/Unblock User, Report Chat, Notification Settings

## Tổng quan

Triển khai theo thứ tự: GraphQL operations → Data layer (implement TODO stubs) → Domain use cases → Presentation (BLoC + UI) → DI → Code gen. Tận dụng `IChatInfoRepository` interface và `ChatInfoRemoteDataSource` structure đã có.

## Tasks

- [ ] 1. Thêm GraphQL operations
  - [ ] 1.1 Tạo `ChatInfoOperations` class tại `flutter_chat_app/lib/data/graphql/chat_info_operations.dart`
    - Mutations: `blockUser`, `unblockUser`, `reportChat`, `updateNotificationSettings`
    - Queries: `isUserBlocked`, `getNotificationSettings`
    - **Lưu ý:** Xác nhận tên mutation/query với backend. Nếu backend chưa có, cần coordinate.
    - _Requirements: 1.3, 2.2, 3.4, 4.3_

- [ ] 2. Implement TODO stubs trong `ChatInfoRemoteDataSource`
  - [ ] 2.1 Implement `blockUser` — gọi GraphQL mutation `blockUser` tại `flutter_chat_app/lib/data/datasources/chat_info/chat_info_remote_datasource.dart`
    - _Requirements: 1.3_
  - [ ] 2.2 Implement `unblockUser` — gọi GraphQL mutation `unblockUser`
    - _Requirements: 2.2_
  - [ ] 2.3 Implement `isUserBlocked` — gọi GraphQL query `isUserBlocked`
    - _Requirements: 5.1_
  - [ ] 2.4 Implement `reportChat` — gọi GraphQL mutation `reportChat`
    - _Requirements: 3.4_
  - [ ] 2.5 Implement `getNotificationSettings` — gọi GraphQL query
    - _Requirements: 4.2_
  - [ ] 2.6 Implement `updateNotificationSettings` — gọi GraphQL mutation
    - _Requirements: 4.3_

- [ ] 3. Checkpoint — Verify data layer compiles và API calls đúng format

- [ ] 4. Tạo Domain use cases (nếu cần, hoặc gọi trực tiếp repository từ BLoC)
  - [ ] 4.1 Tạo `BlockUserUseCase` tại `flutter_chat_app/lib/domain/usecases/chat_info/block_user_usecase.dart`
    - Extends `UseCase<void, BlockUserParams>`
    - _Requirements: 1.3_
  - [ ] 4.2 Tạo `UnblockUserUseCase`, `ReportChatUseCase`, `ToggleNotificationUseCase`, `CheckBlockStatusUseCase`
    - Tương tự pattern
    - _Requirements: 2.2, 3.4, 4.3, 5.1_

- [ ] 5. Tạo `ChatInfoActionsBloc`
  - [ ] 5.1 Tạo events tại `flutter_chat_app/lib/presentation/blocs/chat_info/chat_info_actions_event.dart`
    - `CheckBlockStatus(userId)`, `BlockUser(userId)`, `UnblockUser(userId)`
    - `ReportChat(chatId, reason)`, `LoadNotificationSettings(chatId)`, `ToggleNotification(chatId, isMuted)`
  - [ ] 5.2 Tạo state tại `flutter_chat_app/lib/presentation/blocs/chat_info/chat_info_actions_state.dart`
    - `@freezed`, extends `BaseState`
    - States: initial, loading, loaded(isBlocked, isMuted, isBlockLoading, isReportLoading, isNotificationLoading), error
  - [ ] 5.3 Tạo bloc tại `flutter_chat_app/lib/presentation/blocs/chat_info/chat_info_actions_bloc.dart`
    - `@injectable`, extends `BaseBloc`
    - Handlers cho tất cả events
    - Notification toggle: optimistic update + revert on fail
    - _Requirements: 1.3, 1.4, 2.2, 2.3, 3.4, 4.3, 4.4, 4.5, 5.1, 5.2_

- [ ] 6. Thêm localization keys
  - [ ] 6.1 Thêm keys vào `flutter_chat_app/lib/l10n/app_en.arb`
    - `blockUser`, `unblockUser`, `blockConfirmTitle`, `blockConfirmMessage`, `userBlocked`, `userUnblocked`, `reportChat`, `reportReasonSpam`, `reportReasonHarassment`, `reportReasonInappropriate`, `reportReasonOther`, `reportSubmitted`, `reportThankYou`, `muteNotifications`, `enterReportReason`
  - [ ] 6.2 Thêm keys tương ứng vào `flutter_chat_app/lib/l10n/app_vi.arb`
  - [ ] 6.3 Chạy `flutter gen-l10n`
    - _Requirements: 6.1, 6.2_

- [ ] 7. Tạo UI components
  - [ ] 7.1 Tạo `ReportChatDialog` tại `flutter_chat_app/lib/presentation/widgets/design_system/chat/report_chat_dialog.dart`
    - `AppModalBottomSheet` với radio buttons cho lý do
    - `AppTextArea` cho lý do tùy chỉnh khi chọn "Khác"
    - `AppButton` submit
    - Sử dụng `context.l10n`, `AppColors`, `AppDimens`
    - _Requirements: 3.2, 3.3_
  - [ ] 7.2 Cập nhật Chat Info Page — thêm block/unblock button, report button, notification toggle
    - `BlocProvider` cho `ChatInfoActionsBloc`
    - `BlocBuilder` cho hiển thị state
    - Block button: `AppButton` với confirm dialog (`AppConfirmDialog`)
    - Report button: `AppButton` → `ReportChatDialog.show()`
    - Notification: `AppSwitch` toggle
    - Block button chỉ hiển thị cho direct chat
    - _Requirements: 1.1, 1.2, 1.5, 1.6, 2.1, 2.4, 3.1, 3.5, 4.1, 5.3_

- [ ] 8. DI Registration và Code Generation
  - [ ] 8.1 Đảm bảo `ChatInfoActionsBloc` và use cases đăng ký trong DI
  - [ ] 8.2 Chạy `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 8.3 Chạy `flutter gen-l10n`

- [ ] 9. Final checkpoint
  - Đảm bảo block/unblock/report/notification hoạt động end-to-end

## Ghi chú

- **QUAN TRỌNG:** Cần xác nhận với backend team về tên chính xác của GraphQL mutations/queries cho block/unblock/report. Nếu backend chưa có API, cần coordinate để thêm.
- `IChatInfoRepository` interface đã đầy đủ — không cần thay đổi
- `ChatInfoRemoteDataSource` structure đã có — chỉ cần implement body methods
- Tuân thủ Clean Architecture, base classes, design system
- Tất cả strings dùng `context.l10n`
