import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/create_group_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements IChatRepository {}

void main() {
  late _MockChatRepository repository;
  late CreateGroupUseCase useCase;

  setUpAll(() {
    registerFallbackValue(GroupType.private);
  });

  setUp(() {
    repository = _MockChatRepository();
    useCase = CreateGroupUseCase(
      repository: repository,
      logger: AppLogger(),
    );
  });

  test('forwards description and group type to repository', () async {
    final createdChat = Chat(
      id: 'chat-1',
      name: 'Platform Guild',
      description: 'Architecture decisions',
      groupType: GroupType.public,
      type: ChatType.group,
      participantIds: const ['u1', 'u2'],
    );

    when(() => repository.createChat(
          name: 'Platform Guild',
          participantIds: const ['u1', 'u2'],
          avatarUrl: null,
          description: 'Architecture decisions',
          groupType: GroupType.public,
          isGroup: true,
        )).thenAnswer((_) async => Right(createdChat));

    final result = await useCase(
      name: 'Platform Guild',
      memberIds: const ['u1', 'u2'],
      description: 'Architecture decisions',
      groupType: GroupType.public,
    );

    expect(result.isRight, true);
    expect(result.right.description, 'Architecture decisions');
    expect(result.right.groupType, GroupType.public);

    verify(() => repository.createChat(
          name: 'Platform Guild',
          participantIds: const ['u1', 'u2'],
          avatarUrl: null,
          description: 'Architecture decisions',
          groupType: GroupType.public,
          isGroup: true,
        )).called(1);
  });

  test('returns validation failure when member list is empty', () async {
    final result = await useCase(
      name: 'Platform Guild',
      memberIds: const <String>[],
    );

    expect(result.isLeft, true);
    expect(result.left, isA<ValidationFailure>());

    verifyNever(() => repository.createChat(
          name: any(named: 'name'),
          participantIds: any(named: 'participantIds'),
          avatarUrl: any(named: 'avatarUrl'),
          description: any(named: 'description'),
          groupType: any(named: 'groupType'),
          isGroup: any(named: 'isGroup'),
        ));
  });
}
