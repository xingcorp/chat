import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';
import 'package:flutter_chat_app/presentation/screens/media/image_viewer_screen.dart';

/// Màn hình hiển thị danh sách hình ảnh trong cuộc trò chuyện
class MediaGalleryScreen extends StatefulWidget {
  /// ID của cuộc trò chuyện
  final String chatId;

  /// Tiêu đề
  final String title;

  const MediaGalleryScreen({
    Key? key,
    required this.chatId,
    required this.title,
  }) : super(key: key);

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  /// Service cấu hình animation
  final animationService = GetIt.I<AnimationService>();

  /// Danh sách hình ảnh (sẽ thay bằng dữ liệu thật sau)
  late List<MediaItem> _mediaItems;

  /// Đang tải dữ liệu
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  /// Tải dữ liệu hình ảnh
  Future<void> _loadMedia() async {
    // Giả lập tải dữ liệu từ API hoặc local storage
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data - sẽ thay bằng API call thực tế
    _mediaItems = [
      MediaItem(
        id: '1',
        url: 'https://images.unsplash.com/photo-1583511655826-05700442982f',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        aspectRatio: 1.2,
      ),
      MediaItem(
        id: '2',
        url: 'https://images.unsplash.com/photo-1580456596733-b755f9dbd636',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        aspectRatio: 0.8,
      ),
      MediaItem(
        id: '3',
        url: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
        aspectRatio: 1.5,
      ),
      MediaItem(
        id: '4',
        url: 'https://images.unsplash.com/photo-1558788353-f76d92427f16',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        aspectRatio: 1.0,
      ),
      MediaItem(
        id: '5',
        url: 'https://images.unsplash.com/photo-1575425186775-b8de9a427e67',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        aspectRatio: 0.9,
      ),
      MediaItem(
        id: '6',
        url: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        aspectRatio: 1.1,
      ),
      MediaItem(
        id: '7',
        url: 'https://images.unsplash.com/photo-1552053831-71594a27632d',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 6)),
        aspectRatio: 1.4,
      ),
      MediaItem(
        id: '8',
        url: 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d',
        type: MediaType.image,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        aspectRatio: 0.7,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filter functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMediaGrid(context),
    );
  }

  /// Xây dựng layout lưới ảnh
  Widget _buildMediaGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 2.0,
        crossAxisSpacing: 2.0,
        itemCount: _mediaItems.length,
        itemBuilder: (context, index) {
          final item = _mediaItems[index];
          // Tạo hero tag duy nhất cho từng ảnh
          final heroTag = 'media_${widget.chatId}_${item.id}';

          return _buildMediaItem(context, item, heroTag, index);
        },
      ),
    );
  }

  /// Xây dựng từng item media
  Widget _buildMediaItem(
    BuildContext context,
    MediaItem item,
    String heroTag,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, item, heroTag, index),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: AspectRatio(
            aspectRatio: item.aspectRatio,
            child: CachedNetworkImage(
              imageUrl: item.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
              fadeOutDuration: animationService.config.fastDuration,
              fadeInDuration: animationService.config.fastDuration,
            ),
          ),
        ),
      ),
    );
  }

  /// Mở ảnh xem chi tiết với Hero animation
  void _openImageViewer(
    BuildContext context,
    MediaItem item,
    String heroTag,
    int index,
  ) {
    final viewerItems = _mediaItems
        .map(
          (mediaItem) => ImageViewerItem(
            imageUrl: mediaItem.url,
            heroTag: 'media_${widget.chatId}_${mediaItem.id}',
            title: _formatTimestamp(mediaItem.timestamp),
          ),
        )
        .toList(growable: false);
    final selectedIndex = _mediaItems.indexWhere((m) => m.id == item.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen.gallery(
          images: viewerItems.isNotEmpty
              ? viewerItems
              : <ImageViewerItem>[
                  ImageViewerItem(
                    imageUrl: item.url,
                    heroTag: heroTag,
                    title: _formatTimestamp(item.timestamp),
                  ),
                ],
          initialIndex: selectedIndex >= 0 && selectedIndex < viewerItems.length
              ? selectedIndex
              : index,
          title: _formatTimestamp(item.timestamp),
        ),
      ),
    );
  }

  /// Format thời gian chụp ảnh
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

/// Loại media
enum MediaType {
  image,
  video,
  file,
}

/// Mô hình dữ liệu cho media item
class MediaItem {
  /// ID duy nhất
  final String id;

  /// URL đến nguồn
  final String url;

  /// Loại media
  final MediaType type;

  /// Thời gian gửi
  final DateTime timestamp;

  /// Tỷ lệ chiều rộng/chiều cao
  final double aspectRatio;

  /// Constructor
  const MediaItem({
    required this.id,
    required this.url,
    required this.type,
    required this.timestamp,
    this.aspectRatio = 1.0,
  });
}
