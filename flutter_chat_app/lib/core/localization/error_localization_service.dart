/// **ERROR LOCALIZATION SERVICE - COMPREHENSIVE ERROR HANDLING**
///
/// Professional error localization service following enterprise standards:
/// - Context-aware error message formatting
/// - Recovery guidance generation
/// - Error analytics integration
/// - Multi-language support foundation
///
/// **Architecture:** Clean Architecture + Localization + User Experience

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/localization/error_messages_vi.dart';

/// **ERROR LOCALIZATION SERVICE**
class ErrorLocalizationService {
  // Private constructor for singleton pattern
  ErrorLocalizationService._();
  
  /// Singleton instance
  static final ErrorLocalizationService _instance = ErrorLocalizationService._();
  
  /// Get singleton instance
  static ErrorLocalizationService get instance => _instance;

  /// Current locale (default: Vietnamese)
  String _currentLocale = 'vi';

  /// **Get Current Locale**
  String get currentLocale => _currentLocale;

  /// **Set Locale**
  void setLocale(String locale) {
    _currentLocale = locale;
  }

  /// **Get Localized Error Message**
  /// 
  /// Returns user-friendly error message in current locale
  /// 
  /// Usage:
  /// ```dart
  /// final service = ErrorLocalizationService.instance;
  /// final message = service.getLocalizedErrorMessage(failure);
  /// ```
  String getLocalizedErrorMessage(Failure failure) {
    switch (_currentLocale) {
      case 'vi':
        return _getVietnameseErrorMessage(failure);
      case 'en':
        return _getEnglishErrorMessage(failure);
      default:
        return _getVietnameseErrorMessage(failure); // Default to Vietnamese
    }
  }

  /// **Get Error Message with Context**
  /// 
  /// Returns contextualized error message with additional information
  /// 
  /// Usage:
  /// ```dart
  /// final message = service.getErrorMessageWithContext(
  ///   failure,
  ///   context: {'operation': 'send_message', 'retry_count': 2},
  /// );
  /// ```
  String getErrorMessageWithContext(
    Failure failure, {
    Map<String, dynamic>? context,
  }) {
    final baseMessage = getLocalizedErrorMessage(failure);
    
    if (context == null || context.isEmpty) {
      return baseMessage;
    }

    return _formatMessageWithContext(baseMessage, failure, context);
  }

  /// **Get Recovery Guidance**
  /// 
  /// Returns step-by-step recovery guidance for the error
  /// 
  /// Usage:
  /// ```dart
  /// final guidance = service.getRecoveryGuidance(failure);
  /// ```
  List<String> getRecoveryGuidance(Failure failure) {
    final category = _getErrorCategory(failure);
    
    switch (_currentLocale) {
      case 'vi':
        return ErrorMessagesVi.getRecoveryGuidance(category);
      case 'en':
        return _getEnglishRecoveryGuidance(category);
      default:
        return ErrorMessagesVi.getRecoveryGuidance(category);
    }
  }

  /// **Get Error Summary**
  /// 
  /// Returns comprehensive error summary with message and guidance
  /// 
  /// Usage:
  /// ```dart
  /// final summary = service.getErrorSummary(failure);
  /// ```
  ErrorSummary getErrorSummary(
    Failure failure, {
    Map<String, dynamic>? context,
  }) {
    return ErrorSummary(
      title: _getErrorTitle(failure),
      message: getErrorMessageWithContext(failure, context: context),
      category: failure.category,
      isRecoverable: failure.isRecoverable,
      recoverySteps: getRecoveryGuidance(failure),
      technicalDetails: _getTechnicalDetails(failure),
      errorCode: failure.code,
    );
  }

  /// **Format Error for Display**
  /// 
  /// Returns formatted error suitable for UI display
  /// 
  /// Usage:
  /// ```dart
  /// final displayError = service.formatErrorForDisplay(failure);
  /// ```
  DisplayError formatErrorForDisplay(
    Failure failure, {
    Map<String, dynamic>? context,
    bool includeRecovery = true,
  }) {
    final summary = getErrorSummary(failure, context: context);
    
    return DisplayError(
      title: summary.title,
      message: summary.message,
      severity: _getErrorSeverity(failure),
      icon: _getErrorIcon(failure),
      primaryAction: _getPrimaryAction(failure),
      secondaryAction: includeRecovery ? _getSecondaryAction(failure) : null,
      recoverySteps: includeRecovery ? summary.recoverySteps : null,
    );
  }

  /// **Private Helper Methods**

  /// Get Vietnamese error message
  String _getVietnameseErrorMessage(Failure failure) {
    // Use the failure's built-in userMessage which now uses ErrorMessagesVi
    return failure.userMessage;
  }

  /// Get English error message (fallback)
  String _getEnglishErrorMessage(Failure failure) {
    // Return technical message for English (can be enhanced later)
    return failure.message;
  }

  /// Format message with context
  String _formatMessageWithContext(
    String baseMessage,
    Failure failure,
    Map<String, dynamic> context,
  ) {
    final operation = context['operation'] as String?;
    final retryCount = context['retry_count'] as int?;
    final timestamp = context['timestamp'] as DateTime?;

    var formattedMessage = baseMessage;

    // Add operation context
    if (operation != null) {
      switch (operation) {
        case 'send_message':
          formattedMessage += ' Tin nhắn sẽ được gửi lại khi có kết nối.';
          break;
        case 'login':
          formattedMessage += ' Vui lòng kiểm tra thông tin đăng nhập.';
          break;
        case 'upload_media':
          formattedMessage += ' Vui lòng thử tải lên file khác.';
          break;
        case 'sync_data':
          formattedMessage += ' Dữ liệu sẽ được đồng bộ khi có kết nối.';
          break;
      }
    }

    // Add retry information
    if (retryCount != null && retryCount > 0) {
      formattedMessage += ' (Đã thử $retryCount lần)';
    }

    return formattedMessage;
  }

