import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/image_editor_service.dart';
import 'package:flutter_chat_app/domain/usecases/media/save_media_to_gallery_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reaction_bar.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/forward_message_sheet.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/menus/app_popup_menu.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';

final Map<String, double> _imageAspectRatioCache = {};

/// Widget hiển thị media gallery cho message attachments
/// Result returned from FullscreenGallery when user edits an image
class EditedImageResult {
  final Uint8List bytes;
  final String fileName;

  const EditedImageResult({required this.bytes, required this.fileName});
}

///
/// Khớp với:
/// - Angular: urls[] array rendering per ChatMessageType
/// - stream_chat_flutter: gallery_attachment patterns
///
/// Features:
/// - Image grid: 1 = full width, 2 = 2 columns, 3+ = 2x2 grid + counter
/// - Video thumbnails với play icon
/// - Tap → fullscreen gallery với swipe
/// - Zoom/pinch support
/// - Optional ChatMessage for reactions and forwarding
class MediaGallery extends StatelessWidget {
  /// Danh sách attachments
  final List<MessageAttachment> attachments;

  /// Layout mode: grid hoặc list
  final MediaGalleryLayout layout;

  /// Optional ChatMessage for reactions and forwarding in fullscreen view
  final ChatMessage? message;

  /// Chat ID for forwarding
  final String? chatId;

  final bool isFromCurrentUser;

  final bool isOnPrimaryBackground;

  /// Callback when user edits an image and wants to send it
  final void Function(Uint8List editedBytes, String fileName)?
      onEditedImageSend;

