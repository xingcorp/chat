part of 'chat_draft_bloc.dart';

const _chatDraftUnset = Object();

class ChatDraftState extends Equatable {
  const ChatDraftState({
    this.draftsByConversationId = const <String, ChatDraftEntity>{},
    this.restoreConversationId,
    this.restoreDraft,
    this.isRestoreLoading = false,
    this.errorMessage,
  });

  factory ChatDraftState.initial() => const ChatDraftState();

  final Map<String, ChatDraftEntity> draftsByConversationId;
  final String? restoreConversationId;
  final ChatDraftEntity? restoreDraft;
  final bool isRestoreLoading;
  final String? errorMessage;

  ChatDraftState copyWith({
    Map<String, ChatDraftEntity>? draftsByConversationId,
    Object? restoreConversationId = _chatDraftUnset,
    Object? restoreDraft = _chatDraftUnset,
    bool? isRestoreLoading,
    Object? errorMessage = _chatDraftUnset,
  }) {
    return ChatDraftState(
      draftsByConversationId:
          draftsByConversationId ?? this.draftsByConversationId,
      restoreConversationId: restoreConversationId == _chatDraftUnset
          ? this.restoreConversationId
          : restoreConversationId as String?,
      restoreDraft: restoreDraft == _chatDraftUnset
          ? this.restoreDraft
          : restoreDraft as ChatDraftEntity?,
      isRestoreLoading: isRestoreLoading ?? this.isRestoreLoading,
      errorMessage: errorMessage == _chatDraftUnset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        draftsByConversationId,
        restoreConversationId,
        restoreDraft,
        isRestoreLoading,
        errorMessage,
      ];
}
