/// **COMPREHENSIVE FAILURE HIERARCHY - ERROR HANDLING STANDARDIZATION**
///
/// Enterprise-grade failure types following clean architecture principles:
/// - Specific failure types for different error categories
/// - Vietnamese user-friendly messages
/// - Technical English messages for developers
/// - Proper error codes for debugging
///
/// **Architecture:** Clean Architecture + SOLID principles + Either<Failure, T>

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/localization/error_message_provider.dart';

/// **Base Failure Class**
///
/// Abstract base class for all failures in the application
/// Following clean architecture error handling patterns
abstract class Failure extends Equatable {
  /// Technical message for developers (English)
  final String message;

  /// Error code for debugging and tracking
  final String? code;

  /// Additional context data
  final Map<String, dynamic>? details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  /// User-friendly message in Vietnamese
  String get userMessage;

  /// Error category for analytics
  String get category;

  /// Whether this error is recoverable
  bool get isRecoverable => false;

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => '$runtimeType($code): $message';
}

// **NETWORK FAILURES**

/// **Server Failure**
/// Lỗi từ server (5xx errors, server unavailable, etc.)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case '500':
        return ErrorMessages.getMessage('server_error');
      case '502':
        return ErrorMessages.getMessage('server_unavailable');
      case '503':
        return ErrorMessages.getMessage('server_maintenance');
      case 'overload':
        return ErrorMessages.getMessage('server_overload');
      default:
        return ErrorMessages.getMessage('server_error');
    }
  }

  @override
  String get category => 'server';

  @override
  bool get isRecoverable => true;
}

/// **Connection Failure**
/// Lỗi kết nối mạng (no internet, timeout, etc.)
class ConnectionFailure extends Failure {
  const ConnectionFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'timeout':
        return ErrorMessages.getMessage('connection_timeout');
      case 'no_internet':
        return ErrorMessages.getMessage('no_internet');
      case 'dns_error':
        return ErrorMessages.getMessage('connection_failed');
      case 'lost':
        return ErrorMessages.getMessage('connection_lost');
      case 'weak':
        return ErrorMessages.getMessage('weak_connection');
      default:
        return ErrorMessages.getMessage('connection_failed');
    }
  }

  @override
  String get category => 'network';

  @override
  bool get isRecoverable => true;
}

/// **Network Failure**
/// General network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage => ErrorMessages.getMessage('connection_failed');

  @override
  String get category => 'network';

  @override
  bool get isRecoverable => true;
}

// **AUTHENTICATION & AUTHORIZATION FAILURES**

/// **Authentication Failure**
/// Lỗi xác thực (login failed, invalid credentials, etc.)
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'invalid_credentials':
        return ErrorMessages.getMessage('invalid_credentials');
      case 'account_locked':
        return ErrorMessages.getMessage('account_locked');
      case 'token_expired':
        return ErrorMessages.getMessage('token_expired');
      case 'account_not_verified':
        return ErrorMessages.getMessage('account_not_verified');
      case 'login_failed':
        return ErrorMessages.getMessage('login_failed');
      case 'account_disabled':
        return ErrorMessages.getMessage('account_disabled');
      default:
        return ErrorMessages.getMessage('login_failed');
    }
  }

  @override
  String get category => 'authentication';

  @override
  bool get isRecoverable => true;
}

/// **Permission Failure**
/// Lỗi phân quyền (access denied, insufficient permissions, etc.)
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'access_denied':
        return 'Bạn không có quyền truy cập tính năng này.';
      case 'insufficient_permissions':
        return 'Quyền hạn không đủ để thực hiện thao tác này.';
      case 'admin_required':
        return 'Chỉ quản trị viên mới có thể thực hiện thao tác này.';
      default:
        return 'Bạn không có quyền thực hiện thao tác này.';
    }
  }

  @override
  String get category => 'authorization';

  @override
  bool get isRecoverable => false;
}

// **DATA & VALIDATION FAILURES**

/// **Cache Failure**
/// Lỗi cache/local storage (read/write failed, corruption, etc.)
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'storage_full':
        return 'Bộ nhớ thiết bị đã đầy. Vui lòng giải phóng dung lượng.';
      case 'corruption':
        return 'Dữ liệu bị lỗi. Ứng dụng sẽ tải lại dữ liệu.';
      case 'permission_denied':
        return 'Không có quyền truy cập bộ nhớ thiết bị.';
      default:
        return 'Có lỗi với dữ liệu cục bộ. Dữ liệu có thể không được cập nhật.';
    }
  }

  @override
  String get category => 'cache';

  @override
  bool get isRecoverable => true;
}

