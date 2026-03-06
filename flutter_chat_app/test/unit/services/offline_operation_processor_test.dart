import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/offline_operation_processor.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/models/offline_operation_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'offline_operation_processor_test.mocks.dart';

/// **UNIT TEST: Offline Operation Processor**
///
/// Tests the OfflineOperationProcessor service in isolation.
/// Verifies that each operation type is processed correctly
/// and delegates to the appropriate repository.
///
/// **Test Coverage:**
/// - All 8 operation types
/// - Success scenarios
/// - Failure scenarios with exception throwing
/// - Repository delegation verification

@GenerateMocks([
  IMessageRepository,
  IChatRepository,
])
void main() {
  late OfflineOperationProcessor processor;
  late MockIMessageRepository mockMessageRepository;
  late MockIChatRepository mockChatRepository;
  late AppLogger logger;

  setUp(() {
    mockMessageRepository = MockIMessageRepository();
    mockChatRepository = MockIChatRepository();
    logger = AppLogger();

    processor = OfflineOperationProcessor(
      messageRepository: mockMessageRepository,
      chatRepository: mockChatRepository,
      logger: logger,
    );
  });

  group('OfflineOperationProcessor - SendMessage', () {
    test('should process sendMessage operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-1',
        type: OperationType.sendMessage,
        data:
            '{"chatId":"test-chat-id","content":"Test message","senderId":"user-1","contentType":"text","attachmentIds":[]}',
        timestamp: DateTime.now(),
      );

      final testMessage = ChatMessage(
        id: 'msg-1',
        content: 'Test message',
        sender: MessageSender(id: 'user-1', name: 'User 1'),
        chatId: 'test-chat-id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contentType: ContentType.text,
        attachments: const [],
        reactions: const [],
      );

      when(mockMessageRepository.sendMessage(
        chatId: anyNamed('chatId'),
        content: anyNamed('content'),
        senderId: anyNamed('senderId'),
        contentType: anyNamed('contentType'),
        attachmentIds: anyNamed('attachmentIds'),
      )).thenAnswer((_) async => Right(testMessage));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockMessageRepository.sendMessage(
        chatId: 'test-chat-id',
        content: 'Test message',
        senderId: 'user-1',
        contentType: 'text',
        attachmentIds: <String>[],
      )).called(1);
    });

    test('should throw exception when sendMessage fails', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-2',
        type: OperationType.sendMessage,
        data:
            '{"chatId":"test-chat-id","content":"Test message","senderId":"user-1","contentType":"text","attachmentIds":[]}',
        timestamp: DateTime.now(),
      );

      when(mockMessageRepository.sendMessage(
        chatId: anyNamed('chatId'),
        content: anyNamed('content'),
        senderId: anyNamed('senderId'),
        contentType: anyNamed('contentType'),
        attachmentIds: anyNamed('attachmentIds'),
      )).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server error')),
      );

      // Act & Assert
      expect(
        () => processor.processOperation(operation),
        throwsException,
      );

      verify(mockMessageRepository.sendMessage(
        chatId: anyNamed('chatId'),
        content: anyNamed('content'),
        senderId: anyNamed('senderId'),
        contentType: anyNamed('contentType'),
        attachmentIds: anyNamed('attachmentIds'),
      )).called(1);
    });
  });

  group('OfflineOperationProcessor - EditMessage', () {
    test('should process editMessage operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-3',
        type: OperationType.editMessage,
        data: '{"messageId":"msg-1","newContent":"Updated message"}',
        timestamp: DateTime.now(),
      );

      when(mockMessageRepository.updateMessage(
        any,
        any,
      )).thenAnswer((_) async => const Right(true));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockMessageRepository.updateMessage(
        'msg-1',
        'Updated message',
      )).called(1);
    });

    test('should throw exception when editMessage fails', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-4',
        type: OperationType.editMessage,
        data: '{"messageId":"msg-1","newContent":"Updated message"}',
        timestamp: DateTime.now(),
      );

      when(mockMessageRepository.updateMessage(
        any,
        any,
      )).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Update failed')),
      );

      // Act & Assert
      expect(
        () => processor.processOperation(operation),
        throwsException,
      );
    });
  });

  group('OfflineOperationProcessor - DeleteMessage', () {
    test('should process deleteMessage operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-5',
        type: OperationType.deleteMessage,
        data: '{"chatId":"chat-1","messageId":"msg-1"}',
        timestamp: DateTime.now(),
      );

      when(mockMessageRepository.deleteMessage(any, any))
          .thenAnswer((_) async => const Right(true));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockMessageRepository.deleteMessage('chat-1', 'msg-1')).called(1);
    });
  });

  group('OfflineOperationProcessor - CreateGroup', () {
    test('should process createGroup operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-6',
        type: OperationType.createGroup,
        data:
            '{"name":"Test Group","participantIds":["user-1","user-2"],"description":"Architecture sync","groupType":"public","isGroup":true}',
        timestamp: DateTime.now(),
      );

      final testChat = Chat(
        id: 'chat-1',
        name: 'Test Group',
        description: 'Architecture sync',
        groupType: GroupType.public,
        type: ChatType.group,
        participantIds: const ['user-1', 'user-2'],
        unreadCount: 0,
      );

      when(mockChatRepository.createChat(
        name: anyNamed('name'),
        participantIds: anyNamed('participantIds'),
        description: anyNamed('description'),
        groupType: anyNamed('groupType'),
        isGroup: anyNamed('isGroup'),
      )).thenAnswer((_) async => Right(testChat));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockChatRepository.createChat(
        name: 'Test Group',
        participantIds: ['user-1', 'user-2'],
        description: 'Architecture sync',
        groupType: GroupType.public,
        isGroup: true,
      )).called(1);
    });

    test('should throw exception when createGroup fails', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-7',
        type: OperationType.createGroup,
        data:
            '{"name":"Test Group","participantIds":["user-1","user-2"],"description":"Architecture sync","groupType":"private","isGroup":true}',
        timestamp: DateTime.now(),
      );

      when(mockChatRepository.createChat(
        name: anyNamed('name'),
        participantIds: anyNamed('participantIds'),
        description: anyNamed('description'),
        groupType: anyNamed('groupType'),
        isGroup: anyNamed('isGroup'),
      )).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Creation failed')),
      );

      // Act & Assert
      expect(
        () => processor.processOperation(operation),
        throwsException,
      );
    });
  });

  group('OfflineOperationProcessor - EditGroup', () {
    test('should process editGroup operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-8',
        type: OperationType.editGroup,
        data:
            '{"chatId":"chat-1","name":"Updated Group Name","avatarUrl":"https://example.com/avatar.jpg","description":"Updated description","groupType":"private","memberIds":["user-1","user-2","user-3"],"adminIds":["user-1","user-3"]}',
        timestamp: DateTime.now(),
      );

      final testChat = Chat(
        id: 'chat-1',
        name: 'Updated Group Name',
        description: 'Updated description',
        groupType: GroupType.private,
        type: ChatType.group,
        participantIds: const ['user-1', 'user-2', 'user-3'],
        unreadCount: 0,
      );

      when(mockChatRepository.updateChat(
        chatId: anyNamed('chatId'),
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
        description: anyNamed('description'),
        groupType: anyNamed('groupType'),
        memberIds: anyNamed('memberIds'),
        adminIds: anyNamed('adminIds'),
      )).thenAnswer((_) async => Right(testChat));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockChatRepository.updateChat(
        chatId: 'chat-1',
        name: 'Updated Group Name',
        avatarUrl: 'https://example.com/avatar.jpg',
        description: 'Updated description',
        groupType: GroupType.private,
        memberIds: ['user-1', 'user-2', 'user-3'],
        adminIds: ['user-1', 'user-3'],
      )).called(1);
    });
  });

  group('OfflineOperationProcessor - LeaveConversation', () {
    test('should process leaveConversation operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-9',
        type: OperationType.leaveConversation,
        data: '{"chatId":"chat-1"}',
        timestamp: DateTime.now(),
      );

      when(mockChatRepository.leaveChat(any))
          .thenAnswer((_) async => const Right(true));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockChatRepository.leaveChat('chat-1')).called(1);
    });
  });

  group('OfflineOperationProcessor - MarkAsRead', () {
    test('should process markAsRead operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-10',
        type: OperationType.markAsRead,
        data: '{"chatId":"chat-1"}',
        timestamp: DateTime.now(),
      );

      when(mockMessageRepository.markChatAsRead(any))
          .thenAnswer((_) async => const Right(null));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockMessageRepository.markChatAsRead('chat-1')).called(1);
    });
  });

  group('OfflineOperationProcessor - DeleteConversation', () {
    test('should process deleteConversation operation successfully', () async {
      final operation = OfflineOperationModel(
        operationId: 'op-10b',
        type: OperationType.deleteConversation,
        data: '{"chatId":"chat-1"}',
        timestamp: DateTime.now(),
      );

      when(mockChatRepository.deleteChat(any))
          .thenAnswer((_) async => const Right(true));

      await processor.processOperation(operation);

      verify(mockChatRepository.deleteChat('chat-1')).called(1);
    });
  });

  group('OfflineOperationProcessor - AddReaction', () {
    test('should process addReaction operation successfully', () async {
      // Arrange
      final operation = OfflineOperationModel(
        operationId: 'op-11',
        type: OperationType.addReaction,
        data: '{"messageId":"msg-1","code":"👍"}',
        timestamp: DateTime.now(),
      );

      when(mockMessageRepository.updateReaction(
        messageId: anyNamed('messageId'),
        code: anyNamed('code'),
        act: anyNamed('act'),
      )).thenAnswer((_) async => const Right(true));

      // Act
      await processor.processOperation(operation);

      // Assert
      verify(mockMessageRepository.updateReaction(
        messageId: 'msg-1',
        code: '👍',
        act: 'ADD',
      )).called(1);
    });
  });
}
