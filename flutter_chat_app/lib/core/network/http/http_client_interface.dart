import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_chat_app/core/network/http/media_type.dart';
import 'package:mime/mime.dart';

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

/// Giao diện chung cho HTTP clients được sử dụng trong ứng dụng
abstract class IHttpClient {
  /// Lấy instance Dio cơ bản nếu cần truy cập trực tiếp
  Dio get dioInstance;
  
  /// Cấu hình client với các thông số cơ bản
  Future<void> configure({
    required String baseUrl,
    Map<String, dynamic>? headers,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
    int sendTimeout = 30000,
  });
  
  /// Thêm interceptor
  void addInterceptor(Interceptor interceptor);
  
  /// Cập nhật token xác thực
  void updateAuthToken(String token);
  
  /// Xóa token xác thực
  void clearAuthToken();
  
  /// Thiết lập các header mặc định
  void setDefaultHeaders(Map<String, dynamic> headers);
  
  /// Thực hiện request HTTP GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Options? options,
    bool requiresAuth = true,
  });
  
  /// Thực hiện request HTTP POST
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
  });
  
  /// Thực hiện request HTTP PUT
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
  });
  
  /// Thực hiện request HTTP DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    bool requiresAuth = true,
  });
  
  /// Thực hiện request HTTP PATCH
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
  });
  
  /// Tải lên một tệp
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
  });
  
  /// Tải lên nhiều tệp
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
  });
  
  /// Tải lên dữ liệu bytes
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
  });
  
  /// Tải xuống tệp
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
  });
}

/// Extension để tạo FormData từ file
extension FileFormDataExtension on File {
  Future<FormData> toFormData({
    required String fieldName,
    String? fileName,
  }) async {
    final _fileName = fileName ?? this.path.split('/').last;
    
    return FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        path,
        filename: _fileName,
      ),
    });
  }
}

/// Extension để tạo FormData từ Uint8List
extension Uint8ListFormDataExtension on Uint8List {
  FormData toFormData({
    required String fieldName,
    required String fileName,
    String? mimeType,
  }) {
    return FormData.fromMap({
      fieldName: MultipartFile.fromBytes(
        this,
        filename: fileName,
      ),
    });
  }
} 