import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Định nghĩa kiểu kết nối
enum ConnectionType {
  /// Wifi
  wifi,
  
  /// Dữ liệu di động
  mobile,
  
  /// Ethernet
  ethernet,
  
  /// Bluetooth
  bluetooth,
  
  /// VPN
  vpn,
  
  /// Kiểu kết nối khác
  other,
  
  /// Không có kết nối
  none,
}

/// Định nghĩa chất lượng kết nối
enum ConnectionQuality {
  /// Không có kết nối
  none,
  
  /// Kết nối kém
  poor,
  
  /// Kết nối trung bình
  fair,
  
  /// Kết nối tốt
  good,
  
  /// Kết nối rất tốt
  excellent,
}

/// Interface cho service quản lý kết nối
abstract class IConnectivityService {
  /// Stream thông báo thay đổi trạng thái kết nối
  Stream<List<ConnectionType>> get connectivityStream;
  
  /// Stream thông báo thay đổi chất lượng kết nối
  Stream<ConnectionQuality> get qualityStream;
  
  /// Stream phát ra true/false khi có/mất kết nối
  Stream<bool> get onConnectivityChanged;
  
  /// Các loại kết nối hiện tại
  List<ConnectionType> get currentConnectivity;
  
  /// Chất lượng kết nối hiện tại
  ConnectionQuality get currentQuality;
  
  /// Kiểm tra có kết nối không
  Future<bool> isConnected();
  
  /// Kiểm tra có kết nối Wifi không
  Future<bool> isWifiConnected();
  
  /// Kiểm tra có kết nối dữ liệu di động không
  Future<bool> isMobileConnected();
  
  /// Kiểm tra có thể kết nối đến server không
  Future<bool> canConnectToServer(String host, int port, {Duration timeout});
  
  /// Ping một địa chỉ
  Future<int?> pingHost(String host, {int count = 3});
}

/// Implementation của IConnectivityService
@lazySingleton
class ConnectivityServiceImpl implements IConnectivityService {
  /// Plugin connectivity
  final Connectivity _connectivity;
  
  /// Subject cho trạng thái kết nối
  final BehaviorSubject<List<ConnectionType>> _connectivitySubject;
  
  /// Subject cho chất lượng kết nối
  final BehaviorSubject<ConnectionQuality> _qualitySubject;
  
  /// Trạng thái kết nối hiện tại
  List<ConnectionType> _currentConnectivity = [ConnectionType.none];
  
  /// Chất lượng kết nối hiện tại
  ConnectionQuality _currentQuality = ConnectionQuality.none;
  
  /// Timer để kiểm tra định kỳ
  Timer? _periodicCheckTimer;
  
  /// Thời gian kiểm tra gần nhất
  DateTime? _lastCheckTime;
  
  /// Thời gian kiểm tra định kỳ (ms)
  static const int _periodicCheckInterval = 60000; // 1 phút
  
  /// Constructor
  @factoryMethod
  ConnectivityServiceImpl(this._connectivity)
      : _connectivitySubject = BehaviorSubject.seeded([ConnectionType.none]),
        _qualitySubject = BehaviorSubject.seeded(ConnectionQuality.none) {
    _initialize();
  }
  
  /// Khởi tạo service
  Future<void> _initialize() async {
    // Lắng nghe thay đổi kết nối
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Kiểm tra kết nối ban đầu
    await _checkConnectivity();
    
    // Thiết lập kiểm tra định kỳ
    _periodicCheckTimer = Timer.periodic(
      const Duration(milliseconds: _periodicCheckInterval),
      (_) => _checkNetworkQuality(),
    );
  }
  
  @override
  Stream<List<ConnectionType>> get connectivityStream => _connectivitySubject.stream;
  
  @override
  Stream<ConnectionQuality> get qualityStream => _qualitySubject.stream;
  
  @override
  Stream<bool> get onConnectivityChanged => _connectivitySubject.stream.map((types) => 
      types.isNotEmpty && !types.contains(ConnectionType.none));
  
  @override
  List<ConnectionType> get currentConnectivity => _currentConnectivity;
  
  @override
  ConnectionQuality get currentQuality => _currentQuality;
  
  @override
  Future<bool> isConnected() async {
    if (_lastCheckTime != null && 
        DateTime.now().difference(_lastCheckTime!).inSeconds < 5) {
      // Dùng kết quả gần nhất nếu mới kiểm tra gần đây
      return _currentConnectivity.any((type) => type != ConnectionType.none);
    }
    
    await _checkConnectivity();
    return _currentConnectivity.any((type) => type != ConnectionType.none);
  }
  
  @override
  Future<bool> isWifiConnected() async {
    await _checkConnectivity();
    return _currentConnectivity.contains(ConnectionType.wifi);
  }
  
