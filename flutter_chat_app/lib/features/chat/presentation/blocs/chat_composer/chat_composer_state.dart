part of 'chat_composer_bloc.dart';

const _chatComposerUnset = Object();

class ChatComposerState extends Equatable {
  const ChatComposerState({this.effect});

  factory ChatComposerState.initial() => const ChatComposerState();

  final ChatComposerEffect? effect;

  ChatComposerState copyWith({Object? effect = _chatComposerUnset}) {
    return ChatComposerState(
      effect: effect == _chatComposerUnset
          ? this.effect
          : effect as ChatComposerEffect?,
    );
  }

  @override
  List<Object?> get props => <Object?>[effect];
}

enum ChatComposerWarning {
  emptyMessage,
  unknownSlashCommand,
  missingSlashArgument,
}

enum ChatComposerDismissAction {
  none,
  exitSelection,
  cancelEditAndClear,
  cancelReply,
}

abstract class ChatComposerEffect extends Equatable {
  const ChatComposerEffect();

  @override
  List<Object?> get props => const <Object?>[];
}

class ChatComposerShowWarningEffect extends ChatComposerEffect {
  const ChatComposerShowWarningEffect(this.warning);

  final ChatComposerWarning warning;

  @override
  List<Object?> get props => <Object?>[warning];
}

class ChatComposerSendTextEffect extends ChatComposerEffect {
  const ChatComposerSendTextEffect(this.text, {this.contentDelta});

  final String text;

  /// Quill Delta JSON string. Null for plain text messages.
  final String? contentDelta;

  @override
  List<Object?> get props => <Object?>[text, contentDelta];
}

class ChatComposerEditTextEffect extends ChatComposerEffect {
  const ChatComposerEditTextEffect({
    required this.messageId,
    required this.text,
    this.contentDelta,
  });

  final String messageId;
  final String text;

  /// Quill Delta JSON string. Null for plain text messages.
  final String? contentDelta;

  @override
  List<Object?> get props => <Object?>[messageId, text, contentDelta];
}

class ChatComposerMuteActionEffect extends ChatComposerEffect {
  const ChatComposerMuteActionEffect();
}

class ChatComposerDismissEffect extends ChatComposerEffect {
  const ChatComposerDismissEffect(this.action);

  final ChatComposerDismissAction action;

  @override
  List<Object?> get props => <Object?>[action];
}
