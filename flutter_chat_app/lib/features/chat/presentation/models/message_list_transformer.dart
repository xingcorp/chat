import 'package:intl/intl.dart';
import 'package:flutter_chat_app/core/localization/l10n_helper.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';

/// Transform danh sách domain entity → danh sách UI state
///
/// Tập trung MỌI logic UI-computed vào đây:
/// - Bubble positioning (khớp Angular firstMessage + stream_chat grouping)
/// - Date separator (khớp Angular format 'dd/MM/yyyy' + compareAsc startOfDay)
/// - Timestamp visibility
/// - Reaction grouping
/// - Reply preview
/// - System event formatting
/// - Mention/link detection
///
/// **Testable độc lập** — không phụ thuộc Flutter framework.
///
/// Pattern tham khảo:
/// - Angular: firstMessage, role (OWNER/MEMBER), generateActionText()
/// - stream_chat_flutter: message_list_view.dart grouping algorithm
/// - Signal: ConversationMessage UI wrapper
class MessageListTransformer {
  // ══════════════════════════════════════════
  // Constants
  // ══════════════════════════════════════════

  /// Ngưỡng thời gian (phút) để tách group tin nhắn
  ///
  /// stream_chat: 1 phút (Unit.minute)
  /// Angular: so sánh sender + role (không dùng thời gian)
  /// → 2 phút là cân bằng hợp lý
  static const int _groupTimeThresholdMinutes = 2;

  /// Ngưỡng thời gian (phút) để hiện timestamp giữa các tin nhắn cùng group
  static const int _timestampGapMinutes = 5;

  /// Regex phát hiện URL trong tin nhắn
  /// Khớp Angular: urlRegex pattern
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Regex phát hiện mention trong tin nhắn
  /// Khớp Angular: mentionRegex = /\[@[0-9a-fA-F]{8}-...\]|\[@all\]/gm
  static final RegExp _mentionRegex = RegExp(
    r'\[@[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\]|@all',
  );

  // ══════════════════════════════════════════
  // Main Transform
  // ══════════════════════════════════════════

  /// Transform danh sách ChatMessage → danh sách MessageUIState
  ///
  /// [messages] Danh sách domain entity (đã sắp xếp theo createdAt DESC — mới nhất trước)
  /// [currentUserId] ID người dùng hiện tại (từ AuthBloc)
  /// [lastReadMessageId] ID tin nhắn cuối cùng đã đọc (cho unread separator)
  /// [highlightedMessageId] ID tin nhắn đang highlight (tìm kiếm, nhảy tới)
  /// [isGroupChat] Có phải group chat không (để quyết định hiện tên sender)
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
      // - olderMsg = messages[i+1] = tin nhắn CŨ hơn (phía trên màn hình)
      // - newerMsg = messages[i-1] = tin nhắn MỚI hơn (phía dưới màn hình)
      final olderMsg = (i + 1 < messages.length) ? messages[i + 1] : null;
      final newerMsg = (i - 1 >= 0) ? messages[i - 1] : null;

      // ── System/Log event ──
      if (current.contentType == ContentType.event) {
        result.add(MessageUIState.systemEvent(
          message: current,
          eventInfo: _buildSystemEventInfo(current),
        ));
        continue;
      }

      // ── Bubble grouping ──
      final isCurrentUser = current.sender.id == currentUserId;
      final position = _calculatePosition(current, olderMsg, newerMsg);
      final showDateSep = _shouldShowDateSeparator(current, olderMsg);
      final showTimestamp = _shouldShowTimestamp(current, newerMsg, position);

      // ── Avatar & sender name ──
      // Angular: show khi firstMessage == true && role == MEMBER
      // stream_chat: show khi (hasTimeDiff || !isNextUserSame) && !isMyMessage
      final isFirst = position == BubblePosition.first ||
          position == BubblePosition.standalone;
      final showAvatar = !isCurrentUser && isFirst;
      final showSenderName = !isCurrentUser && isFirst && isGroupChat;

      // ── Reactions grouping ──
      final groupedReactions = _groupReactions(
        current.reactions,
        currentUserId,
      );

      // ── Reply preview ──
      final replyPreview = _buildReplyPreview(current);

