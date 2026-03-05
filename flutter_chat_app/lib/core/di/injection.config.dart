// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_performance/firebase_performance.dart' as _i346;
import 'package:get_it/get_it.dart' as _i174;
import 'package:graphql_flutter/graphql_flutter.dart' as _i128;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker/internet_connection_checker.dart'
    as _i973;
import 'package:isar/isar.dart' as _i338;
import 'package:logger/logger.dart' as _i974;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/datasources/chat_info/chat_info_remote_datasource.dart'
    as _i933;
import '../../data/datasources/media/media_local_datasource.dart' as _i982;
import '../../data/datasources/media/media_remote_datasource.dart' as _i966;
import '../../data/datasources/message/message_local_datasource.dart' as _i75;
import '../../data/datasources/message/message_remote_datasource.dart' as _i102;
import '../../data/datasources/notification/push_notification_remote_datasource.dart'
    as _i1071;
import '../../data/datasources/permissions_datasource.dart' as _i656;
import '../../data/datasources/presence/presence_remote_datasource.dart'
    as _i428;
import '../../data/datasources/sticker/sticker_local_datasource.dart' as _i99;
import '../../data/datasources/user/user_local_datasource.dart' as _i439;
import '../../data/datasources/user/user_remote_datasource.dart' as _i404;
import '../../data/managers/sync_metadata_manager.dart' as _i407;
import '../../data/mappers/socket_io_event_mapper.dart' as _i976;
import '../../data/repositories/attachment_repository.dart' as _i431;
import '../../data/repositories/chat_info_repository_impl.dart' as _i855;
import '../../data/repositories/media_repository_impl.dart' as _i872;
import '../../data/repositories/message_repository_impl.dart' as _i564;
import '../../data/repositories/offline_first_repository.dart' as _i264;
import '../../data/repositories/permissions_repository_impl.dart' as _i760;
import '../../data/repositories/presence_repository_impl.dart' as _i759;
import '../../data/repositories/push_notification_repository_impl.dart'
    as _i602;
import '../../data/repositories/sticker_repository_impl.dart' as _i854;
import '../../data/repositories/user_repository_impl.dart' as _i790;
import '../../domain/repositories/i_attachment_repository.dart' as _i817;
import '../../domain/repositories/i_chat_info_repository.dart' as _i282;
import '../../domain/repositories/i_media_repository.dart' as _i394;
import '../../domain/repositories/i_message_repository.dart' as _i572;
import '../../domain/repositories/i_presence_repository.dart' as _i492;
import '../../domain/repositories/i_push_notification_repository.dart' as _i395;
import '../../domain/repositories/i_sticker_repository.dart' as _i211;
import '../../domain/repositories/permissions_repository.dart' as _i473;
import '../../domain/repositories/user_repository.dart' as _i271;
import '../../domain/usecases/chat_info/block_user_usecase.dart' as _i735;
import '../../domain/usecases/chat_info/get_notification_settings_usecase.dart'
    as _i450;
import '../../domain/usecases/chat_info/get_shared_media_usecase.dart' as _i436;
import '../../domain/usecases/chat_info/report_chat_usecase.dart' as _i34;
import '../../domain/usecases/chat_info/unblock_user_usecase.dart' as _i776;
import '../../domain/usecases/chat_info/update_notification_settings_usecase.dart'
    as _i939;
import '../../domain/usecases/message/add_reaction_usecase.dart' as _i409;
import '../../domain/usecases/message/delete_message_usecase.dart' as _i434;
import '../../domain/usecases/message/edit_message_usecase.dart' as _i203;
import '../../domain/usecases/message/get_messages_usecase.dart' as _i467;
import '../../domain/usecases/message/mark_as_read_usecase.dart' as _i848;
import '../../domain/usecases/message/remove_reaction_usecase.dart' as _i539;
import '../../domain/usecases/message/send_message_usecase.dart' as _i67;
import '../../domain/usecases/message/upload_file_usecase.dart' as _i196;
import '../../domain/usecases/notification/send_push_notification_usecase.dart'
    as _i370;
import '../../domain/usecases/request_permission_usecase.dart' as _i198;
import '../../features/auth/data/datasources/auth/auth_remote_datasource.dart'
    as _i1025;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/presentation/blocs/auth/auth_bloc.dart' as _i331;
import '../../features/chat/data/datasources/chat/chat_local_datasource.dart'
    as _i1011;
import '../../features/chat/data/datasources/chat/chat_remote_datasource.dart'
    as _i351;
import '../../features/chat/data/datasources/chat_object/chat_object_remote_datasource.dart'
    as _i293;
import '../../features/chat/data/datasources/draft/draft_local_datasource.dart'
    as _i711;
import '../../features/chat/data/repositories/chat_repository.dart' as _i796;
import '../../features/chat/data/repositories/draft_repository.dart' as _i1017;
import '../../features/chat/domain/repositories/i_chat_repository.dart' as _i81;
import '../../features/chat/domain/repositories/i_draft_repository.dart'
    as _i1034;
import '../../features/chat/domain/usecases/chat/create_group_usecase.dart'
    as _i224;
import '../../features/chat/domain/usecases/chat/delete_conversation_usecase.dart'
    as _i585;
import '../../features/chat/domain/usecases/chat/edit_group_usecase.dart'
    as _i412;
import '../../features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart'
    as _i899;
import '../../features/chat/domain/usecases/chat/get_conversations_usecase.dart'
    as _i787;
