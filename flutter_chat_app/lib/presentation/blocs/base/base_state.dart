import 'package:equatable/equatable.dart';

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
/// Có thể tùy chọn chứa một thông điệp loading.
class BaseLoading extends BaseState {
  final String? message;
  const BaseLoading({this.message});

  @override
  List<Object?> get props => [message];
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

  const BaseError(this.message, {this.error, this.stackTrace});

  @override
  List<Object?> get props => [message, error, stackTrace];

  @override
  String toString() => 'BaseError { message: $message, error: $error }';
}

/// Trạng thái tùy chọn cho các trường hợp không có dữ liệu (ví dụ: danh sách trống).
class BaseEmpty extends BaseState {
    final String? message; // Optional message explaining why it's empty
    const BaseEmpty({this.message});

     @override
    List<Object?> get props => [message];
} 