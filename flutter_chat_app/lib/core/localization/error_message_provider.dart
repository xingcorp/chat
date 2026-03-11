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

/// Built-in English error message provider.
class EnglishErrorMessageProvider implements ErrorMessageProvider {
  const EnglishErrorMessageProvider();

  @override
  String getErrorMessage(String errorCode, {String? fallback}) {
    return _ErrorMessagesEn.getErrorMessage(errorCode, fallback: fallback);
  }

  @override
  List<String> getRecoveryGuidance(String category) {
    return _ErrorMessagesEn.getRecoveryGuidance(category);
  }
}

/// Internal Vietnamese error messages — complete set for the default provider.
class _ErrorMessagesVi {
  _ErrorMessagesVi._();

  static const Map<String, String> _allErrors = {
    // ── Network Errors ──
    'connection_failed': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.',
    'connection_timeout': 'Kết nối bị timeout. Vui lòng kiểm tra tốc độ mạng và thử lại.',
    'connection_lost': 'Mất kết nối mạng. Đang thử kết nối lại...',
    'no_internet': 'Không có kết nối internet. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động.',
    'weak_connection': 'Kết nối mạng yếu. Một số tính năng có thể bị hạn chế.',
    'server_error': 'Lỗi server. Vui lòng thử lại sau ít phút.',
    'server_unavailable': 'Server tạm thời không khả dụng. Vui lòng thử lại sau.',
    'server_maintenance': 'Server đang bảo trì. Vui lòng thử lại sau.',
    'server_overload': 'Server đang quá tải. Vui lòng thử lại sau ít phút.',

    // ── API Errors ──
    'api_error': 'Có lỗi xảy ra với dịch vụ. Vui lòng thử lại.',
    'api_timeout': 'Yêu cầu bị timeout. Vui lòng thử lại.',
    'api_rate_limit': 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng chờ một chút.',
    'api_version_outdated': 'Phiên bản ứng dụng đã cũ. Vui lòng cập nhật ứng dụng.',
    'bad_request': 'Yêu cầu không hợp lệ. Vui lòng kiểm tra thông tin và thử lại.',
    'unauthorized': 'Bạn không có quyền truy cập. Vui lòng đăng nhập lại.',
    'forbidden': 'Bạn không có quyền thực hiện hành động này.',
    'not_found': 'Không tìm thấy thông tin yêu cầu.',
    'method_not_allowed': 'Phương thức không được hỗ trợ.',
    'conflict': 'Có xung đột dữ liệu. Vui lòng làm mới và thử lại.',

    // ── Authentication Errors ──
    'login_failed': 'Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.',
    'invalid_credentials': 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.',
    'account_locked': 'Tài khoản đã bị khóa do đăng nhập sai quá nhiều lần.',
    'account_disabled': 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.',
    'account_not_verified': 'Tài khoản chưa được xác thực. Vui lòng kiểm tra email.',
    'registration_failed': 'Đăng ký thất bại. Vui lòng thử lại.',
    'email_already_exists': 'Email này đã được sử dụng. Vui lòng sử dụng email khác.',
    'username_taken': 'Tên người dùng đã được sử dụng. Vui lòng chọn tên khác.',
    'weak_password': 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.',
    'token_expired': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'token_invalid': 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
    'refresh_token_expired': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'password_reset_failed': 'Không thể đặt lại mật khẩu. Vui lòng thử lại.',
    'password_change_failed': 'Không thể thay đổi mật khẩu. Vui lòng thử lại.',
    'old_password_incorrect': 'Mật khẩu cũ không đúng. Vui lòng thử lại.',

    // ── Permission Errors ──
    'access_denied': 'Bạn không có quyền truy cập tính năng này.',
    'insufficient_permissions': 'Quyền hạn không đủ để thực hiện thao tác này.',
    'admin_required': 'Chỉ quản trị viên mới có thể thực hiện thao tác này.',
    'permission_denied': 'Không có quyền thực hiện thao tác này.',

    // ── Validation Errors ──
    'invalid_email': 'Email không hợp lệ. Vui lòng nhập đúng định dạng.',
    'password_too_short': 'Mật khẩu phải có ít nhất 8 ký tự.',
    'required_field': 'Vui lòng điền đầy đủ thông tin bắt buộc.',
    'invalid_phone': 'Số điện thoại không hợp lệ.',
    'validation_failed': 'Thông tin không hợp lệ. Vui lòng kiểm tra lại.',
    'email_required': 'Vui lòng nhập địa chỉ email.',
    'email_invalid': 'Địa chỉ email không hợp lệ.',
    'email_too_long': 'Địa chỉ email quá dài.',
    'password_required': 'Vui lòng nhập mật khẩu.',
    'password_too_long': 'Mật khẩu không được quá 128 ký tự.',
    'password_no_uppercase': 'Mật khẩu phải có ít nhất 1 chữ hoa.',
    'password_no_lowercase': 'Mật khẩu phải có ít nhất 1 chữ thường.',
    'password_no_number': 'Mật khẩu phải có ít nhất 1 số.',
    'password_no_special': 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt.',
    'passwords_not_match': 'Mật khẩu xác nhận không khớp.',
    'name_required': 'Vui lòng nhập họ tên.',
    'name_too_short': 'Họ tên phải có ít nhất 2 ký tự.',
    'name_too_long': 'Họ tên không được quá 50 ký tự.',
    'name_invalid_characters': 'Họ tên chỉ được chứa chữ cái và khoảng trắng.',
    'phone_required': 'Vui lòng nhập số điện thoại.',
    'phone_invalid': 'Số điện thoại không hợp lệ.',
    'phone_too_short': 'Số điện thoại quá ngắn.',
    'phone_too_long': 'Số điện thoại quá dài.',
    'message_required': 'Vui lòng nhập nội dung tin nhắn.',
    'message_too_long': 'Tin nhắn quá dài. Tối đa 4000 ký tự.',
    'message_empty': 'Tin nhắn không được để trống.',
    'file_required': 'Vui lòng chọn file.',
    'file_too_large': 'File quá lớn. Tối đa 25MB.',
    'file_invalid_type': 'Loại file không được hỗ trợ.',
    'image_too_large': 'Hình ảnh quá lớn. Tối đa 10MB.',
    'video_too_large': 'Video quá lớn. Tối đa 100MB.',

    // ── Cache & Storage Errors ──
    'storage_full': 'Bộ nhớ thiết bị đã đầy. Vui lòng giải phóng dung lượng.',
    'cache_corruption': 'Dữ liệu bị lỗi. Ứng dụng sẽ tải lại dữ liệu.',
    'storage_permission_denied': 'Không có quyền truy cập bộ nhớ thiết bị.',
    'cache_error': 'Có lỗi với dữ liệu cục bộ. Dữ liệu có thể không được cập nhật.',
    'cache_read_failed': 'Không thể đọc dữ liệu cục bộ.',
    'cache_write_failed': 'Không thể lưu dữ liệu cục bộ.',
    'cache_full': 'Bộ nhớ cục bộ đã đầy. Vui lòng xóa dữ liệu cũ.',
    'cache_corrupted': 'Dữ liệu cục bộ bị lỗi. Đang khôi phục...',
    'storage_not_available': 'Bộ nhớ không khả dụng.',
    'database_error': 'Lỗi cơ sở dữ liệu. Vui lòng khởi động lại ứng dụng.',

    // ── Timeout Errors ──
    'request_timeout': 'Yêu cầu bị timeout. Vui lòng thử lại.',
    'operation_timeout': 'Thao tác mất quá nhiều thời gian. Vui lòng thử lại.',
    'timeout_default': 'Thao tác bị timeout. Vui lòng thử lại sau.',

    // ── Realtime Errors ──
    'realtime_connection_lost': 'Mất kết nối real-time. Đang thử kết nối lại...',
    'realtime_reconnect_failed': 'Không thể kết nối lại. Vui lòng kiểm tra mạng.',
    'realtime_message_failed': 'Không thể gửi tin nhắn. Vui lòng thử lại.',
    'realtime_error': 'Có lỗi với kết nối real-time. Vui lòng thử lại.',
    'realtime_connection_failed': 'Không thể kết nối real-time. Tin nhắn có thể bị trễ.',
    'realtime_disconnected': 'Mất kết nối real-time. Đang thử kết nối lại...',
    'typing_indicator_failed': 'Không thể hiển thị trạng thái đang gõ.',
    'read_receipt_failed': 'Không thể cập nhật trạng thái đã đọc.',

    // ── Upload / Download Errors ──
    'upload_file_too_large': 'File quá lớn. Vui lòng chọn file nhỏ hơn.',
    'upload_invalid_format': 'Định dạng file không được hỗ trợ.',
    'upload_failed': 'Upload thất bại. Vui lòng thử lại.',
    'upload_storage_full': 'Bộ nhớ server đã đầy. Vui lòng thử lại sau.',
    'upload_error': 'Không thể upload file. Vui lòng thử lại.',
    'download_file_not_found': 'File không tồn tại hoặc đã bị xóa.',
    'download_failed': 'Download thất bại. Vui lòng thử lại.',
    'download_storage_full': 'Bộ nhớ thiết bị đã đầy. Vui lòng giải phóng dung lượng.',
    'download_error': 'Không thể download file. Vui lòng thử lại.',
    'media_upload_failed': 'Không thể tải lên media. Vui lòng thử lại.',
    'media_download_failed': 'Không thể tải xuống media. Vui lòng thử lại.',
    'media_processing_failed': 'Không thể xử lý media. Vui lòng thử lại.',
    'media_corrupted': 'File media bị lỗi. Vui lòng chọn file khác.',

    // ── Conflict Errors ──
    'version_conflict': 'Dữ liệu đã được cập nhật bởi người khác. Vui lòng tải lại.',
    'concurrent_modification': 'Có người khác đang chỉnh sửa. Vui lòng thử lại sau.',
    'duplicate_entry': 'Dữ liệu đã tồn tại. Vui lòng kiểm tra lại.',
    'conflict_error': 'Có xung đột dữ liệu. Vui lòng tải lại và thử lại.',

    // ── Messaging Errors ──
    'message_send_failed': 'Không thể gửi tin nhắn. Vui lòng thử lại.',
    'message_blocked': 'Tin nhắn bị chặn do vi phạm quy định.',
    'recipient_not_found': 'Không tìm thấy người nhận.',
    'chat_not_found': 'Không tìm thấy cuộc trò chuyện.',
    'chat_archived': 'Cuộc trò chuyện đã được lưu trữ.',
    'chat_deleted': 'Cuộc trò chuyện đã bị xóa.',

    // ── General Errors ──
    'unknown_error': 'Có lỗi không xác định xảy ra. Vui lòng thử lại.',
    'unexpected_error': 'Có lỗi không mong đợi xảy ra. Vui lòng khởi động lại ứng dụng.',
    'operation_failed': 'Thao tác thất bại. Vui lòng thử lại.',
    'operation_cancelled': 'Thao tác đã bị hủy.',
    'feature_not_available': 'Tính năng này hiện không khả dụng.',
    'maintenance_mode': 'Ứng dụng đang bảo trì. Vui lòng thử lại sau.',

    // ── Update Errors ──
    'update_check_failed': 'Không thể kiểm tra bản cập nhật. Vui lòng thử lại sau.',
    'update_download_failed': 'Không thể tải xuống bản cập nhật. Vui lòng thử lại.',
    'update_verification_failed': 'File cập nhật bị lỗi. Vui lòng tải lại.',
    'update_install_failed': 'Không thể cài đặt bản cập nhật. Vui lòng thử lại.',
    'update_cancelled': 'Đã hủy tải bản cập nhật.',
    'update_no_asset': 'Không tìm thấy file cài đặt cho nền tảng này.',
    'update_error': 'Có lỗi khi cập nhật. Vui lòng thử lại.',
  };

