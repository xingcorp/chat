/// Update Group Use Case
///
/// Updates group conversation information (name, image, etc.).
/// Validates input and handles update logic.
///
/// Author: Senior Flutter/Mobile Architect
library update_group_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for updating a group
class UpdateGroupParams extends Equatable {
  final String conversationId;
  final String? name;
  final String? imageUrl;
  final String? description;

  const UpdateGroupParams({
    required this.conversationId,
    this.name,
    this.imageUrl,
    this.description,
  });

  @override
  List<Object?> get props => [conversationId, name, imageUrl, description];
}

/// Update group use case implementation
///
/// Updates group conversation information with validation.
/// At least one field must be provided for update.
@injectable
class UpdateGroupUseCase implements UseCase<Chat, UpdateGroupParams> {
  final IChatRepository _repository;

  const UpdateGroupUseCase(this._repository);

  @override
  Future<Result<Chat>> call(UpdateGroupParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Update group through repository
    final result = await _repository.updateChat(
      chatId: params.conversationId,
      name: params.name,
      avatarUrl: params.imageUrl,
    );

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (chat) => Result.success(chat),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(UpdateGroupParams params) {
    final errors = <String>[];

    // Conversation ID validation
    if (params.conversationId.isEmpty) {
      errors.add('Conversation ID cannot be empty');
    }

    // At least one field must be provided
    if (params.name == null && 
        params.imageUrl == null && 
        params.description == null) {
      errors.add('At least one field must be provided for update');
    }

    // Name validation (if provided)
    if (params.name != null) {
      if (params.name!.isEmpty) {
        errors.add('Group name cannot be empty');
      } else if (params.name!.length < 3) {
        errors.add('Group name must be at least 3 characters');
      } else if (params.name!.length > 100) {
        errors.add('Group name must not exceed 100 characters');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(message: errors.join(', '));
    }

    return null;
  }
}
