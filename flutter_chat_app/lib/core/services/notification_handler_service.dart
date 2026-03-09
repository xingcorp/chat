// **NOTIFICATION HANDLER SERVICE**
//
// Handles push notification interactions:
// - Notification tap events
// - Deep linking to conversations
// - Error handling for invalid conversations
//
// **Architecture:** Service Layer + Firebase Messaging Integration

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/config/route/app_router.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:flutter_chat_app/core/services/chat_notification_payload.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';

/// **Notification Handler Service**
///
/// Manages notification tap events and deep linking
@lazySingleton
class NotificationHandlerService {
  NotificationHandlerService({
    required AppLogger logger,
    required IChatRepository chatRepository,
  })  : _logger = logger,
        _chatRepository = chatRepository;

  final AppLogger _logger;
  final IChatRepository _chatRepository;

  /// Initialize notification handlers
  ///
  /// Sets up listeners for:
  /// - Foreground notification taps
  /// - Background notification taps
  /// - App opened from terminated state via notification
  Future<void> initialize() async {
    try {
      _logger.i('Initializing notification handlers');

      // Note: Actual Firebase Messaging setup would go here
      // FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      // final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      // if (initialMessage != null) {
      //   _handleNotificationTap(initialMessage);
      // }

      _logger.i('Notification handlers initialized');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize notification handlers',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handles chat notification taps from local notifications.
  Future<void> handleChatNotificationPayload(
    ChatNotificationPayload payload,
  ) async {
    if (ChatNavigationHelper.isPackageMode) {
      if (GetIt.I.isRegistered<ChatModuleEventBus>()) {
        GetIt.I<ChatModuleEventBus>().emitNotificationTap(payload);
        return;
      }

      _logger.w('Notification tap received in package mode without event bus');
      return;
    }

    final BuildContext? context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) {
      _logger.w('Cannot handle notification tap without navigator context');
      return;
    }

    await handleNotificationTap(context, payload.toNotificationData());
  }

  /// Handle notification tap event
  ///
  /// Parses metadata and navigates to the appropriate screen
  Future<void> handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      _logger.d('Handling notification tap: $data');

      // Parse metadata
      final Object? rawMetadata = data['metadata'];
      final Map<String, dynamic>? metadata =
          rawMetadata is Map<String, dynamic> ? rawMetadata : null;
      if (metadata == null) {
        _logger.w('Notification has no metadata');
        return;
      }

      final String? conversationId = metadata['conversationId']?.toString();
      if (conversationId == null || conversationId.isEmpty) {
        _logger.w('Notification has no conversationId');
        return;
      }

      // Verify conversation exists
      final conversationResult =
          await _chatRepository.getChatById(conversationId);

      await conversationResult.fold(
        (failure) async {
          // Conversation doesn't exist or error occurred
          _logger.w('Failed to load conversation: ${failure.message}');
          if (context.mounted) {
            AppSnackBar.error(
              context: context,
              message: context.l10n.conversationNotFound,
            );
          }
        },
        (conversation) async {
          // Navigate to conversation
          _logger.i('Navigating to conversation: $conversationId');
          if (context.mounted) {
            await ChatNavigationHelper.navigateToChatDetail(
              context,
              chatId: conversationId,
            );
          }
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error handling notification tap',
          error: e, stackTrace: stackTrace);
      if (context.mounted) {
        AppSnackBar.error(
          context: context,
          message: context.l10n.cannotOpenConversation,
        );
      }
    }
  }

  /// Parse notification data from RemoteMessage
  ///
  /// Extracts conversationId and other metadata
  Map<String, dynamic>? parseNotificationData(dynamic remoteMessage) {
    try {
      if (remoteMessage is Map<String, dynamic>) {
        return remoteMessage;
      }

      return null;
    } catch (e) {
      _logger.e('Failed to parse notification data', error: e);
      return null;
    }
  }
}
