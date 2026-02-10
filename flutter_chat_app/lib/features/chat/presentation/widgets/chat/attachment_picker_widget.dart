import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Bottom sheet for selecting attachment type
///
/// Features:
/// - Camera (take photo)
/// - Gallery (choose from photos)
/// - File (choose document/file)
/// - Location (share location) - placeholder for future implementation
/// - i18n support for all options
/// - Theme-aware styling
class AttachmentPickerBottomSheet extends StatelessWidget {
  /// Callback when image is selected from camera
  final void Function(File imageFile)? onImageFromCamera;

  /// Callback when image is selected from gallery
  final void Function(File imageFile)? onImageFromGallery;

  /// Callback when file is selected
  final void Function(File file)? onFileSelected;

  /// Callback when location share is requested
  final VoidCallback? onLocationShare;

  const AttachmentPickerBottomSheet({
    Key? key,
    this.onImageFromCamera,
    this.onImageFromGallery,
    this.onFileSelected,
    this.onLocationShare,
  }) : super(key: key);

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
                if (onImageFromGallery != null)
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
          color: iconColor.withOpacity(0.1),
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
        onImageFromCamera?.call(File(image.path));
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
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        onImageFromGallery?.call(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (context.mounted) {
        _showError(context, 'Failed to choose photo');
      }
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      // TODO: Implement file picker when dependency is resolved
      // For now, show placeholder message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File picker will be implemented when dependency is resolved'),
          ),
        );
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
    void Function(File imageFile)? onImageFromCamera,
    void Function(File imageFile)? onImageFromGallery,
    void Function(File file)? onFileSelected,
    VoidCallback? onLocationShare,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentPickerBottomSheet(
        onImageFromCamera: onImageFromCamera,
        onImageFromGallery: onImageFromGallery,
        onFileSelected: onFileSelected,
        onLocationShare: onLocationShare,
      ),
    );
  }
}
