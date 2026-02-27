import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// **PUSH NOTIFICATION REPOSITORY INTERFACE**
///
/// Interface for sending push notifications to users via backend chatNotifyUser mutation.
///
/// **Error Handling**: Returns Either<Failure, bool> for consistent error management
/// **Strategy**: Fire-and-forget pattern - non-critical operation
/// **Architecture**: Clean Architecture with SOLID principles
abstract class IPushNotificationRepository {
  /// **Gửi push notification đến danh sách users**
  ///
  /// **Strategy**: executeOnlineOnly (requires backend mutation)
  /// **Performance**: Non-blocking, fire-and-forget
  /// **Use Case**: Mention notifications, important messages
  ///
  /// **Parameters**:
  /// - [receiverIds]: Danh sách user IDs nhận notification
  /// - [title]: Tiêu đề notification (thường là tên conversation)
  /// - [content]: Nội dung notification (truncated 100 chars)
  /// - [metadata]: Dữ liệu bổ sung (conversationId, messageId, type)
  ///
  /// **Returns**: Either<Failure, bool> - true nếu gửi thành công
  ///
  /// **Validates**: Requirements 2.1
  Future<Either<Failure, bool>> notifyUsers({
    required List<String> receiverIds,
    required String title,
    required String content,
    Map<String, dynamic>? metadata,
  });
}
