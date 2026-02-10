# Kế Hoạch Triển Khai Presentation Layer + Nâng Cấp UI Chat

> **Mục tiêu**: Thêm tầng Presentation/UI State giữa Domain Entity và Widget, đồng bộ thuộc tính với Angular frontend, nâng cấp UI tham khảo stream_chat_flutter.

---

## Tổng Quan Kiến Trúc

### Kiến trúc hiện tại (4 tầng)
```
Backend API → DTO (Freezed) → Isar Model → Domain Entity → Widget (trực tiếp)
```

### Kiến trúc mới (5 tầng)
```
Backend API → DTO (Freezed) → Isar Model → Domain Entity → UI State → Widget
                                                              ↑
                                                     MessageListTransformer
```

### Mapping thuộc tính Backend → Angular → Flutter

| Backend (NestJS)       | Angular Frontend          | Flutter DTO              | Flutter Domain Entity     | Flutter UI State (MỚI)    |
|------------------------|---------------------------|--------------------------|---------------------------|---------------------------|
| `id`                   | `id`                      | `id`                     | `id`                      | `message.id`              |
| `message`              | `message`                 | `content` (@JsonKey)     | `content`                 | `message.content`         |
| `type` (TEXT/IMAGE/...) | `type` (ChatMessageType) | `type` (String)          | `contentType` (enum)      | `message.contentType`     |
| `senderId`             | `senderId`                | `senderId`               | `sender.id`               | `message.sender.id`       |
| `sender`               | `sender` (OfficeUser)     | `sender` (SenderDto)     | `sender` (MessageSender)  | `message.sender`          |
| `conversationId`       | `conversationId`          | `chatId` (@JsonKey)      | `chatId`                  | `message.chatId`          |
| `createdAt` (ms)       | `createdAt` (ms)          | `createdAt` (int ms)     | `createdAt` (DateTime)    | `message.createdAt`       |
| `editAt` (ms)          | `editAt` (ms)             | `editAt` (int? ms)       | `editedAt` (DateTime?)    | `message.editedAt`        |
| `deletedAt` (ms)       | `deletedAt` (ms)          | `deletedAt` (int? ms)    | `deletedAt` (DateTime?)   | `message.deletedAt`       |
| `replyMessageId`       | `replyMessageId`          | `replyMessageId`         | _(thiếu)_                 | `replyMessage`            |
| `replyMessage`         | `replyMessage`            | `replyMessage`           | _(thiếu)_                 | `replyMessage`            |
| `forwardedFromMessageId` | `forwardedFromMessageId` | `forwardedFromMessageId` | `forwardedFromMessageId`  | `message.forwardedFromMessageId` |
| `forwardedFromMessage` | `forwardedFromMessage`    | _(thiếu)_                | _(thiếu)_                 | `forwardedFromMessage`    |
| `fileName`             | `fileName`                | `fileName`               | `fileName`                | `message.fileName`        |
| `urls[]`               | `urls[]`                  | `urls[]`                 | `urls[]`                  | `message.urls`            |
| `reactions[]`          | `reactions[]`             | `reactions[]`            | `reactions[]`             | `groupedReactions`        |
| `readerIds[]`          | `readerIds[]`             | `readerIds[]`            | `readBy[]`                | `message.readBy`          |
| `readers[]`            | `readers[]`               | _(thiếu)_                | _(thiếu)_                 | _(không cần ở client)_    |
| `mentionTo[]`          | `mentionTo[]`             | `mentionTo[]`            | `mentionTo[]`             | `message.mentionTo`       |
| `actionType` (LOG)     | `actionType`              | _(thiếu)_                | _(thiếu)_                 | `actionType`              |
| `actor` (LOG)          | `actor`                   | _(thiếu)_                | _(thiếu)_                 | `actor`                   |
| `targetUsers` (LOG)    | `targetUsers`             | _(thiếu)_                | _(thiếu)_                 | `targetUsers`             |
| `newValue` (LOG)       | `newValue`                | _(thiếu)_                | _(thiếu)_                 | `newValue`                |
| `oldValue` (LOG)       | `oldValue`                | _(thiếu)_                | _(thiếu)_                 | `oldValue`                |

### Thuộc tính UI-computed (Angular frontend dùng, Flutter cần thêm)

| Angular Property       | Mô tả                                     | Flutter UI State (MỚI)       |
|------------------------|--------------------------------------------|------------------------------|
| `firstMessage`         | Tin nhắn đầu tiên trong group (show avatar/name) | `position` (BubblePosition) |
| `role` (OWNER/MEMBER)  | Phân biệt tin nhắn mình/người khác         | `isFromCurrentUser` (bool)  |
| `sending`              | Đang chờ server xác nhận                   | `isSending` (bool)          |
| `lastMessageRead`      | Đánh dấu ranh giới đã đọc                 | `isLastRead` (bool)         |
| `hasLink`              | Tin nhắn chứa URL                          | `hasLink` (bool)            |
| `hasMention`           | Tin nhắn chứa @mention                     | `hasMention` (bool)         |
| `innerHTML`            | HTML đã sanitize cho rendering             | _(Flutter dùng RichText)_   |
| `previewLink`          | URL cuối cùng cho link preview             | `previewLink` (String?)     |
| `messageEdited`        | Raw text khi đang edit                     | _(handled by BLoC state)_   |
| _(không có)_           | _(Angular dùng CSS cho date separator)_    | `showDateSeparator` (bool)  |
| _(không có)_           | _(Angular dùng CSS cho timestamp)_         | `showTimestamp` (bool)      |
| _(không có)_           | _(Angular không group reactions)_          | `groupedReactions` (List)   |

---

## PHASE 1 — Tầng Presentation/UI State (Nền tảng)

### 1.1. Tạo MessageUIState

**File**: `lib/features/chat/presentation/models/message_ui_state.dart`

