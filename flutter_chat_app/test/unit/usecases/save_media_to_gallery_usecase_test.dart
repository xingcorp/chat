import 'dart:typed_data';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:flutter_chat_app/domain/services/i_media_gallery_saver.dart';
import 'package:flutter_chat_app/domain/usecases/media/save_media_to_gallery_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaRepository extends Mock implements IMediaRepository {}

class MockMediaGallerySaver extends Mock implements IMediaGallerySaver {}

void main() {
  late MockMediaRepository mediaRepository;
  late MockMediaGallerySaver gallerySaver;
  late SaveMediaToGalleryUseCase useCase;

  setUp(() {
    mediaRepository = MockMediaRepository();
    gallerySaver = MockMediaGallerySaver();
    useCase = SaveMediaToGalleryUseCase(
      mediaRepository: mediaRepository,
      gallerySaver: gallerySaver,
      logger: AppLogger(),
    );
  });

  test('returns unsupported failure when gallery save is not supported',
      () async {
    when(() => gallerySaver.isSupported).thenReturn(false);

    final result = await useCase(
      const SaveMediaToGalleryParams(
        url: 'https://example.com/image.jpg',
        mediaType: GalleryMediaType.image,
      ),
    );

    expect(result.isLeft, true);
    expect(result.left, isA<DownloadFailure>());
    expect(result.left.code, 'unsupported_platform');
    verifyNever(() => gallerySaver.ensureAccess());
  });

  test('returns permission failure when access is denied', () async {
    when(() => gallerySaver.isSupported).thenReturn(true);
    when(() => gallerySaver.ensureAccess()).thenAnswer(
      (_) async => const Left(
        PermissionFailure(
          message: 'Gallery permission denied.',
          code: 'access_denied',
        ),
      ),
    );

    final result = await useCase(
      const SaveMediaToGalleryParams(
        url: 'https://example.com/image.jpg',
        mediaType: GalleryMediaType.image,
      ),
    );

    expect(result.isLeft, true);
    expect(result.left, isA<PermissionFailure>());
    verify(() => gallerySaver.ensureAccess()).called(1);
    verifyNever(() => mediaRepository.downloadMedia(
          url: any(named: 'url'),
          attachmentId: any(named: 'attachmentId'),
          type: AttachmentType.image,
        ));
  });

  test('downloads image then saves from local path', () async {
    when(() => gallerySaver.isSupported).thenReturn(true);
    when(() => gallerySaver.ensureAccess()).thenAnswer(
      (_) async => const Right(null),
    );
    when(() => mediaRepository.downloadMedia(
          url: 'https://example.com/image.jpg',
          attachmentId: 'media-1',
          type: AttachmentType.image,
        )).thenAnswer((_) async => const Right('/tmp/image.jpg'));
    when(() => gallerySaver.saveImageFromPath(
          path: '/tmp/image.jpg',
          album: SaveMediaToGalleryUseCase.defaultAlbum,
        )).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      const SaveMediaToGalleryParams(
        url: 'https://example.com/image.jpg',
        mediaType: GalleryMediaType.image,
        mediaId: 'media-1',
      ),
    );

    expect(result.isRight, true);
    verify(() => mediaRepository.downloadMedia(
          url: 'https://example.com/image.jpg',
          attachmentId: 'media-1',
          type: AttachmentType.image,
        )).called(1);
    verify(() => gallerySaver.saveImageFromPath(
          path: '/tmp/image.jpg',
          album: SaveMediaToGalleryUseCase.defaultAlbum,
        )).called(1);
  });

  test('saves image directly from bytes', () async {
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);

    when(() => gallerySaver.isSupported).thenReturn(true);
    when(() => gallerySaver.ensureAccess()).thenAnswer(
      (_) async => const Right(null),
    );
    when(() => gallerySaver.saveImageFromBytes(
          bytes: bytes,
          name: 'edited.jpg',
          album: SaveMediaToGalleryUseCase.defaultAlbum,
        )).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      SaveMediaToGalleryParams(
        bytes: bytes,
        fileName: 'edited.jpg',
        mediaType: GalleryMediaType.image,
      ),
    );

    expect(result.isRight, true);
    verifyNever(() => mediaRepository.downloadMedia(
          url: any(named: 'url'),
          attachmentId: any(named: 'attachmentId'),
          type: AttachmentType.image,
        ));
    verify(() => gallerySaver.saveImageFromBytes(
          bytes: bytes,
          name: 'edited.jpg',
          album: SaveMediaToGalleryUseCase.defaultAlbum,
        )).called(1);
  });

  test('saves video from existing local path', () async {
    when(() => gallerySaver.isSupported).thenReturn(true);
    when(() => gallerySaver.ensureAccess()).thenAnswer(
      (_) async => const Right(null),
    );
    when(() => gallerySaver.saveVideoFromPath(
          path: '/tmp/video.mp4',
          album: SaveMediaToGalleryUseCase.defaultAlbum,
        )).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      const SaveMediaToGalleryParams(
        localPath: '/tmp/video.mp4',
        mediaType: GalleryMediaType.video,
      ),
    );

    expect(result.isRight, true);
    verify(() => gallerySaver.saveVideoFromPath(
          path: '/tmp/video.mp4',
          album: SaveMediaToGalleryUseCase.defaultAlbum,
        )).called(1);
    verifyNever(() => mediaRepository.downloadMedia(
          url: any(named: 'url'),
          attachmentId: any(named: 'attachmentId'),
          type: AttachmentType.video,
        ));
  });
}
