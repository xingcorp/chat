import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// **ENTERPRISE PRODUCTION CONFIGURATION**
///
/// Centralized production configuration for enterprise Flutter chat app
/// with environment-specific settings, logging, monitoring, and security.
///
/// **Features:**
/// - Environment-specific configurations
/// - Production logging and monitoring
/// - Security settings and API endpoints
/// - Performance optimization settings
/// - Crash reporting configuration
///
/// **Architecture**: Production-ready configuration management

class ProductionConfig {
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  /// **Current environment**
  static Environment get environment {
    switch (_environment.toLowerCase()) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      case 'development':
        return Environment.development;
      default:
        return Environment.development;
    }
  }

  /// **Is production environment**
  static bool get isProduction => environment == Environment.production;
  
  /// **Is staging environment**
  static bool get isStaging => environment == Environment.staging;
  
  /// **Is development environment**
  static bool get isDevelopment => environment == Environment.development;

  /// **API Configuration**
  static ApiConfig get api {
    switch (environment) {
      case Environment.production:
        return const ApiConfig(
          baseUrl: 'https://api.enterprise-chat.com',
          graphqlEndpoint: 'https://api.enterprise-chat.com/graphql',
          websocketUrl: 'wss://ws.enterprise-chat.com',
          timeout: Duration(seconds: 30),
          retryAttempts: 3,
        );
      case Environment.staging:
        return const ApiConfig(
          baseUrl: 'https://staging-api.enterprise-chat.com',
          graphqlEndpoint: 'https://staging-api.enterprise-chat.com/graphql',
          websocketUrl: 'wss://staging-ws.enterprise-chat.com',
          timeout: Duration(seconds: 30),
          retryAttempts: 3,
        );
      case Environment.development:
        return const ApiConfig(
          baseUrl: 'https://dev-api.enterprise-chat.com',
          graphqlEndpoint: 'https://dev-api.enterprise-chat.com/graphql',
          websocketUrl: 'wss://dev-ws.enterprise-chat.com',
          timeout: Duration(seconds: 15),
          retryAttempts: 2,
        );
    }
  }

  /// **Logging Configuration**
  static LoggingConfig get logging {
    switch (environment) {
      case Environment.production:
        return const LoggingConfig(
          level: Level.warning,
          enableConsoleOutput: false,
          enableFileLogging: true,
          enableRemoteLogging: true,
          maxLogFiles: 5,
          maxLogFileSize: 10 * 1024 * 1024, // 10MB
        );
      case Environment.staging:
        return const LoggingConfig(
          level: Level.info,
          enableConsoleOutput: true,
          enableFileLogging: true,
          enableRemoteLogging: true,
          maxLogFiles: 10,
          maxLogFileSize: 5 * 1024 * 1024, // 5MB
        );
      case Environment.development:
        return const LoggingConfig(
          level: Level.debug,
          enableConsoleOutput: true,
          enableFileLogging: false,
          enableRemoteLogging: false,
          maxLogFiles: 3,
          maxLogFileSize: 1 * 1024 * 1024, // 1MB
        );
    }
  }

  /// **Performance Configuration**
  static PerformanceConfig get performance {
    switch (environment) {
      case Environment.production:
        return const PerformanceConfig(
          enablePerformanceMonitoring: true,
          enableMemoryOptimization: true,
          enableCacheOptimization: true,
          enableNetworkOptimization: true,
          maxMemoryUsageMB: 150,
          maxStartupTimeMs: 2000,
          maxMessageDeliveryMs: 100,
          maxCacheRetrievalMs: 50,
        );
      case Environment.staging:
        return const PerformanceConfig(
          enablePerformanceMonitoring: true,
          enableMemoryOptimization: true,
          enableCacheOptimization: true,
          enableNetworkOptimization: true,
          maxMemoryUsageMB: 200,
          maxStartupTimeMs: 3000,
          maxMessageDeliveryMs: 150,
          maxCacheRetrievalMs: 75,
        );
      case Environment.development:
        return const PerformanceConfig(
          enablePerformanceMonitoring: false,
          enableMemoryOptimization: false,
          enableCacheOptimization: false,
          enableNetworkOptimization: false,
          maxMemoryUsageMB: 300,
          maxStartupTimeMs: 5000,
          maxMessageDeliveryMs: 500,
          maxCacheRetrievalMs: 200,
        );
    }
  }

  /// **Security Configuration**
  static SecurityConfig get security {
    switch (environment) {
      case Environment.production:
        return const SecurityConfig(
          enableSSLPinning: true,
          enableCertificateValidation: true,
          enableEncryption: true,
          enableBiometricAuth: true,
          sessionTimeoutMinutes: 30,
          maxLoginAttempts: 3,
          enableDebugMode: false,
        );
      case Environment.staging:
        return const SecurityConfig(
          enableSSLPinning: true,
          enableCertificateValidation: true,
          enableEncryption: true,
          enableBiometricAuth: true,
          sessionTimeoutMinutes: 60,
          maxLoginAttempts: 5,
          enableDebugMode: false,
        );
      case Environment.development:
        return const SecurityConfig(
          enableSSLPinning: false,
          enableCertificateValidation: false,
          enableEncryption: false,
          enableBiometricAuth: false,
          sessionTimeoutMinutes: 120,
          maxLoginAttempts: 10,
          enableDebugMode: true,
        );
    }
  }

  /// **Analytics Configuration**
  static AnalyticsConfig get analytics {
    switch (environment) {
      case Environment.production:
        return const AnalyticsConfig(
          enableAnalytics: true,
          enableCrashReporting: true,
          enablePerformanceTracking: true,
          enableUserTracking: true,
          sampleRate: 1.0,
        );
      case Environment.staging:
        return const AnalyticsConfig(
          enableAnalytics: true,
          enableCrashReporting: true,
          enablePerformanceTracking: true,
          enableUserTracking: false,
          sampleRate: 0.5,
        );
      case Environment.development:
        return const AnalyticsConfig(
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceTracking: false,
          enableUserTracking: false,
          sampleRate: 0.0,
        );
    }
  }

  /// **Feature Flags**
  static FeatureFlags get features {
    return FeatureFlags(
      enableRealTimeMessaging: true,
      enableVoiceMessages: isProduction || isStaging,
      enableVideoMessages: isProduction || isStaging,
      enableFileSharing: true,
      enableGroupChats: true,
      enableMessageEncryption: isProduction || isStaging,
      enableOfflineMode: true,
      enablePushNotifications: isProduction || isStaging,
      enableBiometricAuth: isProduction || isStaging,
      enableDarkMode: true,
      enableMessageSearch: true,
      enableMessageReactions: isProduction || isStaging,
      enableTypingIndicators: true,
      enableReadReceipts: true,
      enableMessageForwarding: isProduction || isStaging,
      enableChatBackup: isProduction || isStaging,
    );
  }

  /// **Database Configuration**
  static DatabaseConfig get database {
    switch (environment) {
      case Environment.production:
        return const DatabaseConfig(
          enableEncryption: true,
          maxCacheSize: 100 * 1024 * 1024, // 100MB
          enableWAL: true,
          enableForeignKeys: true,
          busyTimeout: Duration(seconds: 30),
        );
      case Environment.staging:
        return const DatabaseConfig(
          enableEncryption: true,
          maxCacheSize: 50 * 1024 * 1024, // 50MB
          enableWAL: true,
          enableForeignKeys: true,
          busyTimeout: Duration(seconds: 15),
        );
      case Environment.development:
        return const DatabaseConfig(
          enableEncryption: false,
          maxCacheSize: 20 * 1024 * 1024, // 20MB
          enableWAL: false,
          enableForeignKeys: true,
          busyTimeout: Duration(seconds: 5),
        );
    }
  }
}

