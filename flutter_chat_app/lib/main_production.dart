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

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/main.dart' as main_app;

/// **Production Main Function**
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
  FlavorConfig.initializeProduction();

  // Launch main app (binding + SystemChrome + runApp all inside runZonedGuarded)
  await main_app.runMainApp();
}
