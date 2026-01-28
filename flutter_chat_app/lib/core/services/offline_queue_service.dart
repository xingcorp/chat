import 'dart:async';

import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/services/offline_operation_processor.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/models/offline_operation_model.dart';
import 'package:flutter_chat_app/domain/services/i_offline_queue_service.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

/// Implementation of offline queue service
/// Manages operations that need to be synced when device comes online
@Singleton(as: IOfflineQueueService)
class OfflineQueueService implements IOfflineQueueService {
  final Isar _isar;
  final INetworkInfo _networkInfo;
  final AppLogger _logger;
  final OfflineOperationProcessor _processor;

  /// Stream controller for queue size changes
  final _queueSizeController = StreamController<int>.broadcast();

  /// Subscription for network connectivity changes
  StreamSubscription? _connectivitySubscription;

  /// Flag to prevent concurrent queue processing
  bool _isProcessing = false;

  /// Constructor
  OfflineQueueService({
    required Isar isar,
    required INetworkInfo networkInfo,
    required AppLogger logger,
    required OfflineOperationProcessor processor,
  })  : _isar = isar,
        _networkInfo = networkInfo,
        _logger = logger,
        _processor = processor {
    _initialize();
  }

  /// Initialize service and listen for connectivity changes
  void _initialize() {
    _logger.info('OfflineQueueService initialized');

    // Listen to network connectivity changes
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen(
      (results) async {
        final isConnected = results.isNotEmpty &&
            !results.every((r) => r.toString().contains('none'));

        if (isConnected) {
          _logger.debug('Device came online, processing queue...');
          await processQueue();
        }
      },
    );

    // Emit initial queue size
    _emitQueueSize();
  }

  @override
  Future<String> addOperation(OfflineOperationModel operation) async {
    try {
      _isar.write((isar) {
        isar.offlineOperationModels.put(operation);
      });

      _logger.debug('Added operation to queue: ${operation.type.name} (${operation.operationId})');
      _emitQueueSize();

      return operation.operationId;
    } catch (e) {
      _logger.error('Error adding operation to queue', e);
      rethrow;
    }
  }

  @override
  Future<List<OfflineOperationModel>> getPendingOperations() async {
    try {
      final pendingOps = _isar.offlineOperationModels
          .where()
          .statusEqualTo(OperationStatus.pending)
          .sortByTimestamp()
          .findAll();

      final failedOps = _isar.offlineOperationModels
          .where()
          .statusEqualTo(OperationStatus.failed)
          .sortByTimestamp()
          .findAll();

      // Combine and filter operations that can be retried
      final allOps = [...pendingOps, ...failedOps];
      final retryableOperations = allOps.where((op) {
        if (op.status == OperationStatus.pending) return true;
        if (op.status == OperationStatus.failed) return op.shouldRetry();
        return false;
      }).toList();

      // Sort by timestamp to maintain FIFO order
      retryableOperations.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _logger.debug('Found ${retryableOperations.length} pending operations');
      return retryableOperations;
    } catch (e) {
      _logger.error('Error getting pending operations', e);
      return [];
    }
  }

  @override
  Future<void> processQueue() async {
    // Prevent concurrent processing
    if (_isProcessing) {
      _logger.debug('Queue processing already in progress, skipping...');
      return;
    }

    // Check network connectivity
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      _logger.debug('Device is offline, skipping queue processing');
      return;
    }

    _isProcessing = true;
    _logger.info('Starting queue processing...');

