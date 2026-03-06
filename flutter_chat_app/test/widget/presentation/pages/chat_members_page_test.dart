import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_state.dart';
import 'package:flutter_chat_app/presentation/pages/chat_members_page.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatMembersBloc extends MockBloc<ChatMembersEvent, ChatMembersState>
    implements ChatMembersBloc {}

class _FakeChatMembersEvent extends Fake implements ChatMembersEvent {}

class _FakeChatMembersState extends Fake implements ChatMembersState {}

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

Widget _host({
  required Widget child,
  required Locale locale,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    ),
  );
}

void main() {
  final getIt = GetIt.instance;
  late _MockChatMembersBloc bloc;
  late Chat chat;

  setUpAll(() {
    registerFallbackValue(_FakeChatMembersEvent());
    registerFallbackValue(_FakeChatMembersState());
    registerFallbackValue(
      const Chat(
        id: 'fallback-chat',
        participantIds: <String>[],
      ),
    );
  });

  setUp(() async {
    await getIt.reset();
    bloc = _MockChatMembersBloc();
    chat = Chat(
      id: 'chat-1',
      name: 'Platform Guild',
      type: ChatType.group,
      participantIds: const ['u1', 'u2'],
      members: <ConversationMember>[
        _member(id: 'u1', name: 'Alice', isAdmin: true),
        _member(id: 'u2', name: 'Bob', isAdmin: false),
      ],
    );

    when(() => bloc.init(any())).thenReturn(null);
    when(() => bloc.close()).thenAnswer((_) async {});
    getIt.registerFactory<ChatMembersBloc>(() => bloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows localized promote action for admins in English',
      (tester) async {
    final state = ChatMembersLoaded(
      members: chat.members,
      filteredMembers: chat.members,
      creatorName: 'Alice',
      createdAt: DateTime(2026, 3, 6, 9),
    );

    when(() => bloc.state).thenReturn(state);
    whenListen(
      bloc,
      const Stream<ChatMembersState>.empty(),
      initialState: state,
    );

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        child: ChatMembersPage(
          chat: chat,
          currentUserId: 'u1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Member actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();

    expect(find.text('Make group admin'), findsOneWidget);
    await tester.ensureVisible(find.text('Make group admin'));

    await tester.tap(find.text('Make group admin'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        const ChatMembersMakeAdmin(
          chatId: 'chat-1',
          memberId: 'u2',
        ),
      ),
    ).called(1);
  });

  testWidgets('shows localized demote action for admins in Vietnamese',
      (tester) async {
    final adminTarget = _member(id: 'u2', name: 'Bob', isAdmin: true);
    final localChat = chat.copyWith(
      members: <ConversationMember>[
        _member(id: 'u1', name: 'Alice', isAdmin: true),
        adminTarget,
      ],
    );
    final state = ChatMembersLoaded(
      members: localChat.members,
      filteredMembers: localChat.members,
      creatorName: 'Alice',
      createdAt: DateTime(2026, 3, 6, 9),
    );

    when(() => bloc.state).thenReturn(state);
    whenListen(
      bloc,
      const Stream<ChatMembersState>.empty(),
      initialState: state,
    );

    await tester.pumpWidget(
      _host(
        locale: const Locale('vi'),
        child: ChatMembersPage(
          chat: localChat,
          currentUserId: 'u1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Thao tác thành viên'), findsOneWidget);

    await tester.tap(find.byTooltip('Thao tác thành viên'));
    await tester.pumpAndSettle();

    expect(find.text('Gỡ quyền quản trị'), findsOneWidget);
    await tester.ensureVisible(find.text('Gỡ quyền quản trị'));

    await tester.tap(find.text('Gỡ quyền quản trị'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        const ChatMembersRemoveAdmin(
          chatId: 'chat-1',
          memberId: 'u2',
        ),
      ),
    ).called(1);
  });

  testWidgets('hides member actions when current user is not admin',
      (tester) async {
    final localChat = chat.copyWith(
      members: <ConversationMember>[
        _member(id: 'u1', name: 'Alice', isAdmin: false),
        _member(id: 'u2', name: 'Bob', isAdmin: false),
      ],
    );
    final state = ChatMembersLoaded(
      members: localChat.members,
      filteredMembers: localChat.members,
    );

    when(() => bloc.state).thenReturn(state);
    whenListen(
      bloc,
      const Stream<ChatMembersState>.empty(),
      initialState: state,
    );

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        child: ChatMembersPage(
          chat: localChat,
          currentUserId: 'u1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Member actions'), findsNothing);
  });
}
