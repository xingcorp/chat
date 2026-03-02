import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/sticker/sticker_local_datasource.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';
import 'package:flutter_chat_app/domain/repositories/i_sticker_repository.dart';
import 'package:injectable/injectable.dart';

/// Sticker repository implementation backed by local json + shared preferences.
@LazySingleton(as: IStickerRepository)
class StickerRepositoryImpl implements IStickerRepository {
  StickerRepositoryImpl(
    this._localDataSource,
    this._logger,
  );

  final StickerLocalDataSource _localDataSource;
  final AppLogger _logger;

  List<StickerPack> _packs = const <StickerPack>[];
  final Map<String, Sticker> _cacheByCode = <String, Sticker>{};

  @override
  Future<Either<Failure, List<StickerPack>>> getAvailablePacks() async {
    try {
      final packs = await _localDataSource.getAvailablePacks();
      _packs = packs;
      _cacheByCode
        ..clear()
        ..addEntries(
          packs.expand((pack) => pack.stickers).map((sticker) => MapEntry(sticker.code, sticker)),
        );
      return Right<Failure, List<StickerPack>>(packs);
    } catch (error, stackTrace) {
      _logger.e('Failed to load sticker packs', error: error, stackTrace: stackTrace);
      return Left<Failure, List<StickerPack>>(
        CacheFailure(message: 'Failed to load sticker packs: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Sticker>>> getRecentlyUsed() async {
    try {
      if (_packs.isEmpty) {
        final packsEither = await getAvailablePacks();
        if (packsEither.isLeft) {
          return Left<Failure, List<Sticker>>(packsEither.left);
        }
      }

      final codes = await _localDataSource.getRecentlyUsedCodes();
      final stickers = <Sticker>[];
      for (final code in codes) {
        final resolved = resolveSticker(code);
        if (resolved != null) {
          stickers.add(resolved);
        }
      }
      return Right<Failure, List<Sticker>>(stickers);
    } catch (error, stackTrace) {
      _logger.e('Failed to load recently used stickers', error: error, stackTrace: stackTrace);
      return Left<Failure, List<Sticker>>(
        CacheFailure(message: 'Failed to load recently used stickers: $error'),
      );
    }
  }

  @override
  Future<void> addToRecentlyUsed(Sticker sticker) async {
    try {
      final current = await _localDataSource.getRecentlyUsedCodes();
      final updated = <String>[sticker.code, ...current.where((code) => code != sticker.code)];
      await _localDataSource.saveRecentlyUsedCodes(updated);
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to persist recently used sticker',
        error: error,
        stackTrace: stackTrace,
        context: <String, dynamic>{'stickerCode': sticker.code},
      );
    }
  }

  @override
  Sticker? resolveSticker(String code) {
    if (_cacheByCode.isNotEmpty) {
      return _cacheByCode[code];
    }
    return _localDataSource.resolveSticker(code);
  }
}
