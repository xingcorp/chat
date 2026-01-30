// Dart imports
import 'dart:async';
import 'dart:io' show Platform;

// Flutter imports
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Third-party package imports
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

// App imports - Core
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/config/environment_manager.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/localization/l10n_helper.dart' as l10n_helper;
import 'package:flutter_chat_app/core/monitoring/analytics_manager.dart';
import 'package:flutter_chat_app/core/monitoring/crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/services/chat_message_service.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/firebase_service_manager.dart';
import 'package:flutter_chat_app/core/services/performance_service.dart';
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

// App imports - Data
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';

// App imports - Presentation
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/main_desktop.dart' show DesktopHomeScreen;
import 'package:flutter_chat_app/main_mobile.dart' show MobileHomeScreen;
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter_chat_app/presentation/pages/home/web_home_screen.dart';

/// **MAIN ENTRY POINT - ENTERPRISE FLUTTER CHAT APP**
///
/// Production-ready chat application với enterprise-grade architecture:
/// - Clean Architecture + SOLID principles
/// - BLoC state management
/// - Offline-first với Isar database
/// - Real-time messaging
/// - Comprehensive error handling
/// - Performance optimization
/// - Multi-platform support
/// - Multi-flavor support (staging/production)
///
/// **Performance Targets:**
/// - Startup time: <2s
/// - Memory usage: <150MB
/// - Message delivery: <100ms
/// - 60fps UI rendering
///
/// **Author:** Senior Flutter/Mobile Architect

/// Main function - Entry point của ứng dụng
/// Sử dụng default flavor (staging) nếu không được specify
Future<void> main() async {
  // Initialize default flavor if not already set
  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initializeFromEnvironment();
  }

  await runMainApp();
}

/// Run main app với flavor configuration
Future<void> runMainApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment manager
  final logger = getIt<Logger>();
  final environmentManager = EnvironmentManager(logger);
  await environmentManager.initialize();

  // Print environment info in debug mode
  environmentManager.printEnvironmentInfo();

  // Thiết lập hướng màn hình và màu theme cho status bar
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cấu hình SystemUI với flavor-specific colors
  final flavorColors = FlavorUtils.getFlavorColors();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Color(flavorColors['primary'] as int).withValues(alpha: 0.8),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(flavorColors['background'] as int),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  try {
    // Khởi tạo Firebase services với flavor-specific configuration
    final firebaseServiceManager = FirebaseServiceManager(logger);
    await firebaseServiceManager.initializeServices();

    // Log Firebase configuration summary
    final configSummary = firebaseServiceManager.getConfigurationSummary();
    logger.i('Firebase configuration: $configSummary');

  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Tải biến môi trường
  await dotenv.load(fileName: '.env');
  
  // Đăng ký và khởi tạo dependency injection
  configureDependencies();
  
  // Tùy thuộc vào nền tảng, chúng ta sẽ khởi động các dịch vụ phù hợp
  if (kIsWeb) {
    await _initializeWebServices();
  } else {
    if (Platform.isAndroid || Platform.isIOS) {
      await _initializeMobileServices();
    } else {
      await _initializeDesktopServices();
    }
  }
  
  // Khởi tạo SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Khởi tạo các managers cache
  // Note: AppCacheManager is registered in DI and will be injected where needed

  // TODO: Register these services in DI later
  // Khởi tạo và bắt đầu preload dữ liệu (if available)
  // try {
  //   final preloadManager = getIt<PreloadManager>();
  //   unawaited(preloadManager.preloadEssentialData());
  // } catch (e) {
  //   print('PreloadManager not available: $e');
  // }

  // Khởi tạo background sync worker (if available)
  // try {
  //   final backgroundSyncWorker = getIt<BackgroundSyncWorker>();
  // } catch (e) {
  //   print('BackgroundSyncWorker not available: $e');
  // }

  // Khởi tạo cache stats (if available)
  // try {
  //   final cacheStats = getIt<CacheStats>();
  // } catch (e) {
  //   print('CacheStats not available: $e');
  // }
  
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
    debugPrint('Could not initialize monitoring services: $e');
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
  
  // Initialize Enterprise dependency injection
  await configureDependencies();
  
  // NOTE: MessageQueueService is now registered directly in DI container
  // The upgradeToEnhancedMessageQueue() function is deprecated and no longer needed
  
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
    debugPrint('Unhandled error: $error\n$stackTrace');
    crashReporter?.recordError(error, stackTrace, reason: 'unhandled_error');
  });
}

