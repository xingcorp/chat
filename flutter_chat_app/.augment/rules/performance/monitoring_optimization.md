# Performance Monitoring & Optimization Rules - Enterprise Messaging

**Type**: Auto  
**Description**: Comprehensive performance monitoring, profiling, and optimization strategies for enterprise-scale messaging app with real-time metrics and automated optimization

## Performance Monitoring Architecture

### Real-time Performance Metrics
```dart
class PerformanceMonitor {
  static const Map<String, PerformanceThreshold> thresholds = {
    'app_startup_time': PerformanceThreshold(
      target: 2000, // 2 seconds
      warning: 1500,
      critical: 3000,
      unit: 'milliseconds',
    ),
    'message_delivery_time': PerformanceThreshold(
      target: 100, // 100ms
      warning: 80,
      critical: 200,
      unit: 'milliseconds',
    ),
    'memory_usage_per_conversation': PerformanceThreshold(
      target: 150 * 1024 * 1024, // 150MB
      warning: 120 * 1024 * 1024,
      critical: 200 * 1024 * 1024,
      unit: 'bytes',
    ),
    'ui_frame_render_time': PerformanceThreshold(
      target: 16, // 60 FPS
      warning: 12,
      critical: 33, // 30 FPS
      unit: 'milliseconds',
    ),
    'websocket_connection_time': PerformanceThreshold(
      target: 2000, // 2 seconds
      warning: 1500,
      critical: 5000,
      unit: 'milliseconds',
    ),
    'offline_sync_duration': PerformanceThreshold(
      target: 5000, // 5 seconds
      warning: 3000,
      critical: 10000,
      unit: 'milliseconds',
    ),
  };
  
  static Future<void> startMonitoring() async {
    // 1. Initialize performance tracking
    await _initializePerformanceTracking();
    
    // 2. Start continuous monitoring
    Timer.periodic(Duration(seconds: 30), (_) async {
      await _collectPerformanceMetrics();
    });
    
    // 3. Setup memory monitoring
    Timer.periodic(Duration(minutes: 1), (_) async {
      await _monitorMemoryUsage();
    });
    
    // 4. Monitor UI performance
    WidgetsBinding.instance.addTimingsCallback(_trackFrameMetrics);
  }
  
  static Future<void> _collectPerformanceMetrics() async {
    final metrics = await Future.wait([
      _measureAppStartupTime(),
      _measureMessageDeliveryTime(),
      _measureMemoryUsage(),
      _measureNetworkLatency(),
      _measureDatabaseQueryTime(),
      _measureUIResponsiveness(),
    ]);
    
    for (final metric in metrics) {
      await _processMetric(metric);
    }
  }
  
  static Future<void> _processMetric(PerformanceMetric metric) async {
    final threshold = thresholds[metric.name];
    if (threshold == null) return;
    
    // Store metric
    await MetricsStorage.store(metric);
    
    // Check thresholds
    if (metric.value > threshold.critical) {
      await _handleCriticalPerformanceIssue(metric);
    } else if (metric.value > threshold.warning) {
      await _handlePerformanceWarning(metric);
    }
    
    // Trigger optimization if needed
    if (metric.value > threshold.target) {
      await _triggerOptimization(metric);
    }
  }
}
```

### Automated Performance Optimization
```dart
class AutoOptimizer {
  static const Map<String, OptimizationStrategy> strategies = {
    'memory_usage_high': OptimizationStrategy(
      trigger: 'memory_usage_per_conversation > 150MB',
      actions: [
        'clear_message_cache',
        'compress_images',
        'garbage_collect',
        'reduce_message_history',
      ],
    ),
    'message_delivery_slow': OptimizationStrategy(
      trigger: 'message_delivery_time > 100ms',
      actions: [
        'optimize_websocket_connection',
        'enable_message_batching',
        'reduce_payload_size',
        'switch_to_faster_server',
      ],
    ),
    'ui_frame_drops': OptimizationStrategy(
      trigger: 'ui_frame_render_time > 16ms',
      actions: [
        'reduce_widget_rebuilds',
        'optimize_animations',
        'implement_virtual_scrolling',
        'cache_expensive_widgets',
      ],
    ),
  };
  
  static Future<void> optimizePerformance(
    String metricName,
    double currentValue,
  ) async {
    final strategy = _findOptimizationStrategy(metricName, currentValue);
    if (strategy == null) return;
    
    print('🔧 Auto-optimizing $metricName (current: $currentValue)');
    
    for (final action in strategy.actions) {
      try {
        await _executeOptimizationAction(action);
        
        // Measure improvement
        final newValue = await _measureMetric(metricName);
        final improvement = ((currentValue - newValue) / currentValue) * 100;
        
        print('✅ Action $action improved $metricName by ${improvement.toStringAsFixed(1)}%');
        
        // Stop if target achieved
        final threshold = PerformanceMonitor.thresholds[metricName];
        if (threshold != null && newValue <= threshold.target) {
          print('🎯 Target performance achieved for $metricName');
          break;
        }
      } catch (e) {
        print('❌ Optimization action $action failed: $e');
      }
    }
  }
  
  static Future<void> _executeOptimizationAction(String action) async {
    switch (action) {
      case 'clear_message_cache':
        await MessageCacheManager.clearOldMessages();
        break;
      case 'compress_images':
        await ImageCompressionService.compressAllImages();
        break;
      case 'garbage_collect':
        await _forceGarbageCollection();
        break;
      case 'optimize_websocket_connection':
        await WebSocketOptimizer.optimizeConnection();
        break;
      case 'enable_message_batching':
        await MessageBatcher.enableBatching();
        break;
      case 'reduce_widget_rebuilds':
        await WidgetOptimizer.optimizeRebuilds();
        break;
      case 'implement_virtual_scrolling':
        await VirtualScrollingManager.enable();
        break;
      default:
        throw UnsupportedError('Unknown optimization action: $action');
    }
  }
}
```