```dart
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Vị trí bubble trong group tin nhắn liên tiếp
enum BubblePosition {
  /// Tin nhắn đầu tiên trong group (bo góc trên, hiện avatar + tên)
  first,
  /// Tin nhắn giữa group (bo góc nhỏ, ẩn avatar + tên)
  middle,
  /// Tin nhắn cuối cùng trong group (bo góc dưới, hiện avatar nhỏ)
  last,
  /// Tin nhắn đơn lẻ (bo góc đầy đủ, hiện avatar + tên)
  standalone,
}

/// Loại item trong danh sách tin nhắn (bao gồm cả separator)
enum MessageListItemType {
  /// Tin nhắn thường
  message,
  /// Date separator (dòng "Hôm nay", "Hôm qua", "10/02/2026")
  dateSeparator,
  /// Unread separator (dòng "Tin nhắn chưa đọc")
  unreadSeparator,
  /// System/Log event (thông báo hệ thống: thêm thành viên, đổi tên, ...)
  systemEvent,
}

/// Reaction đã gom nhóm theo emoji code
/// Khớp với Angular: OfficeChatMessageReaction { code, reactorIds, reactors }
class ReactionGroup {
  /// Emoji code (e.g., '👍', '❤️', '😂')
  final String code;
  /// Danh sách userId đã react emoji này
  final List<String> reactorIds;
  /// Danh sách tên người react (để hiển thị tooltip)
  final List<String> reactorNames;
  /// Số lượng người react
  int get count => reactorIds.length;
  /// Người dùng hiện tại đã react emoji này chưa
  final bool isReactedByCurrentUser;

  const ReactionGroup({
    required this.code,
    required this.reactorIds,
    this.reactorNames = const [],
    this.isReactedByCurrentUser = false,
  });
}

/// Reply message preview — khớp với Angular replyMessage render
class ReplyMessagePreview {
  final String id;
  final String senderName;
  final String? senderAvatar;
  final ContentType contentType;
  /// Nội dung text (nếu TEXT) hoặc "[Hình ảnh]", "[Video]", "[File] filename"
  final String previewText;
  /// URL preview (cho IMAGE/VIDEO)
  final String? previewUrl;

  const ReplyMessagePreview({
    required this.id,
    required this.senderName,
    this.senderAvatar,
    required this.contentType,
    required this.previewText,
    this.previewUrl,
  });
}

/// Forward message info
class ForwardMessageInfo {
  final String originalMessageId;
  final String? originalSenderName;

  const ForwardMessageInfo({
    required this.originalMessageId,
    this.originalSenderName,
  });
}

/// System event info — khớp với Angular ConversationActionType + generateActionText()
class SystemEventInfo {
  /// Loại action: ADD_MEMBER, CHANGE_NAME, REMOVE_MEMBER, ...
  final String actionType;
  /// Người thực hiện action
  final String? actorName;
  /// Danh sách user bị tác động
  final List<String> targetUserNames;
  /// Giá trị cũ (e.g., tên group cũ)
  final String? oldValue;
  /// Giá trị mới (e.g., tên group mới)
  final String? newValue;
  /// Text đã format sẵn (e.g., "An đã thêm Bình vào nhóm")
  final String formattedText;

  const SystemEventInfo({
    required this.actionType,
    this.actorName,
    this.targetUserNames = const [],
    this.oldValue,
    this.newValue,
    required this.formattedText,
  });
}

/// UI State cho mỗi item trong danh sách tin nhắn
///
/// Wrapper nhẹ quanh ChatMessage domain entity.
/// Chỉ thêm các thuộc tính computed mà widget cần.
/// Pattern tham khảo: Signal ConversationMessage, Flutter MVVM UI State.
class MessageUIState {
  // ══════════════════════════════════════════
  // Domain Entity gốc
  // ══════════════════════════════════════════

  /// Domain entity gốc — widget delegate xuống đây cho data access
  final ChatMessage? message;

  // ══════════════════════════════════════════
  // Loại item trong list
  // ══════════════════════════════════════════

  /// Loại item: message, dateSeparator, unreadSeparator, systemEvent
  final MessageListItemType itemType;

  // ══════════════════════════════════════════
  // Bubble Positioning (khớp Angular firstMessage logic)
  // ══════════════════════════════════════════

  /// Vị trí bubble trong group: first/middle/last/standalone
  /// Angular dùng `firstMessage: true` cho tin đầu group
  /// stream_chat_flutter dùng `isNextUserSame + hasTimeDiff`
  final BubblePosition position;

  /// Hiện avatar hay không
  /// - Angular: hiện khi firstMessage == true && role == MEMBER
  /// - stream_chat: hiện khi hasTimeDiff || !isNextUserSame
  /// - Cả hai: chỉ hiện cho tin nhắn NGƯỜI KHÁC, không hiện cho mình
  final bool showAvatar;

  /// Hiện tên người gửi hay không (cho group chat)
  /// Angular: hiện khi firstMessage == true && role == MEMBER
  final bool showSenderName;

  // ══════════════════════════════════════════
  // Timestamp & Date Separator
  // ══════════════════════════════════════════

  /// Hiện timestamp dưới bubble hay không
  /// stream_chat: hiện khi hasTimeDiff || !isNextUserSame
  /// Angular: luôn hiện (format 'h:mm a')
  final bool showTimestamp;

  /// Timestamp đã format sẵn: "2:30 PM", "14:30"
  final String formattedTime;

  /// Hiện date separator phía TRÊN tin nhắn này
  /// Angular: dùng format('dd/MM/yyyy') và compare startOfDay()
  final bool showDateSeparator;

  /// Text cho date separator: "Hôm nay", "Hôm qua", "10/02/2026"
  final String? dateSeparatorText;

  // ══════════════════════════════════════════
  // Reactions (gom nhóm theo emoji)
  // ══════════════════════════════════════════

  /// Reactions đã gom nhóm theo emoji code
  /// Angular: OfficeChatMessageReaction { code, reactorIds[], reactors[] }
  /// stream_chat: latestReactions grouped by type, own reaction prioritized
  final List<ReactionGroup> groupedReactions;

  /// Tổng số reactions
  int get totalReactionCount => groupedReactions.fold(0, (sum, r) => sum + r.count);

  // ══════════════════════════════════════════
  // Reply / Forward / Mention
  // ══════════════════════════════════════════

  /// Reply message preview — khớp Angular replyMessage render
  final ReplyMessagePreview? replyMessage;

  /// Forward info
  final ForwardMessageInfo? forwardInfo;

  /// Tin nhắn chứa @mention (Angular: hasMention)
  final bool hasMention;

  /// Tin nhắn chứa URL/link (Angular: hasLink)
  final bool hasLink;

  /// URL cho link preview (Angular: previewLink = last URL in message)
  final String? previewLink;

  // ══════════════════════════════════════════
  // Message Status & State
  // ══════════════════════════════════════════

  /// Đang gửi (Angular: sending, chờ server xác nhận)
  final bool isSending;

  /// Gửi thất bại
  final bool isFailed;

  /// Đã bị chỉnh sửa (Angular: editAt != null)
  final bool isEdited;

  /// Đã bị xóa mềm (Angular: deletedAt != null)
  final bool isDeleted;

  /// Tin nhắn này là ranh giới "đã đọc" cuối cùng
  /// Angular: lastMessageRead == true
  final bool isLastRead;

  /// Tin nhắn đang được highlight (tìm kiếm, nhảy tới)
  final bool isHighlighted;

  // ══════════════════════════════════════════
  // System Event (Angular: type == LOG)
  // ══════════════════════════════════════════

  /// Thông tin system event (khi itemType == systemEvent)
  final SystemEventInfo? systemEvent;

  // ══════════════════════════════════════════
  // Delegate getters sang domain entity
  // ══════════════════════════════════════════

  String get id => message?.id ?? '';
  String get chatId => message?.chatId ?? '';
  String get content => message?.content ?? dateSeparatorText ?? '';
  ContentType get contentType => message?.contentType ?? ContentType.text;
  MessageSender? get sender => message?.sender;
  String get senderId => message?.sender.id ?? '';
  String get senderName => message?.sender.name ?? '';
  String? get senderAvatar => message?.sender.avatar;
  DateTime get createdAt => message?.createdAt ?? DateTime.now();
  MessageStatus get status => message?.status ?? MessageStatus.sent;
  bool get isFromCurrentUser => message?.isFromCurrentUser ?? false;
  bool get hasMedia => message?.hasMedia ?? false;
  List<String> get urls => message?.urls ?? const [];
  String? get fileName => message?.fileName;
  List<MessageAttachment> get attachments => message?.attachments ?? const [];
  List<MessageSender> get mentionTo => message?.mentionTo ?? const [];

  const MessageUIState({
    this.message,
    this.itemType = MessageListItemType.message,
    this.position = BubblePosition.standalone,
    this.showAvatar = false,
    this.showSenderName = false,
    this.showTimestamp = true,
    this.formattedTime = '',
    this.showDateSeparator = false,
    this.dateSeparatorText,
    this.groupedReactions = const [],
    this.replyMessage,
    this.forwardInfo,
    this.hasMention = false,
    this.hasLink = false,
    this.previewLink,
    this.isSending = false,
    this.isFailed = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.isLastRead = false,
    this.isHighlighted = false,
    this.systemEvent,
  });

  /// Factory cho date separator item
  factory MessageUIState.dateSeparator(String text) {
    return MessageUIState(
      itemType: MessageListItemType.dateSeparator,
      dateSeparatorText: text,
    );
  }

  /// Factory cho unread separator
  factory MessageUIState.unreadSeparator() {
    return const MessageUIState(
      itemType: MessageListItemType.unreadSeparator,
      dateSeparatorText: 'Tin nhắn chưa đọc',
    );
  }

  /// Factory cho system event
  factory MessageUIState.systemEvent({
    required ChatMessage message,
    required SystemEventInfo eventInfo,
  }) {
    return MessageUIState(
      message: message,
      itemType: MessageListItemType.systemEvent,
      systemEvent: eventInfo,
    );
  }
}
```

