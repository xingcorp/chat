import 'package:flutter_chat_app/core/utils/isar_id.dart';
import 'package:flutter_chat_app/data/models/chat_draft_model.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

abstract class DraftLocalDataSource {
  Future<ChatDraftModel?> getDraft(String conversationId);

  Future<List<ChatDraftModel>> getAllDrafts();

  Stream<List<ChatDraftModel>> watchAllDrafts();

  Future<void> saveDraft(ChatDraftModel draft);

  Future<void> removeDraft(String conversationId);
}

@LazySingleton(as: DraftLocalDataSource)
class DraftLocalDataSourceImpl implements DraftLocalDataSource {
  DraftLocalDataSourceImpl(this._isar);

  final Isar _isar;

  @override
  Future<ChatDraftModel?> getDraft(String conversationId) async {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return null;
    }

    return _isar.chatDraftModels.get(normalizedConversationId.toIsarId());
  }

  @override
  Future<List<ChatDraftModel>> getAllDrafts() async {
    return _isar.chatDraftModels.where().findAll();
  }

  @override
  Stream<List<ChatDraftModel>> watchAllDrafts() {
    return _isar.chatDraftModels.where().watch(fireImmediately: true);
  }

  @override
  Future<void> saveDraft(ChatDraftModel draft) async {
    _isar.write((isar) {
      isar.chatDraftModels.put(draft);
    });
  }

  @override
  Future<void> removeDraft(String conversationId) async {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return;
    }

    _isar.write((isar) {
      isar.chatDraftModels.delete(normalizedConversationId.toIsarId());
    });
  }
}