## Memory Management & Leak Detection

### Advanced Memory Monitoring
```dart
class MemoryProfiler {
  static const Duration profilingInterval = Duration(minutes: 5);
  static const int maxMemorySnapshots = 100;
  
  static final List<MemorySnapshot> _snapshots = [];
  static Timer? _profilingTimer;
  
  static void startProfiling() {
    _profilingTimer = Timer.periodic(profilingInterval, (_) async {
      await _takeMemorySnapshot();
    });
  }
  
  static Future<void> _takeMemorySnapshot() async {
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      totalMemory: await _getTotalMemoryUsage(),
      heapMemory: await _getHeapMemoryUsage(),
      nativeMemory: await _getNativeMemoryUsage(),
      dartObjects: await _getDartObjectCount(),
      flutterObjects: await _getFlutterObjectCount(),
      conversationMemory: await _getConversationMemoryUsage(),
      imageMemory: await _getImageMemoryUsage(),
    );
    
    _snapshots.add(snapshot);
    
    // Keep only recent snapshots
    if (_snapshots.length > maxMemorySnapshots) {
      _snapshots.removeAt(0);
    }
    
    // Analyze for leaks
    await _analyzeMemoryLeaks(snapshot);
    
    // Trigger cleanup if needed
    if (snapshot.totalMemory > 200 * 1024 * 1024) { // 200MB
      await _triggerMemoryCleanup();
    }
  }
  
  static Future<void> _analyzeMemoryLeaks(MemorySnapshot current) async {
    if (_snapshots.length < 10) return; // Need history for analysis
    
    final recentSnapshots = _snapshots.takeLast(10).toList();
    
    // Check for memory growth trend
    final memoryGrowth = _calculateMemoryGrowthRate(recentSnapshots);
    if (memoryGrowth > 0.1) { // 10% growth per interval
      await _reportMemoryLeak(memoryGrowth, current);
    }
    
    // Check for specific object leaks
    await _checkObjectLeaks(recentSnapshots);
  }
  
  static Future<void> _checkObjectLeaks(List<MemorySnapshot> snapshots) async {
    final objectGrowth = {
      'dart_objects': _calculateObjectGrowth(snapshots, (s) => s.dartObjects),
      'flutter_objects': _calculateObjectGrowth(snapshots, (s) => s.flutterObjects),
      'conversation_memory': _calculateObjectGrowth(snapshots, (s) => s.conversationMemory),
      'image_memory': _calculateObjectGrowth(snapshots, (s) => s.imageMemory),
    };
    
    for (final entry in objectGrowth.entries) {
      if (entry.value > 0.15) { // 15% growth
        await _reportObjectLeak(entry.key, entry.value);
        await _triggerSpecificCleanup(entry.key);
      }
    }
  }
}
```

