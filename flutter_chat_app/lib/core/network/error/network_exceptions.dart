import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Định nghĩa lỗi không có kết nối mạng
class NoConnectionException implements Exception {
  final String message;

  NoConnectionException([this.message = 'Không có kết nối mạng']);

  @override
  String toString() => message;
}

/// Định nghĩa lỗi timeout khi gọi API
class TimeoutException implements Exception {
  final String message;
  final int? timeoutMs;

  TimeoutException([this.message = 'Kết nối quá hạn', this.timeoutMs]);

  @override
  String toString() => timeoutMs != null 
    ? '$message (sau ${timeoutMs}ms)' 
    : message;
}

/// Định nghĩa lỗi từ server
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({this.message = 'Lỗi máy chủ', this.statusCode});

  @override
  String toString() => statusCode != null 
    ? '$message (Mã lỗi: $statusCode)' 
    : message;
}

/// Định nghĩa lỗi từ API response
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final String? endpoint;

  ApiException({
    this.message = 'Đã xảy ra lỗi',
    this.statusCode,
    this.data,
    this.endpoint,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);
    
    if (statusCode != null) {
      buffer.write(' (Mã lỗi: $statusCode)');
    }
    
    if (endpoint != null) {
      buffer.write(' - API: $endpoint');
    }
    
    return buffer.toString();
  }
  
  /// Convert to a map for analytics
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'statusCode': statusCode,
      'endpoint': endpoint,
      'hasData': data != null,
    };
  }
}

/// Định nghĩa lỗi Bad Request (400)
class BadRequestException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  BadRequestException({
    super.message = 'Yêu cầu không hợp lệ',
    super.data,
    super.endpoint,
  }) : validationErrors = _extractValidationErrors(data),
       super(statusCode: 400);

  static Map<String, dynamic>? _extractValidationErrors(dynamic data) {
    if (data != null && data is Map<String, dynamic> && data.containsKey('errors')) {
      return data['errors'] as Map<String, dynamic>;
    }
    return null;
  }

  /// Lấy danh sách lỗi validation
  List<String> get errorMessages {
    if (validationErrors == null) {
      return [message];
    }

    final List<String> messages = [];
    validationErrors!.forEach((key, value) {
      if (value is List) {
        for (final error in value) {
          messages.add(error.toString());
        }
      } else {
        messages.add(value.toString());
      }
    });

    return messages.isEmpty ? [message] : messages;
  }
  
  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return '${super.toString()} - ${errorMessages.join(', ')}';
    }
    return super.toString();
  }
}

/// Định nghĩa lỗi Unauthorized (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException({
    super.message = 'Chưa đăng nhập hoặc phiên đăng nhập hết hạn',
    super.data,
    super.endpoint,
  }) : super(statusCode: 401);
}

/// Định nghĩa lỗi Forbidden (403)
class ForbiddenException extends ApiException {
  ForbiddenException({
    super.message = 'Không có quyền truy cập',
    super.data,
    super.endpoint,
  }) : super(statusCode: 403);
}

/// Định nghĩa lỗi Not Found (404)
class NotFoundException extends ApiException {
  NotFoundException({
    String message = 'Không tìm thấy tài nguyên',
    dynamic data,
    String? endpoint,
  }) : super(message: message, statusCode: 404, data: data, endpoint: endpoint);
}

/// Định nghĩa lỗi Conflict (409)
class ConflictException extends ApiException {
  ConflictException({
    String message = 'Xung đột dữ liệu',
    dynamic data,
    String? endpoint,
  }) : super(message: message, statusCode: 409, data: data, endpoint: endpoint);
}

/// Định nghĩa lỗi Unprocessable Entity (422)
class UnprocessableEntityException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  UnprocessableEntityException({
    String message = 'Dữ liệu không hợp lệ',
    dynamic data,
    String? endpoint,
  }) : validationErrors = _extractValidationErrors(data),
       super(message: message, statusCode: 422, data: data, endpoint: endpoint);

  static Map<String, dynamic>? _extractValidationErrors(dynamic data) {
    if (data != null && data is Map<String, dynamic> && data.containsKey('errors')) {
      return data['errors'] as Map<String, dynamic>;
    }
    return null;
  }

  /// Lấy danh sách lỗi validation
  List<String> get errorMessages {
    if (validationErrors == null) {
      return [message];
    }

    final List<String> messages = [];
    validationErrors!.forEach((key, value) {
      if (value is List) {
        for (final error in value) {
          messages.add(error.toString());
        }
      } else {
        messages.add(value.toString());
      }
    });

    return messages.isEmpty ? [message] : messages;
  }
  
  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return '${super.toString()} - ${errorMessages.join(', ')}';
    }
    return super.toString();
  }
}

/// Định nghĩa lỗi Too Many Requests (429)
class TooManyRequestsException extends ApiException {
  final Duration? retryAfter;

  TooManyRequestsException({
    String message = 'Quá nhiều yêu cầu, vui lòng thử lại sau',
    dynamic data,
    String? endpoint,
    this.retryAfter,
  }) : super(message: message, statusCode: 429, data: data, endpoint: endpoint);

