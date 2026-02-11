/// Abstract interface for analytics tracking.
///
/// Business logic depends on this interface, not on Firebase directly.
/// In standalone mode, [AnalyticsService] (Firebase-backed) is used.
/// In package mode, host app can provide its own implementation via [ChatConfig],
/// or [NoOpAnalyticsService] is used as default.
abstract class IAnalyticsService {
  /// Initialize the analytics service.
  Future<void> initialize();

  /// Set the user ID for the current session.
  Future<void> setUserId(String userId);

  /// Set user properties.
  Future<void> setUserProperties({
    String? email,
    String? displayName,
    String? role,
    Map<String, dynamic>? customProperties,
  });

  /// Log an analytics event with optional parameters.
  Future<void> logEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
    String? customEventName,
  });

  /// Track a custom event with name and parameters.
  Future<void> track(String eventName, Map<String, dynamic> parameters);

  /// Log a screen view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? additionalParams,
  });

  /// Log an error event.
  Future<void> logError({
    required String errorType,
    String? errorMessage,
    String? errorDetails,
    bool fatal = false,
  });

  /// Track a value metric.
  Future<void> trackValueMetric({
    required String metricName,
    required double value,
    Map<String, dynamic>? dimensions,
  });

  /// Reset analytics data (e.g., on logout).
  Future<void> resetAnalyticsData();

  /// Enable or disable analytics collection.
  Future<void> setAnalyticsEnabled(bool enabled);
}

/// Analytics events tracked by the chat module.
enum AnalyticsEvent {
  login,
  signup,
  logout,
  createChat,
  joinChat,
  leaveChat,
  inviteUser,
  sendMessage,
  loadMessages,
  openChat,
  viewUserProfile,
  search,
  downloadFile,
  uploadFile,
  initiateCall,
  answerCall,
  endCall,
  custom,
}

/// No-op implementation for environments without analytics.
///
/// Used as default in package mode when host app doesn't provide
/// an analytics service via [ChatConfig].
class NoOpAnalyticsService implements IAnalyticsService {
  const NoOpAnalyticsService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> setUserProperties({
    String? email,
    String? displayName,
    String? role,
    Map<String, dynamic>? customProperties,
  }) async {}

  @override
  Future<void> logEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
    String? customEventName,
  }) async {}

  @override
  Future<void> track(String eventName, Map<String, dynamic> parameters) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? additionalParams,
  }) async {}

  @override
  Future<void> logError({
    required String errorType,
    String? errorMessage,
    String? errorDetails,
    bool fatal = false,
  }) async {}

  @override
  Future<void> trackValueMetric({
    required String metricName,
    required double value,
    Map<String, dynamic>? dimensions,
  }) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {}
}