### Intelligent Memory Cleanup
```dart
class MemoryCleanupManager {
  static const Map<String, CleanupStrategy> cleanupStrategies = {
    'conversation_memory': CleanupStrategy(
      priority: 1,
      action: _cleanupConversationMemory,
      expectedSavings: 50 * 1024 * 1024, // 50MB
    ),
    'image_cache': CleanupStrategy(
      priority: 2,
      action: _cleanupImageCache,
      expectedSavings: 30 * 1024 * 1024, // 30MB
    ),
    'message_cache': CleanupStrategy(
      priority: 3,
      action: _cleanupMessageCache,
      expectedSavings: 20 * 1024 * 1024, // 20MB
    ),
    'widget_cache': CleanupStrategy(
      priority: 4,
      action: _cleanupWidgetCache,
      expectedSavings: 10 * 1024 * 1024, // 10MB
    ),
  };
  
  static Future<void> performIntelligentCleanup(int targetMemoryReduction) async {
    final sortedStrategies = cleanupStrategies.entries
        .toList()
        ..sort((a, b) => a.value.priority.compareTo(b.value.priority));
    
    int totalSavings = 0;
    
    for (final entry in sortedStrategies) {
      if (totalSavings >= targetMemoryReduction) break;
      
      final strategy = entry.value;
      final beforeMemory = await _getCurrentMemoryUsage();
      
      try {
        await strategy.action();
        
        final afterMemory = await _getCurrentMemoryUsage();
        final actualSavings = beforeMemory - afterMemory;
        totalSavings += actualSavings;
        
        print('✅ Cleanup ${entry.key}: saved ${actualSavings ~/ (1024 * 1024)}MB');
        
      } catch (e) {
        print('❌ Cleanup ${entry.key} failed: $e');
      }
    }
    
    print('🧹 Total memory cleaned: ${totalSavings ~/ (1024 * 1024)}MB');
  }
  
  static Future<void> _cleanupConversationMemory() async {
    // Remove old conversations from memory
    final conversations = ConversationManager.getAllConversations();
    final cutoffTime = DateTime.now().subtract(Duration(hours: 24));
    
    for (final conversation in conversations) {
      if (conversation.lastActivity.isBefore(cutoffTime)) {
        await ConversationManager.unloadFromMemory(conversation.id);
      }
    }
    
    // Limit messages per conversation in memory
    for (final conversation in conversations) {
      await MessageManager.limitMessagesInMemory(conversation.id, 100);
    }
  }
  
  static Future<void> _cleanupImageCache() async {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Clear images not accessed recently
    imageCache.clearLiveImages();
    
    // Reduce cache size if needed
    if (imageCache.currentSizeBytes > 50 * 1024 * 1024) { // 50MB
      imageCache.maximumSizeBytes = 30 * 1024 * 1024; // Reduce to 30MB
    }
    
    // Clear cached network images
    await CachedNetworkImage.evictFromCache();
  }
}
```

## Network Performance Optimization

### Connection Optimization
```dart
class NetworkOptimizer {
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration readTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;
  
  static Future<void> optimizeNetworkPerformance() async {
    // 1. Optimize HTTP client configuration
    await _optimizeHttpClient();
    
    // 2. Implement connection pooling
    await _setupConnectionPooling();
    
    // 3. Enable request/response compression
    await _enableCompression();
    
    // 4. Implement intelligent caching
    await _setupIntelligentCaching();
    
    // 5. Optimize WebSocket connections
    await _optimizeWebSocketConnections();
  }
  
  static Future<void> _optimizeHttpClient() async {
    final client = HttpClient();
    
    // Connection settings
    client.connectionTimeout = connectionTimeout;
    client.idleTimeout = Duration(seconds: 30);
    client.maxConnectionsPerHost = 6;
    
    // Enable HTTP/2
    client.autoUncompress = true;
    
    // Configure for mobile networks
    client.findProxy = HttpClient.findProxyFromEnvironment;
    
    HttpOverrides.global = OptimizedHttpOverrides(client);
  }
  
  static Future<void> _setupConnectionPooling() async {
    final dio = Dio();
    
    // Connection pool configuration
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.maxConnectionsPerHost = 10;
      client.connectionTimeout = connectionTimeout;
      client.idleTimeout = Duration(minutes: 1);
      return client;
    };
    
    // Add connection pooling interceptor
    dio.interceptors.add(ConnectionPoolInterceptor());
  }
  
  static Future<void> _enableCompression() async {
    final dio = Dio();
    
    // Enable gzip compression
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept-Encoding'] = 'gzip, deflate';
        handler.next(options);
      },
    ));
    
    // Compress request bodies
    dio.interceptors.add(CompressionInterceptor());
  }
}
```

