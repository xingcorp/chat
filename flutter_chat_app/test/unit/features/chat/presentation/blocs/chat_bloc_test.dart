import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/core/pagination/page_request.dart';
import 'package:flutter_chat_app/core/pagination/paged_result.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/create_group_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/delete_conversation_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversations_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_local_conversations_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/leave_conversation_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/persist_incoming_message_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/search_conversations_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/update_group_usecase.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetConversationsUseCase extends Mock
    implements GetConversationsUseCase {}

class _MockGetLocalConversationsUseCase extends Mock
    implements GetLocalConversationsUseCase {}

class _MockGetConversationDetailUseCase extends Mock
    implements GetConversationDetailUseCase {}

class _MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}

class _MockUpdateGroupUseCase extends Mock implements UpdateGroupUseCase {}

class _MockLeaveConversationUseCase extends Mock
    implements LeaveConversationUseCase {}

class _MockDeleteConversationUseCase extends Mock
    implements DeleteConversationUseCase {}

class _MockSearchConversationsUseCase extends Mock
    implements SearchConversationsUseCase {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _MockCacheSyncStrategy extends Mock implements CacheSyncStrategy {}

class _MockMediaCacheManager extends Mock implements MediaCacheManager {}

class _MockRealtimeService extends Mock implements RealtimeService {}

class _MockMarkAsReadUseCase extends Mock implements MarkAsReadUseCase {}

class _MockCurrentUserProvider extends Mock implements CurrentUserProvider {}

class _MockPersistIncomingMessageUseCase extends Mock
    implements PersistIncomingMessageUseCase {}

class _MockAttachmentRepository extends Mock implements IAttachmentRepository {}

Matcher _isEmptyLoadedState() {
  return isA<ChatState>()
      .having(
        (state) => state.maybeWhen(
          loaded: (chats, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              chats.length,
          orElse: () => -1,
        ),
        'chat count',
        0,
      )
      .having(
        (state) => state.maybeWhen(
          loaded: (_, hasMore, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              hasMore,
          orElse: () => true,
        ),
        'hasMore',
        false,
      );
}

void main() {
  late _MockGetConversationsUseCase getConversationsUseCase;
  late _MockGetLocalConversationsUseCase getLocalConversationsUseCase;
  late _MockGetConversationDetailUseCase getConversationDetailUseCase;
  late _MockCreateGroupUseCase createGroupUseCase;
  late _MockUpdateGroupUseCase updateGroupUseCase;
  late _MockLeaveConversationUseCase leaveConversationUseCase;
  late _MockDeleteConversationUseCase deleteConversationUseCase;
  late _MockSearchConversationsUseCase searchConversationsUseCase;
  late _MockConnectivityService connectivityService;
  late _MockCacheSyncStrategy cacheSyncStrategy;
  late _MockMediaCacheManager mediaCacheManager;
  late _MockRealtimeService realtimeService;
  late _MockMarkAsReadUseCase markAsReadUseCase;
  late _MockCurrentUserProvider currentUserProvider;
  late _MockPersistIncomingMessageUseCase persistIncomingMessageUseCase;
  late ChatModuleEventBus eventBus;
  late _MockAttachmentRepository attachmentRepository;

  setUpAll(() {
    registerFallbackValue(const PageRequest(page: 0, size: 25));
    registerFallbackValue(GroupType.private);
  });

  setUp(() {
    getConversationsUseCase = _MockGetConversationsUseCase();
    getLocalConversationsUseCase = _MockGetLocalConversationsUseCase();
    getConversationDetailUseCase = _MockGetConversationDetailUseCase();
    createGroupUseCase = _MockCreateGroupUseCase();
    updateGroupUseCase = _MockUpdateGroupUseCase();
    leaveConversationUseCase = _MockLeaveConversationUseCase();
    deleteConversationUseCase = _MockDeleteConversationUseCase();
    searchConversationsUseCase = _MockSearchConversationsUseCase();
    connectivityService = _MockConnectivityService();
    cacheSyncStrategy = _MockCacheSyncStrategy();
    mediaCacheManager = _MockMediaCacheManager();
    realtimeService = _MockRealtimeService();
    markAsReadUseCase = _MockMarkAsReadUseCase();
    currentUserProvider = _MockCurrentUserProvider();
    persistIncomingMessageUseCase = _MockPersistIncomingMessageUseCase();
    eventBus = ChatModuleEventBus();
    attachmentRepository = _MockAttachmentRepository();

    when(() => connectivityService.onConnectivityChanged)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => realtimeService.connectionState)
        .thenAnswer((_) => const Stream<SocketConnectionState>.empty());
    when(() => realtimeService.messageStream)
        .thenAnswer((_) => const Stream<ChatMessage>.empty());
    when(() => realtimeService.typingStream)
        .thenAnswer((_) => const Stream<TypingIndicator>.empty());
    when(() => realtimeService.readReceiptStream)
        .thenAnswer((_) => const Stream<MessageReadReceipt>.empty());
    when(() => realtimeService.isConnected).thenReturn(true);

    when(() => getLocalConversationsUseCase()).thenAnswer(
      (_) async => const Right<Failure, List<Chat>>(<Chat>[]),
    );
    when(() => getConversationsUseCase(
          any(),
          typeFilter: any(named: 'typeFilter'),
        )).thenAnswer(
      (_) async => const Right<Failure, PagedResult<Chat>>(
        PagedResult<Chat>(items: <Chat>[], total: 0),
      ),
    );
    when(() => cacheSyncStrategy.markChatListDirty()).thenReturn(null);
    when(() => cacheSyncStrategy.resetChatListDirtyFlag()).thenReturn(null);
    when(() => currentUserProvider.currentUserId).thenReturn('u1');
  });

  tearDown(() {
    eventBus.dispose();
  });

  ChatBloc buildBloc() {
    return ChatBloc(
      getConversationsUseCase,
      getLocalConversationsUseCase,
      getConversationDetailUseCase,
      createGroupUseCase,
      updateGroupUseCase,
      leaveConversationUseCase,
      deleteConversationUseCase,
      searchConversationsUseCase,
      connectivityService,
      cacheSyncStrategy,
      mediaCacheManager,
      realtimeService,
      markAsReadUseCase,
      currentUserProvider,
      persistIncomingMessageUseCase,
      eventBus,
      attachmentRepository,
    );
  }

  blocTest<ChatBloc, ChatState>(
    'passes create group metadata and emits chat details state',
    build: () {
      final createdChat = Chat(
        id: 'chat-1',
        name: 'Platform Guild',
        description: 'Architecture decisions',
        groupType: GroupType.public,
        type: ChatType.group,
        participantIds: const ['u1', 'u2'],
      );

      when(() => createGroupUseCase(
            name: 'Platform Guild',
            memberIds: const ['u1', 'u2'],
            avatar: null,
            description: 'Architecture decisions',
            groupType: GroupType.public,
          )).thenAnswer(
        (_) async => Right<Failure, Chat>(createdChat),
      );

      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ChatEvent.createChat(
        type: ChatType.group,
        name: 'Platform Guild',
        description: 'Architecture decisions',
        groupType: GroupType.public,
        participantIds: ['u1', 'u2'],
      ),
    ),
    expect: () => <Object>[
      const ChatState.loading(),
      isA<ChatState>().having(
        (state) => state.maybeWhen(
          chatDetailsLoaded: (chat) => chat.groupType,
          orElse: () => null,
        ),
        'group type',
        GroupType.public,
      ),
    ],
    verify: (_) {
      verify(() => createGroupUseCase(
            name: 'Platform Guild',
            memberIds: const ['u1', 'u2'],
            avatar: null,
            description: 'Architecture decisions',
            groupType: GroupType.public,
          )).called(1);
      verify(() => cacheSyncStrategy.markChatListDirty()).called(1);
    },
  );

  blocTest<ChatBloc, ChatState>(
    'emits leave completion state then refreshes chat list',
    build: () {
      when(() => leaveConversationUseCase('chat-1')).thenAnswer(
        (_) async => const Right<Failure, bool>(true),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ChatEvent.leaveChat(chatId: 'chat-1'),
    ),
    wait: const Duration(milliseconds: 20),
    expect: () => <Object>[
      const ChatState.loading(),
      const ChatState.conversationActionCompleted(
        chatId: 'chat-1',
        action: ChatConversationAction.leave,
      ),
      const ChatState.loading(),
      _isEmptyLoadedState(),
    ],
    verify: (_) {
      verify(() => leaveConversationUseCase('chat-1')).called(1);
      verify(() => cacheSyncStrategy.markChatListDirty()).called(1);
      verify(() => getConversationsUseCase(
            any(),
            typeFilter: null,
          )).called(1);
    },
  );

  blocTest<ChatBloc, ChatState>(
    'emits delete completion state then refreshes chat list',
    build: () {
      when(() => deleteConversationUseCase('chat-1')).thenAnswer(
        (_) async => const Right<Failure, bool>(true),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ChatEvent.deleteChat(chatId: 'chat-1'),
    ),
    wait: const Duration(milliseconds: 20),
    expect: () => <Object>[
      const ChatState.loading(),
      const ChatState.conversationActionCompleted(
        chatId: 'chat-1',
        action: ChatConversationAction.delete,
      ),
      const ChatState.loading(),
      _isEmptyLoadedState(),
    ],
    verify: (_) {
      verify(() => deleteConversationUseCase('chat-1')).called(1);
      verify(() => cacheSyncStrategy.markChatListDirty()).called(1);
      verify(() => getConversationsUseCase(
            any(),
            typeFilter: null,
          )).called(1);
    },
  );
}
