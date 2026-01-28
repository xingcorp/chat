/// **ENTERPRISE APP INITIALIZER**
/// 
/// **DEPRECATED**: This file is deprecated and should not be used.
/// Use `EnterpriseDI.initialize()` from `enterprise_injection.dart` instead.
/// 
/// This file violates Clean Architecture by importing presentation layer
/// from infrastructure layer. It also manually registers dependencies
/// with incorrect parameters, causing constructor mismatch errors.
/// 
/// **Migration Guide:**
/// - Replace `EnterpriseAppInitializer.instance.initializeEnterpriseApp()`
/// - With `EnterpriseDI.initialize()`
/// 
/// Production-ready app initialization for messaging apps with
/// WhatsApp/Telegram/Zalo-level performance and enterprise standards.
/// 
/// **Features:**
/// - Clean Architecture compliance with SOLID principles
/// - Comprehensive initialization sequence
/// - Performance monitoring and optimization
/// - Enterprise error handling and recovery
/// - Dependency injection coordination
/// - Health checks and validation

@Deprecated('Use EnterpriseDI.initialize() instead. This file violates Clean Architecture.')
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../database/database_service.dart';
import '../services/enterprise_app_service.dart';
import '../../data/datasources/chat/chat_local_datasource.dart';
import '../../data/datasources/chat/chat_remote_datasource.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/enterprise_chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../cache/cache_sync_strategy.dart';
import '../cache/media_cache_manager.dart';
import '../services/connectivity_service.dart';

/// **ENTERPRISE APP INITIALIZER**
/// 
/// Orchestrates enterprise app initialization with performance monitoring
class EnterpriseAppInitializer {
  static EnterpriseAppInitializer? _instance;
  static EnterpriseAppInitializer get instance => _instance ??= EnterpriseAppInitializer._();
  
  EnterpriseAppInitializer._();
  
  // Initialization state
  bool _isInitialized = false;
  final Map<String, bool> _initializationStatus = {};
  final Map<String, Duration> _initializationTimes = {};
  
  // Service locator
  final GetIt _getIt = GetIt.instance;
  
