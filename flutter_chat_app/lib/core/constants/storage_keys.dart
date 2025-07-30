// Storage Keys Constants
// Centralized storage keys cho SharedPreferences và local storage
// Tuân thủ naming conventions và avoid conflicts

class StorageKeys {
  StorageKeys._(); // Private constructor để prevent instantiation

  // ========================================
  // PERMISSIONS STORAGE KEYS
  // ========================================
  
  /// Prefix cho permission-related keys
  static const String permissionPrefix = 'permission_';
  
  /// Permission history keys
  static const String permissionHistory = 'permission_history';
  static const String permissionLastCheck = 'permission_last_check';
  static const String permissionRequestCount = 'permission_request_count';
  
  // ========================================
  // USER PREFERENCES
  // ========================================
  
  /// User settings
  static const String userPreferences = 'user_preferences';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String notificationEnabled = 'notification_enabled';
  
  // ========================================
  // AUTHENTICATION & SECURITY
  // ========================================
  
  /// Auth tokens
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userSession = 'user_session';
  static const String biometricEnabled = 'biometric_enabled';
  
  // ========================================
  // CHAT & MESSAGING
  // ========================================
  
  /// Chat settings
  static const String chatSettings = 'chat_settings';
  static const String lastMessageId = 'last_message_id';
  static const String unreadCount = 'unread_count';
  static const String typingIndicators = 'typing_indicators';
  
  // ========================================
  // MEDIA & FILES
  // ========================================
  
  /// Media settings
  static const String mediaSettings = 'media_settings';
  static const String autoDownloadMedia = 'auto_download_media';
  static const String mediaQuality = 'media_quality';
  static const String storageUsage = 'storage_usage';
  
  // ========================================
  // ANALYTICS & TRACKING
  // ========================================
  
  /// Analytics
  static const String analyticsEnabled = 'analytics_enabled';
  static const String crashReportingEnabled = 'crash_reporting_enabled';
  static const String performanceMonitoring = 'performance_monitoring';
  
  // ========================================
  // ONBOARDING & TUTORIALS
  // ========================================
  
  /// Onboarding
  static const String onboardingCompleted = 'onboarding_completed';
  static const String permissionsOnboardingShown = 'permissions_onboarding_shown';
  static const String tutorialSteps = 'tutorial_steps';
  
  // ========================================
  // ENTERPRISE FEATURES
  // ========================================
  
  /// Enterprise settings
  static const String enterprisePolicy = 'enterprise_policy';
  static const String complianceSettings = 'compliance_settings';
  static const String auditLog = 'audit_log';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Tạo permission key cho specific type
  static String permissionKey(String permissionType) {
    return '$permissionPrefix$permissionType';
  }
  
  /// Tạo user-specific key
  static String userKey(String userId, String key) {
    return 'user_${userId}_$key';
  }
  
  /// Tạo chat-specific key
  static String chatKey(String chatId, String key) {
    return 'chat_${chatId}_$key';
  }
  
  /// Tạo temporary key với timestamp
  static String tempKey(String key) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'temp_${key}_$timestamp';
  }
  
  /// Validate key format
  static bool isValidKey(String key) {
    // Key không được rỗng và không chứa ký tự đặc biệt
    return key.isNotEmpty && 
           !key.contains(' ') && 
           !key.contains('\n') && 
           !key.contains('\t');
  }
  
  /// Lấy tất cả permission keys
  static List<String> getAllPermissionKeys() {
    return [
      '${permissionPrefix}camera',
      '${permissionPrefix}microphone',
      '${permissionPrefix}storage',
      '${permissionPrefix}notification',
      '${permissionPrefix}contacts',
      '${permissionPrefix}location',
      '${permissionPrefix}phone',
      '${permissionPrefix}calendar',
      '${permissionPrefix}sms',
      '${permissionPrefix}biometric',
      '${permissionPrefix}bluetooth',
    ];
  }
  
  /// Lấy tất cả user preference keys
  static List<String> getUserPreferenceKeys() {
    return [
      themeMode,
      languageCode,
      notificationEnabled,
      biometricEnabled,
      autoDownloadMedia,
      mediaQuality,
      analyticsEnabled,
      crashReportingEnabled,
      performanceMonitoring,
    ];
  }
  
  /// Lấy tất cả sensitive keys (cần encryption)
  static List<String> getSensitiveKeys() {
    return [
      accessToken,
      refreshToken,
      userSession,
      enterprisePolicy,
      auditLog,
    ];
  }
  
  /// Lấy tất cả temporary keys pattern
  static List<String> getTempKeyPatterns() {
    return [
      'temp_',
      'cache_',
      'session_',
    ];
  }
  
  /// Check if key is sensitive
  static bool isSensitiveKey(String key) {
    return getSensitiveKeys().any((sensitiveKey) => 
        key.contains(sensitiveKey));
  }
  
  /// Check if key is temporary
  static bool isTempKey(String key) {
    return getTempKeyPatterns().any((pattern) => 
        key.startsWith(pattern));
  }
  
  /// Get key category
  static String getKeyCategory(String key) {
    if (key.startsWith(permissionPrefix)) return 'permissions';
    if (key.startsWith('user_')) return 'user';
    if (key.startsWith('chat_')) return 'chat';
    if (key.startsWith('temp_')) return 'temporary';
    if (getSensitiveKeys().contains(key)) return 'sensitive';
    if (getUserPreferenceKeys().contains(key)) return 'preferences';
    return 'general';
  }
}