import '../../features/chat/domain/usecases/chat/get_local_conversations_usecase.dart'
    as _i163;
import '../../features/chat/domain/usecases/chat/leave_conversation_usecase.dart'
    as _i462;
import '../../features/chat/domain/usecases/chat/persist_incoming_message_usecase.dart'
    as _i962;
import '../../features/chat/domain/usecases/chat/search_conversations_usecase.dart'
    as _i130;
import '../../features/chat/domain/usecases/chat/search_messages_usecase.dart'
    as _i56;
import '../../features/chat/domain/usecases/chat/update_group_usecase.dart'
    as _i277;
import '../../features/chat/domain/usecases/draft/get_all_chat_drafts_usecase.dart'
    as _i930;
import '../../features/chat/domain/usecases/draft/get_chat_draft_usecase.dart'
    as _i769;
import '../../features/chat/domain/usecases/draft/remove_chat_draft_usecase.dart'
    as _i185;
import '../../features/chat/domain/usecases/draft/save_chat_draft_usecase.dart'
    as _i77;
import '../../features/chat/domain/usecases/draft/watch_chat_drafts_usecase.dart'
    as _i222;
import '../../features/chat/presentation/blocs/chat/chat_bloc.dart' as _i863;
import '../../features/chat/presentation/blocs/chat_composer/chat_composer_bloc.dart'
    as _i383;
import '../../features/chat/presentation/blocs/chat_draft/chat_draft_bloc.dart'
    as _i209;
import '../../features/chat/presentation/blocs/message_search/message_search_bloc.dart'
    as _i704;
import '../../presentation/blocs/chat_info/chat_info_bloc.dart' as _i915;
import '../../presentation/blocs/chat_members/chat_members_bloc.dart' as _i1028;
import '../../presentation/blocs/connection/connection_bloc.dart' as _i81;
import '../../presentation/blocs/conversation_detail/conversation_detail_bloc.dart'
    as _i101;
import '../../presentation/blocs/locale/locale_cubit.dart' as _i128;
import '../../presentation/blocs/media/media_bloc.dart' as _i921;
import '../../presentation/blocs/message/message_bloc.dart' as _i230;
import '../../presentation/blocs/message_queue/message_queue_bloc.dart'
    as _i379;
import '../../presentation/blocs/permissions/permissions_bloc.dart' as _i1070;
import '../../presentation/blocs/realtime/realtime_message_bloc.dart' as _i88;
import '../../presentation/blocs/realtime_connection/realtime_connection_bloc.dart'
    as _i53;
import '../../presentation/blocs/theme/theme_cubit.dart' as _i473;
import '../../presentation/blocs/typing/typing_bloc.dart' as _i313;
import '../../presentation/blocs/user/user_bloc.dart' as _i222;
import '../cache/app_cache_manager.dart' as _i699;
import '../cache/cache_sync_strategy.dart' as _i514;
import '../cache/enhanced_cache_manager.dart' as _i604;
import '../cache/media_cache_manager.dart' as _i163;
import '../error/retry_config.dart' as _i459;
import '../integration_hub.dart' as _i428;
import '../monitoring/analytics_manager.dart' as _i648;
import '../monitoring/i_analytics_service.dart' as _i451;
import '../monitoring/i_performance_monitor.dart' as _i610;
import '../monitoring/message_delivery_tracker.dart' as _i475;
import '../network/api_client.dart' as _i557;
import '../network/auth/token_manager.dart' as _i694;
import '../network/auth/token_provider.dart' as _i211;
import '../network/auth/token_repository.dart' as _i328;
import '../network/cache/api_cache_manager.dart' as _i931;
import '../network/cache/network_response_cache.dart' as _i903;
import '../network/connection_info.dart' as _i410;
import '../network/connectivity/connectivity_service.dart' as _i888;
import '../network/enhanced_socket_manager.dart' as _i301;
import '../network/graphql_client.dart' as _i788;
import '../network/http/dio_http_client.dart' as _i152;
import '../network/http/http_client_interface.dart' as _i924;
import '../network/monitoring/api_request_tracker.dart' as _i1005;
import '../network/network_info.dart' as _i932;
import '../network/network_optimizer.dart' as _i199;
import '../network/realtime/connection_pool_manager.dart' as _i567;
import '../network/realtime/enhanced_realtime_connection_service.dart' as _i225;
import '../network/realtime/models/realtime_connection_config.dart' as _i783;
import '../network/realtime/realtime_connection_service.dart' as _i287;
import '../network/socket_analytics.dart' as _i604;
import '../network/socket_manager.dart' as _i498;
import '../network/socket_rate_limiter.dart' as _i727;
import '../network/websocket_client.dart' as _i777;
import '../services/animation_service.dart' as _i855;
import '../services/app_service.dart' as _i479;
import '../services/attachment_queue_service.dart' as _i567;
import '../services/auth_service.dart' as _i745;
import '../services/background_sync_service.dart' as _i200;
import '../services/chat_message_service.dart' as _i1060;
import '../services/chat_module_event_bus.dart' as _i1030;
import '../services/connectivity_analyzer_service.dart' as _i286;
import '../services/connectivity_service.dart' as _i47;
import '../services/cross_platform_file_service.dart' as _i590;
import '../services/current_user_provider.dart' as _i113;
import '../services/database_service.dart' as _i665;
import '../services/device_capability_service.dart' as _i98;
import '../services/foreground_sync_service.dart' as _i920;
import '../services/frequent_reaction_service.dart' as _i537;
import '../services/graphql_subscription_service.dart' as _i98;
import '../services/image_editor_service.dart' as _i930;
import '../services/integration_service.dart' as _i808;
import '../services/local_storage_service.dart' as _i527;
import '../services/localization_service.dart' as _i999;
import '../services/location_service.dart' as _i669;
import '../services/media_cache.dart' as _i393;
import '../services/media_processing_service.dart' as _i695;
import '../services/memory_optimizer.dart' as _i803;
import '../services/message_queue_service.dart' as _i556;
import '../services/messaging_service.dart' as _i914;
import '../services/notification_handler_service.dart' as _i89;
import '../services/offline_operation_processor.dart' as _i985;
import '../services/offline_queue_service.dart' as _i520;
import '../services/performance_service.dart' as _i910;
import '../services/permissions_service.dart' as _i179;
import '../services/presence_service.dart' as _i219;
import '../services/realtime_connection_service.dart' as _i357;
import '../services/realtime_messaging_service.dart' as _i706;
import '../services/realtime_service.dart' as _i301;
import '../services/resource_manager_service.dart' as _i558;
import '../services/sso_auth_service.dart' as _i349;
import '../services/state_persistence_service.dart' as _i797;
import '../services/voice_note_playback_manager.dart' as _i46;
import '../storage/local_storage.dart' as _i329;
import '../storage/tombstone_store.dart' as _i677;
import '../utils/isolate_manager.dart' as _i686;
import '../utils/logger.dart' as _i221;
import '../utils/proto_converter.dart' as _i995;
import '../utils/system_resources.dart' as _i260;
import 'modules/external_module.dart' as _i649;

