import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/get_chat_draft_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/remove_chat_draft_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/save_chat_draft_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/watch_chat_drafts_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:injectable/injectable.dart';

part 'chat_draft_event.dart';
part 'chat_draft_state.dart';

class _PendingDraftClear {
  const _PendingDraftClear({
    required this.content,
    required this.queuedAt,
  });

  final String content;
  final DateTime queuedAt;
}

@injectable
class ChatDraftBloc extends Bloc<ChatDraftEvent, ChatDraftState> {
  ChatDraftBloc({
    required WatchChatDraftsUseCase watchChatDrafts,
    required GetChatDraftUseCase getChatDraft,
    required SaveChatDraftUseCase saveChatDraft,
    required RemoveChatDraftUseCase removeChatDraft,
    required AppLogger logger,
  })  : _watchChatDrafts = watchChatDrafts,
        _getChatDraft = getChatDraft,
        _saveChatDraft = saveChatDraft,
        _removeChatDraft = removeChatDraft,
        _logger = logger,
        super(ChatDraftState.initial()) {
    on<ChatDraftWatchRequested>(_onWatchRequested);
    on<ChatDraftWatchUpdated>(_onWatchUpdated);
    on<ChatDraftConversationOpened>(_onConversationOpened);
    on<ChatDraftRestoreHandled>(_onRestoreHandled);
    on<ChatDraftInputChanged>(_onInputChanged);
    on<ChatDraftPersistNowRequested>(_onPersistNowRequested);
    on<ChatDraftClearRequested>(_onClearRequested);
    on<ChatDraftMessageQueued>(_onMessageQueued);
    on<ChatDraftMessageDeliveryChecked>(_onMessageDeliveryChecked);
    on<ChatDraftFlushRequested>(_onFlushRequested);
    on<ChatDraftErrorCleared>(_onErrorCleared);

    add(const ChatDraftWatchRequested());
  }

  final WatchChatDraftsUseCase _watchChatDrafts;
  final GetChatDraftUseCase _getChatDraft;
  final SaveChatDraftUseCase _saveChatDraft;
  final RemoveChatDraftUseCase _removeChatDraft;
  final AppLogger _logger;

  StreamSubscription<Map<String, ChatDraftEntity>>? _draftsSubscription;

  final Map<String, Timer> _persistDebounceTimers = <String, Timer>{};
  final Map<String, String> _lastPersistedTextByConversationId =
      <String, String>{};
  final Map<String, Map<String, String>>
      _lastPersistedMentionNameByIdByConversationId =
      <String, Map<String, String>>{};
  final Map<String, String?> _lastPersistedContentDeltaByConversationId =
      <String, String?>{};
  final Set<String> _restoringConversationIds = <String>{};
  final Set<String> _skipOneEmptyPersistConversationIds = <String>{};
  final Map<String, _PendingDraftClear> _pendingDraftClearByConversationId =
      <String, _PendingDraftClear>{};

