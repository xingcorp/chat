import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Widget hiển thị media gallery cho message attachments
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
class MediaGallery extends StatelessWidget {
  /// Danh sách attachments
  final List<MessageAttachment> attachments;

  /// Layout mode: grid hoặc list
  final MediaGalleryLayout layout;

  const MediaGallery({
    Key? key,
    required this.attachments,
    this.layout = MediaGalleryLayout.grid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    // Lọc attachments theo type
    final images = attachments.where((a) => a.type == 'image').toList();
    final videos = attachments.where((a) => a.type == 'video').toList();
    final files = attachments.where((a) =>
        a.type != 'image' && a.type != 'video').toList();

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

    if (images.length == 1) {
      // Single image: full width
      return _buildImageTile(
        context,
        images[0],
        index: 0,
        width: double.infinity,
        height: 220,
        borderRadius: borderRadius,
      );
    } else if (images.length == 2) {
      // Two images: 2 columns
      return Row(
        children: [
          Expanded(
            child: _buildImageTile(
              context,
              images[0],
              index: 0,
              height: 160,
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
              height: 160,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
          ),
        ],
      );
    } else {
      // 3+ images: 2x2 grid với counter cho thêm
      final displayImages = images.take(4).toList();
      final remaining = images.length - 4;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row
          Row(
            children: [
              Expanded(
                child: _buildImageTile(
                  context,
                  displayImages[0],
                  index: 0,
                  height: 120,
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
                  height: 120,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          // Second row
          Row(
            children: [
              Expanded(
                child: _buildImageTile(
                  context,
                  displayImages[2],
                  index: 2,
                  height: 120,
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
                        height: 120,
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
  }

  /// Build single image tile
  Widget _buildImageTile(
    BuildContext context,
    MessageAttachment image, {
    required int index,
    double? width,
    required double height,
    BorderRadius? borderRadius,
    Widget? overlay,
  }) {
    return GestureDetector(
      onTap: () => _openFullscreenGallery(
        context,
        attachments: attachments.where((a) => a.type == 'image').toList(),
        initialIndex: index,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: image.url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            if (overlay != null) overlay,
          ],
        ),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: _buildFileTile(context, file),
        );
      }).toList(),
    );
  }

  /// Build single file tile
  Widget _buildFileTile(BuildContext context, MessageAttachment file) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // TODO: Download file
        debugPrint('File tapped: ${file.url}');
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(file.type),
              color: theme.colorScheme.primary,
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
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    _formatFileSize(file.size),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: theme.iconTheme.color?.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
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

  /// Open fullscreen gallery
  void _openFullscreenGallery(
    BuildContext context, {
    required List<MessageAttachment> attachments,
    required int initialIndex,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenGallery(
          attachments: attachments,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Fullscreen gallery với swipe navigation
class FullscreenGallery extends StatefulWidget {
  final List<MessageAttachment> attachments;
  final int initialIndex;

  const FullscreenGallery({
    Key? key,
    required this.attachments,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.attachments.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Download current image
              debugPrint('Download: ${widget.attachments[_currentIndex].url}');
            },
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
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
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
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
