/// **ERROR HANDLER - STANDARDIZED ERROR MAPPING**
///
/// Professional error handling utilities following clean architecture:
/// - Standardized exception to failure mapping
/// - Consistent error codes and messages
/// - Vietnamese user messages with technical English logs
/// - Recovery strategy recommendations
///
/// **Architecture:** Clean Architecture + SOLID principles + Either<Failure, T>

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/error/failures.dart';

/// **Error Handler Utility**
///
/// Centralized error mapping following single responsibility principle
class ErrorHandler {
  static final Logger _logger = Logger();

  /// **Map Exception to Failure**
  ///
  /// Standardized mapping from exceptions to appropriate failure types
  /// **Performance:** <10ms error mapping
  /// **Strategy:** Comprehensive exception analysis with proper categorization
  static Failure mapExceptionToFailure(
    dynamic exception, {
    String? context,
    Map<String, dynamic>? additionalDetails,
  }) {
    _logger.e('🚨 Exception in ${context ?? 'Unknown'}: $exception');

    // Network-related exceptions
    if (exception is DioException) {
      return _mapDioException(exception, context, additionalDetails);
    }

    // Socket/Connection exceptions
    if (exception is SocketException) {
      return ConnectionFailure(
        message: 'Socket connection failed: ${exception.message}',
        code: 'socket_error',
        details: {
          'context': context,
          'address': exception.address?.address,
          'port': exception.port,
          ...?additionalDetails,
        },
      );
    }

    // HTTP exceptions
    if (exception is HttpException) {
      return ServerFailure(
        message: 'HTTP error: ${exception.message}',
        code: 'http_error',
        details: {
          'context': context,
          'uri': exception.uri?.toString(),
          ...?additionalDetails,
        },
      );
    }

    // Format exceptions (JSON, parsing, etc.)
    if (exception is FormatException) {
      return ValidationFailure(
        message: 'Data format error: ${exception.message}',
        code: 'format_error',
        details: {
          'context': context,
          'source': exception.source,
          'offset': exception.offset,
          ...?additionalDetails,
        },
      );
    }

    // Timeout exceptions
    if (exception is TimeoutException) {
      return TimeoutFailure(
        message: 'Operation timeout: ${exception.message ?? 'Unknown timeout'}',
        code: 'timeout',
        details: {
          'context': context,
          'duration': exception.duration?.inMilliseconds,
          ...?additionalDetails,
        },
      );
    }

    // File system exceptions
    if (exception is FileSystemException) {
      return CacheFailure(
        message: 'File system error: ${exception.message}',
        code: 'file_system_error',
        details: {
          'context': context,
          'path': exception.path,
          'osError': exception.osError?.message,
          ...?additionalDetails,
        },
      );
    }

    // Argument exceptions (validation)
    if (exception is ArgumentError) {
      return ValidationFailure(
        message: 'Invalid argument: ${exception.message}',
        code: 'invalid_argument',
        details: {
          'context': context,
          'invalidValue': exception.invalidValue,
          'name': exception.name,
          ...?additionalDetails,
        },
      );
    }

    // State exceptions
    if (exception is StateError) {
      return ConflictFailure(
        message: 'Invalid state: ${exception.message}',
        code: 'invalid_state',
        details: {
          'context': context,
          ...?additionalDetails,
        },
      );
    }

    // Generic exceptions
    if (exception is Exception) {
      return UnexpectedFailure(
        message: 'Unexpected exception: ${exception.toString()}',
        code: 'unexpected_exception',
        details: {
          'context': context,
          'type': exception.runtimeType.toString(),
          ...?additionalDetails,
        },
      );
    }

    // Unknown errors
    return UnknownFailure(
      message: 'Unknown error: ${exception.toString()}',
      code: 'unknown_error',
      details: {
        'context': context,
        'type': exception.runtimeType.toString(),
        ...?additionalDetails,
      },
    );
  }

