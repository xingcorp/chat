library;

/// **APP IMAGE GALLERY**
///
/// Image gallery component with grid layout and fullscreen lightbox.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Grid layout with lazy loading
/// - Tap to open fullscreen lightbox
/// - Swipe navigation in lightbox
/// - Pinch to zoom
/// - Share and download actions
/// - Thumbnail caching
/// - Pagination for large galleries
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with lightbox overlay
///
/// **Usage**:
/// ```dart
/// AppImageGallery(
///   images: [
///     GalleryImage(url: 'https://...', thumbnail: 'https://...'),
///     GalleryImage(url: 'https://...', thumbnail: 'https://...'),
///   ],
///   crossAxisCount: 3,
///   onImageTap: (index) => print('Tapped image $index'),
/// )
/// ```

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media_enums.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Gallery image model
class GalleryImage {
  /// Full resolution image URL
  final String url;

  /// Thumbnail URL (optional, uses url if not provided)
  final String? thumbnail;

  /// Image title (optional)
  final String? title;

  /// Image description (optional)
  final String? description;

  /// Image width (optional)
  final int? width;

  /// Image height (optional)
  final int? height;

  const GalleryImage({
    required this.url,
    this.thumbnail,
    this.title,
    this.description,
    this.width,
    this.height,
  });

  /// Get thumbnail URL or fallback to full URL
  String get thumbnailUrl => thumbnail ?? url;
}

