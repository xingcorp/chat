/// Get Conversations Use Case
///
/// Retrieves list of conversations for the current user.
/// Implements offline-first strategy through repository.
///
/// Author: Senior Flutter/Mobile Architect
library get_conversations_usecase;

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Get conversations use case implementation
///
/// Retrieves all conversations for the current user with offline-first support.
/// Returns cached data immediately and syncs with server in background.
@injectable
class GetConversationsUseCase implements NoParamsUseCase<List<Chat>> {
  final IChatRepository _repository;

  const GetConversationsUseCase(this._repository);

  @override
  Future<Result<List<Chat>>> call() async {
    // Get conversations from repository (offline-first)
    final result = await _repository.getChats();

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (conversations) => Result.success(conversations),
    );
  }
}
