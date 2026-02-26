part of 'message_bloc.dart';

/// Nguồn dữ liệu của tin nhắn hiện tại
enum MessageDataSource {
  /// Dữ liệu từ local storage/cache
  local,
  /// Dữ liệu từ server (full load hoặc delta)
  server,
  /// Dữ liệu đã merge giữa local và server
  merged,
}

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
  final List<MessageUIState> uiMessages;
  final bool hasReachedMax;
  /// Lỗi tạm khi pagination fail (không phá state chính, chỉ để reset UI loading)
  final String? paginationError;

  // === Phase 2 + 3 fields ===
  /// Nguồn dữ liệu hiện tại (default: server — giữ backward compat Phase 1)
  final MessageDataSource dataSource;
  /// Đang có background fetch chạy không
  final bool isBackgroundFetching;

  const MessagesLoaded({
    required this.chatId,
    required this.messages,
    this.uiMessages = const [],
    this.hasReachedMax = false,
    this.paginationError,
    this.dataSource = MessageDataSource.server,
    this.isBackgroundFetching = false,
  });

  MessagesLoaded copyWith({
    String? chatId,
    List<ChatMessage>? messages,
    List<MessageUIState>? uiMessages,
    bool? hasReachedMax,
    String? paginationError,
    MessageDataSource? dataSource,
    bool? isBackgroundFetching,
  }) {
    return MessagesLoaded(
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      uiMessages: uiMessages ?? this.uiMessages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      paginationError: paginationError,
      dataSource: dataSource ?? this.dataSource,
      isBackgroundFetching: isBackgroundFetching ?? this.isBackgroundFetching,
    );
  }

  @override
  List<Object?> get props => [
    chatId, messages, uiMessages, hasReachedMax, paginationError,
    dataSource, isBackgroundFetching,
  ];
}

/// **Trạng thái khi có lỗi với enterprise error handling**
class MessagesError extends MessageState {
  final String chatId;
  final String error;
  final List<ChatMessage>? previousMessages; // Preserve previous messages for better UX

  const MessagesError({
    required this.chatId,
    required this.error,
    this.previousMessages,
  });

  @override
  List<Object?> get props => [chatId, error, previousMessages];
}