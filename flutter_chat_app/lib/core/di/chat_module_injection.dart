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
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_chat_app/core/utils/logger.dart' show AppLogger;

import 'package:flutter_chat_app/chat_config.dart';
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:flutter_chat_app/core/error/retry_config.dart' as app_retry;
import 'package:flutter_chat_app/core/initialization/media_kit_initializer.dart';
import 'package:flutter_chat_app/core/localization/error_message_provider.dart';
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:flutter_chat_app/core/monitoring/i_crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';
import 'package:flutter_chat_app/core/network/auth/auth_delegate.dart';
import 'package:flutter_chat_app/core/network/auth/token_provider.dart';
import 'package:flutter_chat_app/core/network/auth/token_repository.dart'
    as token_module;
import 'package:flutter_chat_app/core/network/graphql_client.dart'
    as core_graphql;
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
import 'package:flutter_chat_app/core/network/socket_manager.dart'
    as socket_mgr;
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/data/services/file_download_manager/file_download_manager_factory.dart';
import 'package:flutter_chat_app/data/services/file_downloader/file_downloader_factory.dart';
import 'package:flutter_chat_app/data/services/gal_media_gallery_saver.dart';
import 'package:flutter_chat_app/data/datasources/permissions_datasource.dart';
import 'package:flutter_chat_app/data/datasources/permissions/web_permissions_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart'
    as user_local_ds;
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart'
    as user_remote_ds;
import 'package:flutter_chat_app/data/datasources/media/media_local_datasource.dart'
    as media_local_ds;
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';
import 'package:flutter_chat_app/domain/services/i_media_gallery_saver.dart';
import 'package:flutter_chat_app/domain/usecases/media/download_file_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/media/save_media_to_gallery_usecase.dart';
import 'package:flutter_chat_app/features/auth/data/datasources/auth/auth_remote_datasource.dart'
    as auth_ds;
import 'package:flutter_chat_app/shared/domain/entities/user.dart';

import 'package:flutter_chat_app/core/cache/background_sync_helper.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:flutter_chat_app/core/services/chat_active_conversation_tracker.dart';
import 'package:flutter_chat_app/core/services/chat_notification_orchestrator.dart';
import 'package:flutter_chat_app/core/services/chat_notification_policy_service.dart';
import 'package:flutter_chat_app/core/services/chat_conversation_selection_service.dart';
import 'package:flutter_chat_app/core/services/foreground_sync_service.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/local_notification_service.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';

import 'package:flutter_chat_app/core/di/injection.config.dart';
import 'package:flutter_chat_app/core/di/modules/core_module.dart';
import 'package:flutter_chat_app/core/di/modules/notification_module.dart';

