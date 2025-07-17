/// Base exception class for the application
abstract class AppException implements Exception {
  /// Message for the exception
  final String message;
  
  /// Constructor
  AppException({required this.message});
  
  @override
  String toString() => message;
}

/// Exception thrown when a server returns an error
class ServerException extends AppException {
  /// Status code from the server
  final int? statusCode;
  
  /// Constructor
  ServerException({required super.message, this.statusCode});
}

/// Exception thrown when a cache operation fails
class CacheException extends AppException {
  /// Constructor
  CacheException({required super.message});
}

/// Exception thrown when no internet connection is available
class NoInternetException extends AppException {
  /// Constructor
  NoInternetException({super.message = 'No internet connection'});
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  /// Constructor
  AuthException({required super.message});
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  /// Constructor
  NotFoundException({required super.message});
}

/// Exception thrown when an operation times out
class TimeoutException extends AppException {
  /// Constructor
  TimeoutException({super.message = 'Operation timed out'});
}

/// Exception thrown when an argument is invalid
class InvalidArgumentException extends AppException {
  /// Constructor
  InvalidArgumentException({required super.message});
}

/// Exception thrown when a format is invalid
class FormatException extends AppException {
  /// Constructor
  FormatException({required super.message});
}

/// Exception thrown when a conflict occurs
class ConflictException extends AppException {
  /// Constructor
  ConflictException({required super.message});
}

/// Exception thrown when a resource already exists
class AlreadyExistsException extends AppException {
  /// Constructor
  AlreadyExistsException({required super.message});
}

/// Exception thrown when a validation fails
class ValidationException extends AppException {
  /// Constructor
  ValidationException({required super.message});
}

/// Exception thrown when a permission is denied
class PermissionDeniedException extends AppException {
  /// Constructor
  PermissionDeniedException({required super.message});
}

/// Exception thrown when a resource is being created
class ResourceCreationException extends AppException {
  /// Constructor
  ResourceCreationException({required super.message});
}

/// Exception thrown when an unexpected error occurs
class UnexpectedException extends AppException {
  /// Constructor
  UnexpectedException({super.message = 'An unexpected error occurred'});
} 