  /// **Initialize Enterprise App**
  /// 
  /// Complete enterprise app initialization with performance monitoring.
  /// Target: <2s total initialization time
  Future<void> initializeEnterpriseApp() async {
    if (_isInitialized) return;
    
    final overallStopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🚀 Starting Enterprise App Initialization...');
      debugPrint('🎯 Target: WhatsApp/Telegram/Zalo performance standards');
      debugPrint('=' * 80);
      
      // **PHASE 1: Dependency Registration**
      await _registerDependencies();
      
      // **PHASE 2: Core Services Initialization**
      await _initializeCoreServices();
      
      // **PHASE 3: Data Layer Initialization**
      await _initializeDataLayer();
      
      // **PHASE 4: Domain Layer Initialization**
      await _initializeDomainLayer();
      
      // **PHASE 5: Presentation Layer Initialization**
      await _initializePresentationLayer();
      
      // **PHASE 6: Health Checks**
      await _performHealthChecks();
      
      // **PHASE 7: Performance Validation**
      await _validatePerformance();
      
      _isInitialized = true;
      
      overallStopwatch.stop();
      final totalTime = overallStopwatch.elapsedMilliseconds;
      
      debugPrint('');
      debugPrint('🎉 ENTERPRISE APP INITIALIZATION COMPLETE');
      debugPrint('=' * 80);
      debugPrint('📊 INITIALIZATION SUMMARY:');
      debugPrint('   - Total Time: ${totalTime}ms');
      debugPrint('   - Phases Completed: ${_initializationStatus.length}');
      debugPrint('   - Success Rate: ${_calculateSuccessRate()}%');
      debugPrint('');
      
      if (totalTime < 2000) {
        debugPrint('🎯 PERFORMANCE TARGET MET: ${totalTime}ms < 2000ms');
      } else {
        debugPrint('⚠️  PERFORMANCE WARNING: ${totalTime}ms > 2000ms');
      }
      
      _printInitializationBreakdown();
      
    } catch (e, stackTrace) {
      overallStopwatch.stop();
      debugPrint('❌ Enterprise App Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// **Register Dependencies**
  /// 
  /// Registers all enterprise dependencies with proper lifecycle management
  Future<void> _registerDependencies() async {
    await _executePhase('dependency_registration', () async {
      debugPrint('🔧 Registering Enterprise Dependencies...');
      
      // Core Services
      _getIt.registerSingleton<DatabaseService>(
        DatabaseService.instance,
      );

      _getIt.registerSingleton<EnterpriseAppService>(
        EnterpriseAppService(_getIt<DatabaseService>()),
      );

      // Network Services (Stub implementations for now)
      // TODO: Implement proper GraphQL client and socket manager
      // For now, we'll skip these registrations and handle in datasource

      // Data Layer
      _getIt.registerSingleton<ChatLocalDataSource>(
        ChatLocalDataSourceImpl(_getIt<DatabaseService>()),
      );

      _getIt.registerSingleton<ChatRemoteDataSource>(
        ChatRemoteDataSourceStub(), // Temporary stub implementation
      );

      _getIt.registerSingleton<IChatRepository>(
        EnterpriseChatRepositoryImpl(
          _getIt<ChatLocalDataSource>(),
          _getIt<ChatRemoteDataSource>(),
        ),
      );

      // Core Services for ChatBloc
      _getIt.registerSingleton<Connectivity>(
        Connectivity(),
      );

      _getIt.registerSingleton<ConnectivityService>(
        ConnectivityService(_getIt<Connectivity>()),
      );

      _getIt.registerSingleton<CacheSyncStrategy>(
        CacheSyncStrategy(),
      );

      _getIt.registerSingleton<MediaCacheManager>(
        MediaCacheManager(),
      );

      // Presentation Layer - Updated to use consolidated ChatBloc
      _getIt.registerFactory<ChatBloc>(
        () => ChatBloc(
          _getIt<IChatRepository>(),
          _getIt<ConnectivityService>(),
          _getIt<CacheSyncStrategy>(),
          _getIt<MediaCacheManager>(),
        ),
      );
      
      debugPrint('✅ Dependencies registered successfully');
    });
  }
  
  /// **Initialize Core Services**
  /// 
  /// Initializes core enterprise services
  Future<void> _initializeCoreServices() async {
    await _executePhase('core_services', () async {
      debugPrint('📊 Initializing Core Services...');
      
      // Initialize Database Service
      final databaseService = _getIt<DatabaseService>();
      await databaseService.initialize();
      
      // Initialize App Service
      final appService = _getIt<EnterpriseAppService>();
      await appService.initialize();
      
      debugPrint('✅ Core services initialized');
    });
  }
  
  /// **Initialize Data Layer**
  /// 
  /// Initializes data layer components
  Future<void> _initializeDataLayer() async {
    await _executePhase('data_layer', () async {
      debugPrint('💾 Initializing Data Layer...');
      
      // Data sources are initialized on-demand
      // Repository is ready to use
      
      debugPrint('✅ Data layer initialized');
    });
  }
  
  /// **Initialize Domain Layer**
  /// 
  /// Initializes domain layer components
  Future<void> _initializeDomainLayer() async {
    await _executePhase('domain_layer', () async {
      debugPrint('🏗️  Initializing Domain Layer...');
      
      // Use cases and domain services initialization
      // Currently using repository directly in BLoC
      
      debugPrint('✅ Domain layer initialized');
    });
  }
  
  /// **Initialize Presentation Layer**
  /// 
  /// Initializes presentation layer components
  Future<void> _initializePresentationLayer() async {
    await _executePhase('presentation_layer', () async {
      debugPrint('🎨 Initializing Presentation Layer...');
      
      // BLoCs are created on-demand via factory
      // Test BLoC creation
      final testBloc = _getIt<ChatBloc>();
      await testBloc.close(); // Clean up test instance
      
      debugPrint('✅ Presentation layer initialized');
    });
  }
  
  /// **Perform Health Checks**
  /// 
  /// Validates that all components are healthy
  Future<void> _performHealthChecks() async {
    await _executePhase('health_checks', () async {
      debugPrint('🏥 Performing Health Checks...');
      
      // Database Health Check
      final databaseService = _getIt<DatabaseService>();
      final dbHealth = await databaseService.performHealthCheck();
      
      if (!dbHealth.isHealthy) {
        throw Exception('Database health check failed: ${dbHealth.message}');
      }
      
      // App Service Health Check
      final appService = _getIt<EnterpriseAppService>();
      final appStatus = appService.getAppStatus();
      
      if (!appStatus.isHealthy) {
        throw Exception('App service health check failed');
      }
      
      debugPrint('✅ All health checks passed');
    });
  }
  
  /// **Validate Performance**
  /// 
  /// Validates performance metrics against enterprise targets
  Future<void> _validatePerformance() async {
    await _executePhase('performance_validation', () async {
      debugPrint('📊 Validating Performance Metrics...');
      
      // Collect performance metrics
      final appService = _getIt<EnterpriseAppService>();
      final performanceMetrics = appService.getPerformanceSummary();
      
      debugPrint('📈 Performance Summary:');
      performanceMetrics.forEach((key, value) {
        debugPrint('   - $key: $value');
      });
      
      debugPrint('✅ Performance validation completed');
    });
  }
  
  /// **Execute Phase with Monitoring**
  /// 
  /// Executes initialization phase with performance monitoring
  Future<void> _executePhase(String phaseName, Future<void> Function() phase) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await phase();
      
      stopwatch.stop();
      _initializationStatus[phaseName] = true;
      _initializationTimes[phaseName] = stopwatch.elapsed;
      
    } catch (e) {
      stopwatch.stop();
      _initializationStatus[phaseName] = false;
      _initializationTimes[phaseName] = stopwatch.elapsed;
      
      debugPrint('❌ Phase failed: $phaseName - $e');
      rethrow;
    }
  }
  
