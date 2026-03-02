import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local data source for sticker packs and recently used stickers.
@lazySingleton
class StickerLocalDataSource {
  StickerLocalDataSource(this._preferences, this._logger)
      : _assetBundle = rootBundle;

  @visibleForTesting
  StickerLocalDataSource.test(
    this._preferences,
    this._logger,
    this._assetBundle,
  );

  static const String _stickerPacksAssetPath =
      'assets/stickers/sticker_packs.json';
  static const String _recentlyUsedStickersKey = 'recently_used_stickers';
  static const int _recentlyUsedLimit = 24;

  final SharedPreferences _preferences;
  final AppLogger _logger;
  final AssetBundle _assetBundle;

  List<StickerPack>? _cachedPacks;
  final Map<String, Sticker> _stickerByCode = <String, Sticker>{};

  /// Load sticker packs from bundled json config.
  Future<List<StickerPack>> getAvailablePacks() async {
    if (_cachedPacks != null) {
      return _cachedPacks!;
    }

    final rawJson = await _assetBundle.loadString(_stickerPacksAssetPath);
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Invalid sticker packs json: root is not an object.');
    }

    final packsRaw = decoded['packs'];
    if (packsRaw is! List) {
      throw const FormatException(
          'Invalid sticker packs json: packs must be a list.');
    }

    final packs = <StickerPack>[];
    _stickerByCode.clear();

    for (final packRaw in packsRaw) {
      if (packRaw is! Map<String, dynamic>) {
        continue;
      }

      final id = (packRaw['id'] as String?)?.trim();
      final name = (packRaw['name'] as String?)?.trim();
      final thumbnail = (packRaw['thumbnail'] as String?)?.trim();
      final stickersRaw = packRaw['stickers'];

      if (id == null ||
          id.isEmpty ||
          name == null ||
          name.isEmpty ||
          thumbnail == null ||
          thumbnail.isEmpty) {
        continue;
      }
      if (stickersRaw is! List) {
        continue;
      }

      final stickers = <Sticker>[];
      for (final stickerRaw in stickersRaw) {
        if (stickerRaw is! Map<String, dynamic>) {
          continue;
        }

        final code = (stickerRaw['code'] as String?)?.trim();
        final url = (stickerRaw['url'] as String?)?.trim();
        if (code == null || code.isEmpty || url == null || url.isEmpty) {
          continue;
        }

        final sticker = Sticker(code: code, imageUrl: url);
        stickers.add(sticker);
        _stickerByCode[code] = sticker;
      }

      if (stickers.isEmpty) {
        continue;
      }

      packs.add(
        StickerPack(
          id: id,
          name: name,
          thumbnailUrl: thumbnail,
          stickers: stickers,
        ),
      );
    }

    _cachedPacks = packs;
    return packs;
  }

  /// Resolve sticker by code from in-memory map.
  Sticker? resolveSticker(String code) {
    return _stickerByCode[code];
  }

  /// Load recently used sticker codes.
  Future<List<String>> getRecentlyUsedCodes() async {
    return _preferences.getStringList(_recentlyUsedStickersKey) ??
        const <String>[];
  }

  /// Persist recently used sticker codes.
  Future<void> saveRecentlyUsedCodes(List<String> codes) async {
    final trimmed = codes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(_recentlyUsedLimit)
        .toList(growable: false);
    await _preferences.setStringList(_recentlyUsedStickersKey, trimmed);
  }

  /// Ensure pack cache is initialized, used before sync resolve calls.
  Future<void> warmUp() async {
    if (_cachedPacks != null) {
      return;
    }
    try {
      await getAvailablePacks();
    } catch (error) {
      _logger.w('Failed to warm up sticker packs: $error');
    }
  }
}
