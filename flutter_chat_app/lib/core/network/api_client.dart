import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:mime/mime.dart';

import '../monitoring/analytics_service.dart';
import '../monitoring/logger.dart';
import 'cache/api_cache_manager.dart';
import 'http/http_client_interface.dart';
import 'monitoring/api_request_tracker.dart';

/// ApiClient class that provides a high-level interface for making API calls
/// with built-in performance tracking, error handling, and caching.
@lazySingleton
class ApiClient {
  // Singleton instance
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();
  
  // Dependencies
  final IHttpClient _httpClient;
  final ApiRequestTracker _requestTracker;
  final AppLogger _logger;
  final AnalyticsService _analytics;
  final ApiCacheManager _cacheManager;
  
  // Performance tracking
  final Map<String, int> _endpointCallCounts = {};
  final Map<String, List<int>> _responseTimes = {};
  bool _isPerformanceLoggingEnabled = true;
  
  // Retry configuration
  int _maxRetries = 3;
  List<int> _retryDelays = [1000, 2000, 5000];
  
  @visibleForTesting
  ApiClient({
    required IHttpClient httpClient,
    required ApiRequestTracker requestTracker,
    required AppLogger logger,
    required AnalyticsService analytics,
    required ApiCacheManager cacheManager,
  }) : _httpClient = httpClient,
       _requestTracker = requestTracker,
       _logger = logger,
       _analytics = analytics,
       _cacheManager = cacheManager;
  
  // Internal constructor for singleton pattern
  ApiClient._() :
      _httpClient = GetIt.instance<IHttpClient>(),
      _requestTracker = ApiRequestTracker.instance,
      _logger = GetIt.instance<AppLogger>(),
      _analytics = GetIt.instance<AnalyticsService>(),
      _cacheManager = ApiCacheManager.instance;
  
  /// Initialize the ApiClient with base configuration
  Future<void> initialize({
    required String baseUrl,
    Map<String, dynamic>? defaultHeaders,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
    int sendTimeout = 30000,
    int maxRetries = 3,
    List<int>? retryDelays,
    bool enablePerformanceLogging = true,
  }) async {
    _logger.debug('ApiClient: Initializing with baseUrl: $baseUrl');
    
    await _httpClient.configure(
      baseUrl: baseUrl,
      headers: defaultHeaders,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout, 
      sendTimeout: sendTimeout,
    );
    
    _maxRetries = maxRetries;
    _retryDelays = retryDelays ?? [1000, 2000, 5000];
    _isPerformanceLoggingEnabled = enablePerformanceLogging;
    
    _logger.debug('ApiClient: Initialized successfully');
  }
  
  /// Set authorization token
  void setAuthToken(String token) {
    _httpClient.updateAuthToken(token);
  }
  
  /// Clear authorization token
  void clearAuthToken() {
    _httpClient.clearAuthToken();
  }
  
  /// Set default headers
  void setDefaultHeaders(Map<String, dynamic> headers) {
    _httpClient.setDefaultHeaders(headers);
  }
  
  /// Enable or disable performance logging
  Future<void> setPerformanceLoggingEnabled(bool enabled) async {
    _isPerformanceLoggingEnabled = enabled;
  }
  
  /// Configure retry behavior
  void configureRetry({
    required int maxRetries,
    required List<int> retryDelays,
  }) {
    _maxRetries = maxRetries;
    _retryDelays = retryDelays;
  }
  
