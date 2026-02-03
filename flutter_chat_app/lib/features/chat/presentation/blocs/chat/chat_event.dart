part of 'chat_bloc.dart';

/// Events for the chat bloc
@freezed
class ChatEvent with _$ChatEvent {
  /// Load all chats
  const factory ChatEvent.loadChats({
    @Default(false) bool forceRefresh,
  }) = _LoadChats;
  
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
    required List<String> participantIds,
  }) = _CreateChat;
  
  /// Update an existing chat
  const factory ChatEvent.updateChat({
    required String chatId,
    String? name,
    String? description,
    String? avatar,
  }) = _UpdateChat;
  
  /// Leave a chat
  const factory ChatEvent.leaveChat({
    required String chatId,
  }) = _LeaveChat;
  
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
  const factory ChatEvent.newMessageReceived(ChatMessage message) = _NewMessageReceived;
  
  /// Connectivity changed
  const factory ChatEvent.connectivityChanged(bool isConnected) = _ConnectivityChanged;
  
  /// Message status updated from queue service
  const factory ChatEvent.messageStatusUpdated(QueuedMessage message) = _MessageStatusUpdated;
  
  /// Chat updated from real-time source
  const factory ChatEvent.chatUpdated({required Chat chat}) = _ChatUpdated;
} 