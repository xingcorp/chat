part of 'chat_bloc.dart';

/// States for the chat bloc
@freezed
class ChatState with _$ChatState {
  /// Initial state
  const factory ChatState.initial() = _Initial;

  /// Loading state
  const factory ChatState.loading() = _Loading;

  /// Loaded state with list of chats
  const factory ChatState.loaded({
    required List<Chat> chats,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(0) int page,
    @Default(25) int pageSize,
    @Default(0) int total,
    @Default(ConversationTypeFilter.all) ConversationTypeFilter activeFilter,
    @Default(<ConversationTypeFilter, List<Chat>>{})
    Map<ConversationTypeFilter, List<Chat>> cachedLists,
    @Default(<ConversationTypeFilter, int>{})
    Map<ConversationTypeFilter, int> filterPages,
    @Default(<ConversationTypeFilter, bool>{})
    Map<ConversationTypeFilter, bool> filterHasMore,

    /// Whether a background network refresh is in progress (cache-first pattern)
    @Default(false) bool isSyncing,
  }) = _Loaded;

  /// Chat details loaded state
  const factory ChatState.chatDetailsLoaded({
    required Chat chat,
  }) = _ChatDetailsLoaded;

  /// Conversation action completed successfully
  const factory ChatState.conversationActionCompleted({
    required String chatId,
    required ChatConversationAction action,
  }) = _ConversationActionCompleted;

  /// Messages loading state
  const factory ChatState.messagesLoading({
    List<Chat>? chats,
  }) = _MessagesLoading;

  /// Messages loaded state
  const factory ChatState.messagesLoaded({
    List<Chat>? chats,
    required String chatId,
    required List<ChatMessage> messages,
  }) = _MessagesLoaded;

  /// Message sending state
  const factory ChatState.messageSending({
    required String chatId,
    required String localId,
  }) = _MessageSending;

  /// Message status changed state
  const factory ChatState.messageStatusChanged({
    required String chatId,
    required String localId,
    required MessageQueueStatus status,
    String? serverId,
  }) = _MessageStatusChanged;

  /// Syncing state
  const factory ChatState.syncing() = _Syncing;

  /// Offline state
  const factory ChatState.offline() = _Offline;

  /// Error state
  const factory ChatState.error({
    required String message,
  }) = _Error;
}
