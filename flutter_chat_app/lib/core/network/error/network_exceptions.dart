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

  TimeoutException([this.message = 'Kết nối quá hạn']);

  @override
  String toString() => message;
}

/// Định nghĩa lỗi từ server
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({this.message = 'Lỗi máy chủ', this.statusCode});

  @override
  String toString() => message;
}

/// Định nghĩa lỗi từ API response
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    this.message = 'Đã xảy ra lỗi',
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// Định nghĩa lỗi Bad Request (400)
class BadRequestException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  BadRequestException({
    String message = 'Yêu cầu không hợp lệ',
    dynamic data,
  }) : validationErrors = _extractValidationErrors(data),
       super(message: message, statusCode: 400, data: data);

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
}

/// Định nghĩa lỗi Unauthorized (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException({
    String message = 'Chưa đăng nhập hoặc phiên đăng nhập hết hạn',
    dynamic data,
  }) : super(message: message, statusCode: 401, data: data);
}

/// Định nghĩa lỗi Forbidden (403)
class ForbiddenException extends ApiException {
  ForbiddenException({
    String message = 'Không có quyền truy cập',
    dynamic data,
  }) : super(message: message, statusCode: 403, data: data);
}

/// Định nghĩa lỗi Not Found (404)
class NotFoundException extends ApiException {
  NotFoundException({
    String message = 'Không tìm thấy tài nguyên',
    dynamic data,
  }) : super(message: message, statusCode: 404, data: data);
}

/// Định nghĩa lỗi Conflict (409)
class ConflictException extends ApiException {
  ConflictException({
    String message = 'Xung đột dữ liệu',
    dynamic data,
  }) : super(message: message, statusCode: 409, data: data);
}

/// Định nghĩa lỗi Unprocessable Entity (422)
class UnprocessableEntityException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  UnprocessableEntityException({
    String message = 'Dữ liệu không hợp lệ',
    dynamic data,
  }) : validationErrors = _extractValidationErrors(data),
       super(message: message, statusCode: 422, data: data);

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
}

/// Định nghĩa lỗi Too Many Requests (429)
class TooManyRequestsException extends ApiException {
  final Duration? retryAfter;

  TooManyRequestsException({
    String message = 'Quá nhiều yêu cầu, vui lòng thử lại sau',
    dynamic data,
    this.retryAfter,
  }) : super(message: message, statusCode: 429, data: data);

  /// Tạo exception từ response
  factory TooManyRequestsException.fromResponse(Response response) {
    Duration? retryAfter;
    
    if (response.headers.map.containsKey('retry-after')) {
      final retryAfterValue = response.headers.value('retry-after');
      if (retryAfterValue != null) {
        final seconds = int.tryParse(retryAfterValue);
        if (seconds != null) {
          retryAfter = Duration(seconds: seconds);
        }
      }
    }

    return TooManyRequestsException(
      retryAfter: retryAfter,
      data: response.data,
    );
  }
}

/// Định nghĩa lỗi hủy request
class RequestCancelledException implements Exception {
  final String message;

  RequestCancelledException([this.message = 'Yêu cầu đã bị hủy']);

  @override
  String toString() => message;
}

/// Định nghĩa lỗi không xác định
class UnexpectedException implements Exception {
  final String message;
  final dynamic error;

  UnexpectedException({this.message = 'Đã xảy ra lỗi không xác định', this.error});

  @override
  String toString() => '$message: $error';
}

/// Class factory để tạo exception từ DioException
class NetworkExceptionFactory {
  /// Tạo exception tương ứng từ DioException
  static Exception fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      
      case DioExceptionType.cancel:
        return RequestCancelledException();
      
      case DioExceptionType.badResponse:
        return _handleResponseError(exception);
      
      case DioExceptionType.connectionError:
        return NoConnectionException();
      
      case DioExceptionType.badCertificate:
        return ServerException(message: 'Lỗi chứng chỉ bảo mật');
      
      default:
        if (exception.error is SocketException) {
          return NoConnectionException();
        }
        return UnexpectedException(error: exception.error);
    }
  }
  
  /// Xử lý lỗi response
  static Exception _handleResponseError(DioException exception) {
    final response = exception.response;
    
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
        return BadRequestException(message: message, data: responseData);
      case 401:
        return UnauthorizedException(message: message, data: responseData);
      case 403:
        return ForbiddenException(message: message, data: responseData);
      case 404:
        return NotFoundException(message: message, data: responseData);
      case 409:
        return ConflictException(message: message, data: responseData);
      case 422:
        return UnprocessableEntityException(message: message, data: responseData);
      case 429:
        return TooManyRequestsException.fromResponse(response);
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message: message, statusCode: statusCode);
        }
        return ApiException(message: message, statusCode: statusCode, data: responseData);
    }
  }
} 