  static const Map<String, List<String>> _recoveryGuidance = {
    'network_issues': [
      'Kiểm tra kết nối Wi-Fi hoặc dữ liệu di động',
      'Thử tắt và bật lại Wi-Fi',
      'Di chuyển đến nơi có tín hiệu mạnh hơn',
      'Khởi động lại ứng dụng',
      'Liên hệ nhà cung cấp dịch vụ nếu vấn đề vẫn tiếp tục',
    ],
    'authentication_issues': [
      'Kiểm tra lại email và mật khẩu',
      'Đảm bảo tài khoản đã được xác thực',
      'Thử đặt lại mật khẩu nếu quên',
      'Liên hệ hỗ trợ nếu tài khoản bị khóa',
      'Cập nhật ứng dụng lên phiên bản mới nhất',
    ],
    'validation_issues': [
      'Kiểm tra lại thông tin đã nhập',
      'Đảm bảo tất cả trường bắt buộc đã được điền',
      'Kiểm tra định dạng email và số điện thoại',
      'Sử dụng mật khẩu mạnh hơn nếu cần',
    ],
    'messaging_issues': [
      'Kiểm tra kết nối mạng',
      'Thử gửi lại tin nhắn',
      'Kiểm tra dung lượng bộ nhớ thiết bị',
      'Khởi động lại ứng dụng',
      'Liên hệ hỗ trợ nếu vấn đề vẫn tiếp tục',
    ],
    'storage_issues': [
      'Kiểm tra dung lượng bộ nhớ thiết bị',
      'Xóa các file không cần thiết',
      'Cấp quyền truy cập bộ nhớ cho ứng dụng',
      'Khởi động lại thiết bị',
      'Cập nhật ứng dụng lên phiên bản mới nhất',
    ],
    'general_issues': [
      'Thử lại thao tác sau ít phút',
      'Khởi động lại ứng dụng',
      'Kiểm tra kết nối mạng',
      'Cập nhật ứng dụng lên phiên bản mới nhất',
    ],
  };

