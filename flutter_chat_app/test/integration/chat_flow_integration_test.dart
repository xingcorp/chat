import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/services/offline_queue_service.dart';
import 'package:flutter_chat_app/core/services/offline_operation_processor.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/repositories/chat_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/message_repository_impl.dart';
import 'package:flutter_chat_app/domain/usecases/chat/get_conversations_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:isar/isar.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_flow_integration_test.mocks.dart';

/// **INTEGRATION TEST: End-to-End Chat Flow**
///
/// Tests the complete flow from user action to UI update:
/// 1. Load conversations from API → Cache locally → Display in UI
/// 2. Send message online → Cache locally → Emit to Socket.IO
/// 3. Send message offline → Queue operation → Process when online
/// 4. Receive real-time message → Update cache → Update UI
///
/// **Architecture:** Tests all layers working together
/// **Pattern:** Real components with mocked external dependencies
/// **Validation:** Data consistency at each step

@GenerateMocks([
  IChatRemoteDataSource,
  IMessageRemoteDataSource,
  INetworkInfo,
])
void main() {
  late Isar isar;
  late ChatLocalDataSource chatLocalDataSource;
  late MessageLocalDataSource messageLocalDataSource;
  late MockIChatRemoteDataSource mockChatRemoteDataSource;
  late MockIMessageRemoteDataSource mockMessageRemoteDataSource;
  late MockINetworkInfo mockNetworkInfo;
  late AppLogger logger;
  late OfflineOperationProcessor processor;
  late OfflineQueueService offlineQueueService;
  late ChatRepositoryImpl chatRepository;
  late MessageRepositoryImpl messageRepository;
  late GetConversationsUseCase getConversationsUseCase;
  late GetMessagesUseCase getMessagesUseCase;
  late SendMessageUseCase sendMessageUseCase;
  late ChatBloc chatBloc;
  late MessageBloc messageBloc;

  setUp(() async {
    // Setup real Isar database (in-memory)
    isar = await Isar.open(
      [/* Add your schemas here */],
      directory: '',
      name: 'test_db_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Setup real local data sources
    chatLocalDataSource = ChatLocalDataSource(isar: isar);
    messageLocalDataSource = MessageLocalDataSource(isar: isar);

    // Setup mocked remote data sources
    mockChatRemoteDataSource = MockIChatRemoteDataSource();
    mockMessageRemoteDataSource = MockIMessageRemoteDataSource();
    mockNetworkInfo = MockINetworkInfo();

    // Setup logger
    logger = AppLogger();

    // Setup offline queue components
    processor = OfflineOperationProcessor(
      messageRepository: messageRepository,
      chatRepository: chatRepository,
      logger: logger,
    );

    offlineQueueService = OfflineQueueService(
      isar: isar,
      networkInfo: mockNetworkInfo,
      logger: logger,
      processor: processor,
    );

    // Setup repositories
    chatRepository = ChatRepositoryImpl(
      chatLocalDataSource,
      mockChatRemoteDataSource,
      /* Add other dependencies */
    );

    messageRepository = MessageRepositoryImpl(
      localDataSource: messageLocalDataSource,
      remoteDataSource: mockMessageRemoteDataSource,
      /* Add other dependencies */
    );

    // Setup use cases
    getConversationsUseCase = GetConversationsUseCase(
      repository: chatRepository,
    );

    getMessagesUseCase = GetMessagesUseCase(
      repository: messageRepository,
    );

    sendMessageUseCase = SendMessageUseCase(
      repository: messageRepository,
    );

    // Setup BLoCs
    chatBloc = ChatBloc(
      getConversations: getConversationsUseCase,
      /* Add other use cases */
    );

    messageBloc = MessageBloc(
      getMessages: getMessagesUseCase,
      sendMessage: sendMessageUseCase,
      /* Add other use cases */
    );
  });

  tearDown(() async {
    await chatBloc.close();
    await messageBloc.close();
    await isar.close(deleteFromDisk: true);
    offlineQueueService.dispose();
  });

  group('Integration Test: End-to-End Chat Flow', () {
    test('should load conversations from API, cache locally, and display in UI',
        () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockChatRemoteDataSource.getConversationList())
          .thenAnswer((_) async => []);

      // Act
      chatBloc.add(const ChatEvent.loadConversations());

      // Assert
      await expectLater(
        chatBloc.stream,
        emitsInOrder([
          isA<ChatLoadingState>(),
          isA<ChatLoadedState>()
              .having((s) => s.conversations.length, 'length', greaterThan(0)),
        ]),
      );

      // Verify data is cached locally
      final cachedChats = await chatLocalDataSource.getChats();
      expect(cachedChats, isNotEmpty);
    });

    test('should send message online, cache locally, and emit to Socket.IO',
        () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockMessageRemoteDataSource.sendMessage(
        conversationId: anyNamed('conversationId'),
        type: anyNamed('type'),
        message: anyNamed('message'),
        createdAt: anyNamed('createdAt'),
      )).thenAnswer((_) async => null);

      // Act
      messageBloc.add(MessageEvent.sendMessage(
        chatId: 'test-chat-id',
        content: 'Test message',
      ));

      // Assert
      await expectLater(
        messageBloc.stream,
        emitsInOrder([
          isA<MessageSendingState>(),
          isA<MessageSentState>(),
        ]),
      );

      // Verify message is cached locally
      final cachedMessages =
          await messageLocalDataSource.getMessagesForChat('test-chat-id');
      expect(
        cachedMessages.any((m) => m.content == 'Test message'),
        isTrue,
      );
    });

    test('should queue message offline and process when online', () async {
      // Arrange - Start offline
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act - Send message while offline
      messageBloc.add(MessageEvent.sendMessage(
        chatId: 'test-chat-id',
        content: 'Offline message',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Message should be queued
      final queueSize = await offlineQueueService.getQueueSize();
      expect(queueSize, equals(1));

      // Arrange - Come online
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockMessageRemoteDataSource.sendMessage(
        conversationId: anyNamed('conversationId'),
        type: anyNamed('type'),
        message: anyNamed('message'),
        createdAt: anyNamed('createdAt'),
      )).thenAnswer((_) async => null);

      // Act - Process queue
      await offlineQueueService.processQueue();

      // Assert - Queue should be empty
      final newQueueSize = await offlineQueueService.getQueueSize();
      expect(newQueueSize, equals(0));

      // Verify message was sent
      verify(mockMessageRemoteDataSource.sendMessage(
        conversationId: anyNamed('conversationId'),
        type: anyNamed('type'),
        message: 'Offline message',
        createdAt: anyNamed('createdAt'),
      )).called(1);
    });

    test('should receive real-time message, update cache, and update UI',
        () async {
      // This test would require Socket.IO mock
      // Placeholder for now
      // TODO: Implement when Socket.IO testing is set up
    });
  });

  group('Property Test: Cache-Backend Consistency', () {
    test('Property 13: After sync, cache should match backend', () async {
      // Run 100 iterations with varied data
      for (var i = 0; i < 100; i++) {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        final mockMessages = _generateRandomMessages(i);
        when(mockMessageRemoteDataSource.getMessageList(
          conversationId: anyNamed('conversationId'),
          size: anyNamed('size'),
        )).thenAnswer((_) async => mockMessages);

        // Act
        await messageRepository.syncMessages('test-chat-$i');

        // Assert
        final cachedMessages =
            await messageLocalDataSource.getMessagesForChat('test-chat-$i');
        expect(cachedMessages.length, equals(mockMessages.messages.length));

        // Cleanup
        await isar.writeTxn(() async {
          await isar.messageModels.clear();
        });
      }
    });
  });
}

/// Helper to generate random messages for property testing
dynamic _generateRandomMessages(int seed) {
  // TODO: Implement random message generation
  return null;
}
