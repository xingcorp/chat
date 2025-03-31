import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Phân loại chất lượng mạng
enum NetworkQuality {
  /// Không có kết nối
  none,
  
  /// Kết nối yếu (2G hoặc kết nối không ổn định)
  poor,
  
  /// Kết nối trung bình (3G)
  fair,
  
  /// Kết nối tốt (4G, WiFi)
  good,
  
  /// Kết nối rất tốt (WiFi ổn định, 5G)
  excellent,
}

/// Service phân tích và theo dõi tình trạng kết nối mạng
@lazySingleton
class ConnectivityAnalyzerService {
  /// Plugin kết nối
  final Connectivity _connectivity = Connectivity();
  
  /// Stream thông báo thay đổi kết nối
  final BehaviorSubject<ConnectivityResult> _connectivityStream = BehaviorSubject();
  
  /// Stream thông báo thay đổi chất lượng mạng
  final BehaviorSubject<NetworkQuality> _qualityStream = BehaviorSubject();
  
  /// Stream controller cho ping
  final StreamController<int> _pingResultController = StreamController.broadcast();
  
  /// Kết nối hiện tại
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  
  /// Chất lượng mạng hiện tại
  NetworkQuality _currentQuality = NetworkQuality.none;
  
  /// Các máy chủ dùng để ping
  final List<String> _pingServers = [
    'google.com',
    'cloudflare.com',
    '1.1.1.1',
  ];
  
  /// Ngưỡng ping (ms) để xác định chất lượng
  static const Map<NetworkQuality, int> _pingThresholds = {
    NetworkQuality.excellent: 50,   // <= 50ms: Rất tốt
    NetworkQuality.good: 100,       // <= 100ms: Tốt
    NetworkQuality.fair: 200,       // <= 200ms: Trung bình
    NetworkQuality.poor: 300,       // <= 300ms: Kém
  };
  
  /// Timer để kiểm tra định kỳ
  Timer? _periodicCheckTimer;
  
  /// Constructor
  ConnectivityAnalyzerService() {
    _initialize();
  }
  
  /// Stream theo dõi trạng thái kết nối (ConnectivityResult)
  Stream<ConnectivityResult> get connectivityStream => _connectivityStream.stream;
  
  /// Stream theo dõi chất lượng mạng (NetworkQuality)
  Stream<NetworkQuality> get qualityStream => _qualityStream.stream;
  
  /// Stream theo dõi kết quả ping (ms)
  Stream<int> get pingResultStream => _pingResultController.stream;
  
  /// Getter cho trạng thái kết nối hiện tại
  ConnectivityResult get currentConnectivity => _currentConnectivity;
  
  /// Getter cho chất lượng mạng hiện tại
  NetworkQuality get currentQuality => _currentQuality;
  
  /// Kiểm tra có đang offline không
  bool get isOffline => _currentConnectivity == ConnectivityResult.none;
  
  /// Khởi tạo service
  void _initialize() async {
    // Lấy trạng thái kết nối ban đầu
    _currentConnectivity = await _connectivity.checkConnectivity();
    _connectivityStream.add(_currentConnectivity);
    
    // Đăng ký lắng nghe thay đổi kết nối
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Thực hiện kiểm tra chất lượng mạng ngay lập tức
    _checkNetworkQuality();
    
    // Thiết lập kiểm tra định kỳ
    _periodicCheckTimer = Timer.periodic(
      const Duration(minutes: 2), 
      (_) => _checkNetworkQuality(),
    );
  }
  
  /// Hủy bỏ tài nguyên
  void dispose() {
    _connectivityStream.close();
    _qualityStream.close();
    _pingResultController.close();
    _periodicCheckTimer?.cancel();
  }
  
  /// Xử lý khi kết nối thay đổi
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    debugPrint('Kết nối thay đổi: $result');
    
    // Cập nhật trạng thái và thông báo
    _currentConnectivity = result;
    _connectivityStream.add(result);
    
