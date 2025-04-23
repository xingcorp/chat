import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

/// Interface cho dịch vụ thông tin kết nối
abstract class IConnectionInfo {
  /// Kiểm tra thiết bị có kết nối internet không
  Future<bool> get isConnected;
  
  /// Lấy về loại kết nối hiện tại
  Future<List<ConnectivityResult>> get connectionType;
  
  /// Stream về sự thay đổi trạng thái kết nối
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
  
  /// Kiểm tra xem kết nối hiện tại có phải là WiFi không
  Future<bool> get isWifi;
  
  /// Kiểm tra xem kết nối hiện tại có phải là dữ liệu di động không
  Future<bool> get isMobile;
  
  /// Lắng nghe sự thay đổi kết nối và thực hiện callback
  StreamSubscription<List<ConnectivityResult>> listenConnectivity(
      Function(List<ConnectivityResult>) onChange);
      
  /// Chất lượng kết nối hiện tại
  Stream<ConnectionQuality> get connectionQuality;
  
  /// Kiểm tra kết nối đến một máy chủ cụ thể 
  Future<ConnectionStatus> checkConnection(String host, {int port = 80, Duration timeout = const Duration(seconds: 5)});
}

/// Chất lượng kết nối
enum ConnectionQuality {
  /// Không có kết nối
  none,
  
  /// Kết nối kém, độ trễ cao, tốc độ chậm
  poor,
  
  /// Kết nối vừa phải
  medium,
  
  /// Kết nối tốt
  good,
  
  /// Kết nối rất tốt, độ trễ thấp, tốc độ cao
  excellent,
  
  /// Không xác định được chất lượng
  unknown
}

/// Trạng thái kết nối
enum ConnectionStatus {
  /// Kết nối thành công
  connected,
  
  /// Kết nối bị từ chối
  refused,
  
  /// Kết nối timeout
  timeout,
  
  /// Lỗi kết nối
  error
}

/// Thông tin chi tiết về kết nối
class ConnectionDetails {
  /// Loại kết nối
  final List<ConnectivityResult> types;
  
  /// Chất lượng kết nối
  final ConnectionQuality quality;
  
  /// Địa chỉ IP (nếu có)
  final String? ipAddress;
  
  /// Thông tin bổ sung
  final Map<String, dynamic> additionalInfo;
  
  /// Constructor
  ConnectionDetails({
    required this.types,
    required this.quality,
    this.ipAddress,
    this.additionalInfo = const {},
  });
  
  @override
  String toString() {
    return 'ConnectionDetails(types: $types, quality: $quality, ipAddress: $ipAddress)';
  }
}

/// Triển khai nâng cao của dịch vụ thông tin kết nối
@lazySingleton
class ConnectionInfo implements IConnectionInfo {
  /// Logger
  final Logger _logger;
  
  /// Connectivity plugin
  final Connectivity _connectivity;
  
  /// Subject để theo dõi chất lượng kết nối
  final BehaviorSubject<ConnectionQuality> _qualitySubject = 
      BehaviorSubject<ConnectionQuality>.seeded(ConnectionQuality.unknown);
  
  /// Danh sách các máy chủ để kiểm tra kết nối
  final List<String> _testServers = [
    'google.com',
    'cloudflare.com',
    '1.1.1.1',
  ];
  
  /// Ngưỡng thời gian phản hồi để đánh giá chất lượng (ms)
  final Map<ConnectionQuality, int> _responseTimeThresholds = {
    ConnectionQuality.excellent: 50,   // <= 50ms
    ConnectionQuality.good: 150,       // <= 150ms
    ConnectionQuality.medium: 300,     // <= 300ms
    ConnectionQuality.poor: 1000,      // <= 1000ms
  };
  
  /// Timer kiểm tra chất lượng kết nối định kỳ
  Timer? _qualityCheckTimer;
  
  /// Cache loại kết nối để tránh truy vấn quá nhiều
  List<ConnectivityResult> _lastKnownConnectivity = [ConnectivityResult.none];
  
  /// Thời điểm kiểm tra chất lượng kết nối gần nhất
  DateTime _lastQualityCheck = DateTime.now();
  
  /// Flag để biết đã được khởi tạo chưa
  bool _isInitialized = false;
  
  /// Constructor
  ConnectionInfo(this._connectivity, {Logger? logger}) 
    : _logger = logger ?? Logger() {
    _initialize();
  }
  
  /// Khởi tạo
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    // Lấy trạng thái kết nối ban đầu
    _lastKnownConnectivity = await _connectivity.checkConnectivity();
    
    // Lắng nghe sự thay đổi kết nối
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Bắt đầu kiểm tra chất lượng kết nối
    _startQualityCheck();
    