/// App Image Gallery widget
class AppImageGallery extends BaseStatefulWidget {
  const AppImageGallery({
    super.key,
    required this.images,
    this.crossAxisCount = 3,
    this.mainAxisSpacing = AppDimens.spaceSmall,
    this.crossAxisSpacing = AppDimens.spaceSmall,
    this.childAspectRatio = 1.0,
    this.layoutMode = GalleryLayoutMode.grid,
    this.enableLightbox = true,
    this.enableZoom = true,
    this.enableShare = true,
    this.enableDownload = true,
    this.onImageTap,
    this.onShare,
    this.onDownload,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// List of images to display
  final List<GalleryImage> images;

  /// Number of columns in grid
  final int crossAxisCount;

  /// Spacing between rows
  final double mainAxisSpacing;

  /// Spacing between columns
  final double crossAxisSpacing;

  /// Aspect ratio of grid items
  final double childAspectRatio;

  /// Gallery layout mode
  final GalleryLayoutMode layoutMode;

  /// Whether to enable lightbox on tap
  final bool enableLightbox;

  /// Whether to enable pinch to zoom in lightbox
  final bool enableZoom;

  /// Whether to show share button
  final bool enableShare;

  /// Whether to show download button
  final bool enableDownload;

  /// Callback when image is tapped
  final void Function(int index)? onImageTap;

  /// Callback when share button is tapped
  final void Function(GalleryImage image)? onShare;

  /// Callback when download button is tapped
  final void Function(GalleryImage image)? onDownload;

  /// Custom loading builder
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Custom error builder
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  AppImageGalleryState createState() => AppImageGalleryState();
}

class AppImageGalleryState extends BaseState<AppImageGallery> {
  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildEmptyState();
    }

    switch (widget.layoutMode) {
      case GalleryLayoutMode.grid:
        return _buildGridLayout();
      case GalleryLayoutMode.list:
        return _buildListLayout();
      case GalleryLayoutMode.masonry:
        return _buildMasonryLayout();
    }
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        return _buildImageTile(widget.images[index], index);
      },
    );
  }

  Widget _buildListLayout() {
    return ListView.separated(
      itemCount: widget.images.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: widget.mainAxisSpacing),
      itemBuilder: (context, index) {
        return _buildImageTile(widget.images[index], index);
      },
    );
  }

  Widget _buildMasonryLayout() {
    // Simple masonry layout using Wrap
    return Wrap(
      spacing: widget.crossAxisSpacing,
      runSpacing: widget.mainAxisSpacing,
      children: widget.images.asMap().entries.map((entry) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 
                  (widget.crossAxisCount - 1) * widget.crossAxisSpacing) /
              widget.crossAxisCount,
          child: _buildImageTile(entry.value, entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildImageTile(GalleryImage image, int index) {
    return GestureDetector(
      onTap: () => _handleImageTap(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: CachedNetworkImage(
          imageUrl: image.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              widget.loadingBuilder?.call(context) ?? _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) =>
              widget.errorBuilder?.call(context, error) ??
              _buildErrorPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      child: Icon(
        Icons.broken_image,
        size: AppDimens.iconLarge,
        color: isDark ? AppColors.iconDarkMode.withValues(alpha: 0.5) : AppColors.icon.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: AppDimens.iconXXLarge,
            color: isDark ? AppColors.iconDarkMode.withValues(alpha: 0.5) : AppColors.icon.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          Text(
            l10n.noImagesAvailable,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleImageTap(int index) {
    widget.onImageTap?.call(index);

    if (widget.enableLightbox) {
      _openLightbox(index);
    }
  }

  void _openLightbox(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _LightboxView(
          images: widget.images,
          initialIndex: initialIndex,
          enableZoom: widget.enableZoom,
          enableShare: widget.enableShare,
          enableDownload: widget.enableDownload,
          onShare: widget.onShare,
          onDownload: widget.onDownload,
        ),
      ),
    );
  }
}

/// Lightbox view for fullscreen image viewing
class _LightboxView extends BaseStatefulWidget {
  const _LightboxView({
    required this.images,
    required this.initialIndex,
    this.enableZoom = true,
    this.enableShare = true,
    this.enableDownload = true,
    this.onShare,
    this.onDownload,
  });

  final List<GalleryImage> images;
  final int initialIndex;
  final bool enableZoom;
  final bool enableShare;
  final bool enableDownload;
  final void Function(GalleryImage image)? onShare;
  final void Function(GalleryImage image)? onDownload;

  @override
  _LightboxViewState createState() => _LightboxViewState();
}

class _LightboxViewState extends BaseState<_LightboxView> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundDarkMode,
      body: GestureDetector(
        onTap: () {
          safeSetState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Image gallery
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.images.length,
              builder: (context, index) {
                final image = widget.images[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(image.url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: image.url),
                );
              },
              onPageChanged: (index) {
                safeSetState(() {
                  _currentIndex = index;
                });
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(
                color: AppColors.backgroundDarkMode,
              ),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(theme, isDark),
              ),

            // Bottom bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(theme, isDark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppDimens.paddingSmall,
        left: AppDimens.paddingSmall,
        right: AppDimens.paddingSmall,
        bottom: AppDimens.paddingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundDarkMode.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.iconDarkMode),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: context.l10n.close,
          ),
          Text(
            '${_currentIndex + 1} / ${widget.images.length}',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimaryDarkMode,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.enableShare)
                IconButton(
                  icon: Icon(Icons.share, color: AppColors.iconDarkMode),
                  onPressed: () => widget.onShare?.call(widget.images[_currentIndex]),
                  tooltip: context.l10n.share,
                ),
              if (widget.enableDownload)
                IconButton(
                  icon: Icon(Icons.download, color: AppColors.iconDarkMode),
                  onPressed: () =>
                      widget.onDownload?.call(widget.images[_currentIndex]),
                  tooltip: context.l10n.download,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    final currentImage = widget.images[_currentIndex];

    if (currentImage.title == null && currentImage.description == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.paddingMedium,
        right: AppDimens.paddingMedium,
        bottom: MediaQuery.of(context).padding.bottom + AppDimens.paddingMedium,
        top: AppDimens.paddingMedium,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.backgroundDarkMode.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentImage.title != null)
            Text(
              currentImage.title!,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimaryDarkMode,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (currentImage.description != null) ...[
            const SizedBox(height: AppDimens.spaceSmall),
            Text(
              currentImage.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryDarkMode,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
