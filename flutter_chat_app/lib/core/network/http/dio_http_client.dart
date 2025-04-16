import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart' hide RequestOptions;
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:uuid/uuid.dart';

import '../auth/token_manager.dart';
import '../cache/network_response_cache.dart' hide CacheStrategy;
import '../connectivity/connectivity_service.dart';
import '../error/network_exceptions.dart';
import 'http_client_interface.dart';
import 'media_type.dart';

/// Implementation của IHttpClient sử dụng Dio với tối ưu performance
@LazySingleton(as: IHttpClient)
class DioHttpClient implements IHttpClient {
  /// Dio instance cho các request thông thường
  final dio.Dio _dio;
  
  /// Dio instance riêng cho upload file
  final dio.Dio _uploadDio;
  
  /// Cache manager cho API response
  final NetworkResponseCache _cacheManager;
  
  /// Token manager
  final TokenManager _tokenManager;
  
  /// Connectivity service
  final IConnectivityService _connectivityService;
  
  /// Base URL
  String _baseUrl;
  
  /// Request queue khi không có kết nối mạng
  final List<_PendingRequest> _pendingRequests = [];
  
  /// Trạng thái kết nối mạng
  bool _isConnected = true;
  
  /// Trạng thái khởi tạo
  bool _isInitialized = false;
  
  /// Đối tượng lock cho việc refresh token
  final _refreshTokenLock = Lock();
  
  /// Connection pool management
  final Map<String, DateTime> _connectionFailures = {};
  
  /// Max pending request
  static const int _maxPendingRequests = 50;
  
  /// Subscription for connectivity changes
  StreamSubscription? _connectivitySubscription;
  
  /// Constructor
  @factoryMethod
  DioHttpClient(
    this._cacheManager,
    this._tokenManager,
    this._connectivityService,
    @Named('apiBaseUrl') String baseUrl,
  ) : _dio = dio.Dio(),
      _uploadDio = dio.Dio(),
      _baseUrl = baseUrl {
    _initialize();
  }
  
  /// Khởi tạo client
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    // Cấu hình Dio clients
    _configureDio(_dio);
    _configureDio(_uploadDio, isUpload: true);
    
    // Thiết lập trạng thái kết nối hiện tại
    _isConnected = await _connectivityService.isConnected();
    
    // Lắng nghe sự thay đổi kết nối - use subscription instead of stream
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(_handleConnectivityChange);
    