### 1.2. Tạo MessageListTransformer

**File**: `lib/features/chat/presentation/models/message_list_transformer.dart`

```dart
import 'package:intl/intl.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'message_ui_state.dart';

/// Transform danh sách domain entity → danh sách UI state
///
/// Tập trung MỌI logic UI-computed vào đây:
/// - Bubble positioning (khớp Angular firstMessage + stream_chat grouping)
/// - Date separator (khớp Angular format 'dd/MM/yyyy' + compareAsc startOfDay)
/// - Timestamp visibility
/// - Reaction grouping
/// - Reply preview
/// - Mention/link detection
///
/// **Testable độc lập** — không phụ thuộc Flutter framework
class MessageListTransformer {
  /// Ngưỡng thời gian (phút) để tách group tin nhắn
  /// stream_chat: 1 phút (Unit.minute)
  /// Angular: so sánh sender + role (không dùng thời gian)
  /// → Dùng 2 phút là cân bằng hợp lý
  static const int _groupTimeThresholdMinutes = 2;

  /// Regex phát hiện URL trong tin nhắn
  /// Khớp Angular: urlRegex pattern
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Regex phát hiện mention trong tin nhắn
  /// Khớp Angular: mentionRegex = /\[@[0-9a-fA-F]{8}-...\]|\[@all\]/gm
  static final RegExp _mentionRegex = RegExp(
    r'\[@[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\]|@\w+',
  );

  /// Transform danh sách ChatMessage → danh sách MessageUIState
  ///
  /// [messages]: Danh sách domain entity (đã sắp xếp theo createdAt DESC — mới nhất trước)
  /// [currentUserId]: ID người dùng hiện tại
  /// [lastReadMessageId]: ID tin nhắn cuối cùng đã đọc (cho unread separator)
  /// [highlightedMessageId]: ID tin nhắn đang highlight (tìm kiếm)
  /// [isGroupChat]: Có phải group chat không (để hiện tên sender)
  static List<MessageUIState> transform({
    required List<ChatMessage> messages,
    required String currentUserId,
    String? lastReadMessageId,
    String? highlightedMessageId,
    bool isGroupChat = false,
  }) {
    if (messages.isEmpty) return const [];

    final result = <MessageUIState>[];

    for (int i = 0; i < messages.length; i++) {
      final current = messages[i];

      // List reverse (mới nhất trước), nên:
      // - prev = messages[i+1] = tin nhắn CŨ hơn (phía trên màn hình)
      // - next = messages[i-1] = tin nhắn MỚI hơn (phía dưới màn hình)
      final olderMsg = (i + 1 < messages.length) ? messages[i + 1] : null;
      final newerMsg = (i - 1 >= 0) ? messages[i - 1] : null;

      // Xác định tin nhắn system/log
      if (current.contentType == ContentType.event) {
        result.add(MessageUIState.systemEvent(
          message: current,
          eventInfo: _buildSystemEventInfo(current),
        ));
        continue;
      }

      // Tính toán grouping
      final isCurrentUser = current.sender.id == currentUserId;
      final position = _calculatePosition(current, olderMsg, newerMsg);
      final showDateSep = _shouldShowDateSeparator(current, olderMsg);
      final showTimestamp = _shouldShowTimestamp(current, newerMsg, position);

      // Avatar & sender name (khớp Angular logic)
      // Angular: show khi firstMessage == true && role == MEMBER
      // stream_chat: show khi (hasTimeDiff || !isNextUserSame) && !isMyMessage
      final isFirst = position == BubblePosition.first ||
                      position == BubblePosition.standalone;
      final showAvatar = !isCurrentUser && isFirst;
      final showSenderName = !isCurrentUser && isFirst && isGroupChat;

      // Reactions grouping
      final groupedReactions = _groupReactions(
        current.reactions,
        currentUserId,
      );

      // Reply preview
      final replyPreview = _buildReplyPreview(current);

      // Forward info
      final forwardInfo = current.forwardedFromMessageId != null
          ? ForwardMessageInfo(
              originalMessageId: current.forwardedFromMessageId!,
            )
          : null;

      // Content analysis
      final hasLink = _urlRegex.hasMatch(current.content);
      final hasMention = current.mentionTo.isNotEmpty ||
                          _mentionRegex.hasMatch(current.content);
      final previewLink = hasLink
          ? _urlRegex.allMatches(current.content).last.group(0)
          : null;

      // Status
      final isSending = current.id.startsWith('draft_') ||
                         current.status == MessageStatus.pending ||
                         current.status == MessageStatus.sending;
      final isFailed = current.status == MessageStatus.failed;

      result.add(MessageUIState(
        message: current,
        itemType: MessageListItemType.message,
        position: position,
        showAvatar: showAvatar,
        showSenderName: showSenderName,
        showTimestamp: showTimestamp,
        formattedTime: _formatTime(current.createdAt),
        showDateSeparator: showDateSep,
        dateSeparatorText: showDateSep ? _formatDateSeparator(current.createdAt) : null,
        groupedReactions: groupedReactions,
        replyMessage: replyPreview,
        forwardInfo: forwardInfo,
        hasMention: hasMention,
        hasLink: hasLink,
        previewLink: previewLink,
        isSending: isSending,
        isFailed: isFailed,
        isEdited: current.editedAt != null,
        isDeleted: current.deletedAt != null,
        isLastRead: current.id == lastReadMessageId,
        isHighlighted: current.id == highlightedMessageId,
      ));
    }

    return result;
  }

  /// Tính vị trí bubble trong group
  ///
  /// Logic kết hợp:
  /// - Angular: so sánh senderId + role + type (LOG breaks group)
  /// - stream_chat: so sánh user.id + Jiffy.isSame(Unit.minute)
  ///
  /// Group bị phá khi:
  /// 1. Khác senderId
  /// 2. Khoảng cách thời gian > _groupTimeThresholdMinutes
  /// 3. Tin nhắn system/event xen giữa
  /// 4. Khác ngày (date separator)
  static BubblePosition _calculatePosition(
    ChatMessage current,
    ChatMessage? older,  // tin nhắn phía trên (cũ hơn)
    ChatMessage? newer,  // tin nhắn phía dưới (mới hơn)
  ) {
    final groupedWithOlder = _isInSameGroup(current, older);
    final groupedWithNewer = _isInSameGroup(current, newer);

    if (groupedWithOlder && groupedWithNewer) return BubblePosition.middle;
    if (groupedWithOlder && !groupedWithNewer) return BubblePosition.last;
    if (!groupedWithOlder && groupedWithNewer) return BubblePosition.first;
    return BubblePosition.standalone;
  }

  /// Kiểm tra 2 tin nhắn có cùng group không
  static bool _isInSameGroup(ChatMessage current, ChatMessage? other) {
    if (other == null) return false;

    // Khác sender → không cùng group
    if (current.sender.id != other.sender.id) return false;

    // System event phá group
    if (current.contentType == ContentType.event ||
        other.contentType == ContentType.event) return false;

    // Khoảng cách thời gian > ngưỡng → không cùng group
    final timeDiff = current.createdAt.difference(other.createdAt).abs();
    if (timeDiff.inMinutes >= _groupTimeThresholdMinutes) return false;

    // Khác ngày → không cùng group
    if (!_isSameDay(current.createdAt, other.createdAt)) return false;

    return true;
  }

  /// Có nên hiện date separator phía trên tin nhắn này không
  ///
  /// Khớp Angular: compareAsc(startOfDay(lastMessageDate), startOfDay(currentDate)) !== 0
  /// Khớp stream_chat: !createdAt.isSame(nextCreatedAt, unit: Unit.day)
  static bool _shouldShowDateSeparator(ChatMessage current, ChatMessage? older) {
    if (older == null) return true; // Tin nhắn đầu tiên luôn có date separator
    return !_isSameDay(current.createdAt, older.createdAt);
  }

  /// Có nên hiện timestamp không
  ///
  /// stream_chat: showTimeStamp = hasTimeDiff || !isNextUserSame
  /// Angular: luôn hiện timestamp
  /// → Hiện khi: last/standalone trong group HOẶC khoảng cách > 5 phút
  static bool _shouldShowTimestamp(
    ChatMessage current,
    ChatMessage? newer,
    BubblePosition position,
  ) {
    // Luôn hiện cho tin nhắn cuối group hoặc standalone
    if (position == BubblePosition.last ||
        position == BubblePosition.standalone) return true;

    // Hiện nếu khoảng cách với tin nhắn mới hơn > 5 phút
    if (newer != null) {
      final diff = newer.createdAt.difference(current.createdAt).abs();
      if (diff.inMinutes >= 5) return true;
    }

    return false;
  }

  /// Format thời gian cho timestamp
  /// Angular: format(date, 'h:mm a') → "2:30 PM"
  static String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format text cho date separator
  /// Angular: format(date, 'dd/MM/yyyy')
  /// Nâng cấp: "Hôm nay", "Hôm qua", "dd/MM/yyyy"
  static String _formatDateSeparator(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    if (diff < 7) return DateFormat('EEEE', 'vi').format(dateTime); // Thứ Hai, Thứ Ba...
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// So sánh 2 DateTime có cùng ngày không
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Gom reactions theo emoji code
  ///
  /// Input: List<MessageReaction> (domain) — mỗi item = 1 user react 1 emoji
  /// Output: List<ReactionGroup> — gom theo code, đếm users
  ///
  /// Khớp Angular: OfficeChatMessageReaction { code, reactorIds[], reactors[] }
  /// Khớp stream_chat: reactionsMap grouped by type, own reaction prioritized
  static List<ReactionGroup> _groupReactions(
    List<MessageReaction> reactions,
    String currentUserId,
  ) {
    if (reactions.isEmpty) return const [];

    final Map<String, List<String>> groupMap = {};
    for (final r in reactions) {
      groupMap.putIfAbsent(r.code, () => []).add(r.userId);
    }

    return groupMap.entries.map((entry) {
      return ReactionGroup(
        code: entry.key,
        reactorIds: entry.value,
        isReactedByCurrentUser: entry.value.contains(currentUserId),
      );
    }).toList()
      // Sắp xếp: nhiều reaction nhất trước, own reaction sau (khớp stream_chat)
      ..sort((a, b) {
        if (a.isReactedByCurrentUser && !b.isReactedByCurrentUser) return -1;
        if (!a.isReactedByCurrentUser && b.isReactedByCurrentUser) return 1;
        return b.count.compareTo(a.count);
      });
  }

  /// Build reply preview từ domain entity
  ///
  /// NOTE: Hiện tại ChatMessage chưa có trường replyMessageId/replyMessage
  /// Cần bổ sung ở Phase 1.3 (cập nhật Domain Entity)
  static ReplyMessagePreview? _buildReplyPreview(ChatMessage message) {
    // TODO: Implement khi domain entity có replyMessage
    // Cần: message.replyMessage (ChatMessage?) hoặc message.replyMessageId (String?)
    return null;
  }

  /// Build system event info
  ///
  /// Khớp Angular: generateActionText(message)
  /// Handles: ADD_MEMBER, CHANGE_NAME, REMOVE_MEMBER, LEAVE_CONVERSATION, etc.
  static SystemEventInfo _buildSystemEventInfo(ChatMessage message) {
    // TODO: Parse từ message.content hoặc metadata khi backend cung cấp actionType
    return SystemEventInfo(
      actionType: 'UNKNOWN',
      formattedText: message.content,
    );
  }
}
```

