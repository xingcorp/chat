import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Dịch vụ theo dõi và quản lý kết nối mạng
@singleton
class ConnectivityService {
  /// Loại kết nối hiện tại
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  
  /// Stream phát ra kết nối hiện tại
  final _connectionController = StreamController<ConnectivityResult>.broadcast();
  
  /// Stream phát ra thông tin có kết nối mạng không
  final _hasConnectionController = StreamController<bool>.broadcast();
  
  /// Logger
  final _logger = Logger();
  
  /// Đối tượng Connectivity Plus
  final Connectivity _connectivity;
  
  /// Subscription cho thay đổi kết nối
  StreamSubscription<ConnectivityResult>? _subscription;
  
  /// Thời gian kiểm tra kết nối lần cuối
  DateTime _lastCheck = DateTime.now();
  
  /// Thời gian tối thiểu giữa các lần kiểm tra
  static const Duration _minCheckInterval = Duration(seconds: 2);
  
  /// Constructor
  ConnectivityService(this._connectivity) {
    _initialize();
  }
  
  /// Stream phát ra trạng thái kết nối
  Stream<ConnectivityResult> get onStatusChanged => 
      _connectionController.stream;
  
  /// Stream phát ra thông tin có kết nối hay không
  Stream<bool> get onConnectivityChanged => 
      _hasConnectionController.stream;
  
  /// Getter cho loại kết nối hiện tại
  ConnectivityResult get connectionStatus => _connectionStatus;
  
  /// Kiểm tra xem hiện tại có kết nối hay không
  bool get hasConnection => 
      _connectionStatus != ConnectivityResult.none;
  
  /// Kiểm tra có phải kết nối Wi-Fi không
  bool get isWifi => _connectionStatus == ConnectivityResult.wifi;
  
  /// Kiểm tra có phải kết nối di động không
  bool get isMobile => _connectionStatus == ConnectivityResult.mobile;
  
  /// Khởi tạo service và lắng nghe sự kiện thay đổi
  void _initialize() async {
    try {
      // Lấy trạng thái kết nối ban đầu
      _connectionStatus = await _connectivity.checkConnectivity();
      _emitCurrentState();
      
      // Đăng ký lắng nghe thay đổi kết nối
      _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      
      _logger.i('Connectivity Service initialized. Initial status: $_connectionStatus');
    } catch (e) {
      _logger.e('Error initializing Connectivity Service: $e');
    }
  }
  
  /// Cập nhật trạng thái kết nối khi có thay đổi
  void _updateConnectionStatus(ConnectivityResult result) {
    final now = DateTime.now();
    if (now.difference(_lastCheck) < _minCheckInterval) {
      // Tránh spam quá nhiều sự kiện trong thời gian ngắn
      return;
    }
    
    _lastCheck = now;
    
    // Chỉ cập nhật nếu thực sự thay đổi
    if (result != _connectionStatus) {
      _logger.d('Connection status changed: $_connectionStatus -> $result');
      _connectionStatus = result;
      _emitCurrentState();
    }
  }
  
  /// Phát ra trạng thái hiện tại
  void _emitCurrentState() {
    _connectionController.add(_connectionStatus);
    _hasConnectionController.add(_connectionStatus != ConnectivityResult.none);
  }
  
  /// Kiểm tra kết nối thủ công
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return result;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return ConnectivityResult.none;
    }
  }
  
  /// Kiểm tra có kết nối không
  Future<bool> isConnected() async {
    final result = await checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
    _hasConnectionController.close();
    _logger.d('Connectivity Service disposed');
  }
} 