import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';

/// Types of background tasks that can be executed
enum IsolateTaskType {
  /// Image processing (resizing, compressing)
  imageProcessing,
  
  /// File operations (copying, moving)
  fileOperation,
  
  /// Data processing (parsing, formatting)
  dataProcessing,
  
  /// Encoding/decoding operations
  cryptoOperation,
  
  /// Search operations
  searchOperation,
  
  /// Text processing (analysis, formatting)
  textProcessing,
  
  /// AI/ML local operations
  aiProcessing,
  
  /// Fuzzy search operations
  fuzzySearch,
  
  /// Other custom tasks
  custom,
}

/// Priority levels for tasks
enum TaskPriority {
  /// Low priority tasks (can be delayed)
  low,
  
  /// Medium priority tasks (default)
  medium,
  
  /// High priority tasks
  high,
  
  /// Critical tasks (processed ASAP)
  critical
}

/// Message passed to isolate
class IsolateMessage {
  /// Type of task
  final IsolateTaskType taskType;
  
  /// Unique ID for tracking
  final String taskId;
  
  /// The data to process
  final dynamic data;
  
  /// Additional parameters
  final Map<String, dynamic>? params;
  
  /// Progress reporter port
  final SendPort? progressPort;
  
  /// Whether task is cancellable
  final bool isCancellable;
  
  IsolateMessage({
    required this.taskType,
    required this.taskId,
    required this.data,
    this.params,
    this.progressPort,
    this.isCancellable = false,
  });
}

/// Result returned from isolate
class IsolateResult {
  /// Type of task that was performed
  final IsolateTaskType taskType;
  
  /// Original task ID
  final String taskId;
  
  /// The processed result
  final dynamic result;
  
  /// Error if any occurred
  final dynamic error;
  
  /// Whether the task completed successfully
  bool get isSuccess => error == null;
  
  IsolateResult({
    required this.taskType,
    required this.taskId,
    this.result,
    this.error,
  });
}

/// Progress update from isolate
class IsolateProgress {
  /// Task ID
  final String taskId;
  
  /// Progress value (0.0 to 1.0)
  final double progress;
  
  /// Optional status message
  final String? message;
  
  IsolateProgress({
    required this.taskId,
    required this.progress,
    this.message,
  });
}

/// Represents a task pending execution
class _PendingTask {
  final IsolateMessage message;
  final Completer<IsolateResult> completer;
  final StreamController<IsolateProgress>? progressController;
  bool isCancelled = false;
  
  _PendingTask(this.message, this.completer, this.progressController);
}

/// A service for offloading heavy processing tasks to a background isolate
@singleton
class IsolateManager {
  static const String _isolateName = 'processing_isolate';
  
  /// The default number of isolates in the pool
  static const int _defaultMaxIsolates = 3;
  
  /// Number of isolates in the pool (calculated based on device)
  late final int _maxIsolates;
  
  /// List of isolates in the pool
  late final List<Isolate?> _isolates;
  
  /// List of send ports for communication with isolates
  late final List<SendPort?> _sendPorts;
  
  /// Receive ports for each isolate
  late final List<ReceivePort> _receivePorts;
  
  /// Health status of each isolate (last ping time)
  late final List<DateTime?> _isolateLastActive;
  
  /// Queue of pending tasks organized by priority
  final Map<TaskPriority, Queue<_PendingTask>> _taskQueues = {
    TaskPriority.low: Queue<_PendingTask>(),
    TaskPriority.medium: Queue<_PendingTask>(),
    TaskPriority.high: Queue<_PendingTask>(),
    TaskPriority.critical: Queue<_PendingTask>(),
  };
  
  /// Active tasks being processed by each isolate
  late final List<String?> _activeTaskIds;
  
  /// Map of task ID to its pending task
  final Map<String, _PendingTask> _pendingTasks = {};
  
  /// Timer for health check of isolates
  Timer? _healthCheckTimer;
  
  final PerformanceMonitor _performance;
  
  bool _isInitialized = false;
  
  IsolateManager(this._performance) {
    // Initialize with optimal number of isolates based on device
    _maxIsolates = _calculateOptimalIsolateCount();
    _isolates = List.filled(_maxIsolates, null);
    _sendPorts = List.filled(_maxIsolates, null);
    _receivePorts = List.generate(_maxIsolates, (_) => ReceivePort());
    _isolateLastActive = List.filled(_maxIsolates, null);
    _activeTaskIds = List.filled(_maxIsolates, null);
  }
  
