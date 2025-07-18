part of 'message_queue_bloc.dart';

/// States for MessageQueueBloc
@freezed
class MessageQueueState with _$MessageQueueState {
  /// Initial state
  const factory MessageQueueState.initial() = _Initial;
  
  /// Loading state
  const factory MessageQueueState.loading() = _Loading;
  
  /// Message enqueued state
  const factory MessageQueueState.messageEnqueued(String messageId) = _MessageEnqueued;

  /// Message cancelled state
  const factory MessageQueueState.messageCancelled(String messageId) = _MessageCancelled;

  /// Message status updated state
  const factory MessageQueueState.messageStatusUpdated(String messageId) = _MessageStatusUpdatedState;

  /// Pending messages loaded state
  const factory MessageQueueState.pendingMessagesLoaded(List<String> messageIds) = _PendingMessagesLoaded;
  
  /// Completed messages cleared state
  const factory MessageQueueState.completedMessagesCleared() = _CompletedMessagesCleared;
  
  /// No change state
  const factory MessageQueueState.noChange() = _NoChange;
  
  /// Error state
  const factory MessageQueueState.error(String message) = _Error;
} 