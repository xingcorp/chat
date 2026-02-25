import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Full gallery page for shared media with tabs
/// Similar to Zalo/Messenger media gallery
class SharedMediaGalleryPage extends BaseStatefulWidget {
  final String chatId;
  final String chatName;
  final List<SharedMedia> initialPhotos;
  final List<SharedMedia> initialVideos;
  final List<SharedMedia> initialFiles;
  final List<SharedMedia> initialLinks;
  final SharedMediaType initialTab;
  final Future<List<SharedMedia>> Function(String chatId, SharedMediaType type, int offset)? onLoadMore;

  const SharedMediaGalleryPage({
    super.key,
    required this.chatId,
    required this.chatName,
    this.initialPhotos = const [],
    this.initialVideos = const [],
    this.initialFiles = const [],
    this.initialLinks = const [],
    this.initialTab = SharedMediaType.photo,
    this.onLoadMore,
  });

  @override
  State<SharedMediaGalleryPage> createState() => _SharedMediaGalleryPageState();
}

class _SharedMediaGalleryPageState extends BaseState<SharedMediaGalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<SharedMedia> _photos = [];
  List<SharedMedia> _videos = [];
  List<SharedMedia> _files = [];
  List<SharedMedia> _links = [];
  
  bool _isLoading = false;
  int _currentOffset = 0;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
    _videos = List.from(widget.initialVideos);
    _files = List.from(widget.initialFiles);
    _links = List.from(widget.initialLinks);
    
    final initialIndex = widget.initialTab == SharedMediaType.photo ? 0 :
                         widget.initialTab == SharedMediaType.video ? 1 :
                         widget.initialTab == SharedMediaType.file ? 2 : 3;
    
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );
    
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadMediaForCurrentTab();
  }

  Future<void> _loadMediaForCurrentTab() async {
    if (widget.onLoadMore == null) return;
    
    final type = _getCurrentMediaType();
    final list = _getMediaListForType(type);
    
    if (list.isNotEmpty) return; // Already loaded
    
    setState(() => _isLoading = true);
    
    try {
      final newMedia = await widget.onLoadMore!(widget.chatId, type, 0);
      setState(() {
        _setMediaListForType(type, newMedia);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  SharedMediaType _getCurrentMediaType() {
    switch (_tabController.index) {
      case 0: return SharedMediaType.photo;
      case 1: return SharedMediaType.video;
      case 2: return SharedMediaType.file;
      default: return SharedMediaType.link;
    }
  }

  List<SharedMedia> _getMediaListForType(SharedMediaType type) {
    switch (type) {
      case SharedMediaType.photo: return _photos;
      case SharedMediaType.video: return _videos;
      case SharedMediaType.file: return _files;
      case SharedMediaType.link: return _links;
    }
  }

  void _setMediaListForType(SharedMediaType type, List<SharedMedia> list) {
    switch (type) {
      case SharedMediaType.photo: _photos = list; break;
      case SharedMediaType.video: _videos = list; break;
      case SharedMediaType.file: _files = list; break;
      case SharedMediaType.link: _links = list; break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDarkMode : AppColors.background,
      appBar: AppBar(
        title: AppText(
          widget.chatName,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        foregroundColor: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.primaryDarkMode : AppColors.primary,
          unselectedLabelColor: isDark 
              ? AppColors.textSecondaryDarkMode 
              : AppColors.textSecondary,
          indicatorColor: isDark ? AppColors.primaryDarkMode : AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: '${l10n.photos} (${_photos.length})'),
            Tab(text: '${l10n.videos} (${_videos.length})'),
            Tab(text: '${l10n.files} (${_files.length})'),
            Tab(text: '${l10n.links} (${_links.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMediaGrid(_photos, SharedMediaType.photo, isDark),
          _buildMediaGrid(_videos, SharedMediaType.video, isDark),
          _buildFilesList(_files, isDark),
          _buildLinksList(_links, isDark),
        ],
      ),
    );
  }

  /// Build grid for photos/videos
  Widget _buildMediaGrid(List<SharedMedia> media, SharedMediaType type, bool isDark) {
    if (media.isEmpty) {
      return _buildEmptyState(type, isDark);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          _loadMoreMedia(type);
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(AppDimens.spaceXSmall),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppDimens.spaceXSmall,
          mainAxisSpacing: AppDimens.spaceXSmall,
        ),
        itemCount: media.length,
        itemBuilder: (context, index) {
          return _buildMediaItem(media[index], type, isDark);
        },
      ),
    );
  }

  /// Build individual media item
  Widget _buildMediaItem(SharedMedia media, SharedMediaType type, bool isDark) {
    final isVideo = type == SharedMediaType.video;

    return GestureDetector(
      onTap: () => _openMediaPreview(media, type),
      child: Hero(
        tag: 'media_${media.id}_full',
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            CachedNetworkImage(
              imageUrl: media.thumbnailUrl ?? media.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                child: Center(
                  child: SizedBox(
                    width: AppDimens.iconSizeMedium,
                    height: AppDimens.iconSizeMedium,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                child: Icon(
                  isVideo ? Icons.videocam : Icons.image,
                  color: isDark 
                      ? AppColors.textSecondaryDarkMode 
                      : AppColors.textSecondary,
                ),
              ),
            ),

            // Video play icon
            if (isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.paddingSmall),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: AppDimens.iconSizeMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build files list
  Widget _buildFilesList(List<SharedMedia> files, bool isDark) {
    if (files.isEmpty) {
      return _buildEmptyState(SharedMediaType.file, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileItem(file, isDark);
      },
    );
  }

  /// Build file item
  Widget _buildFileItem(SharedMedia file, bool isDark) {
    final l10n = context.l10n;
    final extension = file.fileName?.split('.').last.toUpperCase() ?? l10n.fileExtensionDefault;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.spaceSmall),
      color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        side: BorderSide(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: AppDimens.iconSizeXLarge,
          height: AppDimens.iconSizeXLarge,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDarkMode : AppColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Center(
            child: AppText(
              extension,
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
              ),
            ),
          ),
        ),
        title: AppText(
          file.fileName ?? l10n.unknownFile,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
          ),
        ),
        subtitle: AppText(
          _formatFileSize(file.fileSize),
          style: TextStyle(
            fontSize: 12.0,
            color: isDark 
                ? AppColors.textSecondaryDarkMode 
                : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.download,
          color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
        ),
        onTap: () => _openFile(file),
      ),
    );
  }

  /// Build links list
  Widget _buildLinksList(List<SharedMedia> links, bool isDark) {
    if (links.isEmpty) {
      return _buildEmptyState(SharedMediaType.link, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        return _buildLinkItem(link, isDark);
      },
    );
  }

  /// Build link item
  Widget _buildLinkItem(SharedMedia link, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.spaceSmall),
      color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        side: BorderSide(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: AppDimens.iconSizeXLarge,
          height: AppDimens.iconSizeXLarge,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDarkMode : AppColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Icon(
            Icons.link,
            color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
          ),
        ),
        title: AppText(
          link.url,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
          ),
        ),
        subtitle: AppText(
          link.senderName,
          style: TextStyle(
            fontSize: 12.0,
            color: isDark 
                ? AppColors.textSecondaryDarkMode 
                : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.open_in_new,
          color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
        ),
        onTap: () => _openLink(link),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(SharedMediaType type, bool isDark) {
    final l10n = context.l10n;
    String message;
    IconData icon;

    switch (type) {
      case SharedMediaType.photo:
        message = l10n.noItemsFound;
        icon = Icons.photo_library_outlined;
        break;
      case SharedMediaType.video:
        message = l10n.noItemsFound;
        icon = Icons.video_library_outlined;
        break;
      case SharedMediaType.file:
        message = l10n.noItemsFound;
        icon = Icons.folder_outlined;
        break;
      case SharedMediaType.link:
        message = l10n.noItemsFound;
        icon = Icons.link_off;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppDimens.iconSizeXXLarge,
            color: isDark 
                ? AppColors.textSecondaryDarkMode 
                : AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            message,
            style: TextStyle(
              fontSize: 16.0,
              color: isDark 
                  ? AppColors.textSecondaryDarkMode 
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMoreMedia(SharedMediaType type) async {
    if (_isLoading || widget.onLoadMore == null) return;
    
    setState(() => _isLoading = true);
    _currentOffset += _pageSize;
    
    try {
      final newMedia = await widget.onLoadMore!(
        widget.chatId,
        type,
        _currentOffset,
      );
      setState(() {
        final currentList = _getMediaListForType(type);
        _setMediaListForType(type, [...currentList, ...newMedia]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openMediaPreview(SharedMedia media, SharedMediaType type) {
    // TODO: Implement media preview with zoom capability
    // For now, just open the URL
    // launchUrl(Uri.parse(media.url));
  }

  void _openFile(SharedMedia file) {
    // TODO: Implement file download/open
    // launchUrl(Uri.parse(file.url));
  }

  void _openLink(SharedMedia link) {
    // TODO: Implement link opening
    // launchUrl(Uri.parse(link.url));
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
