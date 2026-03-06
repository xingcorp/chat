import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Create Group Use Case
///
/// Creates a new group conversation with specified members.
/// Implements remote-only strategy for server confirmation.
///
/// **Requirements**: 2.3, 2.16, 2.17, 2.18
@injectable
class CreateGroupUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const CreateGroupUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to create a group
  ///
  /// [name] - Group name
  /// [memberIds] - List of user IDs to add as members
  /// [avatar] - Optional group avatar URL
  /// [description] - Optional group description
  ///
  /// Returns Either<Failure, Chat>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: Created Chat entity
  Future<Either<Failure, Chat>> call({
    required String name,
    required List<String> memberIds,
    String? avatar,
    String? description,
    GroupType groupType = GroupType.private,
  }) async {
    _logger.info('CreateGroupUseCase: Starting operation', {
      'name': name,
      'memberCount': memberIds.length,
    });

    // Validate inputs
    if (name.trim().isEmpty) {
      _logger.error('CreateGroupUseCase: Validation failed - empty name');
      return const Left(
          ValidationFailure(message: 'Group name cannot be empty'));
    }

    if (memberIds.isEmpty) {
      _logger.error('CreateGroupUseCase: Validation failed - no members');
      return const Left(
          ValidationFailure(message: 'Group must have at least one member'));
    }

    try {
      final result = await _repository.createChat(
        name: name,
        participantIds: memberIds,
        avatarUrl: avatar,
        description: description,
        groupType: groupType,
        isGroup: true,
      );

      return result.fold(
        (failure) {
          _logger.error('CreateGroupUseCase: Failed', failure);
          return Left(failure);
        },
        (chat) {
          _logger.info('CreateGroupUseCase: Success', {
            'chatId': chat.id,
            'name': chat.name,
          });
          return Right(chat);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('CreateGroupUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
