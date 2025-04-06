import 'package:equatable/equatable.dart';

/// Loại lỗi để phân loại và xử lý các lỗi khác nhau
enum ErrorType {
  general,
  network,
  authentication,
  authorization,
  validation,
  server,
  timeout,
  notFound,
  unknown
}

/// Giao diện cho các state cần được lưu trữ (persistence)
abstract class Persistable {
  Map<String, dynamic> toJson();
  static Persistable fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must override fromJson');
  }
}

/// Lớp cơ sở trừu tượng cho tất cả các trạng thái BLoC.
/// Sử dụng Equatable để hỗ trợ so sánh giá trị.
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo ban đầu.
class BaseInitial extends BaseState {
  const BaseInitial();
}

/// Trạng thái đang tải dữ liệu hoặc thực hiện một hành động.
/// Có thể tùy chọn chứa một thông điệp loading và tiến độ.
class BaseLoading extends BaseState {
  final String? message;
  final double? progress; // Giá trị từ 0.0 đến 1.0
  
  const BaseLoading({this.message, this.progress});

  @override
  List<Object?> get props => [message, progress];
}

/// Trạng thái thành công chung.
/// Các BLoC cụ thể thường sẽ muốn định nghĩa các trạng thái thành công riêng
/// (ví dụ: `UserProfileLoaded extends BaseState`) thay vì dùng trạng thái chung này,
/// để chứa dữ liệu cụ thể đã tải thành công.
/// Tuy nhiên, nó có thể hữu ích trong một số trường hợp đơn giản.
class BaseSuccess extends BaseState {
  const BaseSuccess();
}

/// Trạng thái lỗi.
/// Chứa thông điệp lỗi và có thể cả đối tượng lỗi gốc và stack trace.
class BaseError extends BaseState {
  final String message;
  final dynamic error; // Có thể là Exception, DioError, etc.
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
  List<Object?> get props => [message, error, stackTrace, type, shouldRetry, retryAfter];

  @override
  String toString() => 'BaseError { message: $message, type: $type, error: $error }';
}

/// Trạng thái tùy chọn cho các trường hợp không có dữ liệu (ví dụ: danh sách trống).
class BaseEmpty extends BaseState {
    final String? message; // Optional message explaining why it's empty
    final bool isFirstLoad; // Phân biệt giữa lần đầu không có dữ liệu và đã xóa hết dữ liệu
    
    const BaseEmpty({this.message, this.isFirstLoad = false});

    @override
    List<Object?> get props => [message, isFirstLoad];
} 