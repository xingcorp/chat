import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

import 'media_type.dart';

/// Enum định nghĩa các strategy khi lấy dữ liệu từ cache
enum CacheStrategy {
  /// Lấy từ cache trước, nếu không có thì lấy từ network
  cacheFirst,
  
  /// Lấy từ network trước, nếu lỗi thì lấy từ cache
  networkFirst,
  
  /// Trả về cache ngay lập tức và cập nhật cache ngầm với data mới từ network
  staleWhileRevalidate,
  
  /// Chỉ lấy từ cache, không gọi network
  cacheOnly,
  
  /// Chỉ lấy từ network, nhưng vẫn cache lại kết quả
  networkOnly,
}

/// Class chứa thông tin cho việc cấu hình retry
class RetryConfig {
  /// Số lần retry tối đa
  final int maxRetries;
  
  /// Danh sách thời gian delay giữa các lần retry (ms)
  final List<int> retryDelays;
  
  /// Có sử dụng exponential backoff không
  final bool useExponentialBackoff;
  
  /// Hệ số cho exponential backoff
  final double exponentialBackoffFactor;
  
  /// Constructor
  RetryConfig({
    this.maxRetries = 3,
    this.retryDelays = const [1000, 2000, 5000],
    this.useExponentialBackoff = true,
    this.exponentialBackoffFactor = 1.5,
  });
  
  /// Tính thời gian delay cho lần retry thứ n
  int getDelayForRetry(int attempt) {
    if (attempt <= 0 || attempt > maxRetries) {
      return 0;
    }
    
    if (attempt <= retryDelays.length) {
      return retryDelays[attempt - 1];
    }
    
    if (useExponentialBackoff) {
      final lastDelay = retryDelays.last;
      return (lastDelay * exponentialBackoffFactor * (attempt - retryDelays.length)).toInt();
    }
    
    return retryDelays.last;
  }
}

/// Class chứa thông tin cho request options
class RequestOptions {
  /// Timeout cho connection (ms)
  final int? connectTimeout;
  
  /// Timeout cho nhận data (ms)
  final int? receiveTimeout;
  
  /// Timeout cho gửi data (ms)
  final int? sendTimeout;
  
  /// Các headers bổ sung
  final Map<String, String>? headers;
  
  /// Constructor
  RequestOptions({
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.headers,
  });
}

/// Class chứa thông tin cho việc upload file
class FileUploadInfo {
  /// Tên field trong form
  final String fieldName;
  
  /// Bytes của file
  final Uint8List? bytes;
  
  /// Đường dẫn đến file
  final String? filePath;
  
  /// Tên file
  final String? fileName;
  
  /// Content type của file
  final MediaType? contentType;
  
  /// Constructor từ bytes
  FileUploadInfo.fromBytes({
    required this.fieldName,
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
  }) : bytes = bytes,
       filePath = null,
       fileName = fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
       contentType = mimeType != null 
           ? MediaType.parse(mimeType) 
           : null;
  
  /// Constructor từ file path
  FileUploadInfo.fromPath({
    required this.fieldName,
    required String path,
    String? fileName,
    String? mimeType,
  }) : filePath = path,
       bytes = null,
       fileName = fileName ?? path.split('/').last,
       contentType = mimeType != null 
           ? MediaType.parse(mimeType) 
           : lookupMimeType(path) != null 
               ? MediaType.parse(lookupMimeType(path)!) 
               : null;
               
  /// Constructor từ bytes với mimeType từ file extension
  FileUploadInfo.fromBytesWithExtension({
    required this.fieldName,
    required Uint8List bytes,
    required String extension,
    String? fileName,
  }) : bytes = bytes,
       filePath = null,
       fileName = fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}.$extension',
       contentType = lookupMimeType('file.$extension') != null 
           ? MediaType.parse(lookupMimeType('file.$extension')!) 
           : null;
}

/// Interface cho HTTP client
abstract class IHttpClient {
  /// Thực hiện GET request
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
  });
  
  /// Thực hiện POST request
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  });
  
  /// Thực hiện PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  });
  
  /// Thực hiện PATCH request
  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  });
  
  /// Thực hiện DELETE request
  Future<T> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RetryConfig? retryConfig,
    RequestOptions? options,
    String? invalidateCache,
  });
  
  /// Tải file từ url
  Future<String> downloadFile(
    String url, {
    required String savePath,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });
  
  /// Upload file lên server
  Future<T> uploadFile<T>(
    String endpoint, {
    required List<FileUploadInfo> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  });
  
  /// Đặt base URL
  void setBaseUrl(String baseUrl);
  
  /// Đặt token xác thực
  void setToken(String token);
  
  /// Xóa token xác thực
  void clearToken();
  
  /// Thêm interceptor
  void addInterceptor(Interceptor interceptor);
  
  /// Xóa interceptor
  void removeInterceptor(Interceptor interceptor);
  
  /// Giải phóng tài nguyên
  void dispose();
} 