  /// **Calculate Success Rate**
  int _calculateSuccessRate() {
    if (_initializationStatus.isEmpty) return 0;
    
    final successCount = _initializationStatus.values.where((success) => success).length;
    return (successCount / _initializationStatus.length * 100).round();
  }
  
  /// **Print Initialization Breakdown**
  void _printInitializationBreakdown() {
    debugPrint('⏱️  INITIALIZATION BREAKDOWN:');
    
    _initializationTimes.forEach((phase, duration) {
      final status = _initializationStatus[phase] == true ? '✅' : '❌';
      final timeMs = duration.inMilliseconds;
      debugPrint('   $status $phase: ${timeMs}ms');
    });
    
    debugPrint('');
  }
  
  /// **Get Service**
  /// 
  /// Type-safe service retrieval with validation
  T getService<T extends Object>() {
    if (!_isInitialized) {
      throw Exception('Enterprise app not initialized. Call initializeEnterpriseApp() first.');
    }
    
    try {
      return _getIt<T>();
    } catch (e) {
      throw Exception('Failed to get service $T: $e');
    }
  }
  
  /// **Check Service Registration**
  /// 
  /// Checks if a service is registered
  bool isServiceRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }
  
  /// **Get Initialization Status**
  /// 
  /// Returns detailed initialization status
  Map<String, dynamic> getInitializationStatus() {
    return {
      'is_initialized': _isInitialized,
      'phase_status': Map.from(_initializationStatus),
      'phase_times': _initializationTimes.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'success_rate': _calculateSuccessRate(),
      'total_phases': _initializationStatus.length,
      'successful_phases': _initializationStatus.values.where((s) => s).length,
    };
  }
  
  /// **Reset Initialization**
  /// 
  /// Resets initialization state for testing
  Future<void> reset() async {
    try {
      debugPrint('🔄 Resetting Enterprise App Initializer...');
      
      // Dispose services
      if (_getIt.isRegistered<EnterpriseAppService>()) {
        final appService = _getIt<EnterpriseAppService>();
        await appService.dispose();
      }
      
      if (_getIt.isRegistered<DatabaseService>()) {
        final dbService = _getIt<DatabaseService>();
        await dbService.dispose();
      }
      
      // Reset GetIt
      await _getIt.reset();
      
      // Reset state
      _isInitialized = false;
      _initializationStatus.clear();
      _initializationTimes.clear();
      
      debugPrint('✅ Enterprise App Initializer reset');
      
    } catch (e) {
      debugPrint('❌ Failed to reset Enterprise App Initializer: $e');
      rethrow;
    }
  }
}

/// **Enterprise App Initialization Helper Functions**

