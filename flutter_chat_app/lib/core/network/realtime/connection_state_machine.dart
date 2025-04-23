import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/subjects.dart';

import 'backoff_strategy.dart';
import 'connection_health_monitor.dart';

/// Sự kiện kích hoạt chuyển đổi state
enum ConnectionEvent {
  /// Người dùng yêu cầu kết nối
  connectRequested,
  
  /// Người dùng yêu cầu ngắt kết nối
  disconnectRequested,
  
  /// Kết nối thành công
  connectionEstablished,
  
  /// Kết nối thất bại
  connectionFailed,
  
  /// Kết nối bị đóng bởi server
  connectionClosed,
  
  /// Kết nối bị lỗi
  connectionError,
  
  /// Mạng bị mất
  networkLost,
  
  /// Mạng được khôi phục
  networkRestored,
  
  /// Phát hiện zombie connection
  zombieDetected,
  
  /// Trạng thái kết nối bị xuống cấp (nhiều lỗi/độ trễ cao)
  connectionDegraded,
  
  /// Thử kết nối lại
  reconnectAttempted,
  
  /// Vượt quá số lần thử kết nối lại
  reconnectExhausted,
  
  /// Khởi tạo lại
  reset,
}

/// Trạng thái chi tiết của kết nối
enum ConnectionState {
  /// Chưa kết nối, ở trạng thái ban đầu
  initial,
  
  /// Đang kết nối lần đầu
  connecting,
  
  /// Kết nối thành công, đang hoạt động
  connected,
  
  /// Kết nối bị mất, đang thử kết nối lại
  reconnecting,
  
  /// Kết nối bị mất do mạng, đang chờ khôi phục mạng
  waitingForNetwork,
  
  /// Kết nối bị ngắt do người dùng
  disconnected,
  
  /// Kết nối bị lỗi, không thể tự khôi phục
  error,
  
  /// Kết nối đã bị đóng bởi server
  closed,
}

/// Mô hình dữ liệu trạng thái kết nối
class ConnectionStateModel {
  /// Trạng thái kết nối
  final ConnectionState state;
  
  /// Thời điểm chuyển sang trạng thái này
  final DateTime timestamp;
  
  /// Mô tả lý do chuyển trạng thái
  final String? reason;
  
  /// Số lần thử kết nối lại
  final int reconnectAttempts;
  
  /// Trạng thái sức khỏe kết nối
  final ConnectionHealthState healthState;
  
