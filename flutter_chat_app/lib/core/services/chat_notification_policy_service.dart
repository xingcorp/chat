import 'package:flutter_chat_app/core/services/chat_active_conversation_tracker.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Encapsulates the business rules that decide whether a socket message should
/// become a local notification.
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

  bool shouldNotify(ChatMessage message) {
    final currentUserId = _currentUserProvider.currentUserId;
    if (currentUserId.isNotEmpty && message.sender.id == currentUserId) {
      _logger.d(
        'Skipping local notification for self-sent message',
        <String, dynamic>{'messageId': message.id},
      );
      return false;
    }

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

    return true;
  }
}
