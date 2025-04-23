import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/media_processing_service.dart';
import 'package:flutter_chat_app/core/services/resource_manager_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/services/graphql_subscription_service.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/core/services/enhanced_message_queue_service.dart';
import 'package:flutter_chat_app/core/services/attachment_queue_service.dart';
import 'package:flutter_chat_app/core/services/chat_message_service.dart';
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';
import 'package:flutter_chat_app/core/services/media_cache.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart';
import 'package:flutter_chat_app/core/network/socket_analytics.dart';
import 'package:flutter_chat_app/core/network/socket_rate_limiter.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_service.dart';

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
  final connectivityService = ConnectivityService(await Connectivity().checkConnectivity());
  getIt.registerSingleton<ConnectivityService>(connectivityService);
  
  final connectivityAnalyzer = ConnectivityAnalyzerService();
  getIt.registerSingleton<ConnectivityAnalyzerService>(connectivityAnalyzer);
  
  // Register resource services
  final resourceManager = ResourceManagerService();
  getIt.registerSingleton(resourceManager);
  
  // Register media processing service - safe initialization with platform detection
  final mediaProcessingService = MediaProcessingService();
  try {
    await mediaProcessingService.initialize();
  } catch (e) {
    // Log error but don't stop initialization process
    debugPrint('Warning: MediaProcessingService initialization failed: $e');
    debugPrint('Media processing may be limited on this platform');
  }
  getIt.registerSingleton(mediaProcessingService);
  
  // Register database service
  final databaseService = DatabaseService();
  getIt.registerSingleton<DatabaseService>(databaseService);
  
  // Register realtime connection service
  final realtimeConnectionService = RealtimeConnectionService(
    webSocketUrl: AppConfig.webSocketUrl,
    httpUrl: AppConfig.apiUrl,
    authToken: await _getAuthToken(),
    connectivityAnalyzer: connectivityAnalyzer,
    connectivityService: connectivityService,
  );
  getIt.registerSingleton<RealtimeConnectionService>(realtimeConnectionService);
  
  // Register GraphQL subscription service
  final graphQLSubscriptionService = GraphQLSubscriptionService(
    realtimeConnectionService,
    getIt<GraphQLClient>(),
  );
  getIt.registerSingleton<GraphQLSubscriptionService>(graphQLSubscriptionService);
  
  // Register message repository
  getIt.registerSingleton<IMessageRepository>(
    await _createMessageRepository(getIt<GraphQLClient>(), databaseService),
  );
  
  // Register attachment repository
  getIt.registerSingleton<IAttachmentRepository>(
    await _createAttachmentRepository(getIt<GraphQLClient>(), databaseService),
  );
  
  // Register MediaCache service
  final mediaCache = await MediaCache.create();
  getIt.registerSingleton<MediaCache>(mediaCache);
  
  // Register AttachmentQueueService
  final attachmentQueueService = AttachmentQueueService(
    getIt<IAttachmentRepository>(),
    connectivityService,
    localStorageService,
    mediaCache,
  );
  getIt.registerSingleton<AttachmentQueueService>(attachmentQueueService);
  
  // Register message queue service
  final messageQueueService = MessageQueueService(
    getIt<IMessageRepository>(),
    localStorageService,
    connectivityService,
    realtimeConnectionService,
  );
  getIt.registerSingleton<MessageQueueService>(messageQueueService);
  
  // Also register EnhancedMessageQueueService for advanced features
  // (Note: This requires AttachmentQueueService to be registered first)
  if (!getIt.isRegistered<AttachmentQueueService>()) {
    debugPrint('Warning: Cannot register EnhancedMessageQueueService because AttachmentQueueService is not registered');
    debugPrint('Using standard MessageQueueService instead');
  }
  
  // Register chat message service
  final chatMessageService = ChatMessageService(
    messageQueueService,
    realtimeConnectionService,
    graphQLSubscriptionService,
    getIt<IMessageRepository>(),
  );
  getIt.registerSingleton<ChatMessageService>(chatMessageService);
  
  // Register offline-first repository
  getIt.registerSingleton<OfflineFirstRepository>(
    OfflineFirstRepositoryImpl(
      databaseService, 
      connectivityService,
    ),
  );
  
  // Đăng ký và khởi tạo Animation Service
  await configureAnimationServices();

  // --- Đăng ký Hệ thống Socket.IO ---

  // Đăng ký Logger nếu chưa có (hoặc dùng instance chung nếu có)
  if (!getIt.isRegistered<Logger>()) {
    getIt.registerSingleton<Logger>(Logger(
      // Cấu hình Logger tại đây nếu muốn
      // Ví dụ: level: kDebugMode ? Level.verbose : Level.info,
      printer: PrettyPrinter(
          methodCount: 1, // number of method calls to be displayed
          errorMethodCount: 8, // number of method calls if stacktrace is provided
          lineLength: 120, // width of the output
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          printTime: true // Should each log print contain a timestamp
          ),
    ));
  }
  final logger = getIt<Logger>();

  // Lấy AnalyticsService (đã được đăng ký bởi monitoring_module.dart hoặc tương tự)
  // Lưu ý: Cần đảm bảo module đó chạy trước khi configureInjection cần AnalyticsService
  final analyticsService = getIt<AnalyticsService>();

  // Đăng ký SocketAnalytics
  getIt.registerSingleton<SocketAnalytics>(SocketAnalytics(
    analyticsService: analyticsService,
    logger: logger,
  ));

  // Đăng ký SocketRateLimiter
  getIt.registerSingleton<SocketRateLimiter>(SocketRateLimiter(
    logger: logger,
    // Có thể cấu hình defaultLimit, defaultWindowMs, defaultBackoffMs ở đây nếu muốn
    // defaultLimit: 15,
    // defaultWindowMs: 1000,
  ));

  // Đăng ký SocketManager (lớp dùng socket_io_client)
  // !! Lưu ý: Xác nhận AppConfig.webSocketUrl là URL đúng cho Socket.IO server !!
  getIt.registerSingleton<SocketManager>(SocketManager(
    serverUrl: AppConfig.webSocketUrl,
    logger: logger,
    analytics: analyticsService,
    options: {
      // Thêm các options kết nối Socket.IO cần thiết ở đây
      'transports': ['websocket'], // Thường dùng websocket cho mobile
      'autoConnect': false, // EnhancedSocketManager sẽ quản lý việc kết nối
      'reconnection': false, // EnhancedSocketManager sẽ quản lý việc kết nối lại
      // 'forceNew': true, // Cân nhắc nếu cần kết nối mới mỗi lần
      // Cần thêm logic để lấy token và đưa vào query hoặc extraHeaders
      // Ví dụ sử dụng hàm _getAuthToken() đã có:
      // 'query': {
      //   'token': await _getAuthToken(),
      //   'EIO': '4', // Thường cần cho Socket.IO v3/v4
      // },
       'auth': {
         'token': await _getAuthToken()
       },
      // 'extraHeaders': {
      //  'Authorization': 'Bearer ${await _getAuthToken()}'
      // }
    },
  ));

  // Đăng ký EnhancedSocketManager
  getIt.registerSingleton<EnhancedSocketManager>(EnhancedSocketManager(
    getIt<SocketManager>(),
    getIt<SocketAnalytics>(),
    getIt<SocketRateLimiter>(),
    // Logger được tạo bên trong EnhancedSocketManager, không cần inject lại
  ));

  // --- Kết thúc đăng ký Hệ thống Socket.IO ---

  // !!! Quan trọng: Đảm bảo KHÔNG có đăng ký nào cho SocketConnectionService
  // (Đã kiểm tra, không có)
}

