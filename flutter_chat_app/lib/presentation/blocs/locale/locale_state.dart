part of 'locale_cubit.dart';

/// **ENTERPRISE LOCALE STATE**
///
/// State class for LocaleCubit with performance metrics and advanced features
class LocaleState extends Equatable {
  /// The currently selected locale, or null for system default
  final Locale? locale;

  /// Performance metrics
  final Duration? lastSwitchDuration;
  final DateTime? lastLocaleChange;
  final String? error;

  /// Creates a LocaleState instance with enterprise features
  const LocaleState({
    this.locale,
    this.lastSwitchDuration,
    this.lastLocaleChange,
    this.error,
  });

  /// Creates a copy of this state with updated values
  LocaleState copyWith({
    Locale? locale,
    Duration? lastSwitchDuration,
    DateTime? lastLocaleChange,
    String? error,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      lastSwitchDuration: lastSwitchDuration ?? this.lastSwitchDuration,
      lastLocaleChange: lastLocaleChange ?? this.lastLocaleChange,
      error: error,
    );
  }

  /// Check if locale is RTL
  bool get isRtl {
    if (locale == null) return false;
    return ['ar', 'fa', 'he', 'ur'].contains(locale!.languageCode);
  }

  /// Get effective locale (system default if null)
  Locale get effectiveLocale {
    return locale ?? const Locale('vi');
  }

  /// Check if performance is optimal (<50ms)
  bool get isPerformanceOptimal {
    return lastSwitchDuration == null || lastSwitchDuration!.inMilliseconds <= 50;
  }

  /// Check if there's an error
  bool get hasError => error != null;

  @override
  List<Object?> get props => [
    locale,
    lastSwitchDuration,
    lastLocaleChange,
    error,
  ];

  @override
  String toString() {
    return 'LocaleState('
        'locale: ${locale?.languageCode}, '
        'performance: ${lastSwitchDuration?.inMilliseconds}ms, '
        'error: $error'
        ')';
  }
} 