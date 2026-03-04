import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_draft_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class WatchChatDraftsUseCase {
  const WatchChatDraftsUseCase(this._repository);

  final IDraftRepository _repository;

  Stream<Map<String, ChatDraftEntity>> call() {
    return _repository.watchAllDrafts();
  }
}
