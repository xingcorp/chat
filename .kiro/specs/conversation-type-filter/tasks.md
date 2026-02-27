# Kế hoạch Triển khai: Conversation Type Tab Filter

## Tổng quan

Triển khai: Domain enum → Data (mở rộng API call) → Presentation (BLoC + tab widget) → Tích hợp pages → Localization. Backend đã hỗ trợ — chỉ cần truyền `type` filter.

## Tasks

- [~] 1. Tạo `ConversationTypeFilter` enum
  - [~] 1.1 Tạo `ConversationTypeFilter` enum tại `flutter_chat_app/lib/domain/entities/conversation_type_filter.dart`
    - Values: `all`, `direct`, `group`
    - Extension `apiValue` → `null`, `"Direct"`, `"Group"`
    - _Requirements: 2.1, 2.2, 2.3_

- [~] 2. Mở rộng Data layer — truyền type filter
  - [~] 2.1 Mở rộng conversation list method trong repository/datasource
    - Thêm optional parameter `ConversationTypeFilter? typeFilter`
    - Truyền `type` trong GraphQL variables khi filter != all
    - _Requirements: 2.1, 2.2, 2.3_

- [~] 3. Mở rộng Conversation List BLoC
  - [~] 3.1 Thêm `ChangeConversationTypeFilter` event
    - Field: `ConversationTypeFilter filter`
  - [~] 3.2 Thêm `activeFilter` và cache fields vào state
    - `activeFilter: ConversationTypeFilter` (default: all)
    - Cache per tab: `Map<ConversationTypeFilter, List<Chat>>`
    - Pagination per tab: `Map<ConversationTypeFilter, int>` pages, `Map<ConversationTypeFilter, bool>` hasMore
  - [ ] 3.3 Thêm handler `_onChangeConversationTypeFilter`
    - Check cache → emit cached data nếu có
    - Nếu không → emit loading → fetch với type filter → cache + emit
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  - [ ] 3.4 Cập nhật handlers cho refresh và load more
    - Refresh: reset page cho tab hiện tại
    - Load more: increment page cho tab hiện tại, giữ filter
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 4. Thêm localization keys
  - [ ] 4.1 Thêm keys vào `flutter_chat_app/lib/l10n/app_en.arb`
    - `allConversations`: "All", `directConversations`: "Direct", `groupConversations`: "Groups"
    - `noDirectConversations`: "No direct conversations", `noGroupConversations`: "No group conversations"
  - [ ] 4.2 Thêm keys vào `flutter_chat_app/lib/l10n/app_vi.arb`
    - `allConversations`: "Tất cả", `directConversations`: "Cá nhân", `groupConversations`: "Nhóm"
    - `noDirectConversations`: "Không có chat cá nhân", `noGroupConversations`: "Không có nhóm"
  - [ ] 4.3 Chạy `flutter gen-l10n`
    - _Requirements: 5.1, 5.2_

- [ ] 5. Tạo `ConversationTypeTabBar` widget
  - [ ] 5.1 Tạo `ConversationTypeTabBar` tại `flutter_chat_app/lib/features/chat/presentation/widgets/chat/conversation_type_tab_bar.dart`
    - Extends `BaseStatelessWidget`
    - Row of 3 `AppChip` (hoặc custom ChoiceChip): "Tất cả", "Cá nhân", "Nhóm"
    - Active chip highlighted với `AppColors`
    - Spacing với `AppDimens`
    - Labels từ `context.l10n`
    - Callback `onFilterChanged`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 6. Tích hợp vào ChatListPage
  - [ ] 6.1 Thêm `ConversationTypeTabBar` dưới AppBar, trên conversation list
  - [ ] 6.2 `BlocBuilder` cho `activeFilter` state
  - [ ] 6.3 Kết nối `onFilterChanged` → `bloc.add(ChangeConversationTypeFilter(filter))`
  - [ ] 6.4 Cập nhật empty state message theo tab (noDirectConversations / noGroupConversations)
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3_

- [ ] 7. Tích hợp vào ChatListPanel
  - [ ] 7.1 Thêm `ConversationTypeTabBar` vào header area của panel
  - [ ] 7.2 Kết nối giống ChatListPage
    - _Requirements: 4.1, 4.2_

- [ ] 8. Code Generation
  - [ ] 8.1 Chạy `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 8.2 Chạy `flutter gen-l10n`

- [ ] 9. Final checkpoint
  - Đảm bảo tab filter hoạt động trên cả mobile và panel

## Ghi chú

- Backend đã hỗ trợ filter `type` — không cần thay đổi backend
- `ChatQueries.getConversationList` đã có field `type` trong filter variables
- Tính năng đơn giản, ít rủi ro
- Cache per tab giúp chuyển tab nhanh mà không fetch lại
- Tuân thủ Clean Architecture, base classes, design system, `context.l10n`
