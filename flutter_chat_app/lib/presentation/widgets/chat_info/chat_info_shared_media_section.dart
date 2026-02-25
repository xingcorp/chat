import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Shared media section widget for chat info panel
class ChatInfoSharedMediaSection extends BaseStatelessWidget {
  final List<SharedMedia> photos;
  final List<SharedMedia> videos;
  final List<SharedMedia> files;
  final List<SharedMedia> links;
  final VoidCallback onViewAllPhotos;
  final VoidCallback onViewAllVideos;
  final VoidCallback onViewAllFiles;
  final VoidCallback onViewAllLinks;

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
  });

  @override
  Widget buildContent(BuildContext context) {
    final hasAnyMedia = photos.isNotEmpty ||
                        videos.isNotEmpty ||
                        files.isNotEmpty ||
                        links.isNotEmpty;

    if (!hasAnyMedia) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
          child: AppText(
            'Shared Media',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: AppDimens.spaceSmall),

        // Media tabs
        AppCard.elevated(
          margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
          padding: const EdgeInsets.all(AppDimens.paddingMedium),
          child: Column(
            children: [
              // Photos
              if (photos.isNotEmpty)
                _buildMediaRow(
                  context: context,
                  icon: Icons.photo,
                  title: 'Photos',
                  count: photos.length,
                  onTap: onViewAllPhotos,
                  preview: photos.take(3).toList(),
                ),

              // Videos
              if (videos.isNotEmpty) ...[
                if (photos.isNotEmpty) Divider(height: 1),
                _buildMediaRow(
                  context: context,
                  icon: Icons.videocam,
                  title: 'Videos',
                  count: videos.length,
                  onTap: onViewAllVideos,
                  preview: videos.take(3).toList(),
                ),
              ],

              // Files
              if (files.isNotEmpty) ...[
                if (photos.isNotEmpty || videos.isNotEmpty) Divider(height: 1),
                _buildMediaRow(
                  context: context,
                  icon: Icons.insert_drive_file,
                  title: 'Files',
                  count: files.length,
                  onTap: onViewAllFiles,
                  preview: files.take(3).toList(),
                ),
              ],

              // Links
              if (links.isNotEmpty) ...[
                if (photos.isNotEmpty || videos.isNotEmpty || files.isNotEmpty)
                  Divider(height: 1),
                _buildMediaRow(
                  context: context,
                  icon: Icons.link,
                  title: 'Links',
                  count: links.length,
                  onTap: onViewAllLinks,
                  preview: links.take(3).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
    required List<SharedMedia> preview,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.paddingSmall,
          horizontal: AppDimens.paddingSmall,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isDark
                    ? AppColors.primaryDarkMode
                    : AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                size: 20,
              ),
            ),

            SizedBox(width: AppDimens.spaceSmall),

            // Title and count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  AppText(
                    '$count items',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDarkMode
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Preview thumbnails (for images/videos)
            if (preview.isNotEmpty &&
                (icon == Icons.photo || icon == Icons.videocam)) ...[
              SizedBox(width: AppDimens.spaceSmall),
              Row(
                children: preview.map((media) {
                  return Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDarkMode
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                      image: media.thumbnailUrl != null
                          ? DecorationImage(
                              image: NetworkImage(media.thumbnailUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: media.thumbnailUrl == null
                        ? Icon(
                            icon,
                            size: 16,
                            color: isDark
                                ? AppColors.textSecondaryDarkMode
                                : AppColors.textSecondary,
                          )
                        : null,
                  );
                }).toList(),
              ),
            ],

            // Arrow
            SizedBox(width: AppDimens.spaceSmall),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
