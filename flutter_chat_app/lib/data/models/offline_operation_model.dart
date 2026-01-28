import 'dart:convert';

import 'package:isar/isar.dart';

part 'offline_operation_model.g.dart';

/// Type of offline operation
enum OperationType {
  /// Send a message
  sendMessage,
  
  /// Edit a message
  editMessage,
  
  /// Delete a message
  deleteMessage,
  
  /// Mark message as read
  markAsRead,
  
  /// Add reaction to message
  addReaction,
  
  /// Remove reaction from message
  removeReaction,
  
  /// Create a group
  createGroup,
  
  /// Edit group details
  editGroup,
  
  /// Leave a conversation
  leaveConversation,
  
  /// Delete a conversation
  deleteConversation,
}

/// Status of offline operation
enum OperationStatus {
  /// Operation is pending execution
  pending,
  
  /// Operation is currently being processed
  processing,
  
  /// Operation completed successfully
  completed,
  
  /// Operation failed after retries
  failed,
}

/// Model class representing an offline operation to be synced
@collection
class OfflineOperationModel {
  /// Operation's unique identifier in the database
  @Id()
  final int id;

  /// Unique identifier for the operation
  @Index(unique: true)
  final String operationId;

  /// Type of operation
  @enumValue
  final OperationType type;

  /// Serialized data for the operation
  final String data;

  /// Timestamp when the operation was created
  @Index()
  final DateTime timestamp;

  /// Number of times this operation has been retried
  final int retryCount;

  /// Status of the operation
  @enumValue
  final OperationStatus status;

  /// Error message if operation failed
  final String? errorMessage;

  /// Timestamp of last retry attempt
  final DateTime? lastRetryAt;

  /// Default constructor
  OfflineOperationModel({
    this.id = 0,
    required this.operationId,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.status = OperationStatus.pending,
    this.errorMessage,
    this.lastRetryAt,
  });

  /// Create an operation from a map
  factory OfflineOperationModel.fromMap(Map<String, dynamic> map) {
    return OfflineOperationModel(
      operationId: map['operationId'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => OperationType.sendMessage,
      ),
      data: map['data'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
      status: OperationStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => OperationStatus.pending,
      ),
      errorMessage: map['errorMessage'] as String?,
      lastRetryAt: map['lastRetryAt'] != null
          ? DateTime.parse(map['lastRetryAt'] as String)
          : null,
    );
  }

  /// Convert operation to a map
  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'status': status.name,
      'errorMessage': errorMessage,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
    };
  }

  /// Create a copy of this operation with changed fields
  OfflineOperationModel copyWith({
    int? id,
    String? operationId,
    OperationType? type,
    String? data,
    DateTime? timestamp,
    int? retryCount,
    OperationStatus? status,
    String? errorMessage,
    DateTime? lastRetryAt,
  }) {
    return OfflineOperationModel(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  /// Mark operation as processing
  OfflineOperationModel markAsProcessing() {
    return copyWith(
      status: OperationStatus.processing,
      lastRetryAt: DateTime.now(),
    );
  }

  /// Mark operation as completed
  OfflineOperationModel markAsCompleted() {
    return copyWith(
      status: OperationStatus.completed,
    );
  }

  /// Mark operation as failed and increment retry count
  OfflineOperationModel markAsFailed(String error) {
    return copyWith(
      status: OperationStatus.failed,
      retryCount: retryCount + 1,
      errorMessage: error,
      lastRetryAt: DateTime.now(),
    );
  }

  /// Reset operation to pending for retry
  OfflineOperationModel resetToPending() {
    return copyWith(
      status: OperationStatus.pending,
      errorMessage: null,
    );
  }

  /// Get the operation data as a map
  Map<String, dynamic> get dataMap {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Check if operation can be retried
  bool get canRetry => retryCount < 5 && status != OperationStatus.completed;

  /// Check if operation should be retried based on exponential backoff
  bool shouldRetry() {
    if (!canRetry) return false;
    if (lastRetryAt == null) return true;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final backoffSeconds = 1 << retryCount; // 2^retryCount
    final nextRetryTime = lastRetryAt!.add(Duration(seconds: backoffSeconds));
    
    return DateTime.now().isAfter(nextRetryTime);
  }

  /// Create a send message operation
  static OfflineOperationModel createSendMessage({
    required String operationId,
    required Map<String, dynamic> messageData,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.sendMessage,
      data: jsonEncode(messageData),
      timestamp: DateTime.now(),
    );
  }

  /// Create an edit message operation
  static OfflineOperationModel createEditMessage({
    required String operationId,
    required String messageId,
    required String newContent,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.editMessage,
      data: jsonEncode({
        'messageId': messageId,
        'content': newContent,
      }),
      timestamp: DateTime.now(),
    );
  }

  /// Create a delete message operation
  static OfflineOperationModel createDeleteMessage({
    required String operationId,
    required String messageId,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.deleteMessage,
      data: jsonEncode({
        'messageId': messageId,
      }),
      timestamp: DateTime.now(),
    );
  }

  /// Create a mark as read operation
  static OfflineOperationModel createMarkAsRead({
    required String operationId,
    required String conversationId,
    required int readCount,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.markAsRead,
      data: jsonEncode({
        'conversationId': conversationId,
        'readCount': readCount,
      }),
      timestamp: DateTime.now(),
    );
  }

  /// Create an add reaction operation
  static OfflineOperationModel createAddReaction({
    required String operationId,
    required String messageId,
    required String emojiCode,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.addReaction,
      data: jsonEncode({
        'messageId': messageId,
        'code': emojiCode,
      }),
      timestamp: DateTime.now(),
    );
  }

  /// Create a remove reaction operation
  static OfflineOperationModel createRemoveReaction({
    required String operationId,
    required String messageId,
    required String emojiCode,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.removeReaction,
      data: jsonEncode({
        'messageId': messageId,
        'code': emojiCode,
      }),
      timestamp: DateTime.now(),
    );
  }

  /// Create a create group operation
  static OfflineOperationModel createCreateGroup({
    required String operationId,
    required Map<String, dynamic> groupData,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.createGroup,
      data: jsonEncode(groupData),
      timestamp: DateTime.now(),
    );
  }

  /// Create an edit group operation
  static OfflineOperationModel createEditGroup({
    required String operationId,
    required Map<String, dynamic> groupData,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.editGroup,
      data: jsonEncode(groupData),
      timestamp: DateTime.now(),
    );
  }

  /// Create a leave conversation operation
  static OfflineOperationModel createLeaveConversation({
    required String operationId,
    required String conversationId,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.leaveConversation,
      data: jsonEncode({
        'conversationId': conversationId,
      }),
      timestamp: DateTime.now(),
    );
  }

  /// Create a delete conversation operation
  static OfflineOperationModel createDeleteConversation({
    required String operationId,
    required String conversationId,
  }) {
    return OfflineOperationModel(
      operationId: operationId,
      type: OperationType.deleteConversation,
      data: jsonEncode({
        'conversationId': conversationId,
      }),
      timestamp: DateTime.now(),
    );
  }
}