    _isInitialized = true;
  }
  
  /// Xử lý thay đổi kết nối
  void _handleConnectivityChange(bool isConnected) {
    if (isConnected && !_isConnected) {
      // Kết nối đã được khôi phục
      _isConnected = true;
      _processPendingRequests();
    } else if (!isConnected && _isConnected) {
      // Mất kết nối
      _isConnected = false;
    }
  }
  
  /// Cấu hình cho Dio client
  void _configureDio(dio.Dio dioInstance, {bool isUpload = false}) {
    // Thiết lập base options
    dioInstance.options = dio.BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(milliseconds: isUpload ? 60000 : 30000),
      receiveTimeout: Duration(milliseconds: isUpload ? 60000 : 30000),
      sendTimeout: Duration(milliseconds: isUpload ? 60000 : 30000),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
      responseType: dio.ResponseType.json,
      listFormat: dio.ListFormat.multiCompatible,
    );
    
    // Configure HTTP client adapter
    final httpClientAdapter = dioInstance.httpClientAdapter;
    if (httpClientAdapter is IOHttpClientAdapter) {
      httpClientAdapter.createHttpClient = () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 30);
        client.connectionTimeout = const Duration(seconds: 30);
        client.maxConnectionsPerHost = 8; // Limit connection per host for better performance
        return client;
      };
    }
    
    // Custom retry interceptor với backoff strategy
    dioInstance.interceptors.add(
      RetryInterceptor(
        dio: dioInstance,
        logPrint: isUpload ? null : debugPrint,
        retries: 3,
        retryDelays: const [
          Duration(milliseconds: 500),
          Duration(seconds: 1),
          Duration(seconds: 3),
        ],
        retryableExtraStatuses: {401},
        retryEvaluator: _shouldRetryRequest,
      ),
    );
    
    // Interceptor xử lý connection
    dioInstance.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isConnected) {
            // Không có kết nối, cache request để thực hiện sau
            if (options.method == 'GET') {
              _queueRequest(options, handler);
              return;
            } else {
              handler.reject(dio.DioException(
                requestOptions: options,
                error: 'No internet connection',
                type: dio.DioExceptionType.connectionError,
              ));
              return;
            }
          }
          
          // Check if host has previous failures and implement backoff
          final host = _extractHost(options.uri.toString());
          if (_shouldBackOffForHost(host)) {
            handler.reject(dio.DioException(
              requestOptions: options,
              error: 'Host temporarily unavailable due to previous failures',
              type: dio.DioExceptionType.connectionError,
            ));
            return;
          }
          
          // Thêm request ID
          options.headers['X-Request-ID'] = const Uuid().v4();
          
          // Thêm token vào header nếu có
          await _addAuthToken(options);
          
          handler.next(options);
        },
        onError: (error, handler) async {
          // Record connection failures for backoff strategy
          if (_isConnectionError(error)) {
            _recordConnectionFailure(error.requestOptions.uri.toString());
          }
          
          if (error.response?.statusCode == 401) {
            // Token expired hoặc không hợp lệ
            final retried = await _handleTokenRefresh(error, handler);
            if (retried) return;
          }
          
          // Xử lý lỗi mạng
          if (_isNetworkError(error)) {
            // Lưu request để thử lại sau khi có kết nối
            if (error.requestOptions.method == 'GET') {
              _queueRequest(error.requestOptions, handler);
              return;
            }
          }
          
          handler.next(error);
        },
        onResponse: (response, handler) {
          // Reset connection failure count on successful response
          _resetConnectionFailure(response.requestOptions.uri.toString());
          handler.next(response);
        },
      ),
    );
    
    // Thêm logger cho môi trường debug
    if (!isUpload && kDebugMode) {
      dioInstance.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false, // Giảm log cho response header
          responseBody: true,
          compact: true, // Nén log để dễ đọc
          maxWidth: 90,
        ),
      );
    }
  }
  
  /// Extract host from URL
  String _extractHost(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}';
    } catch (_) {
      return url;
    }
  }
  
  /// Record connection failure for a host
  void _recordConnectionFailure(String url) {
    final host = _extractHost(url);
    _connectionFailures[host] = DateTime.now();
    
    // Clean up old entries every 10 failures
    if (_connectionFailures.length % 10 == 0) {
      _cleanupConnectionFailures();
    }
  }
  
  /// Reset connection failure for a host
  void _resetConnectionFailure(String url) {
    final host = _extractHost(url);
    _connectionFailures.remove(host);
  }
  
  /// Clean up old connection failures
  void _cleanupConnectionFailures() {
    final now = DateTime.now();
    _connectionFailures.removeWhere((_, timestamp) {
      return now.difference(timestamp).inMinutes > 10;
    });
  }
  
  /// Check if we should back off for a host
  bool _shouldBackOffForHost(String host) {
    final failureTime = _connectionFailures[host];
    if (failureTime == null) return false;
    
    final timeSinceFailure = DateTime.now().difference(failureTime);
    
    // Exponential backoff: wait longer for repeated failures
    final failureCount = _countRecentFailures(host);
    final backoffSeconds = failureCount * failureCount; // Exponential growth
    
    return timeSinceFailure.inSeconds < backoffSeconds;
  }
  
  /// Count recent failures for a host
  int _countRecentFailures(String host) {
    final now = DateTime.now();
    return _connectionFailures.entries
        .where((entry) => 
            entry.key == host && 
            now.difference(entry.value).inMinutes < 10)
        .length;
  }
  
  /// Check if error is a connection error
  bool _isConnectionError(dio.DioException error) {
    return error.type == dio.DioExceptionType.connectionError ||
           error.type == dio.DioExceptionType.connectionTimeout;
  }

  /// Kiểm tra xem có nên retry request hay không
  bool _shouldRetryRequest(dio.DioException error, int attempt) {
    // Không retry với các lỗi client (4xx) trừ 401
    if (error.response?.statusCode != null) {
      final statusCode = error.response!.statusCode!;
      if (statusCode >= 400 && statusCode < 500 && statusCode != 401) {
        return false;
      }
    }
    
    // Retry với các lỗi timeout và network
    return error.type == dio.DioExceptionType.connectionTimeout ||
           error.type == dio.DioExceptionType.receiveTimeout ||
           error.type == dio.DioExceptionType.sendTimeout ||
           error.type == dio.DioExceptionType.connectionError ||
           (error.response?.statusCode == 401 && attempt == 1);
  }
  
  /// Xử lý khi token hết hạn
  Future<bool> _handleTokenRefresh(dio.DioException error, dio.ErrorInterceptorHandler handler) async {
    return await _refreshTokenLock.synchronized<bool>(() async {
      try {
        final refreshed = await _tokenManager.refreshToken();
        if (refreshed) {
          // Lấy token mới và thử lại request
          final dioOptions = error.requestOptions;
          
          // Thêm token mới vào request
          await _addAuthToken(dioOptions);
          
          // Thực hiện lại request
          final response = await _dio.fetch(dioOptions);
          handler.resolve(response);
          return true;
        }
      } catch (e) {
        debugPrint('Failed to refresh token: $e');
      }
      return false;
    });
  }
  
  /// Thêm token vào request
  Future<void> _addAuthToken(dio.RequestOptions options) async {
    final token = await _tokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }
  
  /// Kiểm tra lỗi mạng
  bool _isNetworkError(dio.DioException error) {
    return error.type == dio.DioExceptionType.connectionError ||
           error.type == dio.DioExceptionType.connectionTimeout ||
           error.error is SocketException;
  }
  
  /// Thêm request vào hàng đợi khi không có kết nối
  void _queueRequest(dio.RequestOptions options, dynamic handler) {
    if (_pendingRequests.length >= _maxPendingRequests) {
      // Giới hạn số lượng request trong hàng đợi
      _pendingRequests.removeAt(0);
    }
    
    _pendingRequests.add(_PendingRequest(options, handler));
    debugPrint('Request queued: ${options.path} (${_pendingRequests.length} pending)');
  }
  
  /// Xử lý các request trong hàng đợi khi connection được khôi phục
  Future<void> _processPendingRequests() async {
    if (_pendingRequests.isEmpty) return;
    
    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    
    final batchSize = 5; // Process in batches to avoid overwhelming the network
    for (int i = 0; i < requests.length; i += batchSize) {
      final batch = requests.skip(i).take(batchSize);
      final futures = <Future>[];
      
      for (final request in batch) {
        futures.add(_processPendingRequest(request));
      }
      
      // Wait for batch to complete before processing the next one
      await Future.wait(futures);
      
      // Short delay between batches
      if (i + batchSize < requests.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }
  
  /// Process a single pending request
  Future<void> _processPendingRequest(_PendingRequest request) async {
    try {
      // Thêm token mới nếu cần
      await _addAuthToken(request.options);
      
      // Thực hiện request
      final response = await _dio.fetch(request.options);
      
      // Xử lý kết quả
      if (request.handler is dio.RequestInterceptorHandler) {
        (request.handler as dio.RequestInterceptorHandler).resolve(response);
      } else if (request.handler is dio.ErrorInterceptorHandler) {
        (request.handler as dio.ErrorInterceptorHandler).resolve(response);
      }
    } catch (e) {
      // Xử lý lỗi
      if (request.handler is dio.RequestInterceptorHandler) {
        (request.handler as dio.RequestInterceptorHandler).reject(
          dio.DioException(
            requestOptions: request.options,
            error: e,
            type: dio.DioExceptionType.unknown,
          ),
        );
      } else if (request.handler is dio.ErrorInterceptorHandler) {
        (request.handler as dio.ErrorInterceptorHandler).next(
          dio.DioException(
            requestOptions: request.options,
            error: e,
            type: dio.DioExceptionType.unknown,
          ),
        );
      }
    }
  }
  
  /// Tạo cache key từ parameters
  String _createCacheKey(String endpoint, Map<String, dynamic>? queryParams) {
    String key = endpoint;
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      key += '_' + json.encode(sortedParams);
    }
    
    return key;
  }
  
  @override
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool useCache = false,
    CacheStrategy cacheStrategy = CacheStrategy.networkFirst,
    Duration cacheDuration = const Duration(minutes: 5),
    String? cacheGroup,
    RetryConfig? retryConfig,
    RequestOptions? options,
  }) async {
    try {
      // Kiểm tra kết nối mạng
      final hasConnection = await _checkConnectivity();
      if (!hasConnection && cacheStrategy != CacheStrategy.cacheOnly) {
        // Nếu không có kết nối và không dùng cache only thì thử lấy từ cache
        if (useCache) {
          final cacheKey = _createCacheKey(endpoint, queryParams);
          final cachedData = await _cacheManager.getCache<T>(cacheKey);
          
          if (cachedData != null) {
            return cachedData;
          }
        }
        
        throw NoConnectionException();
      }
      
      // Tùy chỉnh retry config nếu có
      if (retryConfig != null) {
        final retryInterceptor = RetryInterceptor(
          dio: _dio,
          logPrint: debugPrint,
          retries: retryConfig.maxRetries,
          retryDelays: retryConfig.retryDelays.map((delay) => Duration(milliseconds: delay)).toList(),
        );
        
        // Thêm tạm thời cho request này
        _dio.interceptors.add(retryInterceptor);
        
        // Đảm bảo loại bỏ sau khi hoàn thành
        try {
          return await _executeGetRequest<T>(
            endpoint, queryParams, headers, cancelToken, 
            useCache, cacheStrategy, cacheDuration, cacheGroup, options
          );
        } finally {
          _dio.interceptors.remove(retryInterceptor);
        }
      }
      
      return await _executeGetRequest<T>(
        endpoint, queryParams, headers, cancelToken, 
        useCache, cacheStrategy, cacheDuration, cacheGroup, options
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Thực hiện GET request với các chiến lược cache
  Future<T> _executeGetRequest<T>(
    String endpoint,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool useCache,
    CacheStrategy cacheStrategy,
    Duration cacheDuration,
    String? cacheGroup,
    RequestOptions? customOptions,
  ) async {
    if (useCache) {
      final cacheKey = _createCacheKey(endpoint, queryParams);
      
      switch (cacheStrategy) {
        case CacheStrategy.cacheFirst:
          // Thử lấy từ cache trước
          final cachedData = await _cacheManager.getCache<T>(cacheKey);
          if (cachedData != null) {
            return cachedData;
          }
          
          // Nếu không có cache thì lấy từ network
          final networkResponse = await _dio.get<T>(
            endpoint,
            queryParameters: queryParams,
            options: _buildDioOptions(headers, customOptions),
            cancelToken: cancelToken?.asDioCancelToken,
          );
          
          // Cache lại response
          await _cacheManager.cacheResponse<T>(
            cacheKey, 
            networkResponse.data as T,
            expiryDuration: cacheDuration,
            group: cacheGroup,
          );
          
          return networkResponse.data as T;
          
        case CacheStrategy.networkFirst:
          try {
            // Thử lấy từ network trước
            final networkResponse = await _dio.get<T>(
              endpoint,
              queryParameters: queryParams,
              options: _buildDioOptions(headers, customOptions),
              cancelToken: cancelToken?.asDioCancelToken,
            );
            
            // Cache lại response
            await _cacheManager.cacheResponse<T>(
              cacheKey, 
              networkResponse.data as T,
              expiryDuration: cacheDuration,
              group: cacheGroup,
            );
            
            return networkResponse.data as T;
          } catch (e) {
            // Nếu lỗi thì thử lấy từ cache
            final cachedData = await _cacheManager.getCache<T>(cacheKey);
            if (cachedData != null) {
              return cachedData;
            }
            
            // Nếu không có cache thì throw lỗi
            rethrow;
          }
          
        case CacheStrategy.staleWhileRevalidate:
          // Lấy cache luôn nếu có
          final cachedData = await _cacheManager.getCache<T>(cacheKey);
          
          // Gọi API ngầm để cập nhật cache
          _dio.get<T>(
            endpoint,
            queryParameters: queryParams,
            options: _buildDioOptions(headers, customOptions),
            cancelToken: cancelToken?.asDioCancelToken,
          ).then((response) async {
            // Cache lại response mới
            await _cacheManager.cacheResponse<T>(
              cacheKey, 
              response.data as T,
              expiryDuration: cacheDuration,
              group: cacheGroup,
            );
          }).catchError((e) {
            // Bỏ qua lỗi khi update cache
            debugPrint('Failed to update cache: $e');
          });
          
          // Trả về cache nếu có
          if (cachedData != null) {
            return cachedData;
          }
          
          // Nếu không có cache thì đợi kết quả từ network
          final networkResponse = await _dio.get<T>(
            endpoint,
            queryParameters: queryParams,
            options: _buildDioOptions(headers, customOptions),
            cancelToken: cancelToken?.asDioCancelToken,
          );
          
          // Cache lại response
          await _cacheManager.cacheResponse<T>(
            cacheKey, 
            networkResponse.data as T,
            expiryDuration: cacheDuration,
            group: cacheGroup,
          );
          
          return networkResponse.data as T;
          
        case CacheStrategy.cacheOnly:
          // Chỉ lấy từ cache
          final cachedData = await _cacheManager.getCache<T>(cacheKey);
          if (cachedData != null) {
            return cachedData;
          }
          
          throw CacheNotFoundException(message: 'Required data not in cache');
          
        case CacheStrategy.networkOnly:
          // Chỉ lấy từ network
          final networkResponse = await _dio.get<T>(
            endpoint,
            queryParameters: queryParams,
            options: _buildDioOptions(headers, customOptions),
            cancelToken: cancelToken?.asDioCancelToken,
          );
          
          // Cache lại response
          await _cacheManager.cacheResponse<T>(
            cacheKey, 
            networkResponse.data as T,
            expiryDuration: cacheDuration,
            group: cacheGroup,
          );
          
          return networkResponse.data as T;
      }
    } else {
      // Không dùng cache, gọi API trực tiếp
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParams,
        options: _buildDioOptions(headers, customOptions),
        cancelToken: cancelToken?.asDioCancelToken,
      );
      
      return response.data as T;
    }
    
    // Để tránh lỗi không return (không bao giờ chạy đến đây)
    throw Exception("Unexpected execution path in _executeGetRequest");
  }
  
  /// Tạo Options từ headers và custom options
  dio.Options _buildDioOptions(Map<String, String>? headers, RequestOptions? customOptions) {
    final options = dio.Options(headers: headers);
    
    if (customOptions != null) {
      if (customOptions.connectTimeout != null) {
        options.sendTimeout = Duration(milliseconds: customOptions.connectTimeout!);
      }
      if (customOptions.receiveTimeout != null) {
        options.receiveTimeout = Duration(milliseconds: customOptions.receiveTimeout!);
      }
      if (customOptions.sendTimeout != null) {
        options.sendTimeout = Duration(milliseconds: customOptions.sendTimeout!);
      }
      if (customOptions.headers != null) {
        options.headers = {...?options.headers, ...customOptions.headers!};
      }
    }
    
    return options;
  }
  
  @override
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  }) async {
    try {
      // Kiểm tra kết nối mạng
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw NoConnectionException();
      }
      
      final response = await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: _buildDioOptions(headers, options),
        cancelToken: cancelToken?.asDioCancelToken,
      );
      
      // Invalidate cache nếu cần
      if (invalidateCache != null) {
        await _cacheManager.invalidateCache(invalidateCache);
      }
      
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  }) async {
    try {
      // Kiểm tra kết nối mạng
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw NoConnectionException();
      }
      
      final response = await _dio.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: _buildDioOptions(headers, options),
        cancelToken: cancelToken?.asDioCancelToken,
      );
      
      // Invalidate cache nếu cần
      if (invalidateCache != null) {
        await _cacheManager.invalidateCache(invalidateCache);
      }
      
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  }) async {
    try {
      // Kiểm tra kết nối mạng
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw NoConnectionException();
      }
      
      final response = await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: _buildDioOptions(headers, options),
        cancelToken: cancelToken?.asDioCancelToken,
      );
      
      // Invalidate cache nếu cần
      if (invalidateCache != null) {
        await _cacheManager.invalidateCache(invalidateCache);
      }
      
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<T> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  }) async {
    try {
      // Kiểm tra kết nối mạng
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw NoConnectionException();
      }
      
      final response = await _dio.delete<T>(
        endpoint,
        queryParameters: queryParams,
        options: _buildDioOptions(headers, options),
        cancelToken: cancelToken?.asDioCancelToken,
      );
      
      // Invalidate cache nếu cần
      if (invalidateCache != null) {
        await _cacheManager.invalidateCache(invalidateCache);
      }
      
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<String> downloadFile(
    String url, {
    required String savePath,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      // Kiểm tra kết nối mạng
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw NoConnectionException();
      }
      
      // Tạo thư mục nếu cần
      final directory = Directory(savePath.substring(0, savePath.lastIndexOf('/')));
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      
      // Tải file
      await _dio.download(
        url,
        savePath,
        queryParameters: queryParams,
        options: dio.Options(headers: headers),
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken?.asDioCancelToken,
        deleteOnError: true, // Xóa file nếu có lỗi
      );
      
      return savePath;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<T> uploadFile<T>(
    String endpoint, {
    required List<FileUploadInfo> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Kiểm tra kết nối mạng
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw NoConnectionException();
      }
      
      // Tạo form data
      final formData = dio.FormData();
      
      // Thêm fields
      if (data != null) {
        formData.fields.addAll(
          data.entries.map((e) => MapEntry(e.key, e.value.toString()))
        );
      }
      
      // Thêm files
      for (final file in files) {
        if (file.bytes != null) {
          // Upload từ bytes
          formData.files.add(
            MapEntry(
              file.fieldName,
              dio.MultipartFile.fromBytes(
                file.bytes!,
                filename: file.fileName,
                // Don't explicitly set contentType, let Dio handle it based on filename
              ),
            ),
          );
        } else if (file.filePath != null) {
          // Kiểm tra file tồn tại
          final fileObj = File(file.filePath!);
          if (!await fileObj.exists()) {
            throw FileNotFoundException(message: 'File not found: ${file.filePath}');
          }
          
          // Upload từ file path
          formData.files.add(
            MapEntry(
              file.fieldName,
              await dio.MultipartFile.fromFile(
                file.filePath!,
                filename: file.fileName,
                // Don't explicitly set contentType, let Dio handle it based on filename
              ),
            ),
          );
        }
      }
      
      // Gửi request
      final response = await _uploadDio.post<T>(
        endpoint,
        data: formData,
        queryParameters: queryParams,
        options: dio.Options(headers: headers),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken?.asDioCancelToken,
      );
      
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
    _uploadDio.options.baseUrl = baseUrl;
  }
  
  @override
  void setToken(String token) {
    _tokenManager.setAccessToken(token);
  }
  
  @override
  void clearToken() {
    _tokenManager.clearTokens();
  }
  
  @override
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
  
  @override
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }
  
  /// Kiểm tra kết nối mạng
  Future<bool> _checkConnectivity() async {
    if (_isConnected) {
      // Double-check if we're actually connected if we think we are
      try {
        _isConnected = await _connectivityService.isConnected();
      } catch (e) {
        // Fallback to current state on error
        debugPrint('Error checking connectivity: $e');
      }
    }
    return _isConnected;
  }
  
  /// Xử lý lỗi từ Dio
  Exception _handleError(dynamic error) {
    if (error is dio.DioException) {
      return NetworkExceptionFactory.fromDioException(error);
    } else if (error is Exception) {
      return error;
    }
    
    return UnexpectedException(error: error);
  }
  
  @override
  void dispose() {
    _dio.close(force: true);
    _uploadDio.close(force: true);
    _pendingRequests.clear();
    _connectionFailures.clear();
    _connectivitySubscription?.cancel();
    _isInitialized = false;
  }
}

