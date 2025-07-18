# 💉 **DEPENDENCY INJECTION UNIFICATION STRATEGY**

## 🎯 **DEPENDENCY INJECTION OBJECTIVES**

**Primary Goal**: Consolidate all dependency injection into single EnterpriseDI system  
**Target**: 100% DI consistency (eliminate all manual injection patterns)  
**Timeline**: Week 3 of consolidation roadmap  
**Risk Level**: High (affects entire app initialization)  

## 📊 **CURRENT DI LANDSCAPE**

### **DI Pattern Distribution**
- **EnterpriseDI System**: 40% (core services)
- **Manual Constructor Injection**: 35% (BLoCs, repositories)
- **Service Locator Pattern**: 15% (widgets, utilities)
- **Factory Pattern**: 10% (specialized components)

### **Critical Issues Identified**
1. **Duplicate Service Registration**: GraphQL client registered in 3 places
2. **Inconsistent Lifecycle Management**: Some singletons, some factories
3. **Performance Impact**: Multiple DI initializations
4. **Testing Complexity**: Different mocking strategies required

## 🏛️ **UNIFIED DEPENDENCY INJECTION ARCHITECTURE**

### **Enhanced EnterpriseDI Design**

```dart
// lib/core/di/enterprise_injection.dart
class EnterpriseDI {
  static final GetIt _serviceLocator = GetIt.instance;
  static bool _isInitialized = false;
  static final Map<String, int> _initializationTimes = {};
  static final Logger _logger = Logger();

  /// Initialize the complete DI system
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('EnterpriseDI already initialized');
      return;
    }

    final totalStopwatch = Stopwatch()..start();
    _logger.i('🚀 Initializing Enterprise DI System...');

    try {
      // Initialize in dependency order for optimal performance
      await _initializeFoundation();     // Target: <100ms
      await _initializeCore();           // Target: <150ms
      await _initializeNetworking();     // Target: <100ms
      await _initializeStorage();        // Target: <100ms
      await _initializeServices();       // Target: <50ms
      await _initializeRepositories();   // Target: <100ms
      await _initializeBlocs();          // Target: <50ms

      _isInitialized = true;
      totalStopwatch.stop();
      
      final totalTime = totalStopwatch.elapsedMilliseconds;
      _logger.i('✅ Enterprise DI initialized successfully in ${totalTime}ms');
      
      // Performance validation
      await _validatePerformance(totalTime);
      
    } catch (error, stackTrace) {
      _logger.e('🚨 Enterprise DI initialization failed', error: error, stackTrace: stackTrace);
      await _handleInitializationFailure(error, stackTrace);
      rethrow;
    }
  }

  /// Foundation services (logging, analytics, crash reporting)
  static Future<void> _initializeFoundation() async {
    final stopwatch = Stopwatch()..start();
    
    // Logger (highest priority)
    _serviceLocator.registerLazySingleton<Logger>(() => Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    ));

    // Analytics Service
    _serviceLocator.registerLazySingleton<AnalyticsService>(
      () => AnalyticsServiceImpl(),
    );

    // Crash Reporter
    _serviceLocator.registerLazySingleton<CrashReporter>(
      () => CrashReporterImpl(),
    );

    // Performance Monitor
    _serviceLocator.registerLazySingleton<PerformanceMonitor>(
      () => PerformanceMonitorImpl(),
    );

    stopwatch.stop();
    _initializationTimes['foundation'] = stopwatch.elapsedMilliseconds;
    _logger.d('Foundation services initialized in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Core services (network info, connectivity, error recovery)
  static Future<void> _initializeCore() async {
    final stopwatch = Stopwatch()..start();

    // Network Info
    _serviceLocator.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(DataConnectionChecker()),
    );

    // Connectivity Service
    _serviceLocator.registerLazySingleton<ConnectivityService>(
      () => ConnectivityServiceImpl(),
    );

    // Error Recovery Service
    _serviceLocator.registerLazySingleton<ErrorRecoveryService>(
      () => ErrorRecoveryServiceImpl(
        authService: _serviceLocator<AuthService>(),
        connectivityService: _serviceLocator<ConnectivityService>(),
      ),
    );

    stopwatch.stop();
    _initializationTimes['core'] = stopwatch.elapsedMilliseconds;
    _logger.d('Core services initialized in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Networking services (GraphQL, HTTP, WebSocket)
  static Future<void> _initializeNetworking() async {
    final stopwatch = Stopwatch()..start();

    // Initialize Hive for GraphQL cache
    await initHiveForFlutter();

    // GraphQL Client (single instance)
    _serviceLocator.registerLazySingleton<GraphQLClient>(() {
      final httpLink = HttpLink(AppConfig.apiUrl);
      final authLink = AuthLink(getToken: () async {
        final authService = _serviceLocator<AuthService>();
        return await authService.getAccessToken();
      });
      
      return GraphQLClient(
        cache: GraphQLCache(store: HiveStore()),
        link: authLink.concat(httpLink),
        defaultPolicies: DefaultPolicies(
          query: Policies(
            fetch: FetchPolicy.cacheAndNetwork,
            error: ErrorPolicy.all,
          ),
          mutate: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
          ),
        ),
      );
    });

    // Socket Manager
    _serviceLocator.registerLazySingleton<SocketManager>(
      () => SocketManager(
        serverUrl: AppConfig.socketUrl,
        logger: _serviceLocator<Logger>(),
      ),
    );

    // Enhanced Socket Manager
    _serviceLocator.registerLazySingleton<EnhancedSocketManager>(
      () => EnhancedSocketManager(
        socketManager: _serviceLocator<SocketManager>(),
        analyticsService: _serviceLocator<AnalyticsService>(),
        logger: _serviceLocator<Logger>(),
      ),
    );

    stopwatch.stop();
    _initializationTimes['networking'] = stopwatch.elapsedMilliseconds;
    _logger.d('Networking services initialized in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Storage services (local database, cache, preferences)
  static Future<void> _initializeStorage() async {
    final stopwatch = Stopwatch()..start();

    // Database Service
    _serviceLocator.registerLazySingleton<DatabaseService>(
      () => DatabaseServiceImpl(),
    );

    // Cache Manager
    _serviceLocator.registerLazySingleton<CacheManager>(
      () => CacheManagerImpl(
        databaseService: _serviceLocator<DatabaseService>(),
      ),
    );

    // Shared Preferences
    _serviceLocator.registerLazySingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance(),
    );

    stopwatch.stop();
    _initializationTimes['storage'] = stopwatch.elapsedMilliseconds;
    _logger.d('Storage services initialized in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Business services (auth, media, notification)
  static Future<void> _initializeServices() async {
    final stopwatch = Stopwatch()..start();

    // Auth Service
    _serviceLocator.registerLazySingleton<AuthService>(
      () => AuthServiceImpl(
        graphQLClient: _serviceLocator<GraphQLClient>(),
        cacheManager: _serviceLocator<CacheManager>(),
        logger: _serviceLocator<Logger>(),
      ),
    );

    // Media Service
    _serviceLocator.registerLazySingleton<MediaService>(
      () => MediaServiceImpl(
        graphQLClient: _serviceLocator<GraphQLClient>(),
        cacheManager: _serviceLocator<CacheManager>(),
      ),
    );

    // Notification Service
    _serviceLocator.registerLazySingleton<NotificationService>(
      () => NotificationServiceImpl(
        analyticsService: _serviceLocator<AnalyticsService>(),
      ),
    );

    stopwatch.stop();
    _initializationTimes['services'] = stopwatch.elapsedMilliseconds;
    _logger.d('Business services initialized in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Repository layer
  static Future<void> _initializeRepositories() async {
    final stopwatch = Stopwatch()..start();

    // Data Sources
    _registerDataSources();
    
    // Repositories
    _serviceLocator.registerLazySingleton<IUserRepository>(
      () => UserRepositoryImpl(
        remoteDataSource: _serviceLocator<UserRemoteDataSource>(),
        localDataSource: _serviceLocator<UserLocalDataSource>(),
        networkInfo: _serviceLocator<NetworkInfo>(),
        logger: _serviceLocator<Logger>(),
        performanceMonitor: _serviceLocator<PerformanceMonitor>(),
      ),
    );

    _serviceLocator.registerLazySingleton<IChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: _serviceLocator<ChatRemoteDataSource>(),
        localDataSource: _serviceLocator<ChatLocalDataSource>(),
        networkInfo: _serviceLocator<NetworkInfo>(),
        logger: _serviceLocator<Logger>(),
        performanceMonitor: _serviceLocator<PerformanceMonitor>(),
      ),
    );

    _serviceLocator.registerLazySingleton<IMessageRepository>(
      () => MessageRepositoryImpl(
        remoteDataSource: _serviceLocator<MessageRemoteDataSource>(),
        localDataSource: _serviceLocator<MessageLocalDataSource>(),
        networkInfo: _serviceLocator<NetworkInfo>(),
        logger: _serviceLocator<Logger>(),
        performanceMonitor: _serviceLocator<PerformanceMonitor>(),
      ),
    );

    stopwatch.stop();
    _initializationTimes['repositories'] = stopwatch.elapsedMilliseconds;
    _logger.d('Repositories initialized in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// BLoC layer (factory pattern for proper disposal)
  static Future<void> _initializeBlocs() async {
    final stopwatch = Stopwatch()..start();

    // BLoCs use factory pattern for proper lifecycle management
    _serviceLocator.registerFactory<AuthBloc>(
      () => AuthBloc(
        authRepository: _serviceLocator<IAuthRepository>(),
        analyticsService: _serviceLocator<AnalyticsService>(),
        crashReporter: _serviceLocator<CrashReporter>(),
        logger: _serviceLocator<Logger>(),
        performanceMonitor: _serviceLocator<PerformanceMonitor>(),
        errorRecoveryService: _serviceLocator<ErrorRecoveryService>(),
      ),
    );

    _serviceLocator.registerFactory<ChatBloc>(
      () => ChatBloc(
        chatRepository: _serviceLocator<IChatRepository>(),
        analyticsService: _serviceLocator<AnalyticsService>(),
        crashReporter: _serviceLocator<CrashReporter>(),
        logger: _serviceLocator<Logger>(),
        performanceMonitor: _serviceLocator<PerformanceMonitor>(),
        errorRecoveryService: _serviceLocator<ErrorRecoveryService>(),
      ),
    );

    _serviceLocator.registerFactory<MessageBloc>(
      () => MessageBloc(
        messageRepository: _serviceLocator<IMessageRepository>(),
        analyticsService: _serviceLocator<AnalyticsService>(),
        crashReporter: _serviceLocator<CrashReporter>(),
        logger: _serviceLocator<Logger>(),
        performanceMonitor: _serviceLocator<PerformanceMonitor>(),
        errorRecoveryService: _serviceLocator<ErrorRecoveryService>(),
      ),
    );

    stopwatch.stop();
    _initializationTimes['blocs'] = stopwatch.elapsedMilliseconds;
    _logger.d('BLoCs initialized in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Get service instance
  static T get<T extends Object>() {
    if (!_isInitialized) {
      throw StateError('EnterpriseDI not initialized. Call initialize() first.');
    }
    return _serviceLocator<T>();
  }

  /// Check if service is registered
  static bool isRegistered<T extends Object>() {
    return _serviceLocator.isRegistered<T>();
  }

  /// Reset DI system (for testing)
  @visibleForTesting
  static Future<void> reset() async {
    await _serviceLocator.reset();
    _isInitialized = false;
    _initializationTimes.clear();
    _logger.i('🔄 Enterprise DI System reset completed');
  }
}
```

