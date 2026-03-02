import 'package:flutter_chat_app/core/cache/background_sync_helper.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

/// Handles FCM (Firebase Cloud Messaging) data payloads for the chat module.
///
/// This class provides two entry points:
/// - [onForegroundMessage]: For messages received while the app is in foreground.
///   Routes through [ChatModuleEventBus] so the UI updates instantly.
/// - [onBackgroundMessage]: For messages received when the app is killed or
///   in background. Uses [BackgroundSyncHelper] (no GetIt dependency).
///
/// ## Integration with Host App
///
/// The host app registers its own FCM listener and forwards chat-related
/// payloads to this handler:
///
/// ```dart
/// FirebaseMessaging.onMessage.listen((message) {
///   if (message.data['type']?.startsWith('chat') ?? false) {
///     ChatFCMHandler.onForegroundMessage(message.data);
///   }
/// });
///
/// // Top-level function for background
/// @pragma('vm:entry-point')
/// Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
///   if (message.data['type']?.startsWith('chat') ?? false) {
///     await ChatFCMHandler.onBackgroundMessage(message.data);
///   }
/// }
/// ```
class ChatFCMHandler {
  ChatFCMHandler._();

  static final Logger _logger = Logger();

  /// Known FCM data types that this handler processes.
  static const Set<String> _chatMessageTypes = {
    'chat_new_message',
    'chat_message',
    'new_message',
  };

  static const Set<String> _chatSyncTypes = {
    'chat_sync',
    'chat_update',
    'chat_deleted',
    'chat_member_added',
    'chat_member_removed',
  };

  /// Handle a foreground FCM data payload.
  ///
  /// Routes through [ChatModuleEventBus] if available (GetIt is alive).
  /// Falls back to triggering a sync if the event bus is not registered.
  static void onForegroundMessage(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String? ?? '';

      if (_chatMessageTypes.contains(type)) {
        // Emit raw FCM data to event bus — ChatBloc or ForegroundSyncService
        // will process it and update the UI.
        if (GetIt.instance.isRegistered<ChatModuleEventBus>()) {
          GetIt.instance<ChatModuleEventBus>().emitFCMData(data);
        }
      } else if (_chatSyncTypes.contains(type)) {
        // Trigger a full sync for structural changes
        if (GetIt.instance.isRegistered<ChatModuleEventBus>()) {
          GetIt.instance<ChatModuleEventBus>().triggerSync();
        }
      } else {
        _logger.d('ChatFCMHandler: Ignoring unknown type: $type');
      }
    } catch (e) {
      _logger.e('ChatFCMHandler: Foreground handler error: $e');
    }
  }

  /// Handle a background FCM data payload.
  ///
  /// This runs in a background isolate — GetIt is NOT available.
  /// Uses [BackgroundSyncHelper] to open its own Isar + GraphQL client
  /// and persist changes directly.
  ///
  /// Must be called from a top-level or static function annotated with
  /// `@pragma('vm:entry-point')`.
  static Future<void> onBackgroundMessage(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String? ?? '';

      if (_chatMessageTypes.contains(type) || _chatSyncTypes.contains(type)) {
        final helper = await BackgroundSyncHelper.initialize();
        try {
          await helper.syncChatList();
        } finally {
          await helper.dispose();
        }
      }
    } catch (e) {
      _logger.e('ChatFCMHandler: Background handler error: $e');
    }
  }

  /// Check whether a given FCM data payload is chat-related.
  ///
  /// Host app can use this to decide whether to forward the payload:
  /// ```dart
  /// if (ChatFCMHandler.isChatMessage(message.data)) {
  ///   ChatFCMHandler.onForegroundMessage(message.data);
  /// }
  /// ```
  static bool isChatMessage(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    return _chatMessageTypes.contains(type) || _chatSyncTypes.contains(type);
  }
}