  /// **Map Dio Exception to Failure**
  ///
  /// Specialized mapping for Dio HTTP client exceptions
  static Failure _mapDioException(
    DioException exception,
    String? context,
    Map<String, dynamic>? additionalDetails,
  ) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final responseData = response?.data;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          message: 'Request timeout: ${exception.message}',
          code: 'request_timeout',
          details: {
            'context': context,
            'type': exception.type.toString(),
            'timeout': exception.requestOptions.connectTimeout,
            ...?additionalDetails,
          },
        );

      case DioExceptionType.connectionError:
        return ConnectionFailure(
          message: 'Connection error: ${exception.message}',
          code: 'connection_error',
          details: {
            'context': context,
            'url': exception.requestOptions.uri.toString(),
            ...?additionalDetails,
          },
        );

      case DioExceptionType.badResponse:
        if (statusCode != null) {
          if (statusCode >= 400 && statusCode < 500) {
            // Client errors
            if (statusCode == 401) {
              return AuthenticationFailure(
                message: 'Authentication failed: ${exception.message}',
                code: 'authentication_failed',
                details: {
                  'context': context,
                  'statusCode': statusCode,
                  'response': responseData,
                  ...?additionalDetails,
                },
              );
            } else if (statusCode == 403) {
              return PermissionFailure(
                message: 'Access denied: ${exception.message}',
                code: 'access_denied',
                details: {
                  'context': context,
                  'statusCode': statusCode,
                  'response': responseData,
                  ...?additionalDetails,
                },
              );
            } else if (statusCode == 409) {
              return ConflictFailure(
                message: 'Data conflict: ${exception.message}',
                code: 'data_conflict',
                details: {
                  'context': context,
                  'statusCode': statusCode,
                  'response': responseData,
                  ...?additionalDetails,
                },
              );
            } else if (statusCode == 422) {
              return ValidationFailure(
                message: 'Validation failed: ${exception.message}',
                code: 'validation_failed',
                details: {
                  'context': context,
                  'statusCode': statusCode,
                  'response': responseData,
                  ...?additionalDetails,
                },
              );
            } else {
              return ValidationFailure(
                message: 'Client error: ${exception.message}',
                code: 'client_error',
                details: {
                  'context': context,
                  'statusCode': statusCode,
                  'response': responseData,
                  ...?additionalDetails,
                },
              );
            }
          } else if (statusCode >= 500) {
            // Server errors
            return ServerFailure(
              message: 'Server error: ${exception.message}',
              code: statusCode.toString(),
              details: {
                'context': context,
                'statusCode': statusCode,
                'response': responseData,
                ...?additionalDetails,
              },
            );
          }
        }
        
        return ServerFailure(
          message: 'Bad response: ${exception.message}',
          code: 'bad_response',
          details: {
            'context': context,
            'statusCode': statusCode,
            'response': responseData,
            ...?additionalDetails,
          },
        );

      case DioExceptionType.cancel:
        return UnexpectedFailure(
          message: 'Request cancelled: ${exception.message}',
          code: 'request_cancelled',
          details: {
            'context': context,
            ...?additionalDetails,
          },
        );

      case DioExceptionType.unknown:
      default:
        return NetworkFailure(
          message: 'Network error: ${exception.message}',
          code: 'network_error',
          details: {
            'context': context,
            'type': exception.type.toString(),
            ...?additionalDetails,
          },
        );
    }
  }

  /// **Get Recovery Strategy**
  ///
  /// Recommend recovery strategy based on failure type
  static RecoveryStrategy getRecoveryStrategy(Failure failure) {
    switch (failure.runtimeType) {
      case ConnectionFailure:
      case NetworkFailure:
      case TimeoutFailure:
        return RecoveryStrategy.retry;
      
      case ServerFailure:
        final code = failure.code;
        if (code == '500' || code == '502' || code == '503') {
          return RecoveryStrategy.retryWithBackoff;
        }
        return RecoveryStrategy.showError;
      
      case AuthenticationFailure:
        return RecoveryStrategy.reauthenticate;
      
      case ValidationFailure:
        return RecoveryStrategy.showError;
      
      case CacheFailure:
        return RecoveryStrategy.clearCacheAndRetry;
      
      case ConflictFailure:
        return RecoveryStrategy.refreshAndRetry;
      
      default:
        return RecoveryStrategy.showError;
    }
  }
}

/// **Recovery Strategy Enum**
enum RecoveryStrategy {
  retry,
  retryWithBackoff,
  showError,
  reauthenticate,
  clearCacheAndRetry,
  refreshAndRetry,
}

/// **Timeout Exception**
class TimeoutException implements Exception {
  final String? message;
  final Duration? duration;

  const TimeoutException(this.message, [this.duration]);

  @override
  String toString() => 'TimeoutException: $message';
}
