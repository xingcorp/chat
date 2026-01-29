import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/media/media_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/media/media_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/attachment_model.dart';
import 'package:flutter_chat_app/data/repositories/media_repository_impl.dart';
import 'package:flutter_chat_app/domain/entities/attachment.dart';

// Mock classes
class MockMediaRemoteDataSource extends Mock implements IMediaRemoteDataSource {}
class MockMediaLocalDataSource extends Mock implements IMediaLocalDataSource {}
class MockNetworkInfo extends Mock implements INetworkInfo {}

void main() {
  late MediaRepositoryImpl repository;
  late MockMediaRemoteDataSource mockRemoteDataSource;
  late MockMediaLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockMediaRemoteDataSource();
    mockLocalDataSource = MockMediaLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = MediaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('uploadMedia', () {
    const tFilePath = '/path/to/file.jpg';
    const tType = AttachmentType.image;
    const tChatId = 'chat-123';
    const tMessageId = 'msg-456';
    
    final tAttachmentModel = AttachmentModel(
      id: 'attachment-789',
      name: 'file.jpg',
      type: tType,
      mimeType: 'image/jpeg',
      size: 1024,
      url: 'https://example.com/file.jpg',
    );

    test('should return NetworkFailure when device is offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.uploadMedia(
        filePath: tFilePath,
        type: tType,
        chatId: tChatId,
        messageId: tMessageId,
      );

      // Assert
      expect(result, const Left(NetworkFailure(
        message: 'No internet connection. Upload will be queued.',
      )));
      verifyNever(() => mockRemoteDataSource.uploadMedia(
        filePath: any(named: 'filePath'),
        type: any(named: 'type'),
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
        onProgress: any(named: 'onProgress'),
      ));
    });

    test('should upload media and cache it when online', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.uploadMedia(
        filePath: any(named: 'filePath'),
        type: any(named: 'type'),
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
        onProgress: any(named: 'onProgress'),
      )).thenAnswer((_) async => tAttachmentModel);
      when(() => mockLocalDataSource.cacheMedia(
        sourceFilePath: any(named: 'sourceFilePath'),
        attachmentId: any(named: 'attachmentId'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => '/cache/path/file.jpg');
      when(() => mockLocalDataSource.saveAttachmentMetadata(any()))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.uploadMedia(
        filePath: tFilePath,
        type: tType,
        chatId: tChatId,
        messageId: tMessageId,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (attachment) {
          expect(attachment.id, tAttachmentModel.id);
          expect(attachment.name, tAttachmentModel.name);
          expect(attachment.type, tAttachmentModel.type);
        },
      );
      verify(() => mockRemoteDataSource.uploadMedia(
        filePath: tFilePath,
        type: tType,
        chatId: tChatId,
        messageId: tMessageId,
        onProgress: any(named: 'onProgress'),
      )).called(1);
      verify(() => mockLocalDataSource.cacheMedia(
        sourceFilePath: tFilePath,
        attachmentId: tAttachmentModel.id,
        type: tType,
      )).called(1);
    });

    test('should return NetworkFailure when NetworkException is thrown', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.uploadMedia(
        filePath: any(named: 'filePath'),
        type: any(named: 'type'),
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
        onProgress: any(named: 'onProgress'),
      )).thenThrow(const NetworkException(message: 'Connection timeout'));

      // Act
      final result = await repository.uploadMedia(
        filePath: tFilePath,
        type: tType,
        chatId: tChatId,
      );

      // Assert
      expect(result, const Left(NetworkFailure(message: 'Connection timeout')));
    });

    test('should return ServerFailure when ServerException is thrown', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.uploadMedia(
        filePath: any(named: 'filePath'),
        type: any(named: 'type'),
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
        onProgress: any(named: 'onProgress'),
      )).thenThrow(const ServerException(message: 'Upload failed'));

      // Act
      final result = await repository.uploadMedia(
        filePath: tFilePath,
        type: tType,
        chatId: tChatId,
      );

      // Assert
      expect(result, const Left(ServerFailure(message: 'Upload failed')));
    });

    test('should return ValidationFailure when FileException is thrown', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.uploadMedia(
        filePath: any(named: 'filePath'),
        type: any(named: 'type'),
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
        onProgress: any(named: 'onProgress'),
      )).thenThrow(const FileException(message: 'Invalid file'));

      // Act
      final result = await repository.uploadMedia(
        filePath: tFilePath,
        type: tType,
        chatId: tChatId,
      );

      // Assert
      expect(result, const Left(ValidationFailure(message: 'Invalid file')));
    });

    test('should still succeed even if caching fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.uploadMedia(
        filePath: any(named: 'filePath'),
        type: any(named: 'type'),
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
        onProgress: any(named: 'onProgress'),
      )).thenAnswer((_) async => tAttachmentModel);
      when(() => mockLocalDataSource.cacheMedia(
        sourceFilePath: any(named: 'sourceFilePath'),
        attachmentId: any(named: 'attachmentId'),
        type: any(named: 'type'),
      )).thenThrow(const CacheException(message: 'Cache failed'));

      // Act
      final result = await repository.uploadMedia(
        filePath: tFilePath,
        type: tType,
        chatId: tChatId,
      );

      // Assert
      expect(result.isRight(), true);
    });
  });

  group('downloadMedia', () {
    const tUrl = 'https://example.com/file.jpg';
    const tAttachmentId = 'attachment-123';
    const tType = AttachmentType.image;
    const tCachedPath = '/cache/path/file.jpg';
    const tDownloadedPath = '/tmp/attachment-123';

    test('should return cached path if media is already cached', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedMediaPath(any()))
          .thenAnswer((_) async => tCachedPath);

      // Act
      final result = await repository.downloadMedia(
        url: tUrl,
        attachmentId: tAttachmentId,
        type: tType,
      );

      // Assert
      expect(result, const Right(tCachedPath));
      verify(() => mockLocalDataSource.getCachedMediaPath(tAttachmentId)).called(1);
      verifyNever(() => mockNetworkInfo.isConnected);
      verifyNever(() => mockRemoteDataSource.downloadMedia(
        url: any(named: 'url'),
        savePath: any(named: 'savePath'),
        onProgress: any(named: 'onProgress'),
      ));
    });

    test('should return NetworkFailure when not cached and offline', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedMediaPath(any()))
          .thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.downloadMedia(
        url: tUrl,
        attachmentId: tAttachmentId,
        type: tType,
      );

      // Assert
      expect(result, const Left(NetworkFailure(
        message: 'No internet connection. Cannot download media.',
      )));
    });

    test('should download and cache media when not cached and online', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedMediaPath(any()))
          .thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.downloadMedia(
        url: any(named: 'url'),
        savePath: any(named: 'savePath'),
        onProgress: any(named: 'onProgress'),
      )).thenAnswer((_) async => tDownloadedPath);
      when(() => mockLocalDataSource.cacheMedia(
        sourceFilePath: any(named: 'sourceFilePath'),
        attachmentId: any(named: 'attachmentId'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => tCachedPath);

      // Act
      final result = await repository.downloadMedia(
        url: tUrl,
        attachmentId: tAttachmentId,
        type: tType,
      );

      // Assert
      expect(result, const Right(tCachedPath));
      verify(() => mockRemoteDataSource.downloadMedia(
        url: tUrl,
        savePath: '/tmp/$tAttachmentId',
        onProgress: any(named: 'onProgress'),
      )).called(1);
      verify(() => mockLocalDataSource.cacheMedia(
        sourceFilePath: tDownloadedPath,
        attachmentId: tAttachmentId,
        type: tType,
      )).called(1);
    });

    test('should return NetworkFailure when download throws NetworkException', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedMediaPath(any()))
          .thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.downloadMedia(
        url: any(named: 'url'),
        savePath: any(named: 'savePath'),
        onProgress: any(named: 'onProgress'),
      )).thenThrow(const NetworkException(message: 'Download failed'));

      // Act
      final result = await repository.downloadMedia(
        url: tUrl,
        attachmentId: tAttachmentId,
        type: tType,
      );

      // Assert
      expect(result, const Left(NetworkFailure(message: 'Download failed')));
    });
  });

  group('getCachedMediaPath', () {
    const tAttachmentId = 'attachment-123';
    const tCachedPath = '/cache/path/file.jpg';

    test('should return cached path when available', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedMediaPath(any()))
          .thenAnswer((_) async => tCachedPath);

      // Act
      final result = await repository.getCachedMediaPath(tAttachmentId);

      // Assert
      expect(result, const Right(tCachedPath));
      verify(() => mockLocalDataSource.getCachedMediaPath(tAttachmentId)).called(1);
    });

    test('should return null when not cached', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedMediaPath(any()))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getCachedMediaPath(tAttachmentId);

      // Assert
      expect(result, const Right(null));
    });

    test('should return CacheFailure when CacheException is thrown', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedMediaPath(any()))
          .thenThrow(const CacheException(message: 'Cache error'));

      // Act
      final result = await repository.getCachedMediaPath(tAttachmentId);

      // Assert
      expect(result, const Left(CacheFailure(message: 'Cache error')));
    });
  });

  group('deleteCachedMedia', () {
    const tAttachmentId = 'attachment-123';

    test('should delete cached media successfully', () async {
      // Arrange
      when(() => mockLocalDataSource.deleteCachedMedia(any()))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteCachedMedia(tAttachmentId);

      // Assert
      expect(result, const Right(null));
      verify(() => mockLocalDataSource.deleteCachedMedia(tAttachmentId)).called(1);
    });

    test('should return CacheFailure when deletion fails', () async {
      // Arrange
      when(() => mockLocalDataSource.deleteCachedMedia(any()))
          .thenThrow(const CacheException(message: 'Delete failed'));

      // Act
      final result = await repository.deleteCachedMedia(tAttachmentId);

      // Assert
      expect(result, const Left(CacheFailure(message: 'Delete failed')));
    });
  });

  group('clearMediaCache', () {
    test('should clear cache successfully', () async {
      // Arrange
      when(() => mockLocalDataSource.clearMediaCache())
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.clearMediaCache();

      // Assert
      expect(result, const Right(null));
      verify(() => mockLocalDataSource.clearMediaCache()).called(1);
    });

    test('should return CacheFailure when clear fails', () async {
      // Arrange
      when(() => mockLocalDataSource.clearMediaCache())
          .thenThrow(const CacheException(message: 'Clear failed'));

      // Act
      final result = await repository.clearMediaCache();

      // Assert
      expect(result, const Left(CacheFailure(message: 'Clear failed')));
    });
  });

  group('getCacheSize', () {
    const tCacheSize = 1024000;

    test('should return cache size successfully', () async {
      // Arrange
      when(() => mockLocalDataSource.getCacheSize())
          .thenAnswer((_) async => tCacheSize);

      // Act
      final result = await repository.getCacheSize();

      // Assert
      expect(result, const Right(tCacheSize));
      verify(() => mockLocalDataSource.getCacheSize()).called(1);
    });

    test('should return CacheFailure when getting size fails', () async {
      // Arrange
      when(() => mockLocalDataSource.getCacheSize())
          .thenThrow(const CacheException(message: 'Size calculation failed'));

      // Act
      final result = await repository.getCacheSize();

      // Assert
      expect(result, const Left(CacheFailure(message: 'Size calculation failed')));
    });
  });

  group('getAttachment', () {
    const tAttachmentId = 'attachment-123';
    final tAttachmentModel = AttachmentModel(
      id: tAttachmentId,
      name: 'file.jpg',
      type: AttachmentType.image,
      mimeType: 'image/jpeg',
      size: 1024,
      url: 'https://example.com/file.jpg',
    );

    test('should return cached attachment metadata if available', () async {
      // Arrange
      when(() => mockLocalDataSource.getAttachmentMetadata(any()))
          .thenAnswer((_) async => tAttachmentModel);

      // Act
      final result = await repository.getAttachment(tAttachmentId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (attachment) => expect(attachment.id, tAttachmentId),
      );
      verify(() => mockLocalDataSource.getAttachmentMetadata(tAttachmentId)).called(1);
      verifyNever(() => mockNetworkInfo.isConnected);
    });

    test('should return NetworkFailure when not cached and offline', () async {
      // Arrange
      when(() => mockLocalDataSource.getAttachmentMetadata(any()))
          .thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getAttachment(tAttachmentId);

      // Assert
      expect(result, const Left(NetworkFailure(
        message: 'No internet connection and attachment not cached.',
      )));
    });

    test('should fetch from remote and cache when not cached and online', () async {
      // Arrange
      when(() => mockLocalDataSource.getAttachmentMetadata(any()))
          .thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getAttachment(any()))
          .thenAnswer((_) async => tAttachmentModel);
      when(() => mockLocalDataSource.saveAttachmentMetadata(any()))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.getAttachment(tAttachmentId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.getAttachment(tAttachmentId)).called(1);
      verify(() => mockLocalDataSource.saveAttachmentMetadata(tAttachmentModel)).called(1);
    });
  });

  group('getMessageAttachments', () {
    const tMessageId = 'msg-123';
    final tAttachmentModels = [
      AttachmentModel(
        id: 'att-1',
        name: 'file1.jpg',
        type: AttachmentType.image,
        mimeType: 'image/jpeg',
        size: 1024,
      ),
      AttachmentModel(
        id: 'att-2',
        name: 'file2.jpg',
        type: AttachmentType.image,
        mimeType: 'image/jpeg',
        size: 2048,
      ),
    ];

    test('should return empty list when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getMessageAttachments(tMessageId);

      // Assert
      expect(result, const Right([]));
      verifyNever(() => mockRemoteDataSource.getMessageAttachments(any()));
    });

    test('should fetch and cache attachments when online', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getMessageAttachments(any()))
          .thenAnswer((_) async => tAttachmentModels);
      when(() => mockLocalDataSource.saveAttachmentMetadata(any()))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.getMessageAttachments(tMessageId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (attachments) => expect(attachments.length, 2),
      );
      verify(() => mockRemoteDataSource.getMessageAttachments(tMessageId)).called(1);
      verify(() => mockLocalDataSource.saveAttachmentMetadata(any())).called(2);
    });

    test('should continue even if caching individual attachments fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getMessageAttachments(any()))
          .thenAnswer((_) async => tAttachmentModels);
      when(() => mockLocalDataSource.saveAttachmentMetadata(any()))
          .thenThrow(const CacheException(message: 'Cache failed'));

      // Act
      final result = await repository.getMessageAttachments(tMessageId);

      // Assert
      expect(result.isRight(), true);
    });
  });

  group('getChatAttachments', () {
    const tChatId = 'chat-123';
    const tType = AttachmentType.image;
    final tAttachmentModels = [
      AttachmentModel(
        id: 'att-1',
        name: 'file1.jpg',
        type: AttachmentType.image,
        mimeType: 'image/jpeg',
        size: 1024,
      ),
    ];

    test('should return empty list when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getChatAttachments(chatId: tChatId);

      // Assert
      expect(result, const Right([]));
    });

    test('should fetch and cache chat attachments when online', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getChatAttachments(
        chatId: any(named: 'chatId'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => tAttachmentModels);
      when(() => mockLocalDataSource.saveAttachmentMetadata(any()))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.getChatAttachments(
        chatId: tChatId,
        type: tType,
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.getChatAttachments(
        chatId: tChatId,
        type: tType,
      )).called(1);
    });
  });
}