  static String getErrorMessage(String errorCode, {String? fallback}) {
    return _allErrors[errorCode] ?? fallback ?? _allErrors['unknown_error']!;
  }

  static List<String> getRecoveryGuidance(String category) {
    return _recoveryGuidance[category] ?? [];
  }
}

/// Internal English error messages for i18n support.
class _ErrorMessagesEn {
  _ErrorMessagesEn._();

  static const Map<String, String> _allErrors = {
    // ── Network Errors ──
    'connection_failed': 'Unable to connect to server. Please check your network and try again.',
    'connection_timeout': 'Connection timed out. Please check your network speed and try again.',
    'connection_lost': 'Network connection lost. Reconnecting...',
    'no_internet': 'No internet connection. Please check your Wi-Fi or mobile data.',
    'weak_connection': 'Weak network connection. Some features may be limited.',
    'server_error': 'Server error. Please try again in a few minutes.',
    'server_unavailable': 'Server is temporarily unavailable. Please try again later.',
    'server_maintenance': 'Server is under maintenance. Please try again later.',
    'server_overload': 'Server is overloaded. Please try again in a few minutes.',

    // ── API Errors ──
    'api_error': 'A service error occurred. Please try again.',
    'api_timeout': 'Request timed out. Please try again.',
    'api_rate_limit': 'Too many requests. Please wait a moment.',
    'api_version_outdated': 'App version is outdated. Please update the app.',
    'bad_request': 'Invalid request. Please check the information and try again.',
    'unauthorized': 'Unauthorized access. Please log in again.',
    'forbidden': 'You do not have permission to perform this action.',
    'not_found': 'The requested information was not found.',
    'method_not_allowed': 'Method not supported.',
    'conflict': 'Data conflict. Please refresh and try again.',

    // ── Authentication Errors ──
    'login_failed': 'Login failed. Please check your email and password.',
    'invalid_credentials': 'Invalid email or password. Please try again.',
    'account_locked': 'Account locked due to too many failed login attempts.',
    'account_disabled': 'Account has been disabled. Please contact support.',
    'account_not_verified': 'Account not verified. Please check your email.',
    'registration_failed': 'Registration failed. Please try again.',
    'email_already_exists': 'This email is already in use. Please use a different email.',
    'username_taken': 'This username is taken. Please choose another.',
    'weak_password': 'Password is too weak. Please use a stronger password.',
    'token_expired': 'Session expired. Please log in again.',
    'token_invalid': 'Invalid session. Please log in again.',
    'refresh_token_expired': 'Session expired. Please log in again.',
    'password_reset_failed': 'Unable to reset password. Please try again.',
    'password_change_failed': 'Unable to change password. Please try again.',
    'old_password_incorrect': 'Incorrect current password. Please try again.',

    // ── Permission Errors ──
    'access_denied': 'You do not have access to this feature.',
    'insufficient_permissions': 'Insufficient permissions to perform this action.',
    'admin_required': 'Only administrators can perform this action.',
    'permission_denied': 'Permission denied for this operation.',

    // ── Validation Errors ──
    'invalid_email': 'Invalid email format.',
    'password_too_short': 'Password must be at least 8 characters.',
    'required_field': 'Please fill in all required fields.',
    'invalid_phone': 'Invalid phone number.',
    'validation_failed': 'Invalid information. Please check and try again.',

    // ── Cache & Storage Errors ──
    'storage_full': 'Device storage is full. Please free up space.',
    'cache_corruption': 'Data corrupted. The app will reload data.',
    'storage_permission_denied': 'Storage access denied.',
    'cache_error': 'Local data error. Data may not be up to date.',

    // ── Timeout Errors ──
    'request_timeout': 'Request timed out. Please try again.',
    'operation_timeout': 'Operation took too long. Please try again.',
    'timeout_default': 'Operation timed out. Please try again later.',

    // ── Realtime Errors ──
    'realtime_connection_lost': 'Real-time connection lost. Reconnecting...',
    'realtime_reconnect_failed': 'Unable to reconnect. Please check your network.',
    'realtime_message_failed': 'Unable to send message. Please try again.',
    'realtime_error': 'Real-time connection error. Please try again.',

    // ── Upload / Download Errors ──
    'upload_file_too_large': 'File is too large. Please choose a smaller file.',
    'upload_invalid_format': 'Unsupported file format.',
    'upload_failed': 'Upload failed. Please try again.',
    'upload_storage_full': 'Server storage is full. Please try again later.',
    'upload_error': 'Unable to upload file. Please try again.',
    'download_file_not_found': 'File does not exist or has been deleted.',
    'download_failed': 'Download failed. Please try again.',
    'download_storage_full': 'Device storage is full. Please free up space.',
    'download_error': 'Unable to download file. Please try again.',

    // ── Conflict Errors ──
    'version_conflict': 'Data has been updated by someone else. Please reload.',
    'concurrent_modification': 'Someone else is editing. Please try again later.',
    'duplicate_entry': 'Data already exists. Please check again.',
    'conflict_error': 'Data conflict. Please reload and try again.',

    // ── General Errors ──
    'unknown_error': 'An unknown error occurred. Please try again.',
    'unexpected_error': 'An unexpected error occurred. Please restart the app.',
    'operation_failed': 'Operation failed. Please try again.',
    'operation_cancelled': 'Operation cancelled.',
    'feature_not_available': 'This feature is currently unavailable.',
    'maintenance_mode': 'App is under maintenance. Please try again later.',

    // ── Update Errors ──
    'update_check_failed': 'Unable to check for updates. Please try again later.',
    'update_download_failed': 'Unable to download the update. Please try again.',
    'update_verification_failed': 'Update file is corrupted. Please download again.',
    'update_install_failed': 'Unable to install the update. Please try again.',
    'update_cancelled': 'Update download cancelled.',
    'update_no_asset': 'No installer found for this platform.',
    'update_error': 'An error occurred while updating. Please try again.',
  };

