/// **STAGING FLAVOR ENTRY POINT**
///
/// Main entry point cho staging environment với:
/// - Staging-specific configuration
/// - Debug tools enabled
/// - Mock data support
/// - Enhanced logging
/// - Development features
///
/// **Usage:** flutter run --flavor staging --target lib/main_staging.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/main.dart' as main_app;

/// **Staging Main Function**
/// 
/// Initializes staging environment and launches app
Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize staging flavor
  FlavorConfig.initializeStaging();
  
  // Set staging-specific system UI
  await _setupStagingSystemUI();
  
  // Print environment information for debugging
  _printStagingInfo();
  
  // Launch main app with staging configuration
  await main_app.runMainApp();
}

/// Setup staging-specific system UI
Future<void> _setupStagingSystemUI() async {
  // Set staging status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFF9800), // Orange for staging
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFF9800),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations for staging
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft, // Allow landscape in staging
    DeviceOrientation.landscapeRight,
  ]);
}

/// Print staging environment information
void _printStagingInfo() {
  print('🧪 ===== STAGING ENVIRONMENT =====');
  print('📱 App: OXII Chat STG');
  print('🏷️ Flavor: staging');
  print('🔥 Firebase: oxii-chat-staging');
  print('🛠️ Debug Tools: ENABLED');
  print('🧪 Mock Data: ENABLED');
  print('📊 Analytics: ENABLED');
  print('💥 Crashlytics: ENABLED');
  print('⚡ Performance: ENABLED');
  print('🧪 ===============================');
}