  const MediaGallery({
    Key? key,
    required this.attachments,
    this.layout = MediaGalleryLayout.grid,
    this.message,
    this.chatId,
    this.isFromCurrentUser = false,
    this.isOnPrimaryBackground = false,
    this.onEditedImageSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    // Lọc attachments theo type
    final images = attachments.where((a) => a.type == 'image').toList();
    final videos = attachments.where((a) => a.type == 'video').toList();
    final files = attachments
        .where((a) => a.type != 'image' && a.type != 'video')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image grid
        if (images.isNotEmpty) _buildImageGrid(context, images),

        // Video list
        if (videos.isNotEmpty) ...[
          if (images.isNotEmpty) const SizedBox(height: 8.0),
          _buildVideoList(context, videos),
        ],

        // File list
        if (files.isNotEmpty) ...[
          if (images.isNotEmpty || videos.isNotEmpty)
            const SizedBox(height: 8.0),
          _buildFileList(context, files),
        ],
      ],
    );
  }

  /// Build image grid với adaptive layout
  Widget _buildImageGrid(BuildContext context, List<MessageAttachment> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    const borderRadius = BorderRadius.all(Radius.circular(8.0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final isDesktop = availableWidth >= AppDimens.breakpointDesktop;

        double clamp(double v, double min, double max) {
          if (v < min) return min;
          if (v > max) return max;
          return v;
        }

        final twoColTileHeight =
            isDesktop ? clamp((availableWidth - 4) * 0.32, 160, 240) : 160.0;
        final gridTileHeight =
            isDesktop ? clamp((availableWidth - 4) * 0.24, 120, 200) : 120.0;

        if (images.length == 1) {
          return _SmartSingleImageTile(
            image: images[0],
            borderRadius: borderRadius,
            onTap: () => _openFullscreenGallery(
              context,
              attachments: attachments.where((a) => a.type == 'image').toList(),
              initialIndex: 0,
            ),
          );
        } else if (images.length == 2) {
          return Row(
            children: [
              Expanded(
                child: _buildImageTile(
                  context,
                  images[0],
                  index: 0,
                  height: twoColTileHeight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: _buildImageTile(
                  context,
                  images[1],
                  index: 1,
                  height: twoColTileHeight,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                ),
              ),
            ],
          );
        } else {
          final displayImages = images.take(4).toList();
          final remaining = images.length - 4;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildImageTile(
                      context,
                      displayImages[0],
                      index: 0,
                      height: gridTileHeight,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: _buildImageTile(
                      context,
                      displayImages[1],
                      index: 1,
                      height: gridTileHeight,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Expanded(
                    child: _buildImageTile(
                      context,
                      displayImages[2],
                      index: 2,
                      height: gridTileHeight,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: displayImages.length > 3
                        ? _buildImageTile(
                            context,
                            displayImages[3],
                            index: 3,
                            height: gridTileHeight,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(8.0),
                            ),
                            overlay: remaining > 0
                                ? Container(
                                    color: Colors.black54,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '+$remaining',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  /// Build single image tile
  /// Supports both network URLs and local file paths during upload
  Widget _buildImageTile(
    BuildContext context,
    MessageAttachment image, {
    required int index,
    double? width,
    double? height,
    double? maxHeight,
    BorderRadius? borderRadius,
    Widget? overlay,
    BoxFit fit = BoxFit.cover,
  }) {
    final hasLocalPath = image.localPath != null && image.localPath!.isNotEmpty;
    final hasUrl = image.url.isNotEmpty;
    final isUploading = image.isUploading;
    final uploadProgress = image.uploadProgress ?? 0.0;

    // Choose image source: local file first, then network URL
    Widget imageWidget;
    if (hasLocalPath) {
      // Use local file (during upload or cached)
      imageWidget = Image.file(
        File(image.localPath!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height ?? maxHeight ?? 150,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else if (hasUrl) {
      // Use network image
      imageWidget = CachedNetworkImage(
        imageUrl: image.url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height ?? maxHeight ?? 150,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height ?? maxHeight ?? 150,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      // No image source - show placeholder
      imageWidget = Container(
        width: width,
        height: height ?? maxHeight ?? 150,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
      );
    }

    if (maxHeight != null) {
      imageWidget = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: imageWidget,
      );
    }

    return GestureDetector(
      onTap: isUploading
          ? null // Disable tap during upload
          : () => _openFullscreenGallery(
                context,
                attachments:
                    attachments.where((a) => a.type == 'image').toList(),
                initialIndex: index,
              ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Stack(
          children: [
            imageWidget,
            // Upload progress overlay
            if (isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: _buildUploadProgressIndicator(uploadProgress),
                  ),
                ),
              ),
            if (overlay != null) overlay,
          ],
        ),
      ),
    );
  }

  /// Build circular upload progress indicator (like WhatsApp/Telegram)
  Widget _buildUploadProgressIndicator(double progress) {
    final percentage = (progress * 100).toInt();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null, // Indeterminate if 0
              strokeWidth: 3.0,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          if (progress > 0)
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// Build video list
  Widget _buildVideoList(BuildContext context, List<MessageAttachment> videos) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: videos.map((video) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: _buildVideoTile(context, video),
        );
      }).toList(),
    );
  }

  /// Build single video tile
  Widget _buildVideoTile(BuildContext context, MessageAttachment video) {
    return GestureDetector(
      onTap: () {
        // TODO: Open video player
        debugPrint('Video tapped: ${video.url}');
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            // Video thumbnail (nếu có)
            if (video.url.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: video.url,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[800],
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            // Play icon overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build file list
  Widget _buildFileList(BuildContext context, List<MessageAttachment> files) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: files.map((file) {
        return _buildFileTile(context, file);
      }).toList(),
    );
  }

  /// Build single file tile
  /// Supports upload progress indicator like image tiles
  Widget _buildFileTile(BuildContext context, MessageAttachment file) {
    final theme = Theme.of(context);
    final isUploading = file.isUploading;
    final uploadProgress = file.uploadProgress ?? 0.0;

    // Follow same pattern as ReplyPreview, LinkPreviewCard:
    // - on primary bubble -> use white/onPrimary colors
    // - isFromCurrentUser == false -> use theme neutral colors
    final tileBackgroundColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;

    final primaryIconColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
        : theme.colorScheme.primary;

    final titleTextStyle = isOnPrimaryBackground
        ? theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          )
        : theme.textTheme.bodyMedium;

    final subTextColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);

    final downloadIconColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
        : theme.iconTheme.color?.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: isUploading
          ? null // Disable tap during upload
          : () => _saveAttachmentToGallery(context, file),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        color: tileBackgroundColor,
        child: Row(
          children: [
            // File icon or upload progress indicator
            if (isUploading)
              _buildFileUploadProgressIndicator(uploadProgress)
            else
              Icon(
                _getFileIcon(file.type),
                color: primaryIconColor,
                size: 32,
              ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name.isNotEmpty ? file.name : 'File',
                    style: titleTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  if (isUploading)
                    // Show upload progress text
                    Text(
                      'Uploading... ${(uploadProgress * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primaryIconColor,
                      ),
                    )
                  else if (file.size > 0)
                    Text(
                      _formatFileSize(file.size),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subTextColor,
                      ),
                    ),
                ],
              ),
            ),
            if (!isUploading)
              Icon(
                Icons.download,
                color: downloadIconColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Build circular upload progress indicator for file tiles
  Widget _buildFileUploadProgressIndicator(double progress) {
    final percentage = (progress * 100).toInt();

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress > 0 ? progress : null, // Indeterminate if 0
            strokeWidth: 2.5,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
          ),
          if (progress > 0)
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// Get icon cho file type
  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return Icons.audiotrack;
      case 'location':
        return Icons.location_on;
      case 'doc':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'file':
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _saveAttachmentToGallery(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    final GalleryMediaType? mediaType = switch (attachment.type.toLowerCase()) {
      'image' => GalleryMediaType.image,
      'video' => GalleryMediaType.video,
      _ => null,
    };

    if (mediaType == null) {
      AppSnackBar.warning(
        context: context,
        message: context.l10n.unsupportedFileType,
      );
      return;
    }

    final SaveMediaToGalleryUseCase saveMediaToGallery =
        GetIt.I<SaveMediaToGalleryUseCase>();
    final result = await saveMediaToGallery(
      SaveMediaToGalleryParams(
        url: attachment.url,
        mediaType: mediaType,
        mediaId: attachment.id,
      ),
    );

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) => AppSnackBar.error(
        context: context,
        message: failure.userMessage,
      ),
      (_) => AppSnackBar.success(
        context: context,
        message: context.l10n.downloaded,
      ),
    );
  }

  /// Open fullscreen gallery
  Future<void> _openFullscreenGallery(
    BuildContext context, {
    required List<MessageAttachment> attachments,
    required int initialIndex,
  }) async {
    final result = await Navigator.push<EditedImageResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenGallery(
          attachments: attachments,
          initialIndex: initialIndex,
          message: message,
          chatId: chatId,
        ),
      ),
    );

    debugPrint(
        '[MediaGallery] FullscreenGallery popped, result=$result, onEditedImageSend=${onEditedImageSend != null}');
    // If user edited an image, callback to parent
    if (result != null && onEditedImageSend != null) {
      debugPrint(
          '[MediaGallery] calling onEditedImageSend with ${result.bytes.length} bytes');
      onEditedImageSend!(result.bytes, result.fileName);
    }
  }
}

class _SmartSingleImageTile extends StatefulWidget {
  final MessageAttachment image;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _SmartSingleImageTile({
    required this.image,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_SmartSingleImageTile> createState() => _SmartSingleImageTileState();
}

class _SmartSingleImageTileState extends State<_SmartSingleImageTile> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _SmartSingleImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = oldWidget.image.localPath ?? oldWidget.image.url;
    final newKey = widget.image.localPath ?? widget.image.url;
    if (oldKey != newKey) {
      _aspectRatio = null;
      _resolveAspectRatio();
    }
  }

  void _resolveAspectRatio() {
    final localPath = widget.image.localPath;
    final url = widget.image.url.trim();

    // Try local file first
    if (localPath != null && localPath.isNotEmpty) {
      final cached = _imageAspectRatioCache[localPath];
      if (cached != null) {
        setState(() => _aspectRatio = cached);
        return;
      }

      // Resolve from local file
      final provider = FileImage(File(localPath));
      final stream = provider.resolve(const ImageConfiguration());
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          final w = info.image.width.toDouble();
          final h = info.image.height.toDouble();
          if (w > 0 && h > 0) {
            final ar = w / h;
            _imageAspectRatioCache[localPath] = ar;
            if (mounted) setState(() => _aspectRatio = ar);
          }
          stream.removeListener(listener);
        },
        onError: (_, __) => stream.removeListener(listener),
      );
      stream.addListener(listener);
      return;
    }

    // Fall back to network URL
    if (url.isEmpty) return;

    final cached = _imageAspectRatioCache[url];
    if (cached != null) {
      setState(() => _aspectRatio = cached);
      return;
    }

    final provider = CachedNetworkImageProvider(url);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w > 0 && h > 0) {
          final ar = w / h;
          _imageAspectRatioCache[url] = ar;
          if (mounted) setState(() => _aspectRatio = ar);
        }
        stream.removeListener(listener);
      },
      onError: (_, __) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocalPath =
        widget.image.localPath != null && widget.image.localPath!.isNotEmpty;
    final hasUrl = widget.image.url.isNotEmpty;
    final isUploading = widget.image.isUploading;
    final uploadProgress = widget.image.uploadProgress ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final ar = _aspectRatio ?? 1.0;

        final double maxWidth = ar < 0.85
            ? availableWidth * 0.62
            : (ar < 1.2 ? availableWidth * 0.85 : availableWidth);

        final double maxHeight = ar < 0.85 ? 420 : 360;

        // Build image widget based on source
        Widget imageContent;
        if (hasLocalPath) {
          // Cross-platform: use Image.memory on web, Image.file on mobile
          if (kIsWeb && widget.image.localBytes != null) {
            // Web: use Image.memory with bytes
            imageContent = Image.memory(
              widget.image.localBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          } else if (!kIsWeb) {
            // Mobile: use Image.file
            imageContent = Image.file(
              File(widget.image.localPath!),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          } else {
            // Web without bytes: show placeholder
            imageContent = Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 48),
              ),
            );
          }
        } else if (hasUrl) {
          imageContent = CachedNetworkImage(
            imageUrl: widget.image.url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            placeholder: (_, __) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        } else {
          imageContent = Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
          );
        }

        return GestureDetector(
          onTap: isUploading ? null : widget.onTap,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: AspectRatio(
                aspectRatio: ar,
                child: Stack(
                  children: [
                    imageContent,
                    // Upload progress overlay
                    if (isUploading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                          child: Center(
                            child:
                                _buildUploadProgressIndicator(uploadProgress),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadProgressIndicator(double progress) {
    final percentage = (progress * 100).toInt();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 3.0,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          if (progress > 0)
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fullscreen gallery với swipe navigation
/// Supports reactions and forwarding when ChatMessage is provided
class FullscreenGallery extends StatefulWidget {
  final List<MessageAttachment> attachments;
  final int initialIndex;

  /// Optional ChatMessage for reactions and forwarding
  final ChatMessage? message;

  /// Chat ID for forwarding
  final String? chatId;

  const FullscreenGallery({
    Key? key,
    required this.attachments,
    this.initialIndex = 0,
    this.message,
    this.chatId,
  }) : super(key: key);

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  /// Group reactions by emoji code
  List<ReactionGroup> _groupReactions(List<MessageReaction> reactions) {
    final Map<String, ReactionGroup> groups = {};

    for (final reaction in reactions) {
      if (!groups.containsKey(reaction.code)) {
        groups[reaction.code] = ReactionGroup(
          code: reaction.code,
          reactorIds: [],
          reactorNameById: {},
          reactorAvatarById: {},
        );
      }
      groups[reaction.code]!.reactorIds.add(reaction.userId);
      groups[reaction.code]!.reactorNameById[reaction.userId] =
          reaction.userName ?? reaction.userId;
    }

    return groups.values.toList();
  }

  /// Show reaction picker bottom sheet
  void _showReactionPicker(BuildContext context) {
    EmojiPickerBottomSheet.show(
      context,
      onEmojiSelected: (emoji) {
        if (widget.message != null) {
          context.read<MessageBloc>().add(
                ToggleReaction(
                  messageId: widget.message!.id,
                  emojiCode: emoji,
                ),
              );
        }
      },
    );
  }

  /// Handle forward action
  void _handleForward() {
    if (widget.message == null) return;

    showForwardMessageSheet(
      context,
      messages: [widget.message!],
      sourceChatId: widget.chatId,
    );
  }

  /// Handle edit action - open image editor
  void _handleEdit() {
    final currentAttachment = widget.attachments[_currentIndex];
    final imageEditorService = GetIt.I<ImageEditorService>();

    debugPrint(
        '[FullscreenGallery] _handleEdit called, url=${currentAttachment.url}');
    imageEditorService.editNetworkImage(
      context,
      imageUrl: currentAttachment.url,
      onComplete: (bytes) {
        debugPrint(
            '[FullscreenGallery] onComplete called, bytes=${bytes.length}, mounted=${context.mounted}');
        if (!context.mounted) return;
        final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
        debugPrint('[FullscreenGallery] popping with EditedImageResult');
        // Pop back to caller with edited bytes
        Navigator.of(context).pop(
          EditedImageResult(bytes: bytes, fileName: fileName),
        );
      },
    );
  }

  Future<void> _handleDownload() async {
    final MessageAttachment currentAttachment =
        widget.attachments[_currentIndex];
    final SaveMediaToGalleryUseCase saveMediaToGallery =
        GetIt.I<SaveMediaToGalleryUseCase>();

    final result = await saveMediaToGallery(
      SaveMediaToGalleryParams(
        url: currentAttachment.url,
        mediaType: GalleryMediaType.image,
        mediaId: currentAttachment.id,
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => AppSnackBar.error(
        context: context,
        message: failure.userMessage,
      ),
      (_) => AppSnackBar.success(
        context: context,
        message: context.l10n.downloaded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMessage = widget.message != null;
    final groupedReactions = hasMessage
        ? _groupReactions(widget.message!.reactions)
        : <ReactionGroup>[];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              title: Text(
                '${_currentIndex + 1} / ${widget.attachments.length}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                AppIconButton(
                  icon: Icons.edit,
                  onPressed: () => _handleEdit(),
                  tooltip: context.l10n.edit,
                ),
                AppIconButton(
                  icon: Icons.download,
                  onPressed: _handleDownload,
                  tooltip: context.l10n.download,
                ),
                if (hasMessage)
                  AppPopupMenu<String>(
                    icon: Icons.more_vert,
                    items: [
                      PopupMenuItem(
                        value: 'forward',
                        child: Text(context.l10n.forward),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'forward') _handleForward();
                    },
                  ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleUI,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.attachments.length,
              builder: (context, index) {
                final attachment = widget.attachments[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(attachment.url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(tag: attachment.id),
                );
              },
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),

            // Bottom overlay with forward/reaction bar
            if (hasMessage && _showUI)
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16.0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            icon: Icons.forward,
                            label: context.l10n.forward,
                            onTap: _handleForward,
                          ),
                          const SizedBox(width: 24.0),
                          _buildActionButton(
                            icon: Icons.emoji_emotions_outlined,
                            label: context.l10n.addReaction,
                            onTap: () => _showReactionPicker(context),
                          ),
                        ],
                      ),

                      // Reaction bar (if any reactions exist)
                      if (groupedReactions.isNotEmpty) ...[
                        const SizedBox(height: 12.0),
                        ReactionBar(
                          groupedReactions: groupedReactions,
                          showAddButton: true,
                          onReactionTap: (
                            emojiCode,
                            reactorIds,
                            reactorNameById,
                            reactorAvatarById,
                          ) {
                            ReactionDetailModal.show(
                              context,
                              emojiCode: emojiCode,
                              reactorIds: reactorIds,
                              reactorNameById: reactorNameById,
                              reactorAvatarById: reactorAvatarById,
                            );
                          },
                          onReactionLongPress: (emojiCode, isCurrentlyReacted) {
                            if (isCurrentlyReacted && widget.message != null) {
                              context.read<MessageBloc>().add(
                                    ToggleReaction(
                                      messageId: widget.message!.id,
                                      emojiCode: emojiCode,
                                    ),
                                  );
                            }
                          },
                          onAddReaction: () => _showReactionPicker(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24.0),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layout mode cho media gallery
enum MediaGalleryLayout {
  /// Grid layout (default)
  grid,

  /// List layout
  list,
}
