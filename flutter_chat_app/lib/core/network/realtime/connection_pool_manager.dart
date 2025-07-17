import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/core/network/realtime/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/network/realtime/realtime_error.dart' as realtime_error;

/// Class quản lý connection pool cho các kết nối WebSocket
/// Được cải tiến với cơ chế tự phục hồi, kiểm tra sức khỏe và quản lý bộ nhớ tối ưu
@singleton
class ConnectionPoolManager {
  /// Kích thước tối đa của pool
  final int _maxPoolSize;
  
  /// Thời gian sống tối đa của mỗi kết nối (ms)
  final int _maxConnectionLifetime;
  
  /// Thời gian không hoạt động tối đa trước khi đóng kết nối (ms)
  final int _maxIdleTime;
  
  /// Danh sách các kết nối trong pool
  final Map<String, _PooledConnection> _connections = {};
  
  /// Queue các kết nối theo thứ tự sử dụng (LRU)
  final Queue<String> _connectionQueue = Queue<String>();
  
  /// Timer cho việc dọn dẹp các kết nối cũ
  Timer? _cleanupTimer;
  
  /// Timer cho việc kiểm tra sức khỏe kết nối
  Timer? _healthCheckTimer;
  
  /// Factory tạo kết nối mới
  final Future<IRealtimeConnectionService> Function() _connectionFactory;
  
  /// Flag đánh dấu đã khởi tạo
  bool _initialized = false;
  
  /// Số lần kết nối thành công
  int _successfulConnections = 0;
  
  /// Số lần kết nối thất bại
  int _failedConnections = 0;
  
  /// Thời gian tạo kết nối trung bình (ms)
  double _avgConnectionTime = 0;
  
  /// Thời gian phản hồi trung bình (ms)
  double _avgLatency = 0;
  
  /// Số mẫu latency đã đo
  int _latencySamples = 0;
  
  /// Hoàn trả kết nối nếu quá số lần thử tối đa
  final int _maxRetryAttempts = 3;
  
  /// Cờ đánh dấu đang tạo kết nối mới
  bool _isCreatingConnection = false;
  
  /// Constructor
  ConnectionPoolManager({
    required Future<IRealtimeConnectionService> Function() connectionFactory,
    int maxPoolSize = 5,
    int maxConnectionLifetime = 3600000, // 1 giờ
    int maxIdleTime = 600000, // 10 phút
    int cleanupInterval = 60000, // 1 phút
    int healthCheckInterval = 30000, // 30 giây
  })  : _connectionFactory = connectionFactory,
        _maxPoolSize = maxPoolSize,
        _maxConnectionLifetime = maxConnectionLifetime,
        _maxIdleTime = maxIdleTime {
    _initialized = true;
    _startCleanupTimer(cleanupInterval);
    _startHealthCheckTimer(healthCheckInterval);
  }
  
  /// Khởi tạo pool manager với số lượng kết nối trước
  Future<void> initialize(int preConnectCount) async {
    if (!_initialized) return;
    
    preConnectCount = preConnectCount.clamp(0, _maxPoolSize);
    
    if (preConnectCount > 0) {
      debugPrint('Pre-connecting $preConnectCount connections');
    }
    
    // Tạo số lượng kết nối trước
    final futures = <Future<void>>[];
    for (int i = 0; i < preConnectCount; i++) {
      futures.add(_createNewConnection().catchError((e) {
        debugPrint('Failed to pre-connect: $e');
        return null;
      }));
    }
    
    // Đợi tất cả các kết nối khởi tạo song song (tối ưu thời gian khởi động)
    await Future.wait(futures);
    
    if (_connections.isNotEmpty) {
      debugPrint('Pre-connected ${_connections.length} connections successfully');
    }
  }
  
