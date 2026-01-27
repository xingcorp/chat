/// Get Conversation Detail Use Case
///
/// Retrieves detailed information for a specific conversation.
/// Implements online-first strategy to get latest data.
///
/// Author: Senior Flutter/Mobile Architect
library get_conversation_detail_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for getting conversation detail
class GetConversationDetailParams extends Equatable {
  final String conversationId;

  const GetConversationDetailParams({
    required this.conversationId,
  });

  @override
  List<Object> get props => [conversationId];
}

/// Get conversation detail use case implementation
///
/// Retrieves detailed information for a specific conversation.
/// Uses online-first strategy to ensure fresh data.
@injectable
class GetConversationDetailUseCase 
    implements UseCase<Chat?, GetConversationDetailParams> {
  final IChatRepository _repository;

  const GetConversationDetailUseCase(this._repository);

  @override
  Future<Result<Chat?>> call(GetConversationDetailParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Get conversation detail from repository
    final result = await _repository.getChatById(params.conversationId);

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (conversation) => Result.success(conversation),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(GetConversationDetailParams params) {
    if (params.conversationId.isEmpty) {
      return const ValidationFailure(
        message: 'Conversation ID cannot be empty',
      );
    }
    return null;
  }
}
