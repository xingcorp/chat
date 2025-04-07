import 'package:equatable/equatable.dart';

/// Base class cho tất cả các lỗi trong ứng dụng
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Lỗi server
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi kết nối
class ConnectionFailure extends Failure {
  const ConnectionFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi cache
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi xác thực
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi không xác định
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message) : super(message: message);
}

/// Lỗi truy cập không được phép
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi nhập liệu
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required String message,
    this.fieldErrors,
    int? code,
  }) : super(message: message, code: code);

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Lỗi timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi realtime
class RealtimeFailure extends Failure {
  const RealtimeFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi upload file
class UploadFailure extends Failure {
  const UploadFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Lỗi download file
class DownloadFailure extends Failure {
  const DownloadFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
} 