  /// Constructor
  ConnectionStateModel({
    required this.state,
    this.reason,
    this.reconnectAttempts = 0,
    DateTime? timestamp,
    this.healthState = ConnectionHealthState.healthy,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Tạo bản copy với các thuộc tính mới
  ConnectionStateModel copyWith({
    ConnectionState? state,
    String? reason,
    int? reconnectAttempts,
    DateTime? timestamp,
    ConnectionHealthState? healthState,
  }) {
    return ConnectionStateModel(
      state: state ?? this.state,
      reason: reason ?? this.reason,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      timestamp: timestamp ?? this.timestamp,
      healthState: healthState ?? this.healthState,
    );
  }
}

/// State machine quản lý các trạng thái kết nối
class ConnectionStateMachine {
  /// Trạng thái hiện tại
  ConnectionStateModel _currentState = ConnectionStateModel(
    state: ConnectionState.initial,
    reason: 'Khởi tạo',
  );
  
  /// Subject phát ra các thay đổi trạng thái
  final _stateSubject = BehaviorSubject<ConnectionStateModel>();
  
  /// Chiến lược backoff
  final SmartBackoffStrategy _backoffStrategy;
  
  /// Số lần thử kết nối lại tối đa
  final int _maxReconnectAttempts;
  
  /// Callback khi cần kết nối
  final Future<bool> Function() _connectCallback;
  
  /// Callback khi cần ngắt kết nối
  final Future<void> Function() _disconnectCallback;
  
  /// Có nên tự động kết nối lại khi mất kết nối
  final bool _autoReconnect;
  
  /// Timer đếm thời gian chờ kết nối lại
  Timer? _reconnectTimer;
  
  /// Constructor
  ConnectionStateMachine({
    required Future<bool> Function() connectCallback,
    required Future<void> Function() disconnectCallback,
    SmartBackoffStrategy? backoffStrategy,
    int maxReconnectAttempts = 10,
    bool autoReconnect = true,
  }) : 
    _connectCallback = connectCallback,
    _disconnectCallback = disconnectCallback,
    _backoffStrategy = backoffStrategy ?? BackoffStrategyFactory.createForWebSocketReconnect(),
    _maxReconnectAttempts = maxReconnectAttempts,
    _autoReconnect = autoReconnect {
    // Đặt trạng thái ban đầu
    _stateSubject.add(_currentState);
  }
  
  /// Stream theo dõi các thay đổi trạng thái
  Stream<ConnectionStateModel> get stateStream => _stateSubject.stream;
  
  /// Trạng thái hiện tại
  ConnectionStateModel get currentState => _currentState;
  
  /// Xử lý sự kiện kết nối
  Future<void> handleEvent(ConnectionEvent event, {String? reason}) async {
    debugPrint('ConnectionStateMachine: Handling event $event with reason: $reason');
    
    // Xử lý sự kiện theo trạng thái hiện tại
    switch (_currentState.state) {
      case ConnectionState.initial:
        await _handleInitialStateEvent(event, reason);
        break;
        
      case ConnectionState.connecting:
        await _handleConnectingStateEvent(event, reason);
        break;
        
      case ConnectionState.connected:
        await _handleConnectedStateEvent(event, reason);
        break;
        
      case ConnectionState.reconnecting:
        await _handleReconnectingStateEvent(event, reason);
        break;
        
      case ConnectionState.waitingForNetwork:
        await _handleWaitingForNetworkStateEvent(event, reason);
        break;
        
      case ConnectionState.disconnected:
        await _handleDisconnectedStateEvent(event, reason);
        break;
        
      case ConnectionState.error:
        await _handleErrorStateEvent(event, reason);
        break;
        
      case ConnectionState.closed:
        await _handleClosedStateEvent(event, reason);
        break;
    }
  }
  
  /// Cập nhật health state
  void updateHealthState(ConnectionHealthState healthState, String reason) {
    // Cập nhật trạng thái kết nối nếu health state thay đổi
    if (_currentState.healthState != healthState) {
      _setState(_currentState.copyWith(
        healthState: healthState,
        reason: reason,
      ));
      
      // Nếu phát hiện zombie, gửi sự kiện zombieDetected
      if (healthState == ConnectionHealthState.zombie) {
        handleEvent(ConnectionEvent.zombieDetected, reason: 'Phát hiện zombie connection');
      }
      // Nếu trạng thái kết nối bị xuống cấp, gửi sự kiện connectionDegraded
      else if (healthState == ConnectionHealthState.degraded) {
        handleEvent(ConnectionEvent.connectionDegraded, reason: 'Kết nối không ổn định');
      }
    }
  }
  
  /// Xử lý sự kiện ở trạng thái Initial
  Future<void> _handleInitialStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.connectRequested:
        _setState(ConnectionStateModel(
          state: ConnectionState.connecting,
          reason: reason ?? 'Đang kết nối...',
        ));
        
        try {
          final success = await _connectCallback();
          
          if (success) {
            handleEvent(ConnectionEvent.connectionEstablished, reason: 'Kết nối thành công');
          } else {
            handleEvent(ConnectionEvent.connectionFailed, reason: 'Kết nối thất bại');
          }
        } catch (e) {
          handleEvent(ConnectionEvent.connectionError, reason: 'Lỗi khi kết nối: $e');
        }
        break;
        
      case ConnectionEvent.reset:
        // Đã ở initial, không cần làm gì
        break;
        
      default:
        // Các event khác không xử lý ở initial state
        break;
    }
  }
  