      // ── Forward info ──
      final forwardInfo = current.forwardedFromMessageId != null
          ? ForwardMessageInfo(
              originalMessageId: current.forwardedFromMessageId!,
            )
          : null;

      // ── Content analysis ──
      final contentText = current.content;
      final hasLink = _urlRegex.hasMatch(contentText);
      final hasMention = current.mentionTo.isNotEmpty ||
          _mentionRegex.hasMatch(contentText);
      final previewLink = hasLink
          ? _urlRegex.allMatches(contentText).last.group(0)
          : null;

      // ── Message status ──
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
        dateSeparatorText:
            showDateSep ? _formatDateSeparator(current.createdAt) : null,
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

  // ══════════════════════════════════════════
  // Bubble Positioning
  // ══════════════════════════════════════════

  /// Tính vị trí bubble trong group
  ///
  /// Logic kết hợp Angular + stream_chat:
  /// - Angular: so sánh senderId + role + type (LOG breaks group)
  /// - stream_chat: so sánh user.id + Jiffy.isSame(Unit.minute)
  ///
  /// Group bị phá khi:
  /// 1. Khác senderId
  /// 2. Khoảng cách thời gian > [_groupTimeThresholdMinutes]
  /// 3. Tin nhắn system/event xen giữa
  /// 4. Khác ngày (date separator)
  static BubblePosition _calculatePosition(
    ChatMessage current,
    ChatMessage? older, // tin nhắn phía trên (cũ hơn)
    ChatMessage? newer, // tin nhắn phía dưới (mới hơn)
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

  // ══════════════════════════════════════════
  // Date Separator & Timestamp
  // ══════════════════════════════════════════

  /// Có nên hiện date separator phía trên tin nhắn này không
  ///
  /// Khớp Angular: compareAsc(startOfDay(lastMessageDate), startOfDay(currentDate)) !== 0
  /// Khớp stream_chat: !createdAt.isSame(nextCreatedAt, unit: Unit.day)
  static bool _shouldShowDateSeparator(
    ChatMessage current,
    ChatMessage? older,
  ) {
    // Tin nhắn đầu tiên (cũ nhất trong list) luôn có date separator
    if (older == null) return true;
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
        position == BubblePosition.standalone) {
      return true;
    }

    // Hiện nếu khoảng cách với tin nhắn mới hơn > 5 phút
    if (newer != null) {
      final diff = newer.createdAt.difference(current.createdAt).abs();
      if (diff.inMinutes >= _timestampGapMinutes) return true;
    }

    return false;
  }

  /// Format thời gian cho timestamp
  ///
  /// Angular: format(date, 'h:mm a') → "2:30 PM"
  /// Flutter: dùng 24h format phổ biến ở VN → "14:30"
  static String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format text cho date separator
  ///
  /// Angular: format(date, 'dd/MM/yyyy')
  /// Nâng cấp UX: "Hôm nay", "Hôm qua", tên thứ (< 7 ngày), "dd/MM/yyyy"
  static String _formatDateSeparator(DateTime dateTime) {
    final l10n = L10nHelper.current;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    if (diff < 7) return DateFormat('EEEE', l10n.localeName).format(dateTime);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// So sánh 2 DateTime có cùng ngày không
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ══════════════════════════════════════════
  // Reaction Grouping
  // ══════════════════════════════════════════

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
      // Sắp xếp: own reaction trước, sau đó nhiều nhất trước
      ..sort((a, b) {
        if (a.isReactedByCurrentUser && !b.isReactedByCurrentUser) return -1;
        if (!a.isReactedByCurrentUser && b.isReactedByCurrentUser) return 1;
        return b.count.compareTo(a.count);
      });
  }

  // ══════════════════════════════════════════
  // Reply Preview
  // ══════════════════════════════════════════

  /// Build reply preview từ domain entity
  ///
  /// Khớp Angular: replyMessage { sender.fullname, type, message, urls, fileName }
  static ReplyMessagePreview? _buildReplyPreview(ChatMessage message) {
    final reply = message.replyMessage;
    if (reply == null) return null;

    // Preview text theo content type
    final previewText = _getReplyPreviewText(reply);

    // Preview URL (cho IMAGE/VIDEO)
    String? previewUrl;
    if (reply.urls.isNotEmpty &&
        (reply.contentType == ContentType.image ||
            reply.contentType == ContentType.video)) {
      previewUrl = reply.urls.first;
    }

    return ReplyMessagePreview(
      id: reply.id,
      senderName: reply.sender.name,
      senderAvatar: reply.sender.avatar,
      contentType: reply.contentType,
      previewText: previewText,
      previewUrl: previewUrl,
    );
  }