  /// Tạo exception từ response
  factory TooManyRequestsException.fromResponse(Response response) {
    Duration? retryAfter;
    String? endpoint = response.requestOptions.path;
    
    if (response.headers.map.containsKey('retry-after')) {
      final retryAfterValue = response.headers.value('retry-after');
      if (retryAfterValue != null) {
        final seconds = int.tryParse(retryAfterValue);
        if (seconds != null) {
          retryAfter = Duration(seconds: seconds);
        }
      }
    }

    String message = 'Quá nhiều yêu cầu, vui lòng thử lại sau';
    if (retryAfter != null) {
      message += ' ${retryAfter.inSeconds} giây';
    }

    return TooManyRequestsException(
      message: message,
      retryAfter: retryAfter,
      data: response.data,
      endpoint: endpoint,
    );
  }
  
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['retryAfterSeconds'] = retryAfter?.inSeconds;
    return map;
  }
}

/// Định nghĩa lỗi hủy request
class RequestCancelledException implements Exception {
  final String message;
  final String? endpoint;

  RequestCancelledException([this.message = 'Yêu cầu đã bị hủy', this.endpoint]);

  @override
  String toString() => endpoint != null 
    ? '$message (endpoint: $endpoint)' 
    : message;
}

/// Định nghĩa lỗi không xác định
class UnexpectedException implements Exception {
  final String message;
  final dynamic error;
  final String? endpoint;
  final StackTrace? stackTrace;

  UnexpectedException({
    this.message = 'Đã xảy ra lỗi không xác định', 
    this.error,
    this.endpoint,
    this.stackTrace,
  });

  @override
  String toString() => endpoint != null 
    ? '$message: $error (endpoint: $endpoint)' 
    : '$message: $error';
    
  /// Convert to a map for crash reporting
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'error': error?.toString(),
      'endpoint': endpoint,
      'stackTrace': stackTrace?.toString(),
    };
  }
}

/// Class factory để tạo exception từ DioException
class NetworkExceptionFactory {
  /// Cache cho lỗi phổ biến để giảm việc tạo đối tượng mới
  static final NoConnectionException _noConnectionException = NoConnectionException();
  static final TimeoutException _connectionTimeoutException = TimeoutException('Kết nối quá hạn', 30000);
  static final TimeoutException _receiveTimeoutException = TimeoutException('Nhận dữ liệu quá hạn', 30000);
  static final TimeoutException _sendTimeoutException = TimeoutException('Gửi dữ liệu quá hạn', 30000);
  static final ServerException _serverException = ServerException();
  
  /// Tạo exception tương ứng từ DioException
  static Exception fromDioException(DioException exception) {
    // Log lỗi nếu cần
    if (kDebugMode) {
      print('DioException: ${exception.type}, ${exception.message}');
    }
    
    // Trích xuất endpoint từ request
    final endpoint = exception.requestOptions.path;
    
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return _connectionTimeoutException;
      
      case DioExceptionType.sendTimeout:
        return _sendTimeoutException;
      
      case DioExceptionType.receiveTimeout:
        return _receiveTimeoutException;
      
      case DioExceptionType.cancel:
        return RequestCancelledException('Yêu cầu đã bị hủy', endpoint);
      
      case DioExceptionType.badResponse:
        return _handleResponseError(exception);
      
      case DioExceptionType.connectionError:
        if (exception.error is SocketException) {
          return NoConnectionException('Không thể kết nối đến máy chủ');
        }
        return _noConnectionException;
      
      case DioExceptionType.badCertificate:
        return ServerException(message: 'Lỗi chứng chỉ bảo mật', statusCode: 495);
      
      default:
        if (exception.error is SocketException) {
          return NoConnectionException();
        }
        return UnexpectedException(
          error: exception.error,
          endpoint: endpoint,
          stackTrace: exception.stackTrace,
        );
    }
  }
  
  /// Xử lý lỗi response
  static Exception _handleResponseError(DioException exception) {
    final response = exception.response;
    final endpoint = exception.requestOptions.path;
    
    if (response == null) {
      return ServerException();
    }
    
    final statusCode = response.statusCode;
    final responseData = response.data;
    
    String message = 'Đã xảy ra lỗi';
    if (responseData != null && responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ?? message;
    }
    
    switch (statusCode) {
      case 400:
        return BadRequestException(message: message, data: responseData, endpoint: endpoint);
      case 401:
        return UnauthorizedException(message: message, data: responseData, endpoint: endpoint);
      case 403:
        return ForbiddenException(message: message, data: responseData, endpoint: endpoint);
      case 404:
        return NotFoundException(message: message, data: responseData, endpoint: endpoint);
      case 409:
        return ConflictException(message: message, data: responseData, endpoint: endpoint);
      case 422:
        return UnprocessableEntityException(message: message, data: responseData, endpoint: endpoint);
      case 429:
        return TooManyRequestsException.fromResponse(response);
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message: message, statusCode: statusCode);
        }
        return ApiException(message: message, statusCode: statusCode, data: responseData, endpoint: endpoint);
    }
  }
  
  /// Helpers to determine exception type for analytics
  
  /// Check if exception is network-related
  static bool isNetworkException(Exception exception) {
    return exception is NoConnectionException || 
           exception is TimeoutException ||
           (exception is UnexpectedException && exception.error is SocketException);
  }
  
  /// Check if exception is server-related
  static bool isServerException(Exception exception) {
    return exception is ServerException || 
           (exception is ApiException && (exception.statusCode ?? 0) >= 500);
  }
  
  /// Check if exception is client-related (4xx)
  static bool isClientException(Exception exception) {
    return exception is ApiException && 
           exception.statusCode != null && 
           exception.statusCode! >= 400 && 
           exception.statusCode! < 500;
  }
} 