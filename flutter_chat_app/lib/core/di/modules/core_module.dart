/// Core Module - Manual DI Registration
/// 
/// Registers core infrastructure services that require:
/// - Async initialization (@preResolve)
/// - Complex setup logic
/// - External dependencies
/// 
/// These services are registered manually to avoid overwhelming
/// the Injectable generator and to have fine-grained control.

import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/services/production_logger.dart';
import 'package:flutter_chat_app/core/config/environment_manager.dart';
import 'package:flutter_chat_app/core/services/firebase_service_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Register core infrastructure services
/// 
/// **Order matters**: Services are registered in dependency order.
/// Services registered first can be used by services registered later.
Future<void> registerCoreModule(GetIt getIt) async {
  // 1. Logger - Required by almost all services
  // Already registered in injection.dart
  
  // 2. AppLogger - Wrapper around Logger
  if (!getIt.isRegistered<AppLogger>()) {
    getIt.registerSingleton<AppLogger>(
      AppLogger(),
    );
  }
  
  // 3. ProductionLogger - Production logging
  if (!getIt.isRegistered<ProductionLogger>()) {
    getIt.registerSingleton<ProductionLogger>(
      ProductionLogger(),
    );
  }
  
  // 4. Connectivity - Network monitoring
  // Already registered in injection.dart
  
  // 5. NetworkInfo - Network status checker
  if (!getIt.isRegistered<NetworkInfo>()) {
    getIt.registerLazySingleton<NetworkInfo>(
      () => NetworkInfo(
        connectivity: getIt<Connectivity>(),
        logger: getIt<Logger>(),
      ),
    );
  }
  
  // 6. DatabaseService - Async initialization with @preResolve
  if (!getIt.isRegistered<DatabaseService>()) {
    final databaseService = await DatabaseService.create();
    getIt.registerSingleton<DatabaseService>(databaseService);
  }
  
  // 7. EnvironmentManager - Environment configuration
  if (!getIt.isRegistered<EnvironmentManager>()) {
    getIt.registerSingleton<EnvironmentManager>(
      EnvironmentManager(getIt<Logger>()),
    );
  }
  
  // 8. FirebaseServiceManager - Firebase services
  if (!getIt.isRegistered<FirebaseServiceManager>()) {
    getIt.registerSingleton<FirebaseServiceManager>(
      FirebaseServiceManager(getIt<Logger>()),
    );
  }
}
