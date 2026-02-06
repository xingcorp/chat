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
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_chat_app/core/network/connectivity/connectivity_service.dart'
    as net_connectivity;
import 'package:flutter_chat_app/core/error/retry_config.dart' as app_retry;
import 'package:flutter_chat_app/core/network/auth/token_repository.dart'
    as token_module;
import 'package:flutter_chat_app/core/config/firebase_config.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart' as core_graphql;
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/network/http/dio_http_client.dart';
import 'package:flutter_chat_app/core/network/http/http_client_interface.dart';
import 'package:flutter_chat_app/core/network/realtime/connection_pool_manager.dart';
import 'package:flutter_chat_app/core/network/realtime/enhanced_realtime_connection_service.dart';
import 'package:flutter_chat_app/core/network/realtime/models/realtime_connection_config.dart'
    as realtime_models;
import 'package:flutter_chat_app/core/network/realtime/realtime_connection_service.dart'
    as realtime;
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/data/services/graphql/graphql_client_wrapper.dart'
    as legacy_graphql;
import 'package:flutter_chat_app/features/auth/data/datasources/auth/auth_remote_datasource.dart'
    as auth_ds;

import 'injection.config.dart';
import 'modules/core_module.dart';

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
Future<void> configureDependencies() async {
  getIt.allowReassignment = true;

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

    // Step 2: Register core module (manual registration)
    await registerCoreModule(getIt);

    // Step 3: Initialize auto-generated dependencies (feature services)
    getIt.init();

    if (!getIt.isRegistered<auth_ds.AuthRemoteDataSource>()) {
      getIt.registerLazySingleton<auth_ds.AuthRemoteDataSource>(
        () => getIt<auth_ds.AuthRemoteDataSourceImpl>(),
      );
    }

    if (getIt.isRegistered<core_graphql.GraphQLClientWrapperImpl>()) {
      await getIt.unregister<core_graphql.GraphQLClientWrapperImpl>();
    }

    if (getIt.isRegistered<core_graphql.GraphQLClientWrapper>()) {
      await getIt.unregister<core_graphql.GraphQLClientWrapper>();
    }

    getIt.registerLazySingleton<core_graphql.GraphQLClientWrapperImpl>(
      () => core_graphql.GraphQLClientWrapperImpl(
        getIt<GraphQLClient>(),
        getIt<NetworkInfo>(),
        getIt<token_module.TokenRepository>(),
      ),
    );

    getIt.registerLazySingleton<core_graphql.GraphQLClientWrapper>(
      () => getIt<core_graphql.GraphQLClientWrapperImpl>(),
    );

    if (!getIt.isRegistered<IHttpClient>()) {
      getIt.registerLazySingleton<IHttpClient>(() => getIt<DioHttpClient>());
    }

    if (!getIt.isRegistered<net_connectivity.IConnectivityService>()) {
      getIt.registerLazySingleton<net_connectivity.IConnectivityService>(
          () => getIt<net_connectivity.ConnectivityServiceImpl>());
    }

    if (!getIt.isRegistered<realtime.IRealtimeConnectionService>()) {
      getIt.registerLazySingleton<realtime.IRealtimeConnectionService>(
          () => getIt<EnhancedRealtimeConnectionService>());
    }

    if (!getIt.isRegistered<INetworkInfo>()) {
      getIt.registerLazySingleton<INetworkInfo>(() => getIt<NetworkInfo>());
    }

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

  if (!getIt.isRegistered<SecureStorage>()) {
    getIt.registerSingleton<SecureStorage>(SecureStorageImpl());
  }

  if (!getIt.isRegistered<token_module.TokenStorage>()) {
    getIt.registerSingleton<token_module.TokenStorage>(
      token_module.SecureTokenStorage(getIt<SecureStorage>()),
    );
  }

  if (!getIt.isRegistered<token_module.TokenRepository>()) {
    getIt.registerSingleton<token_module.TokenRepository>(
      token_module.TokenRepositoryImpl(
        tokenStorage: getIt<token_module.TokenStorage>(),
        prefs: getIt<SharedPreferences>(),
        refreshAccessToken: () => getIt<auth_ds.AuthRemoteDataSource>().refreshToken(),
      ),
    );
  }

  await getIt<token_module.TokenRepository>().initialize();

  // Connectivity - required for network monitoring
  if (!getIt.isRegistered<Connectivity>()) {
    getIt.registerSingleton<Connectivity>(Connectivity());
  }

  // HTTP Client - required for API calls
  if (!getIt.isRegistered<http.Client>()) {
    getIt.registerLazySingleton<http.Client>(() => http.Client());
  }

  // Base URL - required for API endpoints
  if (!getIt.isRegistered<String>(instanceName: 'baseUrl')) {
    final apiBaseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final baseUrl = apiBaseUrl.isNotEmpty
        ? apiBaseUrl
        : const String.fromEnvironment(
            'BASE_URL',
            defaultValue: 'http://localhost:5000',
          );
    getIt.registerSingleton<String>(baseUrl, instanceName: 'baseUrl');
  }

  final apiBaseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
  final graphQlApiUrlRaw = (dotenv.env['GRAPHQL_API_URL'] ?? '').trim();
  final graphQlWsUrlRaw = (dotenv.env['GRAPHQL_WS_URL'] ?? '').trim();
  final socketUrlRaw =
      (dotenv.env['SOCKET_URL'] ?? dotenv.env['WEBSOCKET_URL'] ?? '').trim();

  final graphQlApiUrl = graphQlApiUrlRaw.isNotEmpty
      ? graphQlApiUrlRaw
      : (apiBaseUrl.isNotEmpty ? '$apiBaseUrl/graphql' : 'http://localhost:3000/graphql');
  final graphQlWsUrl = graphQlWsUrlRaw.isNotEmpty
      ? graphQlWsUrlRaw
      : (socketUrlRaw.isNotEmpty ? '$socketUrlRaw/graphql' : 'ws://localhost:3000/graphql');
  final socketUrl = socketUrlRaw.isNotEmpty
      ? socketUrlRaw
      : 'ws://localhost:3000';

  if (!getIt.isRegistered<String>(instanceName: 'socketUrl')) {
    getIt.registerSingleton<String>(socketUrl, instanceName: 'socketUrl');
  }

  if (!getIt.isRegistered<String>(instanceName: 'graphQlApiUrl')) {
    getIt.registerSingleton<String>(graphQlApiUrl, instanceName: 'graphQlApiUrl');
  }

  if (!getIt.isRegistered<String>(instanceName: 'graphQlWsUrl')) {
    getIt.registerSingleton<String>(graphQlWsUrl, instanceName: 'graphQlWsUrl');
  }

  if (!getIt.isRegistered<Map<String, dynamic>>()) {
    getIt.registerSingleton<Map<String, dynamic>>(<String, dynamic>{});
  }

  if (!getIt.isRegistered<app_retry.RetryConfig>()) {
    getIt.registerSingleton<app_retry.RetryConfig>(app_retry.RetryConfig.realtime);
  }

  if (kIsWeb && !FirebaseConfigManager.isInitialized) {
    await FirebaseConfigManager.initialize();
  }

  if (!getIt.isRegistered<FirebasePerformance>()) {
    getIt.registerLazySingleton<FirebasePerformance>(
        () => FirebasePerformance.instance);
  }

  if (!getIt.isRegistered<FirebaseAnalytics>()) {
    getIt.registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance);
  }

  if (!getIt.isRegistered<FirebaseCrashlytics>()) {
    getIt.registerLazySingleton<FirebaseCrashlytics>(
        () => FirebaseCrashlytics.instance);
  }

  if (!getIt.isRegistered<int>(instanceName: 'connectionPoolMaxPoolSize')) {
    getIt.registerSingleton<int>(5, instanceName: 'connectionPoolMaxPoolSize');
  }

  if (!getIt.isRegistered<int>(instanceName: 'connectionPoolMaxConnectionLifetime')) {
    getIt.registerSingleton<int>(3600000,
        instanceName: 'connectionPoolMaxConnectionLifetime');
  }

  if (!getIt.isRegistered<int>(instanceName: 'connectionPoolMaxIdleTime')) {
    getIt.registerSingleton<int>(600000,
        instanceName: 'connectionPoolMaxIdleTime');
  }

  if (!getIt.isRegistered<int>(instanceName: 'connectionPoolCleanupInterval')) {
    getIt.registerSingleton<int>(60000,
        instanceName: 'connectionPoolCleanupInterval');
  }

  if (!getIt.isRegistered<int>(instanceName: 'connectionPoolHealthCheckInterval')) {
    getIt.registerSingleton<int>(30000,
        instanceName: 'connectionPoolHealthCheckInterval');
  }

  if (!getIt.isRegistered<ConnectionFactory>()) {
    getIt.registerSingleton<ConnectionFactory>(
        () async => getIt<realtime.IRealtimeConnectionService>());
  }

  if (!getIt.isRegistered<GraphQLClient>()) {
    final client = await core_graphql.GraphQLClientWrapperImpl.createClient(
      accessTokenProvider:
          () => getIt<token_module.TokenRepository>().getAccessToken(),
    );
    getIt.registerSingleton<GraphQLClient>(client);
  }

  if (!getIt.isRegistered<legacy_graphql.GraphQLClientWrapper>()) {
    final prefs = getIt<SharedPreferences>();
    final endpoint = graphQlApiUrl.isNotEmpty
        ? graphQlApiUrl
        : (apiBaseUrl.isNotEmpty ? '$apiBaseUrl/graphql' : 'http://localhost:3000/graphql');
    final wrapper = await legacy_graphql.GraphQLClientWrapper.create(
      endpoint: endpoint,
      preferences: prefs,
      secureStorage: getIt<SecureStorage>(),
    );
    getIt.registerSingleton<legacy_graphql.GraphQLClientWrapper>(wrapper);
  }

  final authToken = ((await getIt<token_module.TokenRepository>().getAccessToken()) ?? '')
      .trim();

  if (!getIt.isRegistered<String>(instanceName: 'authToken')) {
    getIt.registerSingleton<String>(authToken, instanceName: 'authToken');
  }

  if (!getIt.isRegistered<realtime_models.RealtimeConnectionConfig>()) {
    getIt.registerSingleton<realtime_models.RealtimeConnectionConfig>(
      realtime_models.RealtimeConnectionConfig(
        webSocketUrl:
            graphQlWsUrl.isNotEmpty ? graphQlWsUrl : 'ws://localhost:3000/graphql',
        httpUrl:
            graphQlApiUrl.isNotEmpty ? graphQlApiUrl : 'http://localhost:3000/graphql',
        authToken: authToken,
        additionalHeaders: authToken.isNotEmpty
            ? <String, String>{
                'Authorization': 'Bearer $authToken',
              }
            : const <String, String>{},
      ),
    );
  }

  if (!getIt.isRegistered<realtime.RealtimeConfig>()) {
    getIt.registerSingleton<realtime.RealtimeConfig>(
      realtime.RealtimeConfig(
        serverUrl: socketUrl.isNotEmpty ? socketUrl : 'ws://localhost:3000',
      ),
    );
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
