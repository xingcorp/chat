import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:uuid/uuid.dart';

import '../auth/token_manager.dart';
import '../cache/network_response_cache.dart';
import '../connectivity/connectivity_service.dart';
import '../error/network_exceptions.dart';
import 'http_client_interface.dart';

/// Implementation của IHttpClient sử dụng Dio
@LazySingleton(as: IHttpClient)
class DioHttpClient implements IHttpClient {
  /// Dio instance cho các request thông thường
  final Dio _dio;
  
  /// Dio instance riêng cho upload file
  final Dio _uploadDio;
  
  /// Cache manager cho API response
  final NetworkResponseCache _cacheManager;
  
  /// Token manager
  final TokenManager _tokenManager;
  
  /// Connectivity service
  final IConnectivityService _connectivityService;
  
  /// Base URL
  final String _baseUrl;
  
  /// Constructor
  @factoryMethod
  DioHttpClient(
    this._cacheManager,
    this._tokenManager,
    this._connectivityService,
    @Named('apiBaseUrl') this._baseUrl,
  ) : _dio = Dio(),
      _uploadDio = Dio() {
    _configureDio(_dio);
    _configureDio(_uploadDio, isUpload: true);
  }
  
  /// Cấu hình cho Dio client
  void _configureDio(Dio dio, {bool isUpload = false}) {
    // Thiết lập base options
    dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(milliseconds: isUpload ? 60000 : 30000),
      receiveTimeout: const Duration(milliseconds: isUpload ? 60000 : 30000),
      sendTimeout: const Duration(milliseconds: isUpload ? 60000 : 30000),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    );
    
    // Thêm interceptors
    if (!isUpload) {
      // Add pretty logger (chỉ khi không phải upload)
      if (kDebugMode) {
        dio.interceptors.add(
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseHeader: true,
            responseBody: true,
            compact: false,
          ),
        );
      }
    }
    
    // Thêm retry interceptor
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: debugPrint,
        retries: 2,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
        ],
        retryableExtraStatuses: {401},
        retryEvaluator: (error, attempt) {
          // Retry khi lỗi timeout hoặc không có kết nối
          return error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.connectionError ||
                (error.response?.statusCode == 401 && attempt == 1);
        },
      ),
    );
    
    // Thêm auth interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Thêm request ID
          options.headers['X-Request-ID'] = const Uuid().v4();
          
          // Thêm token vào header nếu có
          final token = await _tokenManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          handler.next(options);
        },
        onError: (error, handler) async {
          // Refresh token nếu token hết hạn (401)
          if (error.response?.statusCode == 401) {
            try {
              final refreshed = await _tokenManager.refreshToken();
              if (refreshed) {
                // Lấy token mới
                final newToken = await _tokenManager.getAccessToken();
                
                // Thử lại request với token mới
                if (newToken != null && newToken.isNotEmpty) {
                  error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  
                  // Thực hiện lại request
                  final response = await dio.fetch(error.requestOptions);
                  
                  // Trả về kết quả
                  handler.resolve(response);
                  return;
                }
              }
            } catch (e) {
              debugPrint('Failed to refresh token: $e');
            }
          }
          
          handler.next(error);
        },
      ),
    );
  }
  
  /// Kiểm tra kết nối mạng
  Future<bool> _checkConnectivity() async {
    return await _connectivityService.isConnected();
  }
  
  /// Xử lý lỗi từ Dio
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      return NetworkExceptionFactory.fromDioException(error);
    }
    
    return UnexpectedException(error: error);
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
      
      // Xử lý cache
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
              options: Options(headers: headers),
              cancelToken: cancelToken,
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
                options: Options(headers: headers),
                cancelToken: cancelToken,
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
              options: Options(headers: headers),
              cancelToken: cancelToken,
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
              options: Options(headers: headers),
              cancelToken: cancelToken,
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
            
            throw ApiException(message: 'Cache not found');
            
          case CacheStrategy.networkOnly:
            // Chỉ lấy từ network
            final networkResponse = await _dio.get<T>(
              endpoint,
              queryParameters: queryParams,
              options: Options(headers: headers),
              cancelToken: cancelToken,
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
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
        
        return response.data as T;
      }
    } catch (e) {
      throw _handleError(e);
    }
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
        options: Options(headers: headers),
        cancelToken: cancelToken,
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
        options: Options(headers: headers),
        cancelToken: cancelToken,
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
        options: Options(headers: headers),
        cancelToken: cancelToken,
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
        options: Options(headers: headers),
        cancelToken: cancelToken,
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
      
      // Tải file
      await _dio.download(
        url,
        savePath,
        queryParameters: queryParams,
        options: Options(headers: headers),
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
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
      final formData = FormData();
      
      // Thêm fields
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      // Thêm files
      for (final file in files) {
        if (file.bytes != null) {
          // Upload từ bytes
          formData.files.add(
            MapEntry(
              file.fieldName,
              MultipartFile.fromBytes(
                file.bytes!,
                filename: file.fileName,
                contentType: file.contentType,
              ),
            ),
          );
        } else if (file.filePath != null) {
          // Upload từ file path
          formData.files.add(
            MapEntry(
              file.fieldName,
              await MultipartFile.fromFile(
                file.filePath!,
                filename: file.fileName,
                contentType: file.contentType,
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
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
    _uploadDio.options.baseUrl = baseUrl;
  }
  
  @override
  void setToken(String token) {
    _tokenManager.setAccessToken(token, null);
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
  
  @override
  void dispose() {
    _dio.close();
    _uploadDio.close();
  }
} 