    // Nếu không có kết nối, cập nhật chất lượng mạng và thông báo
    if (result == ConnectivityResult.none) {
      _updateNetworkQuality(NetworkQuality.none);
    } else {
      // Nếu có kết nối, kiểm tra chất lượng
      _checkNetworkQuality();
    }
  }
  
  /// Kiểm tra chất lượng mạng hiện tại
  Future<void> _checkNetworkQuality() async {
    // Nếu không có kết nối, bỏ qua kiểm tra
    if (_currentConnectivity == ConnectivityResult.none) {
      _updateNetworkQuality(NetworkQuality.none);
      return;
    }
    
    try {
      // Thực hiện ping và lấy thời gian trung bình
      final int pingTime = await _performNetworkPing();
      
      // Xác định chất lượng mạng dựa trên thời gian ping
      final quality = _determineNetworkQuality(pingTime);
      
      // Cập nhật chất lượng mạng
      _updateNetworkQuality(quality);
    } catch (e) {
      debugPrint('Lỗi kiểm tra chất lượng mạng: $e');
      
      // Nếu không thực hiện được ping, giả định kết nối kém
      if (_currentConnectivity != ConnectivityResult.none) {
        _updateNetworkQuality(NetworkQuality.poor);
      }
    }
  }
  
  /// Thực hiện ping để đo tốc độ mạng
  Future<int> _performNetworkPing() async {
    final List<int> pingTimes = [];
    
    // Thử ping từng máy chủ
    for (final server in _pingServers) {
      try {
        final stopwatch = Stopwatch()..start();
        
        // Thực hiện ping bằng cách gửi HTTP request
        final socket = await Socket.connect(server, 80, 
          timeout: const Duration(seconds: 5)
        );
        socket.destroy();
        
        final elapsed = stopwatch.elapsedMilliseconds;
        stopwatch.stop();
        
        pingTimes.add(elapsed);
        _pingResultController.add(elapsed);
        
        // Nếu đã ping thành công ít nhất một máy chủ, trả về kết quả
        if (pingTimes.isNotEmpty) {
          break;
        }
      } catch (e) {
        debugPrint('Lỗi ping $server: $e');
        // Tiếp tục thử máy chủ khác
      }
    }
    
    // Nếu không ping được máy chủ nào, ném ngoại lệ
    if (pingTimes.isEmpty) {
      throw Exception('Không thể ping đến bất kỳ máy chủ nào');
    }
    
    // Trả về thời gian ping (lấy giá trị nhỏ nhất để loại bỏ các biến động)
    return pingTimes.reduce((min, time) => min < time ? min : time);
  }
  
  /// Xác định chất lượng mạng dựa trên ping
  NetworkQuality _determineNetworkQuality(int pingTime) {
    // Dựa vào thời gian ping và loại kết nối
    if (pingTime <= _pingThresholds[NetworkQuality.excellent]!) {
      return NetworkQuality.excellent;
    } else if (pingTime <= _pingThresholds[NetworkQuality.good]!) {
      return NetworkQuality.good;
    } else if (pingTime <= _pingThresholds[NetworkQuality.fair]!) {
      return NetworkQuality.fair;
    } else if (pingTime <= _pingThresholds[NetworkQuality.poor]!) {
      return NetworkQuality.poor;
    } else {
      return NetworkQuality.poor;
    }
  }
  
  /// Cập nhật chất lượng mạng và thông báo
  void _updateNetworkQuality(NetworkQuality quality) {
    // Chỉ cập nhật nếu có thay đổi
    if (_currentQuality != quality) {
      debugPrint('Chất lượng mạng thay đổi: $quality');
      _currentQuality = quality;
      _qualityStream.add(quality);
    }
  }
  
  /// Kiểm tra xem có nên tự động tải xuống phương tiện dựa trên kết nối
  bool shouldAutoDownloadMedia(int fileSizeInBytes) {
    // Định nghĩa ngưỡng tự động tải xuống dựa trên chất lượng mạng
    final Map<NetworkQuality, int> autoDownloadThresholds = {
      NetworkQuality.excellent: 50 * 1024 * 1024,  // 50MB
      NetworkQuality.good: 15 * 1024 * 1024,       // 15MB
      NetworkQuality.fair: 5 * 1024 * 1024,        // 5MB
      NetworkQuality.poor: 1 * 1024 * 1024,        // 1MB
      NetworkQuality.none: 0,                      // 0MB (không tải)
    };
    
    // Nếu đang sử dụng dữ liệu di động, áp dụng ngưỡng thấp hơn
    if (_currentConnectivity == ConnectivityResult.mobile) {
      // Giảm ngưỡng xuống 1/3 so với WiFi
      return fileSizeInBytes <= (autoDownloadThresholds[_currentQuality]! ~/ 3);
    }
    
    // Nếu là WiFi hoặc kết nối khác, áp dụng ngưỡng đầy đủ
    return fileSizeInBytes <= autoDownloadThresholds[_currentQuality]!;
  }
  
  /// Xác định chất lượng video nên sử dụng dựa trên kết nối
  int getOptimalVideoQuality() {
    // Định nghĩa chất lượng video (p) dựa trên chất lượng mạng
    final Map<NetworkQuality, int> videoQualityMap = {
      NetworkQuality.excellent: 1080,  // Full HD
      NetworkQuality.good: 720,        // HD
      NetworkQuality.fair: 480,        // SD
      NetworkQuality.poor: 360,        // Low
      NetworkQuality.none: 240,        // Very Low
    };
    
    return videoQualityMap[_currentQuality]!;
  }
  
  /// Xác định có nên sử dụng chế độ tiết kiệm dữ liệu hay không
  bool shouldUseLowDataMode() {
    // Trên dữ liệu di động hoặc mạng yếu, sử dụng chế độ tiết kiệm
    return _currentConnectivity == ConnectivityResult.mobile || 
           _currentQuality == NetworkQuality.poor;
  }
  
  /// Cấu hình thời gian chờ HTTP request dựa trên chất lượng mạng
  Duration getOptimalHttpTimeout() {
    // Định nghĩa thời gian chờ (giây) dựa trên chất lượng mạng
    final Map<NetworkQuality, int> timeoutMap = {
      NetworkQuality.excellent: 30,  // 30s
      NetworkQuality.good: 45,       // 45s
      NetworkQuality.fair: 60,       // 60s 
      NetworkQuality.poor: 90,       // 90s
      NetworkQuality.none: 120,      // 120s
    };
    
    return Duration(seconds: timeoutMap[_currentQuality]!);
  }
  
  /// Kiểm tra xem kết nối có đủ tốt để thực hiện cuộc gọi video không
  bool canMakeVideoCall() {
    return _currentQuality == NetworkQuality.good || 
           _currentQuality == NetworkQuality.excellent;
  }
  
  /// Kiểm tra xem kết nối có đủ tốt để thực hiện cuộc gọi audio không
  bool canMakeAudioCall() {
    return _currentQuality != NetworkQuality.none;
  }
  
  /// Thực hiện kiểm tra chất lượng mạng
  Future<NetworkQuality> checkCurrentNetworkQuality() async {
    await _checkNetworkQuality();
    return _currentQuality;
  }
  
  /// Kiểm tra kết nối đến máy chủ cụ thể
  Future<bool> checkConnectionToServer(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final socket = await Socket.connect(
        uri.host, 
        uri.port > 0 ? uri.port : 80,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (e) {
      debugPrint('Không thể kết nối đến $serverUrl: $e');
      return false;
    }
  }
} 