# Kế Hoạch Triển Khai Chat Info Panel

## 1. Phân Tích Yêu Cầu

### 1.1 Tham khảo từ Angular Frontend
Frontend Angular đã triển khai sử dụng `mat-drawer` với 3 chế độ:
- **showSearch**: Tìm kiếm tin nhắn trong hội thoại
- **showMember**: Hiển thị danh sách thành viên (Group chat)
- **showInfo**: Hiển thị thông tin người dùng (Direct chat)

### 1.2 Tham khảo từ các ứng dụng chat lớn

| Tính năng | Telegram | WhatsApp | Messenger | Zalo |
|-----------|----------|----------|-----------|------|
| Avatar lớn | ✓ | ✓ | ✓ | ✓ |
| Tên/Bio | ✓ | ✓ | ✓ | ✓ |
| Media gallery | ✓ | ✓ | ✓ | ✓ |
| Search messages | ✓ | ✓ | ✓ | ✓ |
| Notifications toggle | ✓ | ✓ | ✓ | ✓ |
| Member list (group) | ✓ | ✓ | ✓ | ✓ |
| Add members | ✓ | ✓ | ✓ | ✓ |
| Leave group | ✓ | ✓ | ✓ | ✓ |
| Block/Report | ✓ | ✓ | ✓ | ✓ |
| Shared links | ✓ | ✓ | ✓ | ✓ |
| Delete chat | ✓ | ✓ | ✓ | ✓ |

---

## 2. Kiến Trúc UI

### 2.1 Layout Pattern
Sử dụng **Sliding Panel / Bottom Sheet** pattern:
- **Mobile**: Bottom Sheet có thể kéo full screen
- **Tablet/Desktop**: Side Panel (drawer) từ bên phải

### 2.2 Cấu trúc Widget

```
ChatInfoPanel
├── ChatInfoHeader
│   ├── CloseButton / BackButton
│   ├── Avatar (large, tappable)
│   ├── Name
│   ├── Status / Member count
│   └── EditButton (nếu là group admin)
│
├── ChatInfoQuickActions
│   ├── SearchButton (tìm trong chat)
│   ├── NotificationToggle
│   ├── CallButton (nếu có)
│   └── VideoCallButton (nếu có)
│
├── ChatInfoSections (Scrollable)
│   │
│   ├── [Direct Chat Only] UserInfoSection
│   │   ├── Phone
│   │   ├── Email
│   │   ├── Department
│   │   └── Bio/Status
│   │
│   ├── [Group Chat Only] MembersSection
│   │   ├── MemberCount header
│   │   ├── AddMemberButton (nếu có quyền)
│   │   └── MemberList (scrollable, với lazy loading)
│   │       └── MemberTile
│   │           ├── Avatar
│   │           ├── Name
│   │           ├── Role badge (Admin/Owner)
│   │           ├── OnlineStatus
│   │           └── MoreActions menu
│   │
│   ├── SharedMediaSection
│   │   ├── TabBar: Photos | Videos | Files | Links
│   │   └── MediaGrid / FileList
│   │
│   └── SettingsSection
│       ├── NotificationSettings
│       ├── Encryption info
│       └── SharedGroups (direct chat)
│
└── ChatInfoDangerZone
    ├── BlockUser (direct chat)
    ├── LeaveGroup (group chat)
    ├── ReportButton
    └── DeleteChat
```

---

## 3. Files Cần Tạo

### 3.1 Presentation Layer

```
lib/features/chat/presentation/
├── pages/chat/
│   └── chat_info_page.dart           # Full page (mobile)
│
├── widgets/chat_info/
│   ├── chat_info_panel.dart          # Main container widget
│   ├── chat_info_header.dart         # Header section
│   ├── chat_info_quick_actions.dart  # Quick action buttons
│   ├── user_info_section.dart        # Direct chat user info
│   ├── members_section.dart          # Group members list
│   ├── member_tile.dart              # Individual member item
│   ├── shared_media_section.dart     # Media/files gallery
│   ├── settings_section.dart         # Settings options
│   └── danger_zone_section.dart      # Destructive actions
```

### 3.2 BLoC/State Management

```
lib/features/chat/presentation/blocs/chat_info/
├── chat_info_bloc.dart
├── chat_info_event.dart
└── chat_info_state.dart
```

### 3.3 Domain Layer (nếu cần)

```
lib/features/chat/domain/usecases/
├── get_shared_media_usecase.dart
├── update_notification_settings_usecase.dart
├── block_user_usecase.dart
└── report_chat_usecase.dart
```

---

## 4. Triển Khai Chi Tiết

### Phase 1: Core UI (MVP)

#### 4.1 ChatInfoPanel Widget
```dart
class ChatInfoPanel extends StatelessWidget {
  final Chat chat;
  final VoidCallback? onClose;

  // Hiển thị khác nhau tùy ChatType.direct vs ChatType.group
}
```

#### 4.2 Tích hợp vào ChatDetailsPage
```dart
// Trong chat_details_page.dart
void _showChatInfo() {
  if (isWideScreen) {
    // Show as side panel
    setState(() => _showInfoPanel = true);
  } else {
    // Show as bottom sheet or push new page
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChatInfoPanel(chat: widget.chat),
    );
  }
}
```

### Phase 2: Member Management (Group)