### 1.3. Cập Nhật Domain Entity — Thêm Trường Thiếu

**File cần sửa**: `lib/shared/domain/entities/chat_message.dart`

Thêm các trường mà Angular frontend có nhưng Flutter đang thiếu:

```dart
// THÊM VÀO ChatMessage class:

/// ID tin nhắn được reply (Angular: replyMessageId)
final String? replyMessageId;

/// Tin nhắn được reply (Angular: replyMessage — nested object)
final ChatMessage? replyMessage;

/// Loại action cho system event (Angular: actionType — ConversationActionType)
final String? actionType;

/// Người thực hiện action (Angular: actor)
final MessageSender? actor;

/// Danh sách user bị tác động (Angular: targetUsers)
final List<MessageSender> targetUsers;

/// Giá trị mới (Angular: newValue — dùng cho CHANGE_NAME, CHANGE_AVATAR)
final String? newValue;

/// Giá trị cũ (Angular: oldValue)
final String? oldValue;
```

**Thêm vào constructor:**
```dart
this.replyMessageId,
this.replyMessage,
this.actionType,
this.actor,
this.targetUsers = const [],
this.newValue,
this.oldValue,
```

### 1.4. Cập Nhật DTO — Thêm Trường Thiếu

**File cần sửa**: `lib/data/dtos/message_dto.dart`

