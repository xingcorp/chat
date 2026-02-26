# Tasks

## Task 1: Add localization keys

- [ ] 1.1 Add `newConversation` key to `flutter_chat_app/lib/l10n/app_en.arb` with value `"New conversation"`
- [ ] 1.2 Add `newConversation` key to `flutter_chat_app/lib/l10n/app_vi.arb` with value `"Thêm cuộc hội thoại"`

## Task 2: Add `contactsRoute` and `contactsPage` to ChatModule

- [ ] 2.1 Add `import` for `ContactsPage` in `flutter_chat_app/lib/chat_module.dart`
- [ ] 2.2 Add `contactsPage()` static method returning `_ChatPackageWrapper(child: ContactsPage())` in `flutter_chat_app/lib/chat_module.dart`
- [ ] 2.3 Add `contactsRoute()` static method returning `MaterialPageRoute` wrapped with `_ChatPackageWrapper` in `flutter_chat_app/lib/chat_module.dart`

## Task 3: Add `navigateToContacts` to ChatNavigationHelper

- [ ] 3.1 Add `import` for `ContactsPage` in `flutter_chat_app/lib/core/navigation/chat_navigation_helper.dart`
- [ ] 3.2 Add `navigateToContacts` static method with package/standalone mode support in `flutter_chat_app/lib/core/navigation/chat_navigation_helper.dart`
- [ ] 3.3 Add `contactsRoute` static route builder method in `flutter_chat_app/lib/core/navigation/chat_navigation_helper.dart`

## Task 4: Update ChatListPage — replace FAB and PopupMenuButton with Plus Button

- [ ] 4.1 Remove `floatingActionButton` property from Scaffold in `flutter_chat_app/lib/features/chat/presentation/pages/chat/chat_list_page.dart`
- [ ] 4.2 Remove existing `PopupMenuButton<String>` from AppBar actions in `flutter_chat_app/lib/features/chat/presentation/pages/chat/chat_list_page.dart`
- [ ] 4.3 Add `PopupMenuButton<String>` with `Icons.add` icon in AppBar actions after search IconButton, with two menu items ("newConversation" → `navigateToContacts`, "newGroup" → `navigateToCreateGroup`) in `flutter_chat_app/lib/features/chat/presentation/pages/chat/chat_list_page.dart`

## Task 5: Update ChatListPanel — add Plus Button to header

- [ ] 5.1 Add `PopupMenuButton<String>` with `Icons.add` icon in header Row after search IconButton, with two menu items ("newConversation" → `navigateToContacts`, "newGroup" → `navigateToCreateGroup`) in `flutter_chat_app/lib/features/chat/presentation/widgets/chat/chat_list_panel.dart`

## Task 6: Write widget tests

- [ ] 6.1 Write widget test verifying ChatListPage shows Plus Button in AppBar and no FAB/old PopupMenuButton
- [ ] 6.2 Write widget test verifying ChatListPanel shows Plus Button in header
- [ ] 6.3 Write widget test verifying tapping Plus Button shows popup with two localized menu items
- [ ] 6.4 Write widget test verifying menu item selection triggers correct navigation
