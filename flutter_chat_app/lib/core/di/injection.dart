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

import 'package:flutter_chat_app/core/utils/logger.dart';

import 'package:flutter_chat_app/core/network/connectivity/connectivity_service.dart'
    as net_connectivity;
import 'package:flutter_chat_app/core/error/retry_config.dart' as app_retry;
import 'package:flutter_chat_app/core/network/auth/auth_delegate.dart';
import 'package:flutter_chat_app/core/network/auth/token_provider.dart';
import 'package:flutter_chat_app/core/network/auth/token_repository.dart'
    as token_module;
import 'package:flutter_chat_app/core/config/firebase_config.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart'
    as core_graphql;
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/network/http/dio_http_client.dart';
import 'package:flutter_chat_app/core/network/http/http_client_interface.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart'
    as socket_mgr;
import 'package:flutter_chat_app/core/network/realtime/connection_pool_manager.dart';
import 'package:flutter_chat_app/core/network/realtime/enhanced_realtime_connection_service.dart';
import 'package:flutter_chat_app/core/network/realtime/models/realtime_connection_config.dart'
    as realtime_models;
import 'package:flutter_chat_app/core/network/realtime/realtime_connection_service.dart'
    as realtime;
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/features/auth/data/datasources/auth/auth_remote_datasource.dart'
    as auth_ds;
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart'
    as user_local_ds;
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart'
    as user_remote_ds;
import 'package:flutter_chat_app/data/datasources/media/media_local_datasource.dart'
    as media_local_ds;
import 'package:flutter_chat_app/data/datasources/permissions_datasource.dart';
import 'package:flutter_chat_app/data/datasources/permissions/web_permissions_datasource.dart';
import 'package:flutter_chat_app/data/services/file_download_manager/file_download_manager_factory.dart';
import 'package:flutter_chat_app/data/services/file_downloader/file_downloader_factory.dart';
import 'package:flutter_chat_app/data/services/gal_media_gallery_saver.dart';
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';
import 'package:flutter_chat_app/domain/services/i_media_gallery_saver.dart';
import 'package:flutter_chat_app/domain/usecases/media/download_file_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/media/save_media_to_gallery_usecase.dart';