  Future<void> _onWatchRequested(
    ChatDraftWatchRequested event,
    Emitter<ChatDraftState> emit,
  ) async {
    await _draftsSubscription?.cancel();

    _draftsSubscription = _watchChatDrafts().listen(
      (draftsByConversationId) {
        add(ChatDraftWatchUpdated(draftsByConversationId));
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.w(
          'ChatDraftBloc watch stream error',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  void _onWatchUpdated(
    ChatDraftWatchUpdated event,
    Emitter<ChatDraftState> emit,
  ) {
    _lastPersistedTextByConversationId
      ..removeWhere((conversationId, _) =>
          !event.draftsByConversationId.containsKey(conversationId))
      ..addEntries(event.draftsByConversationId.entries.map(
        (entry) => MapEntry<String, String>(entry.key, entry.value.text),
      ));

    _lastPersistedMentionNameByIdByConversationId
      ..removeWhere((conversationId, _) =>
          !event.draftsByConversationId.containsKey(conversationId))
      ..addEntries(event.draftsByConversationId.entries.map(
        (entry) => MapEntry<String, Map<String, String>>(
          entry.key,
          Map<String, String>.from(entry.value.mentionNameById),
        ),
      ));

    _lastPersistedContentDeltaByConversationId
      ..removeWhere((conversationId, _) =>
          !event.draftsByConversationId.containsKey(conversationId))
      ..addEntries(event.draftsByConversationId.entries.map(
        (entry) => MapEntry<String, String?>(
          entry.key,
          entry.value.contentDelta,
        ),
      ));

    emit(state.copyWith(
      draftsByConversationId: event.draftsByConversationId,
      errorMessage: null,
    ));
  }

  Future<void> _onConversationOpened(
    ChatDraftConversationOpened event,
    Emitter<ChatDraftState> emit,
  ) async {
    final conversationId = event.conversationId.trim();
    if (conversationId.isEmpty) {
      return;
    }

    emit(state.copyWith(
      isRestoreLoading: true,
      restoreConversationId: null,
      restoreDraft: null,
      errorMessage: null,
    ));

    final result = await _getChatDraft(conversationId);
    result.fold(
      (failure) {
        _logger.w(
          'ChatDraftBloc failed to load draft for restore',
          context: <String, dynamic>{
            'conversationId': conversationId,
            'error': failure.message,
          },
        );

        emit(state.copyWith(
          isRestoreLoading: false,
          errorMessage: failure.userMessage,
        ));
      },
      (draft) {
        if (draft == null || !draft.hasContent) {
          emit(state.copyWith(
            isRestoreLoading: false,
            restoreConversationId: null,
            restoreDraft: null,
          ));
          return;
        }

        _restoringConversationIds.add(conversationId);
        _lastPersistedTextByConversationId[conversationId] = draft.text;
        _lastPersistedMentionNameByIdByConversationId[conversationId] =
            Map<String, String>.from(draft.mentionNameById);

        emit(state.copyWith(
          isRestoreLoading: false,
          restoreConversationId: conversationId,
          restoreDraft: draft,
        ));
      },
    );
  }

  void _onRestoreHandled(
    ChatDraftRestoreHandled event,
    Emitter<ChatDraftState> emit,
  ) {
    final conversationId = event.conversationId.trim();
    if (conversationId.isEmpty) {
      return;
    }

    _restoringConversationIds.remove(conversationId);

    if (state.restoreConversationId == conversationId) {
      emit(state.copyWith(
        restoreConversationId: null,
        restoreDraft: null,
      ));
    }
  }

  void _onInputChanged(
    ChatDraftInputChanged event,
    Emitter<ChatDraftState> emit,
  ) {
    final conversationId = event.conversationId.trim();
    if (conversationId.isEmpty) {
      return;
    }

    if (_restoringConversationIds.contains(conversationId) ||
        event.isEditMode ||
        event.isRecordingVoice) {
      return;
    }

    final normalizedText = event.text.replaceAll('\r\n', '\n');
    final normalizedMentionNameById = _normalizeMentions(event.mentionNameById);

    final currentDrafts =
        Map<String, ChatDraftEntity>.from(state.draftsByConversationId);
    final existingDraft = currentDrafts[conversationId];

    if (normalizedText.trim().isEmpty && event.contentDelta == null) {
      if (existingDraft != null) {
        currentDrafts.remove(conversationId);
        emit(state.copyWith(
          draftsByConversationId:
              Map<String, ChatDraftEntity>.unmodifiable(currentDrafts),
          errorMessage: null,
        ));
      }
    } else {
      final isSameAsCurrent = existingDraft != null &&
          existingDraft.text == normalizedText &&
          existingDraft.contentDelta == event.contentDelta &&
          mapEquals(existingDraft.mentionNameById, normalizedMentionNameById);

      if (!isSameAsCurrent) {
        currentDrafts[conversationId] = ChatDraftEntity(
          conversationId: conversationId,
          text: normalizedText,
          updatedAt: DateTime.now(),
          mentionNameById: normalizedMentionNameById,
          contentDelta: event.contentDelta,
        );
        emit(state.copyWith(
          draftsByConversationId:
              Map<String, ChatDraftEntity>.unmodifiable(currentDrafts),
          errorMessage: null,
        ));
      }
    }

    _schedulePersist(
      conversationId: conversationId,
      text: normalizedText,
      mentionNameById: normalizedMentionNameById,
      isEditMode: event.isEditMode,
      isRecordingVoice: event.isRecordingVoice,
      contentDelta: event.contentDelta,
    );
  }

  Future<void> _onPersistNowRequested(
    ChatDraftPersistNowRequested event,
    Emitter<ChatDraftState> emit,
  ) async {
    final conversationId = event.conversationId.trim();
    if (conversationId.isEmpty) {
      return;
    }

    if (_restoringConversationIds.contains(conversationId) ||
        event.isEditMode ||
        event.isRecordingVoice) {
      return;
    }

    final normalizedText = event.text.replaceAll('\r\n', '\n');
    final normalizedMentionNameById = _normalizeMentions(event.mentionNameById);

    if (_skipOneEmptyPersistConversationIds.contains(conversationId) &&
        normalizedText.trim().isEmpty) {
      _skipOneEmptyPersistConversationIds.remove(conversationId);
      return;
    }

    final lastPersistedText =
        _lastPersistedTextByConversationId[conversationId] ?? '';
    final lastPersistedMentionNameById =
        _lastPersistedMentionNameByIdByConversationId[conversationId] ??
            const <String, String>{};
    final lastPersistedContentDelta =
        _lastPersistedContentDeltaByConversationId[conversationId];

    if (normalizedText == lastPersistedText &&
        event.contentDelta == lastPersistedContentDelta &&
        mapEquals(normalizedMentionNameById, lastPersistedMentionNameById)) {
      return;
    }

    _lastPersistedTextByConversationId[conversationId] = normalizedText;
    _lastPersistedMentionNameByIdByConversationId[conversationId] =
        Map<String, String>.from(normalizedMentionNameById);
    _lastPersistedContentDeltaByConversationId[conversationId] =
        event.contentDelta;

    final result = await _saveChatDraft(
      ChatDraftEntity(
        conversationId: conversationId,
        text: normalizedText,
        updatedAt: DateTime.now(),
        mentionNameById: normalizedMentionNameById,
        contentDelta: event.contentDelta,
      ),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.userMessage));
      },
      (_) {
        if (state.errorMessage != null) {
          emit(state.copyWith(errorMessage: null));
        }
      },
    );
  }

  Future<void> _onClearRequested(
    ChatDraftClearRequested event,
    Emitter<ChatDraftState> emit,
  ) async {
    final conversationId = event.conversationId.trim();
    if (conversationId.isEmpty) {
      return;
    }

    _skipOneEmptyPersistConversationIds.remove(conversationId);
    _pendingDraftClearByConversationId.remove(conversationId);
    _lastPersistedTextByConversationId[conversationId] = '';
    _lastPersistedMentionNameByIdByConversationId[conversationId] =
        const <String, String>{};
    _lastPersistedContentDeltaByConversationId.remove(conversationId);

    final result = await _removeChatDraft(conversationId);
    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.userMessage));
      },
      (_) {
        final currentDrafts =
            Map<String, ChatDraftEntity>.from(state.draftsByConversationId);
        final hadDraft = currentDrafts.remove(conversationId) != null;

        if (hadDraft || state.errorMessage != null) {
          emit(state.copyWith(
            draftsByConversationId:
                Map<String, ChatDraftEntity>.unmodifiable(currentDrafts),
            errorMessage: null,
          ));
        }
      },
    );
  }

  void _onMessageQueued(
    ChatDraftMessageQueued event,
    Emitter<ChatDraftState> emit,
  ) {
    final conversationId = event.conversationId.trim();
    final normalizedContent = event.content.trim();
    if (conversationId.isEmpty || normalizedContent.isEmpty) {
      return;
    }

    _pendingDraftClearByConversationId[conversationId] = _PendingDraftClear(
      content: normalizedContent,
      queuedAt: event.queuedAt,
    );
    _skipOneEmptyPersistConversationIds.add(conversationId);
  }

  void _onMessageDeliveryChecked(
    ChatDraftMessageDeliveryChecked event,
    Emitter<ChatDraftState> emit,
  ) {
    final conversationId = event.conversationId.trim();
    final pendingClear = _pendingDraftClearByConversationId[conversationId];

    if (conversationId.isEmpty || pendingClear == null) {
      return;
    }

    final normalizedPendingContent = pendingClear.content.trim();
    if (normalizedPendingContent.isEmpty) {
      _pendingDraftClearByConversationId.remove(conversationId);
      return;
    }

    final acknowledged = event.messages.any((message) {
      if (message.sender.id != event.currentUserId) {
        return false;
      }

      if (message.id.startsWith('draft_')) {
        return false;
      }

      if (message.createdAt.isBefore(
          pendingClear.queuedAt.subtract(const Duration(seconds: 5)))) {
        return false;
      }

      return message.content.trim() == normalizedPendingContent;
    });

    if (!acknowledged) {
      return;
    }

    _pendingDraftClearByConversationId.remove(conversationId);

    if (event.currentInputText.trim().isNotEmpty) {
      return;
    }

    add(ChatDraftClearRequested(conversationId: conversationId));
  }

  void _onFlushRequested(
    ChatDraftFlushRequested event,
    Emitter<ChatDraftState> emit,
  ) {
    final conversationId = event.conversationId.trim();
    if (conversationId.isEmpty) {
      return;
    }

    _persistDebounceTimers[conversationId]?.cancel();

    final hasPendingClear =
        _pendingDraftClearByConversationId.containsKey(conversationId);
    final hasCurrentInput = event.text.trim().isNotEmpty;
    if (hasPendingClear && !hasCurrentInput) {
      return;
    }

    add(ChatDraftPersistNowRequested(
      conversationId: conversationId,
      text: event.text,
      mentionNameById: event.mentionNameById,
      isEditMode: event.isEditMode,
      isRecordingVoice: event.isRecordingVoice,
      contentDelta: event.contentDelta,
    ));
  }

  void _onErrorCleared(
    ChatDraftErrorCleared event,
    Emitter<ChatDraftState> emit,
  ) {
    if (state.errorMessage != null) {
      emit(state.copyWith(errorMessage: null));
    }
  }

  void _schedulePersist({
    required String conversationId,
    required String text,
    required Map<String, String> mentionNameById,
    required bool isEditMode,
    required bool isRecordingVoice,
    String? contentDelta,
  }) {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return;
    }

    if (_restoringConversationIds.contains(normalizedConversationId) ||
        isEditMode ||
        isRecordingVoice) {
      return;
    }

    _persistDebounceTimers[normalizedConversationId]?.cancel();
    _persistDebounceTimers[normalizedConversationId] = Timer(
      const Duration(milliseconds: 400),
      () {
        if (isClosed) {
          return;
        }

        add(ChatDraftPersistNowRequested(
          conversationId: normalizedConversationId,
          text: text,
          mentionNameById: Map<String, String>.from(mentionNameById),
          isEditMode: isEditMode,
          isRecordingVoice: isRecordingVoice,
          contentDelta: contentDelta,
        ));
      },
    );
  }

  Map<String, String> _normalizeMentions(Map<String, String> mentions) {
    return <String, String>{
      for (final entry in mentions.entries)
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
          entry.key.trim(): entry.value.trim(),
    };
  }

  @override
  Future<void> close() async {
    await _draftsSubscription?.cancel();

    for (final timer in _persistDebounceTimers.values) {
      timer.cancel();
    }
    _persistDebounceTimers.clear();

    return super.close();
  }
}
