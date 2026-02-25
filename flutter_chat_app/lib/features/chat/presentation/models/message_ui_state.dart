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

/// Loại item trong danh sách tin nhắn
enum MessageListItemType {
  /// Tin nhắn thường
  message,

  /// Date separator (dòng "Hôm nay", "Hôm qua", "10/02/2026")
  dateSeparator,

  /// Unread separator (dòng "Tin nhắn chưa đọc")
  unreadSeparator,

  /// System/Log event (thông báo hệ thống)
  systemEvent,
}

/// Reaction đã gom nhóm theo emoji code
///
/// Khớp Angular: OfficeChatMessageReaction { code, reactorIds, reactors }
class ReactionGroup {
  /// Emoji code (e.g., '👍', '❤️', '😂')
  final String code;

  /// Danh sách userId đã react emoji này
  final List<String> reactorIds;

  /// Danh sách tên người react (hiển thị tooltip)
  final List<String> reactorNames;

  /// Người dùng hiện tại đã react emoji này chưa
  final bool isReactedByCurrentUser;

  /// Số lượng người react
  int get count => reactorIds.length;

  const ReactionGroup({
    required this.code,
    required this.reactorIds,
    this.reactorNames = const [],
    this.isReactedByCurrentUser = false,
  });
}

/// Reply message preview
///
/// Khớp Angular: replyMessage { sender.fullname, type, message, urls, fileName }
class ReplyMessagePreview {
  final String id;
  final String senderName;
  final String? senderAvatar;
  final ContentType contentType;

  /// Nội dung text hoặc "[Hình ảnh]", "[Video]", "[File] filename"
  final String previewText;

  /// URL preview (cho IMAGE/VIDEO)
  final String? previewUrl;

  /// Alias for id - the original message ID being replied to
  String get originalMessageId => id;

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

/// System event info
///
/// Khớp Angular: ConversationActionType + generateActionText()
class SystemEventInfo {
  /// Loại action: ADD_MEMBER, CHANGE_NAME, REMOVE_MEMBER, ...
  final String actionType;

  /// Người thực hiện action
  final String? actorName;

  /// Danh sách user bị tác động
  final List<String> targetUserNames;

  /// Giá trị cũ
  final String? oldValue;

  /// Giá trị mới
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
/// Wrapper nhẹ quanh [ChatMessage] domain entity.
/// Chỉ thêm các thuộc tính computed mà widget cần để render.
///
/// Pattern tham khảo:
/// - Signal: ConversationMessage wraps MessageRecord
/// - Flutter MVVM 2025: DTO → Entity → UI State
/// - stream_chat_flutter: position logic trong message_list_view.dart
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
  // Bubble Positioning
  // ══════════════════════════════════════════

  /// Vị trí bubble trong group: first/middle/last/standalone
  final BubblePosition position;

  /// Hiện avatar hay không (chỉ cho tin nhắn người khác)
  final bool showAvatar;

  /// Hiện tên người gửi hay không (cho group chat)
  final bool showSenderName;

  // ══════════════════════════════════════════
  // Timestamp & Date Separator
  // ══════════════════════════════════════════

  /// Hiện timestamp dưới bubble hay không
  final bool showTimestamp;

  /// Timestamp đã format sẵn: "14:30"
  final String formattedTime;

  /// Hiện date separator phía trên tin nhắn này
  final bool showDateSeparator;

  /// Text cho date separator: "Hôm nay", "Hôm qua", "10/02/2026"
  final String? dateSeparatorText;

  // ══════════════════════════════════════════
  // Reactions
  // ══════════════════════════════════════════

  /// Reactions đã gom nhóm theo emoji code
  final List<ReactionGroup> groupedReactions;

  /// Tổng số reactions
  int get totalReactionCount =>
      groupedReactions.fold(0, (sum, r) => sum + r.count);

  // ══════════════════════════════════════════
  // Reply / Forward / Mention
  // ══════════════════════════════════════════

  /// Reply message preview
  final ReplyMessagePreview? replyMessage;

  /// Forward info
  final ForwardMessageInfo? forwardInfo;

  /// Tin nhắn chứa @mention
  final bool hasMention;

