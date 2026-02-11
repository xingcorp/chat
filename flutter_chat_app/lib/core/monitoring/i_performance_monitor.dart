/// Interface for performance monitoring.
///
/// Abstracts performance monitoring so the package can work
/// without Firebase. Host apps can provide their own implementation
/// or use the default no-op [NoOpPerformanceMonitor].
abstract class IPerformanceMonitor {
  /// Initialize performance monitor
  Future<void> initialize();

  /// Start tracing an activity
  Future<void> startTrace(
    TraceType type, {
    String? customTraceName,
    Map<String, String>? attributes,
  });

  /// Stop a trace
  Future<void> stopTrace(
    TraceType type, {
    String? customTraceName,
    Map<String, int>? metrics,
  });

  /// Add metric to active trace
  Future<void> addTraceMetric(
    TraceType type, {
    String? customTraceName,
    required String metricName,
    required int value,
  });

  /// Add attribute to active trace
  Future<void> addTraceAttribute(
    TraceType type, {
    String? customTraceName,
    required String attributeName,
    required String value,
  });

  /// Record custom metric (outside of a trace)
  void recordCustomMetric(String name, double value);

  /// Record custom event
  void recordEvent(String name, {Map<String, dynamic>? parameters});
}

/// Performance trace types
enum TraceType {
  /// App startup
  appStartup,

  /// Loading chat list
  loadChats,

  /// Loading messages
  loadMessages,

  /// Sending messages
  sendMessage,

  /// Media uploads
  uploadMedia,

  /// Loading user profile
  loadUserProfile,

  /// Background data sync
  backgroundSync,

  /// Page loading
  pageLoad,

  /// Screen navigation
  navigation,

  /// Custom trace
  custom,
}

/// No-op implementation for environments without Firebase.
///
/// All methods are safe to call but do nothing.
class NoOpPerformanceMonitor implements IPerformanceMonitor {
  const NoOpPerformanceMonitor();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> startTrace(
    TraceType type, {
    String? customTraceName,
    Map<String, String>? attributes,
  }) async {}

  @override
  Future<void> stopTrace(
    TraceType type, {
    String? customTraceName,
    Map<String, int>? metrics,
  }) async {}

  @override
  Future<void> addTraceMetric(
    TraceType type, {
    String? customTraceName,
    required String metricName,
    required int value,
  }) async {}

  @override
  Future<void> addTraceAttribute(
    TraceType type, {
    String? customTraceName,
    required String attributeName,
    required String value,
  }) async {}

  @override
  void recordCustomMetric(String name, double value) {}

  @override
  void recordEvent(String name, {Map<String, dynamic>? parameters}) {}
}
