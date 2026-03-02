import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';
import 'package:flutter_chat_app/domain/usecases/media/download_file_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFileDownloader extends Mock implements IFileDownloader {}

void main() {
  late MockFileDownloader fileDownloader;
  late DownloadFileUseCase useCase;

  setUp(() {
    fileDownloader = MockFileDownloader();
    useCase = DownloadFileUseCase(fileDownloader);
  });

  test('delegates download request to IFileDownloader', () async {
    when(
      () => fileDownloader.downloadFromUrl(
        url: 'https://example.com/document.xlsx',
        fileName: 'document.xlsx',
        headers: null,
      ),
    ).thenAnswer((_) async => const Right('task-1'));

    final result = await useCase(
      const DownloadFileParams(
        url: 'https://example.com/document.xlsx',
        fileName: 'document.xlsx',
      ),
    );

    expect(result.isRight, true);
    expect(result.right, 'task-1');
    verify(
      () => fileDownloader.downloadFromUrl(
        url: 'https://example.com/document.xlsx',
        fileName: 'document.xlsx',
        headers: null,
      ),
    ).called(1);
  });

  test('returns failure from downloader', () async {
    when(
      () => fileDownloader.downloadFromUrl(
        url: 'https://example.com/document.xlsx',
        fileName: null,
        headers: null,
      ),
    ).thenAnswer(
      (_) async => const Left(
        DownloadFailure(
          message: 'Download failed.',
          code: 'download_failed',
        ),
      ),
    );

    final result = await useCase(
      const DownloadFileParams(
        url: 'https://example.com/document.xlsx',
      ),
    );

    expect(result.isLeft, true);
    expect(result.left, isA<DownloadFailure>());
  });
}
