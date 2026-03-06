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

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/main.dart' as main_app;

/// **Staging Main Function**
///
/// Sets the flavor and delegates to [runMainApp] which handles binding
/// initialization, system UI, and [runApp] inside a single [runZonedGuarded]
/// zone — avoiding the "Zone mismatch" warning.
///
/// **Important:** Do NOT call `WidgetsFlutterBinding.ensureInitialized()`
/// or `SystemChrome` methods here. Those require the binding, which must be
/// created inside `runZonedGuarded` (same zone as `runApp`).
Future<void> main() async {
  // FlavorConfig is pure Dart — safe to call before binding init
  FlavorConfig.initializeStaging();

  // Print environment information for debugging
  _printStagingInfo();

  // Launch main app (binding + SystemChrome + runApp all inside runZonedGuarded)
  await main_app.runMainApp();
}

/// Print staging environment information
void _printStagingInfo() {
  final logger = AppLogger();
  logger.info('===== STAGING ENVIRONMENT =====');
  logger.info('App: OXII Chat STG');
  logger.info('Flavor: staging');
  logger.info('Debug Tools: ENABLED');
  logger.info('Mock Data: ENABLED');
  logger.info('===============================');
}