/// **Environment enumeration**
enum Environment {
  development,
  staging,
  production,
}

/// **API Configuration**
class ApiConfig {
  final String baseUrl;
  final String graphqlEndpoint;
  final String websocketUrl;
  final Duration timeout;
  final int retryAttempts;

  const ApiConfig({
    required this.baseUrl,
    required this.graphqlEndpoint,
    required this.websocketUrl,
    required this.timeout,
    required this.retryAttempts,
  });
}

/// **Logging Configuration**
class LoggingConfig {
  final Level level;
  final bool enableConsoleOutput;
  final bool enableFileLogging;
  final bool enableRemoteLogging;
  final int maxLogFiles;
  final int maxLogFileSize;

  const LoggingConfig({
    required this.level,
    required this.enableConsoleOutput,
    required this.enableFileLogging,
    required this.enableRemoteLogging,
    required this.maxLogFiles,
    required this.maxLogFileSize,
  });
}

/// **Performance Configuration**
class PerformanceConfig {
  final bool enablePerformanceMonitoring;
  final bool enableMemoryOptimization;
  final bool enableCacheOptimization;
  final bool enableNetworkOptimization;
  final int maxMemoryUsageMB;
  final int maxStartupTimeMs;
  final int maxMessageDeliveryMs;
  final int maxCacheRetrievalMs;