  @override
  Future<bool> isMobileConnected() async {
    await _checkConnectivity();
    return _currentConnectivity.contains(ConnectionType.mobile);
  }
  
  @override
  Future<bool> canConnectToServer(String host, int port, {Duration? timeout}) async {
    timeout ??= const Duration(seconds: 5);
    
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<int?> pingHost(String host, {int count = 3}) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        int totalTime = 0;
        int successCount = 0;
        
        for (int i = 0; i < count; i++) {
          final stopwatch = Stopwatch()..start();
          
          final success = await canConnectToServer(host, 80);
          
          stopwatch.stop();
          
          if (success) {
            totalTime += stopwatch.elapsedMilliseconds;
            successCount++;
          }
          
          // Đợi một chút giữa các lần ping
          if (i < count - 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        
        if (successCount > 0) {
          return totalTime ~/ successCount;
        }
      } catch (e) {
        debugPrint('Error pinging host: $e');
      }
    }
    
    return null;
  }
  
  /// Kiểm tra kết nối mạng
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _handleConnectivityChange(connectivityResult);
      _lastCheckTime = DateTime.now();
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      
      // Giả định là không có kết nối nếu lỗi
      _updateConnectivityState([ConnectionType.none]);
    }
  }
  
  /// Xử lý thay đổi kết nối
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      _updateConnectivityState([ConnectionType.none]);
      return;
    }
    
    final connectionTypes = <ConnectionType>[];
    
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          connectionTypes.add(ConnectionType.wifi);
          break;
        case ConnectivityResult.mobile:
          connectionTypes.add(ConnectionType.mobile);
          break;
        case ConnectivityResult.ethernet:
          connectionTypes.add(ConnectionType.ethernet);
          break;
        case ConnectivityResult.bluetooth:
          connectionTypes.add(ConnectionType.bluetooth);
          break;
        case ConnectivityResult.vpn:
          connectionTypes.add(ConnectionType.vpn);
          break;
        case ConnectivityResult.other:
          connectionTypes.add(ConnectionType.other);
          break;
        default:
          // Không thêm vào danh sách nếu là none
          break;
      }
    }
    
    if (connectionTypes.isEmpty) {
      connectionTypes.add(ConnectionType.none);
    }
    
    _updateConnectivityState(connectionTypes);
    
    // Kiểm tra chất lượng mạng khi kết nối thay đổi
    _checkNetworkQuality();
  }
  
  /// Cập nhật trạng thái kết nối
  void _updateConnectivityState(List<ConnectionType> types) {
    // Chỉ cập nhật và phát sự kiện nếu có thay đổi thực sự
    if (!_areListsEqual(_currentConnectivity, types)) {
      _currentConnectivity = types;
      
      if (!_connectivitySubject.isClosed) {
        _connectivitySubject.add(types);
      }
      
      debugPrint('Connectivity changed: $types');
    }
  }
  
  /// Kiểm tra chất lượng mạng
  Future<void> _checkNetworkQuality() async {
    if (_currentConnectivity.contains(ConnectionType.none)) {
      _updateQualityState(ConnectionQuality.none);
      return;
    }
    
    // Ping Google DNS để kiểm tra chất lượng kết nối
    final pingTime = await pingHost('8.8.8.8');
    
    if (pingTime == null) {
      // Không ping được, thử kiểm tra kết nối đến Google
      final canConnect = await canConnectToServer('google.com', 80);
      if (canConnect) {
        // Có thể kết nối nhưng ping không được, coi như chất lượng trung bình
        _updateQualityState(ConnectionQuality.fair);
      } else {
        // Không thể kết nối, coi như không có kết nối
        _updateQualityState(ConnectionQuality.none);
      }
      return;
    }
    
    // Xác định chất lượng dựa trên thời gian ping
    final quality = _determineQualityFromPing(pingTime);
    _updateQualityState(quality);
  }
  
  /// Xác định chất lượng dựa trên ping time
  ConnectionQuality _determineQualityFromPing(int pingTime) {
    if (pingTime < 50) {
      return ConnectionQuality.excellent;
    } else if (pingTime < 100) {
      return ConnectionQuality.good;
    } else if (pingTime < 200) {
      return ConnectionQuality.fair;
    } else {
      return ConnectionQuality.poor;
    }
  }
  
  /// Cập nhật trạng thái chất lượng kết nối
  void _updateQualityState(ConnectionQuality quality) {
    if (quality != _currentQuality) {
      _currentQuality = quality;
      
      if (!_qualitySubject.isClosed) {
        _qualitySubject.add(quality);
      }
      
      debugPrint('Connection quality changed: $quality');
    }
  }
  
  /// So sánh hai danh sách
  bool _areListsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    
    return true;
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _periodicCheckTimer?.cancel();
    _connectivitySubject.close();
    _qualitySubject.close();
  }
} 