/// DI setup for chat package mode.
///
/// Called by [ChatModule.initialize] instead of [configureDependencies].
/// Reads configuration from [ChatConfig] rather than dotenv/Firebase.
///
/// Registration order:
/// 1. External deps from ChatConfig (URLs, tokens, callbacks)
/// 2. Core infrastructure (SharedPreferences, Logger, DB, etc.)
/// 3. Auto-generated deps via getIt.init()
/// 4. Overrides for config-specific implementations (GraphQL, Socket, etc.)
library chat_module_injection;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_chat_app/chat_config.dart';
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:flutter_chat_app/core/config/firebase_config.dart';
import 'package:flutter_chat_app/core/error/retry_config.dart' as app_retry;
import 'package:flutter_chat_app/core/localization/error_message_provider.dart';
import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';
import 'package:flutter_chat_app/core/network/auth/auth_delegate.dart';
import 'package:flutter_chat_app/core/network/auth/token_provider.dart';
import 'package:flutter_chat_app/core/network/auth/token_repository.dart'
    as token_module;
import 'package:flutter_chat_app/core/network/graphql_client.dart' as core_graphql;
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/network/http/dio_http_client.dart';
import 'package:flutter_chat_app/core/network/http/http_client_interface.dart';
import 'package:flutter_chat_app/core/network/connectivity/connectivity_service.dart'
    as net_connectivity;
import 'package:flutter_chat_app/core/network/realtime/connection_pool_manager.dart';
import 'package:flutter_chat_app/core/network/realtime/enhanced_realtime_connection_service.dart';
import 'package:flutter_chat_app/core/network/realtime/models/realtime_connection_config.dart'
    as realtime_models;
import 'package:flutter_chat_app/core/network/realtime/realtime_connection_service.dart'
    as realtime;
import 'package:flutter_chat_app/core/network/socket_manager.dart' as socket_mgr;
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/data/datasources/permissions_datasource.dart';
import 'package:flutter_chat_app/data/datasources/permissions/web_permissions_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart'
    as user_local_ds;
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart'
    as user_remote_ds;
import 'package:flutter_chat_app/data/datasources/media/media_local_datasource.dart'
    as media_local_ds;
import 'package:flutter_chat_app/features/auth/data/datasources/auth/auth_remote_datasource.dart'
    as auth_ds;

import 'injection.config.dart';
import 'modules/core_module.dart';

/// Initializes DI for the chat module running in package mode.
///
/// Mirrors [configureDependencies] but reads URLs and tokens from
/// [ChatConfig] instead of dotenv. Firebase deps are still expected
/// to be initialized by the host app (Phase 4 will make them optional).
class ChatModuleInjection {
  ChatModuleInjection._();

  static final GetIt _getIt = GetIt.instance;

  /// Initialize all dependencies from [ChatConfig].
  static Future<void> initialize(ChatConfig config) async {
    _getIt.allowReassignment = true;

    final logger = Logger(
      printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 5,
        lineLength: 100,
        colors: true,
        printEmojis: true,
      ),
    );

    logger.i('ChatModule: Initializing DI from ChatConfig...');
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Register external deps from ChatConfig
      await _registerExternalDeps(config, logger);

      // Step 2: Register core module (manual registration)
      await registerCoreModule(_getIt);

      // Step 3: Initialize auto-generated deps
      _getIt.init();

      // Step 4: Platform-specific overrides
      if (kIsWeb) {
        if (_getIt.isRegistered<PermissionsDataSource>()) {
          await _getIt.unregister<PermissionsDataSource>();
        }
        _getIt.registerLazySingleton<PermissionsDataSource>(
          () => WebPermissionsDataSource(),
        );
      }

      // Step 5: Interface registrations
      _registerInterfaceBindings();

      // Step 6: Override GraphQL and Socket with config-aware implementations
      _registerConfigOverrides(config);

      // Step 7: Set AppConfig overrides for package mode
      AppConfig.setOverrides({
        'API_URL': config.graphqlUrl,
        'WS_URL': config.graphqlWsUrl,
        'SOCKET_URL': config.socketUrl,
      });

      // Step 8: Set error message provider if provided
      if (config.errorMessageProvider != null) {
        ErrorMessages.setProvider(config.errorMessageProvider!);
      }

