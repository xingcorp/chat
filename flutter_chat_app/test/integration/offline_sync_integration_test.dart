import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/services/offline_queue_service.dart';
import 'package:flutter_chat_app/core/services/offline_operation_processor.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/models/offline_operation_model.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:isar/isar.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'offline_sync_integration_test.mocks.dart';

/// **INTEGRATION TEST: Offline Sync**
///
/// Tests offline operation queuing and synchronization:
/// 1. Queue multiple operations offline
/// 2. Come online → Process queue in FIFO order
/// 3. Handle operation failures → Retry with backoff
/// 4. Verify cache consistency after sync
///
/// **Properties Tested:**
/// - Property 11: Offline Queue Addition
/// - Property 12: Offline Queue Processing Order
///
/// **Architecture:** Tests offline-first strategy end-to-end

@GenerateMocks([
  IMessageRepository,
  IChatRepository,
  INetworkInfo,
])
void main() {
  late Isar isar;
  late MockIMessageRepository mockMessageRepository;
  late MockIChatRepository mockChatRepository;
  late MockINetworkInfo mockNetworkInfo;
  late AppLogger logger;
  late OfflineOperationProcessor processor;
  late OfflineQueueService offlineQueueService;

  setUp(() async {
    // Setup real Isar database (in-memory)
    isar = await Isar.open(
      [OfflineOperationModelSchema],
      directory: '',
      name: 'test_offline_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Setup mocks
    mockMessageRepository = MockIMessageRepository();
    mockChatRepository = MockIChatRepository();
    mockNetworkInfo = MockINetworkInfo();

    // Setup logger
    logger = AppLogger();

    // Setup processor
    processor = OfflineOperationProcessor(
      messageRepository: mockMessageRepository,
      chatRepository: mockChatRepository,
      logger: logger,
    );

    // Setup offline queue service
    offlineQueueService = OfflineQueueService(
      isar: isar,
      networkInfo: mockNetworkInfo,
      logger: logger,
      processor: processor,
    );
  });

  tearDown(() async {
    offlineQueueService.dispose();
    await isar.close(deleteFromDisk: true);
  });

  group('Integration Test: Offline Sync', () {
    test('should queue multiple operations offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act - Queue 5 operations
      final operationIds = <String>[];
      for (var i = 0; i < 5; i++) {
        final operationId = await offlineQueueService.addOperation(
          OfflineOperationModel(
            type: OperationType.sendMessage,
            data: {
              'chatId': 'test-chat',
              'content': 'Message $i',
              'senderId': 'user-1',
              'contentType': 'text',
            },
            timestamp: DateTime.now(),
          ),
        );
        operationIds.add(operationId);
      }

      // Assert
      final queueSize = await offlineQueueService.getQueueSize();
      expect(queueSize, equals(5));

      final pendingOps = await offlineQueueService.getPendingOperations();
      expect(pendingOps.length, equals(5));
    });

    test('should process queue in FIFO order when online', () async {
      // Arrange - Queue 3 operations
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final operation1 = await offlineQueueService.addOperation(
        OfflineOperationModel(
          type: OperationType.sendMessage,
          data: {
            'chatId': 'test-chat',
            'content': 'First message',
            'senderId': 'user-1',
            'contentType': 'text',
          },
          timestamp: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      final operation2 = await offlineQueueService.addOperation(
        OfflineOperationModel(
          type: OperationType.sendMessage,
          data: {
            'chatId': 'test-chat',
            'content': 'Second message',
            'senderId': 'user-1',
            'contentType': 'text',
          },
          timestamp: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      final operation3 = await offlineQueueService.addOperation(
        OfflineOperationModel(
          type: OperationType.sendMessage,
          data: {
            'chatId': 'test-chat',
            'content': 'Third message',
            'senderId': 'user-1',
            'contentType': 'text',
          },
          timestamp: DateTime.now(),
        ),
      );

      // Arrange - Come online and mock successful sends
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockMessageRepository.sendMessage(
        chatId: anyNamed('chatId'),
        content: anyNamed('content'),
        senderId: anyNamed('senderId'),
        contentType: anyNamed('contentType'),
      )).thenAnswer((_) async => const Right(/* Mock message */));

      // Act - Process queue
      await offlineQueueService.processQueue();

      // Assert - Verify FIFO order
      final verificationResult = verify(
        mockMessageRepository.sendMessage(
          chatId: anyNamed('chatId'),
          content: captureAnyNamed('content'),
          senderId: anyNamed('senderId'),
          contentType: anyNamed('contentType'),
        ),
      );

      verificationResult.called(3);
      final capturedContents = verificationResult.captured;
      expect(capturedContents[0], equals('First message'));
      expect(capturedContents[1], equals('Second message'));
      expect(capturedContents[2], equals('Third message'));

      // Verify queue is empty
      final queueSize = await offlineQueueService.getQueueSize();
      expect(queueSize, equals(0));
    });

    test('should retry failed operations with exponential backoff', () async {
      // Arrange - Queue operation
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final operationId = await offlineQueueService.addOperation(
        OfflineOperationModel(
          type: OperationType.sendMessage,
          data: {
            'chatId': 'test-chat',
            'content': 'Test message',
            'senderId': 'user-1',
            'contentType': 'text',
          },
          timestamp: DateTime.now(),
        ),
      );

      // Arrange - Come online but operation fails
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockMessageRepository.sendMessage(
        chatId: anyNamed('chatId'),
        content: anyNamed('content'),
        senderId: anyNamed('senderId'),
        contentType: anyNamed('contentType'),
      )).thenAnswer((_) async => const Left(ServerFailure(message: 'Failed')));

      // Act - First attempt (should fail)
      await offlineQueueService.processQueue();

      // Assert - Operation should be marked as failed
      final operations = await offlineQueueService.getPendingOperations();
      expect(operations.length, equals(1));
      expect(operations.first.status, equals(OperationStatus.failed));
      expect(operations.first.retryCount, equals(1));

      // Act - Wait for backoff period and retry
      await Future.delayed(const Duration(seconds: 2));

      // Arrange - Now operation succeeds
      when(mockMessageRepository.sendMessage(
        chatId: anyNamed('chatId'),
        content: anyNamed('content'),
        senderId: anyNamed('senderId'),
        contentType: anyNamed('contentType'),
      )).thenAnswer((_) async => const Right(/* Mock message */));

      await offlineQueueService.processQueue();

      // Assert - Queue should be empty
      final queueSize = await offlineQueueService.getQueueSize();
      expect(queueSize, equals(0));
    });

    test('should verify cache consistency after sync', () async {
      // This test would verify that after syncing,
      // local cache matches backend data
      // TODO: Implement with real cache verification
    });
  });

  group('Property Test: Offline Queue', () {
    test('Property 11: Offline operations are always queued', () async {
      // Run 100 iterations
      for (var i = 0; i < 100; i++) {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        await offlineQueueService.addOperation(
          OfflineOperationModel(
            type: OperationType.sendMessage,
            data: {
              'chatId': 'test-chat-$i',
              'content': 'Message $i',
              'senderId': 'user-1',
              'contentType': 'text',
            },
            timestamp: DateTime.now(),
          ),
        );

        // Assert
        final queueSize = await offlineQueueService.getQueueSize();
        expect(queueSize, equals(i + 1));
      }
    });

    test('Property 12: Operations processed in FIFO order', () async {
      // Run 50 iterations with 3 operations each
      for (var iteration = 0; iteration < 50; iteration++) {
        // Arrange - Queue 3 operations
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final timestamps = <DateTime>[];
        for (var i = 0; i < 3; i++) {
          final timestamp = DateTime.now();
          timestamps.add(timestamp);

          await offlineQueueService.addOperation(
            OfflineOperationModel(
              type: OperationType.sendMessage,
              data: {
                'chatId': 'test-chat',
                'content': 'Iteration $iteration Message $i',
                'senderId': 'user-1',
                'contentType': 'text',
                'timestamp': timestamp.millisecondsSinceEpoch,
              },
              timestamp: timestamp,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Arrange - Come online
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockMessageRepository.sendMessage(
          chatId: anyNamed('chatId'),
          content: anyNamed('content'),
          senderId: anyNamed('senderId'),
          contentType: anyNamed('contentType'),
        )).thenAnswer((_) async => const Right(/* Mock message */));

        // Act
        await offlineQueueService.processQueue();

        // Assert - Verify FIFO order
        final verificationResult = verify(
          mockMessageRepository.sendMessage(
            chatId: anyNamed('chatId'),
            content: captureAnyNamed('content'),
            senderId: anyNamed('senderId'),
            contentType: anyNamed('contentType'),
          ),
        );

        final capturedContents = verificationResult.captured;
        expect(capturedContents[0], contains('Message 0'));
        expect(capturedContents[1], contains('Message 1'));
        expect(capturedContents[2], contains('Message 2'));

        // Cleanup
        await isar.writeTxn(() async {
          await isar.offlineOperationModels.clear();
        });

        reset(mockMessageRepository);
      }
    });
  });
}
