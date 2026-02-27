import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/data/datasources/notification/push_notification_remote_datasource.dart';
import 'package:flutter_chat_app/domain/repositories/i_push_notification_repository.dart';
import 'package:injectable/injectable.dart';

/// **PUSH NOTIFICATION REPOSITORY IMPLEMENTATION**
///
/// Implementation of IPushNotificationRepository for sending push notifications
/// via backend chatNotifyUser mutation.
///
/// **Error Handling**: Uses BaseRepository pattern with executeOnlineFirst strategy
/// **Strategy**: Fire-and-forget pattern - non-critical operation
/// **Architecture**: Clean Architecture with SOLID principles + BaseRepository pattern
///
/// **Validates**: Requirements 2.4
@LazySingleton(as: IPushNotificationRepository)
class PushNotificationRepositoryImpl extends BaseRepository
    implements IPushNotificationRepository {
  final PushNotificationRemoteDataSource _remoteDataSource;

  PushNotificationRepositoryImpl({
    required PushNotificationRemoteDataSource remoteDataSource,
    required super.networkInfo,
    required super.logger,
    required super.performanceMonitor,
  }) : _remoteDataSource = remoteDataSource;

  /// **Gửi push notification đến danh sách users**
  ///
  /// **Strategy**: Online-first - requires backend mutation, no local fallback
  /// **Performance**: Non-blocking operation with performance monitoring
  ///
  /// **Error Handling**:
  /// - Uses BaseRepository.executeOnlineFirst for consistent error handling
  /// - Automatically converts exceptions to appropriate Failure types
  /// - Logs all operations for debugging and monitoring
  ///
  /// **Validates**: Requirements 2.4
  @override
  Future<Either<Failure, bool>> notifyUsers({
    required List<String> receiverIds,
    required String title,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.d(
          'Sending push notification to ${receiverIds.length} users: $title',
        );

        final result = await _remoteDataSource.notifyUsers(
          receiverIds: receiverIds,
          title: title,
          content: content,
          metadata: metadata,
        );

        if (result) {
          logger.i(
            'Successfully sent push notification to ${receiverIds.length} users',
          );
        } else {
          logger.w(
            'Push notification returned false for ${receiverIds.length} users',
          );
        }

        return result;
      },
      localDataSource: () async {
        // No local fallback for push notifications - they require server
        logger.w('Push notification requires internet connection');
        return false;
      },
      operationName: 'notifyUsers',
    );
  }
}
