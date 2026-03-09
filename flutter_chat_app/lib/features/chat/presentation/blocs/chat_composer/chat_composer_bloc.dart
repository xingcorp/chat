import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'chat_composer_event.dart';
part 'chat_composer_state.dart';

@injectable
class ChatComposerBloc extends Bloc<ChatComposerEvent, ChatComposerState> {
  ChatComposerBloc()
      : _slashCommandEngine = const ChatSlashCommandEngine(),
        super(ChatComposerState.initial()) {
    on<ChatComposerSendRequested>(_onSendRequested);
    on<ChatComposerDismissShortcutRequested>(_onDismissShortcutRequested);
    on<ChatComposerEffectConsumed>(_onEffectConsumed);
  }

  final ChatSlashCommandEngine _slashCommandEngine;

  void _onSendRequested(
    ChatComposerSendRequested event,
    Emitter<ChatComposerState> emit,
  ) {
    final normalizedInput = event.rawInput.trim();

    // Allow empty text if there are file attachments to send
    if (normalizedInput.isEmpty && !event.hasAttachments) {
      emit(state.copyWith(
        effect: const ChatComposerShowWarningEffect(
            ChatComposerWarning.emptyMessage),
      ));
      return;
    }

    // File-only message (no text, but has attachments) — skip slash command
    // parsing and emit send effect directly with empty text
    if (normalizedInput.isEmpty && event.hasAttachments) {
      emit(state.copyWith(
          effect: const ChatComposerSendTextEffect('')));
      return;
    }

    if (event.isEditMode) {
      final editingMessageId = event.editingMessageId?.trim();
      if (editingMessageId == null || editingMessageId.isEmpty) {
        emit(state.copyWith(
          effect: const ChatComposerShowWarningEffect(
            ChatComposerWarning.emptyMessage,
          ),
        ));
        return;
      }

      emit(state.copyWith(
        effect: ChatComposerEditTextEffect(
          messageId: editingMessageId,
          text: normalizedInput,
        ),
      ));
      return;
    }

    final slashCommandResult = _slashCommandEngine.parse(
      input: normalizedInput,
      actorDisplayName: event.actorDisplayName,
    );

    switch (slashCommandResult.outcome) {
      case ChatSlashCommandOutcome.invalid:
        final warning = switch (slashCommandResult.validationError) {
          ChatSlashCommandValidationError.missingArgument =>
            ChatComposerWarning.missingSlashArgument,
          ChatSlashCommandValidationError.unknownCommand ||
          null =>
            ChatComposerWarning.unknownSlashCommand,
        };
        emit(state.copyWith(effect: ChatComposerShowWarningEffect(warning)));
        return;

      case ChatSlashCommandOutcome.muteAction:
        emit(state.copyWith(effect: const ChatComposerMuteActionEffect()));
        return;

      case ChatSlashCommandOutcome.sendMessage:
        final text = (slashCommandResult.messageText ?? '').trim();
        if (text.isEmpty) {
          emit(state.copyWith(
            effect: const ChatComposerShowWarningEffect(
              ChatComposerWarning.emptyMessage,
            ),
          ));
          return;
        }
        emit(state.copyWith(effect: ChatComposerSendTextEffect(text)));
        return;

      case ChatSlashCommandOutcome.none:
        emit(state.copyWith(
            effect: ChatComposerSendTextEffect(normalizedInput)));
        return;
    }
  }

  void _onDismissShortcutRequested(
    ChatComposerDismissShortcutRequested event,
    Emitter<ChatComposerState> emit,
  ) {
    final action = switch ((
      event.isSelectionMode,
      event.isEditMode,
      event.hasReply,
    )) {
      (true, _, _) => ChatComposerDismissAction.exitSelection,
      (false, true, _) => ChatComposerDismissAction.cancelEditAndClear,
      (false, false, true) => ChatComposerDismissAction.cancelReply,
      _ => ChatComposerDismissAction.none,
    };

    emit(state.copyWith(effect: ChatComposerDismissEffect(action)));
  }

  void _onEffectConsumed(
    ChatComposerEffectConsumed event,
    Emitter<ChatComposerState> emit,
  ) {
    if (state.effect != null) {
      emit(state.copyWith(effect: null));
    }
  }
}
