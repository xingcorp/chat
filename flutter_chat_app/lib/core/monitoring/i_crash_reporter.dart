/// Abstract interface for crash reporting.
///
/// Business logic depends on this interface, not on Firebase directly.
/// In standalone mode, [CrashReporter] (Firebase-backed) is used.
/// In package mode, host app can provide its own implementation via [ChatConfig],
/// or [NoOpCrashReporter] is used as default.
abstract class ICrashReporter {
  /// Initialize the crash reporter.
  Future<void> initialize();

  /// Record an error with optional reason and additional data.
  Future<void> recordError(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
  });

  /// Set the user identifier for the current session.
  Future<void> setUserIdentifier(String userId);

  /// Set a custom key-value pair for crash reports.
  Future<void> setCustomKey(String key, dynamic value);

  /// Log a message to the crash reporter.
  Future<void> log(String message);
}

/// No-op implementation for environments without crash reporting.
///
/// Used as default in package mode when host app doesn't provide
/// a crash reporter via [ChatConfig].
class NoOpCrashReporter implements ICrashReporter {
  const NoOpCrashReporter();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {}

  @override
  Future<void> setUserIdentifier(String userId) async {}

  @override
  Future<void> setCustomKey(String key, dynamic value) async {}

  @override
  Future<void> log(String message) async {}
}
