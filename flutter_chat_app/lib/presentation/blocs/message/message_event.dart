part of 'message_bloc.dart';

/// Base class cho các sự kiện tin nhắn
abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

/// Sự kiện tải danh sách tin nhắn
class LoadMessages extends MessageEvent {
  final String chatId;
  final int limit;
  final bool forceRefresh;
  final bool subscribeToUpdates;

  const LoadMessages({
    required this.chatId,
    this.limit = 20,
    this.forceRefresh = false,
    this.subscribeToUpdates = true,
  });

  @override
  List<Object?> get props => [chatId, limit, forceRefresh, subscribeToUpdates];
}

/// Sự kiện tải thêm tin nhắn (pagination)
class LoadMoreMessages extends MessageEvent {
  final int limit;

  const LoadMoreMessages({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

/// Sự kiện gửi tin nhắn mới
class SendMessage extends MessageEvent {
  final String content;
  final String senderId;
  final String contentType;
  final List<String> attachmentIds;
  final String? replyMessageId;

  const SendMessage({
    required this.content,
    required this.senderId,
    required this.contentType,
    this.attachmentIds = const [],
    this.replyMessageId,
  });

  @override
  List<Object?> get props =>
      [content, senderId, contentType, attachmentIds, replyMessageId];
}

/// Sự kiện gửi sticker
class SendSticker extends MessageEvent {
  final String stickerCode;
  final String senderId;
  final String? replyMessageId;

  const SendSticker({
    required this.stickerCode,
    required this.senderId,
    this.replyMessageId,
  });

  @override
  List<Object?> get props => [stickerCode, senderId, replyMessageId];
}

/// Sự kiện gửi tin nhắn với file đính kèm (upload + send)
///
/// **Cross-platform support:**
/// - Mobile: uses [localFilePaths] with dart:io File operations
/// - Web: uses [fileBytes] and [fileNames] directly (no dart:io)
class SendMessageWithAttachments extends MessageEvent {
  final String content;
  final String senderId;
  final List<String> localFilePaths;
  final String? replyMessageId;

  /// File bytes for web platform (indexed same as localFilePaths)
  /// On mobile, this is null and files are read from localFilePaths
  final List<List<int>>? fileBytes;

  /// File names for web platform (indexed same as localFilePaths)
  /// On mobile, extracted from localFilePaths
  final List<String>? fileNames;

  /// File sizes for web platform (indexed same as localFilePaths)
  /// On mobile, read from File.length()
  final List<int>? fileSizes;

  const SendMessageWithAttachments({
    required this.content,
    required this.senderId,
    required this.localFilePaths,
    this.replyMessageId,
    this.fileBytes,
    this.fileNames,
    this.fileSizes,
  });

  @override
  List<Object?> get props => [
        content,
        senderId,
        localFilePaths,
        replyMessageId,
        fileBytes,
        fileNames,
        fileSizes
      ];
}

/// Sự kiện gửi voice note (ghi âm)
class SendVoiceNote extends MessageEvent {
  final String filePath;
  final String senderId;
  final int durationSeconds;
  final String? replyMessageId;

  /// Dùng khi retry để cập nhật lại draft message cũ
  final String? retryDraftMessageId;
  final String? fileName;

  const SendVoiceNote({
    required this.filePath,
    required this.senderId,
    required this.durationSeconds,
    this.replyMessageId,
    this.retryDraftMessageId,
    this.fileName,
  });

  @override
  List<Object?> get props => [
        filePath,
        senderId,
        durationSeconds,
        replyMessageId,
        retryDraftMessageId,
        fileName,
      ];
}

/// Sự kiện retry gửi voice note thất bại
class RetryVoiceNote extends MessageEvent {
  final String draftMessageId;

  const RetryVoiceNote({required this.draftMessageId});

  @override
  List<Object?> get props => [draftMessageId];
}

/// Sự kiện gửi vị trí
class SendLocationMessage extends MessageEvent {
  final String senderId;
  final double latitude;
  final double longitude;
  final String? locationName;

  const SendLocationMessage({
    required this.senderId,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  @override
  List<Object?> get props => [senderId, latitude, longitude, locationName];
}

/// Sự kiện chỉnh sửa tin nhắn
class EditMessage extends MessageEvent {
  final String messageId;
  final String content;

  const EditMessage({
    required this.messageId,
    required this.content,
  });

  @override
  List<Object?> get props => [messageId, content];
}

/// Sự kiện xóa tin nhắn
class DeleteMessage extends MessageEvent {
  final String messageId;

  const DeleteMessage(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Sự kiện đánh dấu chat đã đọc
class MarkChatAsRead extends MessageEvent {
  final String chatId;

  const MarkChatAsRead(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

/// Sự kiện page cập nhật các item hiện đang visible
/// để BLoC chủ động prefetch duration cho voice note.
class PrefetchVisibleVoiceNoteDurations extends MessageEvent {
  final List<int> visibleIndices;

  const PrefetchVisibleVoiceNoteDurations({
    required this.visibleIndices,
  });

  @override
  List<Object?> get props => [visibleIndices];
}

/// Sự kiện nhận tin nhắn thời gian thực mới
class ReceiveRealTimeMessage extends MessageEvent {
  final ChatMessage message;

  const ReceiveRealTimeMessage(this.message);

  @override
  List<Object?> get props => [message];
}

/// Sự kiện làm mới tin nhắn
class RefreshMessages extends MessageEvent {
  const RefreshMessages();
}

/// Sự kiện xóa tin nhắn
class ClearMessages extends MessageEvent {
  const ClearMessages();
}

/// Sự kiện toggle reaction trên tin nhắn
class ToggleReaction extends MessageEvent {
  final String messageId;
  final String emojiCode;

  const ToggleReaction({
    required this.messageId,
    required this.emojiCode,
  });

  @override
  List<Object?> get props => [messageId, emojiCode];
}

// === Phase 2 + 3 Events ===

/// Event khi background fetch hoàn tất (internal, không public)
class _BackgroundFetchCompleted extends MessageEvent {
  final String chatId;
  final List<ChatMessage> serverMessages;

  /// true = delta sync (chi tin nhan moi), false = full page fetch
  final bool isDelta;

  /// Limit used for the fetch request (for hasReachedMax calculation)
  final int fetchLimit;

  const _BackgroundFetchCompleted({
    required this.chatId,
    required this.serverMessages,
    required this.isDelta,
    required this.fetchLimit,
  });

  @override
  List<Object?> get props => [chatId, serverMessages, isDelta, fetchLimit];
}

/// Event khi background fetch thất bại (internal)
class _BackgroundFetchFailed extends MessageEvent {
  final String chatId;
  final String error;

  const _BackgroundFetchFailed({
    required this.chatId,
    required this.error,
  });

  @override
  List<Object?> get props => [chatId, error];
}

/// Event khi socket reconnect — trigger delta sync
class _ReconnectionDetected extends MessageEvent {
  const _ReconnectionDetected();
}

/// Event khi app resume từ background
class AppResumed extends MessageEvent {
  const AppResumed();
}

/// Event cho socket message:edit
class ReceiveMessageEdited extends MessageEvent {
  final ChatMessage editedMessage;

  const ReceiveMessageEdited(this.editedMessage);

  @override
  List<Object?> get props => [editedMessage];
}

/// Event cho socket message:delete
class ReceiveMessageDeleted extends MessageEvent {
  final ChatMessage deletedMessage;

  const ReceiveMessageDeleted(this.deletedMessage);

  @override
  List<Object?> get props => [deletedMessage];
}

/// Event cho socket message:reaction
class ReceiveMessageReaction extends MessageEvent {
  final String messageId;
  final String code;
  final String userId;
  final String userName;
  final bool isAdd;

  const ReceiveMessageReaction({
    required this.messageId,
    required this.code,
    required this.userId,
    required this.userName,
    required this.isAdd,
  });

  @override
  List<Object?> get props => [messageId, code, userId, userName, isAdd];
}

/// Event cho socket message:read
class ReceiveMessageRead extends MessageEvent {
  final String messageId;
  final String readerId;

  const ReceiveMessageRead({
    required this.messageId,
    required this.readerId,
  });

  @override
  List<Object?> get props => [messageId, readerId];
}

/// Event cập nhật danh sách members từ ConversationDetailBloc (cho read receipts)
class UpdateConversationMembers extends MessageEvent {
  final List<ConversationMember> members;

  const UpdateConversationMembers(this.members);

  @override
  List<Object?> get props => [members];
}

/// Event fetch frequently used reactions
class FetchFrequentReactions extends MessageEvent {
  const FetchFrequentReactions();
}

/// Sự kiện nhảy tới tin nhắn cụ thể (từ kết quả tìm kiếm)
///
/// Load messages từ timestamp của tin nhắn đích (matching Angular frontend logic).
/// Thay vì load more tuần tự, load trực tiếp từ cursor = createdAt của tin nhắn.
class JumpToMessage extends MessageEvent {
  final String messageId;
  final int createdAtMs;

  const JumpToMessage({
    required this.messageId,
    required this.createdAtMs,
  });

  @override
  List<Object?> get props => [messageId, createdAtMs];
}

/// Sự kiện chuyển tiếp tin nhắn đến chat khác
class ForwardMessage extends MessageEvent {
  /// Tin nhắn gốc cần chuyển tiếp (full object, không cần tìm trong state)
  final ChatMessage message;

  /// ID chat đích để chuyển tiếp đến
  final String targetChatId;

  /// ID chat gốc (optional, for context)
  final String? sourceChatId;

  const ForwardMessage({
    required this.message,
    required this.targetChatId,
    this.sourceChatId,
  });

  @override
  List<Object?> get props => [message.id, targetChatId, sourceChatId];
}
