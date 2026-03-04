/// **PRODUCTION FLAVOR ENTRY POINT**
///
/// Main entry point cho production environment với:
/// - Production-optimized configuration
/// - Security hardening
/// - Performance optimization
/// - Minimal logging
/// - Release features only
///
/// **Usage:** flutter run --flavor production --target lib/main_production.dart

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/main.dart' as main_app;

/// **Production Main Function**
///
/// Initializes production environment and launches app
Future<void> main() async {
  // Binding needed for SystemChrome calls below; ensureInitialized is idempotent
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize production flavor
  FlavorConfig.initializeProduction();

  // Set production-specific system UI
  await _setupProductionSystemUI();
  
  // Setup production security
  await _setupProductionSecurity();
  
  // Launch main app with production configuration
  await main_app.runMainApp();
}

/// Setup production-specific system UI
Future<void> _setupProductionSystemUI() async {
  // Set production status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF2196F3), // Blue for production
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF2196F3),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations for production (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

/// Setup production security measures
Future<void> _setupProductionSecurity() async {
  // Disable debug banner in production
  // This is handled in main app
  
  // Setup secure storage
  // SecureStorage.initialize();
  
  // Setup certificate pinning
  // CertificatePinning.initialize();
  
  // Setup root detection
  // RootDetection.initialize();
  
  // Setup jailbreak detection
  // JailbreakDetection.initialize();
}