/// **Validation Failure**
/// Lỗi validation dữ liệu đầu vào
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return fieldErrors!.values.first;
    }

    switch (code) {
      case 'invalid_email':
        return 'Email không hợp lệ. Vui lòng nhập đúng định dạng.';
      case 'password_too_short':
        return 'Mật khẩu phải có ít nhất 8 ký tự.';
      case 'required_field':
        return 'Vui lòng điền đầy đủ thông tin bắt buộc.';
      case 'invalid_phone':
        return 'Số điện thoại không hợp lệ.';
      default:
        return 'Thông tin không hợp lệ. Vui lòng kiểm tra lại.';
    }
  }

  @override
  String get category => 'validation';

  @override
  bool get isRecoverable => true;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

// **OPERATION FAILURES**

/// **Timeout Failure**
/// Lỗi timeout (request timeout, operation timeout, etc.)
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'request_timeout':
        return 'Yêu cầu bị timeout. Vui lòng thử lại.';
      case 'connection_timeout':
        return 'Kết nối bị timeout. Vui lòng kiểm tra mạng.';
      case 'operation_timeout':
        return 'Thao tác mất quá nhiều thời gian. Vui lòng thử lại.';
      default:
        return 'Thao tác bị timeout. Vui lòng thử lại sau.';
    }
  }

  @override
  String get category => 'timeout';

  @override
  bool get isRecoverable => true;
}

/// **Realtime Failure**
/// Lỗi real-time communication (WebSocket, SSE, etc.)
class RealtimeFailure extends Failure {
  const RealtimeFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'connection_lost':
        return 'Mất kết nối real-time. Đang thử kết nối lại...';
      case 'reconnect_failed':
        return 'Không thể kết nối lại. Vui lòng kiểm tra mạng.';
      case 'message_failed':
        return 'Không thể gửi tin nhắn. Vui lòng thử lại.';
      default:
        return 'Có lỗi với kết nối real-time. Vui lòng thử lại.';
    }
  }

  @override
  String get category => 'realtime';

  @override
  bool get isRecoverable => true;
}

/// **Upload Failure**
/// Lỗi upload file/media
class UploadFailure extends Failure {
  const UploadFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'file_too_large':
        return 'File quá lớn. Vui lòng chọn file nhỏ hơn.';
      case 'invalid_format':
        return 'Định dạng file không được hỗ trợ.';
      case 'upload_failed':
        return 'Upload thất bại. Vui lòng thử lại.';
      case 'storage_full':
        return 'Bộ nhớ server đã đầy. Vui lòng thử lại sau.';
      default:
        return 'Không thể upload file. Vui lòng thử lại.';
    }
  }

  @override
  String get category => 'upload';

  @override
  bool get isRecoverable => true;
}

/// **Download Failure**
/// Lỗi download file/media
class DownloadFailure extends Failure {
  const DownloadFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'file_not_found':
        return 'File không tồn tại hoặc đã bị xóa.';
      case 'download_failed':
        return 'Download thất bại. Vui lòng thử lại.';
      case 'storage_full':
        return 'Bộ nhớ thiết bị đã đầy. Vui lòng giải phóng dung lượng.';
      default:
        return 'Không thể download file. Vui lòng thử lại.';
    }
  }

  @override
  String get category => 'download';

  @override
  bool get isRecoverable => true;
}

// **BUSINESS LOGIC FAILURES**

/// **Conflict Failure**
/// Lỗi xung đột dữ liệu (concurrent modification, version mismatch, etc.)
class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'version_conflict':
        return 'Dữ liệu đã được cập nhật bởi người khác. Vui lòng tải lại.';
      case 'concurrent_modification':
        return 'Có người khác đang chỉnh sửa. Vui lòng thử lại sau.';
      case 'duplicate_entry':
        return 'Dữ liệu đã tồn tại. Vui lòng kiểm tra lại.';
      default:
        return 'Có xung đột dữ liệu. Vui lòng tải lại và thử lại.';
    }
  }

  @override
  String get category => 'conflict';

  @override
  bool get isRecoverable => true;
}

// **GENERIC FAILURES**

/// **Unknown Failure**
/// Lỗi không xác định hoặc không được phân loại
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    return 'Có lỗi không xác định xảy ra. Vui lòng thử lại sau.';
  }

  @override
  String get category => 'unknown';

  @override
  bool get isRecoverable => true;
}

/// **Unexpected Failure**
/// Lỗi không mong đợi (exceptions, crashes, etc.)
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    return 'Có lỗi không mong đợi xảy ra. Vui lòng khởi động lại ứng dụng.';
  }

  @override
  String get category => 'unexpected';

  @override
  bool get isRecoverable => false;
}