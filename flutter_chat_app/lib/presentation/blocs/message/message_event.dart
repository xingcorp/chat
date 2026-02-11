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