import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';
import 'package:flutter_chat_app/core/monitoring/i_crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/monitoring/crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_service.dart';

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

  // logger.i('🚀 Initializing Dependency Injection...');
  final stopwatch = Stopwatch()..start();

  try {
    // Step 1: Register external dependencies
    await _registerExternalDependencies(logger);

    // Step 2: Register core module (manual registration)
    await registerCoreModule(getIt);

    // Step 3: Initialize auto-generated dependencies (feature services)
    getIt.init(environment: 'standalone');

    // Step 4: Override monitoring with Firebase-backed implementations
    // (standalone mode only — package mode uses NoOp defaults from core_module
    // or host-provided implementations from chat_module_injection)
    if (getIt.isRegistered<IPerformanceMonitor>()) {
      await getIt.unregister<IPerformanceMonitor>();
    }
    getIt.registerLazySingleton<IPerformanceMonitor>(
      () => PerformanceMonitor(getIt<FirebasePerformance>()),
    );

    if (getIt.isRegistered<ICrashReporter>()) {
      await getIt.unregister<ICrashReporter>();
    }
    getIt.registerLazySingleton<ICrashReporter>(
      () => CrashReporter(getIt<FirebaseCrashlytics>()),
    );

    if (getIt.isRegistered<IAnalyticsService>()) {
      await getIt.unregister<IAnalyticsService>();
    }
    getIt.registerLazySingleton<IAnalyticsService>(
      () => AnalyticsService(
        getIt<FirebaseAnalytics>(),
        getIt<ICrashReporter>(),
        getIt<IPerformanceMonitor>(),
      ),
    );

    if (kIsWeb) {
      if (getIt.isRegistered<PermissionsDataSource>()) {
        await getIt.unregister<PermissionsDataSource>();
      }
      getIt.registerLazySingleton<PermissionsDataSource>(
        () => WebPermissionsDataSource(),
      );
    }

    if (!getIt.isRegistered<auth_ds.AuthRemoteDataSource>()) {
      getIt.registerLazySingleton<auth_ds.AuthRemoteDataSource>(
        () => getIt<auth_ds.AuthRemoteDataSourceImpl>(),
      );
    }

    if (!getIt.isRegistered<user_local_ds.UserLocalDataSource>()) {
      getIt.registerLazySingleton<user_local_ds.UserLocalDataSource>(
        () => getIt<user_local_ds.UserLocalDataSourceImpl>(),
      );
    }

    if (!getIt.isRegistered<user_remote_ds.UserRemoteDataSource>()) {
      getIt.registerLazySingleton<user_remote_ds.UserRemoteDataSource>(
        () => getIt<user_remote_ds.UserRemoteDataSourceImpl>(),
      );
    }

    if (!getIt.isRegistered<media_local_ds.IMediaLocalDataSource>()) {
      getIt.registerLazySingleton<media_local_ds.IMediaLocalDataSource>(
        () => getIt<media_local_ds.MediaLocalDataSourceImpl>(),
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
        getIt<TokenProvider>(),
        getIt<AuthDelegate>(),
        getIt<String>(instanceName: 'graphQlApiUrl'),
      ),
    );

    getIt.registerLazySingleton<core_graphql.GraphQLClientWrapper>(
      () => getIt<core_graphql.GraphQLClientWrapperImpl>(),
    );

    // Override generated SocketManager to inject TokenProvider
    getIt.registerFactory<socket_mgr.SocketManager>(
      () => socket_mgr.SocketManager(
        serverUrl: getIt<String>(instanceName: 'socketUrl'),
        options: getIt<Map<String, dynamic>>(),
        logger: getIt<AppLogger>(),
        tokenProvider: getIt<TokenProvider>(),
      ),
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

    // Initialize current user provider so non-UI layers can access
    // current user id and user stream consistently.
    if (getIt.isRegistered<CurrentUserProvider>()) {
      await getIt<CurrentUserProvider>().initialize();

      // Backward compatibility: provide named currentUserId sourced from CurrentUserProvider
      // so callers can migrate away from SharedPreferences('userId').
      final currentUserId = getIt<CurrentUserProvider>().currentUserId;
      if (getIt.isRegistered<String>(instanceName: 'currentUserId')) {
        await getIt.unregister<String>(instanceName: 'currentUserId');
      }
      getIt.registerSingleton<String>(
        currentUserId,
        instanceName: 'currentUserId',
      );
    }

    if (!getIt.isRegistered<INetworkInfo>()) {
      getIt.registerLazySingleton<INetworkInfo>(() => getIt<NetworkInfo>());
    }

    if (!getIt.isRegistered<IFileDownloader>()) {
      getIt.registerLazySingleton<IFileDownloader>(
        () => createFileDownloader(getIt<AppLogger>()),
      );
    }

    if (!getIt.isRegistered<IFileDownloadManager>()) {
      getIt.registerLazySingleton<IFileDownloadManager>(
        () => createFileDownloadManager(getIt<AppLogger>()),
      );
    }

    if (!getIt.isRegistered<IMediaGallerySaver>()) {
      getIt.registerLazySingleton<IMediaGallerySaver>(
        () => GalMediaGallerySaver(
          getIt<AppLogger>(),
          getIt<IFileDownloader>(),
        ),
      );
    }

    if (!getIt.isRegistered<DownloadFileUseCase>()) {
      getIt.registerLazySingleton<DownloadFileUseCase>(
        () => DownloadFileUseCase(getIt<IFileDownloader>()),
      );
    }

    if (!getIt.isRegistered<SaveMediaToGalleryUseCase>()) {
      getIt.registerLazySingleton<SaveMediaToGalleryUseCase>(
        () => SaveMediaToGalleryUseCase(
          mediaRepository: getIt<IMediaRepository>(),
          gallerySaver: getIt<IMediaGallerySaver>(),
          logger: getIt<AppLogger>(),
        ),
      );
    }

    stopwatch.stop();
    logger.i(
        '✅ Dependency Injection initialized in ${stopwatch.elapsedMilliseconds}ms');

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
  // logger.d('📦 Registering external dependencies...');

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
    getIt.registerSingleton<SecureStorage>(
      kIsWeb ? InMemorySecureStorage() : SecureStorageImpl(),
    );
  }

  if (!getIt.isRegistered<token_module.TokenStorage>()) {
    final prefs = getIt<SharedPreferences>();
    getIt.registerSingleton<token_module.TokenStorage>(
      kIsWeb
          ? token_module.SharedPreferencesTokenStorage(prefs)
          : token_module.SecureTokenStorage(getIt<SecureStorage>()),
    );
  }

  if (!getIt.isRegistered<token_module.TokenRepository>()) {
    getIt.registerSingleton<token_module.TokenRepository>(
      token_module.TokenRepositoryImpl(
        tokenStorage: getIt<token_module.TokenStorage>(),
        prefs: getIt<SharedPreferences>(),
        refreshAccessToken: () =>
            getIt<auth_ds.AuthRemoteDataSource>().refreshToken(),
      ),
    );
  }

  await getIt<token_module.TokenRepository>().initialize();

  // Register TokenProvider pointing to TokenRepository (same instance)
  if (!getIt.isRegistered<TokenProvider>()) {
    getIt.registerSingleton<TokenProvider>(
      getIt<token_module.TokenRepository>(),
    );
  }

  // Register AuthDelegate with no-op default
  if (!getIt.isRegistered<AuthDelegate>()) {
    getIt.registerSingleton<AuthDelegate>(const NoOpAuthDelegate());
  }

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
    final apiBaseUrlRaw = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (apiBaseUrlRaw.isEmpty) {
      throw StateError('Missing required environment key: API_BASE_URL');
    }

    final baseUrl = apiBaseUrlRaw.replaceFirst(RegExp(r'/+$'), '');
    getIt.registerSingleton<String>(baseUrl, instanceName: 'baseUrl');
  }

  final apiBaseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
  final graphQlApiUrlRaw = (dotenv.env['GRAPHQL_API_URL'] ?? '').trim();
  final graphQlWsUrlRaw = (dotenv.env['GRAPHQL_WS_URL'] ?? '').trim();
  final socketUrlRaw =
      (dotenv.env['SOCKET_URL'] ?? dotenv.env['WEBSOCKET_URL'] ?? '').trim();

  if (graphQlApiUrlRaw.isEmpty) {
    throw StateError('Missing required environment key: GRAPHQL_API_URL');
  }
  if (graphQlWsUrlRaw.isEmpty) {
    throw StateError('Missing required environment key: GRAPHQL_WS_URL');
  }
  if (socketUrlRaw.isEmpty) {
    throw StateError(
        'Missing required environment key: SOCKET_URL (or WEBSOCKET_URL)');
  }

  final graphQlApiUrl = graphQlApiUrlRaw;
  final graphQlWsUrl = graphQlWsUrlRaw;
  String socketUrl = socketUrlRaw;

  // Socket.IO expects an HTTP(S) base URL. Using ws/wss here often causes
  // TransportError on web when the client constructs the polling/websocket URLs.
  if (socketUrl.startsWith('wss://')) {
    socketUrl = socketUrl.replaceFirst('wss://', 'https://');
  } else if (socketUrl.startsWith('ws://')) {
    socketUrl = socketUrl.replaceFirst('ws://', 'http://');
  }

  socketUrl = socketUrl.replaceFirst(RegExp(r'/+$'), '');

  // logger.i('Resolved endpoints (dotenv):');
  // logger.i('  API_BASE_URL=$apiBaseUrl');
  // logger.i('  GRAPHQL_API_URL(raw)=$graphQlApiUrlRaw');
  // logger.i('  GRAPHQL_WS_URL(raw)=$graphQlWsUrlRaw');
  // logger.i('  SOCKET_URL(raw)=$socketUrlRaw');
  // logger.i('  graphQlApiUrl=$graphQlApiUrl');
  // logger.i('  graphQlWsUrl=$graphQlWsUrl');
  // logger.i('  socketUrl=$socketUrl');

  if (!getIt.isRegistered<String>(instanceName: 'socketUrl')) {
    getIt.registerSingleton<String>(socketUrl, instanceName: 'socketUrl');
  }

  if (!getIt.isRegistered<String>(instanceName: 'graphQlApiUrl')) {
    getIt.registerSingleton<String>(graphQlApiUrl,
        instanceName: 'graphQlApiUrl');
  }

  if (!getIt.isRegistered<String>(instanceName: 'graphQlWsUrl')) {
    getIt.registerSingleton<String>(graphQlWsUrl, instanceName: 'graphQlWsUrl');
  }

  if (!getIt.isRegistered<app_retry.RetryConfig>()) {
    getIt.registerSingleton<app_retry.RetryConfig>(
        app_retry.RetryConfig.realtime);
  }

  // Initialize Firebase for all platforms
  if (!FirebaseConfigManager.isInitialized) {
    await FirebaseConfigManager.initialize();
  }

  if (!getIt.isRegistered<FirebasePerformance>()) {
    getIt.registerLazySingleton<FirebasePerformance>(
        () => FirebasePerformance.instance);
  }

  if (!getIt.isRegistered<FirebaseAnalytics>()) {
    getIt.registerLazySingleton<FirebaseAnalytics>(
        () => FirebaseAnalytics.instance);
  }

  if (!getIt.isRegistered<FirebaseCrashlytics>()) {
    getIt.registerLazySingleton<FirebaseCrashlytics>(
        () => FirebaseCrashlytics.instance);
  }

  if (!getIt.isRegistered<int>(instanceName: 'connectionPoolMaxPoolSize')) {
    getIt.registerSingleton<int>(5, instanceName: 'connectionPoolMaxPoolSize');
  }

  if (!getIt.isRegistered<int>(
      instanceName: 'connectionPoolMaxConnectionLifetime')) {
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

  if (!getIt.isRegistered<int>(
      instanceName: 'connectionPoolHealthCheckInterval')) {
    getIt.registerSingleton<int>(30000,
        instanceName: 'connectionPoolHealthCheckInterval');
  }

  if (!getIt.isRegistered<ConnectionFactory>()) {
    getIt.registerSingleton<ConnectionFactory>(
        () async => getIt<realtime.IRealtimeConnectionService>());
  }

  final authToken =
      ((await getIt<token_module.TokenRepository>().getAccessToken()) ?? '')
          .trim();

  if (!getIt.isRegistered<String>(instanceName: 'authToken')) {
    getIt.registerSingleton<String>(authToken, instanceName: 'authToken');
  }

  // Socket.IO connection options
  // Backend middleware verifies token primarily from `handshake.headers.authorization`.
  // Browsers may not allow custom headers for websocket, so also provide `query.token`
  // (matches @frontend) and `auth.token` as additional fallbacks.
  if (!getIt.isRegistered<Map<String, dynamic>>()) {
    final socketOptions = authToken.isNotEmpty
        ? <String, dynamic>{
            'query': <String, dynamic>{
              'token': authToken,
            },
            'auth': <String, dynamic>{
              'token': 'Bearer $authToken',
            },
            'extraHeaders': <String, String>{
              'Authorization': 'Bearer $authToken',
            },
          }
        : <String, dynamic>{};

    getIt.registerSingleton<Map<String, dynamic>>(socketOptions);
  }

  if (!getIt.isRegistered<GraphQLClient>()) {
    // Pre-populate env cache for GraphQLClientWrapperImpl.createClient fallback
    core_graphql.GraphQLClientWrapperImpl.setEnvCache(
        Map<String, String>.from(dotenv.env));

    // Create a GraphQL client with the current token and explicit URLs
    final client = await core_graphql.GraphQLClientWrapperImpl.createClient(
      accessTokenProvider: () =>
          getIt<token_module.TokenRepository>().getAccessToken(),
      graphqlUrl: graphQlApiUrl,
      graphqlWsUrl: graphQlWsUrl,
    );
    getIt.registerSingleton<GraphQLClient>(client);
  }

  if (!getIt.isRegistered<realtime_models.RealtimeConnectionConfig>()) {
    getIt.registerSingleton<realtime_models.RealtimeConnectionConfig>(
      realtime_models.RealtimeConnectionConfig(
        webSocketUrl: graphQlWsUrl,
        httpUrl: graphQlApiUrl,
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
        serverUrl: socketUrl,
      ),
    );
  }

  // logger.d('✅ External dependencies registered');
}

/// Reset DI container (for testing)
///
/// **Warning**: Only use this in tests!
/// This will clear all registered dependencies.
@visibleForTesting
Future<void> resetDependencies() async {
  await getIt.reset();
}