  const PerformanceConfig({
    required this.enablePerformanceMonitoring,
    required this.enableMemoryOptimization,
    required this.enableCacheOptimization,
    required this.enableNetworkOptimization,
    required this.maxMemoryUsageMB,
    required this.maxStartupTimeMs,
    required this.maxMessageDeliveryMs,
    required this.maxCacheRetrievalMs,
  });
}

/// **Security Configuration**
class SecurityConfig {
  final bool enableSSLPinning;
  final bool enableCertificateValidation;
  final bool enableEncryption;
  final bool enableBiometricAuth;
  final int sessionTimeoutMinutes;
  final int maxLoginAttempts;
  final bool enableDebugMode;

  const SecurityConfig({
    required this.enableSSLPinning,
    required this.enableCertificateValidation,
    required this.enableEncryption,
    required this.enableBiometricAuth,
    required this.sessionTimeoutMinutes,
    required this.maxLoginAttempts,
    required this.enableDebugMode,
  });
}

/// **Analytics Configuration**
class AnalyticsConfig {
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enablePerformanceTracking;
  final bool enableUserTracking;
  final double sampleRate;

  const AnalyticsConfig({
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enablePerformanceTracking,
    required this.enableUserTracking,
    required this.sampleRate,
  });
}

/// **Feature Flags**
class FeatureFlags {
  final bool enableRealTimeMessaging;
  final bool enableVoiceMessages;
  final bool enableVideoMessages;
  final bool enableFileSharing;
  final bool enableGroupChats;
  final bool enableMessageEncryption;
  final bool enableOfflineMode;
  final bool enablePushNotifications;
  final bool enableBiometricAuth;
  final bool enableDarkMode;
  final bool enableMessageSearch;
  final bool enableMessageReactions;
  final bool enableTypingIndicators;
  final bool enableReadReceipts;
  final bool enableMessageForwarding;
  final bool enableChatBackup;

  const FeatureFlags({
    required this.enableRealTimeMessaging,
    required this.enableVoiceMessages,
    required this.enableVideoMessages,
    required this.enableFileSharing,
    required this.enableGroupChats,
    required this.enableMessageEncryption,
    required this.enableOfflineMode,
    required this.enablePushNotifications,
    required this.enableBiometricAuth,
    required this.enableDarkMode,
    required this.enableMessageSearch,
    required this.enableMessageReactions,
    required this.enableTypingIndicators,
    required this.enableReadReceipts,
    required this.enableMessageForwarding,
    required this.enableChatBackup,
  });
}

/// **Database Configuration**
class DatabaseConfig {
  final bool enableEncryption;
  final int maxCacheSize;
  final bool enableWAL;
  final bool enableForeignKeys;
  final Duration busyTimeout;

  const DatabaseConfig({
    required this.enableEncryption,
    required this.maxCacheSize,
    required this.enableWAL,
    required this.enableForeignKeys,
    required this.busyTimeout,
  });
}
