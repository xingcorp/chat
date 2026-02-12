# Chat List Improvement Plan

## Executive Summary

**Objective**: Transform chat list from basic static display to production-grade real-time messaging interface matching industry standards (Facebook Messenger, Zalo, WhatsApp).

**Timeline**: 4-5 development days (senior developer)
**Impact**: Critical UX improvements + Real-time functionality
**Risk Level**: Medium (requires socket integration and state management changes)

---

## Problem Analysis

### Critical Issues (P0 - Blocking)

#### 1. Real-time Updates Not Functional
- **Current State**: Socket subscriptions declared but never initialized
- **Impact**: Users must manually refresh to see new messages
- **Root Cause**: `_subscribeToRealTimeUpdates()` contains only TODO comments
- **Code Location**: `features/chat/presentation/blocs/chat/chat_bloc.dart:298-306`

#### 2. Message Preview Text-Only
- **Current State**: Only displays `chat.lastMessage` string
- **Impact**: No visual indication for image/file/video attachments
- **Missing**: Attachment type icons (📷, 📄, 📹, 🎧)
- **Code Location**: `features/chat/presentation/pages/chat/chat_list_page.dart:332-343`

#### 3. Unread Badge Never Clears
- **Current State**: Badge shows `chat.unreadCount` without mark-as-read logic
- **Impact**: Badge persists after reading messages
- **Missing**: Mark as read on navigation + socket event listener
- **Code Location**: `features/chat/presentation/pages/chat/chat_list_page.dart:291-306`

### UI/UX Issues (P1 - Important)

#### 4. Message Status Indicators Missing
- No sending/sent/delivered/read indicators
- User cannot see message delivery state

#### 5. Typing Indicator Absent
- No visual feedback when other user is typing
- Reduces real-time communication feel

#### 6. Relative Timestamps Not Implemented
- Shows absolute time instead of "2m ago", "5h ago"
- Less intuitive for recent messages

#### 7. Mute State Not Visualized
- Muted chats have no visual distinction
- Cannot identify muted conversations at a glance

---

## Solution Architecture

### Design Principles

1. **Pattern Consistency**: Follow existing BLoC + Repository + DataSource architecture
2. **Clean Separation**: Business logic in BLoC, UI logic in widgets, formatting in dedicated services
3. **Internationalization**: All strings through l10n, no hardcoded text
4. **Scalability**: Support for future features (draft messages, pinned chats, custom status)
5. **Testability**: Pure functions for formatters, mockable repositories

### Component Structure

```
lib/
├── core/
│   ├── formatters/
│   │   ├── message_preview_formatter.dart       (NEW)
│   │   └── relative_time_formatter.dart         (NEW)
│   └── extensions/
│       └── date_time_extensions.dart            (UPDATE)
├── features/chat/
│   ├── domain/
│   │   └── entities/
│   │       └── chat.dart                        (UPDATE - add typing state)
│   ├── presentation/
│   │   ├── blocs/chat/
│   │   │   ├── chat_bloc.dart                   (UPDATE - real-time handlers)
│   │   │   ├── chat_event.dart                  (UPDATE - add events)
│   │   │   └── chat_state.dart                  (UPDATE - add states)
│   │   ├── pages/chat/
│   │   │   └── chat_list_page.dart              (UPDATE - use new widgets)
│   │   └── widgets/
│   │       ├── chat_conversation_tile.dart      (NEW)
│   │       ├── typing_indicator_widget.dart     (NEW)
│   │       └── message_status_indicator.dart    (NEW)
└── l10n/
    ├── arb/
    │   ├── app_en.arb                           (UPDATE)
    │   └── app_vi.arb                           (UPDATE)
```

---

## Implementation Plan

### Phase 1: Critical Functionality (Days 1-2) - PRIORITY

#### Task 1.1: Setup Real-time Socket Subscriptions
**File**: `features/chat/presentation/blocs/chat/chat_bloc.dart`

