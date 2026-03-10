import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/services/chat_notification_payload.dart';
import 'package:flutter_chat_app/core/services/windows_notification_icon_path.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin adapter around flutter_local_notifications.
class LocalNotificationService {
  LocalNotificationService({
    required AppLogger logger,
  }) : _logger = logger;

  static const String _androidChannelName = 'Chat messages';
  static const String _androidChannelDescription =
      'Incoming chat message alerts';
  static const String _androidNotificationIcon = 'ic_notification_app';
  static const String _androidNotificationLargeIcon =
      'ic_notification_large';
  static const Color _androidNotificationColor = Color(0xFF00AFD2);
  static const String _windowsAppName = 'OXII Chat';
  static const String _windowsAppUserModelId = 'OXII.Chat.Desktop.1';
  static const String _windowsGuid = '2c9f7f90-6bb9-4f4c-a0f9-2d9d6a7f5e11';
  static const String _windowsProductionIconAssetPath =
      'assets/icons/app_icon_production.png';
  static const String _windowsStagingIconAssetPath =
      'assets/icons/app_icon_staging.png';

  final AppLogger _logger;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<ChatNotificationPayload> _notificationTapController =
      StreamController<ChatNotificationPayload>.broadcast();

  bool _initialized = false;

  Stream<ChatNotificationPayload> get notificationTapStream =>
      _notificationTapController.stream;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) {
      return;
    }

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: const AndroidInitializationSettings(_androidNotificationIcon),
      iOS: _darwinInitializationSettings,
      macOS: _darwinInitializationSettings,
      windows: WindowsInitializationSettings(
        appName: _windowsAppName,
        appUserModelId: _windowsAppUserModelId,
        guid: _windowsGuid,
        iconPath: resolveWindowsNotificationIconPath(
          _windowsNotificationIconAssetPath,
        ),
      ),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    await _createAndroidChannel();
    await _requestPermissions();

    _initialized = true;
    _logger.i('Local notification service initialized');

    final NotificationAppLaunchDetails? launchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    final NotificationResponse? response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true && response != null) {
      _handleNotificationResponse(response);
    }
  }

  Future<void> showChatMessageNotification(
    ChatNotificationPayload payload,
  ) async {
    if (kIsWeb) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultAndroidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        icon: _androidNotificationIcon,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        channelShowBadge: true,
        color: _androidNotificationColor,
        largeIcon: const DrawableResourceAndroidBitmap(
          _androidNotificationLargeIcon,
        ),
      ),
      iOS: DarwinNotificationDetails(
        subtitle: payload.macosSubtitle,
        threadIdentifier: payload.conversationId,
        presentAlert: true,
        presentBanner: true,
        presentBadge: true,
        presentList: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        subtitle: payload.macosSubtitle,
        threadIdentifier: payload.conversationId,
        presentAlert: true,
        presentBanner: true,
        presentBadge: true,
        presentList: true,
        presentSound: true,
      ),
      windows: const WindowsNotificationDetails(),
    );

    await _plugin.show(
      payload.notificationId,
      payload.title,
      payload.body,
      details,
      payload: jsonEncode(payload.toJson()),
    );
  }

  Future<void> _createAndroidChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _defaultAndroidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.max,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final MacOSFlutterLocalNotificationsPlugin? macosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    await macosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final String? payloadString = response.payload;
    if (payloadString == null || payloadString.trim().isEmpty) {
      _logger.w('Notification response received without payload');
      return;
    }

    try {
      final Object? decoded = jsonDecode(payloadString);
      if (decoded is! Map<String, dynamic>) {
        _logger.w('Notification payload has unexpected format');
        return;
      }

      final payload = ChatNotificationPayload.fromJson(decoded);
      _notificationTapController.add(payload);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to decode notification payload',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static const DarwinInitializationSettings _darwinInitializationSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    defaultPresentAlert: true,
    defaultPresentBadge: true,
    defaultPresentBanner: true,
    defaultPresentList: true,
    defaultPresentSound: true,
  );

  static String get _defaultAndroidChannelId {
    if (FlavorConfig.isInitialized && FlavorConfig.instance.isStaging) {
      return 'oxii_chat_staging_notifications';
    }

    return 'oxii_chat_notifications';
  }

  static String get _windowsNotificationIconAssetPath {
    if (FlavorConfig.isInitialized && FlavorConfig.instance.isStaging) {
      return _windowsStagingIconAssetPath;
    }

    return _windowsProductionIconAssetPath;
  }
}
