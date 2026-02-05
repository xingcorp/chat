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
import 'package:isar/isar.dart';
import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart' as core_graphql;
import 'package:flutter_chat_app/core/network/socket_rate_limiter.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/network/cache/api_cache_manager.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/message/message_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/media/media_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/media/media_remote_datasource.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/core/services/production_logger.dart';
import 'package:flutter_chat_app/core/config/environment_manager.dart';
import 'package:flutter_chat_app/core/services/firebase_service_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 2.1 ApiCacheManager - API cache layer
  if (!getIt.isRegistered<ApiCacheManager>()) {
    await ApiCacheManager.init(
      logger: getIt<AppLogger>(),
      prefs: getIt<SharedPreferences>(),
    );
    getIt.registerSingleton<ApiCacheManager>(ApiCacheManager.instance);
  }

  if (!getIt.isRegistered<AppCacheManager>()) {
    final appCacheManager = AppCacheManager();
    await appCacheManager.initialize();
    getIt.registerSingleton<AppCacheManager>(appCacheManager);
  }

  if (!getIt.isRegistered<core_graphql.GraphQLClientWrapper>()) {
    getIt.registerLazySingleton<core_graphql.GraphQLClientWrapper>(
      () => getIt<core_graphql.GraphQLClientWrapperImpl>(),
    );
  }

  if (!getIt.isRegistered<MessageLocalDataSource>()) {
    getIt.registerLazySingleton<MessageLocalDataSource>(
      () => MessageLocalDataSourceImpl(getIt<LocalStorage>()),
    );
  }

  if (!getIt.isRegistered<IMessageRemoteDataSource>()) {
    getIt.registerLazySingleton<IMessageRemoteDataSource>(
      () => getIt<MessageRemoteDataSourceImpl>(),
    );
  }

  if (!getIt.isRegistered<ChatLocalDataSource>()) {
    getIt.registerLazySingleton<ChatLocalDataSource>(
      () => getIt<ChatLocalDataSourceImpl>(),
    );
  }

  if (!getIt.isRegistered<IMediaLocalDataSource>()) {
    getIt.registerLazySingleton<IMediaLocalDataSource>(
      () => getIt<MediaLocalDataSourceImpl>(),
    );
  }

  if (!getIt.isRegistered<IMediaRemoteDataSource>()) {
    getIt.registerLazySingleton<IMediaRemoteDataSource>(
      () => getIt<MediaRemoteDataSourceImpl>(),
    );
  }

  // 3. ProductionLogger - Production logging
  if (!getIt.isRegistered<ProductionLogger>()) {
    getIt.registerSingleton<ProductionLogger>(
      ProductionLogger(),
    );
  }

  if (!getIt.isRegistered<DeviceCapabilityService>()) {
    getIt.registerSingleton<DeviceCapabilityService>(
      DeviceCapabilityService(),
    );
  }

  if (!getIt.isRegistered<SocketRateLimiter>()) {
    getIt.registerSingleton<SocketRateLimiter>(
      SocketRateLimiter(logger: getIt<Logger>()),
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

  if (!getIt.isRegistered<INetworkInfo>()) {
    getIt.registerLazySingleton<INetworkInfo>(() => getIt<NetworkInfo>());
  }
  
  // 6. DatabaseService - Async initialization with @preResolve
  if (!getIt.isRegistered<DatabaseService>()) {
    final databaseService = await DatabaseService.create();
    getIt.registerSingleton<DatabaseService>(databaseService);
    if (!getIt.isRegistered<Isar>()) {
      getIt.registerSingleton<Isar>(databaseService.isar);
    }
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
