import 'package:equatable/equatable.dart';

/// Sticker item metadata.
class Sticker extends Equatable {
  /// Unique sticker code (e.g. emotions_happy).
  final String code;

  /// URL or asset path to sticker image.
  final String imageUrl;

  const Sticker({
    required this.code,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [code, imageUrl];
}

/// Sticker pack metadata.
class StickerPack extends Equatable {
  /// Unique pack id.
  final String id;

  /// Localized display name from config.
  final String name;

  /// URL or asset path for pack icon.
  final String thumbnailUrl;

  /// Stickers in this pack.
  final List<Sticker> stickers;

  const StickerPack({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.stickers,
  });

  @override
  List<Object?> get props => [id, name, thumbnailUrl, stickers];
}
