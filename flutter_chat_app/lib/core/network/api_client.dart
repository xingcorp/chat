import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Abstract interface for API communication
abstract class ApiClient {
  /// Performs a GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Performs a POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Performs a PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Performs a PATCH request
  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Performs a DELETE request
  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });
}

/// Implementation of the ApiClient interface
class ApiClientImpl implements ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;

  /// Constructor
  ApiClientImpl(this._dio, this._networkInfo) {
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.example.com/v1';
    _dio.options.connectTimeout = const Duration(milliseconds: 30000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token here if needed
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          final errorResponse = _handleDioError(e);
          return handler.reject(errorResponse);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      _dio.get,
      endpoint,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      _dio.post,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      _dio.put,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      _dio.patch,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      _dio.delete,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<dynamic> _executeRequest(
    Future<Response<dynamic>> Function(
      String path, {
      dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
    }) method,
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw NoInternetException();
    }

    try {
      final response = await method(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw NoInternetException();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  DioException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return DioException(
        requestOptions: e.requestOptions,
        type: e.type,
        error: 'Connection timeout. Please try again.',
      );
    }

    if (e.response != null) {
      final int? statusCode = e.response?.statusCode;
      final dynamic data = e.response?.data;
      
      String errorMessage = 'Unknown error occurred';
      
      if (data != null && data is Map<String, dynamic> && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (data != null && data is String) {
        try {
          final decodedData = json.decode(data);
          if (decodedData is Map<String, dynamic> && decodedData.containsKey('message')) {
            errorMessage = decodedData['message'];
          }
        } catch (_) {
          errorMessage = data;
        }
      }
      
      switch (statusCode) {
        case 400:
          return DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: 'Bad request: $errorMessage',
          );
        case 401:
          return DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: 'Unauthorized: $errorMessage',
          );
        case 403:
          return DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: 'Forbidden: $errorMessage',
          );
        case 404:
          return DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: 'Resource not found: $errorMessage',
          );
        case 500:
        case 501:
        case 502:
        case 503:
          return DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: 'Server error: $errorMessage',
          );
        default:
          return DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: errorMessage,
          );
      }
    }
    
    return e;
  }
} 