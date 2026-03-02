import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/sticker/sticker_local_datasource.dart';
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
      },
      {
        "id": "animal_friends",
        "name": "Animals",
        "thumbnail": "https://example.com/animals.png",
        "stickers": [
          {"code": "animal_friends_cat", "url": "https://example.com/cat.png"}
        ]
      }
    ]
  }
  ''';

  late SharedPreferences preferences;
  late StickerLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'recently_used_stickers': <String>['emotion_classic_sad'],
    });
    preferences = await SharedPreferences.getInstance();
    dataSource = StickerLocalDataSource.test(
      preferences,
      AppLogger(),
      _FakeAssetBundle(sampleJson),
    );
  });

  test('loads sticker packs and resolves sticker by code', () async {
    final packs = await dataSource.getAvailablePacks();

    expect(packs, hasLength(2));
    expect(packs.first.stickers, hasLength(2));
    expect(dataSource.resolveSticker('emotion_classic_happy')?.imageUrl,
        'https://example.com/happy.png');
  });

  test('reads and writes recently used sticker codes', () async {
    expect(await dataSource.getRecentlyUsedCodes(),
        <String>['emotion_classic_sad']);

    await dataSource.saveRecentlyUsedCodes(<String>[
      'animal_friends_cat',
      '',
      'emotion_classic_happy',
    ]);

    expect(
      await dataSource.getRecentlyUsedCodes(),
      <String>['animal_friends_cat', 'emotion_classic_happy'],
    );
  });
}
