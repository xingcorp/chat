import 'package:flutter/material.dart';

/// Global application configuration
class AppConfig {
  AppConfig._();
  
  /// Application name
  static const String appName = 'Flutter Chat App';
  
  /// API base URL
  static String get apiBaseUrl => const String.fromEnvironment(
    'API_BASE_URL', 
    defaultValue: 'https://api.example.com/v1',
  );
  
  /// Socket server URL
  static String get socketUrl => const String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'wss://socket.example.com',
  );
  
  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('vi', 'VN'),
  ];
  
  /// Connection timeout in milliseconds
  static const int connectionTimeout = 30000;
  
  /// Message fetch limit (pagination)
  static const int messageFetchLimit = 20;
  
  /// Maximum image upload size in bytes (5 MB)
  static const int maxImageUploadSize = 5 * 1024 * 1024;
  
  /// Maximum file upload size in bytes (10 MB)
  static const int maxFileUploadSize = 10 * 1024 * 1024;
  
  /// Default animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  /// Default debounce duration for search
  static const Duration defaultDebounceDuration = Duration(milliseconds: 500);
  
  /// Chat message sync interval
  static const Duration messageSyncInterval = Duration(minutes: 1);
} 