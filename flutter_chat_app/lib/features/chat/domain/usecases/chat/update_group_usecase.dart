/// Update Group Use Case
///
/// Updates group conversation information (name, image, etc.).
/// Validates input and handles update logic.
///
/// Author: Senior Flutter/Mobile Architect
library update_group_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
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
class UpdateGroupUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const UpdateGroupUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  Future<Either<Failure, Chat>> call(UpdateGroupParams params) async {
    _logger.info('UpdateGroupUseCase: Starting operation', {
      'conversationId': params.conversationId,
      'hasName': params.name != null,
      'hasImageUrl': params.imageUrl != null,
      'hasDescription': params.description != null,
    });

    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      _logger.error('UpdateGroupUseCase: Validation failed', validationResult);
      return Left(validationResult);
    }

    // Update group through repository
    final result = await _repository.updateChat(
      chatId: params.conversationId,
      name: params.name,
      avatarUrl: params.imageUrl,
    );

    // Convert Either to Either
    return result.fold(
      (failure) {
        _logger.error('UpdateGroupUseCase: Failed', failure);
        return Left(failure);
      },
      (chat) {
        _logger.info('UpdateGroupUseCase: Success', {
          'conversationId': params.conversationId,
        });
        return Right(chat);
      },
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
