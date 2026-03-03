import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show immutable, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:image_picker/image_picker.dart';

@immutable
class GalleryImageSelection {
  final File file;
  final Uint8List? bytes;
  final String name;
  final int size;

  const GalleryImageSelection({
    required this.file,
    this.bytes,
    required this.name,
    required this.size,
  });
}

/// Bottom sheet for selecting attachment type
///
/// Features:
/// - Camera (take photo)
/// - Gallery (choose from photos)
/// - Video from gallery
/// - File (choose document/file)
/// - Location (share location) - placeholder for future implementation
/// - i18n support for all options
/// - Theme-aware styling
/// - Cross-platform: passes bytes on web, File on mobile
class AttachmentPickerBottomSheet extends StatelessWidget {
  static const int _maxGallerySelection = 20;

  /// Callback when image is selected from camera
  /// On web: bytes and name are provided
  final void Function(File imageFile,
      {Uint8List? bytes, String? name, int? size})? onImageFromCamera;

  /// Callback when image is selected from gallery
  /// On web: bytes and name are provided
  final void Function(File imageFile,
      {Uint8List? bytes, String? name, int? size})? onImageFromGallery;

  /// Callback when video is selected from gallery
  /// On web: bytes and name are provided
  final void Function(File videoFile,
      {Uint8List? bytes, String? name, int? size})? onVideoFromGallery;

  /// Callback when multiple images are selected from gallery
  final void Function(List<GalleryImageSelection> images)? onImagesFromGallery;

  /// Callback when file is selected (mobile: File, web: bytes + name + size)
  final void Function(File file, {Uint8List? bytes, String? name, int? size})?
      onFileSelected;

  /// Callback when location share is requested
  final VoidCallback? onLocationShare;

  const AttachmentPickerBottomSheet({
    super.key,
    this.onImageFromCamera,
    this.onImageFromGallery,
    this.onVideoFromGallery,
    this.onImagesFromGallery,
    this.onFileSelected,
    this.onLocationShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.pickAttachment,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Attachment options
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Camera option
                if (onImageFromCamera != null)
                  _buildOption(
                    context: context,
                    icon: Icons.camera_alt_outlined,
                    iconColor: Colors.blue,
                    title: l10n.takePhoto,
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromCamera(context);
                    },
                  ),

                // Gallery option
                if (onImageFromGallery != null || onImagesFromGallery != null)
                  _buildOption(
                    context: context,
                    icon: Icons.photo_library_outlined,
                    iconColor: Colors.purple,
                    title: l10n.chooseFromGallery,
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromGallery(context);
                    },
                  ),