**Changes**:
```dart
// Constructor - register event handlers
on<NewMessageReceived>(_onNewMessageReceived);
on<MessagesMarkedAsRead>(_onMessagesMarkedAsRead);
on<TypingStateChanged>(_onTypingStateChanged);

// Implementation
void _subscribeToRealTimeUpdates() {
  // Cancel existing subscriptions
  _chatUpdatesSubscription?.cancel();
  _messageSubscription?.cancel();

  // Listen to socket events
  final socketManager = getIt<SocketManager>();

  // New message event
  _messageSubscription = socketManager.on('message:new').listen((data) {
    try {
      final message = ChatMessage.fromJson(data);
      add(ChatEvent.newMessageReceived(message));
    } catch (e, stackTrace) {
      logger.e('Error parsing new message', error: e, stackTrace: stackTrace);
    }
  });

  // Chat updated event (for unread count, last message, etc.)
  _chatUpdatesSubscription = socketManager.on('chat:updated').listen((data) {
    try {
      final chat = Chat.fromJson(data);
      add(ChatEvent.chatUpdated(chat: chat));
    } catch (e, stackTrace) {
      logger.e('Error parsing chat update', error: e, stackTrace: stackTrace);
    }
  });

  // Typing indicator event
  socketManager.on('typing:start').listen((data) {
    final chatId = data['chatId'] as String;
    final userId = data['userId'] as String;
    add(ChatEvent.typingStateChanged(chatId: chatId, userId: userId, isTyping: true));
  });

  socketManager.on('typing:stop').listen((data) {
    final chatId = data['chatId'] as String;
    final userId = data['userId'] as String;
    add(ChatEvent.typingStateChanged(chatId: chatId, userId: userId, isTyping: false));
  });

  logger.i('Real-time subscriptions established');
}

// Event handlers
void _onNewMessageReceived(
  NewMessageReceived event,
  Emitter<ChatState> emit,
) async {
  final message = event.message;
  final chatId = message.chatId;

  // Get current chats
  final currentChats = state.maybeWhen(
    loaded: (chats) => chats,
    orElse: () => <Chat>[],
  );

  // Find and update the chat
  final updatedChats = _updateChatWithNewMessage(currentChats, message);

  emit(ChatState.loaded(updatedChats));
}

List<Chat> _updateChatWithNewMessage(List<Chat> chats, ChatMessage message) {
  final chatId = message.chatId;
  final chatIndex = chats.indexWhere((c) => c.id == chatId);

  if (chatIndex == -1) {
    // Chat not in list, fetch it
    _loadSingleChat(chatId);
    return chats;
  }

  final chat = chats[chatIndex];
  final updatedChat = chat.copyWith(
    lastMessage: message.content,
    lastMessageAt: message.createdAt,
    unreadCount: message.senderId != _currentUserId
        ? chat.unreadCount + 1
        : chat.unreadCount,
  );

  // Move to top of list
  final newChats = [
    updatedChat,
    ...chats.where((c) => c.id != chatId),
  ];

  return newChats;
}

void _onMessagesMarkedAsRead(
  MessagesMarkedAsRead event,
  Emitter<ChatState> emit,
) async {
  final chatId = event.chatId;

  final currentChats = state.maybeWhen(
    loaded: (chats) => chats,
    orElse: () => <Chat>[],
  );

  final updatedChats = currentChats.map((chat) {
    if (chat.id == chatId) {
      return chat.copyWith(unreadCount: 0);
    }
    return chat;
  }).toList();

  emit(ChatState.loaded(updatedChats));

  // Notify backend
  try {
    await _chatRepository.markChatAsRead(chatId);
  } catch (e, stackTrace) {
    logger.e('Failed to mark chat as read', error: e, stackTrace: stackTrace);
  }
}

void _onTypingStateChanged(
  TypingStateChanged event,
  Emitter<ChatState> emit,
) async {
  final chatId = event.chatId;
  final userId = event.userId;
  final isTyping = event.isTyping;

  // Don't show typing indicator for current user
  if (userId == _currentUserId) return;

  final currentChats = state.maybeWhen(
    loaded: (chats) => chats,
    orElse: () => <Chat>[],
  );

  final updatedChats = currentChats.map((chat) {
    if (chat.id == chatId) {
      return chat.copyWith(
        typingUserIds: isTyping
            ? [...chat.typingUserIds, userId]
            : chat.typingUserIds.where((id) => id != userId).toList(),
      );
    }
    return chat;
  }).toList();

  emit(ChatState.loaded(updatedChats));
}
```

**Events to Add**:
```dart
// chat_event.dart
@freezed
class ChatEvent with _$ChatEvent {
  // ... existing events ...

  const factory ChatEvent.newMessageReceived(ChatMessage message) = NewMessageReceived;
  const factory ChatEvent.messagesMarkedAsRead({required String chatId}) = MessagesMarkedAsRead;
  const factory ChatEvent.typingStateChanged({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) = TypingStateChanged;
  const factory ChatEvent.chatUpdated({required Chat chat}) = ChatUpdated;
}
```

**Testing**:
- [ ] New message arrives → chat moves to top
- [ ] Unread count increments for messages from others
- [ ] Unread count unchanged for own messages
- [ ] Socket reconnection maintains subscriptions

---

