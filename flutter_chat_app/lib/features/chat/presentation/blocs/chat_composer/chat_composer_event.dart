part of 'chat_composer_bloc.dart';

abstract class ChatComposerEvent extends Equatable {
  const ChatComposerEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class ChatComposerSendRequested extends ChatComposerEvent {
  const ChatComposerSendRequested({
    required this.rawInput,
    required this.actorDisplayName,
    required this.isEditMode,
    required this.editingMessageId,
    this.hasAttachments = false,
    this.contentDelta,
  });

  final String rawInput;
  final String actorDisplayName;
  final bool isEditMode;
  final String? editingMessageId;

  /// Whether there are file attachments ready to send.
  /// When true, allows sending even if rawInput is empty (file-only message).
  final bool hasAttachments;

  /// Quill Delta JSON string for rich text content.
  /// Null when the message is plain text only.
  final String? contentDelta;

  @override
  List<Object?> get props => <Object?>[
        rawInput,
        actorDisplayName,
        isEditMode,
        editingMessageId,
        hasAttachments,
        contentDelta,
      ];
}

class ChatComposerDismissShortcutRequested extends ChatComposerEvent {
  const ChatComposerDismissShortcutRequested({
    required this.isSelectionMode,
    required this.isEditMode,
    required this.hasReply,
  });

  final bool isSelectionMode;
  final bool isEditMode;
  final bool hasReply;

  @override
  List<Object?> get props => <Object?>[
        isSelectionMode,
        isEditMode,
        hasReply,
      ];
}

class ChatComposerEffectConsumed extends ChatComposerEvent {
  const ChatComposerEffectConsumed();
}
