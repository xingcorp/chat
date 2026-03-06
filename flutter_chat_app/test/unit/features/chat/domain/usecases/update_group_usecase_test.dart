import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/update_group_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements IChatRepository {}

void main() {
  late _MockChatRepository repository;
  late UpdateGroupUseCase useCase;

  setUpAll(() {
    registerFallbackValue(GroupType.private);
  });

  setUp(() {
    repository = _MockChatRepository();
    useCase = UpdateGroupUseCase(
      repository: repository,
      logger: AppLogger(),
    );
  });

  test('forwards metadata and membership updates to repository', () async {
    final updatedChat = Chat(
      id: 'chat-1',
      name: 'Platform Guild',
      description: 'Updated scope',
      groupType: GroupType.public,
      type: ChatType.group,
      participantIds: const ['u1', 'u2', 'u3'],
    );

    when(() => repository.updateChat(
          chatId: 'chat-1',
          name: 'Platform Guild',
          avatarUrl: 'https://cdn.example.com/group.jpg',
          description: 'Updated scope',
          groupType: GroupType.public,
          memberIds: const ['u1', 'u2', 'u3'],
          adminIds: const ['u1', 'u3'],
        )).thenAnswer((_) async => Right(updatedChat));

    final result = await useCase(
      const UpdateGroupParams(
        conversationId: 'chat-1',
        name: 'Platform Guild',
        imageUrl: 'https://cdn.example.com/group.jpg',
        description: 'Updated scope',
        groupType: GroupType.public,
        memberIds: ['u1', 'u2', 'u3'],
        adminIds: ['u1', 'u3'],
      ),
    );

    expect(result.isRight, true);
    expect(result.right.groupType, GroupType.public);
    expect(result.right.participantIds, const ['u1', 'u2', 'u3']);

    verify(() => repository.updateChat(
          chatId: 'chat-1',
          name: 'Platform Guild',
          avatarUrl: 'https://cdn.example.com/group.jpg',
          description: 'Updated scope',
          groupType: GroupType.public,
          memberIds: const ['u1', 'u2', 'u3'],
          adminIds: const ['u1', 'u3'],
        )).called(1);
  });

  test('returns validation failure when no update field is provided', () async {
    final result = await useCase(
      const UpdateGroupParams(conversationId: 'chat-1'),
    );

    expect(result.isLeft, true);
    expect(result.left, isA<ValidationFailure>());

    verifyNever(() => repository.updateChat(
          chatId: any(named: 'chatId'),
          name: any(named: 'name'),
          avatarUrl: any(named: 'avatarUrl'),
          description: any(named: 'description'),
          groupType: any(named: 'groupType'),
          memberIds: any(named: 'memberIds'),
          adminIds: any(named: 'adminIds'),
        ));
  });
}