                // Video from gallery option
                if (onVideoFromGallery != null || onFileSelected != null)
                  _buildOption(
                    context: context,
                    icon: Icons.videocam_outlined,
                    iconColor: Colors.redAccent,
                    title: '${l10n.attachmentVideo} (${l10n.gallery})',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickVideoFromGallery(context);
                    },
                  ),

                // File option
                if (onFileSelected != null)
                  _buildOption(
                    context: context,
                    icon: Icons.insert_drive_file_outlined,
                    iconColor: Colors.orange,
                    title: l10n.chooseFile,
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFile(context);
                    },
                  ),

                // Location option (placeholder)
                if (onLocationShare != null)
                  _buildOption(
                    context: context,
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.green,
                    title: l10n.shareLocation,
                    onTap: () {
                      Navigator.pop(context);
                      onLocationShare?.call();
                    },
                  ),
              ],
            ),

            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge,
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // On web, read bytes; on mobile, just use path
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = await image.readAsBytes();
        }
        onImageFromCamera?.call(
          File(image.path),
          bytes: bytes,
          name: image.name,
          size: await image.length(),
        );
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      if (context.mounted) {
        _showError(context, 'Failed to take photo');
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();

      // Use image-only APIs so "Choose from gallery" opens photo library
      // instead of Android Documents picker.
      try {
        final imageFiles = await picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
          limit: _maxGallerySelection,
        );
        if (imageFiles.isNotEmpty) {
          await _dispatchPickedGalleryMediaItems(imageFiles);
          return;
        }
      } catch (_) {
        // Some platforms may not support multi-image picker consistently.
      }

      final imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (imageFile != null) {
        await _dispatchPickedGalleryMediaItems([imageFile]);
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (context.mounted) {
        _showError(context, 'Failed to choose media');
      }
    }
  }

  Future<void> _pickVideoFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video == null) return;

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await video.readAsBytes();
      }

      final callback = onVideoFromGallery ?? onFileSelected;
      callback?.call(
        File(video.path),
        bytes: bytes,
        name: video.name,
        size: await video.length(),
      );
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
      if (context.mounted) {
        _showError(context, 'Failed to choose video');
      }
    }
  }

  Future<void> _dispatchPickedGalleryMediaItems(List<XFile> mediaFiles) async {
    final pickedItems = <_PickedMediaItem>[];

    for (final mediaFile in mediaFiles) {
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await mediaFile.readAsBytes();
      }

      final size = await mediaFile.length();
      pickedItems.add(
        _PickedMediaItem(
          file: File(mediaFile.path),
          bytes: bytes,
          name: mediaFile.name,
          size: size,
          isVideo: _isVideoMedia(
            mimeType: mediaFile.mimeType,
            fileName: mediaFile.name,
            filePath: mediaFile.path,
          ),
        ),
      );
    }

    _dispatchPickedMediaItems(pickedItems);
  }

  void _dispatchPickedMediaItems(List<_PickedMediaItem> pickedItems) {
    if (pickedItems.isEmpty) return;

    final imageItems = pickedItems.where((item) => !item.isVideo).toList();
    final videoItems = pickedItems.where((item) => item.isVideo).toList();

    if (imageItems.length > 1 && onImagesFromGallery != null) {
      onImagesFromGallery!(
        imageItems
            .map(
              (item) => GalleryImageSelection(
                file: item.file,
                bytes: item.bytes,
                name: item.name,
                size: item.size,
              ),
            )
            .toList(growable: false),
      );
    } else if (onImageFromGallery != null) {
      for (final image in imageItems) {
        onImageFromGallery?.call(
          image.file,
          bytes: image.bytes,
          name: image.name,
          size: image.size,
        );
      }
    } else if (imageItems.isNotEmpty && onImagesFromGallery != null) {
      onImagesFromGallery!(
        imageItems
            .map(
              (item) => GalleryImageSelection(
                file: item.file,
                bytes: item.bytes,
                name: item.name,
                size: item.size,
              ),
            )
            .toList(growable: false),
      );
    }

    for (final video in videoItems) {
      onFileSelected?.call(
        video.file,
        bytes: video.bytes,
        name: video.name,
        size: video.size,
      );
    }
  }

  bool _isVideoMedia({
    String? mimeType,
    required String fileName,
    required String filePath,
  }) {
    final normalizedMime = mimeType?.toLowerCase().trim();
    if (normalizedMime != null && normalizedMime.startsWith('video/')) {
      return true;
    }

    final candidate = (fileName.isNotEmpty ? fileName : filePath).toLowerCase();
    return candidate.endsWith('.mp4') ||
        candidate.endsWith('.mov') ||
        candidate.endsWith('.avi') ||
        candidate.endsWith('.mkv') ||
        candidate.endsWith('.webm') ||
        candidate.endsWith('.m4v');
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb, // Only load bytes on web platform
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (kIsWeb) {
          // Web: use bytes directly (path is unavailable on web)
          if (file.bytes != null) {
            onFileSelected?.call(
              File(''), // Dummy file for web (not used)
              bytes: file.bytes,
              name: file.name,
              size: file.size,
            );
          }
        } else {
          // Mobile: use path
          if (file.path != null) {
            onFileSelected?.call(
              File(file.path!),
              bytes: null,
              name: file.name,
              size: file.size,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (context.mounted) {
        _showError(context, 'Failed to choose file');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Static method to show the bottom sheet
  static Future<void> show(
    BuildContext context, {
    void Function(File imageFile, {Uint8List? bytes, String? name, int? size})?
        onImageFromCamera,
    void Function(File imageFile, {Uint8List? bytes, String? name, int? size})?
        onImageFromGallery,
    void Function(File videoFile, {Uint8List? bytes, String? name, int? size})?
        onVideoFromGallery,
    void Function(List<GalleryImageSelection> images)? onImagesFromGallery,
    void Function(File file, {Uint8List? bytes, String? name, int? size})?
        onFileSelected,
    VoidCallback? onLocationShare,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentPickerBottomSheet(
        onImageFromCamera: onImageFromCamera,
        onImageFromGallery: onImageFromGallery,
        onVideoFromGallery: onVideoFromGallery,
        onImagesFromGallery: onImagesFromGallery,
        onFileSelected: onFileSelected,
        onLocationShare: onLocationShare,
      ),
    );
  }
}

@immutable
class _PickedMediaItem {
  final File file;
  final Uint8List? bytes;
  final String name;
  final int size;
  final bool isVideo;

  const _PickedMediaItem({
    required this.file,
    this.bytes,
    required this.name,
    required this.size,
    required this.isVideo,
  });
}
