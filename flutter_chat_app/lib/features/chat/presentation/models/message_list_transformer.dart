import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/localization/l10n_helper.dart';
import 'package:flutter_chat_app/core/services/user_cache_service.dart';
import 'package:flutter_chat_app/domain/entities/reader_info.dart';
import 'package:flutter_chat_app/domain/utils/read_receipt_calculator.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:intl/intl.dart';

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
    List<ConversationMember> members = const [],
    UserCacheService? userCache,
  }) {
    if (messages.isEmpty) return const [];

    final result = <MessageUIState>[];

    // Index messages by id for reply/forward lookup
    final Map<String, ChatMessage> messageById = {
      for (final m in messages)
        if (m.id.isNotEmpty) m.id: m,
    };

    // Compute read receipt positions — O(n) via ReadReceiptCalculator
    // Only computed when members are provided (non-empty)
    final readReceiptPositions = members.isEmpty
        ? const <String, List<ReaderInfo>>{}
        : ReadReceiptCalculator.computeLastReadPositions(
            messages: messages,
            currentUserId: currentUserId,
            members: members,
          );

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
          eventInfo: _buildSystemEventInfo(current, members, userCache),
        ));
        continue;
      }

      // ── Bubble grouping ──
      final isCurrentUser = current.sender.id == currentUserId;
      final position = _calculatePosition(current, olderMsg, newerMsg);
      final showDateSep = _shouldShowDateSeparator(current, olderMsg);
      final showTimestamp = _shouldShowTimestamp(current, newerMsg, position);

      // ── Avatar & sender name ──
      // stream_chat: avatar at bottom of group (last), name at top (first)
      // Angular: show khi firstMessage == true && role == MEMBER
      final isFirst = position == BubblePosition.first ||
          position == BubblePosition.standalone;
      final isLast = position == BubblePosition.last ||
          position == BubblePosition.standalone;
      final showAvatar = !isCurrentUser && isLast;
      final showSenderName = !isCurrentUser && isFirst && isGroupChat;

      // ── Reactions grouping ──
      final groupedReactions = _groupReactions(
        current.reactions,
        members,
        currentUserId,
      );

      // ── Reply preview ──
      final replyPreview = _buildReplyPreview(current, messageById, members);

      // ── Forward info ──
      final forwardInfo = _buildForwardInfo(current, members);

      // ── Content analysis ──
      final contentText = current.content;
      final hasLink = _urlRegex.hasMatch(contentText);
      final hasMention =
          current.mentionTo.isNotEmpty || _mentionRegex.hasMatch(contentText);
      final previewLink =
          hasLink ? _urlRegex.allMatches(contentText).last.group(0) : null;

      // ── Message status ──
      final isSending = current.id.startsWith('draft_') ||
          current.status == MessageStatus.pending ||
          current.status == MessageStatus.sending;
      final isFailed = current.status == MessageStatus.failed;

      // ── Resolve sender name/avatar from members ──
      final resolvedSender = _resolveSenderFromMembers(
        current.sender.id,
        current.sender.name,
        current.sender.avatar,
        members,
        userCache,
      );

      result.add(MessageUIState(
        message: current,
        resolvedSenderName: resolvedSender.$1,
        resolvedSenderAvatar: resolvedSender.$2,
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
        isFromCurrentUser: isCurrentUser,
        readReceiptReaders: readReceiptPositions[current.id] ?? const [],
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
  // Sender Resolution
  // ══════════════════════════════════════════

  /// Resolve sender name and avatar from members list.
  ///
  /// Fallback chain:
  ///   1. members lookup by senderId → fullName / avatarUrl
  ///   2. original message sender name / avatar (if non-empty and not a UUID)
  ///   3. null (let MessageUIState fall through to message.sender defaults)
  ///
  /// Returns a Record `(String? resolvedName, String? resolvedAvatar)`.
  static (String?, String?) _resolveSenderFromMembers(
    String senderId,
    String originalName,
    String? originalAvatar,
    List<ConversationMember> members,
    UserCacheService? userCache,
  ) {
    if (members.isEmpty) {
      // Fallback to global user cache when no members available
      if (userCache != null && senderId.isNotEmpty) {
        final cached = userCache.getUser(senderId);
        if (cached != null) {
          return (cached.name, cached.avatar);
        }
      }
      if (kDebugMode && _looksLikeUUID(originalName)) {
        debugPrint(
          '[SenderDebug][Resolve] members EMPTY, sender=$senderId '
          'originalName=$originalName (UUID!) → cannot resolve',
        );
      }
      return (null, null);
    }

    final member = members.cast<ConversationMember?>().firstWhere(
          (m) => m!.userId == senderId,
          orElse: () => null,
        );

    // Resolve name: prefer member.fullName, fallback to userCache, then original
    String? resolvedName;
    if (member != null &&
        member.fullName != null &&
        member.fullName!.trim().isNotEmpty) {
      resolvedName = member.fullName!.trim();
    } else if (userCache != null && senderId.isNotEmpty) {
      // Member not found or has no name — try global user cache
      final cachedName = userCache.getUserName(senderId);
      if (cachedName != null) {
        resolvedName = cachedName;
      } else if (originalName.trim().isNotEmpty &&
          !_looksLikeUUID(originalName.trim())) {
        resolvedName = null; // original name is good
      } else {
        resolvedName = '';
      }
    } else if (originalName.trim().isNotEmpty &&
        !_looksLikeUUID(originalName.trim())) {
      resolvedName =
          null; // original name is good, let getter use message.sender.name
    } else {
      // Original name is empty or looks like UUID, and no member found
      // → return empty string to prevent UUID from showing in UI
      resolvedName = '';
    }

    // Resolve avatar: prefer member.avatarUrl, fallback to original
    String? resolvedAvatar;
    if (member != null &&
        member.avatarUrl != null &&
        member.avatarUrl!.trim().isNotEmpty) {
      resolvedAvatar = member.avatarUrl!.trim();
    } else {
      resolvedAvatar = null; // let default getter handle it
    }

    return (resolvedName, resolvedAvatar);
  }

  /// Check if a string looks like a UUID (8-4-4-4-12 hex pattern)
  static bool _looksLikeUUID(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
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
    List<ConversationMember> members,
    String currentUserId,
  ) {
    if (reactions.isEmpty) return const [];

    final Map<String, List<String>> groupMap = {};
    final Map<String, Map<String, String>> nameByIdMap = {};
    final Map<String, Map<String, String?>> avatarByIdMap = {};

    final Map<String, ConversationMember> memberByUserId = {
      for (final m in members)
        if (m.userId.isNotEmpty) m.userId: m,
    };

    for (final r in reactions) {
      groupMap.putIfAbsent(r.code, () => []).add(r.userId);

      final member = memberByUserId[r.userId];
      final name = (member?.fullName?.trim().isNotEmpty ?? false)
          ? member!.fullName!.trim()
          : (r.userName?.trim().isNotEmpty ?? false)
              ? r.userName!.trim()
              : r.userId;

      nameByIdMap.putIfAbsent(r.code, () => {})[r.userId] = name;
      avatarByIdMap.putIfAbsent(r.code, () => {})[r.userId] = member?.avatarUrl;
    }

    return groupMap.entries.map((entry) {
      return ReactionGroup(
        code: entry.key,
        reactorIds: entry.value,
        reactorNameById: nameByIdMap[entry.key] ?? const {},
        reactorAvatarById: avatarByIdMap[entry.key] ?? const {},
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
  static ReplyMessagePreview? _buildReplyPreview(
    ChatMessage message,
    Map<String, ChatMessage> messageById,
    List<ConversationMember> members,
  ) {
    // Prefer lookup by replyMessageId (frontend uses replyMessageId, nested replyMessage may be partial)
    final lookupId = message.replyMessageId;
    final lookedUp = (lookupId != null) ? messageById[lookupId] : null;
    final reply = lookedUp ?? message.replyMessage;
    if (reply == null) {
      // if (kDebugMode && lookupId != null && lookupId.isNotEmpty) {
      //   debugPrint(
      //     '[replyPreview][MISS] msgId=${message.id} replyMessageId=$lookupId '
      //     'lookupHit=false nestedReply=false -> returning placeholder',
      //   );
      // }

      if (lookupId == null || lookupId.isEmpty) return null;

      // Placeholder to make the missing-data case visible in UI
      final l10n = L10nHelper.current;
      return ReplyMessagePreview(
        id: lookupId,
        senderName: 'Unknown',
        senderAvatar: null,
        contentType: ContentType.text,
        previewText: l10n.noMessages,
        previewUrl: null,
      );
    }

    // if (kDebugMode) {
    //   final urlsCount = reply.urls.length;
    //   final attachCount = reply.attachments.length;
    //   debugPrint(
    //     '[replyPreview] msgId=${message.id} replyMessageId=$lookupId '
    //     'lookupHit=${lookedUp != null} replyId=${reply.id} '
    //     'replyType=${reply.contentType} content="${reply.content.replaceAll("\n", "\\n")}" '
    //     'urls=$urlsCount attachments=$attachCount fileName=${reply.fileName}',
    //   );
    // }

    // Preview text theo content type
    final previewText = _getReplyPreviewText(reply, members);

    // Preview URL (cho IMAGE/VIDEO)
    String? previewUrl;
    if (reply.urls.isNotEmpty &&
        (reply.contentType == ContentType.image ||
            reply.contentType == ContentType.video)) {
      previewUrl = reply.urls.first;
    }

    // if (kDebugMode) {
    //   debugPrint(
    //     '[replyPreview] msgId=${message.id} replyId=${reply.id} '
    //     'computedPreviewUrl=${previewUrl ?? ''} previewText="$previewText"',
    //   );
    // }

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
  static String _getReplyPreviewText(
    ChatMessage reply,
    List<ConversationMember> members,
  ) {
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
      case ContentType.sticker:
        return l10n.replyPreviewSticker;
      case ContentType.link:
        if (reply.content.isEmpty) {
          return l10n.replyPreviewLink;
        }
        return _formatMentionAwareContent(reply, members);
      case ContentType.event:
        return l10n.replyPreviewSystemEvent;
      case ContentType.text:
        return _formatMentionAwareContent(reply, members);
    }
  }

  // ══════════════════════════════════════════
  // Forward Info
  // ══════════════════════════════════════════

  /// Build forward info từ domain entity
  ///
  /// Khớp Angular: forwardedFromMessage { sender.fullname, type, message, urls, fileName }
  static ForwardMessageInfo? _buildForwardInfo(
    ChatMessage message,
    List<ConversationMember> members,
  ) {
    final forwardId = message.forwardedFromMessageId;
    final forwardMsg = message.forwardedFromMessage;

    // Không có forward info
    if (forwardId == null && forwardMsg == null) return null;

    // Có forward object - lấy data từ đó
    if (forwardMsg != null) {
      final previewText = _getForwardPreviewText(forwardMsg, members);
      String? previewUrl;
      if (forwardMsg.urls.isNotEmpty &&
          (forwardMsg.contentType == ContentType.image ||
              forwardMsg.contentType == ContentType.video)) {
        previewUrl = forwardMsg.urls.first;
      }

      return ForwardMessageInfo(
        originalMessageId: forwardMsg.id,
        originalSenderName: forwardMsg.sender.name,
        originalSenderAvatar: forwardMsg.sender.avatar,
        contentType: forwardMsg.contentType,
        previewText: previewText,
        previewUrl: previewUrl,
      );
    }

    // Chỉ có ID - tạo placeholder
    if (forwardId != null && forwardId.isNotEmpty) {
      return ForwardMessageInfo(
        originalMessageId: forwardId,
      );
    }

    return null;
  }

  /// Tạo preview text cho forward message theo content type
  static String _getForwardPreviewText(
    ChatMessage msg,
    List<ConversationMember> members,
  ) {
    final l10n = L10nHelper.current;
    switch (msg.contentType) {
      case ContentType.image:
        return l10n.replyPreviewImage;
      case ContentType.video:
        return l10n.replyPreviewVideo;
      case ContentType.audio:
        return l10n.replyPreviewAudio;
      case ContentType.file:
        return l10n.replyPreviewFile(msg.fileName ?? '');
      case ContentType.location:
        return l10n.replyPreviewLocation;
      case ContentType.sticker:
        return l10n.replyPreviewSticker;
      case ContentType.link:
        if (msg.content.isEmpty) {
          return l10n.replyPreviewLink;
        }
        return _formatMentionAwareContent(msg, members);
      case ContentType.event:
        return l10n.replyPreviewSystemEvent;
      case ContentType.text:
        return _formatMentionAwareContent(msg, members);
    }
  }

  static String _formatMentionAwareContent(
    ChatMessage message,
    List<ConversationMember> members,
  ) {
    final mentionNameById = _buildMentionNameById(message, members);
    return message.content.formatChatMessage(mentionNameById: mentionNameById);
  }

  static Map<String, String> _buildMentionNameById(
    ChatMessage message,
    List<ConversationMember> members,
  ) {
    final map = <String, String>{};

    for (final mention in message.mentionTo) {
      final id = mention.id.trim();
      final name = mention.name.trim();
      if (id.isNotEmpty && name.isNotEmpty) {
        map[id] = name;
      }
    }

    for (final member in members) {
      final userId = member.userId.trim();
      final fullName = member.fullName?.trim();
      if (userId.isNotEmpty && fullName != null && fullName.isNotEmpty) {
        map.putIfAbsent(userId, () => fullName);
      }
    }

    if (!map.containsKey('all') && message.content.contains('[@all]')) {
      map['all'] = 'All';
    }

    return map;
  }

  // ══════════════════════════════════════════
  // System Event
  // ══════════════════════════════════════════

  /// Build system event info từ domain entity
  ///
  /// Khớp Angular: generateActionText(message) trong conversation.component.ts
  /// Angular dùng message.sender?.fullname cho actor name (không phải actor)
  /// Handles: ADD_MEMBER, REMOVE_MEMBER, LEAVE_CONVERSATION, CHANGE_NAME,
  ///          CHANGE_AVATAR, CREATE_CONVERSATION, PIN_MESSAGE, UNPIN_MESSAGE
  ///
  /// [members] dùng để resolve tên khi socket event thiếu sender/targetUsers info
  static SystemEventInfo _buildSystemEventInfo(
    ChatMessage message,
    List<ConversationMember> members,
    UserCacheService? userCache,
  ) {
    final actionType = message.actionType ?? 'UNKNOWN';

    // Build member lookup map: userId -> fullName
    final memberNameById = <String, String>{
      for (final m in members)
        if (m.userId.isNotEmpty && (m.fullName?.isNotEmpty ?? false))
          m.userId: m.fullName!,
    };

    // Resolve actor name: prefer message data, fallback to members lookup
    // CRITICAL: Never show UUID as actor name — use _looksLikeUUID() guard
    final l10n = L10nHelper.current;
    final rawActorName = message.sender.name;
    String actorName;
    if (rawActorName.isNotEmpty &&
        rawActorName != 'Unknown' &&
        !_looksLikeUUID(rawActorName)) {
      actorName = rawActorName;
    } else {
      // Try members lookup
      actorName = memberNameById[message.sender.id]
          // Try actor object (socket events may have separate actor)
          ?? ((message.actor?.name != null &&
                  message.actor!.name.isNotEmpty &&
                  message.actor!.name != 'Unknown' &&
                  !_looksLikeUUID(message.actor!.name))
              ? message.actor!.name
              : null)
          // Try global user cache as last resort
          ?? userCache?.getUserName(message.sender.id)
          ?? l10n.eventSomeone;
    }

    // ─── DEBUG: System event name resolution ───
    final actorIsUUID = _looksLikeUUID(actorName);
    if (kDebugMode && (actorIsUUID || rawActorName == 'Unknown')) {
      debugPrint(
        '[SenderDebug][SystemEvent] msgId=${message.id} actionType=$actionType\n'
        '  rawActorName=$rawActorName → resolved=$actorName (isUUID=$actorIsUUID)\n'
        '  sender.id=${message.sender.id}\n'
        '  actor?.id=${message.actor?.id} actor?.name=${message.actor?.name}\n'
        '  members_count=${members.length} memberLookup=${memberNameById[message.sender.id]}\n'
        '  targetUsers=${message.targetUsers.map((u) => '${u.id}:${u.name}').toList()}\n'
        '  content=${message.content.length > 80 ? message.content.substring(0, 80) : message.content}',
      );
    }

    // Resolve target user names: prefer message data, fallback to members lookup
    // CRITICAL: Never show UUID as target name — use _looksLikeUUID() guard
    final targetNames = message.targetUsers.map((u) {
      if (u.name.isNotEmpty &&
          u.name != 'Unknown' &&
          !_looksLikeUUID(u.name)) {
        return u.name;
      }
      // Members lookup, then global user cache, then raw name
      return memberNameById[u.id]
          ?? userCache?.getUserName(u.id)
          ?? u.name;
    }).toList();

    // If all target names are still 'Unknown' after resolution, and we have
    // fallbackContent from the backend (the `content` field), use that instead.
    // This handles socket events which only send targetUserIds without names,
    // and where the target user may no longer be in the members list
    // (e.g., REMOVE_MEMBER removes them before the system message is rendered).
    final bool allTargetsUnknown = targetNames.isNotEmpty &&
        targetNames.every(
            (n) => n == 'Unknown' || n.trim().isEmpty || _looksLikeUUID(n));
    final bool hasFallbackContent =
        message.content.isNotEmpty && message.content != 'Unknown';

    final formattedText = _generateActionText(
      actionType: actionType,
      actorName: actorName,
      targetUserNames: allTargetsUnknown && hasFallbackContent
          ? const [] // Force fallback to content
          : targetNames,
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
    final targets =
        targetUserNames.where((n) => n.trim().isNotEmpty).join(', ');

    switch (actionType.toUpperCase()) {
      case 'ADD_MEMBER':
        if (targets.isEmpty && fallbackContent?.isNotEmpty == true) {
          return fallbackContent!;
        }
        return l10n.eventAddMember(actor, targets);
      case 'REMOVE_MEMBER':
        if (targets.isEmpty && fallbackContent?.isNotEmpty == true) {
          return fallbackContent!;
        }
        return l10n.eventRemoveMember(actor, targets);
      case 'LEAVE_CONVERSATION':
        return l10n.eventLeaveConversation(actor);
      case 'JOIN_CONVERSATION':
        return l10n.eventJoinConversation(actor);
      case 'CHANGE_NAME':
        if (oldValue != null && newValue != null) {
          return l10n.eventChangeNameFromTo(actor, oldValue, newValue);
        }
        return l10n.eventChangeName(actor, newValue ?? '');
      case 'CHANGE_AVATAR':
        return l10n.eventChangeAvatar(actor);
      case 'CHANGE_BACKGROUND':
        return l10n.eventChangeBackground(actor);
      case 'CREATE_CONVERSATION':
        return l10n.eventCreateConversation(actor);
      case 'PIN_MESSAGE':
        return l10n.eventPinMessage(actor);
      case 'UNPIN_MESSAGE':
        return l10n.eventUnpinMessage(actor);
      case 'PROMOTE_ADMIN':
        return l10n.eventPromoteAdmin(actor, targets);
      case 'DEMOTE_ADMIN':
        return l10n.eventDemoteAdmin(actor, targets);
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
