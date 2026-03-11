part of 'chat_draft_bloc.dart';

abstract class ChatDraftEvent extends Equatable {
  const ChatDraftEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class ChatDraftWatchRequested extends ChatDraftEvent {
  const ChatDraftWatchRequested();
}

class ChatDraftWatchUpdated extends ChatDraftEvent {
  const ChatDraftWatchUpdated(this.draftsByConversationId);

  final Map<String, ChatDraftEntity> draftsByConversationId;

  @override
  List<Object?> get props => <Object?>[draftsByConversationId];
}

class ChatDraftConversationOpened extends ChatDraftEvent {
  const ChatDraftConversationOpened({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => <Object?>[conversationId];
}

class ChatDraftRestoreHandled extends ChatDraftEvent {
  const ChatDraftRestoreHandled({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => <Object?>[conversationId];
}

class ChatDraftInputChanged extends ChatDraftEvent {
  const ChatDraftInputChanged({
    required this.conversationId,
    required this.text,
    required this.mentionNameById,
    required this.isEditMode,
    required this.isRecordingVoice,
    this.contentDelta,
  });

  final String conversationId;
  final String text;
  final Map<String, String> mentionNameById;
  final bool isEditMode;
  final bool isRecordingVoice;

  /// Quill Delta JSON string for rich text draft content.
  final String? contentDelta;

  @override
  List<Object?> get props => <Object?>[
        conversationId,
        text,
        mentionNameById,
        isEditMode,
        isRecordingVoice,
        contentDelta,
      ];
}

class ChatDraftPersistNowRequested extends ChatDraftEvent {
  const ChatDraftPersistNowRequested({
    required this.conversationId,
    required this.text,
    required this.mentionNameById,
    required this.isEditMode,
    required this.isRecordingVoice,
    this.contentDelta,
  });

  final String conversationId;
  final String text;
  final Map<String, String> mentionNameById;
  final bool isEditMode;
  final bool isRecordingVoice;

  /// Quill Delta JSON string for rich text draft content.
  final String? contentDelta;

  @override
  List<Object?> get props => <Object?>[
        conversationId,
        text,
        mentionNameById,
        isEditMode,
        isRecordingVoice,
        contentDelta,
      ];
}

class ChatDraftClearRequested extends ChatDraftEvent {
  const ChatDraftClearRequested({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => <Object?>[conversationId];
}

class ChatDraftMessageQueued extends ChatDraftEvent {
  const ChatDraftMessageQueued({
    required this.conversationId,
    required this.content,
    required this.queuedAt,
  });

  final String conversationId;
  final String content;
  final DateTime queuedAt;

  @override
  List<Object?> get props => <Object?>[conversationId, content, queuedAt];
}

class ChatDraftMessageDeliveryChecked extends ChatDraftEvent {
  const ChatDraftMessageDeliveryChecked({
    required this.conversationId,
    required this.currentUserId,
    required this.currentInputText,
    required this.messages,
  });

  final String conversationId;
  final String currentUserId;
  final String currentInputText;
  final List<ChatMessage> messages;

  @override
  List<Object?> get props => <Object?>[
        conversationId,
        currentUserId,
        currentInputText,
        messages,
      ];
}

class ChatDraftFlushRequested extends ChatDraftEvent {
  const ChatDraftFlushRequested({
    required this.conversationId,
    required this.text,
    required this.mentionNameById,
    required this.isEditMode,
    required this.isRecordingVoice,
    this.contentDelta,
  });

  final String conversationId;
  final String text;
  final Map<String, String> mentionNameById;
  final bool isEditMode;
  final bool isRecordingVoice;

  /// Quill Delta JSON string for rich text draft content.
  final String? contentDelta;

  @override
  List<Object?> get props => <Object?>[
        conversationId,
        text,
        mentionNameById,
        isEditMode,
        isRecordingVoice,
        contentDelta,
      ];
}

class ChatDraftErrorCleared extends ChatDraftEvent {
  const ChatDraftErrorCleared();
}
