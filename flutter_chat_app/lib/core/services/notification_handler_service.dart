/// **NOTIFICATION HANDLER SERVICE**
///
/// Handles push notification interactions:
/// - Notification tap events
/// - Deep linking to conversations
/// - Error handling for invalid conversations
///
/// **Architecture:** Service Layer + Firebase Messaging Integration

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';

/// **Notification Handler Service**
///
/// Manages notification tap events and deep linking
@lazySingleton
class NotificationHandlerService {
  NotificationHandlerService({
    required Logger logger,
    required IChatRepository chatRepository,
  })  : _logger = logger,
        _chatRepository = chatRepository;

  final Logger _logger;
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

  /// Handle notification tap event
  ///
  /// Parses metadata and navigates to the appropriate screen
  Future<void> handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      _logger.d('Handling notification tap: ${data.toString()}');

      // Parse metadata
      final metadata = data['metadata'] as Map<String, dynamic>?;
      if (metadata == null) {
        _logger.w('Notification has no metadata');
        return;
      }

      final conversationId = metadata['conversationId'] as String?;
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
      // Note: Actual parsing would depend on RemoteMessage structure
      // final data = remoteMessage.data;
      // return data;
      return null;
    } catch (e) {
      _logger.e('Failed to parse notification data', error: e);
      return null;
    }
  }
}