MessageDto hiện tại đã có `replyMessageId` và `replyMessage` (ReplyMessageDto).

Cần thêm cho system events:

```dart
// THÊM VÀO MessageDto:
String? actionType,
SenderDto? actor,
String? actorId,
@Default([]) List<String> targetUserIds,
@Default([]) List<SenderDto> targetUsers,
String? newValue,
String? oldValue,
```

Cập nhật `MessageDtoMapper.toDomain()` để map các trường mới:
```dart
// THÊM vào toDomain():
replyMessageId: replyMessageId,
replyMessage: replyMessage != null ? _mapReplyMessage(replyMessage!) : null,
actionType: actionType,
actor: actor != null ? MessageSender(id: actor!.id, name: actor!.fullName, ...) : null,
targetUsers: targetUsers.map((s) => MessageSender(id: s.id, name: s.fullName, ...)).toList(),
newValue: newValue,
oldValue: oldValue,
```

### 1.5. Tích Hợp Vào MessageBloc

**File cần sửa**: `lib/presentation/blocs/message/message_state.dart`

```dart
// CẬP NHẬT MessagesLoaded state:
class MessagesLoaded extends MessageState {
  final String chatId;
  final List<ChatMessage> messages;       // GIỮ NGUYÊN — domain entities
  final List<MessageUIState> uiMessages;  // THÊM MỚI — transformed UI state
  final bool hasReachedMax;

  const MessagesLoaded({
    required this.chatId,
    required this.messages,
    required this.uiMessages,
    this.hasReachedMax = false,
  });
}
```

**File cần sửa**: `lib/presentation/blocs/message/message_bloc.dart`

```dart
// THÊM transform call sau mỗi lần emit MessagesLoaded:

// Trong _onLoadMessages, _onLoadMoreMessages, _onReceiveRealTimeMessage, etc.:
final uiMessages = MessageListTransformer.transform(
  messages: allMessages,
  currentUserId: _getCurrentUserId(),  // Lấy từ AuthBloc hoặc inject
  lastReadMessageId: lastReadId,
  isGroupChat: chatType == ChatType.group,
);

emit(MessagesLoaded(
  chatId: chatId,
  messages: allMessages,
  uiMessages: uiMessages,
  hasReachedMax: hasReachedMax,
));
```

