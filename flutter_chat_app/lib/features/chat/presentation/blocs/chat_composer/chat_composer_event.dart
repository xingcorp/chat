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
  });

  final String rawInput;
  final String actorDisplayName;
  final bool isEditMode;
  final String? editingMessageId;

  @override
  List<Object?> get props => <Object?>[
        rawInput,
        actorDisplayName,
        isEditMode,
        editingMessageId,
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
