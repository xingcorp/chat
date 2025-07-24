/// **VIETNAMESE ERROR MESSAGES - COMPREHENSIVE LOCALIZATION**
///
/// Professional Vietnamese error localization following enterprise standards:
/// - User-friendly Vietnamese error messages
/// - Context-aware error descriptions
/// - Actionable recovery guidance
/// - Consistent tone and terminology
///
/// **Architecture:** Clean Architecture + Localization + User Experience

/// **VIETNAMESE ERROR MESSAGES**
class ErrorMessagesVi {
  // Private constructor to prevent instantiation
  ErrorMessagesVi._();

  /// **NETWORK ERRORS**
  static const Map<String, String> networkErrors = {
    // Connection Errors
    'connection_failed': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.',
    'connection_timeout': 'Kết nối bị timeout. Vui lòng kiểm tra tốc độ mạng và thử lại.',
    'connection_lost': 'Mất kết nối mạng. Đang thử kết nối lại...',
    'no_internet': 'Không có kết nối internet. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động.',
    'weak_connection': 'Kết nối mạng yếu. Một số tính năng có thể bị hạn chế.',
    
    // Server Errors
    'server_error': 'Lỗi server. Vui lòng thử lại sau ít phút.',
    'server_unavailable': 'Server tạm thời không khả dụng. Vui lòng thử lại sau.',
    'server_maintenance': 'Server đang bảo trì. Vui lòng thử lại sau.',
    'server_overload': 'Server đang quá tải. Vui lòng thử lại sau ít phút.',
    
    // API Errors
    'api_error': 'Có lỗi xảy ra với dịch vụ. Vui lòng thử lại.',
    'api_timeout': 'Yêu cầu bị timeout. Vui lòng thử lại.',
    'api_rate_limit': 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng chờ một chút.',
    'api_version_outdated': 'Phiên bản ứng dụng đã cũ. Vui lòng cập nhật ứng dụng.',
    
    // Request Errors
    'bad_request': 'Yêu cầu không hợp lệ. Vui lòng kiểm tra thông tin và thử lại.',
    'unauthorized': 'Bạn không có quyền truy cập. Vui lòng đăng nhập lại.',
    'forbidden': 'Bạn không có quyền thực hiện hành động này.',
    'not_found': 'Không tìm thấy thông tin yêu cầu.',
    'method_not_allowed': 'Phương thức không được hỗ trợ.',
    'conflict': 'Có xung đột dữ liệu. Vui lòng làm mới và thử lại.',
  };

  /// **AUTHENTICATION ERRORS**
  static const Map<String, String> authErrors = {
    // Login Errors
    'login_failed': 'Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.',
    'invalid_credentials': 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.',
    'account_locked': 'Tài khoản đã bị khóa do đăng nhập sai quá nhiều lần.',
    'account_disabled': 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.',
    'account_not_verified': 'Tài khoản chưa được xác thực. Vui lòng kiểm tra email.',
    
    // Registration Errors
    'registration_failed': 'Đăng ký thất bại. Vui lòng thử lại.',
    'email_already_exists': 'Email này đã được sử dụng. Vui lòng sử dụng email khác.',
    'username_taken': 'Tên người dùng đã được sử dụng. Vui lòng chọn tên khác.',
    'weak_password': 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.',
    
    // Token Errors
    'token_expired': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'token_invalid': 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
    'refresh_token_expired': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    
    // Password Errors
    'password_reset_failed': 'Không thể đặt lại mật khẩu. Vui lòng thử lại.',
    'password_change_failed': 'Không thể thay đổi mật khẩu. Vui lòng thử lại.',
    'old_password_incorrect': 'Mật khẩu cũ không đúng. Vui lòng thử lại.',
  };