### 1.6. Cập Nhật Widget — MessageItem Nhận MessageUIState

**File cần sửa**: `lib/features/chat/presentation/widgets/chat/message_item.dart`

```dart
// ĐỔI parameter:
class MessageItem extends StatefulWidget {
  // CŨ: final ChatMessage message;
  final MessageUIState uiState;  // MỚI

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  // XÓA: isLastInGroup, showSenderInfo, highlightMessage
  // → Đã có trong uiState.position, uiState.showSenderName, uiState.isHighlighted
}

// THAY THẾ các chỗ dùng widget.message bằng widget.uiState:
// widget.message.content       → widget.uiState.content
// widget.message.isFromCurrentUser → widget.uiState.isFromCurrentUser
// widget.isLastInGroup         → widget.uiState.position == BubblePosition.last
// widget.showSenderInfo        → widget.uiState.showSenderName
// widget.highlightMessage      → widget.uiState.isHighlighted
```

### 1.7. Cập Nhật ChatDetailsPage

**File cần sửa**: `lib/features/chat/presentation/pages/chat/chat_details_page.dart`

```dart
// THAY THẾ trong builder:
// CŨ:
// AppListView<ChatMessage>(
//   items: messages,
//   itemBuilder: (context, message, index) {
//     return MessageItem(message: message, ...);
//   },

// MỚI:
AppListView<MessageUIState>(
  items: state.uiMessages,
  itemBuilder: (context, uiState, index) {
    // Handle các loại item khác nhau
    switch (uiState.itemType) {
      case MessageListItemType.dateSeparator:
        return _buildDateSeparator(uiState.dateSeparatorText!);
      case MessageListItemType.systemEvent:
        return _buildSystemEvent(uiState);
      case MessageListItemType.unreadSeparator:
        return _buildUnreadSeparator();
      case MessageListItemType.message:
        return MessageItem(
          uiState: uiState,
          onLongPress: () {
            _showMessageOptions(context, uiState.message!, uiState.isFromCurrentUser);
          },
        );
    }
  },
);
```

---

## PHASE 2 — Message Grouping & Timestamps

### 2.1. Bubble Border Radius Theo Position

**Logic tham khảo stream_chat_flutter** (`message_list_view.dart:1369-1388`):

```dart
/// Border radius thay đổi theo vị trí trong group
///
/// stream_chat logic:
/// - bottomLeft cho OTHER messages: sharp (0) khi first/middle, round (16) khi last
/// - bottomRight cho OWN messages: sharp (0) khi first/middle, round (16) khi last
///
/// Angular: không có logic này (CSS đơn giản)
/// → Dùng logic stream_chat cho UI đẹp hơn
BorderRadius getBubbleBorderRadius(BubblePosition position, bool isMe) {
  const fullRadius = Radius.circular(16.0);
  const tightRadius = Radius.circular(4.0);

  switch (position) {
    case BubblePosition.standalone:
      return BorderRadius.all(fullRadius);

    case BubblePosition.first:
      return BorderRadius.only(
        topLeft: fullRadius,
        topRight: fullRadius,
        bottomLeft: isMe ? fullRadius : tightRadius,
        bottomRight: isMe ? tightRadius : fullRadius,
      );

    case BubblePosition.middle:
      return BorderRadius.only(
        topLeft: isMe ? fullRadius : tightRadius,
        topRight: isMe ? tightRadius : fullRadius,
        bottomLeft: isMe ? fullRadius : tightRadius,
        bottomRight: isMe ? tightRadius : fullRadius,
      );

    case BubblePosition.last:
      return BorderRadius.only(
        topLeft: isMe ? fullRadius : tightRadius,
        topRight: isMe ? tightRadius : fullRadius,
        bottomLeft: fullRadius,
        bottomRight: fullRadius,
      );
  }
}
```

### 2.2. Spacing Giữa Các Tin Nhắn

```dart
/// Margin thay đổi theo position
/// stream_chat: spacing builder enum (thread, timeDiff, otherUser, deleted, default)
EdgeInsets getMessageSpacing(BubblePosition position, bool showDateSeparator) {
  return EdgeInsets.only(
    left: 8.0,
    right: 8.0,
    // Khoảng cách lớn hơn cho first/standalone (bắt đầu group mới)
    top: showDateSeparator ? 16.0
        : (position == BubblePosition.first || position == BubblePosition.standalone)
            ? 8.0
            : 2.0,
    // Khoảng cách lớn hơn cho last/standalone (kết thúc group)
    bottom: (position == BubblePosition.last || position == BubblePosition.standalone)
        ? 8.0
        : 2.0,
  );
}
```

### 2.3. Date Separator Widget

```dart
/// Widget hiển thị date separator
/// Khớp Angular: <p class="text-gray-500 font-semibold">{{ item.message }}</p>
Widget buildDateSeparator(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}
```

### 2.4. Avatar Display Logic

```dart
/// Avatar visibility — khớp cả Angular + stream_chat
///
/// Angular: show khi firstMessage && role == MEMBER
/// stream_chat:
///   - isMyMessage → DisplayWidget.gone (không hiện, không chiếm chỗ)
///   - (hasTimeDiff || !isNextUserSame) → DisplayWidget.show
///   - else → DisplayWidget.hide (ẩn nhưng chiếm chỗ = giữ alignment)
///
/// Implementation:
/// - OWN message: không render avatar widget (gone)
/// - OTHER message + showAvatar=true: render avatar
/// - OTHER message + showAvatar=false: render SizedBox(width: 36) giữ alignment
```

---

## PHASE 3 — Tính Năng Còn Thiếu

### 3.1. Reactions UI

**Tham khảo**: stream_chat `reaction_bubble.dart` (336 LOC) + `reaction_indicator.dart`

**File mới**: `lib/features/chat/presentation/widgets/chat/reaction_bar.dart`

Hiển thị reactions gom nhóm dưới bubble:
```
┌─────────────────────────────┐
│  Message content here       │
└─────────────────────────────┘
  👍 3   ❤️ 2   😂 1           ← ReactionBar
```

