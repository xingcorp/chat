import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../monitoring/logger.dart';
import '../monitoring/api_request_tracker.dart';
import '../cache/api_cache_manager.dart';
import 'http_client_interface.dart' hide RequestOptions;

// Khai báo lại class để tránh xung đột
import 'http_client_interface.dart' as http_options;

/// Triển khai IHttpClient sử dụng Dio, tối ưu cho hiệu suất cao và độ tin cậy
@LazySingleton(as: IHttpClient)
class DioHttpClient implements IHttpClient {
  static const Duration _defaultConnectTimeout = Duration(milliseconds: 30000);
  static const Duration _defaultReceiveTimeout = Duration(milliseconds: 30000);
  static const Duration _defaultSendTimeout = Duration(milliseconds: 30000);
  
  final Dio _dio = Dio();
  final AppLogger _logger;
  final ApiRequestTracker _requestTracker;
  final ApiCacheManager _cacheManager;
  
  // Theo dõi kết nối và trạng thái
  bool _isDisposed = false;
  String? _authToken;
  
  @override
  Dio get dioInstance => _dio;
  
  /// Constructor inject dependencies
  DioHttpClient(
    this._logger,
    this._requestTracker,
    this._cacheManager,
  ) {
    _setupInterceptors();
  }

  /// Thiết lập các interceptors mặc định
  void _setupInterceptors() {
    // Log interceptor trong chế độ debug
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => _logger.debug('[HTTP] $obj'),
      ));
    }
    
    // Retry interceptor
    _dio.interceptors.add(_createRetryInterceptor());
    
    // Cache interceptor
    _dio.interceptors.add(_createCacheInterceptor());
    
    _logger.debug('DioHttpClient: Đã thiết lập interceptors');
  }
  
  @override
  Future<void> configure({
    required String baseUrl,
    Map<String, dynamic>? headers,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
    int sendTimeout = 30000,
  }) async {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(milliseconds: connectTimeout),
      receiveTimeout: Duration(milliseconds: receiveTimeout),
      sendTimeout: Duration(milliseconds: sendTimeout),
      headers: headers,
    );
    
    _logger.debug('DioHttpClient: Đã cấu hình với baseUrl: $baseUrl');
  }
  
  @override
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
  
  @override
  void updateAuthToken(String token) {
    _authToken = token;
    _logger.debug('DioHttpClient: Đã cập nhật token xác thực');
  }
  
  @override
  void clearAuthToken() {
    _authToken = null;
    _logger.debug('DioHttpClient: Đã xóa token xác thực');
  }
  
  @override
  void setDefaultHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
    _logger.debug('DioHttpClient: Đã cập nhật headers mặc định');
  }
  
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  }) async {
    final requestId = _requestTracker.startRequest('GET', path, params: queryParameters);
    
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers, requiresAuth),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      
      _requestTracker.completeRequest(requestId, response.statusCode ?? 200, response: response.data);
      return response;
    } catch (e) {
      _handleError(e, requestId);
      rethrow;
    }
  }
  
  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  }) async {
    final requestId = _requestTracker.startRequest('POST', path, params: queryParameters);
    
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers, requiresAuth),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      _requestTracker.completeRequest(requestId, response.statusCode ?? 200, response: response.data);
      return response;
    } catch (e) {
      _handleError(e, requestId);
      rethrow;
    }
  }
  
  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  }) async {
    final requestId = _requestTracker.startRequest('PUT', path, params: queryParameters);
    
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers, requiresAuth),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      _requestTracker.completeRequest(requestId, response.statusCode ?? 200, response: response.data);
      return response;
    } catch (e) {
      _handleError(e, requestId);
      rethrow;
    }
  }
  
  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  }) async {
    final requestId = _requestTracker.startRequest('PATCH', path, params: queryParameters);
    
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers, requiresAuth),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      _requestTracker.completeRequest(requestId, response.statusCode ?? 200, response: response.data);
      return response;
    } catch (e) {
      _handleError(e, requestId);
      rethrow;
    }
  }
  
  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    bool requiresAuth = true,
  }) async {
    final requestId = _requestTracker.startRequest('DELETE', path, params: queryParameters);
    
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers, requiresAuth),
        cancelToken: cancelToken,
      );
      
      _requestTracker.completeRequest(requestId, response.statusCode ?? 200, response: response.data);
      return response;
    } catch (e) {
      _handleError(e, requestId);
      rethrow;
    }
  }
  
  @override
  Future<Response> uploadFile(
    String path, {
    required File file,
    required String fileName,
    String fileKey = 'file',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  }) async {
    final formData = FormData();
    
    // Thêm file
    formData.files.add(MapEntry(
      fileKey,
      await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    ));
    
    // Thêm các dữ liệu khác nếu có
    if (data != null) {
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }
    
    // Sử dụng phương thức POST của chính class này
    return post(
      path,
      data: formData,
      queryParameters: queryParameters,
      headers: headers,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      options: options?.copyWith(contentType: Headers.multipartFormDataContentType) ?? 
          Options(contentType: Headers.multipartFormDataContentType),
      requiresAuth: requiresAuth,
    );
  }
  
  @override
  Future<Response> uploadFiles(
    String path, {
    required List<File> files,
    required List<String> fileNames,
    String fileKey = 'files',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  }) async {
    if (files.length != fileNames.length) {
      throw ArgumentError('Số lượng files và fileNames phải bằng nhau');
    }
    
    final formData = FormData();
    
    // Thêm các files
    for (int i = 0; i < files.length; i++) {
      formData.files.add(MapEntry(
        fileKey,
        await MultipartFile.fromFile(
          files[i].path,
          filename: fileNames[i],
        ),
      ));
    }
    
    // Thêm các dữ liệu khác nếu có
    if (data != null) {
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }
    
    // Sử dụng phương thức POST của chính class này
    return post(
      path,
      data: formData,
      queryParameters: queryParameters,
      headers: headers,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      options: options?.copyWith(contentType: Headers.multipartFormDataContentType) ?? 
          Options(contentType: Headers.multipartFormDataContentType),
      requiresAuth: requiresAuth,
    );
  }
  
  @override
  Future<Response> uploadBytes(
    String path, {
    required Uint8List bytes,
    required String fileName,
    String fileKey = 'file',
    String? mimeType,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  }) async {
    final formData = FormData();
    
    // Thêm bytes
    formData.files.add(MapEntry(
      fileKey,
      MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
    ));
    
    // Thêm các dữ liệu khác nếu có
    if (data != null) {
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }
    
    // Sử dụng phương thức POST của chính class này
    return post(
      path,
      data: formData,
      queryParameters: queryParameters,
      headers: headers,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      options: options?.copyWith(contentType: Headers.multipartFormDataContentType) ?? 
          Options(contentType: Headers.multipartFormDataContentType),
      requiresAuth: requiresAuth,
    );
  }
  
  @override
  Future<Response> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
  }) async {
    final requestId = _requestTracker.startRequest('GET', url, params: queryParameters);
    
    try {
      final response = await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers, requiresAuth),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        deleteOnError: deleteOnError,
      );
      
      _requestTracker.completeRequest(requestId, response.statusCode ?? 200);
      return response;
    } catch (e) {
      _handleError(e, requestId);
      rethrow;
    }
  }
  
  /// Tạo interceptor cho cache
  Interceptor _createCacheInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Kiểm tra xem request có dùng cache không
        final useCache = options.extra['useCache'] == true;
        if (!useCache || options.method != 'GET') {
          return handler.next(options);
        }
        
        // Tạo cache key từ URL và query params
        final cacheKey = _createCacheKey(options);
        
        // Thử lấy dữ liệu từ cache
        final cachedData = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          _logger.debug('DioHttpClient: Sử dụng dữ liệu từ cache cho: ${options.path}');
          
          // Tạo response từ cache
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cachedData['data'],
              statusCode: 200,
              headers: Headers.fromMap(cachedData['headers'] ?? {}),
            ),
          );
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        // Lưu response vào cache nếu cần
        final useCache = response.requestOptions.extra['useCache'] == true;
        final cacheDuration = response.requestOptions.extra['cacheDuration'] as Duration? ?? 
            const Duration(minutes: 5);
        
        if (useCache && 
            response.requestOptions.method == 'GET' && 
            response.statusCode == 200) {
          final cacheKey = _createCacheKey(response.requestOptions);
          
          // Lưu dữ liệu vào cache
          await _cacheManager.put(
            cacheKey, 
            {
              'data': response.data,
              'headers': response.headers.map,
            },
            cacheDuration,
          );
        }
        
        // Xử lý invalidation cache nếu có
        final invalidateCache = response.requestOptions.extra['invalidateCache'];
        if (invalidateCache != null) {
          if (invalidateCache is List<String>) {
            for (final key in invalidateCache) {
              await _cacheManager.remove(key);
            }
          } else if (invalidateCache is String) {
            await _cacheManager.clearGroup(invalidateCache);
          }
        }
        
        return handler.next(response);
      },
    );
  }
  
  /// Tạo interceptor cho retry
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;
        
        // Kiểm tra xem có retry không
        final shouldRetry = requestOptions.extra['retry'] == true;
        final retryCount = requestOptions.extra['retryCount'] as int? ?? 3;
        final retryDelay = requestOptions.extra['retryDelay'] as Duration? ?? 
            const Duration(seconds: 1);
        
        // Kiểm tra xem error có thể retry không
        final canRetry = error.type == DioExceptionType.connectionTimeout ||
                         error.type == DioExceptionType.sendTimeout ||
                         error.type == DioExceptionType.receiveTimeout ||
                         (error.type == DioExceptionType.badResponse && 
                          (error.response?.statusCode == 408 || error.response?.statusCode == 429));
        
        // Lấy số lần đã retry
        final attemptCount = requestOptions.extra['attemptCount'] as int? ?? 0;
        
        if (shouldRetry && canRetry && attemptCount < retryCount) {
          _logger.debug(
            'DioHttpClient: Retry request (${attemptCount + 1}/$retryCount): [${requestOptions.method}] ${requestOptions.path}',
          );
          
          // Đợi trước khi retry
          await Future.delayed(retryDelay * (attemptCount + 1));
          
          // Tạo request options mới với attemptCount tăng lên
          final newOptions = Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            contentType: requestOptions.contentType,
            responseType: requestOptions.responseType,
            extra: Map.from(requestOptions.extra)..['attemptCount'] = attemptCount + 1,
          );
          
          // Thực hiện request lại
          try {
            final response = await _dio.request(
              requestOptions.path,
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
              options: newOptions,
              cancelToken: requestOptions.cancelToken,
            );
            
            return handler.resolve(response);
          } catch (e) {
            return handler.reject(e is DioException ? e : error);
          }
        }
        
        return handler.next(error);
      },
    );
  }
  
  /// Kết hợp các options và headers, thêm authorization nếu cần
  Options _mergeOptions(
    Options? options,
    Map<String, dynamic>? headers,
    bool requiresAuth,
  ) {
    final mergedOptions = options ?? Options();
    final mergedHeaders = Map<String, dynamic>.from(mergedOptions.headers ?? {});
    
    // Thêm headers mới
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }
    
    // Thêm Authorization nếu cần
    if (requiresAuth && _authToken != null && _authToken!.isNotEmpty) {
      mergedHeaders['Authorization'] = 'Bearer $_authToken';
    }
    
    return mergedOptions.copyWith(headers: mergedHeaders);
  }
  
  /// Tạo cache key từ request options
  String _createCacheKey(dynamic options) {
    // Xử lý cho RequestOptions của Dio
    if (options is RequestOptions) {
      final buffer = StringBuffer('${options.method}_${options.path}');
      
      if (options.queryParameters.isNotEmpty) {
        // Sắp xếp các tham số theo key để đảm bảo tính nhất quán
        final sortedParams = Map.fromEntries(
          options.queryParameters.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))
        );
        
        buffer.write('_params:');
        sortedParams.forEach((key, value) {
          buffer.write('_$key=$value');
        });
      }
      
      return buffer.toString();
    } 
    // Xử lý cho RequestOptions trong http_client_interface
    else if (options is http_client_interface.RequestOptions) {
      final buffer = StringBuffer('GET_${options.connectTimeout}');
      return buffer.toString();
    }
    
    // Fallback
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Xử lý lỗi request
  void _handleError(dynamic error, String requestId) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 0;
      final method = error.requestOptions.method;
      final path = error.requestOptions.path;
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          _logger.warn('DioHttpClient: Timeout [${method}] ${path}');
          break;
        case DioExceptionType.badResponse:
          _logger.warn('DioHttpClient: Bad response [${method}] ${path}: ${statusCode}');
          break;
        case DioExceptionType.cancel:
          _logger.debug('DioHttpClient: Request cancelled [${method}] ${path}');
          break;
        default:
          _logger.error('DioHttpClient: Error [${method}] ${path}', error);
          break;
      }
      
      _requestTracker.failRequest(requestId, error);
    } else {
      _logger.error('DioHttpClient: Unexpected error', error);
      _requestTracker.failRequest(requestId, error.toString());
    }
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    if (!_isDisposed) {
      _dio.close(force: true);
      _isDisposed = true;
      _logger.debug('DioHttpClient: Đã hủy');
    }
  }
} 