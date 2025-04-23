import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/network/http/performance_monitor.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import '../monitoring/logger.dart';
import '../monitoring/analytics_service.dart';
import 'http/dio_http_client.dart';
import 'http/http_client_interface.dart';
import 'http/media_type.dart';
import 'error/api_error.dart';
import 'auth/auth_interceptor.dart';
import 'connectivity/connectivity_manager.dart';
import 'cache/api_cache_manager.dart';

/// Abstract interface for API communication
abstract class ApiClient {
  /// Performs a GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool useCache = false,
    Duration? cacheDuration,
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
  
  /// Upload file(s)
  Future<dynamic> uploadFile(
    String endpoint, {
    required List<MapEntry<String, File>> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  });
  
  /// Download file
  Future<String> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  });
  
  /// Set auth token
  void setAuthToken(String token);
  
  /// Clear auth token
  void clearAuthToken();
  
  /// Get performance stats
  Map<String, dynamic> getPerformanceStats();
}

/// Implementation of the ApiClient interface
@LazySingleton(as: ApiClient)
class ApiClientImpl implements ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;
  final NetworkPerformanceMonitor _performanceMonitor;
  
  // In-memory cache for GET requests
  final Map<String, _CacheEntry> _cache = {};
  
  // Default cache duration
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  
  // Maximum cache size
  static const int _maxCacheEntries = 100;

  final HttpClientInterface _httpClient;
  final AppLogger _logger;
  final AnalyticsService _analytics;
  final ConnectivityManager _connectivityManager;
  final ApiCacheManager _cacheManager;
  
  final Map<String, int> _endpointLatency = {};
  final Map<String, int> _endpointErrorCount = {};
  final Map<String, int> _endpointCallCount = {};
  
  /// Singleton instance
  static ApiClientImpl? _instance;
  static ApiClientImpl get instance => _instance!;
  
  /// Constructor
  ApiClientImpl(
    this._dio, 
    this._networkInfo,
    this._httpClient,
    this._logger,
    this._analytics,
    this._connectivityManager,
    this._cacheManager,
  ) : _performanceMonitor = NetworkPerformanceMonitor() {
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

    // Add performance tracking interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Track request start
          final requestId = _performanceMonitor.trackRequestStart(
            options.uri.toString(),
            options.method,
          );
          
          // Add request ID to options for tracking
          options.extra['requestId'] = requestId;
          
          // Add auth token if needed (handled in setAuthToken)
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Get request ID
          final requestId = response.requestOptions.extra['requestId'] as String?;
          if (requestId != null) {
            // Track request end
            _performanceMonitor.trackRequestEnd(
              requestId,
              resultType: RequestResultType.success,
              statusCode: response.statusCode,
              responseSize: _calculateResponseSize(response.data),
            );
          }
          
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // Get request ID
          final requestId = e.requestOptions.extra['requestId'] as String?;
          if (requestId != null) {
            // Track request end with error
            _performanceMonitor.trackRequestEnd(
              requestId,
              resultType: _mapDioErrorToResultType(e),
              statusCode: e.response?.statusCode,
            );
          }
          
          final errorResponse = await _handleDioError(e);
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
    
    // Optimize Dio HTTP client adapter
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.idleTimeout = const Duration(seconds: 30);
      client.connectionTimeout = const Duration(seconds: 30);
      client.maxConnectionsPerHost = 8;
      return client;
    };
  }
  
  // Calculate size of response data
  int? _calculateResponseSize(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is String) {
        return data.length;
      } else {
        return jsonEncode(data).length;
      }
    } catch (_) {
      return null;
    }
  }
  
  // Map Dio error to result type
  RequestResultType _mapDioErrorToResultType(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return RequestResultType.timeout;
      case DioExceptionType.cancel:
        return RequestResultType.canceled;
      default:
        return RequestResultType.error;
    }
  }

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool useCache = false,
    Duration? cacheDuration,
  }) async {
    // Check if we should use cache and if it exists
    if (useCache) {
      final cacheKey = _generateCacheKey(endpoint, queryParameters);
      final cachedEntry = _cache[cacheKey];
      
      // Check if cache is valid
      if (cachedEntry != null && !cachedEntry.isExpired) {
        // Track cached response in performance monitor
        final requestId = _performanceMonitor.trackRequestStart(
          _dio.options.baseUrl + endpoint,
          'GET',
        );
        
        _performanceMonitor.trackRequestEnd(
          requestId,
          resultType: RequestResultType.success,
          fromCache: true,
          responseSize: _calculateResponseSize(cachedEntry.data),
        );
        
        return cachedEntry.data;
      }
    }
    
    final result = await _executeRequest(
      _dio.get,
      endpoint,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    
    // Cache the result if needed
    if (useCache) {
      _cacheResponse(
        endpoint, 
        queryParameters, 
        result, 
        cacheDuration ?? _defaultCacheDuration
      );
    }
    
    return result;
  }

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final result = await _executeRequest(
      _dio.post,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    
    // Invalidate related cache entries
    _invalidateRelatedCache(endpoint);
    
    return result;
  }

  @override
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final result = await _executeRequest(
      _dio.put,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    
    // Invalidate related cache entries
    _invalidateRelatedCache(endpoint);
    
    return result;
  }

  @override
  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final result = await _executeRequest(
      _dio.patch,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    
    // Invalidate related cache entries
    _invalidateRelatedCache(endpoint);
    
    return result;
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final result = await _executeRequest(
      _dio.delete,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    
    // Invalidate related cache entries
    _invalidateRelatedCache(endpoint);
    
    return result;
  }
  
  @override
  Future<dynamic> uploadFile(
    String endpoint, {
    required List<MapEntry<String, File>> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw NoInternetException();
    }
    
    try {
      // Track request start
      final requestId = _performanceMonitor.trackRequestStart(
        _dio.options.baseUrl + endpoint,
        'POST',
      );
      
      // Create form data
      final formData = FormData();
      
      // Add regular data
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      // Add files
      for (final fileEntry in files) {
        final file = fileEntry.value;
        final fileName = file.path.split('/').last;
        
        formData.files.add(
          MapEntry(
            fileEntry.key,
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
            ),
          ),
        );
      }
      
      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      
      // Track request end
      _performanceMonitor.trackRequestEnd(
        requestId,
        resultType: RequestResultType.success,
        statusCode: response.statusCode,
        responseSize: _calculateResponseSize(response.data),
      );
      
      // Invalidate related cache
      _invalidateRelatedCache(endpoint);
      
      return response.data;
    } on DioException catch (e) {
      final requestId = e.requestOptions.extra['requestId'] as String?;
      if (requestId != null) {
        _performanceMonitor.trackRequestEnd(
          requestId,
          resultType: _mapDioErrorToResultType(e),
          statusCode: e.response?.statusCode,
        );
      }
      
      throw await _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  Future<String> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw NoInternetException();
    }
    
    try {
      // Track request start
      final requestId = _performanceMonitor.trackRequestStart(
        url,
        'GET',
      );
      
      // Ensure directory exists
      final saveDir = Directory(savePath.substring(0, savePath.lastIndexOf('/')));
      if (!saveDir.existsSync()) {
        saveDir.createSync(recursive: true);
      }
      
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      
      // Track request end
      _performanceMonitor.trackRequestEnd(
        requestId,
        resultType: RequestResultType.success,
      );
      
      return savePath;
    } on DioException catch (e) {
      final requestId = e.requestOptions.extra['requestId'] as String?;
      if (requestId != null) {
        _performanceMonitor.trackRequestEnd(
          requestId,
          resultType: _mapDioErrorToResultType(e),
          statusCode: e.response?.statusCode,
        );
      }
      
      throw await _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  @override
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  @override
  Map<String, dynamic> getPerformanceStats() {
    final stats = _performanceMonitor.getEndpointsByPerformance();
    
    // Add cache stats
    final cacheHitRate = _calculateCacheHitRate();
    
    return {
      'endpoints': stats,
      'cacheSize': _cache.length,
      'cacheHitRate': cacheHitRate,
      'averageResponseTime': stats.isNotEmpty ? stats.first['avgTimeMs'] : 0,
    };
  }
  
  // Calculate cache hit rate
  double _calculateCacheHitRate() {
    final metrics = _performanceMonitor.metrics;
    if (metrics.isEmpty) return 0.0;
    
    final cacheHits = metrics.where((m) => m.fromCache).length;
    return cacheHits / metrics.length;
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
      throw await _handleDioError(e);
    } on SocketException {
      throw NoInternetException();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<DioException> _handleDioError(DioException e) async {
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
          // Clear auth token on 401 errors
          clearAuthToken();
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
  
  // Cache a response
  void _cacheResponse(
    String endpoint,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Duration duration,
  ) {
    final cacheKey = _generateCacheKey(endpoint, queryParameters);
    
    // Handle cache size limit
    if (_cache.length >= _maxCacheEntries) {
      // Remove oldest entry
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }
    
    _cache[cacheKey] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiry: DateTime.now().add(duration),
    );
  }
  
  // Generate cache key from endpoint and parameters
  String _generateCacheKey(String endpoint, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return endpoint;
    }
    
    // Sort parameters to ensure consistent keys
    final sortedParams = Map.fromEntries(
      queryParameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    return '$endpoint?${_mapToQueryString(sortedParams)}';
  }
  
  // Convert map to query string
  String _mapToQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }
  
  // Invalidate related cache entries
  void _invalidateRelatedCache(String endpoint) {
    _cache.removeWhere((key, _) => key.startsWith(endpoint));
  }
}

// Class to hold cached data
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final DateTime expiry;
  
  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiry,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiry);
} 