Logic:
- Dùng `MessageUIState.groupedReactions` (đã gom sẵn)
- Highlight emoji mà currentUser đã react (`isReactedByCurrentUser`)
- Tap emoji → toggle add/revoke reaction (gọi API)
- Long press → hiện modal danh sách reactors
- Khớp Angular: `countReactions()`, `getUniqueReactors()`
- Khớp stream_chat: `reactionsMap` grouped by type, own reaction border

**WebSocket event cần handle**:
```
// Từ Angular codebase:
// this.websocketService.on('message:reaction', callback)
// Payload: { messageId, code, act: 'ADD' | 'REVOKE', userId }
```

### 3.2. Reply/Quote UI

**File mới**: `lib/features/chat/presentation/widgets/chat/reply_preview.dart`

Hiển thị reply preview phía trên bubble:
```
  ┌─ Reply ────────────────────┐
  │ 👤 An: Nội dung tin gốc... │
  └────────────────────────────┘
  ┌─────────────────────────────┐
  │  Tin nhắn reply             │
  └─────────────────────────────┘
```

Logic:
- Dùng `MessageUIState.replyMessage` (ReplyMessagePreview)
- Render preview theo contentType:
  - TEXT: hiện text (truncate 2 dòng)
  - IMAGE: hiện thumbnail nhỏ + "[Hình ảnh]"
  - VIDEO: hiện thumbnail + "[Video]"
  - DOC: hiện icon + fileName
  - AUDIO/VOICE_NOTE: hiện icon + "[Ghi âm]"
- Tap reply preview → scroll đến tin nhắn gốc
- Khớp Angular: `replyMessage.sender?.fullname`, switch trên `replyMessage.type`

**Swipe-to-reply gesture**:
- Swipe phải (cho OTHER message) hoặc swipe trái (cho OWN message)
- Set `replyingToMessage` state trong BLoC
- Hiện reply bar phía trên input field

### 3.3. Media Gallery

**File mới**: `lib/features/chat/presentation/widgets/chat/media_gallery.dart`

Logic:
- Nhóm attachments theo type (image grid, video list, file list)
- Image grid: 1 ảnh = full width, 2 ảnh = 2 cột, 3+ ảnh = grid 2x2 với counter
- Tap ảnh → fullscreen gallery (PageView swipe)
- Tham khảo stream_chat gallery_attachment patterns
- Khớp Angular: `urls[]` array rendering per `ChatMessageType`

### 3.4. Emoji Picker

**Package đề xuất**: `emoji_picker_flutter` (pub.dev)

Logic:
- Nút emoji bên cạnh input field → toggle emoji picker overlay
- Insert emoji vào TextEditingController tại cursor position
- Recent emojis tab
- Cho reactions: long press reaction bar → show picker → call API

### 3.5. File Picker & Upload

**Package hiện có**: `image_picker` (đã có trong pubspec.yaml)

Logic attachment flow:
- Nút "+" bên cạnh input → bottom sheet chọn loại:
  - Camera (image_picker: ImageSource.camera)
  - Gallery (image_picker: ImageSource.gallery)
  - File (file_picker package — cần thêm)
  - Location (geolocator — cần thêm)
- Upload flow: chọn file → compress → upload API → nhận URL → gửi message với URLs
- Progress indicator trong bubble khi đang upload

---

## PHASE 4 — Hoàn Thiện

### 4.1. Gộp Bubble Implementations

**Vấn đề hiện tại**: 2 widget trùng lặp
- `MessageItem` (599 LOC) — sử dụng trong `chat_details_page.dart`
- `ChatBubble` (498 LOC) — không rõ dùng ở đâu

**Quyết định**: GIỮ `MessageItem`, XÓA `ChatBubble`

**Lý do**:
- `MessageItem` đã có: mention parsing, media preview, avatar, status indicator
- `ChatBubble` là widget generic hơn nhưng thiếu nhiều feature
- `MessageItem` nhận `MessageUIState` (sau Phase 1)

**Bước thực hiện**:
1. Tìm tất cả reference đến `ChatBubble` → replace bằng `MessageItem`
2. Port các feature unique của `ChatBubble` (nếu có) sang `MessageItem`:
   - `_getBubbleRadius()` position-based → đã có trong Phase 2
   - `_getBubbleColor()` dark mode → port sang `MessageItem`
   - Audio/sticker/contact renders → port sang `MessageItem._buildAttachmentPreviews`
3. Xóa file `chat_bubble.dart`
4. Xóa enum `ChatMessageType` trong chat_bubble.dart (trùng với domain `ContentType`)

### 4.2. Dọn Mapper Trùng Lặp

**Vấn đề hiện tại**: 2 hệ thống mapping song song
- Extension methods trên DTO: `MessageDtoMapper.toDomain()` (trong `message_dto.dart`)
- Static class: `MessageMapper.toEntity()`, `MessageMapper.toModel()` (trong `message_mapper.dart`)

**Quyết định**: GIỮ Extension methods, XÓA static mapper class

**Lý do**:
- Extension methods tự nhiên hơn trong Dart (`dto.toDomain()`)
- Không cần import class riêng
- Dễ discover trong IDE (auto-complete trên DTO object)

**Bước thực hiện**:
1. Tìm tất cả call sites của `MessageMapper.toEntity()`, `ChatMapper.toModel()`, etc.
2. Replace bằng extension method tương ứng
3. Move các conversion logic unique từ static class vào extension (nếu có)
4. Xóa `message_mapper.dart` và `chat_mapper.dart` static classes
5. Giữ DTO → Model conversion trong extension nếu cần (`dto.toModel()`)

### 4.3. Typing Indicator

**Khớp Angular**: WebSocket event `message:typing`

```dart
// WebSocket event:
// Emit: { conversationId: chatId }
// Listen: { conversationId, fullName, userId }

// UI: Hiện "An đang soạn tin nhắn..." phía dưới danh sách tin nhắn
// Angular: senderTyping signal → hiện text
```

**File mới**: `lib/features/chat/presentation/widgets/chat/typing_indicator.dart`

### 4.4. Read Receipt

**Khớp Angular**: `readerIds[]`, `lastMessageRead`, `lastMessageReadId`

