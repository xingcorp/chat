import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Shared media section widget for chat info panel
/// Redesigned to match Zalo/Messenger UX with grid preview
class ChatInfoSharedMediaSection extends BaseStatelessWidget {
  final List<SharedMedia> photos;
  final List<SharedMedia> videos;
  final List<SharedMedia> files;
  final List<SharedMedia> links;
  final VoidCallback onViewAllPhotos;
  final VoidCallback onViewAllVideos;
  final VoidCallback onViewAllFiles;
  final VoidCallback onViewAllLinks;
  final void Function(SharedMedia media)? onMediaTap;

  const ChatInfoSharedMediaSection({
    super.key,
    required this.photos,
    required this.videos,
    required this.files,
    required this.links,
    required this.onViewAllPhotos,
    required this.onViewAllVideos,
    required this.onViewAllFiles,
    required this.onViewAllLinks,
    this.onMediaTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    final hasAnyMedia = photos.isNotEmpty ||
                        videos.isNotEmpty ||
                        files.isNotEmpty ||
                        links.isNotEmpty;

    if (!hasAnyMedia) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    // Combine photos and videos for grid preview (like Zalo/Messenger)
    final mediaForGrid = [...photos, ...videos].take(6).toList();
    final totalMediaCount = photos.length + videos.length;
    final hasMore = totalMediaCount > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid preview for photos/videos (Zalo/Messenger style)
        if (mediaForGrid.isNotEmpty) ...[
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingMedium,
              vertical: AppDimens.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  l10n.sharedMedia,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (totalMediaCount > 0)
                  TextButton(
                    onPressed: onViewAllPhotos,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          '$totalMediaCount ${l10n.items}',
                          style: TextStyle(
                            color: isDark 
                                ? AppColors.primaryDarkMode 
                                : AppColors.primary,
                            fontSize: 13.0,
                          ),
                        ),
                        const SizedBox(width: AppDimens.spaceXSmall),
                        Icon(
                          Icons.chevron_right,
                          size: AppDimens.iconSizeSmall,
                          color: isDark 
                              ? AppColors.primaryDarkMode 
                              : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Grid 3x2 preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
            child: GestureDetector(
              onTap: onViewAllPhotos,
              child: _buildMediaGrid(
                context: context,
                mediaList: mediaForGrid,
                totalCount: totalMediaCount,
                hasMore: hasMore,
                isDark: isDark,
              ),
            ),
          ),

          const SizedBox(height: AppDimens.spaceMedium),
        ],

        // Files and Links rows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
          child: Column(
            children: [
              // Files row
              if (files.isNotEmpty)
                _buildCompactRow(
                  context: context,
                  icon: Icons.insert_drive_file_outlined,
                  title: l10n.files,
                  count: files.length,
                  onTap: onViewAllFiles,
                  isDark: isDark,
                ),

              // Links row
              if (links.isNotEmpty) ...[
                if (files.isNotEmpty) const SizedBox(height: AppDimens.spaceSmall),
                _buildCompactRow(
                  context: context,
                  icon: Icons.link_outlined,
                  title: l10n.links,
                  count: links.length,
                  onTap: onViewAllLinks,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build 3x2 grid preview (Zalo/Messenger style)
  Widget _buildMediaGrid({
    required BuildContext context,
    required List<SharedMedia> mediaList,
    required int totalCount,
    required bool hasMore,
    required bool isDark,
  }) {
    const gridSize = 6;
    final displayItems = mediaList.take(gridSize).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.spaceXSmall),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppDimens.spaceXSmall,
          mainAxisSpacing: AppDimens.spaceXSmall,
        ),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final media = displayItems[index];
          final isLastItem = index == displayItems.length - 1;
          final showOverlay = hasMore && isLastItem;

          return _buildGridItem(
            context: context,
            media: media,
            showOverlay: showOverlay,
            overlayText: '+${totalCount - 5}',
            isDark: isDark,
          );
        },
      ),
    );
  }

  /// Build individual grid item with optional overlay
  Widget _buildGridItem({
    required BuildContext context,
    required SharedMedia media,
    bool showOverlay = false,
    String? overlayText,
    required bool isDark,
  }) {
    final isVideo = media.type == SharedMediaType.video;

    return GestureDetector(
      onTap: () => onMediaTap?.call(media),
      child: Hero(
        tag: 'media_${media.id}',
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image/Video thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: _buildThumbnail(media, isDark),
            ),

            // Video play icon overlay
            if (isVideo)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: AppDimens.iconSizeLarge,
                    ),
                  ),
                ),
              ),

            // "+N more" overlay
            if (showOverlay && overlayText != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: Center(
                    child: AppText(
                      overlayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build thumbnail with caching
  Widget _buildThumbnail(SharedMedia media, bool isDark) {
    final thumbnailUrl = media.thumbnailUrl ?? media.url;

    if (thumbnailUrl.isEmpty) {
      return Container(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        child: Icon(
          media.type == SharedMediaType.video
              ? Icons.videocam
              : Icons.image,
          color: isDark
              ? AppColors.textSecondaryDarkMode
              : AppColors.textSecondary,
          size: AppDimens.iconSizeLarge,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
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
          Icons.broken_image,
          color: isDark
              ? AppColors.textSecondaryDarkMode
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Build compact row for files/links
  Widget _buildCompactRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: AppDimens.iconSizeLarge,
              height: AppDimens.iconSizeLarge,
              decoration: BoxDecoration(
                color: (isDark
                    ? AppColors.primaryDarkMode
                    : AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                size: AppDimens.iconSizeSmall,
              ),
            ),

            const SizedBox(width: AppDimens.spaceSmall),

            // Title and count
            Expanded(
              child: AppText(
                '$title ($count)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
              size: AppDimens.iconSizeMedium,
            ),
          ],
        ),
      ),
    );
  }
}
