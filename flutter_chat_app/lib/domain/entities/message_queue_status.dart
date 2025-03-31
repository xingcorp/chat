/// Enum representing the status of a message in the message queue
enum MessageQueueStatus {
  /// Message is created but not yet queued
  created,
  
  /// Message is in the queue waiting to be sent
  queued,
  
  /// Message is currently being sent
  sending,
  
  /// Message has been sent successfully
  sent,
  
  /// Message sending has failed
  failed,
  
  /// Message has been delivered to the recipient's device
  delivered,
  
  /// Message has been read by the recipient
  read,
  
  /// Message has been cancelled and won't be sent
  cancelled,
}

/// Extension methods for MessageQueueStatus
extension MessageQueueStatusX on MessageQueueStatus {
  /// Whether the message is in a terminal state
  bool get isTerminal => 
    this == MessageQueueStatus.sent || 
    this == MessageQueueStatus.failed || 
    this == MessageQueueStatus.cancelled;
    
  /// Whether the message is in a state that can be retried
  bool get canRetry => 
    this == MessageQueueStatus.failed;
    
  /// Whether the message has been successfully delivered
  bool get isSuccessful => 
    this == MessageQueueStatus.sent || 
    this == MessageQueueStatus.delivered || 
    this == MessageQueueStatus.read;
} 