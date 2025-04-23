import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Interface para verificar la conectividad de la red
@injectable
abstract class INetworkInfo {
  /// Verificar si el dispositivo tiene conexión a internet
  Future<bool> get isConnected;
  
  /// Obtener el tipo de conexión actual
  Future<List<ConnectivityResult>> get connectionType;
  
  /// Stream de cambios en el estado de conectividad
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
  
  /// Verificar si la conexión actual es WiFi
  Future<bool> get isWifi;
  
  /// Verificar si la conexión actual es móvil (datos celulares)
  Future<bool> get isMobile;
  
  /// Escuchar los cambios de conectividad y ejecutar el callback
  StreamSubscription<List<ConnectivityResult>> listenConnectivity(
      void Function(List<ConnectivityResult>) onChange);
      
  /// Verificar si hay una conexión real intentando acceder a internet
  Future<bool> checkRealConnection({String host = "8.8.8.8", int port = 53, Duration timeout = const Duration(seconds: 3)});
}

/// Implementación del verificador de conectividad
@LazySingleton(as: INetworkInfo)
class NetworkInfo implements INetworkInfo {
  /// Plugin de conectividad
  final Connectivity _connectivity;
  
  /// Logger
  final Logger _logger;
  
  /// Estado de conectividad en caché
  List<ConnectivityResult> _lastKnownConnectivity = [ConnectivityResult.none];
  
  /// Constructor
  NetworkInfo({
    required Connectivity connectivity,
    Logger? logger,
  }) : _connectivity = connectivity,
       _logger = logger ?? Logger() {
    // Inicializar escuchando cambios de conectividad
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Obtener el estado inicial
    _updateConnectivity();
  }
  
  /// Actualizar el estado de conectividad en caché
  Future<void> _updateConnectivity() async {
    try {
      _lastKnownConnectivity = await _connectivity.checkConnectivity();
      _logger.d('Conectividad actualizada: $_lastKnownConnectivity');
    } catch (e) {
      _logger.e('Error al verificar conectividad: $e');
    }
  }
  
  /// Manejar cambios en la conectividad
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _lastKnownConnectivity = results;
    _logger.d('Cambio de conectividad: $results');
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
      void Function(List<ConnectivityResult>) onChange) {
    return _connectivity.onConnectivityChanged.listen((results) {
      _logger.d('Cambio de conectividad: $results');
      onChange(results);
    });
  }
  
  @override
  Future<bool> checkRealConnection({
    String host = "8.8.8.8", 
    int port = 53, 
    Duration timeout = const Duration(seconds: 3)
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (e) {
      _logger.d('Sin conexión real a internet: $e');
      return false;
    }
  }
  
  /// Obtener información detallada sobre la conectividad actual
  Future<Map<String, dynamic>> getConnectionDetails() async {
    final types = await connectionType;
    final realConnection = await checkRealConnection();
    
    return {
      'types': types.map((t) => t.toString()).toList(),
      'has_wifi': types.contains(ConnectivityResult.wifi),
      'has_mobile': types.contains(ConnectivityResult.mobile),
      'has_ethernet': types.contains(ConnectivityResult.ethernet),
      'has_vpn': types.contains(ConnectivityResult.vpn),
      'real_connection': realConnection,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
} 