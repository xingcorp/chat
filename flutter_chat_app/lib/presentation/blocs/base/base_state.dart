import 'package:equatable/equatable.dart';

/// Enum cho các loại lỗi
enum ErrorType {
  general,
  network,
  timeout,
  authentication,
  authorization,
  validation,
  server,
  notFound,
}

/// Giao diện cho các state cần được lưu trữ (persistence)
abstract class Persistable {
  Map<String, dynamic> toJson();
  static Persistable fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must override fromJson');
  }
}

/// Base state cho tất cả các trạng thái trong BLoC
abstract class BaseState extends Equatable {
  const BaseState();
  
  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo ban đầu
class BaseInitial extends BaseState {
  const BaseInitial();
  
  @override
  List<Object?> get props => [];
  
  @override
  String toString() => 'BaseInitial';
}

/// Trạng thái đang tải
class BaseLoading extends BaseState {
  final String? message;
  final double? progress; // 0.0 đến 1.0
  
  const BaseLoading({this.message, this.progress});
  
  @override
  List<Object?> get props => [message, progress];
  
  @override
  String toString() => 'BaseLoading{message: $message, progress: $progress}';
}

/// Trạng thái thành công
class BaseSuccess<T> extends BaseState {
  final T? data;
  final String? message;
  
  const BaseSuccess({this.data, this.message});
  
  @override
  List<Object?> get props => [data, message];
  
  @override
  String toString() => 'BaseSuccess{data: $data, message: $message}';
}

/// Trạng thái lỗi
class BaseError extends BaseState {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final ErrorType type;
  final bool shouldRetry;
  final Duration retryAfter;
  
  const BaseError(
    this.message, 
    {
      this.error,
      this.stackTrace,
      this.type = ErrorType.general,
      this.shouldRetry = false,
      this.retryAfter = const Duration(seconds: 5),
    }
  );
  
  @override
  List<Object?> get props => [message, error, type, shouldRetry, retryAfter];
  
  @override
  String toString() => 'BaseError{message: $message, type: $type, shouldRetry: $shouldRetry}';
}

/// Trạng thái trống (không có dữ liệu)
class BaseEmpty extends BaseState {
  final String? message;
  
  const BaseEmpty({this.message});
  
  @override
  List<Object?> get props => [message];
  
  @override
  String toString() => 'BaseEmpty{message: $message}';
} 