  /// **VALIDATION ERRORS**
  static const Map<String, String> validationErrors = {
    // Email Validation
    'email_required': 'Vui lòng nhập địa chỉ email.',
    'email_invalid': 'Địa chỉ email không hợp lệ.',
    'email_too_long': 'Địa chỉ email quá dài.',
    
    // Password Validation
    'password_required': 'Vui lòng nhập mật khẩu.',
    'password_too_short': 'Mật khẩu phải có ít nhất 8 ký tự.',
    'password_too_long': 'Mật khẩu không được quá 128 ký tự.',
    'password_no_uppercase': 'Mật khẩu phải có ít nhất 1 chữ hoa.',
    'password_no_lowercase': 'Mật khẩu phải có ít nhất 1 chữ thường.',
    'password_no_number': 'Mật khẩu phải có ít nhất 1 số.',
    'password_no_special': 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt.',
    'passwords_not_match': 'Mật khẩu xác nhận không khớp.',
    
    // Name Validation
    'name_required': 'Vui lòng nhập họ tên.',
    'name_too_short': 'Họ tên phải có ít nhất 2 ký tự.',
    'name_too_long': 'Họ tên không được quá 50 ký tự.',
    'name_invalid_characters': 'Họ tên chỉ được chứa chữ cái và khoảng trắng.',
    
    // Phone Validation
    'phone_required': 'Vui lòng nhập số điện thoại.',
    'phone_invalid': 'Số điện thoại không hợp lệ.',
    'phone_too_short': 'Số điện thoại quá ngắn.',
    'phone_too_long': 'Số điện thoại quá dài.',
    
    // Message Validation
    'message_required': 'Vui lòng nhập nội dung tin nhắn.',
    'message_too_long': 'Tin nhắn quá dài. Tối đa 4000 ký tự.',
    'message_empty': 'Tin nhắn không được để trống.',
    
    // File Validation
    'file_required': 'Vui lòng chọn file.',
    'file_too_large': 'File quá lớn. Tối đa 25MB.',
    'file_invalid_type': 'Loại file không được hỗ trợ.',
    'image_too_large': 'Hình ảnh quá lớn. Tối đa 10MB.',
    'video_too_large': 'Video quá lớn. Tối đa 100MB.',
  };

  /// **MESSAGING ERRORS**
  static const Map<String, String> messagingErrors = {
    // Send Message Errors
    'message_send_failed': 'Không thể gửi tin nhắn. Vui lòng thử lại.',
    'message_too_long': 'Tin nhắn quá dài. Vui lòng rút ngắn nội dung.',
    'message_blocked': 'Tin nhắn bị chặn do vi phạm quy định.',
    'recipient_not_found': 'Không tìm thấy người nhận.',
    'chat_not_found': 'Không tìm thấy cuộc trò chuyện.',
    'chat_archived': 'Cuộc trò chuyện đã được lưu trữ.',
    'chat_deleted': 'Cuộc trò chuyện đã bị xóa.',
    
    // Media Errors
    'media_upload_failed': 'Không thể tải lên media. Vui lòng thử lại.',
    'media_download_failed': 'Không thể tải xuống media. Vui lòng thử lại.',
    'media_processing_failed': 'Không thể xử lý media. Vui lòng thử lại.',
    'media_corrupted': 'File media bị lỗi. Vui lòng chọn file khác.',
    
    // Real-time Errors
    'realtime_connection_failed': 'Không thể kết nối real-time. Tin nhắn có thể bị trễ.',
    'realtime_disconnected': 'Mất kết nối real-time. Đang thử kết nối lại...',
    'typing_indicator_failed': 'Không thể hiển thị trạng thái đang gõ.',
    'read_receipt_failed': 'Không thể cập nhật trạng thái đã đọc.',
  };

