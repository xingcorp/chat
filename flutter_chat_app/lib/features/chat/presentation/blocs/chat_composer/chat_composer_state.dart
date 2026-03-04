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
  const ChatComposerSendTextEffect(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

class ChatComposerEditTextEffect extends ChatComposerEffect {
  const ChatComposerEditTextEffect({
    required this.messageId,
    required this.text,
  });

  final String messageId;
  final String text;

  @override
  List<Object?> get props => <Object?>[messageId, text];
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
