import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/models/chat_draft_model.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/draft/draft_local_datasource.dart';
import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_draft_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IDraftRepository)
class DraftRepositoryImpl implements IDraftRepository {
  DraftRepositoryImpl({
    required DraftLocalDataSource localDataSource,
    required AppLogger logger,
  })  : _localDataSource = localDataSource,
        _logger = logger;

  final DraftLocalDataSource _localDataSource;
  final AppLogger _logger;

  @override
  Future<Either<Failure, ChatDraftEntity?>> getDraft(
    String conversationId,
  ) async {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Right<Failure, ChatDraftEntity?>(null);
    }

    try {
      final model = await _localDataSource.getDraft(normalizedConversationId);
      final draft = model?.toEntity();
      if (draft == null || !draft.hasContent) {
        return const Right<Failure, ChatDraftEntity?>(null);
      }

      return Right<Failure, ChatDraftEntity>(draft);
    } catch (error, stackTrace) {
      _logger.w(
        'DraftRepositoryImpl.getDraft failed',
        error: error,
        stackTrace: stackTrace,
        context: <String, dynamic>{
          'conversationId': normalizedConversationId,
        },
      );
      return const Left<Failure, ChatDraftEntity?>(
        CacheFailure(message: 'Failed to load draft'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, ChatDraftEntity>>> getAllDrafts() async {
    try {
      final models = await _localDataSource.getAllDrafts();
      return Right<Failure, Map<String, ChatDraftEntity>>(
        _mapDraftsByConversation(models),
      );
    } catch (error, stackTrace) {
      _logger.w(
        'DraftRepositoryImpl.getAllDrafts failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left<Failure, Map<String, ChatDraftEntity>>(
        CacheFailure(message: 'Failed to load drafts'),
      );
    }
  }

  @override
  Stream<Map<String, ChatDraftEntity>> watchAllDrafts() {
    return _localDataSource
        .watchAllDrafts()
        .map(_mapDraftsByConversation)
        .handleError(
      (Object error, StackTrace stackTrace) {
        _logger.w(
          'DraftRepositoryImpl.watchAllDrafts stream error',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  @override
  Future<Either<Failure, void>> saveDraft(ChatDraftEntity draft) async {
    final normalizedConversationId = draft.conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Left<Failure, void>(
        ValidationFailure(message: 'conversationId cannot be empty'),
      );
    }

    final normalizedText = draft.text.replaceAll('\r\n', '\n');
    if (normalizedText.trim().isEmpty) {
      return removeDraft(normalizedConversationId);
    }

    final normalizedMentions = <String, String>{
      for (final entry in draft.mentionNameById.entries)
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
          entry.key.trim(): entry.value.trim(),
    };

    final normalizedDraft = ChatDraftEntity(
      conversationId: normalizedConversationId,
      text: normalizedText,
      updatedAt: DateTime.now(),
      mentionNameById: normalizedMentions,
    );

    try {
      await _localDataSource
          .saveDraft(ChatDraftModel.fromEntity(normalizedDraft));
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      _logger.w(
        'DraftRepositoryImpl.saveDraft failed',
        error: error,
        stackTrace: stackTrace,
        context: <String, dynamic>{
          'conversationId': normalizedConversationId,
        },
      );
      return const Left<Failure, void>(
        CacheFailure(message: 'Failed to save draft'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> removeDraft(String conversationId) async {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Right<Failure, void>(null);
    }

    try {
      await _localDataSource.removeDraft(normalizedConversationId);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      _logger.w(
        'DraftRepositoryImpl.removeDraft failed',
        error: error,
        stackTrace: stackTrace,
        context: <String, dynamic>{
          'conversationId': normalizedConversationId,
        },
      );
      return const Left<Failure, void>(
        CacheFailure(message: 'Failed to remove draft'),
      );
    }
  }

  Map<String, ChatDraftEntity> _mapDraftsByConversation(
    List<ChatDraftModel> models,
  ) {
    final draftsByConversation = <String, ChatDraftEntity>{};

    for (final model in models) {
      final entity = model.toEntity();
      if (!entity.hasContent) {
        continue;
      }

      final conversationId = entity.conversationId.trim();
      if (conversationId.isEmpty) {
        continue;
      }

      draftsByConversation[conversationId] = entity;
    }

    return Map<String, ChatDraftEntity>.unmodifiable(draftsByConversation);
  }
}
