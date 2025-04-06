import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/core/utils/adaptive_animations.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';
import 'package:flutter_chat_app/core/utils/optimized_repaint_boundary.dart';
import 'package:flutter_chat_app/core/utils/virtual_scroll_controller.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
import 'package:flutter_chat_app/data/repositories/auth_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/chat_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/message_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/user_repository_impl.dart';
import 'package:flutter_chat_app/domain/repositories/auth_repository.dart';
import 'package:flutter_chat_app/domain/repositories/chat_repository.dart';
import 'package:flutter_chat_app/domain/repositories/message_repository.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:flutter_chat_app/domain/usecases/auth/check_auth_status_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/auth/login_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/auth/logout_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/auth/register_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/create_group_chat_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/get_chat_details_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/get_user_chats_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_chat_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/get_user_contacts_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/get_user_profile_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/search_users_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/update_user_profile_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/user/user_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/data/repositories/message_repository_with_cache.dart';
import 'package:flutter_chat_app/core/cache/cache_stats.dart';
import 'package:flutter_chat_app/core/cache/preload_manager.dart';
import 'package:flutter_chat_app/core/cache/background_sync_worker.dart';
import 'package:flutter_chat_app/core/network/socket_analytics.dart';
import 'package:flutter_chat_app/core/network/socket_rate_limiter.dart';
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart';

final getIt = GetIt.instance;

/// Initialize core performance services
Future<void> initCoreServices() async {
  // Performance Monitor - needed by other services
  getIt.registerSingleton<PerformanceMonitor>(PerformanceMonitor());
  
  // Initialize Isolate Manager
  final isolateManager = IsolateManager(getIt<PerformanceMonitor>());
  await isolateManager.initialize();
  getIt.registerSingleton<IsolateManager>(isolateManager);
  
  // Adaptive Animation Manager
  getIt.registerSingleton<AdaptiveAnimationManager>(
    AdaptiveAnimationManager(getIt<PerformanceMonitor>())
  );
}

/// Configure dependency injection
Future<void> setupServiceLocator() async {
  // First, initialize core performance services
  await initCoreServices();
  
  // Network
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>())
  );
  
  // GraphQL Client
  getIt.registerLazySingleton<GraphQLClient>(() {
    final httpLink = HttpLink('https://your-api-url.com/graphql');
    return GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
    );
  });
  
  // Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(getIt<SharedPreferences>())
  );
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorageImpl());
  
  // Cache Managers
  getIt.registerLazySingleton<AppCacheManager>(() => AppCacheManager());
  getIt.registerLazySingleton<MediaCacheManager>(() => MediaCacheManager());
  
  // Data Sources
  getIt.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(getIt<LocalStorage>())
  );
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(getIt<GraphQLClient>())
  );
  getIt.registerLazySingleton<MessageLocalDataSource>(
    () => MessageLocalDataSourceImpl(getIt<LocalStorage>())
  );
  getIt.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(getIt<GraphQLClient>())
  );
  getIt.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(getIt<LocalStorage>())
  );
  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(getIt<GraphQLClient>())
  );
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<SecureStorage>(),
      getIt<LocalStorage>(),
    )
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      getIt<NetworkInfo>(),
      getIt<ChatLocalDataSource>(),
      getIt<ChatRemoteDataSource>(),
    )
  );
  getIt.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryWithCache(
      getIt<NetworkInfo>(),
      getIt<MessageLocalDataSource>(),
      getIt<MessageRemoteDataSource>(),
      getIt<AppCacheManager>(),
    )
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      getIt<NetworkInfo>(),
      getIt<UserLocalDataSource>(),
      getIt<UserRemoteDataSource>(),
    )
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => CheckAuthStatusUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetChatDetailsUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => GetUserChatsUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => CreateGroupChatUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => GetChatMessagesUseCase(getIt<MessageRepository>()));
  getIt.registerLazySingleton(() => SendMessageUseCase(getIt<MessageRepository>()));
  getIt.registerLazySingleton(() => GetUserContactsUseCase(getIt<UserRepository>()));
  getIt.registerLazySingleton(() => GetUserProfileUseCase(getIt<UserRepository>()));
  getIt.registerLazySingleton(() => SearchUsersUseCase(getIt<UserRepository>()));
  getIt.registerLazySingleton(() => UpdateUserProfileUseCase(getIt<UserRepository>()));
  
  // BLoCs
  getIt.registerFactory(() => AppBloc());
  getIt.registerFactory(
    () => AuthBloc(
      getIt<CheckAuthStatusUseCase>(),
      getIt<LoginUseCase>(),
      getIt<LogoutUseCase>(),
      getIt<RegisterUseCase>(),
    )
  );
  getIt.registerFactory(
    () => ChatBloc(
      getIt<GetUserChatsUseCase>(),
      getIt<GetChatDetailsUseCase>(),
      getIt<CreateGroupChatUseCase>(),
    )
  );
  getIt.registerFactory(
    () => MessageBloc(
      getIt<GetChatMessagesUseCase>(),
      getIt<SendMessageUseCase>(),
    )
  );
  getIt.registerFactory(
    () => UserBloc(
      getIt<GetUserProfileUseCase>(),
      getIt<GetUserContactsUseCase>(),
      getIt<SearchUsersUseCase>(),
      getIt<UpdateUserProfileUseCase>(),
    )
  );
  getIt.registerFactory(
    () => ConnectivityBloc(
      getIt<NetworkInfo>(),
    )
  );
  
  // Factories for utility classes that might be created multiple times
  getIt.registerFactory(() => VirtualScrollController(
    maxMessageBuffer: 100,
    bufferZoneSize: 30,
  ));
  
  // Initialize all services that need it
  await getIt<AppCacheManager>().initialize();
  await getIt<MediaCacheManager>().initialize();
} 