  /// Mượn một kết nối từ pool với retry và health check
  Future<IRealtimeConnectionService> acquireConnection() async {
    // Kiểm tra và khởi tạo nếu chưa
    if (!_initialized) {
      throw realtime_error.RealtimeError(
        type: realtime_error.RealtimeErrorType.unknown,
        message: 'Connection pool manager has not been initialized',
      );
    }
    
    int retryCount = 0;
    while (retryCount < _maxRetryAttempts) {
      try {
        // Tìm kết nối có sẵn
        String? connectionId = _findAvailableConnection();
        
        // Nếu không có, tạo mới nếu chưa đạt giới hạn
        if (connectionId == null) {
          if (_connections.length < _maxPoolSize && !_isCreatingConnection) {
            try {
              connectionId = await _createNewConnection();
            } catch (e) {
              _failedConnections++;
              debugPrint('Failed to create new connection: $e');
              
              // Nếu không tạo được, thử lấy kết nối ít dùng nhất
              connectionId = _getLeastRecentlyUsedConnection();
            }
          } else {
            // Lấy kết nối ít dùng nhất
            connectionId = _getLeastRecentlyUsedConnection();
          }
          
          // Nếu vẫn không có kết nối nào, đợi ngắn và thử lại
          if (connectionId == null) {
            retryCount++;
            if (retryCount >= _maxRetryAttempts) {
              throw realtime_error.RealtimeError(
                type: realtime_error.RealtimeErrorType.connectionPoolExhausted,
                message: 'Connection pool exhausted, max size: $_maxPoolSize',
              );
            }
            await Future.delayed(Duration(milliseconds: 100 * retryCount));
            continue;
          }
        }
        
        // Lấy kết nối và kiểm tra trạng thái
        final connection = _connections[connectionId]!;
        final service = connection.service;
        
        // Kiểm tra kết nối có hoạt động không
        if (!service.isConnected) {
          // Thử kết nối lại
          final reconnected = await service.reconnect();
          if (!reconnected) {
            // Nếu không kết nối lại được, loại bỏ kết nối này
            await _removeConnection(connectionId);
            retryCount++;
            continue; // Thử lại từ đầu
          }
        }
        
        // Cập nhật thời gian sử dụng gần nhất
        connection.lastUsedAt = DateTime.now();
        connection.inUse = true;
        connection.usageCount++;
        
        // Cập nhật queue
        _updateConnectionQueueOrder(connectionId);
        
        return service;
      } catch (e) {
        retryCount++;
        // Nếu lỗi và đã thử đủ số lần, ném lỗi ra ngoài
        if (retryCount >= _maxRetryAttempts) {
          throw realtime_error.RealtimeError.fromException(e as Exception, type: realtime_error.RealtimeErrorType.connectionPoolExhausted);
        }
        // Đợi một chút trước khi thử lại
        await Future.delayed(Duration(milliseconds: 100 * retryCount));
      }
    }
    
    // Nếu đã thử hết các cách mà vẫn không có kết nối
    throw realtime_error.RealtimeError(
      type: realtime_error.RealtimeErrorType.connectionPoolExhausted,
      message: 'Failed to acquire connection after $_maxRetryAttempts attempts',
    );
  }
  
  /// Trả kết nối về pool với kiểm tra sức khỏe
  Future<void> releaseConnection(IRealtimeConnectionService connection) async {
    final connectionId = _findConnectionIdByService(connection);
    
    if (connectionId != null && _connections.containsKey(connectionId)) {
      final pooledConnection = _connections[connectionId]!;
      pooledConnection.inUse = false;
      pooledConnection.lastUsedAt = DateTime.now();
      
      // Kiểm tra sức khỏe kết nối khi trả về
      if (!connection.isConnected) {
        // Thử kết nối lại trước khi hoàn trả
        final reconnected = await connection.reconnect().timeout(
          Duration(seconds: 5),
          onTimeout: () => false,
        );
        
        // Nếu không kết nối lại được, đánh dấu để làm mới
        if (!reconnected) {
          debugPrint('Connection in poor health removed from pool: $connectionId');
          await _removeConnection(connectionId);
          
          // Tạo kết nối mới để thay thế nếu cần
          if (_connections.length < _maxPoolSize / 2) {
            _createNewConnection().catchError((e) {
              debugPrint('Failed to create replacement connection: $e');
            });
          }
        }
      }
    }
  }
  
