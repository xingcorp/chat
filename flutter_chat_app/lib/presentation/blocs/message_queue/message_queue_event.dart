part of 'message_queue_bloc.dart';

/// Events for MessageQueueBloc
@freezed
class MessageQueueEvent with _$MessageQueueEvent {
  /// Add message to the queue
  const factory MessageQueueEvent.enqueueMessage({
    required String chatId,
    required String content,
    required ContentType contentType,
    @Default([]) List<Attachment> attachments,
  }) = _EnqueueMessage;
  
  /// Cancel a pending message
  const factory MessageQueueEvent.cancelMessage({
    required String messageId,
  }) = _CancelMessage;
  
  /// Update message status
  const factory MessageQueueEvent.messageStatusUpdated(
    String messageId,
  ) = _MessageStatusUpdated;
  
  /// Load all pending messages
  const factory MessageQueueEvent.loadPendingMessages() = _LoadPendingMessages;
  
  /// Clear completed messages
  const factory MessageQueueEvent.clearCompletedMessages() = _ClearCompletedMessages;
} 