  /// Calculate optimal number of isolates based on available CPUs
  int _calculateOptimalIsolateCount() {
    // Get number of processors, with fallback to default
    int cpuCores;
    try {
      cpuCores = Platform.numberOfProcessors;
    } catch (e) {
      cpuCores = _defaultMaxIsolates;
    }
    
    // Use at most cpuCores-1 to avoid starving main thread
    // but minimum 1 and maximum 6
    return cpuCores > 1 
        ? (cpuCores - 1).clamp(1, 6) 
        : 1;
  }
  
  /// Initialize the isolate manager with a pool of isolates
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize isolates in the pool
      for (int i = 0; i < _maxIsolates; i++) {
        await _initializeIsolate(i);
      }
      
      _isInitialized = true;
      
      // Start background health check
      _startHealthCheck();
      
      // Start task processing
      _processTaskQueue();
    } catch (e) {
      debugPrint('Failed to initialize isolate pool: $e');
      _isInitialized = false;
      
      // Kill any isolates that were created
      for (int i = 0; i < _maxIsolates; i++) {
        if (_isolates[i] != null) {
          _isolates[i]!.kill(priority: Isolate.immediate);
          _isolates[i] = null;
        }
      }
    }
  }
  
  /// Start periodic health check of isolates
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkIsolateHealth();
    });
  }
  
  /// Check health of all isolates and restart any that appear to be dead
  Future<void> _checkIsolateHealth() async {
    final now = DateTime.now();
    
    for (int i = 0; i < _maxIsolates; i++) {
      // Skip if no isolate at this index
      if (_isolates[i] == null) continue;
      
      // Check if isolate has been inactive for too long
      final lastActive = _isolateLastActive[i];
      if (lastActive != null && now.difference(lastActive).inMinutes > 5) {
        debugPrint('Isolate $i appears to be dead, restarting...');
        
        // Restart this isolate
        await _restartIsolate(i);
      } else if (_sendPorts[i] != null) {
        // Ping the isolate to check it's responsive
        try {
          _sendPorts[i]!.send('ping');
        } catch (e) {
          debugPrint('Error sending ping to isolate $i: $e, restarting...');
          await _restartIsolate(i);
        }
      }
    }
  }
  
  /// Restart a specific isolate
  Future<void> _restartIsolate(int index) async {
    // Kill existing isolate
    if (_isolates[index] != null) {
      try {
        _isolates[index]!.kill(priority: Isolate.immediate);
      } catch (e) {
        // Ignore errors when killing
      }
      _isolates[index] = null;
    }
    
    // Close and reset the receive port
    _receivePorts[index].close();
    _receivePorts[index] = ReceivePort();
    
    // Reset the send port
    _sendPorts[index] = null;
    
    // Clear active task
    final activeTaskId = _activeTaskIds[index];
    if (activeTaskId != null) {
      final task = _pendingTasks[activeTaskId];
      if (task != null) {
        // Requeue the task if it wasn't cancelled
        if (!task.isCancelled) {
          _taskQueues[TaskPriority.high]!.addFirst(task);
        }
        _pendingTasks.remove(activeTaskId);
      }
      _activeTaskIds[index] = null;
    }
    
    // Initialize the isolate again
    try {
      await _initializeIsolate(index);
      
      // Process queue immediately if there are pending tasks
      _processTaskQueue();
    } catch (e) {
      debugPrint('Failed to restart isolate $index: $e');
    }
  }
  
  /// Initialize a single isolate in the pool
  Future<void> _initializeIsolate(int index) async {
    try {
      final instanceName = '${_isolateName}_$index';
      
      // Unregister if already registered
      if (IsolateNameServer.lookupPortByName(instanceName) != null) {
        IsolateNameServer.removePortNameMapping(instanceName);
      }
      
      // Register the receive port for this isolate
      IsolateNameServer.registerPortWithName(
        _receivePorts[index].sendPort,
        instanceName,
      );
      
      // Listen for messages from this isolate
      _receivePorts[index].listen((message) => _handleIsolateMessage(message, index));
      
      // Spawn the isolate
      _isolates[index] = await Isolate.spawn(
        _isolateEntryPoint,
        instanceName,
        debugName: instanceName,
      );
      
      // Wait for the isolate to send its SendPort
      final completer = Completer<SendPort>();
      late StreamSubscription subscription;
      subscription = _receivePorts[index].listen((message) {
        if (message is SendPort && !completer.isCompleted) {
          completer.complete(message);
          subscription.cancel();
        }
      });
      
      // Set timeout for getting the SendPort
      _sendPorts[index] = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Failed to initialize isolate $index');
        },
      );
      
      // Mark isolate as active now
      _isolateLastActive[index] = DateTime.now();
    } catch (e) {
      debugPrint('Failed to initialize isolate $index: $e');
      
      // Clean up resources for this isolate
      if (_isolates[index] != null) {
        _isolates[index]!.kill(priority: Isolate.immediate);
        _isolates[index] = null;
      }
      
      final instanceName = '${_isolateName}_$index';
      IsolateNameServer.removePortNameMapping(instanceName);
      
      rethrow;
    }
  }
  
  /// Process data in a background isolate from the pool
  /// Falls back to the main thread if isolates are not available
  Future<IsolateResult> processInBackground({
    required IsolateTaskType taskType,
    required dynamic data,
    String? taskId,
    Map<String, dynamic>? params,
    TaskPriority priority = TaskPriority.medium,
    StreamController<IsolateProgress>? progressController,
    bool enableCancellation = false,
  }) async {
    final id = taskId ?? 'task_${DateTime.now().millisecondsSinceEpoch}_${_pendingTasks.length}';
    
    // Start performance trace
    _performance.startTrace('isolate_task_$id');
    
    try {
      // Create a progress port if progress reporting is requested
      ReceivePort? progressPort;
      StreamSubscription? progressSubscription;
      
      if (progressController != null) {
        progressPort = ReceivePort();
        progressSubscription = progressPort.listen((progress) {
          if (progress is Map<String, dynamic>) {
            final update = IsolateProgress(
              taskId: id,
              progress: progress['progress'] as double,
              message: progress['message'] as String?,
            );
            progressController.add(update);
          }
        });
      }
      
      // If isolate pool is not initialized, process on main thread
      if (!_isInitialized || _sendPorts.every((port) => port == null)) {
        final result = await _processOnMainThread(
          taskType: taskType,
          taskId: id,
          data: data is TransferableTypedData ? data.materialize().asUint8List() : data,
          params: params,
          progressPort: progressPort?.sendPort,
        );
        
        // Cleanup progress port
        await progressSubscription?.cancel();
        progressPort?.close();
        
        _performance.stopTrace('isolate_task_$id');
        return result;
      }
      
      // Create a completer to wait for the result
      final completer = Completer<IsolateResult>();
      
      // Prepare the message to send to isolate
      final message = IsolateMessage(
        taskType: taskType,
        taskId: id,
        data: data,
        params: params,
        progressPort: progressPort?.sendPort,
        isCancellable: enableCancellation,
      );
      
      // Create the pending task object
      final pendingTask = _PendingTask(message, completer, progressController);
      _pendingTasks[id] = pendingTask;
      
      // Queue the task with its priority
      _taskQueues[priority]!.add(pendingTask);
      
      // Try to process the queue immediately
      _processTaskQueue();
      
      // Wait for the result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingTasks.remove(id);
          throw TimeoutException('Processing timed out');
        },
      );
      
      // Cleanup progress port
      await progressSubscription?.cancel();
      progressPort?.close();
      
      _performance.stopTrace('isolate_task_$id');
      return result;
    } catch (e) {
      _performance.stopTrace('isolate_task_$id');
      
      // Return error result
      return IsolateResult(
        taskType: taskType,
        taskId: id,
        error: e.toString(),
      );
    }
  }
  
  /// Cancel a running task if possible
  Future<bool> cancelTask(String taskId) async {
    final task = _pendingTasks[taskId];
    if (task == null) return false;
    
    // Mark as cancelled
    task.isCancelled = true;
    
    // If not yet started, remove from queue
    bool removed = false;
    for (final queue in _taskQueues.values) {
      final iterator = queue.iterator;
      while (iterator.moveNext()) {
        if (iterator.current.message.taskId == taskId) {
          queue.remove(iterator.current);
          removed = true;
          break;
        }
      }
      if (removed) break;
    }
    
    // If already running and cancellable, try to signal cancellation
    if (!removed) {
      for (int i = 0; i < _maxIsolates; i++) {
        if (_activeTaskIds[i] == taskId && _sendPorts[i] != null) {
          try {
            _sendPorts[i]!.send({'type': 'cancel', 'taskId': taskId});
            // We don't know if cancellation succeeded yet, so return true
            return true;
          } catch (e) {
            debugPrint('Error sending cancellation: $e');
          }
        }
      }
    }
    
    // If it was in a queue and we removed it, or if we sent a cancellation
    // signal, complete with cancelled error
    if (removed) {
      task.completer.complete(IsolateResult(
        taskType: task.message.taskType,
        taskId: taskId,
        error: 'Task cancelled',
      ));
      _pendingTasks.remove(taskId);
      return true;
    }
    
    return false;
  }
  
  /// Process the task queue based on priorities
  void _processTaskQueue() {
    // Priorities in order (critical first)
    final priorities = [
      TaskPriority.critical,
      TaskPriority.high, 
      TaskPriority.medium,
      TaskPriority.low,
    ];
    
    // Try to find an available isolate
    for (int i = 0; i < _maxIsolates; i++) {
      // Skip if this isolate is not ready or already processing
      if (_sendPorts[i] == null || _activeTaskIds[i] != null) continue;
      
      // Find the highest priority non-empty queue
      _PendingTask? task;
      for (final priority in priorities) {
        if (_taskQueues[priority]!.isNotEmpty) {
          task = _taskQueues[priority]!.removeFirst();
          break;
        }
      }
      
      // If we found a task, send it to the isolate
      if (task != null && !task.isCancelled) {
        final taskId = task.message.taskId;
        _activeTaskIds[i] = taskId;
        
        // Optimize data transfer for large byte arrays
        dynamic dataToSend = task.message.data;
        if (dataToSend is Uint8List && dataToSend.length > 100 * 1024) {
          dataToSend = TransferableTypedData.fromList([dataToSend]);
        }
        
        final messageToSend = IsolateMessage(
          taskType: task.message.taskType,
          taskId: taskId,
          data: dataToSend,
          params: task.message.params,
          progressPort: task.message.progressPort,
          isCancellable: task.message.isCancellable,
        );
        
        try {
          // Send the message to the isolate
          _sendPorts[i]!.send(messageToSend);
          
          // Update last active timestamp
          _isolateLastActive[i] = DateTime.now();
        } catch (e) {
          debugPrint('Error sending task to isolate: $e');
          
          // Mark isolate as unavailable
          _sendPorts[i] = null;
          _activeTaskIds[i] = null;
          
          // Requeue the task
          _taskQueues[TaskPriority.high]!.addFirst(task);
          
          // Restart isolate in background
          _restartIsolate(i);
        }
      }
    }
    
    // Process on main thread if all isolates are busy
    if (_sendPorts.every((port) => port == null) || 
        _activeTaskIds.every((id) => id != null)) {
      _processHighPriorityTasksOnMainThread();
    }
  }
  
  /// Process high priority tasks on main thread if all isolates are busy
  void _processHighPriorityTasksOnMainThread() {
    // Only process critical tasks on main thread when isolates are busy
    if (_taskQueues[TaskPriority.critical]!.isEmpty) return;
    
    final task = _taskQueues[TaskPriority.critical]!.removeFirst();
    if (task.isCancelled) return;
    
    final taskId = task.message.taskId;
    
    // Process on main thread and complete the completer
    _processOnMainThread(
      taskType: task.message.taskType,
      taskId: taskId,
      data: task.message.data is TransferableTypedData ? 
            task.message.data.materialize().asUint8List() : 
            task.message.data,
      params: task.message.params,
      progressPort: task.message.progressPort,
    ).then((result) {
      task.completer.complete(result);
      _pendingTasks.remove(taskId);
    });
  }
  
  /// Handle messages received from isolates
  void _handleIsolateMessage(dynamic message, int isolateIndex) {
    // Update isolate last active timestamp
    _isolateLastActive[isolateIndex] = DateTime.now();
    
    if (message == 'pong') {
      // Ping response, isolate is alive
      return;
    }
    
    if (message is IsolateResult) {
      // Find the pending task for this result
      final taskId = message.taskId;
      final task = _pendingTasks[taskId];
      
      // Mark this isolate as available
      _activeTaskIds[isolateIndex] = null;
      
      // Complete the task if it hasn't been cancelled
      if (task != null && !task.isCancelled) {
        task.completer.complete(message);
        _pendingTasks.remove(taskId);
      }
      
      // Process the next task in queue
      _processTaskQueue();
    }
  }
  
  /// Process a task on the main thread (fallback)
  Future<IsolateResult> _processOnMainThread({
    required IsolateTaskType taskType,
    required String taskId,
    required dynamic data,
    Map<String, dynamic>? params,
    SendPort? progressPort,
  }) async {
    try {
      // Process according to task type
      dynamic result;
      
      // Helper for reporting progress
      void reportProgress(double progress, [String? message]) {
        progressPort?.send({
          'progress': progress,
          'message': message,
        });
      }
      
      // Dummy cancellation check for consistency with isolate processing
      bool checkCancelled() => false;
      
      switch (taskType) {
        case IsolateTaskType.imageProcessing:
          result = await compute(_processImage, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.fileOperation:
          result = await compute(_processFile, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.dataProcessing:
          result = await compute(_processData, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.cryptoOperation:
          result = await compute(_processCrypto, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.searchOperation:
          result = await compute(_processSearch, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.textProcessing:
          result = await compute(_processText, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.aiProcessing:
          result = await compute(_processAI, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.fuzzySearch:
          result = await compute(_processFuzzySearch, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        case IsolateTaskType.custom:
          result = await compute(_processCustom, {
            'data': data,
            'params': params,
            'reportProgress': reportProgress,
            'isCancelled': checkCancelled,
          });
          break;
          
        default:
          throw Exception('Unknown task type');
      }
      
      return IsolateResult(
        taskType: taskType,
        taskId: taskId,
        result: result,
      );
    } catch (e) {
      return IsolateResult(
        taskType: taskType,
        taskId: taskId,
        error: e.toString(),
      );
    }
  }
  
  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    
    for (int i = 0; i < _maxIsolates; i++) {
      if (_isolates[i] != null) {
        _isolates[i]!.kill(priority: Isolate.immediate);
      }
      
      _receivePorts[i].close();
      
      final instanceName = '${_isolateName}_$i';
      IsolateNameServer.removePortNameMapping(instanceName);
    }
    
    _isInitialized = false;
  }
}

// ISOLATE IMPLEMENTATION

/// Entry point for the isolate
void _isolateEntryPoint(String name) {
  // Create a receive port for this isolate
  final receivePort = ReceivePort();
  
  // Get the main isolate's send port from the name server
  final SendPort? mainSendPort = IsolateNameServer.lookupPortByName(name);
  
  if (mainSendPort == null) {
    receivePort.close();
    return;
  }
  
  // Send this isolate's send port to the main isolate
  mainSendPort.send(receivePort.sendPort);
  
  // Keep track of cancelable tasks
  final Map<String, bool> cancelledTasks = {};
  
  // Listen for tasks from the main isolate
  receivePort.listen((message) {
    if (message is IsolateMessage) {
      _processMessage(message, mainSendPort, cancelledTasks);
    } else if (message is Map<String, dynamic> && message['type'] == 'cancel') {
      // Handle cancellation request
      final taskId = message['taskId'] as String;
      cancelledTasks[taskId] = true;
    } else if (message == 'ping') {
      // Respond to ping with pong for health checks
      mainSendPort.send('pong');
    }
  });
}

/// Process a message in the isolate and send the result back
Future<void> _processMessage(
  IsolateMessage message, 
  SendPort sendPort,
  Map<String, bool> cancelledTasks
) async {
  // Extract data, handle TransferableTypedData
  final data = message.data is TransferableTypedData 
      ? message.data.materialize().asUint8List()
      : message.data;
  
  // Get progress port if available
  final progressPort = message.progressPort;
  
  // Helper for reporting progress
  void reportProgress(double progress, [String? statusMessage]) {
    progressPort?.send({
      'progress': progress,
      'message': statusMessage,
    });
  }
  
  // Check for cancellation
  bool isCancelled() {
    return cancelledTasks[message.taskId] == true;
  }
  
  try {
    dynamic result;
    
    // Process based on task type
    switch (message.taskType) {
      case IsolateTaskType.imageProcessing:
        result = await _processImage({
          'data': data,
          'params': message.params,
          'reportProgress': reportProgress,
          'isCancelled': isCancelled,
        });
        break;
        
      case IsolateTaskType.fileOperation:
        result = await _processFile({
          'data': data,
          'params': message.params,
          'reportProgress': reportProgress,
          'isCancelled': isCancelled,
        });
        break;
        
      case IsolateTaskType.dataProcessing:
        result = await _processData({
          'data': data,
          'params': message.params,
          'progressPort': progressPort,
        });
        break;
        
      case IsolateTaskType.cryptoOperation:
        result = await _processCrypto({
          'data': data,
          'params': message.params,
          'progressPort': progressPort,
        });
        break;
        
      case IsolateTaskType.searchOperation:
        result = await _processSearch({
          'data': data,
          'params': message.params,
          'progressPort': progressPort,
        });
        break;
        
      case IsolateTaskType.textProcessing:
        result = await _processText({
          'data': data,
          'params': message.params,
          'progressPort': progressPort,
        });
        break;
        
      case IsolateTaskType.aiProcessing:
        result = await _processAI({
          'data': data,
          'params': message.params,
          'progressPort': progressPort,
        });
        break;
        
      case IsolateTaskType.fuzzySearch:
        result = await _processFuzzySearch({
          'data': data,
          'params': message.params,
          'progressPort': progressPort,
        });
        break;
        
      case IsolateTaskType.custom:
        result = await _processCustom({
          'data': data,
          'params': message.params,
          'progressPort': progressPort,
        });
        break;
    }
    
    // Clean up
    cancelledTasks.remove(message.taskId);
    
    // Check if cancelled during processing
    if (isCancelled()) {
      sendPort.send(IsolateResult(
        taskType: message.taskType,
        taskId: message.taskId,
        error: 'Task was cancelled',
      ));
      return;
    }
    
    // Send the result back to the main isolate
    final isolateResult = IsolateResult(
      taskType: message.taskType,
      taskId: message.taskId,
      result: result,
    );
    
    sendPort.send(isolateResult);
  } catch (e) {
    // Clean up
    cancelledTasks.remove(message.taskId);
    
    // Send the error back to the main isolate
    final isolateResult = IsolateResult(
      taskType: message.taskType,
      taskId: message.taskId,
      error: e.toString(),
    );
    
    sendPort.send(isolateResult);
  }
}

// PROCESSING FUNCTIONS

/// Process image data
Future<dynamic> _processImage(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  // Báo cáo bắt đầu
  reportProgress?.call(0.0, 'Khởi tạo xử lý hình ảnh');
  
  // Trích xuất thông tin từ params
  final operation = params?['operation'] as String? ?? 'resize';
  final quality = params?['quality'] as int? ?? 80;
  
  // Giả lập xử lý nhiều bước có thể hủy bỏ
  for (int i = 0; i < 10; i++) {
    // Kiểm tra hủy bỏ
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    // Giả lập xử lý
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Báo cáo tiến trình
    reportProgress?.call((i + 1) / 10, 'Xử lý phần ${i + 1}/10');
  }
  
  // Báo cáo hoàn thành
  reportProgress?.call(1.0, 'Xử lý hình ảnh hoàn tất');
  
  Map<String, dynamic> result = {
    'processed': true,
    'operation': operation,
  };
  
  if (data is Map<String, dynamic> && data.containsKey('size')) {
    final originalSize = data['size'] as num;
    result['original_size'] = originalSize;
    
    // Giả lập kết quả nén
    if (operation == 'compress') {
      // Kích thước mới phụ thuộc vào chất lượng
      result['new_size'] = originalSize * (quality / 100);
      result['compression_ratio'] = (100 - quality) / 100;
    } 
    // Giả lập kết quả resize
    else if (operation == 'resize') {
      final scale = params?['scale'] as double? ?? 0.8;
      result['new_size'] = originalSize * scale * scale; // Area reduces by scale²
      result['scale_factor'] = scale;
    }
  }
  
  return result;
}

/// Process file operations
Future<dynamic> _processFile(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  reportProgress?.call(0.0, 'Bắt đầu xử lý tệp');
  
  // Implementation for file operations
  // For example, copying, moving, or renaming files
  
  // Simulated processing with progress
  final steps = 5;
  for (int i = 0; i < steps; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    await Future.delayed(const Duration(milliseconds: 100));
    reportProgress?.call((i + 1) / steps, 'Xử lý tệp: ${(i + 1) / steps * 100}%');
  }
  
  reportProgress?.call(1.0, 'Hoàn thành xử lý tệp');
  
  return {
    'success': true,
    'path': data['path'],
  };
}

/// Process data
Future<dynamic> _processData(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  reportProgress?.call(0.0, 'Bắt đầu xử lý dữ liệu');
  
  // Phân tích dữ liệu theo số lượng phần tử
  if (data is List) {
    final total = data.length;
    for (int i = 0; i < total; i += max(1, total ~/ 10)) {
      if (isCancelled?.call() == true) {
        return {'cancelled': true};
      }
      
      await Future.delayed(const Duration(milliseconds: 20));
      reportProgress?.call(i / total, 'Xử lý phần tử ${i + 1}/$total');
    }
    
    reportProgress?.call(1.0, 'Hoàn thành xử lý dữ liệu');
    return {
      'processed': true,
      'count': total,
      'summary': 'Đã xử lý $total phần tử',
    };
  } 
  // Phân tích dữ liệu đơn lẻ
  else {
    for (int i = 0; i < 5; i++) {
      if (isCancelled?.call() == true) {
        return {'cancelled': true};
      }
      
      await Future.delayed(const Duration(milliseconds: 50));
      reportProgress?.call((i + 1) / 5, 'Xử lý dữ liệu ${(i + 1) * 20}%');
    }
    
    reportProgress?.call(1.0, 'Hoàn thành xử lý dữ liệu');
    return {
      'processed': true,
      'type': data?.runtimeType.toString() ?? 'null',
    };
  }
}

/// Process crypto operations
Future<dynamic> _processCrypto(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  final operation = params?['operation'] as String? ?? 'encrypt';
  final algorithm = params?['algorithm'] as String? ?? 'AES';
  
  reportProgress?.call(0.0, 'Khởi tạo $operation với $algorithm');
  
  // Giả lập các bước của thao tác mã hóa
  final totalSteps = operation == 'hash' ? 3 : 5;
  
  for (int i = 0; i < totalSteps; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    // Giả lập thời gian xử lý
    await Future.delayed(const Duration(milliseconds: 80));
    reportProgress?.call((i + 1) / totalSteps, 
      'Đang $operation: bước ${i + 1}/$totalSteps');
  }
  
  reportProgress?.call(1.0, 'Hoàn thành $operation');
  
  return {
    'processed': true,
    'operation': operation,
    'algorithm': algorithm,
  };
}

/// Process search operations
Future<dynamic> _processSearch(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  reportProgress?.call(0.0, 'Chuẩn bị tìm kiếm');
  
  final query = params?['query'] as String? ?? '';
  final caseSensitive = params?['caseSensitive'] as bool? ?? false;
  
  // Giả lập chuẩn bị index/dữ liệu cho tìm kiếm
  await Future.delayed(const Duration(milliseconds: 100));
  reportProgress?.call(0.2, 'Đã chuẩn bị dữ liệu tìm kiếm');
  
  if (isCancelled?.call() == true) {
    return {'cancelled': true};
  }
  
  // Giả lập quá trình tìm kiếm
  final searchSteps = data is List ? data.length : 5;
  final maxSteps = min(20, searchSteps); // Giới hạn số bước để tránh quá nhiều
  
  for (int i = 0; i < maxSteps; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true, 'progress': i / maxSteps};
    }
    
    await Future.delayed(const Duration(milliseconds: 30));
    reportProgress?.call(0.2 + 0.8 * (i + 1) / maxSteps, 
      'Đang tìm kiếm: ${((i + 1) / maxSteps * 100).toStringAsFixed(0)}%');
  }
  
  reportProgress?.call(1.0, 'Tìm kiếm hoàn tất');
  
  // Trả về kết quả giả lập
  return {
    'processed': true,
    'query': query,
    'caseSensitive': caseSensitive,
    'resultsCount': 5, // Giả lập tìm thấy 5 kết quả
  };
}

/// Process text processing
Future<dynamic> _processText(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  reportProgress?.call(0.0, 'Khởi tạo xử lý văn bản');
  
  final operation = params?['operation'] as String? ?? 'analyze';
  
  // Xác định số lượng bước dựa trên loại thao tác
  int steps;
  switch (operation) {
    case 'analyze':
      steps = 8;
      break;
    case 'format':
      steps = 5;
      break;
    case 'translate':
      steps = 10;
      break;
    default:
      steps = 5;
  }
  
  // Giả lập xử lý văn bản
  for (int i = 0; i < steps; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    await Future.delayed(const Duration(milliseconds: 40));
    reportProgress?.call((i + 1) / steps, 
      '${_getTextOperationDescription(operation)}: ${((i + 1) / steps * 100).toStringAsFixed(0)}%');
  }
  
  reportProgress?.call(1.0, 'Xử lý văn bản hoàn tất');
  
  return {
    'processed': true,
    'operation': operation,
  };
}

/// Get description for text operation
String _getTextOperationDescription(String operation) {
  switch (operation) {
    case 'analyze':
      return 'Phân tích văn bản';
    case 'format':
      return 'Định dạng văn bản';
    case 'translate':
      return 'Dịch văn bản';
    default:
      return 'Xử lý văn bản';
  }
}

/// Process AI/ML operations
Future<dynamic> _processAI(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  final model = params?['model'] as String? ?? 'default';
  
  reportProgress?.call(0.0, 'Chuẩn bị mô hình $model');
  
  // Giả lập tải mô hình
  for (int i = 0; i < 3; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    await Future.delayed(const Duration(milliseconds: 200));
    reportProgress?.call((i + 1) / 10, 'Đang tải mô hình: ${(i + 1) * 10}%');
  }
  
  // Giả lập xử lý dữ liệu
  for (int i = 0; i < 7; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    await Future.delayed(const Duration(milliseconds: 100));
    final progressPercent = 30 + ((i + 1) / 7 * 70);
    reportProgress?.call(0.3 + 0.7 * (i + 1) / 7, 'Đang xử lý: ${progressPercent.toStringAsFixed(0)}%');
  }
  
  reportProgress?.call(1.0, 'Xử lý AI hoàn tất');
  
  return {
    'processed': true,
    'model': model,
    'confidence': 0.87,
  };
}

/// Process fuzzy search
Future<dynamic> _processFuzzySearch(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  final query = params?['query'] as String? ?? '';
  final threshold = params?['threshold'] as double? ?? 0.7;
  
  reportProgress?.call(0.0, 'Chuẩn bị tìm kiếm mờ');
  
  // Giả lập chuẩn bị dữ liệu
  await Future.delayed(const Duration(milliseconds: 100));
  reportProgress?.call(0.1, 'Đã chuẩn bị dữ liệu');
  
  if (isCancelled?.call() == true) {
    return {'cancelled': true};
  }
  
  // Giả lập tìm kiếm mờ
  for (int i = 0; i < 9; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    await Future.delayed(const Duration(milliseconds: 50));
    reportProgress?.call(0.1 + 0.9 * (i + 1) / 9, 'Đang tìm kiếm mờ: ${(10 + (i + 1) / 9 * 90).toStringAsFixed(0)}%');
  }
  
  reportProgress?.call(1.0, 'Tìm kiếm mờ hoàn tất');
  
  return {
    'processed': true,
    'query': query,
    'threshold': threshold,
    'matches': 3, // Giả lập số kết quả phù hợp
  };
}

/// Process custom operations
Future<dynamic> _processCustom(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  final reportProgress = args['reportProgress'] as Function?;
  final isCancelled = args['isCancelled'] as Function?;
  
  final customOperation = params?['customOperation'] as String? ?? 'unknown';
  
  reportProgress?.call(0.0, 'Bắt đầu xử lý tuỳ chỉnh: $customOperation');
  
  // Giả lập xử lý tuỳ chỉnh
  for (int i = 0; i < 5; i++) {
    if (isCancelled?.call() == true) {
      return {'cancelled': true};
    }
    
    await Future.delayed(const Duration(milliseconds: 100));
    reportProgress?.call((i + 1) / 5, 'Xử lý tuỳ chỉnh: ${(i + 1) * 20}%');
  }
  
  reportProgress?.call(1.0, 'Xử lý tuỳ chỉnh hoàn tất');
  
  return {
    'processed': true,
    'customOperation': customOperation,
  };
} 