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

/// Trạng thái tin nhắn sử dụng @freezed + BaseState
@freezed
class MessageState extends BaseState with _$MessageState {
  const MessageState._();

  /// Override props để Equatable (từ BaseState) so sánh đúng các field.
  /// Freezed không tự sinh == khi class extends Equatable, nên phải khai báo
  /// props thủ công — nếu không, props = [] → mọi state đều "bằng nhau"
  /// → BLoC emit bị suppress → UI không cập nhật.
  @override
  List<Object?> get props => map(
    initial: (_) => const [],
    loading: (s) => [s.chatId],
    loaded: (s) => [
      s.chatId,
      s.messages,
      s.uiMessages,
      s.hasReachedMax,
      s.paginationError,
      s.dataSource,
      s.isBackgroundFetching,
      s.conversationDetail,
    ],
    error: (s) => [s.chatId, s.error, s.previousMessages],
  );

  /// Trạng thái ban đầu
  const factory MessageState.initial() = MessageInitial;

  /// Trạng thái đang tải tin nhắn
  const factory MessageState.loading({
    required String chatId,
  }) = MessagesLoading;

  /// Trạng thái khi tải tin nhắn thành công
  const factory MessageState.loaded({
    required String chatId,
    required List<ChatMessage> messages,
    @Default([]) List<MessageUIState> uiMessages,
    @Default(false) bool hasReachedMax,
    String? paginationError,
    // === Phase 2 + 3 fields ===
    /// Nguồn dữ liệu hiện tại (default: server — giữ backward compat Phase 1)
    @Default(MessageDataSource.server) MessageDataSource dataSource,
    /// Đang có background fetch chạy không
    @Default(false) bool isBackgroundFetching,
    /// Thông tin conversation từ GetConversationDetailUseCase
    Chat? conversationDetail,
  }) = MessagesLoaded;

  /// Trạng thái khi có lỗi với enterprise error handling
  const factory MessageState.error({
    required String chatId,
    required String error,
    /// Preserve previous messages for better UX
    List<ChatMessage>? previousMessages,
  }) = MessagesError;
}
