/// **ENTERPRISE FLAVOR CONFIGURATION SYSTEM**
///
/// Multi-environment support cho staging và production với:
/// - Type-safe environment configuration
/// - API endpoint management
/// - Feature flag system
/// - Debug/release mode handling
/// - Firebase project switching
///
/// **Architecture:** Clean Architecture + Environment Abstraction + Enterprise Standards

import 'package:flutter/foundation.dart';

/// **Flavor Types**
/// 
/// Defines available application flavors
enum FlavorType {
  staging('staging', 'STG'),
  production('production', 'PROD');

  const FlavorType(this.name, this.shortName);
  
  final String name;
  final String shortName;
  
  /// Check if current flavor is production
  bool get isProduction => this == FlavorType.production;
  
  /// Check if current flavor is staging
  bool get isStaging => this == FlavorType.staging;
  
  /// Check if debug features should be enabled
  bool get enableDebugFeatures => this == FlavorType.staging || kDebugMode;
}

/// **Environment Configuration**
/// 
/// Contains all environment-specific settings
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.firebaseProjectId,
    required this.enableAnalytics,
    required this.enableCrashlytics,
    required this.enablePerformanceMonitoring,
    required this.logLevel,
    required this.cacheTimeout,
    required this.requestTimeout,
    required this.maxRetryAttempts,
    required this.enableMockData,
    required this.enableDebugTools,
    required this.enableFeatureFlags,
    this.customHeaders = const {},
  });

  // API Configuration
  final String apiBaseUrl;
  final String websocketUrl;
  final Map<String, String> customHeaders;
  
  // Firebase Configuration
  final String firebaseProjectId;
  
  // Monitoring Configuration
  final bool enableAnalytics;
  final bool enableCrashlytics;
  final bool enablePerformanceMonitoring;
  
  // Debug Configuration
  final String logLevel;
  final bool enableMockData;
  final bool enableDebugTools;
  final bool enableFeatureFlags;
  
  // Network Configuration
  final Duration cacheTimeout;
  final Duration requestTimeout;
  final int maxRetryAttempts;
  
  /// Create staging configuration
  factory EnvironmentConfig.staging() => const EnvironmentConfig(
    apiBaseUrl: 'https://api-staging.oxii.chat',
    websocketUrl: 'wss://ws-staging.oxii.chat',
    firebaseProjectId: 'common-stag',
    enableAnalytics: true,
    enableCrashlytics: true,
    enablePerformanceMonitoring: true,
    logLevel: 'DEBUG',
    cacheTimeout: Duration(minutes: 5),
    requestTimeout: Duration(seconds: 30),
    maxRetryAttempts: 3,
    enableMockData: true,
    enableDebugTools: true,
    enableFeatureFlags: true,
    customHeaders: {
      'X-Environment': 'staging',
      'X-Debug-Mode': 'true',
    },
  );
  
  /// Create production configuration
  factory EnvironmentConfig.production() => const EnvironmentConfig(
    apiBaseUrl: 'https://oxii-office-api.oxiitek.com',
    websocketUrl: 'wss://oxii-office-api.oxiitek.com',
    firebaseProjectId: 'common-18e05',
    enableAnalytics: true,
    enableCrashlytics: true,
    enablePerformanceMonitoring: true,
    logLevel: 'ERROR',
    cacheTimeout: Duration(minutes: 30),
    requestTimeout: Duration(seconds: 15),
    maxRetryAttempts: 2,
    enableMockData: false,
    enableDebugTools: false,
    enableFeatureFlags: false,
    customHeaders: {
      'X-Environment': 'production',
    },
  );
}

/// **Feature Flags Configuration**
/// 
/// Manages feature toggles per environment
class FeatureFlags {
  const FeatureFlags({
    required this.enableNewChatUI,
    required this.enableVoiceMessages,
    required this.enableVideoCall,
    required this.enableGroupChat,
    required this.enableFileSharing,
    required this.enableLocationSharing,
    required this.enableMessageReactions,
    required this.enableMessageForwarding,
    required this.enableChatBackup,
    required this.enableEndToEndEncryption,
    required this.enableBiometricAuth,
    required this.enableDarkMode,
    required this.enableNotificationScheduling,
    required this.enableOfflineMode,
    required this.enableAdvancedSearch,
  });

  // UI Features
  final bool enableNewChatUI;
  final bool enableDarkMode;
  
  // Communication Features
  final bool enableVoiceMessages;
  final bool enableVideoCall;
  final bool enableGroupChat;
  final bool enableFileSharing;
  final bool enableLocationSharing;
  final bool enableMessageReactions;
  final bool enableMessageForwarding;
  