## 🔄 **DI CONSOLIDATION STRATEGY**

### **Phase 1: DI System Enhancement (Days 1-2)**

#### **Step 1: Audit Current DI Usage**
```bash
# Find all manual dependency injection patterns
grep -r "required.*Repository" lib/presentation/blocs/
grep -r "GetIt" lib/
grep -r "serviceLocator" lib/
grep -r "Provider.of" lib/
```

#### **Step 2: Identify Duplicate Registrations**
```dart
// lib/core/di/di_audit.dart
class DIAudit {
  static Future<Map<String, List<String>>> findDuplicateRegistrations() async {
    final duplicates = <String, List<String>>{};
    
    // Scan for duplicate service registrations
    // Check EnterpriseDI registrations
    // Check manual registrations in BLoCs
    // Check factory patterns in widgets
    
    return duplicates;
  }
}
```

### **Phase 2: Eliminate Manual Injection (Days 3-4)**

#### **Step 3: Convert BLoCs to Use EnterpriseDI**

**Before: Manual Constructor Injection**
```dart
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  final IChatRepository _chatRepository;
  final IMessageRepository _messageRepository;
  final AnalyticsService _analyticsService;
  // ... many manual dependencies

  ChatBloc({
    required IChatRepository chatRepository,
    required IMessageRepository messageRepository,
    required AnalyticsService analyticsService,
    // ... manual injection parameters
  }) : _chatRepository = chatRepository,
       _messageRepository = messageRepository,
       _analyticsService = analyticsService,
       super(initialState: const ChatState.initial());
}
```

