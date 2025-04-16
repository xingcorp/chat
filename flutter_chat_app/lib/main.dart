import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/config/route/app_router.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/lifecycle/app_lifecycle_observer.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/services/chat_message_service.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_stats.dart';
import 'package:flutter_chat_app/core/cache/preload_manager.dart';
import 'package:flutter_chat_app/core/cache/background_sync_worker.dart';
import 'package:flutter_chat_app/di/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_manager.dart';
import 'package:flutter_chat_app/core/monitoring/crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';
import 'package:flutter_chat_app/core/services/performance_service.dart';
import 'package:flutter_chat_app/presentation/widgets/app_wrapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import home screens from respective platform files
import 'main_mobile.dart' show MobileHomeScreen;
import 'main_web.dart' show WebHomeScreen;
import 'main_desktop.dart' show DesktopHomeScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Thiết lập hướng màn hình và màu theme cho status bar
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Cấu hình SystemUI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  try {
    // Khởi tạo Firebase
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  // Tải biến môi trường
  await dotenv.load(fileName: '.env');
  
  // Đăng ký và khởi tạo dependency injection
  await configureInjection();
  
  // Tùy thuộc vào nền tảng, chúng ta sẽ khởi động các dịch vụ phù hợp
  if (kIsWeb) {
    await _initializeWebServices();
  } else if (Platform.isAndroid || Platform.isIOS) {
    await _initializeMobileServices();
  } else {
    await _initializeDesktopServices();
  }
  
  // Khởi tạo SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Khởi tạo các managers cache
  final appCacheManager = await GetIt.I<AppCacheManager>();
  
  // Khởi tạo và bắt đầu preload dữ liệu
  final preloadManager = await GetIt.I<PreloadManager>();
  unawaited(preloadManager.preloadEssentialData());
  
  // Khởi tạo background sync worker
  final backgroundSyncWorker = await GetIt.I<BackgroundSyncWorker>();
    
  // Khởi tạo cache stats
  final cacheStats = await GetIt.I<CacheStats>();
  
  // Khởi tạo monitoring services nếu có
  CrashReporter? crashReporter;
  PerformanceMonitor? performanceMonitor;
  AnalyticsManager? analyticsManager;
  
  try {
    crashReporter = await GetIt.I.getAsync<CrashReporter>();
    performanceMonitor = await GetIt.I.getAsync<PerformanceMonitor>();
    analyticsManager = await GetIt.I.getAsync<AnalyticsManager>();
    
    // Bắt đầu tracking hiệu suất ứng dụng
    await performanceMonitor.startTrace(TraceType.appStartup);
    
    // Dừng trace sau khi app khởi động
    Future.delayed(const Duration(seconds: 5), () async {
      await performanceMonitor?.stopTrace(TraceType.appStartup);
      
      // Log sự kiện khởi động ứng dụng
      await analyticsManager?.logEvent('app_started', {
        'startup_time': DateTime.now().toIso8601String(),
      });
    });
  } catch (e) {
    // Log lỗi nếu không khởi tạo được monitoring services
    print('Could not initialize monitoring services: $e');
  }
  
  // Khởi tạo PerformanceService
  final performanceService = GetIt.I<PerformanceService>();
  await performanceService.initialize();
  
  // Nếu đang trong chế độ debug, bật overlay hiệu suất khi khởi động
  if (kDebugMode) {
    // Cung cấp thời gian cho các widget khác khởi tạo
    Future.delayed(const Duration(seconds: 2), () {
      performanceService.showPerformanceOverlay = true;
    });
  }
  
  // Bắt tất cả lỗi không xử lý trong zone
  runZonedGuarded(() {
    runApp(
      ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MyApp(sharedPreferences: sharedPreferences),
      ),
    );
  }, (error, stackTrace) {
    print('Unhandled error: $error\n$stackTrace');
    crashReporter?.recordError(error, stackTrace, reason: 'unhandled_error');
  });
}

Future<void> _initializeWebServices() async {
  // Initialize web-specific services
  final databaseService = GetIt.I<DatabaseService>();
  await databaseService.initialize();
  
  // Khởi tạo dịch vụ kết nối thời gian thực
  final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
  await realtimeConnectionService.initialize();
  
  // Khởi tạo dịch vụ tin nhắn chat
  final chatMessageService = GetIt.I<ChatMessageService>();
  await chatMessageService.initialize();
}

Future<void> _initializeMobileServices() async {
  // Initialize mobile-specific services
  final databaseService = GetIt.I<DatabaseService>();
  await databaseService.initialize();
  
  // Khởi tạo dịch vụ kết nối thời gian thực
  final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
  await realtimeConnectionService.initialize();
  
  // Khởi tạo dịch vụ hàng đợi tin nhắn
  final messageQueueService = GetIt.I<MessageQueueService>();
  await messageQueueService.initialize();
  
  // Khởi tạo dịch vụ tin nhắn chat
  final chatMessageService = GetIt.I<ChatMessageService>();
  await chatMessageService.initialize();
}

