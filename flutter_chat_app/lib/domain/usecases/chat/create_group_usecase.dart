/// Create Group Use Case
///
/// Creates a new group conversation with specified members.
/// Validates input and handles group creation logic.
///
/// Author: Senior Flutter/Mobile Architect
library create_group_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for creating a group
class CreateGroupParams extends Equatable {
  final String name;
  final List<String> memberIds;
  final String? description;
  final String? imageUrl;

  const CreateGroupParams({
    required this.name,
    required this.memberIds,
    this.description,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [name, memberIds, description, imageUrl];
}

/// Create group use case implementation
///
/// Creates a new group conversation with validation.
/// Ensures group has valid name and at least one member.
@injectable
class CreateGroupUseCase implements UseCase<Chat, CreateGroupParams> {
  final IChatRepository _repository;

  const CreateGroupUseCase(this._repository);

  @override
  Future<Result<Chat>> call(CreateGroupParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Create group through repository
    final result = await _repository.createChat(
      name: params.name,
      participantIds: params.memberIds,
      isGroup: true,
    );

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (chat) => Result.success(chat),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(CreateGroupParams params) {
    final errors = <String>[];

    // Name validation
    if (params.name.isEmpty) {
      errors.add('Group name cannot be empty');
    } else if (params.name.length < 3) {
      errors.add('Group name must be at least 3 characters');
    } else if (params.name.length > 100) {
      errors.add('Group name must not exceed 100 characters');
    }

    // Members validation
    if (params.memberIds.isEmpty) {
      errors.add('Group must have at least one member');
    } else if (params.memberIds.length > 256) {
      errors.add('Group cannot have more than 256 members');
    }

    // Check for duplicate member IDs
    if (params.memberIds.toSet().length != params.memberIds.length) {
      errors.add('Duplicate member IDs are not allowed');
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(message: errors.join(', '));
    }

    return null;
  }
}
