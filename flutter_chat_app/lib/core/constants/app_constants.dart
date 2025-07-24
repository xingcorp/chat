
/// **APP CONSTANTS - CENTRALIZED CONFIGURATION**
///
/// Professional centralized constants following enterprise standards:
/// - No hardcoded values in business logic
/// - SCREAMING_SNAKE_CASE for primitive constants
/// - PascalCase for configuration classes
/// - Comprehensive documentation with usage examples
///
/// **Architecture:** Clean Architecture + Configuration Management

/// **APPLICATION CONSTANTS**
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// **Application Information**
  static const String appName = 'Flutter Chat App';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appPackageName = 'com.enterprise.flutter_chat_app';

  /// **API Configuration**
  static const String apiBaseUrl = 'https://api.enterprise-chat.com';
  static const String apiVersion = 'v1';
  static const int apiTimeoutSeconds = 30;
  static const int apiRetryAttempts = 3;
  static const int apiRetryDelayMs = 1000;

  /// **WebSocket Configuration**
  static const String websocketUrl = 'wss://ws.enterprise-chat.com';
  static const int websocketReconnectAttempts = 5;
  static const int websocketReconnectDelayMs = 500;
  static const int websocketPingIntervalSeconds = 30;
  static const int websocketTimeoutSeconds = 10;

  /// **UI Dimensions (Legacy - Maintained for backward compatibility)**
  // Kích thước và khoảng cách
  static const double kDefaultPadding = 16.0;
  static const double kSmallPadding = 8.0;
  static const double kLargePadding = 24.0;
  static const double kExtraLargePadding = 32.0;
  
  static const double kDefaultBorderRadius = 12.0;
  static const double kSmallBorderRadius = 8.0;
  static const double kLargeBorderRadius = 16.0;
  static const double kCircularBorderRadius = 100.0;
  
  static const double kTouchTargetSize = 48.0;
  static const double kDefaultIconSize = 24.0;
  static const double kSmallIconSize = 16.0;
  static const double kLargeIconSize = 32.0;
  
  static const double kDefaultElevation = 2.0;
  static const double kProfileImageSize = 40.0;
  static const double kLargeProfileImageSize = 80.0;
  
  // Animation durations
  static const Duration kFastAnimationDuration = Duration(milliseconds: 150);
  static const Duration kDefaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration kSlowAnimationDuration = Duration(milliseconds: 500);
  
  // Feature flags and limits
  static const int kMaxMessageLength = 4000;
  static const int kMaxGroupMembers = 100;
  static const int kMaxAttachmentSize = 25 * 1024 * 1024; // 25 MB
  static const int kMaxAttachmentsPerMessage = 10;
  static const int kMaxGroupNameLength = 100;
  static const int kMaxUserNameLength = 50;
  static const int kMaxStatusLength = 200;
  
  // Network timeouts
  static const Duration kConnectionTimeout = Duration(seconds: 30);
  static const Duration kReceiveTimeout = Duration(seconds: 30);
  static const Duration kSendTimeout = Duration(seconds: 30);
  
  // Retry logic
  static const int kMaxRetryAttempts = 3;
  static const Duration kInitialRetryDelay = Duration(seconds: 1);
  static const double kRetryBackoffFactor = 1.5;
  
  // Cache constants
  static const Duration kDefaultCacheDuration = Duration(days: 7);
  static const Duration kShortCacheDuration = Duration(hours: 1);
  static const Duration kLongCacheDuration = Duration(days: 30);
  
  static const int kMediaCacheSizeLimit = 200 * 1024 * 1024; // 200 MB
  static const int kChatHistoryLimit = 100; // Messages to load initially
  static const int kChatLoadMoreLimit = 50; // Messages to load when scrolling
  
  // Notification
  static const String kNotificationChannelId = 'chat_notifications';
  static const String kNotificationChannelName = 'Chat Notifications';
  static const String kNotificationChannelDescription = 'Notifications for new messages and calls';
  
  // Shared Preferences Keys
  static const String kPrefsKeyUser = 'user_data';
  static const String kPrefsKeyToken = 'auth_token';
  static const String kPrefsKeyRefreshToken = 'refresh_token';
  static const String kPrefsKeySettings = 'app_settings';
  static const String kPrefsKeyLastSyncTime = 'last_sync_time';
  static const String kPrefsKeyDeviceId = 'device_id';
  static const String kPrefsKeyThemeMode = 'theme_mode';
  static const String kPrefsKeyLanguage = 'app_language';
  
  // Database
  static const String kDatabaseName = 'flutter_chat_app.db';
  static const int kDatabaseVersion = 1;
  
  // Firebase Dynamic Links
  static const String kDeepLinkPrefix = 'https://flutterchatapp.page.link';
  
  // Routes
  static const String kRouteHome = '/';
  static const String kRouteLogin = '/login';
  static const String kRouteRegister = '/register';
  static const String kRouteChat = '/chat';
  static const String kRouteGroupChat = '/group-chat';
  static const String kRouteProfile = '/profile';
  static const String kRouteSettings = '/settings';
  static const String kRouteSearch = '/search';
  static const String kRouteContacts = '/contacts';
  static const String kRouteCreateGroup = '/create-group';
  static const String kRouteInviteUsers = '/invite-users';
  
  // Error messages
  static const String kErrorMessageNoInternet = 'Không có kết nối Internet. Vui lòng kiểm tra lại kết nối của bạn.';
  static const String kErrorMessageServerError = 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
  static const String kErrorMessageTimeoutError = 'Kết nối tới máy chủ quá lâu. Vui lòng thử lại sau.';
  static const String kErrorMessageUnauthorized = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  
  // Misc
  static const String kDefaultDateFormat = 'dd/MM/yyyy';
  static const String kDefaultTimeFormat = 'HH:mm';
  static const String kDefaultDateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Chat message types
  static const String kMessageTypeText = 'text';
  static const String kMessageTypeImage = 'image';
  static const String kMessageTypeVideo = 'video';
  static const String kMessageTypeAudio = 'audio';
  static const String kMessageTypeFile = 'file';
  static const String kMessageTypeLocation = 'location';
  static const String kMessageTypeSticker = 'sticker';
  static const String kMessageTypeContact = 'contact';
  static const String kMessageTypeSystem = 'system';
  
  // Websocket Events
  static const String kEventUserJoined = 'user_joined';
  static const String kEventUserLeft = 'user_left';
  static const String kEventMessageSent = 'message_sent';
  static const String kEventMessageRead = 'message_read';
  static const String kEventMessageDeleted = 'message_deleted';
  static const String kEventTypingStarted = 'typing_started';
  static const String kEventTypingStopped = 'typing_stopped';
  static const String kEventUserOnline = 'user_online';
  static const String kEventUserOffline = 'user_offline';
  static const String kEventGroupCreated = 'group_created';
  static const String kEventGroupUpdated = 'group_updated';
  static const String kEventGroupDeleted = 'group_deleted';
  static const String kEventGroupUserAdded = 'group_user_added';
  static const String kEventGroupUserRemoved = 'group_user_removed';

  /// **Mock Data URLs (for development/testing)**
  static const String mockAvatarBaseUrl = 'https://api.dicebear.com/7.x/avataaars/svg';
  static const String mockImageBaseUrl = 'https://picsum.photos';
  static const List<String> mockAvatarUrls = [
    '$mockAvatarBaseUrl?seed=avatar1',
    '$mockAvatarBaseUrl?seed=avatar2',
    '$mockAvatarBaseUrl?seed=avatar3',
  ];
  static const List<String> mockImageUrls = [
    '$mockImageBaseUrl/300/200?random=1',
    '$mockImageBaseUrl/300/200?random=2',
  ];
  static const List<String> mockVideoThumbnailUrls = [
    '$mockImageBaseUrl/300/200?random=video1',
  ];
}