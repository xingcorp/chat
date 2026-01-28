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
  final int? statusCode;
  
  ServerException({
    super.message = 'Server error occurred',
    super.code,
    super.details,
    this.statusCode,
  });
}

/// Exception thrown when the device has no internet connection
class NoInternetException extends AppException {
  NoInternetException({
    super.message = 'No internet connection',
    super.code = 'NO_INTERNET',
  });
}

/// Exception thrown when the device's cache has no data
class CacheException extends AppException {
  CacheException({
    super.message = 'Cache error occurred',
    super.code = 'CACHE_ERROR',
    super.details,
  });
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  AuthException({
    super.message = 'Authentication failed',
    super.code = 'AUTH_ERROR',
    super.details,
  });
}

/// Exception thrown when a timeout occurs
class TimeoutException extends AppException {
  TimeoutException({
    super.message = 'Operation timed out',
    super.code = 'TIMEOUT',
  });
}

/// Exception thrown when an unknown error occurs
class UnknownException extends AppException {
  UnknownException({
    super.message = 'An unknown error occurred',
    super.code = 'UNKNOWN_ERROR',
    super.details,
  });
}

/// Exception thrown when a validation error occurs
class ValidationException extends AppException {
  ValidationException({
    super.message = 'Validation failed',
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

/// Exception thrown when a required resource is not found
class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'Resource not found',
    super.code = 'NOT_FOUND',
    super.details,
  });
}

/// Exception thrown when a permission is denied
class PermissionDeniedException extends AppException {
  PermissionDeniedException({
    super.message = 'Permission denied',
    super.code = 'PERMISSION_DENIED',
    super.details,
  });
}

/// Exception thrown when a file operation fails
class FileException extends AppException {
  const FileException({
    super.message = 'File operation failed',
    super.code = 'FILE_ERROR',
    super.details,
  });
}

/// Exception thrown when a network error occurs
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error occurred',
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}