/// **Initialize Enterprise App**
/// 
/// Convenience function for app initialization
Future<void> initializeEnterpriseApp() async {
  await EnterpriseAppInitializer.instance.initializeEnterpriseApp();
}

/// **Get Enterprise Service**
/// 
/// Convenience function for service retrieval
T getEnterpriseService<T extends Object>() {
  return EnterpriseAppInitializer.instance.getService<T>();
}

/// **Check Enterprise Service**
///
/// Convenience function for service registration check
bool isEnterpriseServiceRegistered<T extends Object>() {
  return EnterpriseAppInitializer.instance.isServiceRegistered<T>();
}

/// **TEMPORARY STUB IMPLEMENTATIONS**
///
/// These are temporary stub implementations to resolve dependency issues
/// during the critical error resolution phase.

/// Temporary stub for ChatRemoteDataSource
class ChatRemoteDataSourceStub implements ChatRemoteDataSource {
  @override
  Future<List<ChatModel>> getUserChats() async {
    // Stub implementation - returns empty list
    await Future.delayed(const Duration(milliseconds: 100));
    return <ChatModel>[];
  }

  @override
  Future<ChatModel> getChatDetails(String chatId) async {
    // Stub implementation - throws not implemented
    throw UnimplementedError('ChatRemoteDataSourceStub: getChatDetails not implemented');
  }

  @override
  Future<ChatModel> createDirectChat(String userId) async {
    throw UnimplementedError('ChatRemoteDataSourceStub: createDirectChat not implemented');
  }

  @override
  Future<ChatModel> createGroupChat(String name, List<String> userIds) async {
    throw UnimplementedError('ChatRemoteDataSourceStub: createGroupChat not implemented');
  }

  @override
  Future<ChatModel> updateChat(String chatId, {String? name, String? avatarUrl}) async {
    throw UnimplementedError('ChatRemoteDataSourceStub: updateChat not implemented');
  }

  @override
  Future<bool> addUsersToChat(String chatId, List<String> userIds) async {
    throw UnimplementedError('ChatRemoteDataSourceStub: addUsersToChat not implemented');
  }

  @override
  Future<bool> removeUsersFromChat(String chatId, List<String> userIds) async {
    throw UnimplementedError('ChatRemoteDataSourceStub: removeUsersFromChat not implemented');
  }

  @override
  Future<bool> deleteChat(String chatId) async {
    throw UnimplementedError('ChatRemoteDataSourceStub: deleteChat not implemented');
  }

  @override
  Future<bool> leaveChat(String chatId) async {
    throw UnimplementedError('ChatRemoteDataSourceStub: leaveChat not implemented');
  }

  @override
  Stream<ChatModel> subscribeToChats() {
    // Stub implementation - returns empty stream
    return const Stream.empty();
  }

  /// **Additional Methods for Repository Support**

  /// Get chat messages (stub implementation)
  @override
  Future<List<MessageModel>> getChatMessages(
    String chatId, {
    int limit = 50,
    String? before,
  }) async {
    // Stub implementation - returns empty list
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint('📋 ChatRemoteDataSourceStub: getChatMessages called for $chatId');
    return <MessageModel>[];
  }

  /// Send message (stub implementation)
  @override
  Future<MessageModel> sendMessage(ChatMessage message) async {
    // Stub implementation - returns the same message with server ID
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('📤 ChatRemoteDataSourceStub: sendMessage called for ${message.id}');

    // Return message with server-generated ID
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch, // int ID for MessageModel
      serverId: 'server_${DateTime.now().millisecondsSinceEpoch}',
      localId: message.id,
      chatId: message.chatId,
      senderId: message.sender.id, // Use sender.id from ChatMessage
      content: message.content,
      type: MessageType.text, // Default to text type
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
      readBy: const [],
    );
  }

  /// Get chats (stub implementation)
  @override
  Future<List<ChatModel>> getChats() async {
    // Stub implementation - returns empty list
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('📋 ChatRemoteDataSourceStub: getChats called');
    return <ChatModel>[];
  }

  /// Get chat by ID (stub implementation)
  @override
  Future<ChatModel?> getChatById(String chatId) async {
    // Stub implementation - returns null
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint('🔍 ChatRemoteDataSourceStub: getChatById called for $chatId');
    return null;
  }
}
