import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_draft_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetAllChatDraftsUseCase {
  const GetAllChatDraftsUseCase(this._repository);

  final IDraftRepository _repository;

  Future<Either<Failure, Map<String, ChatDraftEntity>>> call() {
    return _repository.getAllDrafts();
  }
}