/// Initializes DI for the chat module running in package mode.
///
/// Mirrors [configureDependencies] but reads URLs and tokens from
/// [ChatConfig] instead of dotenv. Firebase is not required — monitoring
/// services use NoOp defaults unless the host app provides implementations
/// via [ChatConfig].
class ChatModuleInjection {
  ChatModuleInjection._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
  );

  static final GetIt _getIt = GetIt.instance;

  /// Initialize all dependencies from [ChatConfig].
  static Future<void> initialize(ChatConfig config) async {
    _getIt.allowReassignment = true;

    _logger.i('ChatModule: Initializing DI from ChatConfig...');
    final stopwatch = Stopwatch()..start();
    int lastCheckpoint = 0;

    void lap(String label) {
      final elapsed = stopwatch.elapsedMilliseconds;
      final delta = elapsed - lastCheckpoint;
      _logger.d('⏱️ ChatModule DI [$label]: ${delta}ms (total: ${elapsed}ms)');
      lastCheckpoint = elapsed;
    }

    try {
      // Step 1: Register external deps from ChatConfig
      await _registerExternalDeps(config, _logger);
      lap('Step1: External deps');

      // Step 2: Register core module (manual registration)
      await registerCoreModule(_getIt);
      lap('Step2: Core module');

      // Step 2.1: Initialize platform-specific media libraries (Windows: media_kit)
      await ensureMediaKitInitialized();
      lap('Step2.1: MediaKit init');

      // Step 2.5: Pre-register monitoring services BEFORE auto-generated deps
      // These are needed by many auto-generated registrations but would normally
      // be provided by Firebase. In package mode, we use NoOp implementations.
      _registerMonitoringServices(config);
      lap('Step2.5: Monitoring services');

      // Step 3: Initialize auto-generated deps
      _getIt.init(environment: 'package');
      lap('Step3: Auto-generated deps (getIt.init)');

      // Step 4: Platform-specific overrides
      if (kIsWeb) {
        if (_getIt.isRegistered<PermissionsDataSource>()) {
          await _getIt.unregister<PermissionsDataSource>();
        }
        _getIt.registerLazySingleton<PermissionsDataSource>(
          () => WebPermissionsDataSource(),
        );
      }
      lap('Step4: Platform overrides');

      // Step 5: Interface registrations
      _registerInterfaceBindings();
      lap('Step5: Interface bindings');

      // Step 6: Override GraphQL and Socket with config-aware implementations
      _registerConfigOverrides(config);
      lap('Step6: Config overrides');

      registerNotificationModule(_getIt);
      lap('Step6.5: Notification module');

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
      lap('Step7-8: AppConfig + ErrorMessages');

      // Step 9: Initialize CurrentUserProvider and seed with ChatConfig user.
      // This makes current user available to non-UI layers (BLoCs/services)
      // without depending on AuthBloc state or SharedPreferences.
      if (_getIt.isRegistered<CurrentUserProvider>()) {
        final currentUserProvider = _getIt<CurrentUserProvider>();
        await currentUserProvider.initialize();

        final currentUser = User(
          id: config.currentUserId,
          username: config.currentUserName ?? 'user_${config.currentUserId}',
          email: config.currentUserEmail ?? '',
          fullName: config.currentUserFullName,
          avatar: config.currentUserAvatar,
          isOnline: true,
        );
        await currentUserProvider.setCurrentUser(currentUser);
      }
      lap('Step9: CurrentUserProvider');

      // Step 10: Persist config to SharedPreferences for background isolate
      final prefs = _getIt<SharedPreferences>();
      await prefs.setString(BackgroundSyncHelper.keyBaseUrl, config.baseUrl);
      await prefs.setString(
          BackgroundSyncHelper.keyGraphqlUrl, config.graphqlUrl);
      await prefs.setString(
          BackgroundSyncHelper.keyAccessToken, config.accessToken);

      // Step 11: Wire ChatConfig callbacks into ChatModuleEventBus
      if (_getIt.isRegistered<ChatModuleEventBus>()) {
        final eventBus = _getIt<ChatModuleEventBus>();

        if (config.onNewMessageReceived != null) {
          eventBus.newMessageStream.listen(config.onNewMessageReceived!);
        }
        if (config.onUnreadCountChanged != null) {
          eventBus.totalUnreadCountStream.listen(config.onUnreadCountChanged!);
        }
        if (config.onNotificationTap != null) {
          eventBus.notificationTapStream.listen(config.onNotificationTap!);
        }
      }

      // Step 12: Initialize ForegroundSyncService
      if (_getIt.isRegistered<ForegroundSyncService>()) {
        _getIt<ForegroundSyncService>().initialize();
      }

      if (_getIt.isRegistered<ChatNotificationOrchestrator>()) {
        await _getIt<ChatNotificationOrchestrator>().initialize(
          enableBuiltInNotifications: config.enableBuiltInLocalNotifications,
        );
      }

      stopwatch.stop();
      _logger.i(
        '✅ ChatModule: DI initialized in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.e(
        '❌ ChatModule: DI initialization failed after ${stopwatch.elapsedMilliseconds}ms',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Logout the current user and clear **ALL** user-specific data.
  ///
  /// This method ensures complete data isolation between users:
  /// 1. Disconnects Socket.IO and realtime connections (stop receiving old user's events)
  /// 2. Clears tokens from SecureStorage/SharedPreferences (prevent API calls as old user)
  /// 3. Clears the local database (Isar) to remove cached chats/messages
  /// 4. Clears GraphQL cache, in-memory caches, and SharedPreferences keys
  /// 5. Clears CurrentUserProvider and user-specific named instances
  /// 6. Unregisters singleton repositories so they get recreated on next login
  /// 7. Preserves core infrastructure (SharedPreferences instance, Logger, DatabaseService)
  ///
  /// Call this when user logs out to ensure the next user doesn't see
  /// the previous user's data.
  static Future<void> logout() async {
    _logger.d('[ChatModuleInjection] Logging out - clearing ALL user data...');

    // ── Step 0: Dispose services that produce real-time side-effects ──
    try {
      if (_getIt.isRegistered<ForegroundSyncService>()) {
        _getIt<ForegroundSyncService>().dispose();
        _tryUnregister<ForegroundSyncService>();
      }
    } catch (e) {
      _logger.d(
          '[ChatModuleInjection] Failed to dispose ForegroundSyncService: $e');
    }
    try {
      if (_getIt.isRegistered<ChatNotificationOrchestrator>()) {
        await _getIt<ChatNotificationOrchestrator>().dispose();
        _tryUnregister<ChatNotificationOrchestrator>();
      }
    } catch (e) {
      _logger.d(
          '[ChatModuleInjection] Failed to dispose ChatNotificationOrchestrator: $e');
    }
    try {
      if (_getIt.isRegistered<ChatModuleEventBus>()) {
        _getIt<ChatModuleEventBus>().dispose();
        _tryUnregister<ChatModuleEventBus>();
      }
    } catch (e) {
      _logger
          .d('[ChatModuleInjection] Failed to dispose ChatModuleEventBus: $e');
    }
    _tryUnregister<ChatActiveConversationTracker>();
    _tryUnregister<ChatConversationSelectionService>();
    _tryUnregister<ChatNotificationPolicyService>();
    _tryUnregister<LocalNotificationService>();

    // ── Step 1: Disconnect Socket.IO — HIGH PRIORITY ──
    // Without this, socket stays connected with old user's token and
    // the next user receives real-time messages from the old user.
    try {
      if (_getIt.isRegistered<socket_mgr.SocketManager>()) {
        final socketManager = _getIt<socket_mgr.SocketManager>();
        socketManager.dispose();
        _logger.d('[ChatModuleInjection] SocketManager disconnected & disposed');
      }
    } catch (e) {
      _logger.d('[ChatModuleInjection] Failed to dispose SocketManager: $e');
    }
    _tryUnregister<socket_mgr.SocketManager>();

    // Dispose ConnectionPoolManager (closes all WebSocket pool connections)
    try {
      if (_getIt.isRegistered<ConnectionPoolManager>()) {
        await _getIt<ConnectionPoolManager>().dispose();
        _logger.d('[ChatModuleInjection] ConnectionPoolManager disposed');
      }
    } catch (e) {
      _logger.d(
          '[ChatModuleInjection] Failed to dispose ConnectionPoolManager: $e');
    }
    _tryUnregister<ConnectionPoolManager>();

    // Dispose EnhancedRealtimeConnectionService
    try {
      if (_getIt.isRegistered<EnhancedRealtimeConnectionService>()) {
        _getIt<EnhancedRealtimeConnectionService>().dispose();
        _logger.d(
            '[ChatModuleInjection] EnhancedRealtimeConnectionService disposed');
      }
    } catch (e) {
      _logger.d(
          '[ChatModuleInjection] Failed to dispose EnhancedRealtimeConnectionService: $e');
    }
    _tryUnregister<EnhancedRealtimeConnectionService>();
    _tryUnregister<realtime.IRealtimeConnectionService>();

    // ── Step 2: Clear tokens from persistent storage — HIGH PRIORITY ──
    // TokenRepository.clear() removes tokens from SecureStorage AND
    // SharedPreferences, preventing API calls as the old user.
    try {
      if (_getIt.isRegistered<token_module.TokenRepository>()) {
        await _getIt<token_module.TokenRepository>().clear();
        _logger.d(
            '[ChatModuleInjection] TokenRepository cleared (SecureStorage + SharedPrefs)');
      }
    } catch (e) {
      _logger.d('[ChatModuleInjection] Failed to clear TokenRepository: $e');
    }

    // ── Step 3: Clear SharedPreferences user-specific keys — HIGH PRIORITY ──
    // These were written in initialize() Step 10 for background isolate sync.
    // Without clearing, BackgroundSyncHelper reads old user's access token.
    try {
      if (_getIt.isRegistered<SharedPreferences>()) {
        final prefs = _getIt<SharedPreferences>();
        await Future.wait([
          prefs.remove(BackgroundSyncHelper.keyBaseUrl),
          prefs.remove(BackgroundSyncHelper.keyGraphqlUrl),
          prefs.remove(BackgroundSyncHelper.keyAccessToken),
          prefs.remove(BackgroundSyncHelper.keyLastBgSyncTime),
        ]);
        _logger.d(
            '[ChatModuleInjection] SharedPreferences background sync keys cleared');
      }
    } catch (e) {
      _logger.d(
          '[ChatModuleInjection] Failed to clear SharedPreferences keys: $e');
    }

    // ── Step 4: Clear CurrentUserProvider — MEDIUM PRIORITY ──
    // Without this, services that inject CurrentUserProvider still return
    // the old user's ID and profile data.
    try {
      if (_getIt.isRegistered<CurrentUserProvider>()) {
        await _getIt<CurrentUserProvider>().clear();
        _logger.d('[ChatModuleInjection] CurrentUserProvider cleared');
      }
    } catch (e) {
      _logger.d(
          '[ChatModuleInjection] Failed to clear CurrentUserProvider: $e');
    }

    // ── Step 5: Clear local database (Isar) — data isolation ──
    try {
      if (_getIt.isRegistered<DatabaseService>()) {
        final dbService = _getIt<DatabaseService>();
        await dbService.clearAllData();
        _logger.d('[ChatModuleInjection] Database cleared successfully');
      }
    } catch (e) {
      _logger.d('[ChatModuleInjection] Failed to clear database: $e');
    }

    // ── Step 6: Clear local datasource in-memory cache ──
    try {
      if (_getIt.isRegistered<ChatLocalDataSource>()) {
        final localDs = _getIt<ChatLocalDataSource>();
        await localDs.clearAll();
        _logger.d('[ChatModuleInjection] Local datasource cleared');
      }
    } catch (e) {
      _logger.d('[ChatModuleInjection] Failed to clear local datasource: $e');
    }

    // ── Step 7: Clear GraphQL cache (HiveStore) ──
    // Without this, cached queries return old user's data.
    try {
      if (_getIt.isRegistered<GraphQLClient>()) {
        final graphqlClient = _getIt<GraphQLClient>();
        graphqlClient.cache.store.reset();
        _logger.d('[ChatModuleInjection] GraphQL cache cleared');
      }
    } catch (e) {
      _logger.d('[ChatModuleInjection] Failed to clear GraphQL cache: $e');
    }

    // ── Step 8: Unregister singleton repositories ──
    // These hold stale references; they will be recreated on next init.
    _tryUnregister<IChatRepository>();
    _tryUnregister<ChatLocalDataSource>();

    // ── Step 9: Clear AppConfig overrides ──
    AppConfig.clearOverrides();

    // ── Step 10: Unregister user-specific named instances — MEDIUM PRIORITY ──
    // These were set in _registerExternalDeps() with the old user's values.
    // Without clearing, inject by name returns old user's userId/token.
    _tryUnregisterNamed<String>('currentUserId');
    _tryUnregisterNamed<String>('authToken');
    _tryUnregisterNamed<String>('baseUrl');
    _tryUnregisterNamed<String>('socketUrl');
    _tryUnregisterNamed<String>('graphQlApiUrl');
    _tryUnregisterNamed<String>('graphQlWsUrl');

    // Unregister connection pool config named instances
    _tryUnregisterNamed<int>('connectionPoolMaxPoolSize');
    _tryUnregisterNamed<int>('connectionPoolMaxConnectionLifetime');
    _tryUnregisterNamed<int>('connectionPoolMaxIdleTime');
    _tryUnregisterNamed<int>('connectionPoolCleanupInterval');
    _tryUnregisterNamed<int>('connectionPoolHealthCheckInterval');

    // Unregister socket options (contains old auth token)
    _tryUnregister<Map<String, dynamic>>();

    // Unregister RealtimeConnectionConfig (contains old auth token)
    _tryUnregister<realtime_models.RealtimeConnectionConfig>();
    _tryUnregister<realtime.RealtimeConfig>();
    _tryUnregister<ConnectionFactory>();

    // ── Step 11: Unregister auth-related singletons ──
    _tryUnregister<TokenProvider>();
    _tryUnregister<AuthDelegate>();
    _tryUnregister<token_module.TokenRepository>();
    _tryUnregister<token_module.TokenStorage>();
    _tryUnregister<core_graphql.GraphQLClientWrapperImpl>();
    _tryUnregister<core_graphql.GraphQLClientWrapper>();
    _tryUnregister<GraphQLClient>();

    _logger.d('[ChatModuleInjection] ✅ Logout complete — all user data cleared');
  }

  /// Clean up chat module specific resources.
  ///
  /// Performs full cleanup: clears user data (like [logout]) AND unregisters
  /// all chat module dependencies, preserving host app's registrations.
  ///
  /// NOTE: We do NOT call _getIt.reset() because chat module shares
  /// GetIt instance with host app. Calling reset() would unregister ALL
  /// dependencies including host app's routes, causing navigation failures.
  static Future<void> dispose() async {
    // First perform full user-data cleanup (same as logout)
    await logout();

    // Then unregister remaining infrastructure singletons that logout preserves
    _tryUnregister<CurrentUserProvider>();
    _tryUnregister<DatabaseService>();
    _tryUnregister<SecureStorage>();
    _tryUnregister<token_module.TokenStorage>();

    // Unregister named instances (in case logout didn't run or was skipped)
    _tryUnregisterNamed<String>('currentUserId');
    _tryUnregisterNamed<String>('authToken');
    _tryUnregisterNamed<String>('baseUrl');
    _tryUnregisterNamed<String>('socketUrl');
    _tryUnregisterNamed<String>('graphQlApiUrl');
    _tryUnregisterNamed<String>('graphQlWsUrl');
    _tryUnregisterNamed<int>('connectionPoolMaxPoolSize');
    _tryUnregisterNamed<int>('connectionPoolMaxConnectionLifetime');
    _tryUnregisterNamed<int>('connectionPoolMaxIdleTime');
    _tryUnregisterNamed<int>('connectionPoolCleanupInterval');
    _tryUnregisterNamed<int>('connectionPoolHealthCheckInterval');

    _tryUnregister<socket_mgr.SocketManager>();
    _tryUnregister<ConnectionPoolManager>();
    _tryUnregister<EnhancedRealtimeConnectionService>();
    _tryUnregister<realtime.IRealtimeConnectionService>();
    _tryUnregister<Map<String, dynamic>>();
    _tryUnregister<realtime_models.RealtimeConnectionConfig>();
    _tryUnregister<realtime.RealtimeConfig>();
    _tryUnregister<ConnectionFactory>();

    _logger.d('[ChatModuleInjection] ✅ Dispose complete — all chat deps unregistered');
  }

  /// Helper to safely unregister a type if registered.
  static void _tryUnregister<T extends Object>() {
    try {
      if (_getIt.isRegistered<T>()) {
        _getIt.unregister<T>();
      }
    } catch (e) {
      // Ignore - type may not be registered or may have dependencies
    }
  }

  /// Helper to safely unregister a named instance if registered.
  static void _tryUnregisterNamed<T extends Object>(String instanceName) {
    try {
      if (_getIt.isRegistered<T>(instanceName: instanceName)) {
        _getIt.unregister<T>(instanceName: instanceName);
      }
    } catch (e) {
      // Ignore - instance may not be registered
    }
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
      _getIt.registerSingleton<Logger>(_logger);
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

    // Connectivity
    if (!_getIt.isRegistered<Connectivity>()) {
      _getIt.registerSingleton<Connectivity>(Connectivity());
    }

    if (!_getIt.isRegistered<InternetConnectionChecker>()) {
      _getIt.registerLazySingleton<InternetConnectionChecker>(
        () => InternetConnectionChecker.instance,
      );
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

    // Current user ID (authoritative from ChatConfig)
    if (!_getIt.isRegistered<String>(instanceName: 'currentUserId')) {
      _getIt.registerSingleton<String>(
        config.currentUserId,
        instanceName: 'currentUserId',
      );
    }

    // RetryConfig
    if (!_getIt.isRegistered<app_retry.RetryConfig>()) {
      _getIt.registerSingleton<app_retry.RetryConfig>(
        app_retry.RetryConfig.realtime,
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

    _logger.d('ChatModule: External dependencies registered');
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

    if (!_getIt.isRegistered<IFileDownloader>()) {
      _getIt.registerLazySingleton<IFileDownloader>(
        () => createFileDownloader(_getIt<AppLogger>()),
      );
    }

    if (!_getIt.isRegistered<IFileDownloadManager>()) {
      _getIt.registerLazySingleton<IFileDownloadManager>(
        () => createFileDownloadManager(_getIt<AppLogger>()),
      );
    }

    if (!_getIt.isRegistered<IMediaGallerySaver>()) {
      _getIt.registerLazySingleton<IMediaGallerySaver>(
        () => GalMediaGallerySaver(
          _getIt<AppLogger>(),
          _getIt<IFileDownloader>(),
        ),
      );
    }

    if (!_getIt.isRegistered<DownloadFileUseCase>()) {
      _getIt.registerLazySingleton<DownloadFileUseCase>(
        () => DownloadFileUseCase(_getIt<IFileDownloader>()),
      );
    }

    if (!_getIt.isRegistered<SaveMediaToGalleryUseCase>()) {
      _getIt.registerLazySingleton<SaveMediaToGalleryUseCase>(
        () => SaveMediaToGalleryUseCase(
          mediaRepository: _getIt<IMediaRepository>(),
          gallerySaver: _getIt<IMediaGallerySaver>(),
          logger: _getIt<AppLogger>(),
        ),
      );
    }
  }

  /// Pre-register monitoring services before auto-generated deps.
  ///
  /// These interfaces are required by many auto-generated registrations
  /// (e.g., EnhancedCacheManager, SocketManager, etc.) but the auto-generated
  /// code expects Firebase implementations. In package mode, we register
  /// NoOp implementations (or config-provided ones) BEFORE init() runs.
  static void _registerMonitoringServices(ChatConfig config) {
    if (!_getIt.isRegistered<IPerformanceMonitor>()) {
      _getIt.registerSingleton<IPerformanceMonitor>(
        config.performanceMonitor ?? const NoOpPerformanceMonitor(),
      );
    }

    if (!_getIt.isRegistered<ICrashReporter>()) {
      _getIt.registerSingleton<ICrashReporter>(
        config.crashReporter ?? const NoOpCrashReporter(),
      );
    }

    if (!_getIt.isRegistered<IAnalyticsService>()) {
      _getIt.registerSingleton<IAnalyticsService>(
        config.analyticsService ?? const NoOpAnalyticsService(),
      );
    }
  }

  /// Override auto-generated registrations with config-aware versions.
  static void _registerConfigOverrides(ChatConfig config) {
    // NOTE: Monitoring services are now registered in _registerMonitoringServices
    // which runs BEFORE init() to satisfy dependencies.

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
        logger: _getIt<AppLogger>(),
        tokenProvider: _getIt<TokenProvider>(),
      ),
    );
  }
}
