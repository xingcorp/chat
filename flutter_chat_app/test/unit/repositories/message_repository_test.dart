import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/repositories/message_repository_impl.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';

import '../../test_config.dart';
import 'message_repository_test.mocks.dart';

/// **ENTERPRISE MESSAGE REPOSITORY UNIT TESTS**
///
/// Comprehensive unit tests for MessageRepositoryImpl with >90% coverage
/// validating Either<Failure, T> pattern, error handling, and performance.
///
/// **Test Coverage:**
/// - All repository methods
/// - Success and failure scenarios
/// - Edge cases and error conditions
/// - Performance validation
///
/// **Architecture**: Clean Architecture + SOLID principles + Either pattern testing

@GenerateMocks([MessageRemoteDataSource])
void main() {
  group('MessageRepositoryImpl', () {
    late MessageRepositoryImpl repository;
    late MockMessageRemoteDataSource mockRemoteDataSource;

    setUp(() async {
      await TestConfig.initializeTestEnvironment();
      
      mockRemoteDataSource = MockMessageRemoteDataSource();
      repository = MessageRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    tearDown(() async {
      await TestConfig.cleanup();
    });

    group('getMessages', () {
      const chatId = 'test_chat_1';
      final testMessages = [
        TestDataFactory.createTestMessage(id: 'msg1', chatId: chatId),
        TestDataFactory.createTestMessage(id: 'msg2', chatId: chatId),
      ];

      test('should return messages when remote data source succeeds', () async {
        // Arrange
        when(mockRemoteDataSource.getMessages(chatId))
            .thenAnswer((_) async => Right(testMessages.map((msg) => 
                MessageModel.fromDomain(msg)).toList()));

        // Act
        final result = await repository.getMessages(chatId);

        // Assert
        expect(result, TestMatchers.isRight<List<ChatMessage>>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (messages) {
            expect(messages, hasLength(2));
            expect(messages.first.id, equals('msg1'));
            expect(messages.last.id, equals('msg2'));
          },
        );

        verify(mockRemoteDataSource.getMessages(chatId)).called(1);
      });

      test('should return failure when remote data source fails', () async {
        // Arrange
        const failure = ServerFailure(message: 'Server error');
        when(mockRemoteDataSource.getMessages(chatId))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await repository.getMessages(chatId);

        // Assert
        expect(result, TestMatchers.isLeft<List<ChatMessage>>());
        result.fold(
          (actualFailure) {
            expect(actualFailure, isA<ServerFailure>());
            expect(actualFailure.message, equals('Server error'));
          },
          (messages) => fail('Expected failure but got success'),
        );

        verify(mockRemoteDataSource.getMessages(chatId)).called(1);
      });

      test('should handle empty message list', () async {
        // Arrange
        when(mockRemoteDataSource.getMessages(chatId))
            .thenAnswer((_) async => const Right([]));

        // Act
        final result = await repository.getMessages(chatId);

        // Assert
        expect(result, TestMatchers.isRight<List<ChatMessage>>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (messages) {
            expect(messages, isEmpty);
          },
        );
      });

      test('should complete within performance target', () async {
        // Arrange
        when(mockRemoteDataSource.getMessages(chatId))
            .thenAnswer((_) async => Right(testMessages.map((msg) => 
                MessageModel.fromDomain(msg)).toList()));

        // Act & Assert
        final duration = await TestConfig.measurePerformance(() async {
          await repository.getMessages(chatId);
        });

        expect(duration, TestMatchers.takesLessThan(TestConstants.maxMessageDeliveryTime));
      });
    });

    group('sendMessage', () {
      final testMessage = TestDataFactory.createTestMessage();

      test('should return message when sending succeeds', () async {
        // Arrange
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => Right(MessageModel.fromDomain(testMessage)));

        // Act
        final result = await repository.sendMessage(
          chatId: testMessage.chatId,
          content: testMessage.content,
          contentType: testMessage.contentType,
        );

        // Assert
        expect(result, TestMatchers.isRight<ChatMessage>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (message) {
            expect(message.id, equals(testMessage.id));
            expect(message.content, equals(testMessage.content));
            expect(message.chatId, equals(testMessage.chatId));
          },
        );

        verify(mockRemoteDataSource.sendMessage(any)).called(1);
      });

      test('should return failure when sending fails', () async {
        // Arrange
        const failure = ConnectionFailure(message: 'Network error');
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await repository.sendMessage(
          chatId: testMessage.chatId,
          content: testMessage.content,
          contentType: testMessage.contentType,
        );

        // Assert
        expect(result, TestMatchers.isLeft<ChatMessage>());
        result.fold(
          (actualFailure) {
            expect(actualFailure, isA<ConnectionFailure>());
            expect(actualFailure.message, equals('Network error'));
          },
          (message) => fail('Expected failure but got success'),
        );
      });

      test('should validate required parameters', () async {
        // Act & Assert
        expect(
          () => repository.sendMessage(
            chatId: '',
            content: testMessage.content,
            contentType: testMessage.contentType,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => repository.sendMessage(
            chatId: testMessage.chatId,
            content: '',
            contentType: testMessage.contentType,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should complete within performance target', () async {
        // Arrange
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => Right(MessageModel.fromDomain(testMessage)));

        // Act & Assert
        final duration = await TestConfig.measurePerformance(() async {
          await repository.sendMessage(
            chatId: testMessage.chatId,
            content: testMessage.content,
            contentType: testMessage.contentType,
          );
        });

        expect(duration, TestMatchers.takesLessThan(TestConstants.maxMessageDeliveryTime));
      });
    });

    group('updateMessage', () {
      final testMessage = TestDataFactory.createTestMessage();

      test('should return updated message when update succeeds', () async {
        // Arrange
        final updatedMessage = TestDataFactory.createTestMessage(
          id: testMessage.id,
          content: 'Updated content',
        );
        
        when(mockRemoteDataSource.updateMessage(any))
            .thenAnswer((_) async => Right(MessageModel.fromDomain(updatedMessage)));

        // Act
        final result = await repository.updateMessage(
          messageId: testMessage.id,
          content: 'Updated content',
        );

        // Assert
        expect(result, TestMatchers.isRight<ChatMessage>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (message) {
            expect(message.id, equals(testMessage.id));
            expect(message.content, equals('Updated content'));
          },
        );
      });

      test('should return failure when update fails', () async {
        // Arrange
        const failure = ValidationFailure(message: 'Invalid content');
        when(mockRemoteDataSource.updateMessage(any))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await repository.updateMessage(
          messageId: testMessage.id,
          content: 'Updated content',
        );

        // Assert
        expect(result, TestMatchers.isLeft<ChatMessage>());
        result.fold(
          (actualFailure) {
            expect(actualFailure, isA<ValidationFailure>());
            expect(actualFailure.message, equals('Invalid content'));
          },
          (message) => fail('Expected failure but got success'),
        );
      });
    });

    group('deleteMessage', () {
      const messageId = 'test_message_1';

      test('should return true when deletion succeeds', () async {
        // Arrange
        when(mockRemoteDataSource.deleteMessage(messageId))
            .thenAnswer((_) async => const Right(true));

        // Act
        final result = await repository.deleteMessage(messageId);

        // Assert
        expect(result, TestMatchers.isRight<bool>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (success) {
            expect(success, isTrue);
          },
        );

        verify(mockRemoteDataSource.deleteMessage(messageId)).called(1);
      });

      test('should return failure when deletion fails', () async {
        // Arrange
        const failure = PermissionFailure(message: 'Not authorized');
        when(mockRemoteDataSource.deleteMessage(messageId))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await repository.deleteMessage(messageId);

        // Assert
        expect(result, TestMatchers.isLeft<bool>());
        result.fold(
          (actualFailure) {
            expect(actualFailure, isA<PermissionFailure>());
            expect(actualFailure.message, equals('Not authorized'));
          },
          (success) => fail('Expected failure but got success'),
        );
      });
    });

    group('markAsRead', () {
      const messageId = 'test_message_1';

      test('should return true when marking as read succeeds', () async {
        // Arrange
        when(mockRemoteDataSource.markAsRead(messageId))
            .thenAnswer((_) async => const Right(true));

        // Act
        final result = await repository.markAsRead(messageId);

        // Assert
        expect(result, TestMatchers.isRight<bool>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (success) {
            expect(success, isTrue);
          },
        );
      });

      test('should return failure when marking as read fails', () async {
        // Arrange
        const failure = ServerFailure(message: 'Database error');
        when(mockRemoteDataSource.markAsRead(messageId))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await repository.markAsRead(messageId);

        // Assert
        expect(result, TestMatchers.isLeft<bool>());
        result.fold(
          (actualFailure) {
            expect(actualFailure, isA<ServerFailure>());
            expect(actualFailure.message, equals('Database error'));
          },
          (success) => fail('Expected failure but got success'),
        );
      });
    });

    group('searchMessages', () {
      const query = 'test query';
      final testMessages = [
        TestDataFactory.createTestMessage(content: 'test message 1'),
        TestDataFactory.createTestMessage(content: 'test message 2'),
      ];

      test('should return search results when search succeeds', () async {
        // Arrange
        when(mockRemoteDataSource.searchMessages(query))
            .thenAnswer((_) async => Right(testMessages.map((msg) => 
                MessageModel.fromDomain(msg)).toList()));

        // Act
        final result = await repository.searchMessages(query);

        // Assert
        expect(result, TestMatchers.isRight<List<ChatMessage>>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (messages) {
            expect(messages, hasLength(2));
            expect(messages.every((msg) => msg.content.contains('test')), isTrue);
          },
        );
      });

      test('should return empty list for empty query', () async {
        // Act
        final result = await repository.searchMessages('');

        // Assert
        expect(result, TestMatchers.isRight<List<ChatMessage>>());
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (messages) {
            expect(messages, isEmpty);
          },
        );

        verifyNever(mockRemoteDataSource.searchMessages(any));
      });
    });
  });
}