**After: EnterpriseDI Integration**
```dart
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  late final IChatRepository _chatRepository;
  late final IMessageRepository _messageRepository;

  ChatBloc() : super(
    analyticsService: EnterpriseDI.get<AnalyticsService>(),
    crashReporter: EnterpriseDI.get<CrashReporter>(),
    logger: EnterpriseDI.get<Logger>(),
    performanceMonitor: EnterpriseDI.get<PerformanceMonitor>(),
    errorRecoveryService: EnterpriseDI.get<ErrorRecoveryService>(),
    initialState: const ChatState.initial(),
  ) {
    _chatRepository = EnterpriseDI.get<IChatRepository>();
    _messageRepository = EnterpriseDI.get<IMessageRepository>();
  }
}
```

#### **Step 4: Update Widget BLoC Providers**

**Before: Manual BLoC Creation**
```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        chatRepository: context.read<IChatRepository>(),
        messageRepository: context.read<IMessageRepository>(),
        analyticsService: context.read<AnalyticsService>(),
        // ... many manual dependencies
      ),
      child: ChatView(),
    );
  }
}
```

**After: EnterpriseDI Integration**
```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EnterpriseDI.get<ChatBloc>(),
      child: ChatView(),
    );
  }
}
```

### **Phase 3: Performance Optimization (Day 5)**

