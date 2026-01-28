import 'package:flutter_chat_app/data/models/offline_operation_model.dart';

/// Interface for offline queue service
/// Manages operations that need to be synced when device comes online
abstract class IOfflineQueueService {
  /// Add an operation to the queue
  /// Returns the operation ID
  Future<String> addOperation(OfflineOperationModel operation);

  /// Get all pending operations
  /// Returns operations in FIFO order (oldest first)
  Future<List<OfflineOperationModel>> getPendingOperations();

  /// Process the queue
  /// Attempts to execute all pending operations
  Future<void> processQueue();

  /// Mark an operation as completed
  Future<void> markAsCompleted(String operationId);

  /// Mark an operation as failed
  /// Increments retry count and updates error message
  Future<void> markAsFailed(String operationId, String errorMessage);

  /// Get the current queue size
  /// Returns a stream that emits the queue size whenever it changes
  Stream<int> get queueSizeStream;

  /// Get the current queue size (one-time value)
  Future<int> getQueueSize();

  /// Clear all completed operations
  Future<void> clearCompleted();

  /// Clear all operations (use with caution)
  Future<void> clearAll();

  /// Dispose resources
  void dispose();
}
