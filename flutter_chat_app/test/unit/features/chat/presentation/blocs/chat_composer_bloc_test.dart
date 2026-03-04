import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat_composer/chat_composer_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatComposerBloc send flow', () {
    blocTest<ChatComposerBloc, ChatComposerState>(
      'emits empty warning when user sends blank input',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerSendRequested(
            rawInput: '   ',
            actorDisplayName: 'Alice',
            isEditMode: false,
            editingMessageId: null,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerShowWarningEffect(
            ChatComposerWarning.emptyMessage,
          ),
        ),
      ],
    );

    blocTest<ChatComposerBloc, ChatComposerState>(
      'emits send text effect for normal message',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerSendRequested(
            rawInput: 'hello world',
            actorDisplayName: 'Alice',
            isEditMode: false,
            editingMessageId: null,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerSendTextEffect('hello world'),
        ),
      ],
    );

    blocTest<ChatComposerBloc, ChatComposerState>(
      'maps /me command into send effect with actor name',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerSendRequested(
            rawInput: '/me is typing',
            actorDisplayName: 'Alice',
            isEditMode: false,
            editingMessageId: null,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerSendTextEffect('* Alice is typing'),
        ),
      ],
    );

    blocTest<ChatComposerBloc, ChatComposerState>(
      'maps /mute into mute action effect',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerSendRequested(
            rawInput: '/mute',
            actorDisplayName: 'Alice',
            isEditMode: false,
            editingMessageId: null,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerMuteActionEffect(),
        ),
      ],
    );

    blocTest<ChatComposerBloc, ChatComposerState>(
      'emits unknown warning for unsupported slash command',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerSendRequested(
            rawInput: '/unknown',
            actorDisplayName: 'Alice',
            isEditMode: false,
            editingMessageId: null,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerShowWarningEffect(
            ChatComposerWarning.unknownSlashCommand,
          ),
        ),
      ],
    );
  });

  group('ChatComposerBloc shortcut flow', () {
    blocTest<ChatComposerBloc, ChatComposerState>(
      'maps escape shortcut to exit selection first',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerDismissShortcutRequested(
            isSelectionMode: true,
            isEditMode: true,
            hasReply: true,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerDismissEffect(
            ChatComposerDismissAction.exitSelection,
          ),
        ),
      ],
    );

    blocTest<ChatComposerBloc, ChatComposerState>(
      'maps escape shortcut to cancel edit when not selecting',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerDismissShortcutRequested(
            isSelectionMode: false,
            isEditMode: true,
            hasReply: true,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerDismissEffect(
            ChatComposerDismissAction.cancelEditAndClear,
          ),
        ),
      ],
    );

    blocTest<ChatComposerBloc, ChatComposerState>(
      'maps escape shortcut to cancel reply when not selecting or editing',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerDismissShortcutRequested(
            isSelectionMode: false,
            isEditMode: false,
            hasReply: true,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerDismissEffect(
            ChatComposerDismissAction.cancelReply,
          ),
        ),
      ],
    );

    blocTest<ChatComposerBloc, ChatComposerState>(
      'maps escape shortcut to no-op when nothing is active',
      build: ChatComposerBloc.new,
      act: (bloc) {
        bloc.add(
          const ChatComposerDismissShortcutRequested(
            isSelectionMode: false,
            isEditMode: false,
            hasReply: false,
          ),
        );
      },
      expect: () => const <ChatComposerState>[
        ChatComposerState(
          effect: ChatComposerDismissEffect(
            ChatComposerDismissAction.none,
          ),
        ),
      ],
    );
  });

  blocTest<ChatComposerBloc, ChatComposerState>(
    'clears one-shot effect after consume event',
    build: ChatComposerBloc.new,
    act: (bloc) {
      bloc
        ..add(
          const ChatComposerSendRequested(
            rawInput: 'hello',
            actorDisplayName: 'Alice',
            isEditMode: false,
            editingMessageId: null,
          ),
        )
        ..add(const ChatComposerEffectConsumed());
    },
    expect: () => const <ChatComposerState>[
      ChatComposerState(
        effect: ChatComposerSendTextEffect('hello'),
      ),
      ChatComposerState(),
    ],
  );
}
