import 'package:flutter_chat_app/core/error/exceptions.dart' as app_exceptions;
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/presence/presence_remote_datasource.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/domain/repositories/i_presence_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IPresenceRepository)
class PresenceRepositoryImpl implements IPresenceRepository {
  PresenceRepositoryImpl(
    this._remoteDataSource,
    this._logger,
  );

  final PresenceRemoteDataSource _remoteDataSource;
  final AppLogger _logger;

  @override
  Future<Either<Failure, List<UserPresence>>> getUsersPresence(
    List<String> userIds,
  ) async {
    final normalizedIds = userIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIds.isEmpty) {
      return const Right<Failure, List<UserPresence>>(<UserPresence>[]);
    }

    try {
      final models = await _remoteDataSource.getUsersPresence(normalizedIds);
      final entities = models
          .map((model) => model.toEntity())
          .where((presence) => presence.userId.trim().isNotEmpty)
          .toList(growable: false);
      return Right<Failure, List<UserPresence>>(entities);
    } on app_exceptions.NoInternetException catch (error, stackTrace) {
      _logger.e(
        'Presence query failed: no internet',
        error: error,
        stackTrace: stackTrace,
      );
      return Left<Failure, List<UserPresence>>(
        ConnectionFailure(
          message: error.message,
          code: error.code ?? 'no_internet',
        ),
      );
    } on app_exceptions.TimeoutException catch (error, stackTrace) {
      _logger.e(
        'Presence query timed out',
        error: error,
        stackTrace: stackTrace,
      );
      return Left<Failure, List<UserPresence>>(
        TimeoutFailure(
          message: error.message,
          code: error.code ?? 'timeout',
        ),
      );
    } on app_exceptions.AppException catch (error, stackTrace) {
      _logger.e(
        'Presence query failed with app exception',
        error: error,
        stackTrace: stackTrace,
      );
      return Left<Failure, List<UserPresence>>(
        ServerFailure(
          message: error.message,
          code: error.code,
        ),
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Presence query failed with unknown error',
        error: error,
        stackTrace: stackTrace,
      );
      return Left<Failure, List<UserPresence>>(
        ServerFailure(message: 'Failed to fetch user presence: $error'),
      );
    }
  }
}
