part of 'message_bloc.dart';

/// Base class cho các trạng thái tin nhắn
abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu
class MessageInitial extends MessageState {
  const MessageInitial();
}

/// Trạng thái đang tải tin nhắn
class MessagesLoading extends MessageState {
  final String chatId;

  const MessagesLoading({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Trạng thái khi tải tin nhắn thành công
class MessagesLoaded extends MessageState {
  final String chatId;
  final List<ChatMessage> messages;
  final bool hasReachedMax;

  const MessagesLoaded({
    required this.chatId,
    required this.messages,
    this.hasReachedMax = false,
  });

  MessagesLoaded copyWith({
    String? chatId,
    List<ChatMessage>? messages,
    bool? hasReachedMax,
  }) {
    return MessagesLoaded(
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [chatId, messages, hasReachedMax];
}

/// Trạng thái khi có lỗi
class MessagesError extends MessageState {
  final String chatId;
  final String error;

  const MessagesError({
    required this.chatId,
    required this.error,
  });

  @override
  List<Object?> get props => [chatId, error];
} 