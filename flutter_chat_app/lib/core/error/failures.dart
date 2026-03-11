/// **COMPREHENSIVE FAILURE HIERARCHY - ERROR HANDLING STANDARDIZATION**
///
/// Enterprise-grade failure types following clean architecture principles:
/// - Specific failure types for different error categories
/// - Localized user-friendly messages via ErrorMessages provider (i18n ready)
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

  /// User-friendly localized message
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
/// Lỗi từ server (5xx errors, server unavailable, GraphQL business errors, etc.)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    // Priority 1: Backend API message (already user-friendly Vietnamese)
    final apiMessage = details?['apiMessage'] as String?;
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }

    // Priority 2: Map by error code
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
    // Priority 1: Backend API message (already user-friendly Vietnamese)
    final apiMessage = details?['apiMessage'] as String?;
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }

    // Priority 2: Map by error code
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
    // Priority 1: Backend API message
    final apiMessage = details?['apiMessage'] as String?;
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }

    // Priority 2: Map by error code
    switch (code) {
      case 'access_denied':
        return ErrorMessages.getMessage('access_denied');
      case 'insufficient_permissions':
        return ErrorMessages.getMessage('insufficient_permissions');
      case 'admin_required':
        return ErrorMessages.getMessage('admin_required');
      default:
        return ErrorMessages.getMessage('permission_denied');
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
    // Cache failures are local — no backend API message needed
    switch (code) {
      case 'storage_full':
        return ErrorMessages.getMessage('storage_full');
      case 'corruption':
        return ErrorMessages.getMessage('cache_corruption');
      case 'permission_denied':
        return ErrorMessages.getMessage('storage_permission_denied');
      default:
        return ErrorMessages.getMessage('cache_error');
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
    // Priority 1: Backend API message
    final apiMessage = details?['apiMessage'] as String?;
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }

    // Priority 2: Field-level errors (from local validation)
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return fieldErrors!.values.first;
    }

    // Priority 3: Map by error code
    switch (code) {
      case 'invalid_email':
        return ErrorMessages.getMessage('invalid_email');
      case 'password_too_short':
        return ErrorMessages.getMessage('password_too_short');
      case 'required_field':
        return ErrorMessages.getMessage('required_field');
      case 'invalid_phone':
        return ErrorMessages.getMessage('invalid_phone');
      default:
        return ErrorMessages.getMessage('validation_failed');
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
        return ErrorMessages.getMessage('request_timeout');
      case 'connection_timeout':
        return ErrorMessages.getMessage('connection_timeout');
      case 'operation_timeout':
        return ErrorMessages.getMessage('operation_timeout');
      default:
        return ErrorMessages.getMessage('timeout_default');
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
        return ErrorMessages.getMessage('realtime_connection_lost');
      case 'reconnect_failed':
        return ErrorMessages.getMessage('realtime_reconnect_failed');
      case 'message_failed':
        return ErrorMessages.getMessage('realtime_message_failed');
      default:
        return ErrorMessages.getMessage('realtime_error');
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
        return ErrorMessages.getMessage('upload_file_too_large');
      case 'invalid_format':
        return ErrorMessages.getMessage('upload_invalid_format');
      case 'upload_failed':
        return ErrorMessages.getMessage('upload_failed');
      case 'storage_full':
        return ErrorMessages.getMessage('upload_storage_full');
      default:
        return ErrorMessages.getMessage('upload_error');
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
        return ErrorMessages.getMessage('download_file_not_found');
      case 'download_failed':
        return ErrorMessages.getMessage('download_failed');
      case 'storage_full':
        return ErrorMessages.getMessage('download_storage_full');
      default:
        return ErrorMessages.getMessage('download_error');
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
        return ErrorMessages.getMessage('version_conflict');
      case 'concurrent_modification':
        return ErrorMessages.getMessage('concurrent_modification');
      case 'duplicate_entry':
        return ErrorMessages.getMessage('duplicate_entry');
      default:
        return ErrorMessages.getMessage('conflict_error');
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
    return ErrorMessages.getMessage('unknown_error');
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
    return ErrorMessages.getMessage('unexpected_error');
  }

  @override
  String get category => 'unexpected';

  @override
  bool get isRecoverable => false;
}

// **UPDATE FAILURES**

/// **Update Failure**
/// Lỗi liên quan đến kiểm tra, tải, xác minh hoặc cài đặt bản cập nhật
class UpdateFailure extends Failure {
  const UpdateFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'check_failed':
        return ErrorMessages.getMessage('update_check_failed');
      case 'download_failed':
        return ErrorMessages.getMessage('update_download_failed');
      case 'verification_failed':
        return ErrorMessages.getMessage('update_verification_failed');
      case 'install_failed':
        return ErrorMessages.getMessage('update_install_failed');
      case 'cancelled':
        return ErrorMessages.getMessage('update_cancelled');
      case 'no_asset':
        return ErrorMessages.getMessage('update_no_asset');
      default:
        return ErrorMessages.getMessage('update_error');
    }
  }

  @override
  String get category => 'update';

  @override
  bool get isRecoverable => code != 'verification_failed';
}