part of 'chat_bloc.dart';

/// Events for the chat bloc
@freezed
class ChatEvent with _$ChatEvent {
  /// Load all chats
  const factory ChatEvent.loadChats({
    @Default(false) bool forceRefresh,
  }) = _LoadChats;

  /// Load next page of chats
  const factory ChatEvent.loadMoreChats() = _LoadMoreChats;

  /// Load details for a specific chat
  const factory ChatEvent.loadChatDetails({
    required String chatId,
  }) = _LoadChatDetails;

  /// Load messages for a specific chat
  const factory ChatEvent.loadMessages({
    required String chatId,
    @Default(20) int limit,
    @Default(0) int offset,
  }) = _LoadMessages;

  /// Send a new message
  const factory ChatEvent.sendMessage({
    required String chatId,
    required String content,
    required ContentType contentType,
    @Default([]) List<String> attachmentIds,
  }) = _SendMessage;

  /// Create a new chat
  const factory ChatEvent.createChat({
    required ChatType type,
    String? name,
    String? description,
    @Default(GroupType.private) GroupType groupType,
    required List<String> participantIds,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? avatarFilePath,
  }) = _CreateChat;

  /// Update an existing chat
  const factory ChatEvent.updateChat({
    required String chatId,
    String? name,
    String? description,
    String? avatar,
    GroupType? groupType,
    List<String>? memberIds,
    List<String>? adminIds,
  }) = _UpdateChat;

  /// Leave a chat
  const factory ChatEvent.leaveChat({
    required String chatId,
  }) = _LeaveChat;

  /// Delete a chat
  const factory ChatEvent.deleteChat({
    required String chatId,
  }) = _DeleteChat;

  /// Add users to a chat
  const factory ChatEvent.addUsersToChat({
    required String chatId,
    required List<String> userIds,
  }) = _AddUsersToChat;

  /// Remove users from a chat
  const factory ChatEvent.removeUsersFromChat({
    required String chatId,
    required List<String> userIds,
  }) = _RemoveUsersFromChat;

  /// Mark messages as read
  const factory ChatEvent.markMessagesAsRead({
    required String chatId,
    required List<String> messageIds,
  }) = _MarkMessagesAsRead;

  /// Synchronize all chats
  const factory ChatEvent.syncChats() = _SyncChats;

  /// Synchronize messages for a specific chat
  const factory ChatEvent.syncMessages({
    required String chatId,
  }) = _SyncMessages;

  /// New message received
  const factory ChatEvent.newMessageReceived(ChatMessage message) =
      _NewMessageReceived;

  /// Connectivity changed
  const factory ChatEvent.connectivityChanged(bool isConnected) =
      _ConnectivityChanged;

  /// Message status updated from queue service
  const factory ChatEvent.messageStatusUpdated(QueuedMessage message) =
      _MessageStatusUpdated;

  /// Chat updated from real-time source
  const factory ChatEvent.chatUpdated({required Chat chat}) = _ChatUpdated;

  /// Search conversations by keyword (calls remote API like Angular frontend)
  const factory ChatEvent.searchChats({
    required String keyword,
  }) = _SearchChats;

  /// Clear search and reload normal chat list
  const factory ChatEvent.clearSearch() = _ClearSearch;

  /// Change conversation type filter (All / Direct / Group)
  const factory ChatEvent.changeConversationTypeFilter({
    required ConversationTypeFilter filter,
  }) = _ChangeConversationTypeFilter;
}
