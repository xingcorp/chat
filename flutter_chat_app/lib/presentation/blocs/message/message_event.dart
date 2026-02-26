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
  List<Object?> get props => [content, senderId, contentType, attachmentIds, replyMessageId];
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
  List<Object?> get props => [content, senderId, localFilePaths, replyMessageId, fileBytes, fileNames, fileSizes];
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

  const _BackgroundFetchCompleted({
    required this.chatId,
    required this.serverMessages,
  });

  @override
  List<Object?> get props => [chatId, serverMessages];
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
  final String messageId;

  const ReceiveMessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
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