  /// **CACHE & STORAGE ERRORS**
  static const Map<String, String> cacheErrors = {
    'cache_read_failed': 'Không thể đọc dữ liệu cục bộ.',
    'cache_write_failed': 'Không thể lưu dữ liệu cục bộ.',
    'cache_full': 'Bộ nhớ cục bộ đã đầy. Vui lòng xóa dữ liệu cũ.',
    'cache_corrupted': 'Dữ liệu cục bộ bị lỗi. Đang khôi phục...',
    'storage_permission_denied': 'Không có quyền truy cập bộ nhớ.',
    'storage_not_available': 'Bộ nhớ không khả dụng.',
    'database_error': 'Lỗi cơ sở dữ liệu. Vui lòng khởi động lại ứng dụng.',
  };

  /// **GENERAL ERRORS**
  static const Map<String, String> generalErrors = {
    'unknown_error': 'Có lỗi không xác định xảy ra. Vui lòng thử lại.',
    'unexpected_error': 'Có lỗi bất ngờ xảy ra. Vui lòng thử lại.',
    'operation_failed': 'Thao tác thất bại. Vui lòng thử lại.',
    'operation_cancelled': 'Thao tác đã bị hủy.',
    'operation_timeout': 'Thao tác bị timeout. Vui lòng thử lại.',
    'permission_denied': 'Không có quyền thực hiện thao tác này.',
    'feature_not_available': 'Tính năng này hiện không khả dụng.',
    'maintenance_mode': 'Ứng dụng đang bảo trì. Vui lòng thử lại sau.',
  };

  /// **RECOVERY GUIDANCE**
  static const Map<String, List<String>> recoveryGuidance = {
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
  };

  /// **Get Error Message**
  /// 
  /// Returns Vietnamese error message for given error code
  /// 
  /// Usage:
  /// ```dart
  /// final message = ErrorMessagesVi.getErrorMessage('connection_failed');
  /// ```
  static String getErrorMessage(String errorCode, {String? fallback}) {
    // Search in all error categories
    final allErrors = {
      ...networkErrors,
      ...authErrors,
      ...validationErrors,
      ...messagingErrors,
      ...cacheErrors,
      ...generalErrors,
    };

    return allErrors[errorCode] ?? 
           fallback ?? 
           generalErrors['unknown_error']!;
  }

  /// **Get Recovery Guidance**
  /// 
  /// Returns recovery steps for given error category
  /// 
  /// Usage:
  /// ```dart
  /// final steps = ErrorMessagesVi.getRecoveryGuidance('network_issues');
  /// ```
  static List<String> getRecoveryGuidance(String category) {
    return recoveryGuidance[category] ?? [];
  }

  /// **Get Error Category**
  /// 
  /// Determines error category from error code
  static String getErrorCategory(String errorCode) {
    if (networkErrors.containsKey(errorCode)) return 'network_issues';
    if (authErrors.containsKey(errorCode)) return 'authentication_issues';
    if (messagingErrors.containsKey(errorCode)) return 'messaging_issues';
    if (cacheErrors.containsKey(errorCode)) return 'storage_issues';
    return 'general_issues';
  }

  /// **Format Error with Context**
  /// 
  /// Returns formatted error message with additional context
  /// 
  /// Usage:
  /// ```dart
  /// final message = ErrorMessagesVi.formatErrorWithContext(
  ///   'connection_failed',
  ///   context: {'operation': 'send_message'},
  /// );
  /// ```
  static String formatErrorWithContext(
    String errorCode, {
    Map<String, dynamic>? context,
    String? fallback,
  }) {
    final baseMessage = getErrorMessage(errorCode, fallback: fallback);
    
    if (context == null || context.isEmpty) {
      return baseMessage;
    }

    // Add context-specific information
    final operation = context['operation'] as String?;
    if (operation != null) {
      switch (operation) {
        case 'send_message':
          return '$baseMessage Tin nhắn sẽ được gửi lại khi có kết nối.';
        case 'login':
          return '$baseMessage Vui lòng kiểm tra thông tin đăng nhập.';
        case 'upload_media':
          return '$baseMessage Vui lòng thử tải lên file khác.';
        default:
          return baseMessage;
      }
    }

    return baseMessage;
  }
}
