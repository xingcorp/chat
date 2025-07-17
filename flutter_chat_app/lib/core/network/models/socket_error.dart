

/// Enum representing types of socket errors that can occur
enum SocketErrorType {
  /// Connection could not be established
  connectionFailed,
  
  /// Connection was interrupted unexpectedly
  connectionLost,
  
  /// Authentication with the server failed
  authenticationFailed,
  
  /// Server returned an error response
  serverError,
  
  /// Client-side timeout occurred
  timeout,
  
  /// Rate limit was exceeded
  rateLimitExceeded,
  
  /// Message format was invalid
  invalidMessageFormat,
  
  /// Network is not available
  networkUnavailable,
  
  /// Other unspecified error
  unknown
}

/// Represents an error that occurred during socket communication
class SocketError {
  /// The type of error that occurred
  final SocketErrorType type;
  
  /// A human-readable error message
  final String message;
  
  /// The original exception or error object, if available
  final dynamic originalError;
  
  /// Optional data related to the error
  final Map<String, dynamic>? data;
  
  /// Optional error code from the server
  final String? code;
  
  /// Creates a new socket error
  const SocketError({
    required this.type,
    required this.message,
    this.originalError,
    this.data,
    this.code,
  });
  
  /// Creates a copy of this error with some fields replaced
  SocketError copyWith({
    SocketErrorType? type,
    String? message,
    dynamic originalError,
    Map<String, dynamic>? data,
    String? code,
  }) {
    return SocketError(
      type: type ?? this.type,
      message: message ?? this.message,
      originalError: originalError ?? this.originalError,
      data: data ?? this.data,
      code: code ?? this.code,
    );
  }
  
  @override
  String toString() {
    return 'SocketError(type: $type, message: $message, code: $code)';
  }
} 