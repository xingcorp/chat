import 'dart:typed_data';

/// Result returned from image viewer when user edits and sends an image.
class EditedImageResult {
  final Uint8List bytes;
  final String fileName;

  const EditedImageResult({
    required this.bytes,
    required this.fileName,
  });
}