      stopwatch.stop();
      logger.i(
        'ChatModule: DI initialized in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.e(
        'ChatModule: DI initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Clean up all registered dependencies.
  static Future<void> dispose() async {
    AppConfig.clearOverrides();
    await _getIt.reset();
  }

  /// Register external dependencies from [ChatConfig].
  ///
  /// Mirrors [_registerExternalDependencies] in injection.dart but reads
  /// from config instead of dotenv.
  static Future<void> _registerExternalDeps(
    ChatConfig config,
    Logger logger,
  ) async {
    // Logger
    if (!_getIt.isRegistered<Logger>()) {
      _getIt.registerSingleton<Logger>(logger);
    }

    // SharedPreferences
    if (!_getIt.isRegistered<SharedPreferences>()) {
      final prefs = await SharedPreferences.getInstance();
      _getIt.registerSingleton<SharedPreferences>(prefs);
    }

    // SecureStorage
    if (!_getIt.isRegistered<SecureStorage>()) {
      _getIt.registerSingleton<SecureStorage>(
        kIsWeb ? InMemorySecureStorage() : SecureStorageImpl(),
      );
    }

    // TokenStorage
    if (!_getIt.isRegistered<token_module.TokenStorage>()) {
      final prefs = _getIt<SharedPreferences>();
      _getIt.registerSingleton<token_module.TokenStorage>(
        kIsWeb
            ? token_module.SharedPreferencesTokenStorage(prefs)
            : token_module.SecureTokenStorage(_getIt<SecureStorage>()),
      );
    }

    // TokenRepository — pre-populated with config tokens
    if (!_getIt.isRegistered<token_module.TokenRepository>()) {
      final tokenRepo = token_module.TokenRepositoryImpl(
        tokenStorage: _getIt<token_module.TokenStorage>(),
        prefs: _getIt<SharedPreferences>(),
        refreshAccessToken: config.onTokenRefresh,
      );
      _getIt.registerSingleton<token_module.TokenRepository>(tokenRepo);
    }

    // Initialize and pre-populate tokens from config
    final tokenRepo = _getIt<token_module.TokenRepository>();
    await tokenRepo.initialize();
    if (config.accessToken.isNotEmpty) {
      await tokenRepo.saveAccessToken(config.accessToken);
    }
    if (config.refreshToken != null && config.refreshToken!.isNotEmpty) {
      await tokenRepo.saveRefreshToken(config.refreshToken!);
    }

    // TokenProvider (same instance as TokenRepository)
    if (!_getIt.isRegistered<TokenProvider>()) {
      _getIt.registerSingleton<TokenProvider>(tokenRepo);
    }

    // AuthDelegate from config callbacks
    if (!_getIt.isRegistered<AuthDelegate>()) {
      _getIt.registerSingleton<AuthDelegate>(
        CallbackAuthDelegate(
          onAuthExpired: config.onAuthExpired,
          onTokenRefreshed: config.onTokenRefreshed,
        ),
      );
    }

    // IPerformanceMonitor from config or NoOp
    if (!_getIt.isRegistered<IPerformanceMonitor>()) {
      _getIt.registerSingleton<IPerformanceMonitor>(
        config.performanceMonitor ?? const NoOpPerformanceMonitor(),
      );
    }

    // Connectivity
    if (!_getIt.isRegistered<Connectivity>()) {
      _getIt.registerSingleton<Connectivity>(Connectivity());
    }

    // HTTP Client
    if (!_getIt.isRegistered<http.Client>()) {
      _getIt.registerLazySingleton<http.Client>(() => http.Client());
    }

    // URLs from ChatConfig (instead of dotenv)
    final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (!_getIt.isRegistered<String>(instanceName: 'baseUrl')) {
      _getIt.registerSingleton<String>(baseUrl, instanceName: 'baseUrl');
    }

    String socketUrl = config.socketUrl;
    if (socketUrl.startsWith('wss://')) {
      socketUrl = socketUrl.replaceFirst('wss://', 'https://');
    } else if (socketUrl.startsWith('ws://')) {
      socketUrl = socketUrl.replaceFirst('ws://', 'http://');
    }
    socketUrl = socketUrl.replaceFirst(RegExp(r'/+$'), '');

    if (!_getIt.isRegistered<String>(instanceName: 'socketUrl')) {
      _getIt.registerSingleton<String>(socketUrl, instanceName: 'socketUrl');
    }

    if (!_getIt.isRegistered<String>(instanceName: 'graphQlApiUrl')) {
      _getIt.registerSingleton<String>(
        config.graphqlUrl,
        instanceName: 'graphQlApiUrl',
      );
    }

    if (!_getIt.isRegistered<String>(instanceName: 'graphQlWsUrl')) {
      _getIt.registerSingleton<String>(
        config.graphqlWsUrl,
        instanceName: 'graphQlWsUrl',
      );
    }

    // RetryConfig
    if (!_getIt.isRegistered<app_retry.RetryConfig>()) {
      _getIt.registerSingleton<app_retry.RetryConfig>(
        app_retry.RetryConfig.realtime,
      );
    }

    // Firebase — host app must initialize Firebase before calling ChatModule.initialize.
    // Phase 4 will make Firebase fully optional.
    if (kIsWeb && !FirebaseConfigManager.isInitialized) {
      await FirebaseConfigManager.initialize();
    }

    if (!_getIt.isRegistered<FirebasePerformance>()) {
      _getIt.registerLazySingleton<FirebasePerformance>(
        () => FirebasePerformance.instance,
      );
    }

    if (!_getIt.isRegistered<FirebaseAnalytics>()) {
      _getIt.registerLazySingleton<FirebaseAnalytics>(
        () => FirebaseAnalytics.instance,
      );
    }

    if (!_getIt.isRegistered<FirebaseCrashlytics>()) {
      _getIt.registerLazySingleton<FirebaseCrashlytics>(
        () => FirebaseCrashlytics.instance,
      );
    }

    // Connection pool config
    if (!_getIt.isRegistered<int>(instanceName: 'connectionPoolMaxPoolSize')) {
      _getIt.registerSingleton<int>(5,
          instanceName: 'connectionPoolMaxPoolSize');
    }
    if (!_getIt.isRegistered<int>(
        instanceName: 'connectionPoolMaxConnectionLifetime')) {
      _getIt.registerSingleton<int>(3600000,
          instanceName: 'connectionPoolMaxConnectionLifetime');
    }
    if (!_getIt.isRegistered<int>(instanceName: 'connectionPoolMaxIdleTime')) {
      _getIt.registerSingleton<int>(600000,
          instanceName: 'connectionPoolMaxIdleTime');
    }
    if (!_getIt.isRegistered<int>(
        instanceName: 'connectionPoolCleanupInterval')) {
      _getIt.registerSingleton<int>(60000,
          instanceName: 'connectionPoolCleanupInterval');
    }
    if (!_getIt.isRegistered<int>(
        instanceName: 'connectionPoolHealthCheckInterval')) {
      _getIt.registerSingleton<int>(30000,
          instanceName: 'connectionPoolHealthCheckInterval');
    }

    if (!_getIt.isRegistered<ConnectionFactory>()) {
      _getIt.registerSingleton<ConnectionFactory>(
        () async => _getIt<realtime.IRealtimeConnectionService>(),
      );
    }

    final authToken = config.accessToken.trim();
    if (!_getIt.isRegistered<String>(instanceName: 'authToken')) {
      _getIt.registerSingleton<String>(authToken, instanceName: 'authToken');
    }

    // Socket.IO connection options
    if (!_getIt.isRegistered<Map<String, dynamic>>()) {
      final socketOptions = authToken.isNotEmpty
          ? <String, dynamic>{
              'query': <String, dynamic>{'token': authToken},
              'auth': <String, dynamic>{'token': 'Bearer $authToken'},
              'extraHeaders': <String, String>{
                'Authorization': 'Bearer $authToken',
              },
            }
          : <String, dynamic>{};
      _getIt.registerSingleton<Map<String, dynamic>>(socketOptions);
    }

    // GraphQLClient
    if (!_getIt.isRegistered<GraphQLClient>()) {
      final client = await core_graphql.GraphQLClientWrapperImpl.createClient(
        accessTokenProvider: () => tokenRepo.getAccessToken(),
        graphqlUrl: config.graphqlUrl,
        graphqlWsUrl: config.graphqlWsUrl,
      );
      _getIt.registerSingleton<GraphQLClient>(client);
    }

    // RealtimeConnectionConfig
    if (!_getIt.isRegistered<realtime_models.RealtimeConnectionConfig>()) {
      _getIt.registerSingleton<realtime_models.RealtimeConnectionConfig>(
        realtime_models.RealtimeConnectionConfig(
          webSocketUrl: config.graphqlWsUrl,
          httpUrl: config.graphqlUrl,
          authToken: authToken,
          additionalHeaders: authToken.isNotEmpty
              ? <String, String>{'Authorization': 'Bearer $authToken'}
              : const <String, String>{},
        ),
      );
    }

    // RealtimeConfig
    if (!_getIt.isRegistered<realtime.RealtimeConfig>()) {
      _getIt.registerSingleton<realtime.RealtimeConfig>(
        realtime.RealtimeConfig(serverUrl: socketUrl),
      );
    }

    logger.d('ChatModule: External dependencies registered');
  }

  /// Register interface → implementation bindings.
  static void _registerInterfaceBindings() {
    if (!_getIt.isRegistered<auth_ds.AuthRemoteDataSource>()) {
      _getIt.registerLazySingleton<auth_ds.AuthRemoteDataSource>(
        () => _getIt<auth_ds.AuthRemoteDataSourceImpl>(),
      );
    }

    if (!_getIt.isRegistered<user_local_ds.UserLocalDataSource>()) {
      _getIt.registerLazySingleton<user_local_ds.UserLocalDataSource>(
        () => _getIt<user_local_ds.UserLocalDataSourceImpl>(),
      );
    }

    if (!_getIt.isRegistered<user_remote_ds.UserRemoteDataSource>()) {
      _getIt.registerLazySingleton<user_remote_ds.UserRemoteDataSource>(
        () => _getIt<user_remote_ds.UserRemoteDataSourceImpl>(),
      );
    }

    if (!_getIt.isRegistered<media_local_ds.IMediaLocalDataSource>()) {
      _getIt.registerLazySingleton<media_local_ds.IMediaLocalDataSource>(
        () => _getIt<media_local_ds.MediaLocalDataSourceImpl>(),
      );
    }

    if (!_getIt.isRegistered<IHttpClient>()) {
      _getIt.registerLazySingleton<IHttpClient>(() => _getIt<DioHttpClient>());
    }

    if (!_getIt.isRegistered<net_connectivity.IConnectivityService>()) {
      _getIt.registerLazySingleton<net_connectivity.IConnectivityService>(
        () => _getIt<net_connectivity.ConnectivityServiceImpl>(),
      );
    }

    if (!_getIt.isRegistered<realtime.IRealtimeConnectionService>()) {
      _getIt.registerLazySingleton<realtime.IRealtimeConnectionService>(
        () => _getIt<EnhancedRealtimeConnectionService>(),
      );
    }

    if (!_getIt.isRegistered<INetworkInfo>()) {
      _getIt.registerLazySingleton<INetworkInfo>(() => _getIt<NetworkInfo>());
    }
  }

  /// Override auto-generated registrations with config-aware versions.
  static void _registerConfigOverrides(ChatConfig config) {
    // GraphQLClientWrapperImpl — use TokenProvider + AuthDelegate
    if (_getIt.isRegistered<core_graphql.GraphQLClientWrapperImpl>()) {
      _getIt.unregister<core_graphql.GraphQLClientWrapperImpl>();
    }
    if (_getIt.isRegistered<core_graphql.GraphQLClientWrapper>()) {
      _getIt.unregister<core_graphql.GraphQLClientWrapper>();
    }

    _getIt.registerLazySingleton<core_graphql.GraphQLClientWrapperImpl>(
      () => core_graphql.GraphQLClientWrapperImpl(
        _getIt<GraphQLClient>(),
        _getIt<NetworkInfo>(),
        _getIt<TokenProvider>(),
        _getIt<AuthDelegate>(),
        config.graphqlUrl,
      ),
    );

    _getIt.registerLazySingleton<core_graphql.GraphQLClientWrapper>(
      () => _getIt<core_graphql.GraphQLClientWrapperImpl>(),
    );

    // SocketManager — inject TokenProvider
    _getIt.registerFactory<socket_mgr.SocketManager>(
      () => socket_mgr.SocketManager(
        serverUrl: _getIt<String>(instanceName: 'socketUrl'),
        options: _getIt<Map<String, dynamic>>(),
        logger: _getIt<Logger>(),
        tokenProvider: _getIt<TokenProvider>(),
      ),
    );

    // Override IPerformanceMonitor if auto-generated registered Firebase version
    if (config.performanceMonitor != null) {
      _getIt.registerSingleton<IPerformanceMonitor>(config.performanceMonitor!);
    }
  }
}
