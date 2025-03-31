import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/config/app_config.dart';
import 'package:flutter_chat_app/config/route/app_router.dart';
import 'package:flutter_chat_app/config/theme/app_theme.dart';
import 'package:flutter_chat_app/di/service_locator.dart';
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/utils/app_bloc_observer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/background_sync_service.dart';
import 'package:flutter_chat_app/core/services/chat_sync_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/notification_service.dart';
import 'package:flutter_chat_app/presentation/app.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/media_processing_service.dart';
import 'package:flutter_chat_app/core/services/resource_manager_service.dart';
import 'package:get_it/get_it.dart';

/// Handle Firebase background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase inside the background handler
  await Firebase.initializeApp();
  
  // Extract notification data
  final data = message.data;
  debugPrint("Background message received: ${message.messageId}");
  debugPrint("Data: $data");
}

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Configure dependency injection
    await configureDependencies();
    
    // Initialize media and resource services
    final resourceManager = GetIt.I<ResourceManagerService>();
    final mediaProcessor = GetIt.I<MediaProcessingService>();
    final connectivityAnalyzer = GetIt.I<ConnectivityAnalyzerService>();
    
    // Initialize platform-specific features
    await _initializePlatformSpecifics();
    
    // Initialize services
    await _initializeServices();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize Crashlytics
    if (!kDebugMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }
    
    // Initialize BLoC observer
    Bloc.observer = AppBlocObserver();
    
    runApp(const MyApp());
  }, (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
    }
  });
}

/// Initialize all required services
Future<void> _initializeServices() async {
  // Get service instances from dependency injection
  final connectivityService = GetIt.I<ConnectivityService>();
  final chatSyncService = GetIt.I<ChatSyncService>();
  final notificationService = GetIt.I<NotificationService>();
  final backgroundSyncService = GetIt.I<BackgroundSyncService>();
  
  // Initialize services
  await chatSyncService.initialize();
  await notificationService.initialize();
  await backgroundSyncService.initialize();
  
  // Schedule background sync
  await backgroundSyncService.schedulePeriodicSync(
    frequency: const Duration(hours: 1),
    requiresCharging: false,
    requiresDeviceIdle: false,
  );
  
  // Perform initial sync if connected
  if (await connectivityService.isConnected()) {
    await chatSyncService.syncAllChats();
  }
}

/// Initialize platform-specific features
Future<void> _initializePlatformSpecifics() async {
  if (Platform.isAndroid || Platform.isIOS) {
    // Request permissions for media processing
    await Permission.storage.request();
    
    // Initialize background task support
    await _initializeBackgroundTasks();
  }
}

/// Initialize background tasks for media processing
Future<void> _initializeBackgroundTasks() async {
  try {
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Register periodic tasks
    await Workmanager().registerPeriodicTask(
      'mediaProcessingTask',
      'mediaProcessing',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        batteryNotLow: true,
      ),
    );
    
    debugPrint('Background tasks initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize background tasks: $e');
  }
}

/// Background task callback
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case 'mediaProcessing':
          // Clean up temporary files
          final resourceManager = GetIt.I<ResourceManagerService>();
          await resourceManager.clearTemporaryFiles();
          
          // Process any pending media files
          final mediaProcessor = GetIt.I<MediaProcessingService>();
          await mediaProcessor.clearTemporaryFiles();
          break;
          
        default:
          debugPrint('Unknown task: $taskName');
          break;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error executing background task: $e');
      return false;
    }
  });
}

/// Main app widget
class MyApp extends StatelessWidget {
  /// Constructor
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App();
  }
} 