    _isInitialized = true;
    _logger.d('ConnectionInfo đã được khởi tạo');
  }
  
  /// Xử lý sự thay đổi kết nối
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _lastKnownConnectivity = results;
    _logger.d('Kết nối thay đổi: $results');
    
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      _qualitySubject.add(ConnectionQuality.none);
    } else {
      // Kiểm tra lại chất lượng mỗi khi kết nối thay đổi
      _checkQuality();
    }
  }
  
  /// Bắt đầu kiểm tra chất lượng kết nối
  void _startQualityCheck() {
    _qualityCheckTimer?.cancel();
    
    // Kiểm tra chất lượng mỗi 30 giây
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkQuality();
    });
    
    // Kiểm tra chất lượng ngay lập tức
    _checkQuality();
  }
  
  /// Kiểm tra chất lượng kết nối
  Future<void> _checkQuality() async {
    // Không kiểm tra nếu không có kết nối
    if (_lastKnownConnectivity.isEmpty || 
        (_lastKnownConnectivity.length == 1 && _lastKnownConnectivity.first == ConnectivityResult.none)) {
      _qualitySubject.add(ConnectionQuality.none);
      return;
    }
    
    // Không kiểm tra quá thường xuyên
    final now = DateTime.now();
    if (now.difference(_lastQualityCheck).inSeconds < 10) {
      return;
    }
    
    _lastQualityCheck = now;
    
    try {
      List<ConnectionStatus> results = [];
      List<int> responseTimes = [];
      
      // Ping các máy chủ kiểm tra
      for (final server in _testServers) {
        final startTime = DateTime.now().millisecondsSinceEpoch;
        final status = await checkConnection(server);
        final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
        
        results.add(status);
        if (status == ConnectionStatus.connected) {
          responseTimes.add(elapsed);
        }
      }
      
      // Xác định chất lượng dựa trên kết quả
      ConnectionQuality quality;
      
      if (results.every((status) => status == ConnectionStatus.timeout || status == ConnectionStatus.error)) {
        quality = ConnectionQuality.none;
      } else if (responseTimes.isEmpty) {
        quality = ConnectionQuality.poor;
      } else {
        // Tính thời gian phản hồi trung bình
        final avgResponseTime = responseTimes.reduce((a, b) => a + b) ~/ responseTimes.length;
        
        if (avgResponseTime <= _responseTimeThresholds[ConnectionQuality.excellent]!) {
          quality = ConnectionQuality.excellent;
        } else if (avgResponseTime <= _responseTimeThresholds[ConnectionQuality.good]!) {
          quality = ConnectionQuality.good;
        } else if (avgResponseTime <= _responseTimeThresholds[ConnectionQuality.medium]!) {
          quality = ConnectionQuality.medium;
        } else if (avgResponseTime <= _responseTimeThresholds[ConnectionQuality.poor]!) {
          quality = ConnectionQuality.poor;
        } else {
          quality = ConnectionQuality.poor;
        }
      }
      
      // Cập nhật chất lượng
      _qualitySubject.add(quality);
      _logger.d('Chất lượng kết nối: $quality');
      
    } catch (e) {
      _logger.e('Lỗi khi kiểm tra chất lượng kết nối: $e');
      _qualitySubject.add(ConnectionQuality.unknown);
    }
  }
  
  @override
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);
  }
  
  @override
  Future<List<ConnectivityResult>> get connectionType async {
    return await _connectivity.checkConnectivity();
  }
  
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
  
  @override
  Future<bool> get isWifi async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }
  
  @override
  Future<bool> get isMobile async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile);
  }
  
  @override
  StreamSubscription<List<ConnectivityResult>> listenConnectivity(
      Function(List<ConnectivityResult>) onChange) {
    return _connectivity.onConnectivityChanged.listen(onChange);
  }
  
  @override
  Stream<ConnectionQuality> get connectionQuality => _qualitySubject.stream;
  
  @override
  Future<ConnectionStatus> checkConnection(String host, {int port = 80, Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final socket = await Socket.connect(host, port).timeout(timeout);
      await socket.close();
      return ConnectionStatus.connected;
    } on SocketException {
      return ConnectionStatus.refused;
    } on TimeoutException {
      return ConnectionStatus.timeout;
    } catch (e) {
      _logger.e('Lỗi kết nối đến $host:$port - $e');
      return ConnectionStatus.error;
    }
  }
  
  /// Thông tin chi tiết về kết nối hiện tại
  Future<ConnectionDetails> getConnectionDetails() async {
    final types = await connectionType;
    final quality = _qualitySubject.value;
    
    String? ipAddress;
    try {
      // Lấy địa chỉ IP của thiết bị
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ipAddress = addr.address;
            break;
          }
        }
        if (ipAddress != null) break;
      }
    } catch (e) {
      _logger.e('Lỗi khi lấy địa chỉ IP: $e');
    }
    
    // Thông tin bổ sung
    final additionalInfo = <String, dynamic>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    return ConnectionDetails(
      types: types,
      quality: quality,
      ipAddress: ipAddress,
      additionalInfo: additionalInfo,
    );
  }
  
  /// Báo cáo về kết nối hiện tại
  Future<Map<String, dynamic>> generateConnectionReport() async {
    final details = await getConnectionDetails();
    final pingResults = <String, dynamic>{};
    
    for (final server in _testServers) {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      final status = await checkConnection(server);
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      
      pingResults[server] = {
        'status': status.toString(),
        'response_time_ms': status == ConnectionStatus.connected ? elapsed : null,
      };
    }
    
    return {
      'connection_types': details.types.map((t) => t.toString()).toList(),
      'connection_quality': details.quality.toString(),
      'ip_address': details.ipAddress,
      'ping_results': pingResults,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Dispose
  void dispose() {
    _qualityCheckTimer?.cancel();
    _qualitySubject.close();
  }
} 