/// Class để lưu trữ request đang chờ
class _PendingRequest {
  final dio.RequestOptions options;
  final dynamic handler;
  final DateTime timestamp = DateTime.now();
  
  _PendingRequest(this.options, this.handler);
}

/// Class lock để synchronize các requests
class Lock {
  Completer<void>? _completer;
  
  bool get isLocked => _completer != null;
  
  Future<T> synchronized<T>(Future<T> Function() action) async {
    // Wait for previous action to complete
    if (_completer != null) {
      await _completer!.future;
    }
    
    // Create new lock
    _completer = Completer<void>();
    
    try {
      // Execute the action
      return await action();
    } finally {
      // Release the lock
      _completer!.complete();
      _completer = null;
    }
  }
}

/// Custom exception cho cache không tìm thấy
class CacheNotFoundException implements Exception {
  final String message;
  
  CacheNotFoundException({required this.message});
  
  @override
  String toString() => 'CacheNotFoundException: $message';
}

/// Custom exception cho file không tìm thấy
class FileNotFoundException implements Exception {
  final String message;
  
  FileNotFoundException({required this.message});
  
  @override
  String toString() => 'FileNotFoundException: $message';
}

/// Extension to convert our CancelToken to Dio's CancelToken
extension CancelTokenExtension on CancelToken {
  dio.CancelToken get asDioCancelToken {
    final dioCancelToken = dio.CancelToken();
    
    // Link our cancel token to Dio's
    whenCancel.then((_) {
      if (!dioCancelToken.isCancelled) {
        dioCancelToken.cancel('Request cancelled');
      }
    });
    
    return dioCancelToken;
  }
} 