#### 4.3 MembersSection
- Danh sách thành viên với avatar, tên, role
- Online/offline indicator
- Menu actions: Xem profile, Đặt làm admin, Xóa khỏi nhóm
- Nút thêm thành viên

#### 4.4 Member Actions
- Add member → Navigator.push(AddMemberPage)
- Remove member → Confirmation dialog → API call
- Set/Remove admin → API call

### Phase 3: Shared Media

#### 4.5 SharedMediaSection
- Tabs: Photos | Videos | Files | Links
- Grid view cho media
- List view cho files/links
- Pagination/lazy loading

### Phase 4: Settings & Actions

#### 4.6 Notification Settings
- Mute notifications (on/off)
- Mute duration options (1h, 8h, 1d, forever)

#### 4.7 Danger Zone
- Block user (direct chat)
- Leave group (confirmation)
- Delete chat (confirmation)
- Report

---

## 5. UI/UX Guidelines

### 5.1 Design Tokens
- Sử dụng theme colors từ `app_theme.dart`
- Border radius: 12-16dp cho cards
- Spacing: 8, 12, 16, 24dp
- Avatar sizes: 72dp (header), 48dp (member list)

### 5.2 Animations
- Slide transition khi mở panel
- Hero animation cho avatar (từ header)
- Fade transitions cho sections

### 5.3 Responsive Behavior
| Screen Size | Behavior |
|-------------|----------|
| Phone (< 600dp) | Full screen page hoặc bottom sheet |
| Tablet (600-900dp) | Side panel 320dp width |
| Desktop (> 900dp) | Side panel 400dp width |

### 5.4 Accessibility
- Semantic labels cho tất cả interactive elements
- Đủ contrast ratio
- Focus management
- Screen reader support

---

## 6. API Integration

### 6.1 Existing Endpoints (tái sử dụng)
- `GET /chat/:id` - Chi tiết chat với members
- `POST /chat/:id/leave` - Rời nhóm
- `DELETE /chat/:id` - Xóa chat
- `PUT /chat/:id` - Cập nhật thông tin nhóm

### 6.2 New Endpoints (nếu cần)
- `GET /chat/:id/media` - Lấy shared media
- `PUT /chat/:id/notifications` - Cập nhật notification settings
- `POST /user/:id/block` - Block user
- `POST /chat/:id/report` - Report chat

---

## 7. Localization Keys

```yaml
# Thêm vào intl_en.arb và intl_vi.arb
chatInfo: "Chat Info"
members: "Members"
addMembers: "Add Members"
sharedMedia: "Shared Media"
photos: "Photos"
videos: "Videos"
files: "Files"
links: "Links"
notifications: "Notifications"
muteNotifications: "Mute Notifications"
muteFor: "Mute for"
oneHour: "1 hour"
eightHours: "8 hours"
oneDay: "1 day"
forever: "Forever"
blockUser: "Block User"
leaveGroup: "Leave Group"
deleteChat: "Delete Chat"
report: "Report"
admin: "Admin"
owner: "Owner"
removeFromGroup: "Remove from Group"
makeAdmin: "Make Admin"
removeAdmin: "Remove Admin"
viewProfile: "View Profile"
```

---

## 8. Testing Strategy

### 8.1 Unit Tests
- ChatInfoBloc tests
- Use case tests

### 8.2 Widget Tests
- ChatInfoPanel renders correctly
- Member list interactions
- Button actions

### 8.3 Integration Tests
- Open chat info from header
- Add/remove members
- Leave group flow

---

## 9. Timeline Đề Xuất

| Phase | Tasks | Priority |
|-------|-------|----------|
| 1 | Core UI (header, basic info) | High |
| 2 | Member list & management | High |
| 3 | Shared media gallery | Medium |
| 4 | Notification settings | Medium |
| 5 | Block/Report/Delete | Medium |
| 6 | Polish & animations | Low |

---

## 10. Dependencies

### 10.1 Existing
- `flutter_bloc` - State management
- `get_it` - DI
- `cached_network_image` - Image loading
- `intl` - Localization

### 10.2 New (nếu cần)
- `photo_view` - Full screen image viewer
- `share_plus` - Share functionality

---

## 11. Mockup Reference

```
┌─────────────────────────────────┐
│  ←  Chat Info              ✕   │
├─────────────────────────────────┤
│                                 │
│         ┌───────┐               │
│         │ Avatar│               │
│         │  72dp │               │
│         └───────┘               │
│                                 │
│        John Doe                 │
│     Online • Marketing          │
│                                 │
├─────────────────────────────────┤
│  🔍 Search   🔔 Mute   📞 Call  │
├─────────────────────────────────┤
│                                 │
│  📧 john.doe@company.com        │
│  📱 +84 123 456 789             │
│  🏢 Marketing Department        │
│                                 │
├─────────────────────────────────┤
│  Shared Media            See All│
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │ 📷 │ │ 📷 │ │ 📷 │ │ 📷 │   │
│  └────┘ └────┘ └────┘ └────┘   │
├─────────────────────────────────┤
│                                 │
│  🚫 Block User                  │
│  🗑️ Delete Chat                 │
│  ⚠️ Report                      │
│                                 │
└─────────────────────────────────┘
```

---

## 12. Notes

1. **Consistency**: Giữ UI consistent với Angular frontend
2. **Performance**: Lazy load members và media
3. **Offline**: Cache thông tin cơ bản
4. **Security**: Validate permissions trước mỗi action
5. **UX**: Confirmation dialogs cho destructive actions