  /// Tạo preview text cho reply message theo content type
  ///
  /// Khớp Angular: renderReplyMessage() switch case
  static String _getReplyPreviewText(ChatMessage reply) {
    final l10n = L10nHelper.current;
    switch (reply.contentType) {
      case ContentType.image:
        return l10n.replyPreviewImage;
      case ContentType.video:
        return l10n.replyPreviewVideo;
      case ContentType.audio:
        return l10n.replyPreviewAudio;
      case ContentType.file:
        return l10n.replyPreviewFile(reply.fileName ?? '');
      case ContentType.location:
        return l10n.replyPreviewLocation;
      case ContentType.link:
        return reply.content.isNotEmpty ? reply.content : l10n.replyPreviewLink;
      case ContentType.event:
        return l10n.replyPreviewSystemEvent;
      case ContentType.text:
        return reply.content;
    }
  }

  // ══════════════════════════════════════════
  // System Event
  // ══════════════════════════════════════════

  /// Build system event info từ domain entity
  ///
  /// Khớp Angular: generateActionText(message) trong conversation.component.ts
  /// Handles: ADD_MEMBER, REMOVE_MEMBER, LEAVE_CONVERSATION, CHANGE_NAME,
  ///          CHANGE_AVATAR, CREATE_CONVERSATION, PIN_MESSAGE, UNPIN_MESSAGE
  static SystemEventInfo _buildSystemEventInfo(ChatMessage message) {
    final actionType = message.actionType ?? 'UNKNOWN';
    final actorName = message.actor?.name;
    final targetNames =
        message.targetUsers.map((u) => u.name).toList();

    final formattedText = _generateActionText(
      actionType: actionType,
      actorName: actorName,
      targetUserNames: targetNames,
      newValue: message.newValue,
      oldValue: message.oldValue,
      fallbackContent: message.content,
    );

    return SystemEventInfo(
      actionType: actionType,
      actorName: actorName,
      targetUserNames: targetNames,
      oldValue: message.oldValue,
      newValue: message.newValue,
      formattedText: formattedText,
    );
  }

  /// Generate text hiển thị cho system event
  ///
  /// Khớp Angular: generateActionText() switch/case
  static String _generateActionText({
    required String actionType,
    String? actorName,
    List<String> targetUserNames = const [],
    String? newValue,
    String? oldValue,
    String? fallbackContent,
  }) {
    final l10n = L10nHelper.current;
    final actor = actorName ?? l10n.eventSomeone;
    final targets = targetUserNames.join(', ');

    switch (actionType.toUpperCase()) {
      case 'ADD_MEMBER':
        return l10n.eventAddMember(actor, targets);
      case 'REMOVE_MEMBER':
        return l10n.eventRemoveMember(actor, targets);
      case 'LEAVE_CONVERSATION':
        return l10n.eventLeaveConversation(actor);
      case 'CHANGE_NAME':
        if (oldValue != null && newValue != null) {
          return l10n.eventChangeNameFromTo(actor, oldValue, newValue);
        }
        return l10n.eventChangeName(actor, newValue ?? '');
      case 'CHANGE_AVATAR':
        return l10n.eventChangeAvatar(actor);
      case 'CREATE_CONVERSATION':
        return l10n.eventCreateConversation(actor);
      case 'PIN_MESSAGE':
        return l10n.eventPinMessage(actor);
      case 'UNPIN_MESSAGE':
        return l10n.eventUnpinMessage(actor);
      case 'JOIN_CONVERSATION':
        return l10n.eventJoinConversation(actor);
      default:
        // Fallback: dùng content gốc nếu không map được actionType
        return fallbackContent?.isNotEmpty == true
            ? fallbackContent!
            : l10n.eventPerformedAction(actor);
    }
  }

  // Prevent instantiation
  MessageListTransformer._();
}
