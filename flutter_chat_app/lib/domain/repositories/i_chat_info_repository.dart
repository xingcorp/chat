import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';

/// Repository interface cho Chat Info operations
/// Domain layer - định nghĩa contract, không implement
abstract class IChatInfoRepository {
  /// Lấy danh sách shared media theo loại
  ///
  /// [chatId] - ID của chat
  /// [type] - Loại media cần lấy (photo, video, file, link)
  /// [limit] - Số lượng items tối đa (optional)
  /// [offset] - Offset cho pagination (optional)
  ///
  /// Returns [Right(List<SharedMedia>)] nếu thành công
  /// Returns [Left(Failure)] nếu có lỗi
  Future<Either<Failure, List<SharedMedia>>> getSharedMedia({
    required String chatId,
    required SharedMediaType type,
    int? limit,
    int? offset,
  });

  /// Lấy notification settings của chat
  ///
  /// [chatId] - ID của chat
  ///
  /// Returns [Right(NotificationSettings)] nếu thành công
  /// Returns [Left(Failure)] nếu có lỗi
  Future<Either<Failure, NotificationSettings>> getNotificationSettings({
    required String chatId,
  });

  /// Cập nhật notification settings
  ///
  /// [chatId] - ID của chat
  /// [settings] - Settings mới
  ///
  /// Returns [Right(NotificationSettings)] với settings đã cập nhật
  /// Returns [Left(Failure)] nếu có lỗi
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings({
    required String chatId,
    required NotificationSettings settings,
  });

  /// Block user (chỉ dành cho direct chat)
  ///
  /// [userId] - ID của user cần block
  ///
  /// Returns [Right(void)] nếu thành công
  /// Returns [Left(Failure)] nếu có lỗi
  Future<Either<Failure, void>> blockUser({
    required String userId,
  });

  /// Unblock user
  ///
  /// [userId] - ID của user cần unblock
  ///
  /// Returns [Right(void)] nếu thành công
  /// Returns [Left(Failure)] nếu có lỗi
  Future<Either<Failure, void>> unblockUser({
    required String userId,
  });

  /// Check xem user có bị block không
  ///
  /// [userId] - ID của user
  ///
  /// Returns [Right(bool)] true nếu bị block
  /// Returns [Left(Failure)] nếu có lỗi
  Future<Either<Failure, bool>> isUserBlocked({
    required String userId,
  });

  /// Report chat hoặc user
  ///
  /// [chatId] - ID của chat
  /// [reason] - Lý do report
  ///
  /// Returns [Right(void)] nếu thành công
  /// Returns [Left(Failure)] nếu có lỗi
  Future<Either<Failure, void>> reportChat({
    required String chatId,
    required String reason,
  });
}