### Intelligent Request Batching
```dart
class RequestBatcher {
  static const Duration batchWindow = Duration(milliseconds: 100);
  static const int maxBatchSize = 10;
  
  static final Map<String, List<BatchedRequest>> _pendingBatches = {};
  static final Map<String, Timer> _batchTimers = {};
  
  static Future<T> batchRequest<T>(
    String batchKey,
    Future<T> Function() request,
    T Function(List<dynamic>) combineResults,
  ) async {
    final completer = Completer<T>();
    final batchedRequest = BatchedRequest<T>(
      request: request,
      completer: completer,
    );
    
    // Add to batch
    _pendingBatches.putIfAbsent(batchKey, () => []).add(batchedRequest);
    
    // Schedule batch execution
    _batchTimers[batchKey]?.cancel();
    _batchTimers[batchKey] = Timer(batchWindow, () async {
      await _executeBatch(batchKey, combineResults);
    });
    
    // Execute immediately if batch is full
    if (_pendingBatches[batchKey]!.length >= maxBatchSize) {
      _batchTimers[batchKey]?.cancel();
      await _executeBatch(batchKey, combineResults);
    }
    
    return completer.future;
  }
  
  static Future<void> _executeBatch<T>(
    String batchKey,
    T Function(List<dynamic>) combineResults,
  ) async {
    final batch = _pendingBatches.remove(batchKey);
    if (batch == null || batch.isEmpty) return;
    
    try {
      // Execute all requests in parallel
      final results = await Future.wait(
        batch.map((req) => req.request()),
      );
      
      // Combine results if needed
      final combinedResult = combineResults(results);
      
      // Complete all requests
      for (int i = 0; i < batch.length; i++) {
        batch[i].completer.complete(
          i < results.length ? results[i] : combinedResult,
        );
      }
      
    } catch (e) {
      // Fail all requests in batch
      for (final req in batch) {
        req.completer.completeError(e);
      }
    }
  }
}
```

## UI Performance Optimization

### Frame Rate Monitoring
```dart
class FrameRateMonitor {
  static const double targetFrameTime = 16.67; // 60 FPS
  static const int frameHistorySize = 120; // 2 seconds at 60 FPS
  
  static final List<double> _frameHistory = [];
  static double _averageFrameTime = 0;
  static int _droppedFrames = 0;
  
  static void startMonitoring() {
    WidgetsBinding.instance.addTimingsCallback(_onFrameMetrics);
  }
  
  static void _onFrameMetrics(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // Convert to ms
      
      _frameHistory.add(frameTime);
      if (_frameHistory.length > frameHistorySize) {
        _frameHistory.removeAt(0);
      }
      
      // Calculate average
      _averageFrameTime = _frameHistory.reduce((a, b) => a + b) / _frameHistory.length;
      
      // Count dropped frames
      if (frameTime > targetFrameTime * 1.5) { // 150% of target
        _droppedFrames++;
      }
      
      // Trigger optimization if performance is poor
      if (_averageFrameTime > targetFrameTime * 1.2) { // 20% above target
        _triggerUIOptimization();
      }
    }
  }
  
  static Future<void> _triggerUIOptimization() async {
    // Reduce widget rebuilds
    await WidgetOptimizer.optimizeRebuilds();
    
    // Optimize animations
    await AnimationOptimizer.reduceComplexity();
    
    // Enable virtual scrolling if not already enabled
    await VirtualScrollingManager.enable();
    
    // Reduce image quality temporarily
    await ImageOptimizer.reduceQuality();
  }
}
```

### Widget Optimization
```dart
class WidgetOptimizer {
  static final Set<String> _optimizedWidgets = {};
  
  static Future<void> optimizeRebuilds() async {
    // 1. Implement selective rebuilding
    await _implementSelectiveRebuilding();
    
    // 2. Cache expensive widgets
    await _cacheExpensiveWidgets();
    
    // 3. Optimize list rendering
    await _optimizeListRendering();
    
    // 4. Reduce animation complexity
    await _reduceAnimationComplexity();
  }
  
  static Future<void> _implementSelectiveRebuilding() async {
    // Use BlocSelector instead of BlocBuilder where possible
    // Implement custom shouldRebuild logic
    // Use const constructors aggressively
    
    final widgetAnalyzer = WidgetAnalyzer();
    final unnecessaryRebuilds = await widgetAnalyzer.findUnnecessaryRebuilds();
    
    for (final widget in unnecessaryRebuilds) {
      if (!_optimizedWidgets.contains(widget.id)) {
        await _optimizeWidget(widget);
        _optimizedWidgets.add(widget.id);
      }
    }
  }
  
  static Future<void> _optimizeWidget(WidgetInfo widget) async {
    switch (widget.type) {
      case WidgetType.messageList:
        await _optimizeMessageList(widget);
        break;
      case WidgetType.messageItem:
        await _optimizeMessageItem(widget);
        break;
      case WidgetType.conversationList:
        await _optimizeConversationList(widget);
        break;
      default:
        await _applyGenericOptimizations(widget);
    }
  }
}
```
