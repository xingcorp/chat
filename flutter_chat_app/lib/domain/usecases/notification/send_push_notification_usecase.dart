import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_push_notification_repository.dart';
import 'package:injectable/injectable.dart';

/// **SEND PUSH NOTIFICATION USE CASE**
///
/// Fire-and-forget use case để gửi push notification đến danh sách users.
///
/// **Strategy**: Non-blocking, silent fail (log only)
/// **Performance**: Không block UI, không throw exception
/// **Use Case**: Mention notifications, important messages
///
/// **Business Rules**:
/// - Skip nếu receiverIds rỗng
/// - Truncate content > 100 chars
/// - Log error nhưng không throw (non-critical operation)
///
/// **Validates**: Requirements 2.3, 3.2, 3.3
@injectable
class SendPushNotificationUseCase {
  final IPushNotificationRepository _repository;
  final AppLogger _logger;

  const SendPushNotificationUseCase({
    required IPushNotificationRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// **Gửi push notification đến danh sách users**
  ///
  /// **Parameters**:
  /// - [receiverIds]: Danh sách user IDs nhận notification
  /// - [title]: Tiêu đề notification (thường là tên conversation)
  /// - [content]: Nội dung notification (sẽ truncate nếu > 100 chars)
  /// - [metadata]: Dữ liệu bổ sung (conversationId, messageId, type)
  ///
  /// **Returns**: void (fire-and-forget)
  ///
  /// **Example**:
  /// ```dart
  /// await sendPushNotification(
  ///   receiverIds: ['user_1', 'user_2'],
  ///   title: 'Nhóm ABC',
  ///   content: '@User Bạn xem giúp mình...',
  ///   metadata: {
  ///     'conversationId': 'conv_123',
  ///     'messageId': 'msg_456',
  ///     'type': 'mention',
  ///   },
  /// );
  /// ```
  Future<void> call({
    required List<String> receiverIds,
    required String title,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    // Skip nếu receiverIds rỗng
    if (receiverIds.isEmpty) {
      _logger.debug('Skip push notification: receiverIds is empty');
      return;
    }

    // Truncate content nếu > 100 chars
    final truncatedContent = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;

    // Gọi repository để gửi notification
    final result = await _repository.notifyUsers(
      receiverIds: receiverIds,
      title: title,
      content: truncatedContent,
      metadata: metadata,
    );

    // Fire-and-forget: log kết quả, không throw
    result.fold(
      (failure) => _logger.error(
        'Push notification failed',
        failure,
      ),
      (success) => _logger.info(
        'Push notification sent',
        {'count': receiverIds.length, 'title': title},
      ),
    );
  }
}
