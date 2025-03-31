import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';

/// Model representing a message in the message queue
class QueuedMessage {
  /// Unique identifier for the message in the queue
  final String localId;
  
  /// ID of the chat this message belongs to
  final String chatId;
  
  /// The message content
  final ChatMessage message;
  
  /// Current status of the message in the queue
  final MessageQueueStatus status;
  
  /// Server ID assigned to the message after successful sending
  final String? serverId;
  
  /// Time when the message was created
  final DateTime createdAt;
  
  /// Time when the message status was last updated
  final DateTime updatedAt;
  
  /// Number of retry attempts that have been made
  final int retryCount;
  
  /// Scheduled time for the next retry attempt
  final DateTime? nextRetryTime;
  
  /// Creates a new queued message
  QueuedMessage({
    required this.localId,
    required this.chatId,
    required this.message,
    required this.status,
    this.serverId,
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.nextRetryTime,
  });
  
  /// Creates a copy of this queued message with the given fields replaced
  QueuedMessage copyWith({
    String? localId,
    String? chatId,
    ChatMessage? message,
    MessageQueueStatus? status,
    String? serverId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retryCount,
    DateTime? nextRetryTime,
  }) {
    return QueuedMessage(
      localId: localId ?? this.localId,
      chatId: chatId ?? this.chatId,
      message: message ?? this.message,
      status: status ?? this.status,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryTime: nextRetryTime ?? this.nextRetryTime,
    );
  }
  
  /// Converts the queued message to a map
  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'chatId': chatId,
      'message': message.toJson(),
      'status': status.index,
      'serverId': serverId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'nextRetryTime': nextRetryTime?.millisecondsSinceEpoch,
    };
  }
  
  /// Creates a queued message from a map
  factory QueuedMessage.fromMap(Map<String, dynamic> map) {
    return QueuedMessage(
      localId: map['localId'] as String,
      chatId: map['chatId'] as String,
      message: ChatMessage.fromJson(map['message'] as Map<String, dynamic>),
      status: MessageQueueStatus.values[map['status'] as int],
      serverId: map['serverId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      retryCount: map['retryCount'] as int,
      nextRetryTime: map['nextRetryTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['nextRetryTime'] as int)
          : null,
    );
  }
  
  /// Whether the message can be retried
  bool get canRetry => status.canRetry;
  
  /// Whether the message is in a terminal state
  bool get isTerminal => status.isTerminal;
  
  /// Whether the message has been successfully sent
  bool get isSuccessful => status.isSuccessful;
} 