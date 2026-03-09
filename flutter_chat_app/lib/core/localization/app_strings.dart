/// **APP STRINGS - COMPREHENSIVE LOCALIZATION**
///
/// Professional string localization following enterprise standards:
/// - Vietnamese as primary language
/// - English as fallback language
/// - Context-aware string management
/// - Consistent terminology across app
///
/// **Architecture:** Clean Architecture + Localization + Multi-language Support
library;

/// **APPLICATION STRINGS**
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  /// Current locale (default: Vietnamese)
  static String currentLocale = 'vi';

  /// **GENERAL APP STRINGS**
  static String get appName => _getString('app_name');
  static String get appDescription => _getString('app_description');
  static String get loading => _getString('loading');
  static String get retry => _getString('retry');
  static String get cancel => _getString('cancel');
  static String get ok => _getString('ok');
  static String get yes => _getString('yes');
  static String get no => _getString('no');
  static String get save => _getString('save');
  static String get delete => _getString('delete');
  static String get edit => _getString('edit');
  static String get close => _getString('close');
  static String get back => _getString('back');
  static String get next => _getString('next');
  static String get done => _getString('done');
  static String get search => _getString('search');
  static String get settings => _getString('settings');
  static String get help => _getString('help');
  static String get about => _getString('about');

  /// **AUTHENTICATION STRINGS**
  static String get login => _getString('login');
  static String get logout => _getString('logout');
  static String get register => _getString('register');
  static String get forgotPassword => _getString('forgot_password');
  static String get resetPassword => _getString('reset_password');
  static String get changePassword => _getString('change_password');
  static String get email => _getString('email');
  static String get password => _getString('password');
  static String get confirmPassword => _getString('confirm_password');
  static String get fullName => _getString('full_name');
  static String get phoneNumber => _getString('phone_number');
  static String get loginSuccess => _getString('login_success');
  static String get logoutSuccess => _getString('logout_success');
  static String get registerSuccess => _getString('register_success');
  static String get passwordResetSent => _getString('password_reset_sent');

  /// **CHAT STRINGS**
  static String get chats => _getString('chats');
  static String get messages => _getString('messages');
  static String get newChat => _getString('new_chat');
  static String get newMessage => _getString('new_message');
  static String get sendMessage => _getString('send_message');
  static String get typeMessage => _getString('type_message');
  static String get messageHint => _getString('message_hint');
  static String get messageSent => _getString('message_sent');
  static String get messageDelivered => _getString('message_delivered');
  static String get messageRead => _getString('message_read');
  static String get messageFailed => _getString('message_failed');
  static String get typing => _getString('typing');
  static String get online => _getString('online');
  static String get offline => _getString('offline');
  static String get lastSeen => _getString('last_seen');
  static String get deleteMessage => _getString('delete_message');
  static String get editMessage => _getString('edit_message');
  static String get copyMessage => _getString('copy_message');
  static String get forwardMessage => _getString('forward_message');
  static String get replyMessage => _getString('reply_message');

  /// **MEDIA STRINGS**
  static String get photo => _getString('photo');
  static String get video => _getString('video');
  static String get audio => _getString('audio');
  static String get document => _getString('document');
  static String get camera => _getString('camera');
  static String get gallery => _getString('gallery');
  static String get selectPhoto => _getString('select_photo');
  static String get takePhoto => _getString('take_photo');
  static String get recordVideo => _getString('record_video');
  static String get recordAudio => _getString('record_audio');
  static String get uploadFile => _getString('upload_file');
  static String get downloading => _getString('downloading');
  static String get uploading => _getString('uploading');
  static String get downloadFailed => _getString('download_failed');
  static String get uploadFailed => _getString('upload_failed');

  /// **PROFILE STRINGS**
  static String get profile => _getString('profile');
  static String get editProfile => _getString('edit_profile');
  static String get profilePicture => _getString('profile_picture');
  static String get status => _getString('status');
  static String get bio => _getString('bio');
  static String get updateProfile => _getString('update_profile');
  static String get profileUpdated => _getString('profile_updated');

  /// **SETTINGS STRINGS**
  static String get notifications => _getString('notifications');
  static String get privacy => _getString('privacy');
  static String get security => _getString('security');
  static String get language => _getString('language');
  static String get theme => _getString('theme');
  static String get darkMode => _getString('dark_mode');
  static String get lightMode => _getString('light_mode');
  static String get systemMode => _getString('system_mode');
  static String get fontSize => _getString('font_size');
  static String get chatWallpaper => _getString('chat_wallpaper');
  static String get backup => _getString('backup');
  static String get restore => _getString('restore');
  static String get clearCache => _getString('clear_cache');
  static String get clearData => _getString('clear_data');

  /// **VALIDATION STRINGS**
  static String get fieldRequired => _getString('field_required');
  static String get invalidEmail => _getString('invalid_email');
  static String get invalidPhone => _getString('invalid_phone');
  static String get passwordTooShort => _getString('password_too_short');
  static String get passwordsNotMatch => _getString('passwords_not_match');
  static String get nameTooShort => _getString('name_too_short');
  static String get messageTooLong => _getString('message_too_long');
  static String get fileTooLarge => _getString('file_too_large');
  static String get invalidFileType => _getString('invalid_file_type');

  /// **TIME STRINGS**
  static String get now => _getString('now');
  static String get today => _getString('today');
  static String get yesterday => _getString('yesterday');
  static String get thisWeek => _getString('this_week');
  static String get lastWeek => _getString('last_week');
  static String get thisMonth => _getString('this_month');
  static String get lastMonth => _getString('last_month');
  static String minutesAgo(int minutes) =>
      _getStringWithParam('minutes_ago', minutes);
  static String hoursAgo(int hours) => _getStringWithParam('hours_ago', hours);
  static String daysAgo(int days) => _getStringWithParam('days_ago', days);

  /// **CONNECTION STRINGS**
  static String get connecting => _getString('connecting');
  static String get connected => _getString('connected');
  static String get disconnected => _getString('disconnected');
  static String get reconnecting => _getString('reconnecting');
  static String get connectionLost => _getString('connection_lost');
  static String get connectionRestored => _getString('connection_restored');
  static String get offlineMode => _getString('offline_mode');
  static String get syncingData => _getString('syncing_data');
  static String get dataSynced => _getString('data_synced');

  /// **PERMISSION STRINGS**
  static String get permissionRequired => _getString('permission_required');
  static String get cameraPermission => _getString('camera_permission');
  static String get storagePermission => _getString('storage_permission');
  static String get microphonePermission => _getString('microphone_permission');
  static String get contactsPermission => _getString('contacts_permission');
  static String get locationPermission => _getString('location_permission');
  static String get grantPermission => _getString('grant_permission');
  static String get permissionDenied => _getString('permission_denied');

  /// **CONFIRMATION STRINGS**
  static String get confirmDelete => _getString('confirm_delete');
  static String get confirmLogout => _getString('confirm_logout');
  static String get confirmClearData => _getString('confirm_clear_data');
  static String get deleteConfirmation => _getString('delete_confirmation');
  static String get logoutConfirmation => _getString('logout_confirmation');
  static String get clearDataConfirmation =>
      _getString('clear_data_confirmation');

  /// **SUCCESS STRINGS**
  static String get operationSuccess => _getString('operation_success');
  static String get dataSaved => _getString('data_saved');
  static String get messageDeleted => _getString('message_deleted');
  static String get profileSaved => _getString('profile_saved');
  static String get settingsSaved => _getString('settings_saved');
  static String get passwordChanged => _getString('password_changed');

  /// **HELPER METHODS**

  /// Get string by key for current locale
  static String _getString(String key) {
    switch (currentLocale) {
      case 'vi':
        return _vietnameseStrings[key] ?? _englishStrings[key] ?? key;
      case 'en':
        return _englishStrings[key] ?? _vietnameseStrings[key] ?? key;
      default:
        return _vietnameseStrings[key] ?? _englishStrings[key] ?? key;
    }
  }

  /// Get string with parameter
  static String _getStringWithParam(String key, dynamic param) {
    final template = _getString(key);
    return template.replaceAll('{param}', param.toString());
  }

  /// **VIETNAMESE STRINGS**
  static const Map<String, String> _vietnameseStrings = {
    // General
    'app_name': 'OXII Chat',
    'app_description': 'Ứng dụng chat hiện đại và bảo mật',
    'loading': 'Đang tải...',
    'retry': 'Thử lại',
    'cancel': 'Hủy',
    'ok': 'Đồng ý',
    'yes': 'Có',
    'no': 'Không',
    'save': 'Lưu',
    'delete': 'Xóa',
    'edit': 'Chỉnh sửa',
    'close': 'Đóng',
    'back': 'Quay lại',
    'next': 'Tiếp theo',
    'done': 'Hoàn thành',
    'search': 'Tìm kiếm',
    'settings': 'Cài đặt',
    'help': 'Trợ giúp',
    'about': 'Giới thiệu',

    // Authentication
    'login': 'Đăng nhập',
    'logout': 'Đăng xuất',
    'register': 'Đăng ký',
    'forgot_password': 'Quên mật khẩu',
    'reset_password': 'Đặt lại mật khẩu',
    'change_password': 'Đổi mật khẩu',
    'email': 'Email',
    'password': 'Mật khẩu',
    'confirm_password': 'Xác nhận mật khẩu',
    'full_name': 'Họ và tên',
    'phone_number': 'Số điện thoại',
    'login_success': 'Đăng nhập thành công',
    'logout_success': 'Đăng xuất thành công',
    'register_success': 'Đăng ký thành công',
    'password_reset_sent': 'Email đặt lại mật khẩu đã được gửi',

    // Chat
    'chats': 'Trò chuyện',
    'messages': 'Tin nhắn',
    'new_chat': 'Cuộc trò chuyện mới',
    'new_message': 'Tin nhắn mới',
    'send_message': 'Gửi tin nhắn',
    'type_message': 'Nhập tin nhắn...',
    'message_hint': 'Nhập tin nhắn của bạn',
    'message_sent': 'Đã gửi',
    'message_delivered': 'Đã nhận',
    'message_read': 'Đã đọc',
    'message_failed': 'Gửi thất bại',
    'typing': 'đang gõ...',
    'online': 'Trực tuyến',
    'offline': 'Ngoại tuyến',
    'last_seen': 'Hoạt động lần cuối',
    'delete_message': 'Xóa tin nhắn',
    'edit_message': 'Chỉnh sửa tin nhắn',
    'copy_message': 'Sao chép tin nhắn',
    'forward_message': 'Chuyển tiếp tin nhắn',
    'reply_message': 'Trả lời tin nhắn',

    // Time
    'now': 'Bây giờ',
    'today': 'Hôm nay',
    'yesterday': 'Hôm qua',
    'this_week': 'Tuần này',
    'last_week': 'Tuần trước',
    'this_month': 'Tháng này',
    'last_month': 'Tháng trước',
    'minutes_ago': '{param} phút trước',
    'hours_ago': '{param} giờ trước',
    'days_ago': '{param} ngày trước',

    // Validation
    'field_required': 'Trường này là bắt buộc',
    'invalid_email': 'Email không hợp lệ',
    'invalid_phone': 'Số điện thoại không hợp lệ',
    'password_too_short': 'Mật khẩu quá ngắn',
    'passwords_not_match': 'Mật khẩu không khớp',
    'name_too_short': 'Tên quá ngắn',
    'message_too_long': 'Tin nhắn quá dài',
    'file_too_large': 'File quá lớn',
    'invalid_file_type': 'Loại file không hợp lệ',
  };

  /// **ENGLISH STRINGS**
  static const Map<String, String> _englishStrings = {
    // General
    'app_name': 'OXII Chat',
    'app_description': 'Modern and secure chat application',
    'loading': 'Loading...',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'done': 'Done',
    'search': 'Search',
    'settings': 'Settings',
    'help': 'Help',
    'about': 'About',

    // Authentication
    'login': 'Login',
    'logout': 'Logout',
    'register': 'Register',
    'forgot_password': 'Forgot Password',
    'reset_password': 'Reset Password',
    'change_password': 'Change Password',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'full_name': 'Full Name',
    'phone_number': 'Phone Number',
    'login_success': 'Login successful',
    'logout_success': 'Logout successful',
    'register_success': 'Registration successful',
    'password_reset_sent': 'Password reset email sent',

    // Chat
    'chats': 'Chats',
    'messages': 'Messages',
    'new_chat': 'New Chat',
    'new_message': 'New Message',
    'send_message': 'Send Message',
    'type_message': 'Type a message...',
    'message_hint': 'Enter your message',
    'message_sent': 'Sent',
    'message_delivered': 'Delivered',
    'message_read': 'Read',
    'message_failed': 'Failed',
    'typing': 'typing...',
    'online': 'Online',
    'offline': 'Offline',
    'last_seen': 'Last seen',
    'delete_message': 'Delete Message',
    'edit_message': 'Edit Message',
    'copy_message': 'Copy Message',
    'forward_message': 'Forward Message',
    'reply_message': 'Reply Message',

    // Time
    'now': 'Now',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'this_week': 'This Week',
    'last_week': 'Last Week',
    'this_month': 'This Month',
    'last_month': 'Last Month',
    'minutes_ago': '{param} minutes ago',
    'hours_ago': '{param} hours ago',
    'days_ago': '{param} days ago',

    // Validation
    'field_required': 'This field is required',
    'invalid_email': 'Invalid email',
    'invalid_phone': 'Invalid phone number',
    'password_too_short': 'Password too short',
    'passwords_not_match': 'Passwords do not match',
    'name_too_short': 'Name too short',
    'message_too_long': 'Message too long',
    'file_too_large': 'File too large',
    'invalid_file_type': 'Invalid file type',
  };
}
