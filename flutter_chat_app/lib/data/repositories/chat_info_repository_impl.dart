import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';
import 'package:flutter_chat_app/data/datasources/chat_info/chat_info_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/chat_info/notification_settings_model.dart';

/// Implementation của IChatInfoRepository
/// Tuân thủ Clean Architecture - chuyển đổi giữa Data layer và Domain layer
@LazySingleton(as: IChatInfoRepository)
class ChatInfoRepositoryImpl implements IChatInfoRepository {
  final IChatInfoRemoteDataSource _remoteDataSource;
  final AppLogger _logger;

  ChatInfoRepositoryImpl({
    required IChatInfoRemoteDataSource remoteDataSource,
    required AppLogger logger,
  })  : _remoteDataSource = remoteDataSource,
        _logger = logger;

  @override
  Future<Either<Failure, List<SharedMedia>>> getSharedMedia({
    required String chatId,
    required SharedMediaType type,
    int? limit,
    int? offset,
  }) async {
    try {
      _logger.d('Getting shared media for chat: $chatId, type: $type');

      final models = await _remoteDataSource.getSharedMedia(
        chatId: chatId,
        type: type.name,
        limit: limit,
        offset: offset,
      );

      final entities = models.map((m) => m.toEntity()).toList();

      _logger.i('Successfully loaded ${entities.length} media items');

      return Right(entities);
    } on ServerException catch (e) {
      _logger.e('Server error getting shared media', error: e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error getting shared media', error: e);
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error getting shared media',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> getNotificationSettings({
    required String chatId,
  }) async {
    try {
      _logger.d('Getting notification settings for chat: $chatId');

      final model = await _remoteDataSource.getNotificationSettings(
        chatId: chatId,
      );

      _logger.i('Successfully loaded notification settings');

      return Right(model.toEntity());
    } on ServerException catch (e) {
      _logger.e('Server error getting notification settings', error: e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error getting notification settings', error: e);
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error getting notification settings',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings({
    required String chatId,
    required NotificationSettings settings,
  }) async {
    try {
      _logger.d('Updating notification settings for chat: $chatId');

      final model = await _remoteDataSource.updateNotificationSettings(
        chatId: chatId,
        settings: NotificationSettingsModel.fromEntity(settings).toJson(),
      );

      _logger.i('Successfully updated notification settings');

      return Right(model.toEntity());
    } on ServerException catch (e) {
      _logger.e('Server error updating notification settings', error: e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error updating notification settings', error: e);
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error updating notification settings',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser({required String userId}) async {
    try {
      _logger.d('Blocking user: $userId');

      await _remoteDataSource.blockUser(userId: userId);

      _logger.i('Successfully blocked user: $userId');

      return const Right(null);
    } on ServerException catch (e) {
      _logger.e('Server error blocking user', error: e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error blocking user', error: e);
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e('Unexpected error blocking user', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unblockUser({required String userId}) async {
    try {
      _logger.d('Unblocking user: $userId');

      await _remoteDataSource.unblockUser(userId: userId);

      _logger.i('Successfully unblocked user: $userId');

      return const Right(null);
    } on ServerException catch (e) {
      _logger.e('Server error unblocking user', error: e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error unblocking user', error: e);
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error unblocking user',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserBlocked({required String userId}) async {
    try {
      _logger.d('Checking if user is blocked: $userId');

      final isBlocked = await _remoteDataSource.isUserBlocked(userId: userId);

      return Right(isBlocked);
    } on ServerException catch (e) {
      _logger.e('Server error checking block status', error: e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error checking block status', error: e);
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error checking block status',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reportChat({
    required String chatId,
    required String reason,
  }) async {
    try {
      _logger.d('Reporting chat: $chatId, reason: $reason');

      await _remoteDataSource.reportChat(chatId: chatId, reason: reason);

      _logger.i('Successfully reported chat: $chatId');

      return const Right(null);
    } on ServerException catch (e) {
      _logger.e('Server error reporting chat', error: e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error reporting chat', error: e);
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      _logger.e('Unexpected error reporting chat', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }
}