    try {
      final operations = await getPendingOperations();

      if (operations.isEmpty) {
        _logger.debug('No pending operations to process');
        return;
      }

      _logger.info('Processing ${operations.length} operations...');

      for (final operation in operations) {
        try {
          // Mark as processing
          await _updateOperationStatus(
            operation.operationId,
            operation.markAsProcessing(),
          );

          // Process the operation based on type
          await _processOperation(operation);

          // Mark as completed
          await markAsCompleted(operation.operationId);

          _logger.debug('Operation completed: ${operation.type.name} (${operation.operationId})');
        } catch (e) {
          _logger.error(
            'Operation failed: ${operation.type.name} (${operation.operationId})',
            e,
          );

          // Mark as failed
          await markAsFailed(operation.operationId, e.toString());
        }
      }

      _logger.info('Queue processing completed');
    } catch (e) {
      _logger.error('Error processing queue', e);
    } finally {
      _isProcessing = false;
      _emitQueueSize();
    }
  }

  /// Process a single operation
  Future<void> _processOperation(OfflineOperationModel operation) async {
    // Delegate to processor service
    await _processor.processOperation(operation);
  }

  @override
  Future<void> markAsCompleted(String operationId) async {
    try {
      final operation = await _getOperationById(operationId);
      if (operation == null) {
        _logger.warning('Operation not found: $operationId');
        return;
      }

      await _updateOperationStatus(
        operationId,
        operation.markAsCompleted(),
      );

      _logger.debug('Operation marked as completed: $operationId');
      _emitQueueSize();
    } catch (e) {
      _logger.error('Error marking operation as completed', e);
      rethrow;
    }
  }

  @override
  Future<void> markAsFailed(String operationId, String errorMessage) async {
    try {
      final operation = await _getOperationById(operationId);
      if (operation == null) {
        _logger.warning('Operation not found: $operationId');
        return;
      }

      await _updateOperationStatus(
        operationId,
        operation.markAsFailed(errorMessage),
      );

      _logger.debug('Operation marked as failed: $operationId (retry: ${operation.retryCount + 1})');
      _emitQueueSize();
    } catch (e) {
      _logger.error('Error marking operation as failed', e);
      rethrow;
    }
  }

  @override
  Stream<int> get queueSizeStream => _queueSizeController.stream;

  @override
  Future<int> getQueueSize() async {
    try {
      final pendingCount = _isar.offlineOperationModels
          .where()
          .statusEqualTo(OperationStatus.pending)
          .count();

      final failedCount = _isar.offlineOperationModels
          .where()
          .statusEqualTo(OperationStatus.failed)
          .count();

      return pendingCount + failedCount;
    } catch (e) {
      _logger.error('Error getting queue size', e);
      return 0;
    }
  }

  @override
  Future<void> clearCompleted() async {
    try {
      _isar.write((isar) {
        final completedOps = isar.offlineOperationModels
            .where()
            .statusEqualTo(OperationStatus.completed)
            .findAll();

        final ids = completedOps.map((op) => op.id).toList();
        isar.offlineOperationModels.deleteAll(ids);
      });

      _logger.info('Cleared completed operations');
      _emitQueueSize();
    } catch (e) {
      _logger.error('Error clearing completed operations', e);
      rethrow;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      _isar.write((isar) {
        isar.offlineOperationModels.clear();
      });

      _logger.warning('Cleared all operations');
      _emitQueueSize();
    } catch (e) {
      _logger.error('Error clearing all operations', e);
      rethrow;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _queueSizeController.close();
    _logger.debug('OfflineQueueService disposed');
  }

  /// Get an operation by ID
  Future<OfflineOperationModel?> _getOperationById(String operationId) async {
    try {
      return _isar.offlineOperationModels
          .where()
          .operationIdEqualTo(operationId)
          .findFirst();
    } catch (e) {
      _logger.error('Error getting operation by ID', e);
      return null;
    }
  }

  /// Update operation status
  Future<void> _updateOperationStatus(
    String operationId,
    OfflineOperationModel updatedOperation,
  ) async {
    try {
      _isar.write((isar) {
        isar.offlineOperationModels.put(updatedOperation);
      });
    } catch (e) {
      _logger.error('Error updating operation status', e);
      rethrow;
    }
  }

  /// Emit current queue size
  Future<void> _emitQueueSize() async {
    final size = await getQueueSize();
    _queueSizeController.add(size);
  }
}