Future<void> _initializeWebServices() async {
  // Initialize web-specific services
  // NOTE: Isar database not supported on web platform
  // final databaseService = getIt<DatabaseService>();
  // await databaseService.initialize();

  // TODO: Register these services in EnterpriseDI
  // Khởi tạo dịch vụ kết nối thời gian thực
  // final realtimeConnectionService = getIt<RealtimeConnectionService>();
  // await realtimeConnectionService.initialize();

  // Khởi tạo dịch vụ tin nhắn chat
  // final chatMessageService = getIt<ChatMessageService>();
  // await chatMessageService.initialize();
}

Future<void> _initializeMobileServices() async {
  // Initialize mobile-specific services
  final databaseService = getIt<DatabaseService>();
  await databaseService.initialize();

  // TODO: Register these services in EnterpriseDI
  // Khởi tạo dịch vụ kết nối thời gian thực
  // final realtimeConnectionService = getIt<RealtimeConnectionService>();
  // await realtimeConnectionService.initialize();

  // Khởi tạo dịch vụ hàng đợi tin nhắn (standard or enhanced)
  // if (getIt.isRegistered<EnhancedMessageQueueService>()) {
  //   final enhancedMessageQueueService = getIt<EnhancedMessageQueueService>();
  //   await enhancedMessageQueueService.initialize();
  //   debugPrint('Using EnhancedMessageQueueService for mobile platform');
  // } else {
  //   final messageQueueService = getIt<MessageQueueService>();
  //   await messageQueueService.initialize();
  //   debugPrint('Using standard MessageQueueService for mobile platform');
  // }

  // TODO: Register ChatMessageService in EnterpriseDI
  // Khởi tạo dịch vụ tin nhắn chat
  // final chatMessageService = getIt<ChatMessageService>();
  // await chatMessageService.initialize();
}

Future<void> _initializeDesktopServices() async {
  // Initialize desktop-specific services
  final databaseService = getIt<DatabaseService>();
  await databaseService.initialize();

  // TODO: Register these services in EnterpriseDI
  // Khởi tạo dịch vụ kết nối thời gian thực
  // final realtimeConnectionService = getIt<RealtimeConnectionService>();
  // await realtimeConnectionService.initialize();

  // Khởi tạo dịch vụ hàng đợi tin nhắn
  // final messageQueueService = getIt<MessageQueueService>();
  // await messageQueueService.initialize();
  
  // Khởi tạo dịch vụ tin nhắn chat
  final chatMessageService = GetIt.I<ChatMessageService>();
  await chatMessageService.initialize();
}

/// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  
  const MyApp({
    super.key,
    required this.sharedPreferences,
  });

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
        BlocProvider<LocaleCubit>(
          create: (context) => GetIt.I<LocaleCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => GetIt.I<ThemeCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              // Initialize L10nHelper with current locale
              l10n_helper.L10nHelper.initialize(localeState.locale ?? const Locale('en'));

              return MaterialApp(
                title: 'Flutter Chat App',
                debugShowCheckedModeBanner: false,

                // **ENTERPRISE THEME INTEGRATION**
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState.themeMode, // Use enhanced ThemeCubit

                // **ENTERPRISE I18N INTEGRATION**
                locale: localeState.locale,
                supportedLocales: L10n.all,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // **RTL SUPPORT**
                builder: (context, child) {
                  return Directionality(
                    textDirection: localeState.isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  );
                },

                // ... rest of your app configuration
                home: _buildHomeScreen(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen() {
    if (kIsWeb) {
      return const WebHomeScreen();
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        return const MobileHomeScreen();
      } else {
        return const DesktopHomeScreen();
      }
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
  final _uuid = const Uuid();
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
  const HomeScreen({super.key});

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