/// Tạo repository tin nhắn
/// Hàm này cần được thay thế bằng implementation thực tế
Future<IMessageRepository> _createMessageRepository(
  GraphQLClient graphQLClient,
  DatabaseService databaseService,
) async {
  // Đây là placeholder, thay bằng implementation thực tế
  return MessageRepositoryPlaceholder();
}

/// Placeholder cho IMessageRepository, cần thay thế sau
class MessageRepositoryPlaceholder implements IMessageRepository {
  // Implementation tạm thời, cần thay thế bằng implementation thực tế
  @override
  dynamic noSuchMethod(Invocation invocation) {
    debugPrint('Warning: MessageRepository not fully implemented');
    return null;
  }
}

/// Create GraphQL client
GraphQLClient _createGraphQLClient() {
  // Link for HTTP operations
  final httpLink = HttpLink(
    AppConfig.apiUrl + '/graphql',
    defaultHeaders: {
      'Content-Type': 'application/json',
      // Add auth headers here if needed
    },
  );
  
  // Link for WebSocket operations
  final websocketLink = WebSocketLink(
    AppConfig.webSocketUrl,
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

/// Configure animation services
Future<void> configureAnimationServices() async {
  // Đăng ký DeviceCapabilityService để đánh giá khả năng thiết bị
  final deviceCapabilityService = DeviceCapabilityService();
  getIt.registerSingleton<DeviceCapabilityService>(deviceCapabilityService);
  
  // Khởi tạo benchmark và đánh giá thiết bị
  await deviceCapabilityService.initialize();
  
  // Đăng ký AnimationService để quản lý cấu hình animation
  getIt.registerSingleton<AnimationService>(
    AnimationService(deviceCapabilityService),
  );
}

/// Module to register non-injectable dependencies
@module
abstract class RegisterModule {
  // Register dependencies that cannot be auto-injected here
} 