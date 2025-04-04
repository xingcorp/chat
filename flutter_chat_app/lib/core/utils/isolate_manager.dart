import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

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
  
  /// Other custom tasks
  custom,
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
  
  IsolateMessage({
    required this.taskType,
    required this.taskId,
    required this.data,
    this.params,
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

/// A service for offloading heavy processing tasks to a background isolate
@singleton
class IsolateManager {
  static const String _isolateName = 'processing_isolate';
  
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  final Map<String, Completer<IsolateResult>> _pendingTasks = {};
  final PerformanceMonitor _performance;
  
  bool _isInitialized = false;
  
  IsolateManager(this._performance);
  
  /// Initialize the isolate manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Register the receive port for isolate communication
      final instanceName = _isolateName;
      IsolateNameServer.registerPortWithName(
        _receivePort.sendPort,
        instanceName,
      );
      
      // Listen for messages from the isolate
      _receivePort.listen(_handleIsolateMessage);
      
      // Spawn the isolate
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        instanceName,
        debugName: instanceName,
      );
      
      // Wait for the isolate to send its SendPort
      final completer = Completer<SendPort>();
      late StreamSubscription subscription;
      subscription = _receivePort.listen((message) {
        if (message is SendPort && !completer.isCompleted) {
          completer.complete(message);
          subscription.cancel();
        }
      });
      
      // Set timeout for getting the SendPort
      _sendPort = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Failed to initialize isolate');
        },
      );
      
      _isInitialized = true;
    } catch (e) {
      // Fall back to main thread execution if isolate fails
      debugPrint('Failed to initialize isolate: $e');
      _isInitialized = false;
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }
  
  /// Process data in the background isolate
  /// Falls back to the main thread if isolate is not available
  Future<IsolateResult> processInBackground({
    required IsolateTaskType taskType,
    required dynamic data,
    String? taskId,
    Map<String, dynamic>? params,
  }) async {
    final id = taskId ?? 'task_${DateTime.now().millisecondsSinceEpoch}_${_pendingTasks.length}';
    
    // Start performance trace
    _performance.startTrace('isolate_task_$id');
    
    try {
      // If isolate is not initialized, process on main thread
      if (!_isInitialized || _sendPort == null) {
        final result = await _processOnMainThread(
          taskType: taskType,
          taskId: id,
          data: data,
          params: params,
        );
        
        _performance.stopTrace('isolate_task_$id');
        return result;
      }
      
      // Prepare the message to send to isolate
      final message = IsolateMessage(
        taskType: taskType,
        taskId: id,
        data: data,
        params: params,
      );
      
      // Create a completer to wait for the result
      final completer = Completer<IsolateResult>();
      _pendingTasks[id] = completer;
      
      // Send the message to the isolate
      _sendPort!.send(message);
      
      // Wait for the result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingTasks.remove(id);
          throw TimeoutException('Processing timed out');
        },
      );
      
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
  
  /// Process the data on the main thread as fallback
  Future<IsolateResult> _processOnMainThread({
    required IsolateTaskType taskType,
    required String taskId,
    required dynamic data,
    Map<String, dynamic>? params,
  }) async {
    try {
      // Process according to task type
      dynamic result;
      
      switch (taskType) {
        case IsolateTaskType.imageProcessing:
          result = await compute(_processImage, {
            'data': data,
            'params': params,
          });
          break;
          
        case IsolateTaskType.fileOperation:
          result = await compute(_processFile, {
            'data': data,
            'params': params,
          });
          break;
          
        case IsolateTaskType.dataProcessing:
          result = await compute(_processData, {
            'data': data,
            'params': params,
          });
          break;
          
        case IsolateTaskType.cryptoOperation:
          result = await compute(_processCrypto, {
            'data': data,
            'params': params,
          });
          break;
          
        case IsolateTaskType.searchOperation:
          result = await compute(_processSearch, {
            'data': data,
            'params': params,
          });
          break;
          
        case IsolateTaskType.custom:
          result = await compute(_processCustom, {
            'data': data,
            'params': params,
          });
          break;
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
  
  /// Handle messages coming back from the isolate
  void _handleIsolateMessage(dynamic message) {
    if (message is IsolateResult) {
      final completer = _pendingTasks.remove(message.taskId);
      if (completer != null && !completer.isCompleted) {
        completer.complete(message);
      }
    }
  }
  
  /// Dispose the isolate manager
  void dispose() {
    if (_isolate != null) {
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
    
    IsolateNameServer.removePortNameMapping(_isolateName);
    _receivePort.close();
    
    // Complete any pending tasks with error
    for (final task in _pendingTasks.values) {
      if (!task.isCompleted) {
        task.completeError('Isolate manager was disposed');
      }
    }
    _pendingTasks.clear();
    
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
  
  // Listen for tasks from the main isolate
  receivePort.listen((message) {
    if (message is IsolateMessage) {
      _processMessage(message, mainSendPort);
    }
  });
}

/// Process a message in the isolate and send the result back
Future<void> _processMessage(IsolateMessage message, SendPort sendPort) async {
  try {
    dynamic result;
    
    // Process based on task type
    switch (message.taskType) {
      case IsolateTaskType.imageProcessing:
        result = await _processImage({
          'data': message.data,
          'params': message.params,
        });
        break;
        
      case IsolateTaskType.fileOperation:
        result = await _processFile({
          'data': message.data,
          'params': message.params,
        });
        break;
        
      case IsolateTaskType.dataProcessing:
        result = await _processData({
          'data': message.data,
          'params': message.params,
        });
        break;
        
      case IsolateTaskType.cryptoOperation:
        result = await _processCrypto({
          'data': message.data,
          'params': message.params,
        });
        break;
        
      case IsolateTaskType.searchOperation:
        result = await _processSearch({
          'data': message.data,
          'params': message.params,
        });
        break;
        
      case IsolateTaskType.custom:
        result = await _processCustom({
          'data': message.data,
          'params': message.params,
        });
        break;
    }
    
    // Send the result back to the main isolate
    final isolateResult = IsolateResult(
      taskType: message.taskType,
      taskId: message.taskId,
      result: result,
    );
    
    sendPort.send(isolateResult);
  } catch (e) {
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
  
  // Implementation would depend on what processing is needed
  // For example, resize or compress images
  
  // Simulated processing for now
  await Future.delayed(const Duration(milliseconds: 100));
  
  return {
    'processed': true,
    'original_size': data['size'],
    'new_size': data['size'] * 0.7,
  };
}

/// Process file operations
Future<dynamic> _processFile(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  
  // Implementation for file operations
  // For example, copying, moving, or renaming files
  
  // Simulated processing for now
  await Future.delayed(const Duration(milliseconds: 100));
  
  return {
    'success': true,
    'path': data['path'],
  };
}

/// Process data
Future<dynamic> _processData(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  
  // Implementation for data processing
  // For example, parsing JSON, formatting data, etc.
  
  // Simulated processing for now
  await Future.delayed(const Duration(milliseconds: 100));
  
  if (data is List) {
    return {
      'processed': true,
      'count': data.length,
      'summary': 'Processed ${data.length} items',
    };
  }
  
  return {
    'processed': true,
    'type': data.runtimeType.toString(),
  };
}

/// Process crypto operations
Future<dynamic> _processCrypto(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  
  // Implementation for crypto operations
  // For example, encryption, decryption, hashing
  
  // Simulated processing for now
  await Future.delayed(const Duration(milliseconds: 100));
  
  return {
    'processed': true,
    'algorithm': params?['algorithm'] ?? 'default',
  };
}

/// Process search operations
Future<dynamic> _processSearch(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  
  // Implementation for search operations
  // For example, full-text search in a large dataset
  
  // Simulated processing for now
  await Future.delayed(const Duration(milliseconds: 100));
  
  if (data is List && params?['query'] != null) {
    final query = params!['query'] as String;
    final results = data.where((item) => 
      item.toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
    
    return {
      'results': results,
      'count': results.length,
      'query': query,
    };
  }
  
  return {
    'error': 'Invalid search parameters',
  };
}

/// Process custom operations
Future<dynamic> _processCustom(Map<String, dynamic> args) async {
  final data = args['data'];
  final params = args['params'] as Map<String, dynamic>?;
  
  // Implementation for custom operations
  // This would be specific to the application's needs
  
  // Simulated processing for now
  await Future.delayed(const Duration(milliseconds: 100));
  
  return {
    'processed': true,
    'operation': params?['operation'] ?? 'unknown',
  };
} 