  /// Execute a GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    CacheStrategy cacheStrategy = CacheStrategy.networkOnly,
    Duration cacheDuration = const Duration(minutes: 5),
    bool trackPerformance = true,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest<T>(
      'GET',
      endpoint,
      queryParams: queryParams,
      headers: headers,
      requiresAuth: requiresAuth,
      cacheStrategy: cacheStrategy,
      cacheDuration: cacheDuration,
      trackPerformance: trackPerformance,
      cancelToken: cancelToken,
    );
  }

  /// Execute a POST request
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    CacheStrategy cacheStrategy = CacheStrategy.networkOnly,
    Duration cacheDuration = const Duration(minutes: 5),
    bool trackPerformance = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _executeRequest<T>(
      'POST',
      endpoint,
      data: data,
      queryParams: queryParams,
      headers: headers,
      requiresAuth: requiresAuth,
      cacheStrategy: cacheStrategy,
      cacheDuration: cacheDuration,
      trackPerformance: trackPerformance,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Execute a PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    CacheStrategy cacheStrategy = CacheStrategy.networkOnly,
    Duration cacheDuration = const Duration(minutes: 5),
    bool trackPerformance = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _executeRequest<T>(
      'PUT',
      endpoint,
      data: data,
      queryParams: queryParams,
      headers: headers,
      requiresAuth: requiresAuth,
      cacheStrategy: cacheStrategy,
      cacheDuration: cacheDuration,
      trackPerformance: trackPerformance,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Execute a DELETE request
  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    CacheStrategy cacheStrategy = CacheStrategy.networkOnly,
    Duration cacheDuration = const Duration(minutes: 5),
    bool trackPerformance = true,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest<T>(
      'DELETE',
      endpoint,
      data: data,
      queryParams: queryParams,
      headers: headers,
      requiresAuth: requiresAuth,
      cacheStrategy: cacheStrategy,
      cacheDuration: cacheDuration,
      trackPerformance: trackPerformance,
      cancelToken: cancelToken,
    );
  }

  /// Execute a PATCH request
  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    CacheStrategy cacheStrategy = CacheStrategy.networkOnly,
    Duration cacheDuration = const Duration(minutes: 5),
    bool trackPerformance = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _executeRequest<T>(
      'PATCH',
      endpoint,
      data: data,
      queryParams: queryParams,
      headers: headers,
      requiresAuth: requiresAuth,
      cacheStrategy: cacheStrategy,
      cacheDuration: cacheDuration,
      trackPerformance: trackPerformance,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
  
  /// Upload a file
  Future<T> uploadFile<T>(
    String endpoint, {
    required File file,
    required String fileName,
    String fileKey = 'file',
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    bool trackPerformance = true,
      CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (!file.existsSync()) {
      throw FileSystemException('File not found', file.path);
    }
    
    final requestId = trackPerformance 
        ? _requestTracker.startRequest('POST', endpoint, params: queryParams)
        : null;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await _httpClient.uploadFile(
        endpoint,
        file: file,
        fileName: fileName,
        fileKey: fileKey,
        data: additionalData,
        queryParameters: queryParams,
        headers: headers,
        requiresAuth: requiresAuth,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      if (trackPerformance) {
        _trackRequestCompletion(
          requestId!,
          endpoint,
          'POST',
          stopwatch.elapsedMilliseconds,
          response.statusCode ?? 200,
        );
      }
      
      return _processResponse<T>(response);
    } catch (e) {
      if (trackPerformance && requestId != null) {
        _requestTracker.failRequest(requestId, e);
        _trackRequestError(endpoint, 'POST', stopwatch.elapsedMilliseconds, e);
      }
      
      rethrow;
    }
  }
  
  /// Upload multiple files
  Future<T> uploadFiles<T>(
    String endpoint, {
    required List<File> files,
    required List<String> fileNames,
    String fileKey = 'files',
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    bool trackPerformance = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    // Verify all files exist
    for (var i = 0; i < files.length; i++) {
      if (!files[i].existsSync()) {
        throw FileSystemException('File not found', files[i].path);
      }
    }
    
    final requestId = trackPerformance 
        ? _requestTracker.startRequest('POST', endpoint, params: queryParams)
        : null;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await _httpClient.uploadFiles(
        endpoint,
        files: files,
        fileNames: fileNames,
        fileKey: fileKey,
        data: additionalData,
        queryParameters: queryParams,
        headers: headers,
        requiresAuth: requiresAuth,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      if (trackPerformance) {
        _trackRequestCompletion(
          requestId!,
          endpoint,
          'POST',
          stopwatch.elapsedMilliseconds,
          response.statusCode ?? 200,
        );
      }
      
      return _processResponse<T>(response);
    } catch (e) {
      if (trackPerformance && requestId != null) {
        _requestTracker.failRequest(requestId, e);
        _trackRequestError(endpoint, 'POST', stopwatch.elapsedMilliseconds, e);
      }
      
      rethrow;
    }
  }
  
  /// Upload bytes as a file
  Future<T> uploadBytes<T>(
    String endpoint, {
    required Uint8List bytes,
    required String fileName,
    String fileKey = 'file',
    String? mimeType,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    bool trackPerformance = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final requestId = trackPerformance 
        ? _requestTracker.startRequest('POST', endpoint, params: queryParams)
        : null;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await _httpClient.uploadBytes(
        endpoint,
        bytes: bytes,
        fileName: fileName,
        fileKey: fileKey,
        mimeType: mimeType ?? _guessMimeType(fileName),
        data: additionalData,
        queryParameters: queryParams,
        headers: headers,
        requiresAuth: requiresAuth,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      if (trackPerformance) {
        _trackRequestCompletion(
          requestId!,
          endpoint,
          'POST',
          stopwatch.elapsedMilliseconds,
          response.statusCode ?? 200,
        );
      }
      
      return _processResponse<T>(response);
    } catch (e) {
      if (trackPerformance && requestId != null) {
        _requestTracker.failRequest(requestId, e);
        _trackRequestError(endpoint, 'POST', stopwatch.elapsedMilliseconds, e);
      }
      
      rethrow;
    }
  }
  
  /// Download a file
  Future<bool> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    bool trackPerformance = true,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool deleteOnError = true,
  }) async {
    final requestId = trackPerformance 
        ? _requestTracker.startRequest('GET', url, params: queryParams)
        : null;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await _httpClient.downloadFile(
        url,
        savePath,
        queryParameters: queryParams,
        headers: headers,
        requiresAuth: requiresAuth,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        deleteOnError: deleteOnError,
      );
      
      if (trackPerformance) {
        _trackRequestCompletion(
          requestId!,
          url,
          'GET',
          stopwatch.elapsedMilliseconds,
          response.statusCode ?? 200,
        );
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (trackPerformance && requestId != null) {
        _requestTracker.failRequest(requestId, e);
        _trackRequestError(url, 'GET', stopwatch.elapsedMilliseconds, e);
      }
      
      // Clean up partially downloaded file if needed
      if (deleteOnError && File(savePath).existsSync()) {
        await File(savePath).delete();
      }
      
      rethrow;
    }
  }
  
  /// Get API performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{
      'endpoints': <String, Map<String, dynamic>>{},
    };
    
    _endpointCallCounts.forEach((endpoint, count) {
      final responseTimes = _responseTimes[endpoint] ?? [];
      
      // Calculate metrics
      final avgTime = responseTimes.isNotEmpty 
          ? responseTimes.reduce((a, b) => a + b) / responseTimes.length 
          : 0;
      
      final maxTime = responseTimes.isNotEmpty 
          ? responseTimes.reduce((a, b) => a > b ? a : b) 
          : 0;
      
      final minTime = responseTimes.isNotEmpty 
          ? responseTimes.reduce((a, b) => a < b ? a : b) 
          : 0;
      
      metrics['endpoints'][endpoint] = {
        'callCount': count,
        'averageResponseTime': avgTime,
        'maxResponseTime': maxTime,
        'minResponseTime': minTime,
      };
    });
    
    // Add overall stats from ApiRequestTracker
    final stats = _requestTracker.getStats();
    metrics['overall'] = {
      'totalRequests': stats.totalRequests,
      'successfulRequests': stats.successfulRequests,
      'failedRequests': stats.failedRequests,
      'averageResponseTime': stats.averageResponseTime,
      'successRate': stats.successRate,
    };
    
    return metrics;
  }
  
  /// Clear all cached API responses
  Future<void> clearCache() async {
    return _cacheManager.clear();
  }
  
  /// Clear cache for a specific group of endpoints
  Future<void> clearCacheForEndpoint(String endpointPrefix) async {
    return _cacheManager.clearGroup(endpointPrefix);
  }
  
  /// Internal method to execute a request with all options
  Future<T> _executeRequest<T>(
    String method,
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
    CacheStrategy cacheStrategy = CacheStrategy.networkOnly,
    Duration cacheDuration = const Duration(minutes: 5),
    bool trackPerformance = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    // Check if we should use cache
    if (method == 'GET' && cacheStrategy != CacheStrategy.networkOnly) {
      // Generate cache key
      final cacheKey = _generateCacheKey(method, endpoint, queryParams);
      
      // Check for cached data first if needed
      if (cacheStrategy == CacheStrategy.cacheFirst || 
          cacheStrategy == CacheStrategy.cacheOnly || 
          cacheStrategy == CacheStrategy.staleWhileRevalidate) {
        final cachedData = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
        
        if (cachedData != null) {
          _logger.debug('ApiClient: Using cached data for $method $endpoint');
          
          // Return cached data for cache-first, cache-only, or stale-while-revalidate
          if (cacheStrategy == CacheStrategy.cacheOnly) {
            // For cache-only, just return the cached data
            return cachedData['data'] as T;
          } else if (cacheStrategy == CacheStrategy.staleWhileRevalidate) {
            // For stale-while-revalidate, fetch new data in the background
            _refreshCacheInBackground(
              method, 
              endpoint, 
              data, 
              queryParams, 
              headers, 
              requiresAuth, 
              cacheKey, 
              cacheDuration,
            );
            
            return cachedData['data'] as T;
          } else {
            // For cache-first, return the cached data
            return cachedData['data'] as T;
          }
        }
        
        // If we're cache-only but there's no cache, fail
        if (cacheStrategy == CacheStrategy.cacheOnly) {
          throw Exception('No cached data available for $method $endpoint');
        }
      }
    }
    
    // No cached data or we're doing a network request, so proceed with network
    final requestId = trackPerformance 
        ? _requestTracker.startRequest(method, endpoint, params: queryParams)
        : null;
    
    final stopwatch = Stopwatch()..start();
    final options = Options(extra: {
      'useCache': cacheStrategy != CacheStrategy.networkOnly,
      'cacheDuration': cacheDuration,
      'retry': true,
      'retryCount': _maxRetries,
      'retryDelay': const Duration(milliseconds: 1000),
    });
    
    try {
      Response response;
      
      switch (method) {
        case 'GET':
          response = await _httpClient.get(
            endpoint,
            queryParameters: queryParams,
            headers: headers,
            options: options,
            requiresAuth: requiresAuth,
            cancelToken: cancelToken,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case 'POST':
          response = await _httpClient.post(
            endpoint,
            data: data,
            queryParameters: queryParams,
            headers: headers,
            options: options,
            requiresAuth: requiresAuth,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            endpoint,
            data: data,
            queryParameters: queryParams,
            headers: headers,
            options: options,
            requiresAuth: requiresAuth,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(
            endpoint,
            data: data,
            queryParameters: queryParams,
            headers: headers,
            options: options,
            requiresAuth: requiresAuth,
            cancelToken: cancelToken,
          );
          break;
        case 'PATCH':
          response = await _httpClient.patch(
            endpoint,
            data: data,
            queryParameters: queryParams,
            headers: headers,
            options: options,
            requiresAuth: requiresAuth,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
      
      if (trackPerformance) {
        _trackRequestCompletion(
          requestId!,
          endpoint,
          method,
          stopwatch.elapsedMilliseconds,
          response.statusCode ?? 200,
        );
      }
      
      // Handle network-first cache strategy
      if (method == 'GET' && 
          cacheStrategy == CacheStrategy.networkFirst && 
          response.statusCode == 200) {
        final cacheKey = _generateCacheKey(method, endpoint, queryParams);
        await _cacheManager.put(
          cacheKey, 
          {'data': response.data, 'headers': response.headers.map}, 
          cacheDuration,
        );
      }
      
      return _processResponse<T>(response);
    } catch (e) {
      if (trackPerformance && requestId != null) {
        _requestTracker.failRequest(requestId, e);
        _trackRequestError(endpoint, method, stopwatch.elapsedMilliseconds, e);
      }
      
      // If network-first strategy fails, try to get from cache
      if (method == 'GET' && cacheStrategy == CacheStrategy.networkFirst) {
        final cacheKey = _generateCacheKey(method, endpoint, queryParams);
        final cachedData = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
        
        if (cachedData != null) {
          _logger.debug('ApiClient: Network request failed, using cached data for $method $endpoint');
          return cachedData['data'] as T;
        }
      }
      
      rethrow;
    }
  }
  
  /// Process response data
  T _processResponse<T>(Response response) {
    if (response.data == null) {
      if (T == bool) {
        return true as T;
      }
      return null as T;
    }
    
    return response.data as T;
  }
  
  /// Track request completion for performance metrics
  void _trackRequestCompletion(
    String requestId,
    String endpoint,
    String method,
    int elapsedTime,
    int statusCode,
  ) {
    // Update request tracker
    _requestTracker.completeRequest(requestId, statusCode);
    
    // Only track performance metrics if enabled
    if (!_isPerformanceLoggingEnabled) return;
    
    // Update local performance metrics
    final key = '$method $endpoint';
    _endpointCallCounts[key] = (_endpointCallCounts[key] ?? 0) + 1;
    
    _responseTimes[key] = _responseTimes[key] ?? [];
    _responseTimes[key]!.add(elapsedTime);
    
    // Limit the size of response time lists
    if (_responseTimes[key]!.length > 100) {
      _responseTimes[key]!.removeAt(0);
    }
    
    // Log slow requests
    if (elapsedTime > 1000) {
      _logger.warn('ApiClient: Slow request [$method] $endpoint took ${elapsedTime}ms');
      
      // Track slow API calls in analytics
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'slow_api_call',
        parameters: {
          'endpoint': endpoint,
          'method': method,
          'duration_ms': elapsedTime,
          'is_slow': true,
        },
      );
    }
  }
  
  /// Track request errors for performance metrics
  void _trackRequestError(
    String endpoint,
    String method,
    int elapsedTime,
    dynamic error,
  ) {
    if (!_isPerformanceLoggingEnabled) return;
    
    // Log error details
    _logger.error('ApiClient: Request [$method] $endpoint failed after ${elapsedTime}ms', error);
    
    // Track API errors in analytics
    _analytics.logError(
      errorType: 'api_error',
      errorMessage: error.toString(),
      errorDetails: '$method $endpoint (${elapsedTime}ms)',
      fatal: false,
    );
  }
  
  /// Refresh cache in background for stale-while-revalidate strategy
  Future<void> _refreshCacheInBackground(
    String method,
    String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool requiresAuth,
    String cacheKey,
    Duration cacheDuration,
  ) async {
    try {
      Response response;
      
      switch (method) {
        case 'GET':
          response = await _httpClient.get(
            endpoint,
            queryParameters: queryParams,
            headers: headers,
            requiresAuth: requiresAuth,
          );
          break;
        default:
          return; // Only support GET for background refresh
      }
      
      if (response.statusCode == 200) {
        await _cacheManager.put(
          cacheKey, 
          {'data': response.data, 'headers': response.headers.map}, 
          cacheDuration,
        );
        _logger.debug('ApiClient: Background refresh successful for $method $endpoint');
      }
    } catch (e) {
      _logger.warn('ApiClient: Background refresh failed for $method $endpoint: $e');
    }
  }
  
  /// Generate a cache key for the request
  String _generateCacheKey(
    String method,
    String endpoint,
    Map<String, dynamic>? queryParams,
  ) {
    final buffer = StringBuffer('${method}_$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      // Sort the parameters by key for consistency
      final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      
      buffer.write('_params:');
      sortedParams.forEach((key, value) {
        buffer.write('_$key=$value');
      });
    }
    
    return buffer.toString();
  }
  
  /// Guess the MIME type based on file name
  String? _guessMimeType(String fileName) {
    return lookupMimeType(fileName);
  }
} 