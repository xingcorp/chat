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
    required super.message,
    super.code,
  });
}

/// Lỗi kết nối
class ConnectionFailure extends Failure {
  const ConnectionFailure({
    required super.message,
    super.code,
  });
}

/// Lỗi cache
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

/// Lỗi xác thực
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code,
  });
}

/// Lỗi không xác định
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message) : super(message: message);
}

/// Lỗi truy cập không được phép
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
  });
}

/// Lỗi nhập liệu
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.code,
  });

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Lỗi timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.code,
  });
}

/// Lỗi realtime
class RealtimeFailure extends Failure {
  const RealtimeFailure({
    required super.message,
    super.code,
  });
}

/// Lỗi upload file
class UploadFailure extends Failure {
  const UploadFailure({
    required super.message,
    super.code,
  });
}

/// Lỗi download file
class DownloadFailure extends Failure {
  const DownloadFailure({
    required super.message,
    super.code,
  });
}