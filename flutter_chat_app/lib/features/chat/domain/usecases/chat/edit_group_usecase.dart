import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

class EditGroupParams extends Equatable {
  final String conversationId;
  final String? name;
  final String? avatarUrl;
  final String? description;
  final GroupType? groupType;
  final List<String>? memberIds;
  final List<String>? adminIds;

  const EditGroupParams({
    required this.conversationId,
    this.name,
    this.avatarUrl,
    this.description,
    this.groupType,
    this.memberIds,
    this.adminIds,
  });

  @override
  List<Object?> get props => [
        conversationId,
        name,
        avatarUrl,
        description,
        groupType,
        memberIds,
        adminIds,
      ];
}

@injectable
class EditGroupUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const EditGroupUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  Future<Either<Failure, Chat>> call(EditGroupParams params) async {
    _logger.info('EditGroupUseCase: Starting operation', {
      'conversationId': params.conversationId,
      'hasName': params.name != null,
      'hasAvatarUrl': params.avatarUrl != null,
      'hasDescription': params.description != null,
      'hasGroupType': params.groupType != null,
      'hasMemberIds': params.memberIds != null,
      'hasAdminIds': params.adminIds != null,
    });

    if (params.conversationId.trim().isEmpty) {
      _logger
          .error('EditGroupUseCase: Validation failed - empty conversationId');
      return const Left(
          ValidationFailure(message: 'Conversation ID cannot be empty'));
    }

    if (params.name == null &&
        params.avatarUrl == null &&
        params.description == null &&
        params.groupType == null &&
        params.memberIds == null &&
        params.adminIds == null) {
      _logger
          .error('EditGroupUseCase: Validation failed - no fields to update');
      return const Left(ValidationFailure(
          message: 'At least one field must be provided for update'));
    }

    final result = await _repository.updateChat(
      chatId: params.conversationId,
      name: params.name,
      avatarUrl: params.avatarUrl,
      description: params.description,
      groupType: params.groupType,
      memberIds: params.memberIds,
      adminIds: params.adminIds,
    );

    return result.fold(
      (failure) {
        _logger.error('EditGroupUseCase: Failed', failure);
        return Left(failure);
      },
      (chat) {
        _logger.info('EditGroupUseCase: Success', {
          'conversationId': params.conversationId,
        });
        return Right(chat);
      },
    );
  }
}