const String _dev = 'dev';
const String _prod = 'prod';
const String _standalone = 'standalone';
const String _staging = 'staging';
const String _test = 'test';

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final externalModule = _$ExternalModule();
    gh.factory<_i383.ChatComposerBloc>(() => _i383.ChatComposerBloc());
    gh.singleton<_i221.AppLogger>(() => externalModule.appLogger);
    gh.lazySingleton<_i163.MediaCacheManager>(() => _i163.MediaCacheManager());
    gh.lazySingleton<_i514.CacheSyncStrategy>(() => _i514.CacheSyncStrategy());
    gh.lazySingleton<_i995.ProtoConverter>(() => _i995.ProtoConverter());
    gh.lazySingleton<_i260.SystemResourceMonitor>(
        () => _i260.SystemResourceMonitor());
    gh.lazySingletonAsync<_i527.LocalStorageService>(
        () => _i527.LocalStorageService.init());
    gh.lazySingleton<_i590.CrossPlatformFileService>(
        () => _i590.CrossPlatformFileService());
    gh.lazySingleton<_i1030.ChatModuleEventBus>(
        () => _i1030.ChatModuleEventBus());
    gh.lazySingleton<_i558.ResourceManagerService>(
        () => _i558.ResourceManagerService());
    gh.lazySingleton<_i200.BackgroundSyncService>(
        () => _i200.BackgroundSyncService());
    gh.lazySingleton<_i695.MediaProcessingServiceFactory>(
        () => _i695.MediaProcessingServiceFactory());
    gh.lazySingleton<_i695.MediaProcessingService>(
        () => _i695.MediaProcessingService());
    gh.lazySingleton<_i930.ImageEditorService>(
        () => _i930.ImageEditorService());
    gh.lazySingleton<_i982.MediaLocalDataSourceImpl>(
        () => _i982.MediaLocalDataSourceImpl());
    gh.lazySingleton<_i976.SocketIOEventMapper>(
        () => _i976.SocketIOEventMapper());
    gh.lazySingleton<_i271.UserRepository>(() => _i790.UserRepositoryImpl(
          localDataSource: gh<_i439.UserLocalDataSource>(),
          remoteDataSource: gh<_i404.UserRemoteDataSource>(),
          networkInfo: gh<_i932.NetworkInfo>(),
          logger: gh<_i221.AppLogger>(),
          performanceMonitor: gh<_i610.IPerformanceMonitor>(),
        ));
    gh.lazySingleton<_i933.IChatInfoRemoteDataSource>(
        () => _i933.ChatInfoRemoteDataSource(gh<_i788.GraphQLClientWrapper>()));
    gh.lazySingleton<_i903.NetworkResponseCache>(
        () => _i903.NetworkResponseCache(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i694.TokenManager>(
        () => _i694.TokenManager(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i966.MediaRemoteDataSourceImpl>(
        () => _i966.MediaRemoteDataSourceImpl(
              httpClient: gh<_i519.Client>(),
              baseUrl: gh<String>(instanceName: 'baseUrl'),
            ));
    gh.factory<_i656.PermissionsDataSource>(
        () => _i656.MobilePermissionsDataSource());
    gh.lazySingleton<_i410.ConnectionInfo>(() => _i410.ConnectionInfo(
          gh<_i895.Connectivity>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i1071.PushNotificationRemoteDataSource>(() =>
        _i1071.PushNotificationRemoteDataSource(
            gh<_i788.GraphQLClientWrapper>()));
    gh.lazySingleton<_i428.PresenceRemoteDataSource>(
        () => _i428.PresenceRemoteDataSource(gh<_i788.GraphQLClientWrapper>()));
    gh.lazySingleton<_i329.LocalStorage>(
        () => _i329.LocalStorageImpl(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i349.SsoAuthService>(
      () => _i349.SsoAuthService(),
      registerFor: {
        _dev,
        _prod,
        _standalone,
      },
    );
    gh.lazySingleton<_i475.MessageDeliveryTracker>(
        () => _i475.MessageDeliveryTracker(gh<_i610.IPerformanceMonitor>()));
    gh.lazySingleton<_i47.ConnectivityService>(() => _i47.ConnectivityService(
          gh<_i895.Connectivity>(),
          gh<_i973.InternetConnectionChecker>(),
        ));
    gh.lazySingleton<_i393.MediaCache>(
        () => _i393.MediaCache(logger: gh<_i221.AppLogger>()));
    gh.lazySingleton<_i99.StickerLocalDataSource>(
        () => _i99.StickerLocalDataSource(
              gh<_i460.SharedPreferences>(),
              gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i745.AuthService>(
        () => _i745.AuthService(gh<_i328.TokenRepository>()));
    gh.lazySingleton<_i803.MemoryOptimizer>(() => _i803.MemoryOptimizer(
        performanceMonitor: gh<_i610.IPerformanceMonitor>()));
    gh.lazySingleton<_i282.IChatInfoRepository>(
        () => _i855.ChatInfoRepositoryImpl(
              remoteDataSource: gh<_i933.IChatInfoRemoteDataSource>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i711.DraftLocalDataSource>(
        () => _i711.DraftLocalDataSourceImpl(gh<_i338.Isar>()));
    gh.lazySingleton<_i264.OfflineFirstRepositoryImpl>(
        () => _i264.OfflineFirstRepositoryImpl(
              gh<_i665.DatabaseService>(),
              gh<_i47.ConnectivityService>(),
            ));
    gh.lazySingleton<_i1005.ApiRequestTracker>(() => _i1005.ApiRequestTracker(
          gh<_i221.AppLogger>(),
          gh<_i451.IAnalyticsService>(),
        ));
    gh.lazySingleton<_i557.ApiClient>(() => _i557.ApiClient(
          httpClient: gh<_i924.IHttpClient>(),
          requestTracker: gh<_i1005.ApiRequestTracker>(),
          logger: gh<_i221.AppLogger>(),
          analytics: gh<_i451.IAnalyticsService>(),
          cacheManager: gh<_i931.ApiCacheManager>(),
        ));
    gh.factory<_i498.SocketManager>(() => _i498.SocketManager(
          serverUrl: gh<String>(instanceName: 'socketUrl'),
          options: gh<Map<String, dynamic>>(),
          logger: gh<_i221.AppLogger>(),
          analytics: gh<_i451.IAnalyticsService>(),
          tokenProvider: gh<_i211.TokenProvider>(),
        ));
    gh.lazySingleton<_i787.IAuthRepository>(() => _i153.AuthRepositoryImpl(
          authRemoteDataSource: gh<_i1025.AuthRemoteDataSource>(),
          userLocalDataSource: gh<_i439.UserLocalDataSource>(),
          networkInfo: gh<_i932.NetworkInfo>(),
          logger: gh<_i221.AppLogger>(),
          performanceMonitor: gh<_i610.IPerformanceMonitor>(),
        ));
    gh.lazySingleton<_i808.IntegrationService>(
        () => _i808.IntegrationService(gh<_i665.DatabaseService>()));
    gh.lazySingleton<_i479.AppService>(
        () => _i479.AppService(gh<_i665.DatabaseService>()));
    gh.lazySingleton<_i1011.ChatLocalDataSourceImpl>(
        () => _i1011.ChatLocalDataSourceImpl(gh<_i665.DatabaseService>()));
    gh.lazySingleton<_i395.IPushNotificationRepository>(
        () => _i602.PushNotificationRepositoryImpl(
              remoteDataSource: gh<_i1071.PushNotificationRemoteDataSource>(),
              networkInfo: gh<_i932.NetworkInfo>(),
              logger: gh<_i221.AppLogger>(),
              performanceMonitor: gh<_i610.IPerformanceMonitor>(),
            ));
    gh.lazySingleton<_i567.ConnectionPoolManager>(
        () => _i567.ConnectionPoolManager(
              connectionFactory: gh<_i567.ConnectionFactory>(),
              maxPoolSize: gh<int>(instanceName: 'connectionPoolMaxPoolSize'),
              maxConnectionLifetime:
                  gh<int>(instanceName: 'connectionPoolMaxConnectionLifetime'),
              maxIdleTime: gh<int>(instanceName: 'connectionPoolMaxIdleTime'),
              cleanupInterval:
                  gh<int>(instanceName: 'connectionPoolCleanupInterval'),
              healthCheckInterval:
                  gh<int>(instanceName: 'connectionPoolHealthCheckInterval'),
            ));
    gh.lazySingleton<_i537.FrequentReactionService>(
        () => _i537.FrequentReactionService(
              gh<_i788.GraphQLClientWrapper>(),
              gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i404.UserRemoteDataSourceImpl>(
        () => _i404.UserRemoteDataSourceImpl(gh<_i788.GraphQLClientWrapper>()));
    gh.lazySingleton<_i604.EnhancedCacheManager>(
        () => _i604.EnhancedCacheManager(
              localStorage: gh<_i329.LocalStorage>(),
              performanceMonitor: gh<_i610.IPerformanceMonitor>(),
            ));
    gh.lazySingleton<_i113.CurrentUserProvider>(
        () => _i113.CurrentUserProviderImpl(
              userLocalDataSource: gh<_i439.UserLocalDataSource>(),
              tokenRepository: gh<_i328.TokenRepository>(),
            ));
    gh.lazySingleton<_i855.AnimationService>(() => _i855.AnimationService(
          gh<_i98.DeviceCapabilityService>(),
          gh<_i610.IPerformanceMonitor>(),
        ));
    gh.lazySingleton<_i686.IsolateManager>(() => _i686.IsolateManager(
          gh<_i610.IPerformanceMonitor>(),
          gh<_i260.SystemResourceMonitor>(),
        ));
    gh.lazySingleton<_i910.PerformanceService>(
      () => _i910.PerformanceService(gh<_i346.FirebasePerformance>()),
      registerFor: {_standalone},
    );
    gh.lazySingleton<_i888.ConnectivityServiceImpl>(
        () => _i888.ConnectivityServiceImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i286.ConnectivityAnalyzerService>(
        () => _i286.ConnectivityAnalyzerService(gh<_i895.Connectivity>()));
    gh.factory<_i222.UserBloc>(
        () => _i222.UserBloc(userRepository: gh<_i271.UserRepository>()));
    gh.lazySingleton<_i152.DioHttpClient>(() => _i152.DioHttpClient(
          gh<_i221.AppLogger>(),
          gh<_i1005.ApiRequestTracker>(),
          gh<_i931.ApiCacheManager>(),
        ));
    gh.lazySingleton<_i428.IntegrationHub>(
        () => _i428.IntegrationHub(gh<_i665.DatabaseService>()));
    gh.factory<_i962.PersistIncomingMessageUseCase>(
        () => _i962.PersistIncomingMessageUseCase(
              localDataSource: gh<_i1011.ChatLocalDataSource>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i677.TombstoneStore>(
        () => _i677.TombstoneStore(gh<_i329.LocalStorage>()));
    gh.lazySingleton<_i999.LocalizationService>(
        () => _i999.LocalizationService(gh<_i329.LocalStorage>()));
    gh.lazySingleton<_i439.UserLocalDataSourceImpl>(
        () => _i439.UserLocalDataSourceImpl(gh<_i329.LocalStorage>()));
    gh.factory<_i128.LocaleCubit>(
        () => _i128.LocaleCubit(gh<_i329.LocalStorage>()));
    gh.factory<_i473.ThemeCubit>(
        () => _i473.ThemeCubit(gh<_i329.LocalStorage>()));
    gh.lazySingleton<_i492.IPresenceRepository>(
        () => _i759.PresenceRepositoryImpl(
              gh<_i428.PresenceRemoteDataSource>(),
              gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i777.WebSocketClient>(() => _i777.WebSocketClient(
          serverUrl: gh<String>(instanceName: 'socketUrl'),
          options: gh<Map<String, dynamic>>(),
          reconnectConfig: gh<_i459.RetryConfig>(),
        ));
    gh.factory<_i648.AnalyticsManager>(
      () => _i648.DefaultAnalyticsManager(
          providers: gh<List<_i648.AnalyticsManager>>()),
      registerFor: {
        _staging,
        _prod,
      },
    );
    gh.factory<_i604.SocketAnalytics>(() => _i604.SocketAnalytics(
          analyticsService: gh<_i451.IAnalyticsService>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i1034.IDraftRepository>(() => _i1017.DraftRepositoryImpl(
          localDataSource: gh<_i711.DraftLocalDataSource>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i407.SyncMetadataManager>(() => _i407.SyncMetadataManager(
          isar: gh<_i338.Isar>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i706.RealtimeMessagingService>(
        () => _i706.RealtimeMessagingService(
              gh<_i932.NetworkInfo>(),
              serverUrl: gh<String>(instanceName: 'socketUrl'),
            ));
    gh.lazySingleton<_i797.StatePersistenceService>(
        () => _i797.StatePersistenceService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i225.EnhancedRealtimeConnectionService>(
        () => _i225.EnhancedRealtimeConnectionService(
              gh<_i221.AppLogger>(),
              gh<_i924.IHttpClient>(),
              gh<_i888.IConnectivityService>(),
              gh<_i783.RealtimeConnectionConfig>(),
              gh<_i287.RealtimeConfig>(),
            ));
    gh.factory<_i331.AuthBloc>(
      () => _i331.AuthBloc(
        authRepository: gh<_i787.IAuthRepository>(),
        preferences: gh<_i460.SharedPreferences>(),
        ssoAuthService: gh<_i349.SsoAuthService>(),
      ),
      registerFor: {
        _dev,
        _prod,
        _standalone,
      },
    );
    gh.lazySingleton<_i293.IChatObjectRemoteDataSource>(
        () => _i293.ChatObjectRemoteDataSource(
              gh<_i788.GraphQLClientWrapper>(),
              gh<_i361.Dio>(instanceName: 'uploadClient'),
            ));
    gh.factory<_i648.AnalyticsManager>(
      () => _i648.NoOpAnalyticsManager(),
      registerFor: {
        _test,
        _dev,
      },
    );
    gh.lazySingleton<_i211.IStickerRepository>(
        () => _i854.StickerRepositoryImpl(
              gh<_i99.StickerLocalDataSource>(),
              gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i394.IMediaRepository>(() => _i872.MediaRepositoryImpl(
          remoteDataSource: gh<_i966.IMediaRemoteDataSource>(),
          localDataSource: gh<_i982.IMediaLocalDataSource>(),
          networkInfo: gh<_i932.INetworkInfo>(),
        ));
    gh.lazySingleton<_i572.IMessageRepository>(
        () => _i564.MessageRepositoryImpl(
              localDataSource: gh<_i75.MessageLocalDataSource>(),
              remoteDataSource: gh<_i102.IMessageRemoteDataSource>(),
              cacheManager: gh<_i699.AppCacheManager>(),
              cacheSyncStrategy: gh<_i514.CacheSyncStrategy>(),
              mediaCacheManager: gh<_i163.MediaCacheManager>(),
              networkInfo: gh<_i932.NetworkInfo>(),
              logger: gh<_i221.AppLogger>(),
              performanceMonitor: gh<_i610.IPerformanceMonitor>(),
            ));
    gh.lazySingleton<_i1025.AuthRemoteDataSourceImpl>(
        () => _i1025.AuthRemoteDataSourceImpl(
              gh<_i788.GraphQLClientWrapper>(),
              gh<_i328.TokenRepository>(),
            ));
    gh.factory<_i473.PermissionsRepository>(
        () => _i760.PermissionsRepositoryImpl(
              gh<_i656.PermissionsDataSource>(),
              gh<_i460.SharedPreferences>(),
              gh<_i221.AppLogger>(),
            ));
    gh.factory<_i370.SendPushNotificationUseCase>(
        () => _i370.SendPushNotificationUseCase(
              repository: gh<_i395.IPushNotificationRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.factory<_i939.UpdateNotificationSettingsUseCase>(() =>
        _i939.UpdateNotificationSettingsUseCase(
            gh<_i282.IChatInfoRepository>()));
    gh.factory<_i735.BlockUserUseCase>(
        () => _i735.BlockUserUseCase(gh<_i282.IChatInfoRepository>()));
    gh.factory<_i34.ReportChatUseCase>(
        () => _i34.ReportChatUseCase(gh<_i282.IChatInfoRepository>()));
    gh.factory<_i776.UnblockUserUseCase>(
        () => _i776.UnblockUserUseCase(gh<_i282.IChatInfoRepository>()));
    gh.factory<_i450.GetNotificationSettingsUseCase>(() =>
        _i450.GetNotificationSettingsUseCase(gh<_i282.IChatInfoRepository>()));
    gh.factory<_i436.GetSharedMediaUseCase>(
        () => _i436.GetSharedMediaUseCase(gh<_i282.IChatInfoRepository>()));
    gh.lazySingleton<_i357.RealtimeConnectionService>(
        () => _i357.RealtimeConnectionService(
              webSocketUrl: gh<String>(instanceName: 'graphQlWsUrl'),
              httpUrl: gh<String>(instanceName: 'graphQlApiUrl'),
              authToken: gh<String>(instanceName: 'authToken'),
              connectivityAnalyzer: gh<_i286.ConnectivityAnalyzerService>(),
              connectivityService: gh<_i47.ConnectivityService>(),
            ));
    gh.lazySingleton<_i199.NetworkOptimizer>(() => _i199.NetworkOptimizer(
          connectivityService: gh<_i47.ConnectivityService>(),
          performanceMonitor: gh<_i610.IPerformanceMonitor>(),
        ));
    gh.factory<_i81.ConnectionBloc>(() => _i81.ConnectionBloc(
          realtimeConnectionService: gh<_i357.RealtimeConnectionService>(),
          connectivityAnalyzerService: gh<_i286.ConnectivityAnalyzerService>(),
        ));
    gh.factory<_i930.GetAllChatDraftsUseCase>(
        () => _i930.GetAllChatDraftsUseCase(gh<_i1034.IDraftRepository>()));
    gh.factory<_i77.SaveChatDraftUseCase>(
        () => _i77.SaveChatDraftUseCase(gh<_i1034.IDraftRepository>()));
    gh.factory<_i769.GetChatDraftUseCase>(
        () => _i769.GetChatDraftUseCase(gh<_i1034.IDraftRepository>()));
    gh.factory<_i185.RemoveChatDraftUseCase>(
        () => _i185.RemoveChatDraftUseCase(gh<_i1034.IDraftRepository>()));
    gh.factory<_i222.WatchChatDraftsUseCase>(
        () => _i222.WatchChatDraftsUseCase(gh<_i1034.IDraftRepository>()));
    gh.factory<_i198.RequestPermissionUseCase>(() =>
        _i198.RequestPermissionUseCase(gh<_i473.PermissionsRepository>()));
    gh.lazySingleton<_i914.MessagingService>(() =>
        _i914.MessagingService(webSocketClient: gh<_i777.WebSocketClient>()));
    gh.factory<_i915.ChatInfoBloc>(() => _i915.ChatInfoBloc(
          getSharedMediaUseCase: gh<_i436.GetSharedMediaUseCase>(),
          getNotificationSettingsUseCase:
              gh<_i450.GetNotificationSettingsUseCase>(),
          updateNotificationSettingsUseCase:
              gh<_i939.UpdateNotificationSettingsUseCase>(),
          blockUserUseCase: gh<_i735.BlockUserUseCase>(),
          unblockUserUseCase: gh<_i776.UnblockUserUseCase>(),
          reportChatUseCase: gh<_i34.ReportChatUseCase>(),
          repository: gh<_i282.IChatInfoRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i98.GraphQLSubscriptionService>(
        () => _i98.GraphQLSubscriptionService(
              gh<_i357.RealtimeConnectionService>(),
              gh<_i128.GraphQLClient>(),
            ));
    gh.lazySingleton<_i817.IAttachmentRepository>(
        () => _i431.AttachmentRepository(
              gh<_i293.IChatObjectRemoteDataSource>(),
              gh<_i221.AppLogger>(),
            ));
    gh.factory<_i209.ChatDraftBloc>(() => _i209.ChatDraftBloc(
          watchChatDrafts: gh<_i222.WatchChatDraftsUseCase>(),
          getChatDraft: gh<_i769.GetChatDraftUseCase>(),
          saveChatDraft: gh<_i77.SaveChatDraftUseCase>(),
          removeChatDraft: gh<_i185.RemoveChatDraftUseCase>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i179.PermissionsService>(() => _i179.PermissionsService(
          gh<_i473.PermissionsRepository>(),
          gh<_i198.RequestPermissionUseCase>(),
          gh<_i451.IAnalyticsService>(),
          gh<_i221.AppLogger>(),
        ));
    gh.factory<_i196.UploadFileUseCase>(() => _i196.UploadFileUseCase(
          dataSource: gh<_i293.IChatObjectRemoteDataSource>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i88.RealtimeMessageBloc>(
        () => _i88.RealtimeMessageBloc(gh<_i706.RealtimeMessagingService>()));
    gh.lazySingletonAsync<_i567.AttachmentQueueService>(
        () async => _i567.AttachmentQueueService(
              gh<_i817.IAttachmentRepository>(),
              gh<_i47.ConnectivityService>(),
              await getAsync<_i527.LocalStorageService>(),
              gh<_i393.MediaCache>(),
              gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i301.EnhancedSocketManager>(
        () => _i301.EnhancedSocketManager(
              gh<_i498.SocketManager>(),
              gh<_i604.SocketAnalytics>(),
              gh<_i727.SocketRateLimiter>(),
            ));
    gh.factory<_i921.MediaBloc>(() => _i921.MediaBloc(
          mediaRepository: gh<_i394.IMediaRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i301.RealtimeService>(() => _i301.RealtimeService(
        socketManager: gh<_i301.EnhancedSocketManager>()));
    gh.lazySingleton<_i102.MessageRemoteDataSourceImpl>(
        () => _i102.MessageRemoteDataSourceImpl(
              gh<_i788.GraphQLClientWrapper>(),
              gh<_i706.RealtimeMessagingService>(),
              gh<_i976.SocketIOEventMapper>(),
            ));
    gh.factory<_i434.DeleteMessageUseCase>(() => _i434.DeleteMessageUseCase(
          repository: gh<_i572.IMessageRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i409.AddReactionUseCase>(() => _i409.AddReactionUseCase(
          repository: gh<_i572.IMessageRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i467.GetMessagesUseCase>(() => _i467.GetMessagesUseCase(
          repository: gh<_i572.IMessageRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i203.EditMessageUseCase>(() => _i203.EditMessageUseCase(
          repository: gh<_i572.IMessageRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i539.RemoveReactionUseCase>(() => _i539.RemoveReactionUseCase(
          repository: gh<_i572.IMessageRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i67.SendMessageUseCase>(() => _i67.SendMessageUseCase(
          repository: gh<_i572.IMessageRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i848.MarkAsReadUseCase>(() => _i848.MarkAsReadUseCase(
          repository: gh<_i572.IMessageRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingleton<_i219.PresenceService>(() => _i219.PresenceService(
          repository: gh<_i492.IPresenceRepository>(),
          realtimeService: gh<_i301.RealtimeService>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingletonAsync<_i556.MessageQueueService>(
        () async => _i556.MessageQueueService(
              gh<_i572.IMessageRepository>(),
              await getAsync<_i527.LocalStorageService>(),
              gh<_i47.ConnectivityService>(),
              gh<_i287.IRealtimeConnectionService>(),
              await getAsync<_i567.AttachmentQueueService>(),
            ));
    gh.lazySingleton<_i351.IChatRemoteDataSource>(
        () => _i351.ChatRemoteDataSourceImpl(
              gh<_i788.GraphQLClientWrapper>(),
              gh<_i301.EnhancedSocketManager>(),
            ));
    gh.lazySingleton<_i669.ILocationService>(() => _i669.LocationService(
          gh<_i179.PermissionsService>(),
          gh<_i221.AppLogger>(),
        ));
    gh.factory<_i1070.PermissionsBloc>(() => _i1070.PermissionsBloc(
          gh<_i179.PermissionsService>(),
          gh<_i221.AppLogger>(),
        ));
    gh.factoryAsync<_i379.MessageQueueBloc>(() async =>
        _i379.MessageQueueBloc(await getAsync<_i556.MessageQueueService>()));
    gh.factory<_i313.TypingBloc>(() => _i313.TypingBloc(
          realtimeService: gh<_i301.RealtimeService>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.lazySingletonAsync<_i1060.ChatMessageService>(
        () async => _i1060.ChatMessageService(
              await getAsync<_i556.MessageQueueService>(),
              gh<_i706.RealtimeMessagingService>(),
              gh<_i976.SocketIOEventMapper>(),
              gh<_i572.IMessageRepository>(),
            ));
    gh.factory<_i53.RealtimeConnectionBloc>(() => _i53.RealtimeConnectionBloc(
          realtimeService: gh<_i301.RealtimeService>(),
          connectivityService: gh<_i47.ConnectivityService>(),
        ));
    gh.lazySingleton<_i81.IChatRepository>(() => _i796.ChatRepositoryImpl(
          localDataSource: gh<_i1011.ChatLocalDataSource>(),
          remoteDataSource: gh<_i351.IChatRemoteDataSource>(),
          networkInfo: gh<_i932.INetworkInfo>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i230.MessageBloc>(() => _i230.MessageBloc(
          getMessages: gh<_i467.GetMessagesUseCase>(),
          sendMessage: gh<_i67.SendMessageUseCase>(),
          editMessage: gh<_i203.EditMessageUseCase>(),
          deleteMessage: gh<_i434.DeleteMessageUseCase>(),
          markAsRead: gh<_i848.MarkAsReadUseCase>(),
          addReaction: gh<_i409.AddReactionUseCase>(),
          removeReaction: gh<_i539.RemoveReactionUseCase>(),
          attachmentRepository: gh<_i817.IAttachmentRepository>(),
          cacheSyncStrategy: gh<_i514.CacheSyncStrategy>(),
          realtimeService: gh<_i301.RealtimeService>(),
          locationService: gh<_i669.ILocationService>(),
          syncMetadataManager: gh<_i407.SyncMetadataManager>(),
          frequentReactionService: gh<_i537.FrequentReactionService>(),
          sendPushNotification: gh<_i370.SendPushNotificationUseCase>(),
          tombstoneStore: gh<_i677.TombstoneStore>(),
          voiceNotePlaybackManager: gh<_i46.VoiceNotePlaybackManager>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i787.GetConversationsUseCase>(
        () => _i787.GetConversationsUseCase(
              repository: gh<_i81.IChatRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.factory<_i224.CreateGroupUseCase>(() => _i224.CreateGroupUseCase(
          repository: gh<_i81.IChatRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i462.LeaveConversationUseCase>(
        () => _i462.LeaveConversationUseCase(
              repository: gh<_i81.IChatRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.factory<_i277.UpdateGroupUseCase>(() => _i277.UpdateGroupUseCase(
          repository: gh<_i81.IChatRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i585.DeleteConversationUseCase>(
        () => _i585.DeleteConversationUseCase(
              repository: gh<_i81.IChatRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.factory<_i412.EditGroupUseCase>(() => _i412.EditGroupUseCase(
          repository: gh<_i81.IChatRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i130.SearchConversationsUseCase>(
        () => _i130.SearchConversationsUseCase(
              repository: gh<_i81.IChatRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.factory<_i899.GetConversationDetailUseCase>(
        () => _i899.GetConversationDetailUseCase(
              repository: gh<_i81.IChatRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.factory<_i163.GetLocalConversationsUseCase>(
        () => _i163.GetLocalConversationsUseCase(
              repository: gh<_i81.IChatRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i985.OfflineOperationProcessor>(
        () => _i985.OfflineOperationProcessor(
              messageRepository: gh<_i572.IMessageRepository>(),
              chatRepository: gh<_i81.IChatRepository>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i920.ForegroundSyncService>(
        () => _i920.ForegroundSyncService(
              repository: gh<_i81.IChatRepository>(),
              eventBus: gh<_i1030.ChatModuleEventBus>(),
              logger: gh<_i221.AppLogger>(),
            ));
    gh.lazySingleton<_i89.NotificationHandlerService>(
        () => _i89.NotificationHandlerService(
              logger: gh<_i974.Logger>(),
              chatRepository: gh<_i81.IChatRepository>(),
            ));
    gh.lazySingleton<_i520.OfflineQueueService>(() => _i520.OfflineQueueService(
          isar: gh<_i338.Isar>(),
          networkInfo: gh<_i932.INetworkInfo>(),
          logger: gh<_i221.AppLogger>(),
          processor: gh<_i985.OfflineOperationProcessor>(),
        ));
    gh.factory<_i56.SearchMessagesUseCase>(() =>
        _i56.SearchMessagesUseCase(repository: gh<_i81.IChatRepository>()));
    gh.factory<_i704.MessageSearchBloc>(() => _i704.MessageSearchBloc(
          searchMessages: gh<_i56.SearchMessagesUseCase>(),
          logger: gh<_i221.AppLogger>(),
        ));
    gh.factory<_i863.ChatBloc>(() => _i863.ChatBloc(
          gh<_i787.GetConversationsUseCase>(),
          gh<_i163.GetLocalConversationsUseCase>(),
          gh<_i899.GetConversationDetailUseCase>(),
          gh<_i224.CreateGroupUseCase>(),
          gh<_i277.UpdateGroupUseCase>(),
          gh<_i462.LeaveConversationUseCase>(),
          gh<_i585.DeleteConversationUseCase>(),
          gh<_i130.SearchConversationsUseCase>(),
          gh<_i47.ConnectivityService>(),
          gh<_i514.CacheSyncStrategy>(),
          gh<_i163.MediaCacheManager>(),
          gh<_i301.RealtimeService>(),
          gh<_i848.MarkAsReadUseCase>(),
          gh<_i113.CurrentUserProvider>(),
          gh<_i962.PersistIncomingMessageUseCase>(),
          gh<_i1030.ChatModuleEventBus>(),
          gh<_i817.IAttachmentRepository>(),
        ));
    gh.factory<_i1028.ChatMembersBloc>(() => _i1028.ChatMembersBloc(
          logger: gh<_i221.AppLogger>(),
          chatRepository: gh<_i81.IChatRepository>(),
        ));
    gh.factory<_i101.ConversationDetailBloc>(() => _i101.ConversationDetailBloc(
          getConversationDetail: gh<_i899.GetConversationDetailUseCase>(),
          chatRepository: gh<_i81.IChatRepository>(),
          logger: gh<_i221.AppLogger>(),
        ));
    return this;
  }
}

class _$ExternalModule extends _i649.ExternalModule {}
