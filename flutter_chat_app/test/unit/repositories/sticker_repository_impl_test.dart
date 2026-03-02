import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/sticker/sticker_local_datasource.dart';
import 'package:flutter_chat_app/data/repositories/sticker_repository_impl.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._json);

  final String _json;

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError('load() is not used in this test');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _json;
  }
}

void main() {
  const sampleJson = '''
  {
    "packs": [
      {
        "id": "emotion_classic",
        "name": "Classic",
        "thumbnail": "https://example.com/classic.png",
        "stickers": [
          {"code": "emotion_classic_happy", "url": "https://example.com/happy.png"},
          {"code": "emotion_classic_sad", "url": "https://example.com/sad.png"}
        ]
      }
    ]
  }
  ''';

  late StickerRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'recently_used_stickers': <String>['emotion_classic_sad', 'missing_code'],
    });

    final preferences = await SharedPreferences.getInstance();
    final dataSource = StickerLocalDataSource.test(
      preferences,
      AppLogger(),
      _FakeAssetBundle(sampleJson),
    );

    repository = StickerRepositoryImpl(dataSource, AppLogger());
  });

  test('loads packs and resolves sticker code', () async {
    final result = await repository.getAvailablePacks();

    expect(result.isRight, isTrue);
    expect(result.right, hasLength(1));
    expect(repository.resolveSticker('emotion_classic_happy')?.imageUrl,
        'https://example.com/happy.png');
  });

  test('returns recently used stickers and ignores unknown codes', () async {
    await repository.getAvailablePacks();

    final recent = await repository.getRecentlyUsed();

    expect(recent.isRight, isTrue);
    expect(recent.right.map((sticker) => sticker.code),
        <String>['emotion_classic_sad']);
  });

  test('adds sticker to recent list and deduplicates', () async {
    await repository.getAvailablePacks();

    await repository.addToRecentlyUsed(const Sticker(
      code: 'emotion_classic_happy',
      imageUrl: 'https://example.com/happy.png',
    ));

    final recent = await repository.getRecentlyUsed();

    expect(recent.isRight, isTrue);
    expect(recent.right.map((sticker) => sticker.code), <String>[
      'emotion_classic_happy',
      'emotion_classic_sad',
    ]);
  });
}