  /// Get error category for recovery guidance
  String _getErrorCategory(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
      case ConnectionFailure:
      case NetworkFailure:
        return 'network_issues';
      case AuthenticationFailure:
      case PermissionFailure:
        return 'authentication_issues';
      case ValidationFailure:
        return 'validation_issues';
      case CacheFailure:
        return 'storage_issues';
      default:
        return 'general_issues';
    }
  }

  /// Get error title
  String _getErrorTitle(Failure failure) {
    switch (_currentLocale) {
      case 'vi':
        return _getVietnameseErrorTitle(failure);
      case 'en':
        return _getEnglishErrorTitle(failure);
      default:
        return _getVietnameseErrorTitle(failure);
    }
  }

  /// Get Vietnamese error title
  String _getVietnameseErrorTitle(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Lỗi Server';
      case ConnectionFailure:
        return 'Lỗi Kết Nối';
      case NetworkFailure:
        return 'Lỗi Mạng';
      case AuthenticationFailure:
        return 'Lỗi Xác Thực';
      case PermissionFailure:
        return 'Lỗi Phân Quyền';
      case ValidationFailure:
        return 'Lỗi Dữ Liệu';
      case CacheFailure:
        return 'Lỗi Lưu Trữ';
      default:
        return 'Có Lỗi Xảy Ra';
    }
  }

  /// Get English error title
  String _getEnglishErrorTitle(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Error';
      case ConnectionFailure:
        return 'Connection Error';
      case NetworkFailure:
        return 'Network Error';
      case AuthenticationFailure:
        return 'Authentication Error';
      case PermissionFailure:
        return 'Permission Error';
      case ValidationFailure:
        return 'Validation Error';
      case CacheFailure:
        return 'Storage Error';
      default:
        return 'An Error Occurred';
    }
  }

  /// Get technical details
  String _getTechnicalDetails(Failure failure) {
    final details = <String>[];
    
    details.add('Type: ${failure.runtimeType}');
    if (failure.code != null) {
      details.add('Code: ${failure.code}');
    }
    details.add('Message: ${failure.message}');
    
    if (failure.details != null && failure.details!.isNotEmpty) {
      details.add('Details: ${failure.details}');
    }
    
    return details.join('\n');
  }

  /// Get error severity
  ErrorSeverity _getErrorSeverity(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return ErrorSeverity.high;
      case ConnectionFailure:
      case NetworkFailure:
        return ErrorSeverity.medium;
      case AuthenticationFailure:
        return ErrorSeverity.high;
      case PermissionFailure:
        return ErrorSeverity.medium;
      case ValidationFailure:
        return ErrorSeverity.low;
      case CacheFailure:
        return ErrorSeverity.low;
      default:
        return ErrorSeverity.medium;
    }
  }

  /// Get error icon
  String _getErrorIcon(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return '🔧';
      case ConnectionFailure:
      case NetworkFailure:
        return '📡';
      case AuthenticationFailure:
        return '🔐';
      case PermissionFailure:
        return '🚫';
      case ValidationFailure:
        return '⚠️';
      case CacheFailure:
        return '💾';
      default:
        return '❌';
    }
  }

  /// Get primary action
  String _getPrimaryAction(Failure failure) {
    if (failure.isRecoverable) {
      return _currentLocale == 'vi' ? 'Thử Lại' : 'Retry';
    } else {
      return _currentLocale == 'vi' ? 'Đóng' : 'Close';
    }
  }

  /// Get secondary action
  String? _getSecondaryAction(Failure failure) {
    if (failure.isRecoverable) {
      return _currentLocale == 'vi' ? 'Xem Hướng Dẫn' : 'View Guide';
    }
    return null;
  }

  /// Get English recovery guidance (placeholder)
  List<String> _getEnglishRecoveryGuidance(String category) {
    // This can be implemented later for English support
    return [];
  }
}

/// **Error Summary Model**
class ErrorSummary {
  final String title;
  final String message;
  final String category;
  final bool isRecoverable;
  final List<String> recoverySteps;
  final String technicalDetails;
  final String? errorCode;

  const ErrorSummary({
    required this.title,
    required this.message,
    required this.category,
    required this.isRecoverable,
    required this.recoverySteps,
    required this.technicalDetails,
    this.errorCode,
  });
}

/// **Display Error Model**
class DisplayError {
  final String title;
  final String message;
  final ErrorSeverity severity;
  final String icon;
  final String primaryAction;
  final String? secondaryAction;
  final List<String>? recoverySteps;

  const DisplayError({
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
    required this.primaryAction,
    this.secondaryAction,
    this.recoverySteps,
  });
}

/// **Error Severity Enum**
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// **Usage Examples:**
/// 
/// ```dart
/// // Basic usage
/// final service = ErrorLocalizationService.instance;
/// final message = service.getLocalizedErrorMessage(failure);
/// 
/// // With context
/// final contextualMessage = service.getErrorMessageWithContext(
///   failure,
///   context: {'operation': 'send_message', 'retry_count': 2},
/// );
/// 
/// // For UI display
/// final displayError = service.formatErrorForDisplay(failure);
/// 
/// // Complete error summary
/// final summary = service.getErrorSummary(failure);
/// ```
