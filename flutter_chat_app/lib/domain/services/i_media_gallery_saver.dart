import 'dart:typed_data';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// Interface for saving media files to the system gallery.
///
/// This abstraction keeps UI and use cases independent from a concrete plugin.
abstract class IMediaGallerySaver {
  /// Whether the current platform supports gallery save operations.
  bool get isSupported;

  /// Ensures the app has permission to write into the gallery/photo library.
  Future<Either<Failure, void>> ensureAccess();

  /// Saves an image file from a local file path.
  Future<Either<Failure, void>> saveImageFromPath({
    required String path,
    String? album,
  });

  /// Saves an image directly from in-memory bytes.
  Future<Either<Failure, void>> saveImageFromBytes({
    required Uint8List bytes,
    required String name,
    String? album,
  });

  /// Saves a video file from a local file path.
  Future<Either<Failure, void>> saveVideoFromPath({
    required String path,
    String? album,
  });
}
