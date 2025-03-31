import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/media_processing_service.dart';
import 'package:flutter_chat_app/core/services/resource_manager_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/services/graphql_subscription_service.dart';
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';

/// GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Configure dependency injection
Future<void> configureInjection() async {
  // Initialize Hive for GraphQL cache
  await initHiveForFlutter();
  
  // Register GraphQL client
  getIt.registerSingleton<GraphQLClient>(_createGraphQLClient());
  
  // Initialize the local storage service
  final localStorageService = await LocalStorageService.init();
  getIt.registerSingleton<LocalStorageService>(localStorageService);
  
  // Register connectivity service
  final connectivityService = ConnectivityService();
  getIt.registerSingleton<ConnectivityService>(connectivityService);
  
  // Register resource services
  final resourceManager = ResourceManagerService();
  getIt.registerSingleton(resourceManager);
  
  // Register media processing service
  final mediaProcessingService = MediaProcessingService();
  await mediaProcessingService.initialize();
  getIt.registerSingleton(mediaProcessingService);
  
  // Register connectivity analyzer service
  final connectivityAnalyzer = ConnectivityAnalyzerService();
  getIt.registerSingleton(connectivityAnalyzer);
  
  // Register realtime connection service
  final realtimeConnectionService = RealtimeConnectionService(
    webSocketUrl: AppConfig.webSocketUrl,
    httpUrl: AppConfig.apiUrl,
    authToken: await _getAuthToken(),
    connectivityAnalyzer: connectivityAnalyzer,
  );
  getIt.registerSingleton(realtimeConnectionService);
  
  // Register GraphQL subscription service
  final graphQLSubscriptionService = GraphQLSubscriptionService(
    realtimeConnectionService,
    getIt<GraphQLClient>(),
  );
  getIt.registerSingleton(graphQLSubscriptionService);
  
  // Register database service and initialize
  final databaseService = DatabaseService();
  await databaseService.initialize();
  getIt.registerSingleton<DatabaseService>(databaseService);
  
  // Register offline-first repository
  getIt.registerSingleton<OfflineFirstRepository>(
    OfflineFirstRepositoryImpl(
      databaseService, 
      connectivityService,
    ),
  );
}

/// Create GraphQL client
GraphQLClient _createGraphQLClient() {
  // Link for HTTP operations
  final httpLink = HttpLink(
    'https://stg-office-api.smarthiz.vn/graphql',
    defaultHeaders: {
      'Content-Type': 'application/json',
      // Add auth headers here if needed
    },
  );
  
  // Link for WebSocket operations
  final websocketLink = WebSocketLink(
    'wss://stg-office-api.smarthiz.vn/graphql',
    config: SocketClientConfig(
      initialPayload: {
        // Add auth payload here if needed
      },
      autoReconnect: true,
      inactivityTimeout: const Duration(seconds: 30),
    ),
  );
  
  // Link for authentication
  final authLink = AuthLink(
    getToken: () async {
      // Get auth token from storage or service
      return 'Bearer ${await _getAuthToken()}';
    },
  );
  
  // Cache for offline support
  final cache = GraphQLCache(store: HiveStore());
  
  // Create client
  return GraphQLClient(
    link: Link.split(
      (request) => request.isSubscription,
      websocketLink,
      authLink.concat(httpLink),
    ),
    cache: cache,
    defaultPolicies: DefaultPolicies(
      query: Policies(
        fetch: FetchPolicy.networkOnly,
        error: ErrorPolicy.all,
        cacheReread: CacheRereadPolicy.ignoreAll,
      ),
      mutate: Policies(
        fetch: FetchPolicy.networkOnly,
        error: ErrorPolicy.all,
        cacheReread: CacheRereadPolicy.ignoreAll,
      ),
      subscribe: Policies(
        fetch: FetchPolicy.networkOnly,
        error: ErrorPolicy.all,
        cacheReread: CacheRereadPolicy.ignoreAll,
      ),
    ),
  );
}

/// Get auth token from storage
Future<String> _getAuthToken() async {
  try {
    final localStorageService = getIt<LocalStorageService>();
    return await localStorageService.getString('auth_token') ?? '';
  } catch (e) {
    return '';
  }
}

/// Module to register non-injectable dependencies
@module
abstract class RegisterModule {
  // Register dependencies that cannot be auto-injected here
} 