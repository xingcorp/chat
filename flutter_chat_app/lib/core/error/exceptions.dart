/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException: [$code] $message';
}

/// Exception thrown when a server error occurs
class ServerException extends AppException {
  ServerException({
    String message = 'Server error occurred',
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Exception thrown when the device has no internet connection
class NoInternetException extends AppException {
  NoInternetException({
    String message = 'No internet connection',
    String? code = 'NO_INTERNET',
  }) : super(message: message, code: code);
}

/// Exception thrown when the device's cache has no data
class CacheException extends AppException {
  CacheException({
    String message = 'Cache error occurred',
    String? code = 'CACHE_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  AuthException({
    String message = 'Authentication failed',
    String? code = 'AUTH_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Exception thrown when a timeout occurs
class TimeoutException extends AppException {
  TimeoutException({
    String message = 'Operation timed out',
    String? code = 'TIMEOUT',
  }) : super(message: message, code: code);
}

/// Exception thrown when an unknown error occurs
class UnknownException extends AppException {
  UnknownException({
    String message = 'An unknown error occurred',
    String? code = 'UNKNOWN_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Exception thrown when a validation error occurs
class ValidationException extends AppException {
  ValidationException({
    String message = 'Validation failed',
    String? code = 'VALIDATION_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Exception thrown when a required resource is not found
class NotFoundException extends AppException {
  NotFoundException({
    String message = 'Resource not found',
    String? code = 'NOT_FOUND',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Exception thrown when a permission is denied
class PermissionDeniedException extends AppException {
  PermissionDeniedException({
    String message = 'Permission denied',
    String? code = 'PERMISSION_DENIED',
    dynamic details,
  }) : super(message: message, code: code, details: details);
} 