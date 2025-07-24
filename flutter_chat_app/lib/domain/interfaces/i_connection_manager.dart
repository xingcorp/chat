/// **CONNECTION MANAGER INTERFACE - INTERFACE SEGREGATION PRINCIPLE**
///
/// Focused interface for connection management only
/// Following ISP: clients depend only on methods they use
///
/// **Architecture:** Clean Architecture + SOLID principles

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/websocket_client.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// **Connection Manager Interface**
///
/// Single responsibility: Connection state management
abstract class IConnectionManager {
  /// Current connection state
  ConnectionState get currentState;
  
  /// Connection state stream
  Stream<ConnectionState> get connectionState;
  
  /// Check if connected
  bool get isConnected;
  
  /// Connect to server
  Future<Either<Failure, bool>> connect();
  
  /// Disconnect from server
  Future<Either<Failure, bool>> disconnect();
  
  /// Enable offline-first mode
  void enableOfflineFirst();
  
  /// Disable offline-first mode
  void disableOfflineFirst();
}