  /// Đóng tất cả kết nối và giải phóng tài nguyên
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _healthCheckTimer?.cancel();
    
    // Đánh dấu là không khởi tạo để ngừng các hoạt động mới
    _initialized = false;
    
    // Đóng tất cả kết nối
    final futures = <Future<void>>[];
    for (final connection in _connections.values) {
      futures.add(Future(() {
        try {
          connection.service.dispose();
        } catch (e) {
          debugPrint('Error closing connection: $e');
        }
      }));
    }
    
    await Future.wait(futures);
    
    _connections.clear();
    _connectionQueue.clear();
    
    debugPrint('Connection pool disposed, all connections closed');
  }
  
  /// Làm mới toàn bộ pool kết nối
  Future<void> refreshPool() async {
    // Chỉ làm mới các kết nối không đang sử dụng
    final connectionsToRefresh = _connections.entries
        .where((entry) => !entry.value.inUse)
        .map((entry) => entry.key)
        .toList();
    
    if (connectionsToRefresh.isEmpty) return;
    
    debugPrint('Refreshing ${connectionsToRefresh.length} idle connections');
    
    final futures = <Future<void>>[];
    for (final connectionId in connectionsToRefresh) {
      futures.add(_refreshConnection(connectionId));
    }
    
    await Future.wait(futures);
  }
  
  /// Làm mới một kết nối cụ thể
  Future<void> _refreshConnection(String connectionId) async {
    // Loại bỏ kết nối cũ
    await _removeConnection(connectionId);
    
    // Tạo kết nối mới thay thế
    try {
      await _createNewConnection();
    } catch (e) {
      debugPrint('Failed to refresh connection: $e');
    }
  }
  
  /// Lấy số lượng kết nối hiện tại
  int get connectionCount => _connections.length;
  
  /// Lấy số lượng kết nối đang sử dụng
  int get activeConnectionCount => _connections.values.where((conn) => conn.inUse).length;
  
  /// Lấy số lượng kết nối không đang sử dụng
  int get idleConnectionCount => _connections.values.where((conn) => !conn.inUse).length;
  
  /// Lấy số lượng kết nối thành công
  int get successfulConnections => _successfulConnections;
  
  /// Lấy số lượng kết nối thất bại
  int get failedConnections => _failedConnections;
  
  /// Lấy tỷ lệ thành công
  double get successRate => _successfulConnections + _failedConnections > 0 
      ? _successfulConnections / (_successfulConnections + _failedConnections) 
      : 1.0;
  
  /// Lấy thông tin chi tiết về pool
  Map<String, dynamic> getPoolStats() {
    return {
      'totalConnections': _connections.length,
      'activeConnections': activeConnectionCount,
      'idleConnections': idleConnectionCount,
      'maxPoolSize': _maxPoolSize,
      'successfulConnections': _successfulConnections,
      'failedConnections': _failedConnections,
      'successRate': successRate,
      'avgConnectionTime': _avgConnectionTime,
      'avgLatency': _avgLatency,
      'connections': _connections.entries.map((entry) {
        final connection = entry.value;
        return {
          'id': entry.key,
          'inUse': connection.inUse,
          'createdAt': connection.createdAt.millisecondsSinceEpoch,
          'lastUsedAt': connection.lastUsedAt.millisecondsSinceEpoch,
          'ageMs': DateTime.now().difference(connection.createdAt).inMilliseconds,
          'idleTimeMs': DateTime.now().difference(connection.lastUsedAt).inMilliseconds,
          'usageCount': connection.usageCount,
          'isConnected': connection.service.isConnected,
        };
      }).toList(),
    };
  }
  
  /// Tạo kết nối mới
  Future<String> _createNewConnection() async {
    if (_isCreatingConnection) {
      // Tránh tạo nhiều kết nối cùng lúc
      throw realtime_error.RealtimeError(
        type: realtime_error.RealtimeErrorType.unknown,
        message: 'Already creating a new connection',
      );
    }
    
    _isCreatingConnection = true;
    final stopwatch = Stopwatch()..start();
    
    try {
      final service = await _connectionFactory();
      await service.initialize();
      
      // Kết nối với timeout để tránh treo
      try {
        await service.connect().timeout(Duration(seconds: 10));
      } catch (e) {
        // Connection failed
        _failedConnections++;
        throw realtime_error.RealtimeError(
          type: realtime_error.RealtimeErrorType.networkError,
          message: 'Failed to connect to realtime service',
        );
      }
      
      // Tạo ID kết nối độc nhất
      final randomPart = (1000 + math.Random().nextInt(9000)).toString();
      final connectionId = 'conn_${DateTime.now().millisecondsSinceEpoch}_$randomPart';
      
      final pooledConnection = _PooledConnection(
        service: service,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        inUse: false,
      );
      
      _connections[connectionId] = pooledConnection;
      _connectionQueue.add(connectionId);
      
      stopwatch.stop();
      
      // Cập nhật thống kê
      _successfulConnections++;
      _updateAvgConnectionTime(stopwatch.elapsedMilliseconds);
      
      debugPrint('Created new connection: $connectionId in ${stopwatch.elapsedMilliseconds}ms, total: ${_connections.length}');
      
      return connectionId;
    } catch (e) {
      _failedConnections++;
      
      stopwatch.stop();
      debugPrint('Failed to create connection: $e (${stopwatch.elapsedMilliseconds}ms)');
      
      throw realtime_error.RealtimeError.fromException(e as Exception);
    } finally {
      _isCreatingConnection = false;
    }
  }
  
  /// Cập nhật thời gian kết nối trung bình
  void _updateAvgConnectionTime(int timeMs) {
    if (_successfulConnections == 1) {
      _avgConnectionTime = timeMs.toDouble();
    } else {
      _avgConnectionTime = (_avgConnectionTime * (_successfulConnections - 1) + timeMs) / _successfulConnections;
    }
  }
  
  /// Cập nhật độ trễ trung bình
  void _updateAvgLatency(int latencyMs) {
    _latencySamples++;
    if (_latencySamples == 1) {
      _avgLatency = latencyMs.toDouble();
    } else {
      _avgLatency = (_avgLatency * (_latencySamples - 1) + latencyMs) / _latencySamples;
    }
  }
  
  /// Tìm kết nối có sẵn
  String? _findAvailableConnection() {
    // Ưu tiên kết nối đã được khởi tạo và đang connected
    for (final entry in _connections.entries) {
      if (!entry.value.inUse && entry.value.service.isConnected) {
        return entry.key;
      }
    }
    
    // Nếu không có, lấy bất kỳ kết nối nào không sử dụng
    for (final entry in _connections.entries) {
      if (!entry.value.inUse) {
        return entry.key;
      }
    }
    
    return null;
  }
  
  /// Lấy kết nối ít dùng gần đây nhất (LRU)
  String? _getLeastRecentlyUsedConnection() {
    if (_connectionQueue.isEmpty) return null;
    
    // Tìm kết nối LRU không đang sử dụng
    for (final connectionId in _connectionQueue) {
      final connection = _connections[connectionId];
      if (connection != null && !connection.inUse) {
        return connectionId;
      }
    }
    
    return null;
  }
  
  /// Tìm id kết nối từ service
  String? _findConnectionIdByService(IRealtimeConnectionService service) {
    for (final entry in _connections.entries) {
      if (identical(entry.value.service, service)) {
        return entry.key;
      }
    }
    return null;
  }
  
  /// Cập nhật thứ tự queue
  void _updateConnectionQueueOrder(String connectionId) {
    _connectionQueue.removeWhere((id) => id == connectionId);
    _connectionQueue.add(connectionId);
  }
  
  /// Khởi động timer dọn dẹp
  void _startCleanupTimer(int intervalMs) {
    _cleanupTimer?.cancel();
    
    _cleanupTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _cleanupIdleConnections();
    });
  }
  
  /// Khởi động timer kiểm tra sức khỏe
  void _startHealthCheckTimer(int intervalMs) {
    _healthCheckTimer?.cancel();
    
    _healthCheckTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _checkConnectionsHealth();
    });
  }
  
  /// Kiểm tra sức khỏe của các kết nối
  Future<void> _checkConnectionsHealth() async {
    if (_connections.isEmpty || !_initialized) return;
    
    // Chỉ kiểm tra các kết nối không đang sử dụng
    final connectionsToCheck = _connections.entries
        .where((entry) => !entry.value.inUse)
        .map((entry) => entry.key)
        .toList();
    
    if (connectionsToCheck.isEmpty) return;
    
    // Lấy ngẫu nhiên tối đa 2 kết nối để kiểm tra
    connectionsToCheck.shuffle();
    final toCheck = connectionsToCheck.take(2).toList();
    
    for (final connectionId in toCheck) {
      final connection = _connections[connectionId];
      if (connection == null) continue;
      
      try {
        // Kiểm tra độ trễ
        final latency = await connection.service.checkLatency().timeout(
          Duration(seconds: 5),
          onTimeout: () => null,
        );
        
        if (latency != null) {
          _updateAvgLatency(latency);
        } else {
          // Nếu không đo được độ trễ, có thể kết nối có vấn đề
          if (!connection.service.isConnected) {
            // Thử kết nối lại
            final reconnected = await connection.service.reconnect().timeout(
              Duration(seconds: 5),
              onTimeout: () => false,
            );
            
            if (!reconnected) {
              debugPrint('Unhealthy connection detected during health check: $connectionId');
              await _refreshConnection(connectionId);
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking connection health: $e');
      }
    }
  }
  
  /// Dọn dẹp các kết nối không sử dụng
  Future<void> _cleanupIdleConnections() async {
    if (!_initialized) return;
    
    final now = DateTime.now();
    var connectionsToRemove = <String>[];
    
    // Tìm các kết nối cần đóng
    for (final entry in _connections.entries) {
      final connection = entry.value;
      final connectionId = entry.key;
      
      // Bỏ qua kết nối đang sử dụng
      if (connection.inUse) continue;
      
      // Kiểm tra thời gian tồn tại
      final age = now.difference(connection.createdAt).inMilliseconds;
      if (age > _maxConnectionLifetime) {
        connectionsToRemove.add(connectionId);
        continue;
      }
      
      // Kiểm tra thời gian không hoạt động
      final idleTime = now.difference(connection.lastUsedAt).inMilliseconds;
      if (idleTime > _maxIdleTime) {
        connectionsToRemove.add(connectionId);
      }
    }
    
    // Giới hạn số lượng kết nối đóng cùng lúc
    if (connectionsToRemove.length > 3) {
      connectionsToRemove.shuffle();
      connectionsToRemove = connectionsToRemove.sublist(0, 3);
    }
    
    // Đóng các kết nối
    for (final connectionId in connectionsToRemove) {
      await _removeConnection(connectionId);
    }
    
    if (connectionsToRemove.isNotEmpty) {
      debugPrint('Cleaned up ${connectionsToRemove.length} idle connections, remaining: ${_connections.length}');
    }
  }
  
  /// Xóa kết nối
  Future<void> _removeConnection(String connectionId) async {
    final connection = _connections[connectionId];
    if (connection == null) return;
    
    try {
      // Dispose doesn't return a Future, so we wrap it
      await Future(connection.service.dispose).timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('Error disposing connection: $e');
    }
    
    _connections.remove(connectionId);
    _connectionQueue.removeWhere((id) => id == connectionId);
  }
}

/// Class đại diện cho một kết nối trong pool
class _PooledConnection {
  /// Service thực tế
  final IRealtimeConnectionService service;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Thời gian sử dụng gần nhất
  DateTime lastUsedAt;
  
  /// Flag đánh dấu đang sử dụng
  bool inUse;
  
  /// Số lần sử dụng
  int usageCount = 0;
  
  /// Số lần lỗi
  int errorCount = 0;
  
  /// Độ trễ gần nhất (ms)
  int? lastLatency;
  
  /// Constructor
  _PooledConnection({
    required this.service,
    required this.createdAt,
    required this.lastUsedAt,
    required this.inUse,
  });
} 