import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/di/injection.config.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/media_processing_service.dart';
import 'package:flutter_chat_app/core/services/resource_manager_service.dart';

/// GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Configure dependency injection
@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
Future<void> configureInjection() async {
  // Initialize Hive for GraphQL cache
  await initHiveForFlutter();
  
  // Initialize the injection
  init(getIt);
  
  // Register GraphQL client
  getIt.registerSingleton<GraphQLClient>(_createGraphQLClient());
  
  // Initialize the local storage service
  final localStorageService = await LocalStorageService.init();
  getIt.registerSingleton<LocalStorageService>(localStorageService);
  
  // Register resource services
  final resourceManager = ResourceManagerService();
  await resourceManager.initialize();
  getIt.registerSingleton(resourceManager);
  
  // Register media processing service
  final mediaProcessingService = MediaProcessingService();
  await mediaProcessingService.initialize();
  getIt.registerSingleton(mediaProcessingService);
  
  // Register connectivity analyzer service
  final connectivityAnalyzer = ConnectivityAnalyzerService();
  getIt.registerSingleton(connectivityAnalyzer);
}

/// Create GraphQL client
GraphQLClient _createGraphQLClient() {
  // Link for HTTP operations
  final httpLink = HttpLink(
    'https://your-graphql-api.com/graphql',
    defaultHeaders: {
      'Content-Type': 'application/json',
      // Add auth headers here if needed
    },
  );
  
  // Link for WebSocket operations
  final websocketLink = WebSocketLink(
    'wss://your-graphql-api.com/graphql',
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
      return 'Bearer ...';
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

/// Module to register non-injectable dependencies
@module
abstract class RegisterModule {
  // Register dependencies that cannot be auto-injected here
} 