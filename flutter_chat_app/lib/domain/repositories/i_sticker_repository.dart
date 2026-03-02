import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';

/// Repository contract for sticker data and recently used state.
abstract class IStickerRepository {
  /// Load available sticker packs from local config.
  Future<Either<Failure, List<StickerPack>>> getAvailablePacks();

  /// Load recently used stickers from local storage.
  Future<Either<Failure, List<Sticker>>> getRecentlyUsed();

  /// Add a sticker to recently used list.
  Future<void> addToRecentlyUsed(Sticker sticker);

  /// Resolve sticker metadata by sticker code.
  Sticker? resolveSticker(String code);
}