  // Advanced Features
  final bool enableChatBackup;
  final bool enableEndToEndEncryption;
  final bool enableBiometricAuth;
  final bool enableNotificationScheduling;
  final bool enableOfflineMode;
  final bool enableAdvancedSearch;
  
  /// Staging feature flags - Enable all features for testing
  factory FeatureFlags.staging() => const FeatureFlags(
    enableNewChatUI: true,
    enableVoiceMessages: true,
    enableVideoCall: true,
    enableGroupChat: true,
    enableFileSharing: true,
    enableLocationSharing: true,
    enableMessageReactions: true,
    enableMessageForwarding: true,
    enableChatBackup: true,
    enableEndToEndEncryption: true,
    enableBiometricAuth: true,
    enableDarkMode: true,
    enableNotificationScheduling: true,
    enableOfflineMode: true,
    enableAdvancedSearch: true,
  );
  
  /// Production feature flags - Conservative approach
  factory FeatureFlags.production() => const FeatureFlags(
    enableNewChatUI: true,
    enableVoiceMessages: true,
    enableVideoCall: false, // Not ready for production
    enableGroupChat: true,
    enableFileSharing: true,
    enableLocationSharing: true,
    enableMessageReactions: true,
    enableMessageForwarding: true,
    enableChatBackup: true,
    enableEndToEndEncryption: true,
    enableBiometricAuth: true,
    enableDarkMode: true,
    enableNotificationScheduling: false, // Beta feature
    enableOfflineMode: true,
    enableAdvancedSearch: false, // Performance testing needed
  );
}

/// **Main Flavor Configuration**
/// 
/// Central configuration manager for the application
class FlavorConfig {
  FlavorConfig._({
    required this.flavor,
    required this.environment,
    required this.features,
  });

  final FlavorType flavor;
  final EnvironmentConfig environment;
  final FeatureFlags features;
  
  static FlavorConfig? _instance;
  
  /// Get current flavor configuration
  static FlavorConfig get instance {
    assert(_instance != null, 'FlavorConfig must be initialized first');
    return _instance!;
  }
  
  /// Check if flavor is initialized
  static bool get isInitialized => _instance != null;
  
  /// Initialize staging flavor
  static void initializeStaging() {
    _instance = FlavorConfig._(
      flavor: FlavorType.staging,
      environment: EnvironmentConfig.staging(),
      features: FeatureFlags.staging(),
    );
  }
  
  /// Initialize production flavor
  static void initializeProduction() {
    _instance = FlavorConfig._(
      flavor: FlavorType.production,
      environment: EnvironmentConfig.production(),
      features: FeatureFlags.production(),
    );
  }
  
  /// Initialize from environment variable
  static void initializeFromEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'staging');
    
    switch (flavor.toLowerCase()) {
      case 'production':
      case 'prod':
        initializeProduction();
        break;
      case 'staging':
      case 'stg':
      default:
        initializeStaging();
        break;
    }
  }
  
  // Convenience getters
  bool get isProduction => flavor.isProduction;
  bool get isStaging => flavor.isStaging;
  bool get enableDebugFeatures => flavor.enableDebugFeatures;
  
  String get appName => isProduction ? 'OXII Chat' : 'OXII Chat ${flavor.shortName}';
  String get packageSuffix => isProduction ? '' : '.${flavor.name}';
  
  @override
  String toString() => 'FlavorConfig(${flavor.name})';
}

/// **Flavor Utilities**
/// 
/// Helper functions for flavor-specific operations
class FlavorUtils {
  FlavorUtils._();
  
  /// Get app display name with flavor suffix
  static String getAppDisplayName() {
    final config = FlavorConfig.instance;
    return config.appName;
  }
  
  /// Get package name with flavor suffix
  static String getPackageName(String basePackage) {
    final config = FlavorConfig.instance;
    return '$basePackage${config.packageSuffix}';
  }
  
  /// Check if feature is enabled
  static bool isFeatureEnabled(bool Function(FeatureFlags) featureGetter) {
    final config = FlavorConfig.instance;
    return featureGetter(config.features);
  }
  
  /// Get environment-specific asset path
  static String getAssetPath(String assetName) {
    final config = FlavorConfig.instance;
    final flavorPrefix = config.isProduction ? '' : '${config.flavor.name}/';
    return 'assets/${flavorPrefix}$assetName';
  }
  
  /// Get flavor-specific color scheme
  static Map<String, dynamic> getFlavorColors() {
    final config = FlavorConfig.instance;
    
    if (config.isProduction) {
      return {
        'primary': 0xFF2196F3,
        'accent': 0xFF03DAC6,
        'background': 0xFFFFFFFF,
      };
    } else {
      return {
        'primary': 0xFFFF9800, // Orange for staging
        'accent': 0xFF4CAF50,
        'background': 0xFFFFF3E0,
      };
    }
  }
}
