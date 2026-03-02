import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/services/file_download_state.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/screens/media/image_viewer_screen.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/presentation/widgets/media_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final Future<List<SharedMedia>> Function(
      String chatId, SharedMediaType type, int offset)? onLoadMore;

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

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<SharedMedia> _photos = [];
  List<SharedMedia> _videos = [];
  List<SharedMedia> _files = [];
  List<SharedMedia> _links = [];

  // Filtered lists for search
  List<SharedMedia> _filteredPhotos = [];
  List<SharedMedia> _filteredVideos = [];
  List<SharedMedia> _filteredFiles = [];
  List<SharedMedia> _filteredLinks = [];

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

    // Initialize filtered lists
    _filteredPhotos = List.from(_photos);
    _filteredVideos = List.from(_videos);
    _filteredFiles = List.from(_files);
    _filteredLinks = List.from(_links);

    final initialIndex = widget.initialTab == SharedMediaType.photo
        ? 0
        : widget.initialTab == SharedMediaType.video
            ? 1
            : widget.initialTab == SharedMediaType.file
                ? 2
                : 3;

    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );

    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadMediaForCurrentTab();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredPhotos = List.from(_photos);
      _filteredVideos = List.from(_videos);
      _filteredFiles = List.from(_files);
      _filteredLinks = List.from(_links);
    } else {
      _filteredPhotos = _photos
          .where(
              (m) => m.fileName?.toLowerCase().contains(_searchQuery) ?? false)
          .toList();
      _filteredVideos = _videos
          .where(
              (m) => m.fileName?.toLowerCase().contains(_searchQuery) ?? false)
          .toList();
      _filteredFiles = _files
          .where(
              (m) => m.fileName?.toLowerCase().contains(_searchQuery) ?? false)
          .toList();
      _filteredLinks = _links
          .where((m) =>
              m.url.toLowerCase().contains(_searchQuery) ||
              (m.fileName?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _applySearchFilter();
      }
    });
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
      case 0:
        return SharedMediaType.photo;
      case 1:
        return SharedMediaType.video;
      case 2:
        return SharedMediaType.file;
      default:
        return SharedMediaType.link;
    }
  }

  List<SharedMedia> _getMediaListForType(SharedMediaType type) {
    switch (type) {
      case SharedMediaType.photo:
        return _photos;
      case SharedMediaType.video:
        return _videos;
      case SharedMediaType.file:
        return _files;
      case SharedMediaType.link:
        return _links;
    }
  }

  void _setMediaListForType(SharedMediaType type, List<SharedMedia> list) {
    switch (type) {
      case SharedMediaType.photo:
        _photos = list;
        break;
      case SharedMediaType.video:
        _videos = list;
        break;
      case SharedMediaType.file:
        _files = list;
        break;
      case SharedMediaType.link:
        _links = list;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDarkMode : AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchMedia,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDarkMode
                        : AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDarkMode
                      : AppColors.textPrimary,
                ),
              )
            : AppText(
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
        foregroundColor:
            isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.primaryDarkMode : AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDarkMode
              : AppColors.textSecondary,
          indicatorColor:
              isDark ? AppColors.primaryDarkMode : AppColors.primary,
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
            Tab(text: '${l10n.photos} (${_filteredPhotos.length})'),
            Tab(text: '${l10n.videos} (${_filteredVideos.length})'),
            Tab(text: '${l10n.files} (${_filteredFiles.length})'),
            Tab(text: '${l10n.links} (${_filteredLinks.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMediaGridWithTimeline(
              _filteredPhotos, SharedMediaType.photo, isDark),
          _buildMediaGridWithTimeline(
              _filteredVideos, SharedMediaType.video, isDark),
          _buildFilesList(_filteredFiles, isDark),
          _buildLinksList(_filteredLinks, isDark),
        ],
      ),
    );
  }

  /// Build grid for photos/videos with timeline grouping
  Widget _buildMediaGridWithTimeline(
      List<SharedMedia> media, SharedMediaType type, bool isDark) {
    if (media.isEmpty) {
      return _buildEmptyState(type, isDark);
    }

    // Group media by timeline
    final groupedMedia = _groupByTimeline(media);
    final l10n = context.l10n;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          _loadMoreMedia(type);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.spaceXSmall),
        itemCount: groupedMedia.length,
        itemBuilder: (context, groupIndex) {
          final group = groupedMedia[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline header
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.spaceSmall,
                  horizontal: AppDimens.spaceXSmall,
                ),
                child: AppText(
                  _getTimelineLabel(group.key, l10n),
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDarkMode
                        : AppColors.textSecondary,
                  ),
                ),
              ),

              // Grid for this timeline group
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppDimens.spaceXSmall,
                  mainAxisSpacing: AppDimens.spaceXSmall,
                ),
                itemCount: group.items.length,
                itemBuilder: (context, index) {
                  return _buildMediaItem(group.items[index], type, isDark);
                },
              ),

              const SizedBox(height: AppDimens.spaceSmall),
            ],
          );
        },
      ),
    );
  }

  /// Group media by actual date (like Zalo/Messenger)
  List<_TimelineGroup> _groupByTimeline(List<SharedMedia> media) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Sort media by date descending (newest first)
    final sortedMedia = List<SharedMedia>.from(media)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final groups = <String, List<SharedMedia>>{};
    final dateLabels = <String, String>{};

    for (final item in sortedMedia) {
      final itemDate = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );

      String key;
      String label;

      if (itemDate == today) {
        key = 'today';
        label = 'today';
      } else if (itemDate == yesterday) {
        key = 'yesterday';
        label = 'yesterday';
      } else {
        // Format as actual date: "15 tháng 2" or "15 Feb"
        key = '${itemDate.year}-${itemDate.month}-${itemDate.day}';
        label = key; // Will be formatted in _getTimelineLabel
      }

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(item);
      dateLabels[key] = label;
    }

    // Build result maintaining order (today, yesterday, then by date descending)
    final result = <_TimelineGroup>[];

    // Add today and yesterday first if they exist
    if (groups.containsKey('today')) {
      result.add(_TimelineGroup(key: 'today', items: groups['today']!));
    }
    if (groups.containsKey('yesterday')) {
      result.add(_TimelineGroup(key: 'yesterday', items: groups['yesterday']!));
    }

    // Add other dates in descending order
    final otherDates = groups.keys
        .where((k) => k != 'today' && k != 'yesterday')
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order

    for (final key in otherDates) {
      result.add(_TimelineGroup(key: key, items: groups[key]!));
    }

    return result;
  }

  /// Get localized timeline label with actual date formatting
  String _getTimelineLabel(String key, dynamic l10n) {
    if (key == 'today') {
      return l10n.today;
    } else if (key == 'yesterday') {
      return l10n.yesterday;
    }

    // Parse date key and format: "15 tháng 2" or "15 Feb"
    final parts = key.split('-');
    if (parts.length == 3) {
      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);

      // Get localized month name
      final monthName = _getMonthName(month, l10n);

      // Return format like "15 tháng 2" (Vietnamese) or "15 Feb" (English)
      return l10n.dateFormatDayMonth(day, monthName);
    }

    return key;
  }

  /// Get localized month name
  String _getMonthName(int month, dynamic l10n) {
    switch (month) {
      case 1:
        return l10n.monthJanuary;
      case 2:
        return l10n.monthFebruary;
      case 3:
        return l10n.monthMarch;
      case 4:
        return l10n.monthApril;
      case 5:
        return l10n.monthMay;
      case 6:
        return l10n.monthJune;
      case 7:
        return l10n.monthJuly;
      case 8:
        return l10n.monthAugust;
      case 9:
        return l10n.monthSeptember;
      case 10:
        return l10n.monthOctober;
      case 11:
        return l10n.monthNovember;
      case 12:
        return l10n.monthDecember;
      default:
        return month.toString();
    }
  }

  /// Build individual media item
  Widget _buildMediaItem(SharedMedia media, SharedMediaType type, bool isDark) {
    final isVideo = type == SharedMediaType.video;
    final hasThumbnail =
        media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _openMediaPreview(media, type),
      child: Hero(
        tag: 'media_${media.id}_full',
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or placeholder
            if (hasThumbnail)
              CachedNetworkImage(
                imageUrl: media.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                  child: Center(
                    child: SizedBox(
                      width: AppDimens.iconSizeMedium,
                      height: AppDimens.iconSizeMedium,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: isDark
                            ? AppColors.primaryDarkMode
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildVideoPlaceholder(isVideo, isDark),
              )
            else if (isVideo)
              // For videos without thumbnail, show placeholder instead of trying to load video URL
              _buildVideoPlaceholder(isVideo, isDark)
            else
              // For photos without thumbnail, try loading the photo URL
              CachedNetworkImage(
                imageUrl: media.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                  child: Center(
                    child: SizedBox(
                      width: AppDimens.iconSizeMedium,
                      height: AppDimens.iconSizeMedium,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: isDark
                            ? AppColors.primaryDarkMode
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                  child: Icon(
                    Icons.image,
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

  /// Build video placeholder when no thumbnail available
  Widget _buildVideoPlaceholder(bool isVideo, bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      child: Center(
        child: Icon(
          Icons.videocam,
          size: AppDimens.iconSizeLarge,
          color: isDark
              ? AppColors.textSecondaryDarkMode
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Build files list with timeline grouping
  Widget _buildFilesList(List<SharedMedia> files, bool isDark) {
    if (files.isEmpty) {
      return _buildEmptyState(SharedMediaType.file, isDark);
    }

    // Group files by timeline
    final groupedFiles = _groupByTimeline(files);
    final l10n = context.l10n;

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      itemCount: groupedFiles.length,
      itemBuilder: (context, groupIndex) {
        final group = groupedFiles[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.spaceSmall,
                horizontal: AppDimens.spaceXSmall,
              ),
              child: AppText(
                _getTimelineLabel(group.key, l10n),
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDarkMode
                      : AppColors.textSecondary,
                ),
              ),
            ),

            // Files for this timeline group
            ...group.items.map((file) => _buildFileItem(file, isDark)),

            const SizedBox(height: AppDimens.spaceSmall),
          ],
        );
      },
    );
  }

  /// Build file item
  Widget _buildFileItem(SharedMedia file, bool isDark) {
    final l10n = context.l10n;
    final extension = file.fileName?.split('.').last.toUpperCase() ??
        l10n.fileExtensionDefault;

    final IFileDownloadManager downloadManager =
        GetIt.I<IFileDownloadManager>();
    final String downloadKey = _buildSharedFileDownloadKey(file);

    return StreamBuilder<FileDownloadState>(
      stream: downloadManager.watch(downloadKey),
      initialData: downloadManager.stateOf(downloadKey),
      builder: (context, snapshot) {
        final FileDownloadState downloadState = snapshot.data ??
            FileDownloadState.idle(
              downloadKey,
              sourceUrl: file.url,
              fileName: file.fileName,
            );
        final bool isDownloading = downloadState.isInProgress;
        final bool isDownloaded =
            downloadState.status == FileDownloadStatus.completed;
        final bool isFailed = downloadState.status == FileDownloadStatus.failed;

        String subtitle = _formatFileSize(file.fileSize);
        if (isDownloading) {
          subtitle = '${l10n.downloading} ${downloadState.progress}%';
        } else if (isDownloaded) {
          subtitle = l10n.downloaded;
        } else if (isFailed) {
          subtitle = l10n.downloadFailed;
        }

        final Color trailingColor =
            isDark ? AppColors.primaryDarkMode : AppColors.primary;

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
                child: isDownloading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: downloadState.progress > 0
                              ? downloadState.progress / 100
                              : null,
                          strokeWidth: 2.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(trailingColor),
                        ),
                      )
                    : AppText(
                        extension,
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: trailingColor,
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
                color: isDark
                    ? AppColors.textPrimaryDarkMode
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: AppText(
              subtitle,
              style: TextStyle(
                fontSize: 12.0,
                color: isFailed
                    ? Theme.of(context).colorScheme.error
                    : (isDark
                        ? AppColors.textSecondaryDarkMode
                        : AppColors.textSecondary),
              ),
            ),
            trailing: Icon(
              isDownloading
                  ? Icons.close
                  : isDownloaded
                      ? Icons.open_in_new
                      : isFailed
                          ? Icons.refresh
                          : Icons.download,
              color: trailingColor,
            ),
            onTap: () => _handleSharedFileTap(
              file,
              downloadManager: downloadManager,
              downloadState: downloadState,
              downloadKey: downloadKey,
            ),
          ),
        );
      },
    );
  }

  /// Build links list with timeline grouping
  Widget _buildLinksList(List<SharedMedia> links, bool isDark) {
    if (links.isEmpty) {
      return _buildEmptyState(SharedMediaType.link, isDark);
    }

    // Group links by timeline
    final groupedLinks = _groupByTimeline(links);
    final l10n = context.l10n;

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      itemCount: groupedLinks.length,
      itemBuilder: (context, groupIndex) {
        final group = groupedLinks[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.spaceSmall,
                horizontal: AppDimens.spaceXSmall,
              ),
              child: AppText(
                _getTimelineLabel(group.key, l10n),
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDarkMode
                      : AppColors.textSecondary,
                ),
              ),
            ),

            // Links for this timeline group
            ...group.items.map((link) => _buildLinkItem(link, isDark)),

            const SizedBox(height: AppDimens.spaceSmall),
          ],
        );
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
          color: isDark
              ? AppColors.textSecondaryDarkMode
              : AppColors.textSecondary,
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
    if (type == SharedMediaType.photo) {
      // Use ImageViewerScreen for photos with zoom capability
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            imageUrl: media.url,
            heroTag: 'media_${media.id}_full',
            title: media.fileName,
          ),
        ),
      );
    } else if (type == SharedMediaType.video) {
      // On web platform, video_player is not supported, use url_launcher instead
      if (kIsWeb) {
        _openVideoInBrowser(media);
      } else {
        // Use MediaViewer for videos on mobile (supports Chewie player)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: AppText(
                  media.fileName ?? 'Video',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              body: MediaViewer(
                mediaUrl: media.url,
                mediaType: MediaType.video,
              ),
            ),
          ),
        );
      }
    }
  }

  /// Open video in browser (for web platform)
  Future<void> _openVideoInBrowser(SharedMedia media) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final uri = Uri.parse(media.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: AppText(l10n.errorOpeningFile),
        ),
      );
    }
  }

  String _buildSharedFileDownloadKey(SharedMedia file) {
    final String id = file.id.trim();
    if (id.isNotEmpty) {
      return 'shared_media_$id';
    }
    return 'shared_media_url_${file.url.hashCode}';
  }

  Future<void> _handleSharedFileTap(
    SharedMedia file, {
    required IFileDownloadManager downloadManager,
    required FileDownloadState downloadState,
    required String downloadKey,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    if (downloadState.isInProgress) {
      final cancelResult = await downloadManager.cancelDownload(downloadKey);
      if (!mounted) {
        return;
      }

      cancelResult.fold(
        (failure) => messenger.showSnackBar(
          SnackBar(content: AppText(failure.userMessage)),
        ),
        (_) {},
      );
      return;
    }

    if (downloadState.canOpen) {
      final openResult = await downloadManager.openDownloadedFile(downloadKey);
      if (!mounted) {
        return;
      }

      openResult.fold(
        (failure) => messenger.showSnackBar(
          SnackBar(content: AppText(failure.userMessage)),
        ),
        (_) {},
      );
      return;
    }

    final result = await downloadManager.startDownload(
      key: downloadKey,
      url: file.url,
      fileName: file.fileName,
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: AppText(failure.userMessage)),
      ),
      (_) => messenger.showSnackBar(
        SnackBar(content: AppText(l10n.downloading)),
      ),
    );
  }

  Future<void> _openLink(SharedMedia link) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    // Open link in external browser
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: AppText(l10n.errorOpeningLink),
        ),
      );
    }
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

/// Helper class for timeline grouping
class _TimelineGroup {
  final String key;
  final List<SharedMedia> items;

  _TimelineGroup({required this.key, required this.items});
}
