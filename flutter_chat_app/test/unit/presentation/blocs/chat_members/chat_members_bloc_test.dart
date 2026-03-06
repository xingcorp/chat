import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_state.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements IChatRepository {}

ConversationMember _member({
  required String id,
  required String name,
  required bool isAdmin,
}) {
  return ConversationMember(
    id: id,
    userId: id,
    fullName: name,
    isAdmin: isAdmin,
  );
}

void main() {
  late _MockChatRepository chatRepository;
  late Chat chat;
  late ConversationMember currentAdmin;
  late ConversationMember bob;
  late ConversationMember cara;

  setUp(() {
    chatRepository = _MockChatRepository();
    currentAdmin = _member(
      id: 'u1',
      name: 'Alice',
      isAdmin: true,
    );
    bob = _member(
      id: 'u2',
      name: 'Bob',
      isAdmin: false,
    );
    cara = _member(
      id: 'u3',
      name: 'Cara',
      isAdmin: false,
    );
    chat = Chat(
      id: 'chat-1',
      name: 'Platform Guild',
      type: ChatType.group,
      participantIds: const ['u1', 'u2', 'u3'],
      members: <ConversationMember>[currentAdmin, bob, cara],
      creatorName: 'Alice',
      createdAt: DateTime(2026, 3, 6, 9),
    );
  });

  ChatMembersBloc buildBloc() {
    final bloc = ChatMembersBloc(
      logger: AppLogger(),
      chatRepository: chatRepository,
    );
    bloc.init(chat);
    return bloc;
  }

  blocTest<ChatMembersBloc, ChatMembersState>(
    'make admin keeps current search context and emits refreshed loaded state',
    build: () {
      when(() => chatRepository.updateAdmins(
            chatId: 'chat-1',
            adminIds: const ['u1', 'u2'],
          )).thenAnswer((_) async => const Right(true));
      return buildBloc();
    },
    seed: () => ChatMembersLoaded(
      members: <ConversationMember>[currentAdmin, bob, cara],
      filteredMembers: <ConversationMember>[bob],
      searchKeyword: 'bob',
      sortType: MembersSortType.alphabetical,
      creatorName: 'Alice',
      createdAt: DateTime(2026, 3, 6, 9),
    ),
    act: (bloc) => bloc.add(
      const ChatMembersMakeAdmin(
        chatId: 'chat-1',
        memberId: 'u2',
      ),
    ),
    expect: () => <Matcher>[
      isA<ChatMembersLoading>().having(
        (state) => state.message,
        'message',
        'Making admin...',
      ),
      isA<ChatMembersAdminUpdated>()
          .having((state) => state.memberId, 'memberId', 'u2')
          .having((state) => state.isAdmin, 'isAdmin', true)
          .having(
              (state) => state.members.single.isAdmin, 'updated admin', true),
      isA<ChatMembersLoaded>()
          .having((state) => state.searchKeyword, 'searchKeyword', 'bob')
          .having(
            (state) => state.sortType,
            'sortType',
            MembersSortType.alphabetical,
          )
          .having((state) => state.filteredCount, 'filteredCount', 1)
          .having(
            (state) => state.filteredMembers.single.userId,
            'filtered member',
            'u2',
          )
          .having(
            (state) => state.filteredMembers.single.isAdmin,
            'filtered admin state',
            true,
          ),
    ],
    verify: (_) {
      verify(() => chatRepository.updateAdmins(
            chatId: 'chat-1',
            adminIds: const ['u1', 'u2'],
          )).called(1);
    },
  );

  blocTest<ChatMembersBloc, ChatMembersState>(
    'remove member emits refreshed loaded state without dropping filters',
    build: () {
      when(() => chatRepository.removeParticipants(
            chatId: 'chat-1',
            userIds: const ['u2'],
          )).thenAnswer((_) async => const Right(true));
      return buildBloc();
    },
    seed: () => ChatMembersLoaded(
      members: <ConversationMember>[currentAdmin, bob, cara],
      filteredMembers: <ConversationMember>[bob],
      searchKeyword: 'bo',
      sortType: MembersSortType.reverseAlphabetical,
      creatorName: 'Alice',
      createdAt: DateTime(2026, 3, 6, 9),
    ),
    act: (bloc) => bloc.add(
      const ChatMembersRemove(
        chatId: 'chat-1',
        memberId: 'u2',
      ),
    ),
    expect: () => <Matcher>[
      isA<ChatMembersLoading>().having(
        (state) => state.message,
        'message',
        'Removing member...',
      ),
      isA<ChatMembersMemberRemoved>()
          .having((state) => state.memberId, 'memberId', 'u2')
          .having(
            (state) => state.remainingMembers.isEmpty,
            'remaining filtered members empty',
            true,
          ),
      isA<ChatMembersLoaded>()
          .having((state) => state.searchKeyword, 'searchKeyword', 'bo')
          .having(
            (state) => state.sortType,
            'sortType',
            MembersSortType.reverseAlphabetical,
          )
          .having((state) => state.memberCount, 'memberCount', 2)
          .having((state) => state.filteredCount, 'filteredCount', 0),
    ],
    verify: (_) {
      verify(() => chatRepository.removeParticipants(
            chatId: 'chat-1',
            userIds: const ['u2'],
          )).called(1);
    },
  );
}
