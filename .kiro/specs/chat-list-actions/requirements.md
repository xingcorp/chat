# Requirements Document

## Introduction

Tính năng "Chat List Actions" thêm nút "+" vào màn hình danh sách chat, hiển thị popup menu với hai tùy chọn: tạo cuộc hội thoại mới (điều hướng đến trang danh bạ) và tạo nhóm mới (điều hướng đến trang tạo nhóm). Tính năng này áp dụng cho cả giao diện mobile (`chat_list_page.dart`) và giao diện panel/tablet (`chat_list_panel.dart`). Trên mobile, nút "+" thay thế FAB và PopupMenuButton hiện tại; tùy chọn Settings được chuyển sang BottomNavigationBar hoặc điều hướng riêng.

## Glossary

- **Chat_List_Page**: Trang danh sách chat trên giao diện mobile (`chat_list_page.dart`), bao gồm AppBar, body danh sách, và BottomNavigationBar.
- **Chat_List_Panel**: Widget danh sách chat trên giao diện panel/tablet (`chat_list_panel.dart`), bao gồm header toolbar và body danh sách.
- **Plus_Button**: Nút IconButton có icon "+" (`Icons.add`) hiển thị trong AppBar (mobile) hoặc header (panel).
- **Action_Menu**: Popup menu hiển thị khi người dùng nhấn Plus_Button, chứa các tùy chọn hành động.
- **Contacts_Page**: Trang danh bạ hiện có (`contacts_page.dart`) hiển thị danh sách liên hệ để bắt đầu cuộc hội thoại trực tiếp.
- **Create_Group_Page**: Trang tạo nhóm hiện có (`create_group_page.dart`) cho phép chọn thành viên và tạo nhóm chat.
- **Settings_Page**: Trang cài đặt hiện có (`settings_page.dart`) hiển thị cài đặt ứng dụng và hồ sơ người dùng.
- **Chat_Navigation_Helper**: Lớp tiện ích điều hướng (`chat_navigation_helper.dart`) hỗ trợ điều hướng giữa các trang trong module chat.

## Requirements

### Requirement 1: Hiển thị Plus_Button trên Chat_List_Page (Mobile)

**User Story:** Là người dùng mobile, tôi muốn thấy nút "+" trên AppBar của trang danh sách chat, để tôi có thể nhanh chóng tạo cuộc hội thoại mới hoặc nhóm mới.

#### Acceptance Criteria

1. THE Chat_List_Page SHALL display a Plus_Button as an IconButton with `Icons.add` icon in the AppBar actions area, positioned after the search toggle button.
2. THE Chat_List_Page SHALL remove the existing FloatingActionButton from the Scaffold.
3. THE Chat_List_Page SHALL remove the existing PopupMenuButton (three-dot menu) from the AppBar actions.

### Requirement 2: Hiển thị Plus_Button trên Chat_List_Panel (Panel/Tablet)

**User Story:** Là người dùng tablet/desktop, tôi muốn thấy nút "+" trên header của panel danh sách chat, để tôi có thể tạo cuộc hội thoại hoặc nhóm mới mà không cần chuyển trang.

#### Acceptance Criteria

1. THE Chat_List_Panel SHALL display a Plus_Button as an IconButton with `Icons.add` icon in the header row, positioned after the search toggle button.

### Requirement 3: Hiển thị Action_Menu khi nhấn Plus_Button

**User Story:** Là người dùng, tôi muốn thấy menu popup với các tùy chọn khi nhấn nút "+", để tôi có thể chọn hành động phù hợp.

#### Acceptance Criteria

1. WHEN the user taps the Plus_Button, THE Action_Menu SHALL display a popup menu with exactly two options: "Thêm cuộc hội thoại" (localized via `context.l10n.newConversation`) and "Tạo nhóm mới" (localized via `context.l10n.createNewGroup`).
2. THE Action_Menu SHALL use localized strings from the l10n system for all displayed text.
3. THE Action_Menu SHALL display on both Chat_List_Page and Chat_List_Panel with identical options.

### Requirement 4: Điều hướng đến Contacts_Page từ Action_Menu

**User Story:** Là người dùng, tôi muốn chọn "Thêm cuộc hội thoại" từ menu để mở trang danh bạ, để tôi có thể chọn liên hệ và bắt đầu chat trực tiếp.

#### Acceptance Criteria

1. WHEN the user selects the "Thêm cuộc hội thoại" option from the Action_Menu, THE Chat_Navigation_Helper SHALL navigate to the Contacts_Page.
2. THE Chat_Navigation_Helper SHALL provide a `navigateToContacts` method that supports both package mode and standalone mode navigation.

### Requirement 5: Điều hướng đến Create_Group_Page từ Action_Menu

**User Story:** Là người dùng, tôi muốn chọn "Tạo nhóm mới" từ menu để mở trang tạo nhóm, để tôi có thể tạo nhóm chat với nhiều thành viên.

#### Acceptance Criteria

1. WHEN the user selects the "Tạo nhóm mới" option from the Action_Menu, THE Chat_Navigation_Helper SHALL navigate to the Create_Group_Page using the existing `navigateToCreateGroup` method.

### Requirement 6: Điều hướng đến Settings_Page từ Mobile

**User Story:** Là người dùng mobile, tôi muốn vẫn có thể truy cập trang cài đặt sau khi PopupMenuButton bị loại bỏ, để tôi không mất quyền truy cập vào chức năng cài đặt.

#### Acceptance Criteria

1. THE Chat_List_Page SHALL provide navigation to the Settings_Page through the BottomNavigationBar settings tab (index 2, icon `Icons.settings`).

### Requirement 7: Thêm chuỗi bản địa hóa mới

**User Story:** Là nhà phát triển, tôi muốn có chuỗi bản địa hóa cho tùy chọn "Thêm cuộc hội thoại", để ứng dụng hỗ trợ đa ngôn ngữ.

#### Acceptance Criteria

1. THE l10n system SHALL include a `newConversation` key with English value "New conversation" in `app_en.arb`.
2. THE l10n system SHALL include a `newConversation` key with Vietnamese value "Thêm cuộc hội thoại" in `app_vi.arb`.

### Requirement 8: Thêm phương thức navigateToContacts vào Chat_Navigation_Helper

**User Story:** Là nhà phát triển, tôi muốn có phương thức điều hướng đến trang danh bạ trong Chat_Navigation_Helper, để việc điều hướng nhất quán với các phương thức hiện có.

#### Acceptance Criteria

1. THE Chat_Navigation_Helper SHALL provide a static `navigateToContacts` method that returns `Future<void>`.
2. WHILE in package mode, THE Chat_Navigation_Helper SHALL wrap the Contacts_Page with ChatModule route wrapper for provider injection.
3. WHILE in standalone mode, THE Chat_Navigation_Helper SHALL navigate directly to the Contacts_Page using MaterialPageRoute.