#### Task 1.2: Message Preview Formatter
**File**: `lib/core/formatters/message_preview_formatter.dart` (NEW)

**Implementation**:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Service for formatting message previews with attachment type indicators.
///
/// Follows Stream Chat Flutter patterns for consistency and extensibility.
/// All formatting is internationalized through l10n.
class MessagePreviewFormatter {
  const MessagePreviewFormatter._();

  /// Formats a message preview with attachment indicators.
  ///
  /// Returns formatted text with emoji icons for attachments:
  /// - 📷 Photo
  /// - 📹 Video
  /// - 🎧 Audio
  /// - 📄 Document
  /// - 🎤 Voice message
  ///
  /// Falls back to [text] if no attachments, or to [emptyMessage] if neither.
  static String format({
    required BuildContext context,
    String? text,
    List<Attachment>? attachments,
  }) {
    // If has attachments, show icon + title
    if (attachments != null && attachments.isNotEmpty) {
      return _formatWithAttachment(context, text, attachments.first);
    }

    // If has text, show it
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }

    // Empty message
    return context.l10n.emptyMessage;
  }

  static String _formatWithAttachment(
    BuildContext context,
    String? text,
    Attachment attachment,
  ) {
    final icon = _getAttachmentIcon(attachment.type);
    final title = _getAttachmentTitle(context, attachment, text);

    if (icon.isEmpty) {
      return title;
    }

    return '$icon $title';
  }

  static String _getAttachmentIcon(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => '📷',
      AttachmentType.video => '📹',
      AttachmentType.audio => '🎧',
      AttachmentType.file => '📄',
      AttachmentType.voiceRecording => '🎤',
      _ => '',
    };
  }

  static String _getAttachmentTitle(
    BuildContext context,
    Attachment attachment,
    String? text,
  ) {
    final l10n = context.l10n;

    // If message has text, prefer it
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }

    // Otherwise use localized attachment type name
    return switch (attachment.type) {
      AttachmentType.image => l10n.photo,
      AttachmentType.video => l10n.video,
      AttachmentType.audio => l10n.audio,
      AttachmentType.file => attachment.name ?? l10n.file,
      AttachmentType.voiceRecording => l10n.voiceMessage,
      _ => l10n.attachment,
    };
  }
}
```

**L10n Additions**:
```dart
// app_en.arb
"emptyMessage": "No message",
"photo": "Photo",
"video": "Video",
"audio": "Audio",
"file": "File",
"voiceMessage": "Voice message",
"attachment": "Attachment"

// app_vi.arb
"emptyMessage": "Không có tin nhắn",
"photo": "Ảnh",
"video": "Video",
"audio": "Âm thanh",
"file": "Tệp",
"voiceMessage": "Tin nhắn thoại",
"attachment": "Tệp đính kèm"
```

**Testing**:
- [ ] Text message → shows text only
- [ ] Image + text → shows "📷 [text]"
- [ ] Image no text → shows "📷 Ảnh"
- [ ] File with name → shows "📄 filename.pdf"
- [ ] Empty message → shows "Không có tin nhắn"

---

#### Task 1.3: Mark as Read on Navigation
**File**: `features/chat/presentation/pages/chat/chat_list_page.dart`

**Changes**:
```dart
Widget _buildChatListItem(BuildContext context, Chat chat) {
  // ... existing code ...

  return AppCard.filled(
    // ... existing properties ...
    onTap: () async {
      final chatId = chat.id;

      // Optimistic update: clear unread badge immediately
      if (chat.unreadCount > 0) {
        _chatBloc.add(ChatEvent.messagesMarkedAsRead(chatId: chatId));
      }

      // Navigate to chat detail
      final result = await ChatNavigationHelper.navigateToChatDetail(
        context,
        chatId: chatId,
      );

      // Refresh list when returning (in case of new messages)
      if (result != null || !mounted) return;
      _chatBloc.add(const ChatEvent.loadChats(forceRefresh: true));
    },
    child: // ... existing child ...
  );
}
```

**Repository Addition**:
```dart
// features/chat/domain/repositories/i_chat_repository.dart
abstract class IChatRepository {
  // ... existing methods ...

  /// Marks all messages in a chat as read by the current user.
  Future<Either<Failure, Unit>> markChatAsRead(String chatId);
}