```dart
// Hiện trạng thái đã đọc:
// - ✓ (sent) — message đã gửi
// - ✓✓ (delivered) — đã nhận
// - ✓✓ xanh (read) — đã đọc
//
// Angular: readAt marks, đếm readers
// stream_chat: icon done_all với color
//
// Cần: gọi API mark as read khi message visible (visibility_detector)
```

### 4.5. Presence (Online/Offline)

**Khớp Angular**: WebSocket event connection tracking

```dart
// WebSocket events:
// - user:online → cập nhật status
// - user:offline → cập nhật status
//
// UI: Dot xanh/xám bên cạnh avatar
// Text: "Online" / "Offline 5 phút trước"
```

---

## Thứ Tự File Cần Tạo/Sửa

### File MỚI tạo:
| # | File | Phase | Mô tả |
|---|------|-------|--------|
| 1 | `lib/features/chat/presentation/models/message_ui_state.dart` | 1.1 | UI State classes |
| 2 | `lib/features/chat/presentation/models/message_list_transformer.dart` | 1.2 | Transform logic |
| 3 | `lib/features/chat/presentation/widgets/chat/reaction_bar.dart` | 3.1 | Reaction display |
| 4 | `lib/features/chat/presentation/widgets/chat/reply_preview.dart` | 3.2 | Reply/quote preview |
| 5 | `lib/features/chat/presentation/widgets/chat/media_gallery.dart` | 3.3 | Image/video gallery |
| 6 | `lib/features/chat/presentation/widgets/chat/typing_indicator.dart` | 4.3 | Typing animation |
| 7 | `test/features/chat/presentation/models/message_list_transformer_test.dart` | 1.2 | Unit tests |

### File CẦN SỬA:
| # | File | Phase | Thay đổi |
|---|------|-------|----------|
| 1 | `lib/shared/domain/entities/chat_message.dart` | 1.3 | Thêm replyMessageId, replyMessage, actionType, actor, targetUsers, newValue, oldValue |
| 2 | `lib/data/dtos/message_dto.dart` | 1.4 | Thêm actionType, actor, actorId, targetUserIds, targetUsers, newValue, oldValue; Cập nhật toDomain() |
| 3 | `lib/presentation/blocs/message/message_state.dart` | 1.5 | Thêm uiMessages vào MessagesLoaded |
| 4 | `lib/presentation/blocs/message/message_bloc.dart` | 1.5 | Gọi MessageListTransformer.transform() sau mỗi emit |
| 5 | `lib/features/chat/presentation/widgets/chat/message_item.dart` | 1.6 | Đổi param từ ChatMessage → MessageUIState; thêm position-based border radius |
| 6 | `lib/features/chat/presentation/pages/chat/chat_details_page.dart` | 1.7 | Dùng uiMessages, handle item types, fix placeholder userId |
| 7 | `lib/data/dtos/message_dto.freezed.dart` | 1.4 | Regenerate (build_runner) |
| 8 | `lib/data/dtos/message_dto.g.dart` | 1.4 | Regenerate (build_runner) |

### File CẦN XÓA:
| # | File | Phase | Lý do |
|---|------|-------|-------|
| 1 | `lib/features/chat/presentation/widgets/chat/chat_bubble.dart` | 4.1 | Trùng lặp với MessageItem |
| 2 | `lib/data/mappers/message_mapper.dart` | 4.2 | Trùng lặp với extension methods |
| 3 | `lib/data/mappers/chat_mapper.dart` | 4.2 | Trùng lặp với extension methods |

---

## Dependency & Build Commands

### Packages cần thêm (pubspec.yaml):
```yaml
# Phase 3 — Emoji Picker
emoji_picker_flutter: ^3.1.0

# Phase 3 — File Picker (nếu chưa có)
file_picker: ^9.0.0
```

### Build commands sau khi sửa Freezed DTOs:
```bash
cd flutter_chat_app
dart run build_runner build --delete-conflicting-outputs
```

---

## Testing Strategy

### Unit Tests (MessageListTransformer):
```dart
// test/features/chat/presentation/models/message_list_transformer_test.dart

group('BubblePosition', () {
  test('standalone - single message from user', ...);
  test('first - start of consecutive group', ...);
  test('middle - between same-sender messages', ...);
  test('last - end of consecutive group', ...);
  test('breaks group when sender changes', ...);
  test('breaks group when time gap > 2 minutes', ...);
  test('breaks group on day boundary', ...);
  test('breaks group on system event', ...);
});

group('DateSeparator', () {
  test('shows for first message', ...);
  test('shows when day changes', ...);
  test('formats "Hôm nay" for today', ...);
  test('formats "Hôm qua" for yesterday', ...);
  test('formats "dd/MM/yyyy" for older dates', ...);
});

group('ReactionGrouping', () {
  test('groups by emoji code', ...);
  test('marks currentUser reactions', ...);
  test('sorts by count and own reaction', ...);
  test('empty for no reactions', ...);
});

group('Timestamp', () {
  test('shows for last/standalone positions', ...);
  test('shows for time gap > 5 minutes', ...);
  test('hides for middle positions within threshold', ...);
});

group('Avatar & SenderName', () {
  test('hides for own messages', ...);
  test('shows for first/standalone of other user', ...);
  test('hides sender name in direct chat', ...);
  test('shows sender name in group chat', ...);
});
```

### Widget Tests:
- MessageItem renders correctly with each BubblePosition
- Date separator widget appearance
- Reaction bar display and interaction
- Reply preview display

---

## Rủi Ro & Giải Pháp

| Rủi ro | Mức độ | Giải pháp |
|--------|--------|-----------|
| Freezed codegen fail sau thêm trường DTO | TRUNG BÌNH | Chạy build_runner, fix nếu conflict |
| Performance khi transform list lớn (1000+ messages) | THẤP | Transform chỉ chạy khi state change, cached trong BLoC |
| Breaking change MessageItem API | TRUNG BÌNH | Tìm tất cả call sites trước, update cùng lúc |
| Backend chưa gửi actionType cho LOG messages | THẤP | Fallback: parse từ message content |
| Reaction WebSocket event chưa implement | TRUNG BÌNH | Phase 3, có thể mock trước |