  /// Xử lý sự kiện ở trạng thái Connecting
  Future<void> _handleConnectingStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.connectionEstablished:
        _backoffStrategy.reset();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.connected,
          reason: reason ?? 'Kết nối thành công',
        ));
        break;
        
      case ConnectionEvent.connectionFailed:
      case ConnectionEvent.connectionError:
        if (_autoReconnect) {
          _setState(ConnectionStateModel(
            state: ConnectionState.reconnecting,
            reason: reason ?? 'Kết nối thất bại, đang thử lại...',
            reconnectAttempts: 1,
          ));
          
          _scheduleReconnect();
        } else {
          _setState(ConnectionStateModel(
            state: ConnectionState.error,
            reason: reason ?? 'Kết nối thất bại',
          ));
        }
        break;
        
      case ConnectionEvent.networkLost:
        _setState(ConnectionStateModel(
          state: ConnectionState.waitingForNetwork,
          reason: reason ?? 'Mạng bị mất, đang chờ khôi phục...',
        ));
        break;
        
      case ConnectionEvent.disconnectRequested:
        await _disconnectCallback();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.disconnected,
          reason: reason ?? 'Ngắt kết nối theo yêu cầu',
        ));
        break;
        
      case ConnectionEvent.reset:
        await _disconnectCallback();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.initial,
          reason: 'Đã reset',
        ));
        break;
        
      default:
        // Các event khác không xử lý ở connecting state
        break;
    }
  }
  
  /// Xử lý sự kiện ở trạng thái Connected
  Future<void> _handleConnectedStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.disconnectRequested:
        await _disconnectCallback();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.disconnected,
          reason: reason ?? 'Ngắt kết nối theo yêu cầu',
        ));
        break;
        
      case ConnectionEvent.connectionClosed:
      case ConnectionEvent.connectionError:
        if (_autoReconnect) {
          _setState(ConnectionStateModel(
            state: ConnectionState.reconnecting,
            reason: reason ?? 'Kết nối bị đóng, đang thử kết nối lại...',
            reconnectAttempts: 1,
          ));
          
          _scheduleReconnect();
        } else {
          _setState(ConnectionStateModel(
            state: ConnectionState.closed,
            reason: reason ?? 'Kết nối bị đóng',
          ));
        }
        break;
        
      case ConnectionEvent.networkLost:
        _setState(ConnectionStateModel(
          state: ConnectionState.waitingForNetwork,
          reason: reason ?? 'Mạng bị mất, đang chờ khôi phục...',
        ));
        break;
        
      case ConnectionEvent.zombieDetected:
        // Phát hiện zombie connection, thử kết nối lại
        await _disconnectCallback();
        
        if (_autoReconnect) {
          _setState(ConnectionStateModel(
            state: ConnectionState.reconnecting,
            reason: reason ?? 'Phát hiện zombie connection, đang thử kết nối lại...',
            reconnectAttempts: 1,
          ));
          
          _scheduleReconnect();
        } else {
          _setState(ConnectionStateModel(
            state: ConnectionState.error,
            reason: reason ?? 'Phát hiện zombie connection',
          ));
        }
        break;
        
      case ConnectionEvent.connectionDegraded:
        // Kết nối không ổn định, có thể cần thử kết nối lại
        // Chỉ ghi nhận trạng thái, không thay đổi state
        _setState(_currentState.copyWith(
          reason: reason ?? 'Kết nối không ổn định',
        ));
        break;
        
      case ConnectionEvent.reset:
        await _disconnectCallback();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.initial,
          reason: 'Đã reset',
        ));
        break;
        
      default:
        // Các event khác không xử lý ở connected state
        break;
    }
  }
  
  /// Xử lý sự kiện ở trạng thái Reconnecting
  Future<void> _handleReconnectingStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.connectionEstablished:
        _backoffStrategy.reset();
        _cancelReconnectTimer();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.connected,
          reason: reason ?? 'Kết nối lại thành công',
        ));
        break;
        
      case ConnectionEvent.reconnectAttempted:
        try {
          final success = await _connectCallback();
          
          if (success) {
            handleEvent(ConnectionEvent.connectionEstablished, reason: 'Kết nối lại thành công');
          } else {
            // Tăng số lần thử
            final attempts = _currentState.reconnectAttempts + 1;
            
            // Kiểm tra xem đã vượt quá số lần thử tối đa chưa
            if (attempts >= _maxReconnectAttempts) {
              handleEvent(ConnectionEvent.reconnectExhausted, 
                reason: 'Đã thử kết nối lại $attempts lần nhưng không thành công');
            } else {
              _setState(_currentState.copyWith(
                reconnectAttempts: attempts,
                reason: 'Kết nối lại thất bại, lần thử $attempts/$_maxReconnectAttempts',
              ));
              
              _scheduleReconnect();
            }
          }
        } catch (e) {
          // Tăng số lần thử
          final attempts = _currentState.reconnectAttempts + 1;
          
          // Kiểm tra xem đã vượt quá số lần thử tối đa chưa
          if (attempts >= _maxReconnectAttempts) {
            handleEvent(ConnectionEvent.reconnectExhausted, 
              reason: 'Đã thử kết nối lại $attempts lần nhưng gặp lỗi: $e');
          } else {
            _setState(_currentState.copyWith(
              reconnectAttempts: attempts,
              reason: 'Lỗi khi thử kết nối lại: $e, lần thử $attempts/$_maxReconnectAttempts',
            ));
            
            _scheduleReconnect();
          }
        }
        break;
        
      case ConnectionEvent.reconnectExhausted:
        _cancelReconnectTimer();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.error,
          reason: reason ?? 'Đã vượt quá số lần thử kết nối lại',
          reconnectAttempts: _currentState.reconnectAttempts,
        ));
        break;
        
      case ConnectionEvent.networkLost:
        _cancelReconnectTimer();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.waitingForNetwork,
          reason: reason ?? 'Mạng bị mất trong khi đang thử kết nối lại',
          reconnectAttempts: _currentState.reconnectAttempts,
        ));
        break;
        
      case ConnectionEvent.disconnectRequested:
        _cancelReconnectTimer();
        await _disconnectCallback();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.disconnected,
          reason: reason ?? 'Ngắt kết nối theo yêu cầu',
        ));
        break;
        
      case ConnectionEvent.reset:
        _cancelReconnectTimer();
        await _disconnectCallback();
        
        _backoffStrategy.reset();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.initial,
          reason: 'Đã reset',
        ));
        break;
        
      default:
        // Các event khác không xử lý ở reconnecting state
        break;
    }
  }
  
  /// Xử lý sự kiện ở trạng thái WaitingForNetwork
  Future<void> _handleWaitingForNetworkStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.networkRestored:
        _setState(ConnectionStateModel(
          state: ConnectionState.reconnecting,
          reason: reason ?? 'Mạng đã được khôi phục, đang thử kết nối lại',
          reconnectAttempts: 1,
        ));
        
        _backoffStrategy.reset();
        _scheduleReconnect(delay: 1000); // Đợi 1s để mạng ổn định
        break;
        
      case ConnectionEvent.disconnectRequested:
        await _disconnectCallback();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.disconnected,
          reason: reason ?? 'Ngắt kết nối theo yêu cầu',
        ));
        break;
        
      case ConnectionEvent.reset:
        await _disconnectCallback();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.initial,
          reason: 'Đã reset',
        ));
        break;
        
      default:
        // Các event khác không xử lý ở waiting for network state
        break;
    }
  }
  
  /// Xử lý sự kiện ở trạng thái Disconnected
  Future<void> _handleDisconnectedStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.connectRequested:
        _setState(ConnectionStateModel(
          state: ConnectionState.connecting,
          reason: reason ?? 'Đang kết nối...',
        ));
        
        try {
          final success = await _connectCallback();
          
          if (success) {
            handleEvent(ConnectionEvent.connectionEstablished, reason: 'Kết nối thành công');
          } else {
            handleEvent(ConnectionEvent.connectionFailed, reason: 'Kết nối thất bại');
          }
        } catch (e) {
          handleEvent(ConnectionEvent.connectionError, reason: 'Lỗi khi kết nối: $e');
        }
        break;
        
      case ConnectionEvent.reset:
        _setState(ConnectionStateModel(
          state: ConnectionState.initial,
          reason: 'Đã reset',
        ));
        break;
        
      default:
        // Các event khác không xử lý ở disconnected state
        break;
    }
  }
  
  /// Xử lý sự kiện ở trạng thái Error
  Future<void> _handleErrorStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.connectRequested:
        _backoffStrategy.reset();
        
        _setState(ConnectionStateModel(
          state: ConnectionState.connecting,
          reason: reason ?? 'Đang thử kết nối lại sau lỗi...',
        ));
        
        try {
          final success = await _connectCallback();
          
          if (success) {
            handleEvent(ConnectionEvent.connectionEstablished, reason: 'Kết nối thành công');
          } else {
            handleEvent(ConnectionEvent.connectionFailed, reason: 'Kết nối thất bại');
          }
        } catch (e) {
          handleEvent(ConnectionEvent.connectionError, reason: 'Lỗi khi kết nối: $e');
        }
        break;
        
      case ConnectionEvent.reset:
        _setState(ConnectionStateModel(
          state: ConnectionState.initial,
          reason: 'Đã reset',
        ));
        break;
        
      default:
        // Các event khác không xử lý ở error state
        break;
    }
  }
  
  /// Xử lý sự kiện ở trạng thái Closed
  Future<void> _handleClosedStateEvent(ConnectionEvent event, String? reason) async {
    switch (event) {
      case ConnectionEvent.connectRequested:
        _setState(ConnectionStateModel(
          state: ConnectionState.connecting,
          reason: reason ?? 'Đang kết nối lại sau khi đóng...',
        ));
        
        try {
          final success = await _connectCallback();
          
          if (success) {
            handleEvent(ConnectionEvent.connectionEstablished, reason: 'Kết nối thành công');
          } else {
            handleEvent(ConnectionEvent.connectionFailed, reason: 'Kết nối thất bại');
          }
        } catch (e) {
          handleEvent(ConnectionEvent.connectionError, reason: 'Lỗi khi kết nối: $e');
        }
        break;
        
      case ConnectionEvent.reset:
        _setState(ConnectionStateModel(
          state: ConnectionState.initial,
          reason: 'Đã reset',
        ));
        break;
        
      default:
        // Các event khác không xử lý ở closed state
        break;
    }
  }
  
  /// Lập lịch kết nối lại
  void _scheduleReconnect({int? delay}) {
    _cancelReconnectTimer();
    
    // Tính toán thời gian delay
    final reconnectDelay = delay ?? _backoffStrategy.nextDelay();
    
    debugPrint('Đặt lịch kết nối lại sau ${reconnectDelay}ms');
    
    _reconnectTimer = Timer(Duration(milliseconds: reconnectDelay), () {
      handleEvent(ConnectionEvent.reconnectAttempted, 
        reason: 'Đang thử kết nối lại (lần ${_currentState.reconnectAttempts + 1})...');
    });
  }
  
  /// Hủy timer kết nối lại
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Cập nhật trạng thái
  void _setState(ConnectionStateModel newState) {
    if (_currentState.state != newState.state || 
        _currentState.reason != newState.reason ||
        _currentState.reconnectAttempts != newState.reconnectAttempts ||
        _currentState.healthState != newState.healthState) {
      _currentState = newState;
      _stateSubject.add(newState);
      
      debugPrint('ConnectionStateMachine: State changed to ${newState.state} (${newState.reason})');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _cancelReconnectTimer();
    _stateSubject.close();
  }
} 