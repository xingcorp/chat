import 'dart:async';
import 'dart:collection';

import 'package:flutter_chat_app/core/services/chat_notification_payload.dart';
import 'package:flutter_chat_app/core/services/chat_notification_policy_service.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/services/local_notification_service.dart';
import 'package:flutter_chat_app/core/services/notification_avatar_service.dart';
import 'package:flutter_chat_app/core/services/notification_handler_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Orchestrates socket -> local notification -> tap handling.
///
/// Flow:
/// 1. Receive message from [RealtimeService.messageStream]
/// 2. Deduplication check (recent 100 message IDs)
/// 3. Look up [Chat] entity for metadata (type, name, mute status)
/// 4. Detect @mention of current user
/// 5. Policy check (self-sent, active conversation, muted, mention override)
/// 6. Build rich [ChatNotificationPayload] (group vs direct format)
/// 7. Show local notification via [LocalNotificationService]
class ChatNotificationOrchestrator {
  ChatNotificationOrchestrator({
    required RealtimeService realtimeService,
    required ChatNotificationPolicyService notificationPolicy,
    required LocalNotificationService localNotificationService,
    required NotificationHandlerService notificationHandlerService,
    required IChatRepository chatRepository,
    required CurrentUserProvider currentUserProvider,
    required NotificationAvatarService notificationAvatarService,
    required AppLogger logger,
  })  : _realtimeService = realtimeService,
        _notificationPolicy = notificationPolicy,
        _localNotificationService = localNotificationService,
        _notificationHandlerService = notificationHandlerService,
        _chatRepository = chatRepository,
        _currentUserProvider = currentUserProvider,
        _notificationAvatarService = notificationAvatarService,
        _logger = logger;

  static const int _maxRecentMessageIds = 100;

  final RealtimeService _realtimeService;
  final ChatNotificationPolicyService _notificationPolicy;
  final LocalNotificationService _localNotificationService;
  final NotificationHandlerService _notificationHandlerService;
  final IChatRepository _chatRepository;
  final CurrentUserProvider _currentUserProvider;
  final NotificationAvatarService _notificationAvatarService;
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

    // 1. Deduplication check.
    if (!_rememberMessageId(message.id)) {
      _logger.d(
        'Skipping duplicate local notification candidate',
        <String, dynamic>{'messageId': message.id},
      );
      return;
    }

    // 2. Detect if the current user is @mentioned.
    final String currentUserId = _currentUserProvider.currentUserId;
    final bool isMention = currentUserId.isNotEmpty &&
        message.mentionTo.any(
          (MessageSender s) => s.id == currentUserId,
        );

    // 3. Look up Chat entity for metadata (type, name, mute status).
    Chat? chat;
    try {
      final chatResult = await _chatRepository.getChatById(message.chatId);
      chatResult.fold(
        (failure) {
          _logger.w(
            'Failed to look up chat for notification — falling back to direct format',
            context: <String, dynamic>{
              'conversationId': message.chatId,
              'failure': failure.message,
            },
          );
        },
        (foundChat) {
          chat = foundChat;
        },
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error looking up chat for notification',
        error: error,
        stackTrace: stackTrace,
      );
    }

    // 4. Policy check (self-sent, active conversation, muted, mention override).
    if (!_notificationPolicy.shouldNotify(
      message: message,
      chat: chat,
      isMention: isMention,
    )) {
      return;
    }

    // 5. Build rich payload.
    final ChatNotificationPayload payload;
    if (chat != null) {
      payload = ChatNotificationPayload.fromMessageWithChat(
        message: message,
        chat: chat!,
        isMention: isMention,
      );
    } else {
      // Fallback: no Chat metadata available — use legacy format.
      payload = ChatNotificationPayload.fromChatMessage(message);
    }

    // 6. Download avatar for notification icon (non-blocking, 3s timeout).
    //    For group chats: use group avatar if available, else sender avatar.
    //    For direct chats: use sender avatar.
    //    Fallback: generate initials-based avatar if download fails or no URL.
    final String? avatarUrl = (chat != null &&
            (chat!.type == ChatType.group || chat!.type == ChatType.channel) &&
            chat!.avatarUrl != null &&
            chat!.avatarUrl!.isNotEmpty)
        ? chat!.avatarUrl
        : message.sender.avatar;
    String? avatarFilePath =
        await _notificationAvatarService.getAvatarFilePath(avatarUrl);

    // Fallback: generate initials avatar matching the conversation list style.
    if (avatarFilePath == null && message.sender.name.isNotEmpty) {
      avatarFilePath = await _notificationAvatarService
          .generateInitialsAvatar(message.sender.name);
    }

    // 7. Show local notification with avatar.
    await _localNotificationService.showChatMessageNotification(
      payload,
      avatarFilePath: avatarFilePath,
    );
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
