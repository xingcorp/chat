/// Interface for providing localized error messages.
///
/// Allows package consumers to provide their own error messages
/// in any language. The default implementation uses Vietnamese messages.
abstract class ErrorMessageProvider {
  /// Get a localized error message for the given error code.
  ///
  /// [errorCode] identifies the specific error (e.g. 'server_error', 'connection_failed')
  /// [fallback] optional fallback message if code is not found
  String getErrorMessage(String errorCode, {String? fallback});

  /// Get recovery guidance steps for the given error category.
  ///
  /// [category] identifies the error category (e.g. 'network_issues', 'authentication_issues')
  List<String> getRecoveryGuidance(String category);
}

/// Default Vietnamese error message provider.
///
/// Delegates to [ErrorMessagesVi] for backward compatibility.
class VietnameseErrorMessageProvider implements ErrorMessageProvider {
  const VietnameseErrorMessageProvider();

  @override
  String getErrorMessage(String errorCode, {String? fallback}) {
    return _ErrorMessagesVi.getErrorMessage(errorCode, fallback: fallback);
  }

  @override
  List<String> getRecoveryGuidance(String category) {
    return _ErrorMessagesVi.getRecoveryGuidance(category);
  }
}

/// Registry that holds the current [ErrorMessageProvider].
///
/// Defaults to [VietnameseErrorMessageProvider].
/// Package consumers can override via [ErrorMessages.setProvider].
class ErrorMessages {
  ErrorMessages._();

  static ErrorMessageProvider _provider = const VietnameseErrorMessageProvider();

  /// The current error message provider.
  static ErrorMessageProvider get provider => _provider;

  /// Set a custom error message provider.
  ///
  /// Call this during module initialization to override the default
  /// Vietnamese messages with your own localization.
  static void setProvider(ErrorMessageProvider provider) {
    _provider = provider;
  }

  /// Reset to the default Vietnamese provider.
  static void resetToDefault() {
    _provider = const VietnameseErrorMessageProvider();
  }

  /// Convenience: get a localized error message.
  static String getMessage(String errorCode, {String? fallback}) {
    return _provider.getErrorMessage(errorCode, fallback: fallback);
  }
}

/// Internal copy of Vietnamese error messages for the default provider.
/// This avoids a circular dependency with the public ErrorMessagesVi class.
class _ErrorMessagesVi {
  _ErrorMessagesVi._();

  static const Map<String, String> _allErrors = {
    // Network Errors
    'connection_failed': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.',
    'connection_timeout': 'Kết nối bị timeout. Vui lòng kiểm tra tốc độ mạng và thử lại.',
    'connection_lost': 'Mất kết nối mạng. Đang thử kết nối lại...',
    'no_internet': 'Không có kết nối internet. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động.',
    'weak_connection': 'Kết nối mạng yếu. Một số tính năng có thể bị hạn chế.',
    'server_error': 'Lỗi server. Vui lòng thử lại sau ít phút.',
    'server_unavailable': 'Server tạm thời không khả dụng. Vui lòng thử lại sau.',
    'server_maintenance': 'Server đang bảo trì. Vui lòng thử lại sau.',
    'server_overload': 'Server đang quá tải. Vui lòng thử lại sau ít phút.',
    // Auth Errors
    'login_failed': 'Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.',
    'invalid_credentials': 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.',
    'account_locked': 'Tài khoản đã bị khóa do đăng nhập sai quá nhiều lần.',
    'account_disabled': 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.',
    'account_not_verified': 'Tài khoản chưa được xác thực. Vui lòng kiểm tra email.',
    'token_expired': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    // General
    'unknown_error': 'Có lỗi không xác định xảy ra. Vui lòng thử lại.',
  };

  static const Map<String, List<String>> _recoveryGuidance = {
    'network_issues': [
      'Kiểm tra kết nối Wi-Fi hoặc dữ liệu di động',
      'Thử tắt và bật lại Wi-Fi',
      'Di chuyển đến nơi có tín hiệu mạnh hơn',
      'Khởi động lại ứng dụng',
    ],
    'authentication_issues': [
      'Kiểm tra lại email và mật khẩu',
      'Thử đặt lại mật khẩu nếu quên',
      'Liên hệ hỗ trợ nếu tài khoản bị khóa',
    ],
  };

  static String getErrorMessage(String errorCode, {String? fallback}) {
    return _allErrors[errorCode] ?? fallback ?? _allErrors['unknown_error']!;
  }

  static List<String> getRecoveryGuidance(String category) {
    return _recoveryGuidance[category] ?? [];
  }
}
