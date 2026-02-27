# Kế hoạch Triển khai: Advanced Search Filters UI

## Tổng quan

Triển khai: Domain (SearchFilters) → Data (mở rộng datasource) → Presentation (BLoC + UI widgets) → Localization → Tích hợp. Backend đã hỗ trợ đầy đủ — chỉ cần truyền thêm parameters.

## Tasks

- [ ] 1. Tạo `SearchFilters` value object
  - [ ] 1.1 Tạo `SearchFilters` tại `flutter_chat_app/lib/domain/entities/search_filters.dart`
    - Fields: `senderIds`, `messageTypes`, `fromDate`, `toDate`
    - `isEmpty`, `isNotEmpty`, `activeCount` getters
    - `copyWith` method
    - `const` constructor với default empty values
    - _Requirements: 6.1_

- [ ] 2. Mở rộng Data layer — truyền filters trong search
  - [ ] 2.1 Mở rộng `SearchMessagesUseCase` tại `flutter_chat_app/lib/features/chat/domain/usecases/chat/search_messages_usecase.dart`
    - Thêm parameters: `senderIds`, `messageTypes`, `fromDate`, `toDate`
    - Truyền đến repository
    - _Requirements: 6.2_
  - [ ] 2.2 Mở rộng search method trong repository interface và implementation
    - Thêm filter parameters
    - _Requirements: 6.2_
  - [ ] 2.3 Mở rộng search remote datasource — truyền filter variables trong GraphQL query
    - `senderIds`, `messageTypes` truyền trực tiếp
    - `fromDate`/`toDate` convert sang milliseconds timestamp
    - _Requirements: 6.3_

- [ ] 3. Mở rộng `MessageSearchBloc`
  - [ ] 3.1 Thêm events: `SearchWithFilters`, `UpdateFilters`, `ClearFilters` vào `flutter_chat_app/lib/features/chat/presentation/blocs/message_search/message_search_event.dart`
    - _Requirements: 6.1_
  - [ ] 3.2 Thêm `activeFilters: SearchFilters` vào loaded state trong `message_search_state.dart`
    - _Requirements: 6.1_
  - [ ] 3.3 Thêm handlers trong `MessageSearchBloc`
    - `_onSearchWithFilters`: search với keyword + filters
    - `_onUpdateFilters`: cập nhật filters, trigger search lại
    - `_onClearFilters`: reset filters, search lại chỉ với keyword
    - `_onLoadMore`: giữ nguyên filters khi pagination
    - _Requirements: 6.1, 6.4_

- [ ] 4. Thêm localization keys
  - [ ] 4.1 Thêm keys vào `flutter_chat_app/lib/l10n/app_en.arb`
    - `filters`, `applyFilters`, `clearFilters`, `filterBySender`, `filterByType`, `filterByDate`, `fromDate`, `toDate`, `noFiltersApplied`, `activeFiltersCount`
    - Message type names: `messageTypeText`, `messageTypeImage`, `messageTypeVideo`, `messageTypeDocument`, `messageTypeVoiceNote`, `messageTypeSticker`, `messageTypeAudio`
  - [ ] 4.2 Thêm keys tương ứng vào `flutter_chat_app/lib/l10n/app_vi.arb`
  - [ ] 4.3 Chạy `flutter gen-l10n`
    - _Requirements: 7.1_

- [ ] 5. Tạo `SearchFilterPanel` widget
  - [ ] 5.1 Tạo `SearchFilterPanel` tại `flutter_chat_app/lib/features/chat/presentation/widgets/search/search_filter_panel.dart`
    - Extends `BaseStatefulWidget`
    - Sender section: `AppCheckbox` list với `AppAvatar` + `AppText` cho mỗi member
    - Type section: `Wrap` of `AppChip` (multi-select) cho message types
    - Date section: Row với 2 `AppDatePicker` ("Từ ngày", "Đến ngày")
    - Buttons: `AppButton` "Xoá bộ lọc" + `AppButton` "Áp dụng"
    - Validation: disable "Áp dụng" nếu fromDate > toDate
    - Sử dụng `AppColors`, `AppDimens`, `context.l10n`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4_

- [ ] 6. Tạo `ActiveFilterChips` widget
  - [ ] 6.1 Tạo `ActiveFilterChips` tại `flutter_chat_app/lib/features/chat/presentation/widgets/search/active_filter_chips.dart`
    - Extends `BaseStatelessWidget`
    - `Wrap` of `AppChip` với nút xoá cho mỗi active filter
    - Map senderIds → tên members, messageTypes → display names, dates → formatted strings
    - Callback `onRemoveFilter` khi xoá chip
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 7. Cập nhật `message_search_panel.dart`
  - [ ] 7.1 Thêm filter toggle button (icon filter) cạnh search field
    - `AppIconButton` với badge hiển thị số active filters
    - _Requirements: 1.1, 1.2_
  - [ ] 7.2 Thêm `SearchFilterPanel` (expandable, toggle show/hide)
    - `AnimatedSize` cho smooth expand/collapse
    - _Requirements: 1.2, 1.3_
  - [ ] 7.3 Thêm `ActiveFilterChips` row dưới search field
    - Chỉ hiển thị khi có active filters
    - _Requirements: 5.1_
  - [ ] 7.4 Kết nối UI với `MessageSearchBloc` events
    - Apply filters → `SearchWithFilters` event
    - Remove chip → `UpdateFilters` event
    - Clear all → `ClearFilters` event
    - _Requirements: 6.1_

- [ ] 8. Code Generation
  - [ ] 8.1 Chạy `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 8.2 Chạy `flutter gen-l10n`

- [ ] 9. Final checkpoint
  - Đảm bảo search với filters hoạt động end-to-end

## Ghi chú

- Backend `chatSearch` đã hỗ trợ đầy đủ filters — không cần thay đổi backend
- `ChatQueries.searchMessages` GraphQL query đã có tất cả filter fields
- `MessageSearchBloc` hiện có cần mở rộng, không tạo mới
- Sender filter chỉ hiển thị khi search trong conversation cụ thể (có members)
- Tuân thủ Clean Architecture, base classes, design system, `context.l10n`
