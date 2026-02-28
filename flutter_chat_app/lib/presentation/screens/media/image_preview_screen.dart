import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/image_editor_service.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Result when user sends or cancels from preview
class ImagePreviewResult {
  /// The edited image bytes (null if cancelled)
  final Uint8List? editedBytes;

  /// Original file name
  final String? fileName;

  /// Whether user cancelled
  final bool isCancelled;

  const ImagePreviewResult({
    this.editedBytes,
    this.fileName,
    this.isCancelled = false,
  });

  const ImagePreviewResult.cancelled()
      : editedBytes = null,
        fileName = null,
        isCancelled = true;
}

/// Preview screen for images before sending
/// Allows editing before sending as new message
class ImagePreviewScreen extends StatefulWidget {
  /// Image file (mobile)
  final File? imageFile;

  /// Image bytes (web)
  final Uint8List? imageBytes;

  /// Image file name
  final String? fileName;

  /// Chat ID to send to
  final String chatId;

  const ImagePreviewScreen({
    Key? key,
    this.imageFile,
    this.imageBytes,
    this.fileName,
    required this.chatId,
  }) : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late Uint8List _currentBytes;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialImage();
  }

  Future<void> _loadInitialImage() async {
    if (widget.imageBytes != null) {
      _currentBytes = widget.imageBytes!;
    } else if (widget.imageFile != null && !kIsWeb) {
      _currentBytes = await widget.imageFile!.readAsBytes();
    } else {
      _currentBytes = Uint8List(0);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: AppIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(const ImagePreviewResult.cancelled()),
          tooltip: context.l10n.cancel,
        ),
        title: Text(
          context.l10n.imagePreview,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Edit button
          AppIconButton(
            icon: Icons.edit,
            onPressed: _isEditing ? null : _handleEdit,
            tooltip: context.l10n.edit,
          ),
          // Send button
          AppIconButton(
            icon: Icons.send,
            onPressed: _isEditing ? null : () => _handleSend(context),
            tooltip: context.l10n.send,
          ),
        ],
      ),
      body: _currentBytes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // Image preview
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.memory(
                      _currentBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Bottom action bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 12.0,
                      bottom: MediaQuery.of(context).padding.bottom + 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Retake button
                        _buildActionButton(
                          icon: Icons.camera_alt,
                          label: context.l10n.retake,
                          onPressed: () => Navigator.of(context).pop(const ImagePreviewResult.cancelled()),
                        ),
                        // Edit button
                        _buildActionButton(
                          icon: Icons.edit,
                          label: context.l10n.edit,
                          onPressed: _isEditing ? null : _handleEdit,
                        ),
                        // Send button
                        _buildActionButton(
                          icon: Icons.send,
                          label: context.l10n.send,
                          onPressed: _isEditing ? null : () => _handleSend(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDisabled ? Colors.grey : Colors.white,
              size: 24.0,
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? Colors.grey : Colors.white,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle edit action - open image editor
  void _handleEdit() {
    if (_isEditing) return;

    setState(() => _isEditing = true);

    final imageEditorService = GetIt.I<ImageEditorService>();

    if (widget.imageFile != null && !kIsWeb) {
      // Mobile: use local file
      imageEditorService.editLocalFile(
        context,
        file: widget.imageFile!,
        onComplete: (bytes) {
          setState(() {
            _currentBytes = bytes;
            _isEditing = false;
          });
        },
        onCancel: () {
          setState(() => _isEditing = false);
        },
      );
    } else if (_currentBytes.isNotEmpty) {
      // Use current bytes (web or edited)
      imageEditorService.editFromBytes(
        context,
        bytes: _currentBytes,
        onComplete: (bytes) {
          setState(() {
            _currentBytes = bytes;
            _isEditing = false;
          });
        },
        onCancel: () {
          setState(() => _isEditing = false);
        },
      );
    }
  }

  /// Handle send action - return result to caller
  /// Caller will handle the actual message sending with progress
  void _handleSend(BuildContext context) {
    // Pop and return the edited bytes to caller
    // Caller will send via SendMessageWithAttachments for progress display
    Navigator.of(context).pop(ImagePreviewResult(
      editedBytes: _currentBytes,
      fileName: widget.fileName,
    ));
  }
}