  static const Map<String, List<String>> _recoveryGuidance = {
    'network_issues': [
      'Check your Wi-Fi or mobile data connection',
      'Try toggling Wi-Fi off and on',
      'Move to an area with better signal',
      'Restart the app',
      'Contact your service provider if the issue persists',
    ],
    'authentication_issues': [
      'Check your email and password',
      'Make sure your account is verified',
      'Try resetting your password',
      'Contact support if your account is locked',
      'Update the app to the latest version',
    ],
    'validation_issues': [
      'Check the information you entered',
      'Make sure all required fields are filled',
      'Check email and phone number format',
      'Use a stronger password if required',
    ],
    'messaging_issues': [
      'Check your network connection',
      'Try resending the message',
      'Check device storage space',
      'Restart the app',
      'Contact support if the issue persists',
    ],
    'storage_issues': [
      'Check device storage space',
      'Delete unnecessary files',
      'Grant storage access permissions to the app',
      'Restart your device',
      'Update the app to the latest version',
    ],
    'general_issues': [
      'Try again in a few minutes',
      'Restart the app',
      'Check your network connection',
      'Update the app to the latest version',
    ],
  };

  static String getErrorMessage(String errorCode, {String? fallback}) {
    return _allErrors[errorCode] ?? fallback ?? _allErrors['unknown_error']!;
  }

  static List<String> getRecoveryGuidance(String category) {
    return _recoveryGuidance[category] ?? [];
  }
}