Future<void> _initializeDesktopServices() async {
  // Initialize desktop-specific services
  final databaseService = GetIt.I<DatabaseService>();
  await databaseService.initialize();
  
  // Khởi tạo dịch vụ kết nối thời gian thực
  final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
  await realtimeConnectionService.initialize();
  
  // Khởi tạo dịch vụ hàng đợi tin nhắn
  final messageQueueService = GetIt.I<MessageQueueService>();
  await messageQueueService.initialize();
  
  // Khởi tạo dịch vụ tin nhắn chat
  final chatMessageService = GetIt.I<ChatMessageService>();
  await chatMessageService.initialize();
}

/// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  
  const MyApp({
    Key? key, 
    required this.sharedPreferences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) => GetIt.I<AppBloc>(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => GetIt.I<AuthBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Chat App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // ... rest of your app configuration
        home: _buildHomeScreen(),
      ),
    );
  }

  Widget _buildHomeScreen() {
    if (kIsWeb) {
      return const WebHomeScreen();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return const MobileHomeScreen();
    } else {
      return const DesktopHomeScreen();
    }
  }
}

class IsarTestScreen extends StatefulWidget {
  const IsarTestScreen({super.key});

  @override
  State<IsarTestScreen> createState() => _IsarTestScreenState();
}

class _IsarTestScreenState extends State<IsarTestScreen> {
  final _repository = GetIt.I<OfflineFirstRepository>();
  final _uuid = Uuid();
  bool _isLoading = false;
  String _statusMessage = 'Ready';
  List<UserModel> _users = [];
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _repository.getUserStream().listen((users) {
      setState(() {
        _users = users;
      });
    });
    
    _repository.getChatStream().listen((chats) {
      setState(() {
        _chats = chats;
      });
    });
  }

  Future<void> _createTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating test data...';
    });

    try {
      // Create test user
      final user = UserModel(
        serverId: 'srv_${_uuid.v4()}',
        username: 'testuser',
        displayName: 'Test User',
        lastSeen: DateTime.now(),
      );
      await _repository.saveUser(user);

      // Create test chat
      final chat = ChatModel(
        serverId: 'srv_${_uuid.v4()}',
        type: ChatType.direct,
        participantIds: [user.serverId],
        createdAt: DateTime.now(),
      );
      await _repository.saveChat(chat);

      // Create test message
      final message = MessageModel(
        localId: _uuid.v4(),
        chatId: chat.serverId,
        senderId: user.serverId,
        content: 'Hello, this is a test message',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );
      await _repository.saveMessage(message);

      // Load messages for the chat
      _repository.getMessagesForChat(chat.serverId).listen((messages) {
        setState(() {
          _messages = messages;
        });
      });

      setState(() {
        _statusMessage = 'Test data created successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating test data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing data...';
    });

    try {
      final databaseService = GetIt.I<DatabaseService>();
      await databaseService.clearAllData();
      
      setState(() {
        _messages = [];
        _statusMessage = 'Data cleared successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isar Offline-First Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: $_statusMessage', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  const Text('Users:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _users.isEmpty
                      ? const Text('No users yet')
                      : Column(
                          children: _users
                              .map((user) => ListTile(
                                    title: Text(user.displayName),
                                    subtitle: Text(user.username),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 20),
                  
                  const Text('Chats:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _chats.isEmpty
                      ? const Text('No chats yet')
                      : Column(
                          children: _chats
                              .map((chat) => ListTile(
                                    title: Text('Chat ${chat.id}'),
                                    subtitle: Text('Type: ${chat.type.name}'),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 20),
                  
                  const Text('Messages:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _messages.isEmpty
                      ? const Text('No messages yet')
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ListTile(
                                title: Text(message.content),
                                subtitle: Text('Status: ${message.status.name}'),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _createTestData,
            tooltip: 'Create Test Data',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _clearData,
            tooltip: 'Clear Data',
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}

/// Thiết lập các services sử dụng DI
Future<void> setupServices() async {
  final getIt = GetIt.instance;
  
  // Đăng ký DeviceCapabilityService để đánh giá khả năng thiết bị
  final deviceCapabilityService = DeviceCapabilityService();
  getIt.registerSingleton<DeviceCapabilityService>(deviceCapabilityService);
  
  // Khởi tạo benchmark và đánh giá thiết bị
  await deviceCapabilityService.initialize();
  
  // Đăng ký AnimationService để quản lý cấu hình animation
  getIt.registerSingleton<AnimationService>(
    AnimationService(deviceCapabilityService),
  );
  
  // Đăng ký các services khác...
}

/// Màn hình chính
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    // Placeholder cho các tab
    switch (_currentIndex) {
      case 0:
        return const Center(
          child: Text(
            'Chats Tab',
            style: TextStyle(fontSize: 24),
          ),
        );
      case 1:
        return const Center(
          child: Text(
            'Contacts Tab',
            style: TextStyle(fontSize: 24),
          ),
        );
      case 2:
        return const Center(
          child: Text(
            'Settings Tab',
            style: TextStyle(fontSize: 24),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
} 