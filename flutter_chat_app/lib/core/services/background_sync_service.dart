import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Service for handling background synchronization
@lazySingleton
class BackgroundSyncService {
  static const String _taskName = 'chatSyncTask';
  static const String _taskUniqueName = 'com.example.flutter_chat_app.chat_sync';
  
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  final Workmanager _workmanager = Workmanager();
  
  /// Initialize the background sync service
  Future<void> initialize() async {
    // Initialize background service
    await _initializeBackgroundService();
    
    // Initialize workmanager for periodic background tasks
    await _initializeWorkManager();
  }
  
  /// Initialize the background service for continuous running tasks
  Future<void> _initializeBackgroundService() async {
    // Configure the background service
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'chat_sync_channel',
        initialNotificationTitle: 'Chat Sync',
        initialNotificationContent: 'Syncing your messages',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onBackgroundServiceStart,
        onBackground: _onIosBackground,
      ),
    );
  }
  
  /// Handler for iOS background processing
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final syncEnabled = prefs.getBool('background_sync_enabled') ?? false;
    
    return syncEnabled;
  }
  
  /// Handler for when the background service starts
  @pragma('vm:entry-point')
  static void _onBackgroundServiceStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }
    
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    
    // Execute sync every 15 minutes
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        // Check if the service should still be running
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final syncEnabled = prefs.getBool('background_sync_enabled') ?? false;
        
        if (!syncEnabled) {
          service.stopSelf();
          return;
        }
        
        // Notify that sync is happening
        service.setForegroundNotificationInfo(
          title: 'Chat Sync',
          content: 'Syncing messages in background',
        );
      }
      
      // Perform the sync
      await _performBackgroundSync();
      
      if (service is AndroidServiceInstance) {
        // Update notification after sync completes
        service.setForegroundNotificationInfo(
          title: 'Chat Sync',
          content: 'Last sync: ${DateTime.now().toString()}',
        );
      }
      
      // Broadcast sync complete to main app
      service.invoke('syncComplete', {
        'time': DateTime.now().toIso8601String(),
      });
    });
  }
  
  /// Initialize WorkManager for periodic tasks (cross-platform)
  Future<void> _initializeWorkManager() async {
    await _workmanager.initialize(
      _workmanagerCallbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
  }
  
  /// Callback dispatcher for Workmanager
  @pragma('vm:entry-point')
  static void _workmanagerCallbackDispatcher() {
    Workmanager().executeTask((taskName, inputData) async {
      // Initialize necessary components
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      
      if (taskName == 'chatSyncTask') {
        try {
          await _performBackgroundSync();
          return true;
        } catch (e) {
          debugPrint('Error in background sync: $e');
          return false;
        }
      }
      
      return true;
    });
  }
  
  /// Perform the actual background sync
  static Future<void> _performBackgroundSync() async {
    // In a real implementation, this would use your dependency injection to get
    // instances of the chat and message repository, and then sync data.
    // 
    // For the purpose of this example, we'll simulate a sync operation:
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_time');
    final lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.now();
    
    // Update last sync time
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
    
    // Show a notification that sync completed
    await _showSyncCompletedNotification();
  }
  
  /// Show a notification when sync completes
  static Future<void> _showSyncCompletedNotification() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Initialize notification
    const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInitializationSettings = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Define notification details
    const androidNotificationDetails = AndroidNotificationDetails(
      'background_sync_channel',
      'Background Sync',
      channelDescription: 'Notifications for background sync operations',
      importance: Importance.low,
      priority: Priority.low,
    );
    
    const iosNotificationDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0,
      'Sync Complete',
      'Your messages have been synchronized',
      notificationDetails,
    );
  }
  
  /// Schedule a periodic background sync using WorkManager
  Future<void> schedulePeriodicSync({
    Duration frequency = const Duration(hours: 1),
    bool requiresCharging = false,
    bool requiresDeviceIdle = false,
  }) async {
    // Cancel any existing tasks first
    await _workmanager.cancelByUniqueName(_taskUniqueName);
    
    // Schedule new periodic task
    await _workmanager.registerPeriodicTask(
      _taskUniqueName,
      _taskName,
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: requiresCharging,
        requiresDeviceIdle: requiresDeviceIdle,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    
    // Save the sync settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_sync_enabled', true);
    await prefs.setInt('background_sync_frequency_minutes', frequency.inMinutes);
    await prefs.setBool('background_sync_requires_charging', requiresCharging);
    await prefs.setBool('background_sync_requires_device_idle', requiresDeviceIdle);
  }
  
  /// Start the continuous background service
  Future<bool> startBackgroundService() async {
    final isRunning = await _backgroundService.isRunning();
    if (!isRunning) {
      await _backgroundService.startService();
      
      // Save service state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_sync_enabled', true);
    }
    return await _backgroundService.isRunning();
  }
  
  /// Stop the continuous background service
  Future<bool> stopBackgroundService() async {
    // Invoke the stop service event
    await _backgroundService.invoke('stopService');
    
    // Cancel any work manager tasks
    await _workmanager.cancelByUniqueName(_taskUniqueName);
    
    // Save service state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_sync_enabled', false);
    
    // Wait a moment and check if service is actually stopped
    await Future.delayed(const Duration(seconds: 1));
    return !(await _backgroundService.isRunning());
  }
  
  /// Get current background sync settings
  Future<Map<String, dynamic>> getBackgroundSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('background_sync_enabled') ?? false,
      'frequency': prefs.getInt('background_sync_frequency_minutes') ?? 60,
      'requiresCharging': prefs.getBool('background_sync_requires_charging') ?? false,
      'requiresDeviceIdle': prefs.getBool('background_sync_requires_device_idle') ?? false,
      'lastSyncTime': prefs.getString('last_sync_time') ?? DateTime.now().toIso8601String(),
    };
  }
} 