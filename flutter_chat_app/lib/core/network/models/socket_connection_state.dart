/// Represents the current state of a WebSocket connection
enum SocketConnectionState {
  /// Initial state, not yet connected
  disconnected,
  
  /// In the process of establishing connection
  connecting,
  
  /// Successfully connected and ready to send/receive messages
  connected,
  
  /// Connection has been interrupted, attempting to reconnect
  reconnecting,
  
  /// Explicit disconnection by the user or application
  disconnectedByUser,
  
  /// Disconnected due to network issues
  disconnectedByServer,
  
  /// Connection failed with error
  error
} 