#### **Step 5: Optimize Service Lifecycle**
```dart
// Implement lazy loading for heavy services
_serviceLocator.registerLazySingleton<HeavyService>(
  () => HeavyService(),
  dispose: (service) => service.dispose(),
);

// Use factory for stateful services
_serviceLocator.registerFactory<StatefulService>(
  () => StatefulService(),
);
```

#### **Step 6: Add DI Performance Monitoring**
```dart
class DIPerformanceMonitor {
  static Future<void> monitorServiceCreation<T>() async {
    final stopwatch = Stopwatch()..start();
    final service = EnterpriseDI.get<T>();
    stopwatch.stop();
    
    Logger().d('Service ${T.toString()} created in ${stopwatch.elapsedMilliseconds}ms');
  }
}
```

## 📊 **DI VALIDATION CHECKLIST**

### **System-wide Validation**
- [ ] All services registered in EnterpriseDI
- [ ] No duplicate service registrations
- [ ] All BLoCs use EnterpriseDI
- [ ] All repositories use EnterpriseDI
- [ ] Widget providers simplified
- [ ] Performance targets met (<500ms initialization)

### **Testing Validation**
- [ ] All services mockable
- [ ] Test DI setup working
- [ ] Integration tests passing
- [ ] Performance tests validating
- [ ] Memory leak tests passing

## 🎯 **SUCCESS METRICS**

### **Quantitative Targets**
- **DI Consistency**: 40% → 100%
- **Duplicate Registrations**: 3 → 0
- **Initialization Time**: <500ms
- **Memory Usage**: -20% (eliminate duplicates)
- **Code Complexity**: -40% (simplified injection)

### **Qualitative Improvements**
- **Simplified BLoC Creation**: No manual dependency passing
- **Consistent Service Lifecycle**: Proper singleton/factory patterns
- **Better Testing**: Unified mocking strategy
- **Improved Performance**: Single initialization, lazy loading

---

**Next**: Review `07_naming_convention_standards.md` for comprehensive naming guidelines.
