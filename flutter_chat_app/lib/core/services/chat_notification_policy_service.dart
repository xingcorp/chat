import 'package:flutter_chat_app/core/services/chat_active_conversation_tracker.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Encapsulates the business rules that decide whether a socket message should
/// become a local notification.
///
/// Decision matrix:
///
/// | Condition              | isMention=false | isMention=true |
/// |------------------------|-----------------|----------------|
/// | Self-sent              | SKIP            | SKIP           |
/// | Active conversation    | SKIP            | **SHOW**       |
/// | Muted conversation     | SKIP            | **SHOW**       |
/// | Normal                 | SHOW            | SHOW           |
class ChatNotificationPolicyService {
  ChatNotificationPolicyService({
    required CurrentUserProvider currentUserProvider,
    required ChatActiveConversationTracker activeConversationTracker,
    required AppLogger logger,
  })  : _currentUserProvider = currentUserProvider,
        _activeConversationTracker = activeConversationTracker,
        _logger = logger;

  final CurrentUserProvider _currentUserProvider;
  final ChatActiveConversationTracker _activeConversationTracker;
  final AppLogger _logger;

  /// Determines whether a notification should be shown for [message].
  ///
  /// [chat] is nullable because the Isar/remote lookup may fail. When `null`,
  /// the mute check is skipped (fail-open: show rather than silently swallow).
  ///
  /// [isMention] overrides active-conversation and mute suppression so that
  /// the user always sees notifications for messages that @mention them.
  bool shouldNotify({
    required ChatMessage message,
    Chat? chat,
    bool isMention = false,
  }) {
    final currentUserId = _currentUserProvider.currentUserId;

    // 1. ALWAYS skip self-sent messages — no exception, even for mentions.
    //    Fail-closed: if currentUserId is unknown (empty), suppress rather
    //    than risk showing the user a notification for their own message.
    if (currentUserId.isEmpty) {
      _logger.w(
        'Cannot determine current user — suppressing notification',
        context: <String, dynamic>{'messageId': message.id},
      );
      return false;
    }
    if (message.sender.id == currentUserId) {
      _logger.d(
        'Skipping local notification for self-sent message',
        <String, dynamic>{'messageId': message.id},
      );
      return false;
    }

    // 2. If the current user is @mentioned, override remaining suppression
    //    rules and show the notification.
    if (isMention) {
      _logger.d(
        'Showing notification despite suppression rules — user is @mentioned',
        <String, dynamic>{
          'conversationId': message.chatId,
          'messageId': message.id,
        },
      );
      return true;
    }

    // 3. Skip if the user is currently viewing this conversation.
    if (_activeConversationTracker.shouldSuppressConversationNotification(
      message.chatId,
    )) {
      _logger.d(
        'Skipping local notification for active conversation',
        <String, dynamic>{
          'conversationId': message.chatId,
          'messageId': message.id,
        },
      );
      return false;
    }

    // 4. Skip if the conversation is muted.
    if (chat?.isMuted == true) {
      _logger.d(
        'Skipping local notification for muted conversation',
        <String, dynamic>{
          'conversationId': message.chatId,
          'messageId': message.id,
        },
      );
      return false;
    }

    return true;
  }
}