  /// Tin nhắn chứa URL/link
  final bool hasLink;

  /// URL cho link preview (URL cuối cùng trong tin nhắn)
  final String? previewLink;

  // ══════════════════════════════════════════
  // Ownership
  // ══════════════════════════════════════════

  /// Tin nhắn từ người dùng hiện tại (computed by transformer)
  final bool isFromCurrentUser;

  // ══════════════════════════════════════════
  // Message Status & State
  // ══════════════════════════════════════════

  /// Đang gửi (chờ server xác nhận)
  final bool isSending;

  /// Gửi thất bại
  final bool isFailed;

  /// Đã bị chỉnh sửa
  final bool isEdited;

  /// Đã bị xóa mềm
  final bool isDeleted;

  /// Ranh giới "đã đọc" cuối cùng
  final bool isLastRead;

  /// Đang được highlight (tìm kiếm, nhảy tới)
  final bool isHighlighted;

  // ══════════════════════════════════════════
  // System Event
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
  bool get hasMedia => message?.hasMedia ?? false;
  List<String> get urls => message?.urls ?? const [];
  String? get fileName => message?.fileName;
  List<MessageAttachment> get attachments =>
      message?.attachments ?? const [];
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
    this.isFromCurrentUser = false,
    this.systemEvent,
  });

  /// Create a copy with modified fields
  MessageUIState copyWith({
    ChatMessage? message,
    MessageListItemType? itemType,
    BubblePosition? position,
    bool? showAvatar,
    bool? showSenderName,
    bool? showTimestamp,
    String? formattedTime,
    bool? showDateSeparator,
    String? dateSeparatorText,
    List<ReactionGroup>? groupedReactions,
    ReplyMessagePreview? replyMessage,
    ForwardMessageInfo? forwardInfo,
    bool? hasMention,
    bool? hasLink,
    String? previewLink,
    bool? isSending,
    bool? isFailed,
    bool? isEdited,
    bool? isDeleted,
    bool? isLastRead,
    bool? isHighlighted,
    bool? isFromCurrentUser,
    SystemEventInfo? systemEvent,
  }) {
    return MessageUIState(
      message: message ?? this.message,
      itemType: itemType ?? this.itemType,
      position: position ?? this.position,
      showAvatar: showAvatar ?? this.showAvatar,
      showSenderName: showSenderName ?? this.showSenderName,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      formattedTime: formattedTime ?? this.formattedTime,
      showDateSeparator: showDateSeparator ?? this.showDateSeparator,
      dateSeparatorText: dateSeparatorText ?? this.dateSeparatorText,
      groupedReactions: groupedReactions ?? this.groupedReactions,
      replyMessage: replyMessage ?? this.replyMessage,
      forwardInfo: forwardInfo ?? this.forwardInfo,
      hasMention: hasMention ?? this.hasMention,
      hasLink: hasLink ?? this.hasLink,
      previewLink: previewLink ?? this.previewLink,
      isSending: isSending ?? this.isSending,
      isFailed: isFailed ?? this.isFailed,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isLastRead: isLastRead ?? this.isLastRead,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      systemEvent: systemEvent ?? this.systemEvent,
    );
  }

  /// Factory cho date separator item
  factory MessageUIState.dateSeparator(String text) {
    return MessageUIState(
      itemType: MessageListItemType.dateSeparator,
      dateSeparatorText: text,
      showTimestamp: false,
    );
  }

  /// Factory cho backward compatibility — wrap ChatMessage đơn giản
  ///
  /// Dùng cho các widget legacy chưa tích hợp MessageListTransformer.
  /// Không có grouping/positioning — chỉ wrap message với defaults.
  factory MessageUIState.fromMessage(ChatMessage message) {
    return MessageUIState(
      message: message,
      itemType: MessageListItemType.message,
      position: BubblePosition.standalone,
      showAvatar: true,
      showSenderName: true,
      showTimestamp: true,
    );
  }

  /// Factory cho unread separator
  factory MessageUIState.unreadSeparator() {
    return const MessageUIState(
      itemType: MessageListItemType.unreadSeparator,
      showTimestamp: false,
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
      showTimestamp: false,
    );
  }
}
