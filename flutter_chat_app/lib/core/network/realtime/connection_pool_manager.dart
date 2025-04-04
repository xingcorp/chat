import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'realtime_connection_service.dart';
import 'realtime_error.dart';

/// Class quản lý connection pool cho các kết nối WebSocket
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
  
  /// Factory tạo kết nối mới
  final Future<IRealtimeConnectionService> Function() _connectionFactory;
  
  /// Flag đánh dấu đã khởi tạo
  bool _initialized = false;
  
  /// Constructor
  ConnectionPoolManager({
    required Future<IRealtimeConnectionService> Function() connectionFactory,
    int maxPoolSize = 5,
    int maxConnectionLifetime = 3600000, // 1 giờ
    int maxIdleTime = 600000, // 10 phút
    int cleanupInterval = 60000, // 1 phút
  })  : _connectionFactory = connectionFactory,
        _maxPoolSize = maxPoolSize,
        _maxConnectionLifetime = maxConnectionLifetime,
        _maxIdleTime = maxIdleTime {
    _initialized = true;
    _startCleanupTimer(cleanupInterval);
  }
  
  /// Khởi tạo pool manager với số lượng kết nối trước
  Future<void> initialize(int preConnectCount) async {
    if (!_initialized) return;
    
    preConnectCount = preConnectCount.clamp(0, _maxPoolSize);
    
    // Tạo số lượng kết nối trước
    for (int i = 0; i < preConnectCount; i++) {
      try {
        await _createNewConnection();
      } catch (e) {
        debugPrint('Failed to pre-connect: $e');
      }
    }
  }
  
  /// Mượn một kết nối từ pool
  Future<IRealtimeConnectionService> acquireConnection() async {
    // Tìm kết nối có sẵn
    String? connectionId = _findAvailableConnection();
    
    // Nếu không có, tạo mới nếu chưa đạt giới hạn
    if (connectionId == null) {
      if (_connections.length < _maxPoolSize) {
        try {
          connectionId = await _createNewConnection();
        } catch (e) {
          throw RealtimeError.fromException(e, type: RealtimeErrorType.connectionPoolExhausted);
        }
      } else {
        // Lấy kết nối ít dùng nhất
        connectionId = _getLeastRecentlyUsedConnection();
        
        if (connectionId == null) {
          throw RealtimeError(
            type: RealtimeErrorType.connectionPoolExhausted,
            message: 'Connection pool exhausted, max size: $_maxPoolSize',
          );
        }
      }
    }
    
    // Cập nhật thời gian sử dụng gần nhất
    final connection = _connections[connectionId]!;
    connection.lastUsedAt = DateTime.now();
    connection.inUse = true;
    
    // Cập nhật queue
    _updateConnectionQueueOrder(connectionId);
    
    return connection.service;
  }
  
  /// Trả kết nối về pool
  void releaseConnection(IRealtimeConnectionService connection) {
    final connectionId = _findConnectionIdByService(connection);
    
    if (connectionId != null && _connections.containsKey(connectionId)) {
      _connections[connectionId]!.inUse = false;
      _connections[connectionId]!.lastUsedAt = DateTime.now();
    }
  }
  
  /// Đóng tất cả kết nối và giải phóng tài nguyên
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    
    // Đóng tất cả kết nối
    final futures = <Future<void>>[];
    for (final connection in _connections.values) {
      futures.add(connection.service.dispose());
    }
    
    await Future.wait(futures);
    
    _connections.clear();
    _connectionQueue.clear();
    _initialized = false;
  }
  
  /// Lấy số lượng kết nối hiện tại
  int get connectionCount => _connections.length;
  
  /// Lấy số lượng kết nối đang sử dụng
  int get activeConnectionCount => _connections.values.where((conn) => conn.inUse).length;
  
  /// Lấy thông tin về kết nối pool
  Map<String, dynamic> getPoolStats() {
    return {
      'totalConnections': _connections.length,
      'activeConnections': activeConnectionCount,
      'maxPoolSize': _maxPoolSize,
      'connections': _connections.entries.map((entry) {
        final connection = entry.value;
        return {
          'id': entry.key,
          'inUse': connection.inUse,
          'createdAt': connection.createdAt.millisecondsSinceEpoch,
          'lastUsedAt': connection.lastUsedAt.millisecondsSinceEpoch,
          'ageMs': DateTime.now().difference(connection.createdAt).inMilliseconds,
          'idleTimeMs': DateTime.now().difference(connection.lastUsedAt).inMilliseconds,
          'active': connection.service.isConnected,
        };
      }).toList(),
    };
  }
  
  /// Tạo kết nối mới
  Future<String> _createNewConnection() async {
    final service = await _connectionFactory();
    await service.initialize();
    await service.connect();
    
    final connectionId = 'conn_${DateTime.now().millisecondsSinceEpoch}_${_connections.length}';
    
    final pooledConnection = _PooledConnection(
      service: service,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
      inUse: false,
    );
    
    _connections[connectionId] = pooledConnection;
    _connectionQueue.add(connectionId);
    
    debugPrint('Created new connection: $connectionId, total: ${_connections.length}');
    
    return connectionId;
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
    return _connectionQueue.first;
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
  
  /// Dọn dẹp các kết nối không sử dụng
  Future<void> _cleanupIdleConnections() async {
    final now = DateTime.now();
    final connectionsToRemove = <String>[];
    
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
      await connection.service.dispose();
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
  
  /// Constructor
  _PooledConnection({
    required this.service,
    required this.createdAt,
    required this.lastUsedAt,
    required this.inUse,
  });
} 