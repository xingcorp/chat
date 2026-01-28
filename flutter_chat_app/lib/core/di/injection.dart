/// Dependency Injection Configuration
/// 
/// Professional DI setup using GetIt + Injectable.
/// Follows Clean Architecture with automatic dependency registration.
/// 
/// Performance Targets:
/// - Startup time: <500ms
/// - Memory usage: <150MB
/// - Zero duplicate registrations
/// 
/// Author: Senior Flutter/Mobile Architect
library injection;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'injection.config.dart';

/// Global service locator instance
/// 
/// Use this to access registered dependencies throughout the app.
/// Example: `final authService = getIt<IAuthService>();`
final GetIt getIt = GetIt.instance;

/// Initialize all dependencies
/// 
/// This must be called before running the app.
/// Registers external dependencies first, then auto-generated ones.
/// 
/// **Performance**: <500ms initialization time
/// **Memory**: <20MB for DI system
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> initializeDependencies() async {
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  logger.i('🚀 Initializing Dependency Injection...');
  final stopwatch = Stopwatch()..start();

  try {
    // Step 1: Register external dependencies
    await _registerExternalDependencies(logger);

    // Step 2: Initialize auto-generated dependencies
    configureDependencies(getIt);

    stopwatch.stop();
    logger.i('✅ DI initialized in ${stopwatch.elapsedMilliseconds}ms');

    // Validate performance
    if (stopwatch.elapsedMilliseconds > 500) {
      logger.w('⚠️ DI initialization took longer than target (500ms)');
    }
  } catch (e, stackTrace) {
    stopwatch.stop();
    logger.e('❌ DI initialization failed', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

/// Register external dependencies that cannot be auto-registered
/// 
/// These are third-party packages that need manual registration:
/// - Logger: For logging throughout the app
/// - SharedPreferences: For local storage
/// - Connectivity: For network status monitoring
Future<void> _registerExternalDependencies(Logger logger) async {
  logger.d('📦 Registering external dependencies...');

  // Logger - required by many services
  if (!getIt.isRegistered<Logger>()) {
    getIt.registerSingleton<Logger>(logger);
  }

  // SharedPreferences - required for local storage
  if (!getIt.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
  }

  // Connectivity - required for network monitoring
  if (!getIt.isRegistered<Connectivity>()) {
    getIt.registerSingleton<Connectivity>(Connectivity());
  }

  logger.d('✅ External dependencies registered');
}

/// Reset DI container (for testing)
/// 
/// **Warning**: Only use this in tests!
/// This will clear all registered dependencies.
@visibleForTesting
Future<void> resetDependencies() async {
  await getIt.reset();
}
