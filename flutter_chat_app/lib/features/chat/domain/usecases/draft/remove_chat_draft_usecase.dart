import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_draft_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class RemoveChatDraftUseCase {
  const RemoveChatDraftUseCase(this._repository);

  final IDraftRepository _repository;

  Future<Either<Failure, void>> call(String conversationId) {
    return _repository.removeDraft(conversationId);
  }
}
