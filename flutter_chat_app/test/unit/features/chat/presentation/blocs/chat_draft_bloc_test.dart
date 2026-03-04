import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/get_chat_draft_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/remove_chat_draft_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/save_chat_draft_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/draft/watch_chat_drafts_usecase.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat_draft/chat_draft_bloc.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchChatDraftsUseCase extends Mock
    implements WatchChatDraftsUseCase {}

class _MockGetChatDraftUseCase extends Mock implements GetChatDraftUseCase {}

class _MockSaveChatDraftUseCase extends Mock implements SaveChatDraftUseCase {}

class _MockRemoveChatDraftUseCase extends Mock
    implements RemoveChatDraftUseCase {}

void main() {
  late _MockWatchChatDraftsUseCase watchChatDraftsUseCase;
  late _MockGetChatDraftUseCase getChatDraftUseCase;
  late _MockSaveChatDraftUseCase saveChatDraftUseCase;
  late _MockRemoveChatDraftUseCase removeChatDraftUseCase;
  late StreamController<Map<String, ChatDraftEntity>> draftsController;

  setUpAll(() {
    registerFallbackValue(
      ChatDraftEntity(
        conversationId: 'fallback',
        text: '',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  });

  setUp(() {
    watchChatDraftsUseCase = _MockWatchChatDraftsUseCase();
    getChatDraftUseCase = _MockGetChatDraftUseCase();
    saveChatDraftUseCase = _MockSaveChatDraftUseCase();
    removeChatDraftUseCase = _MockRemoveChatDraftUseCase();
    draftsController =
        StreamController<Map<String, ChatDraftEntity>>.broadcast();

    when(() => watchChatDraftsUseCase())
        .thenAnswer((_) => draftsController.stream);
    when(() => getChatDraftUseCase(any())).thenAnswer(
      (_) async => const Right<Failure, ChatDraftEntity?>(null),
    );
    when(() => saveChatDraftUseCase(any())).thenAnswer(
      (_) async => const Right<Failure, void>(null),
    );
    when(() => removeChatDraftUseCase(any())).thenAnswer(
      (_) async => const Right<Failure, void>(null),
    );
  });

  tearDown(() async {
    await draftsController.close();
  });

  ChatDraftBloc buildBloc() {
    return ChatDraftBloc(
      watchChatDrafts: watchChatDraftsUseCase,
      getChatDraft: getChatDraftUseCase,
      saveChatDraft: saveChatDraftUseCase,
      removeChatDraft: removeChatDraftUseCase,
      logger: AppLogger(),
    );
  }

  group('ChatDraftBloc restore and watch', () {
    blocTest<ChatDraftBloc, ChatDraftState>(
      'restores existing draft when opening conversation',
      build: () {
        final draft = ChatDraftEntity(
          conversationId: 'conversation-1',
          text: 'Hello draft',
          updatedAt: DateTime(2026, 3, 4, 9, 0, 0),
          mentionNameById: const <String, String>{'user-1': 'Alice'},
        );
        when(() => getChatDraftUseCase('conversation-1')).thenAnswer(
          (_) async => Right<Failure, ChatDraftEntity?>(draft),
        );
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(
          const ChatDraftConversationOpened(
            conversationId: 'conversation-1',
          ),
        );
      },
      expect: () => <ChatDraftState>[
        const ChatDraftState(isRestoreLoading: true),
        ChatDraftState(
          restoreConversationId: 'conversation-1',
          restoreDraft: ChatDraftEntity(
            conversationId: 'conversation-1',
            text: 'Hello draft',
            updatedAt: DateTime(2026, 3, 4, 9, 0, 0),
            mentionNameById: const <String, String>{'user-1': 'Alice'},
          ),
        ),
      ],
    );

    blocTest<ChatDraftBloc, ChatDraftState>(
      'updates draft map when watch stream emits',
      build: buildBloc,
      act: (bloc) async {
        await Future<void>.delayed(Duration.zero);
        draftsController.add(
          <String, ChatDraftEntity>{
            'conversation-1': ChatDraftEntity(
              conversationId: 'conversation-1',
              text: 'draft value',
              updatedAt: DateTime(2026, 3, 4, 10, 0, 0),
            ),
          },
        );
      },
      expect: () => <Matcher>[
        isA<ChatDraftState>().having(
          (state) => state.draftsByConversationId.containsKey('conversation-1'),
          'contains conversation draft',
          true,
        ),
      ],
    );
  });

  group('ChatDraftBloc persistence lifecycle', () {
    blocTest<ChatDraftBloc, ChatDraftState>(
      'persists input with debounce through save use case',
      build: buildBloc,
      act: (bloc) {
        bloc.add(
          const ChatDraftInputChanged(
            conversationId: 'conversation-1',
            text: 'Hello draft',
            mentionNameById: <String, String>{' user-1 ': ' Alice '},
            isEditMode: false,
            isRecordingVoice: false,
          ),
        );
      },
      wait: const Duration(milliseconds: 500),
      expect: () => <Matcher>[
        isA<ChatDraftState>()
            .having(
              (state) =>
                  state.draftsByConversationId.containsKey('conversation-1'),
              'contains draft for conversation',
              true,
            )
            .having(
              (state) => state.draftsByConversationId['conversation-1']?.text,
              'draft text',
              'Hello draft',
            ),
      ],
      verify: (_) {
        final verification = verify(() => saveChatDraftUseCase(captureAny()));
        verification.called(1);
        final savedDraft = verification.captured.single as ChatDraftEntity;

        expect(savedDraft.conversationId, 'conversation-1');
        expect(savedDraft.text, 'Hello draft');
        expect(
          savedDraft.mentionNameById,
          const <String, String>{'user-1': 'Alice'},
        );
      },
    );

    blocTest<ChatDraftBloc, ChatDraftState>(
      'clears draft after delivery acknowledgment when input is empty',
      build: buildBloc,
      act: (bloc) {
        final queuedAt = DateTime(2026, 3, 4, 11, 0, 0);
        bloc
          ..add(
            ChatDraftMessageQueued(
              conversationId: 'conversation-1',
              content: 'hello world',
              queuedAt: queuedAt,
            ),
          )
          ..add(
            ChatDraftMessageDeliveryChecked(
              conversationId: 'conversation-1',
              currentUserId: 'user-1',
              currentInputText: '',
              messages: <ChatMessage>[
                ChatMessage(
                  id: 'message-1',
                  chatId: 'conversation-1',
                  content: 'hello world',
                  contentType: ContentType.text,
                  sender: MessageSender(
                    id: 'user-1',
                    name: 'Alice',
                  ),
                  createdAt: queuedAt.add(const Duration(seconds: 1)),
                  updatedAt: queuedAt.add(const Duration(seconds: 1)),
                ),
              ],
            ),
          );
      },
      wait: const Duration(milliseconds: 50),
      expect: () => <ChatDraftState>[],
      verify: (_) {
        verify(
          () => removeChatDraftUseCase('conversation-1'),
        ).called(1);
      },
    );
  });
}
