import 'dart:async';
import 'dart:collection';

import 'package:flutter_chat_app/core/services/chat_notification_payload.dart';
import 'package:flutter_chat_app/core/services/chat_notification_policy_service.dart';
import 'package:flutter_chat_app/core/services/local_notification_service.dart';
import 'package:flutter_chat_app/core/services/notification_handler_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Orchestrates socket -> local notification -> tap handling.
class ChatNotificationOrchestrator {
  ChatNotificationOrchestrator({
    required RealtimeService realtimeService,
    required ChatNotificationPolicyService notificationPolicy,
    required LocalNotificationService localNotificationService,
    required NotificationHandlerService notificationHandlerService,
    required AppLogger logger,
  })  : _realtimeService = realtimeService,
        _notificationPolicy = notificationPolicy,
        _localNotificationService = localNotificationService,
        _notificationHandlerService = notificationHandlerService,
        _logger = logger;

  static const int _maxRecentMessageIds = 100;

  final RealtimeService _realtimeService;
  final ChatNotificationPolicyService _notificationPolicy;
  final LocalNotificationService _localNotificationService;
  final NotificationHandlerService _notificationHandlerService;
  final AppLogger _logger;

  final ListQueue<String> _recentMessageIds = ListQueue<String>();
  final Set<String> _recentMessageIdSet = <String>{};

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<ChatNotificationPayload>? _tapSubscription;

  bool _isInitialized = false;

  Future<void> initialize({
    required bool enableBuiltInNotifications,
  }) async {
    await dispose();

    if (!enableBuiltInNotifications) {
      _logger.i('Built-in local chat notifications are disabled');
      return;
    }

    _tapSubscription = _localNotificationService.notificationTapStream.listen(
      (payload) {
        unawaited(_notificationHandlerService.handleChatNotificationPayload(
          payload,
        ));
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.e(
          'Notification tap stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    await _localNotificationService.initialize();

    _messageSubscription = _realtimeService.messageStream.listen(
      (message) {
        unawaited(_handleIncomingMessage(message));
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.e(
          'Realtime message stream failed for notifications',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _isInitialized = true;
    _logger.i('Chat notification orchestrator initialized');
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _tapSubscription?.cancel();
    _messageSubscription = null;
    _tapSubscription = null;
    _recentMessageIds.clear();
    _recentMessageIdSet.clear();
    _isInitialized = false;
  }

  Future<void> _handleIncomingMessage(ChatMessage message) async {
    if (!_isInitialized) {
      return;
    }

    if (!_rememberMessageId(message.id)) {
      _logger.d(
        'Skipping duplicate local notification candidate',
        <String, dynamic>{'messageId': message.id},
      );
      return;
    }

    if (!_notificationPolicy.shouldNotify(message)) {
      return;
    }

    final payload = ChatNotificationPayload.fromChatMessage(message);
    await _localNotificationService.showChatMessageNotification(payload);
  }

  bool _rememberMessageId(String messageId) {
    if (_recentMessageIdSet.contains(messageId)) {
      return false;
    }

    _recentMessageIdSet.add(messageId);
    _recentMessageIds.addLast(messageId);

    while (_recentMessageIds.length > _maxRecentMessageIds) {
      final String oldestId = _recentMessageIds.removeFirst();
      _recentMessageIdSet.remove(oldestId);
    }

    return true;
  }
}