// features/chat/data/repositories/chat_repository_impl.dart
@override
Future<Either<Failure, Unit>> markChatAsRead(String chatId) async {
  try {
    await _remoteDataSource.markChatAsRead(chatId);
    await _localDataSource.updateChatUnreadCount(chatId, 0);
    return const Right(unit);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

**Testing**:
- [ ] Click chat → badge disappears immediately
- [ ] Return to list → badge still cleared
- [ ] Backend receives mark-as-read request

---

### Phase 2: UI Enhancements (Days 3-4)

#### Task 2.1: Relative Time Formatter
**File**: `lib/core/formatters/relative_time_formatter.dart` (NEW)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Formats timestamps as relative time strings (e.g., "2m ago", "3h ago").
///
/// Follows industry standards:
/// - < 1 minute: "now"
/// - < 60 minutes: "Xm"
/// - < 24 hours: "Xh"
/// - < 7 days: "Xd"
/// - >= 7 days: absolute date
class RelativeTimeFormatter {
  const RelativeTimeFormatter._();

  static String format(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return context.l10n.justNow;
    }

    if (difference.inMinutes < 60) {
      return context.l10n.minutesAgo(difference.inMinutes);
    }

    if (difference.inHours < 24) {
      return context.l10n.hoursAgo(difference.inHours);
    }

    if (difference.inDays < 7) {
      return context.l10n.daysAgo(difference.inDays);
    }

    // For older messages, show absolute date
    return _formatAbsoluteDate(context, dateTime);
  }

  static String _formatAbsoluteDate(BuildContext context, DateTime dateTime) {
    // Use existing DateFormatterService for consistency
    return DateFormatterService.formatTimeForMessage(dateTime);
  }
}
```

---

#### Task 2.2: Professional Chat List Tile Widget
**File**: `features/chat/presentation/widgets/chat_conversation_tile.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/formatters/message_preview_formatter.dart';
import 'package:flutter_chat_app/core/formatters/relative_time_formatter.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

import 'typing_indicator_widget.dart';
import 'message_status_indicator.dart';

/// Professional chat conversation list tile.
///
/// Displays:
/// - Avatar with mute indicator overlay
/// - Chat name (bold if unread)
/// - Message preview with attachment icons
/// - Relative timestamp
/// - Unread count badge (formatted "99+" for large numbers)
/// - Typing indicator animation
/// - Message status indicator (sending/sent/delivered/read)
///
/// Follows Facebook Messenger / Zalo design patterns.
class ChatConversationTile extends StatelessWidget {
  const ChatConversationTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.onTap,
  });

  final Chat chat;
  final String currentUserId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;
    final isTyping = chat.typingUserIds.isNotEmpty;
    final isOwnMessage = chat.lastMessage?.senderId == currentUserId;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: AppDimens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(context, hasUnread, isTyping),
                  const SizedBox(height: AppDimens.spaceXSmall),
                  _buildSubtitleRow(context, hasUnread, isOwnMessage, isTyping),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.spaceSmall),
            _buildTrailing(context, hasUnread),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        AppHeroAvatar(
          id: chat.id,
          imageUrl: chat.avatarUrl,
          displayName: chat.name,
          size: AvatarSize.large,
          hasBorder: false,
        ),
        if (chat.isMuted)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.volume_off,
                size: 10,
                color: AppColors.textButton,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context, bool hasUnread, bool isTyping) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            chat.name ?? context.l10n.unknownUser,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
              color: hasUnread ? AppColors.textPrimary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isTyping) ...[
          const SizedBox(width: AppDimens.spaceSmall),
          const TypingIndicatorWidget(),
        ],
      ],
    );
  }

  Widget _buildSubtitleRow(
    BuildContext context,
    bool hasUnread,
    bool isOwnMessage,
    bool isTyping,
  ) {
    if (isTyping) {
      return AppText(
        context.l10n.typing,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: [
        if (isOwnMessage) ...[
          MessageStatusIndicator(
            status: chat.lastMessage?.status,
            size: 14,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: AppText(
            MessagePreviewFormatter.format(
              context: context,
              text: chat.lastMessage?.content,
              attachments: chat.lastMessage?.attachments,
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, bool hasUnread) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppText(
          RelativeTimeFormatter.format(context, chat.lastMessageAt),
          style: AppTextStyles.labelSmall.copyWith(
            color: hasUnread ? AppColors.primary : AppColors.textSecondary,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (hasUnread) ...[
          const SizedBox(height: 4),
          _buildUnreadBadge(),
        ],
      ],
    );
  }

  Widget _buildUnreadBadge() {
    final displayCount = chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
      ),
      child: AppText(
        displayCount,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textButton,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

---

#### Task 2.3: Typing Indicator Widget
**File**: `features/chat/presentation/widgets/typing_indicator_widget.dart` (NEW)

```dart
import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Animated typing indicator with three bouncing dots.
///
/// Animation pattern: Staggered sine wave for natural typing feel.
/// Used in chat list to show when other users are typing.
class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({
    super.key,
    this.dotSize = 4.0,
    this.dotColor,
  });

  final double dotSize;
  final Color? dotColor;

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.dotColor ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Stagger each dot by 0.2
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);

            // Sine wave for smooth bounce
            final opacity = (sin(progress * pi * 2) * 0.5 + 0.5);

            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
```

---

#### Task 2.4: Message Status Indicator
**File**: `features/chat/presentation/widgets/message_status_indicator.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Displays message sending status with appropriate icon.
///
/// Status mapping:
/// - Sending: clock icon (grey)
/// - Sent: single check (grey)
/// - Delivered: double check (grey)
/// - Read: double check (primary color)
class MessageStatusIndicator extends StatelessWidget {
  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.size = 16.0,
  });

  final MessageStatus? status;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    final iconData = _getIconData(status!);
    final color = _getColor(status!);

    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }

  IconData _getIconData(MessageStatus status) {
    return switch (status) {
      MessageStatus.sending => Icons.access_time,
      MessageStatus.sent => Icons.check,
      MessageStatus.delivered => Icons.done_all,
      MessageStatus.read => Icons.done_all,
      MessageStatus.failed => Icons.error_outline,
    };
  }

  Color _getColor(MessageStatus status) {
    return switch (status) {
      MessageStatus.read => AppColors.primary,
      MessageStatus.failed => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }
}
```

---

### Phase 3: Testing & Polish (Day 5)

#### Task 3.1: Integration Testing
- [ ] Real-time message reception
- [ ] Unread count updates
- [ ] Typing indicator triggers
- [ ] Mark as read functionality
- [ ] Socket reconnection handling

#### Task 3.2: Unit Testing
- [ ] MessagePreviewFormatter.format()
- [ ] RelativeTimeFormatter.format()
- [ ] ChatBloc event handlers
- [ ] Repository mark as read

#### Task 3.3: UI Testing
- [ ] Chat list renders correctly
- [ ] Animations smooth (60fps)
- [ ] Tap gestures responsive
- [ ] Scroll performance acceptable

---

## Migration Guide

### Breaking Changes
None. All changes are additive.

### Update ChatListPage Usage
```dart
// Before
_buildChatListItem(context, chat);

// After (recommended)
ChatConversationTile(
  chat: chat,
  currentUserId: currentUserId,
  onTap: () => _handleChatTap(chat),
);
```

---

## Success Metrics

### Performance Targets
- Message arrival latency: < 500ms
- UI update latency: < 100ms (60fps)
- Badge clear latency: < 50ms

### Quality Gates
- [ ] Zero lint warnings in new code
- [ ] 80%+ unit test coverage for new services
- [ ] All strings internationalized
- [ ] No memory leaks in socket subscriptions
- [ ] Accessibility labels present

---

## Risk Mitigation

### Technical Risks

1. **Socket Connection Instability**
   - Mitigation: Implement exponential backoff retry
   - Fallback: Poll-based updates if socket fails

2. **State Synchronization Issues**
   - Mitigation: Server-authoritative updates
   - Validation: Periodic full sync

3. **Performance Degradation**
   - Mitigation: Debounce typing events
   - Monitoring: Performance traces

### Timeline Risks

1. **Backend API Not Ready**
   - Mitigation: Mock socket events for development
   - Documentation: Define socket event contract

2. **Scope Creep**
   - Mitigation: Strict phase boundaries
   - Control: P0 features only for Phase 1

---

## Next Steps After Phase 1

1. Draft message persistence
2. Pinned conversations
3. Swipe actions (archive, delete, mute)
4. Search & filter
5. Multi-select mode
6. Conversation settings

---

## Appendix

### Socket Event Contracts

```typescript
// message:new
{
  id: string;
  chatId: string;
  senderId: string;
  content: string;
  attachments: Attachment[];
  createdAt: string; // ISO 8601
  status: 'sending' | 'sent' | 'delivered' | 'read';
}

// chat:updated
{
  id: string;
  name: string;
  avatarUrl?: string;
  lastMessage: string;
  lastMessageAt: string;
  unreadCount: number;
}

// typing:start / typing:stop
{
  chatId: string;
  userId: string;
  userName: string;
}
```

### Code Review Checklist

- [ ] BLoC pattern followed correctly
- [ ] All strings use l10n
- [ ] Error handling implemented
- [ ] Logger used for debugging
- [ ] No hardcoded values
- [ ] Null safety respected
- [ ] Performance acceptable
- [ ] Documentation present
