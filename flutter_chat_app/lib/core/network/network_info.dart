import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// Abstract class định nghĩa interface cho các phương thức kiểm tra kết nối
abstract class NetworkInfo {
  /// Kiểm tra thiết bị có kết nối internet không
  Future<bool> get isConnected;
  
  /// Lấy về loại kết nối hiện tại
  Future<ConnectivityResult> get connectionType;
  
  /// Stream về sự thay đổi trạng thái kết nối
  Stream<ConnectivityResult> get onConnectivityChanged;
  
  /// Kiểm tra xem kết nối hiện tại có phải là WiFi không
  Future<bool> get isWifi;
  
  /// Kiểm tra xem kết nối hiện tại có phải là dữ liệu di động không
  Future<bool> get isMobile;
  
  /// Lắng nghe sự thay đổi kết nối và thực hiện callback
  StreamSubscription<ConnectivityResult> listenConnectivity(
      Function(ConnectivityResult) onChange);
}

/// Triển khai của NetworkInfo sử dụng connectivity_plus
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  
  NetworkInfoImpl({required this.connectivity});
  
  @override
  Future<bool> get isConnected async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  @override
  Future<ConnectivityResult> get connectionType async {
    return await connectivity.checkConnectivity();
  }
  
  @override
  Stream<ConnectivityResult> get onConnectivityChanged {
    return connectivity.onConnectivityChanged;
  }
  
  @override
  Future<bool> get isWifi async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }
  
  @override
  Future<bool> get isMobile async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile;
  }
  
  @override
  StreamSubscription<ConnectivityResult> listenConnectivity(
      Function(ConnectivityResult) onChange) {
    return connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      LogUtils.d('NetworkInfo', 'Connectivity changed: $result');
      onChange(result);
    });
  }
} 