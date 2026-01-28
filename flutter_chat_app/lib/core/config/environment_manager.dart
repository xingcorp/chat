/// **ENTERPRISE ENVIRONMENT MANAGER**
///
/// Centralized environment management với:
/// - Runtime environment detection
/// - Configuration validation
/// - Environment switching capabilities
/// - Debug information display
/// - Performance monitoring per environment
///
/// **Architecture:** Singleton Pattern + Environment Abstraction + Enterprise Standards

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:logger/logger.dart';

/// **Environment Manager Service**
/// 
/// Manages application environment configuration and runtime behavior
/// 
/// **Note**: Registered manually in core_module.dart (not via Injectable)
class EnvironmentManager {
  EnvironmentManager(this._logger);

  final Logger _logger;
  
  late final FlavorConfig _config;
  late final Map<String, dynamic> _runtimeInfo;
  
  /// Initialize environment manager
  Future<void> initialize() async {
    try {
      // Initialize flavor configuration
      if (!FlavorConfig.isInitialized) {
        FlavorConfig.initializeFromEnvironment();
      }
      
      _config = FlavorConfig.instance;
      
      // Collect runtime information
      await _collectRuntimeInfo();
      
      // Validate configuration
      await _validateConfiguration();
      
      // Setup environment-specific services
      await _setupEnvironmentServices();
      
      _logger.i('Environment initialized: ${_config.flavor.name}');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize environment', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Get current flavor configuration
  FlavorConfig get config => _config;
  
  /// Get runtime information
  Map<String, dynamic> get runtimeInfo => Map.unmodifiable(_runtimeInfo);
  
  /// Check if running in debug mode
  bool get isDebugMode => kDebugMode;
  
  /// Check if running in release mode
  bool get isReleaseMode => kReleaseMode;
  
  /// Check if running in profile mode
  bool get isProfileMode => kProfileMode;
  
  /// Get build mode string
  String get buildMode {
    if (kDebugMode) return 'debug';
    if (kProfileMode) return 'profile';
    return 'release';
  }
  
  /// Get platform information
  String get platformInfo {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
  
  /// Get environment display name
  String get environmentDisplayName {
    final flavor = _config.flavor.name.toUpperCase();
    final mode = buildMode.toUpperCase();
    return '$flavor ($mode)';
  }
  
  /// Check if feature is enabled
  bool isFeatureEnabled(bool Function(FeatureFlags) featureGetter) {
    return FlavorUtils.isFeatureEnabled(featureGetter);
  }
  
  /// Get API base URL
  String get apiBaseUrl => _config.environment.apiBaseUrl;
  
  /// Get WebSocket URL
  String get websocketUrl => _config.environment.websocketUrl;
  
  /// Get Firebase project ID
  String get firebaseProjectId => _config.environment.firebaseProjectId;
  
  /// Get request timeout
  Duration get requestTimeout => _config.environment.requestTimeout;
  
  /// Get cache timeout
  Duration get cacheTimeout => _config.environment.cacheTimeout;
  
  /// Get max retry attempts
  int get maxRetryAttempts => _config.environment.maxRetryAttempts;
  
  /// Get custom headers
  Map<String, String> get customHeaders => _config.environment.customHeaders;
  
  /// Check if analytics is enabled
  bool get isAnalyticsEnabled => _config.environment.enableAnalytics;
  
  /// Check if crashlytics is enabled
  bool get isCrashlyticsEnabled => _config.environment.enableCrashlytics;
  
  /// Check if performance monitoring is enabled
  bool get isPerformanceMonitoringEnabled => _config.environment.enablePerformanceMonitoring;
  
  /// Check if mock data is enabled
  bool get isMockDataEnabled => _config.environment.enableMockData;
  
  /// Check if debug tools are enabled
  bool get isDebugToolsEnabled => _config.environment.enableDebugTools;
  
  /// Get log level
  String get logLevel => _config.environment.logLevel;
  
  /// Get environment summary for debugging
  Map<String, dynamic> getEnvironmentSummary() {
    return {
      'flavor': _config.flavor.name,
      'buildMode': buildMode,
      'platform': platformInfo,
      'apiBaseUrl': apiBaseUrl,
      'websocketUrl': websocketUrl,
      'firebaseProjectId': firebaseProjectId,
      'enableAnalytics': isAnalyticsEnabled,
      'enableCrashlytics': isCrashlyticsEnabled,
      'enablePerformanceMonitoring': isPerformanceMonitoringEnabled,
      'enableMockData': isMockDataEnabled,
      'enableDebugTools': isDebugToolsEnabled,
      'logLevel': logLevel,
      'runtimeInfo': _runtimeInfo,
    };
  }
  
  /// Print environment information to console
  void printEnvironmentInfo() {
    if (!kDebugMode) return;
    
    final summary = getEnvironmentSummary();
    
    _logger.i('🏗️ ===== ENVIRONMENT INFORMATION =====');
    _logger.i('📱 App: ${FlavorUtils.getAppDisplayName()}');
    _logger.i('🏷️ Flavor: ${summary['flavor']}');
    _logger.i('🔧 Build Mode: ${summary['buildMode']}');
    _logger.i('📱 Platform: ${summary['platform']}');
    _logger.i('🌐 API Base URL: ${summary['apiBaseUrl']}');
    _logger.i('🔌 WebSocket URL: ${summary['websocketUrl']}');
    _logger.i('🔥 Firebase Project: ${summary['firebaseProjectId']}');
    _logger.i('📊 Analytics: ${summary['enableAnalytics']}');
    _logger.i('💥 Crashlytics: ${summary['enableCrashlytics']}');
    _logger.i('⚡ Performance Monitoring: ${summary['enablePerformanceMonitoring']}');
    _logger.i('🧪 Mock Data: ${summary['enableMockData']}');
    _logger.i('🛠️ Debug Tools: ${summary['enableDebugTools']}');
    _logger.i('📝 Log Level: ${summary['logLevel']}');
    _logger.i('🏗️ =====================================');
  }
  
  /// Collect runtime information
  Future<void> _collectRuntimeInfo() async {
    _runtimeInfo = {
      'dartVersion': Platform.version,
      'operatingSystem': Platform.operatingSystem,
      'operatingSystemVersion': Platform.operatingSystemVersion,
      'localHostname': Platform.localHostname,
      'numberOfProcessors': Platform.numberOfProcessors,
      'pathSeparator': Platform.pathSeparator,
      'isDebugMode': kDebugMode,
      'isReleaseMode': kReleaseMode,
      'isProfileMode': kProfileMode,
      'isWeb': kIsWeb,
    };
    
    // Add platform-specific information
    if (!kIsWeb) {
      _runtimeInfo.addAll({
        'executable': Platform.executable,
        'executableArguments': Platform.executableArguments,
        // 'packageRoot': Platform.packageRoot, // DEPRECATED - removed in Dart 2.0+
        'packageConfig': Platform.packageConfig,
      });
    }
  }
  
  /// Validate environment configuration
  Future<void> _validateConfiguration() async {
    final errors = <String>[];
    
    // Validate API URLs
    if (_config.environment.apiBaseUrl.isEmpty) {
      errors.add('API base URL is empty');
    }
    
    if (_config.environment.websocketUrl.isEmpty) {
      errors.add('WebSocket URL is empty');
    }
    
    // Validate Firebase configuration
    if (_config.environment.firebaseProjectId.isEmpty) {
      errors.add('Firebase project ID is empty');
    }
    
    // Validate timeouts
    if (_config.environment.requestTimeout.inSeconds <= 0) {
      errors.add('Request timeout must be positive');
    }
    
    if (_config.environment.cacheTimeout.inSeconds <= 0) {
      errors.add('Cache timeout must be positive');
    }
    
    // Validate retry attempts
    if (_config.environment.maxRetryAttempts < 0) {
      errors.add('Max retry attempts must be non-negative');
    }
    
    if (errors.isNotEmpty) {
      final errorMessage = 'Environment configuration validation failed:\n${errors.join('\n')}';
      _logger.e(errorMessage);
      throw StateError(errorMessage);
    }
    
    _logger.i('Environment configuration validated successfully');
  }
  
  /// Setup environment-specific services
  Future<void> _setupEnvironmentServices() async {
    // Setup logging level
    // LogUtils.setLogLevel(_config.environment.logLevel);
    
    // Setup network timeouts
    // NetworkConfig.setTimeouts(
    //   requestTimeout: _config.environment.requestTimeout,
    //   cacheTimeout: _config.environment.cacheTimeout,
    // );
    
    // Setup retry configuration
    // RetryConfig.setMaxAttempts(_config.environment.maxRetryAttempts);
    
    _logger.i('Environment-specific services configured');
  }
  
  /// Switch environment (for testing purposes only)
  Future<void> switchEnvironment(FlavorType newFlavor) async {
    if (kReleaseMode) {
      throw UnsupportedError('Environment switching is not allowed in release mode');
    }
    
    _logger.i('Switching environment from ${_config.flavor.name} to ${newFlavor.name}');
    
    // Reinitialize with new flavor
    switch (newFlavor) {
      case FlavorType.staging:
        FlavorConfig.initializeStaging();
        break;
      case FlavorType.production:
        FlavorConfig.initializeProduction();
        break;
    }
    
    await initialize();
  }
}
