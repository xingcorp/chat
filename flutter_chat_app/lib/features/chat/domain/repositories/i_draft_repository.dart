import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';

abstract class IDraftRepository {
  Future<Either<Failure, ChatDraftEntity?>> getDraft(String conversationId);

  Future<Either<Failure, Map<String, ChatDraftEntity>>> getAllDrafts();

  Stream<Map<String, ChatDraftEntity>> watchAllDrafts();

  Future<Either<Failure, void>> saveDraft(ChatDraftEntity draft);

  Future<Either<Failure, void>> removeDraft(String conversationId);
}
