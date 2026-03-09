import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/utils/screen_utils.dart';
import 'package:flutter_chat_app/data/services/file_validation_service.dart';
import 'package:flutter_chat_app/domain/entities/pending_file.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';

/// Individual file preview card showing thumbnail, name, size, and upload status.
///
/// Used in [FilePreviewBar] to display each pending attachment.
/// File name and size are shown in a tooltip on hover/long press to
/// keep the card compact and prevent overflow.
///
/// Card size adapts to screen size:
/// - Mobile: 48×48  |  Tablet: 52×52  |  Desktop: 60×60
class FilePreviewCard extends BaseStatelessWidget {
  /// The pending file to display
  final PendingFile file;

  /// File validation service for formatting file size
  final FileValidationService fileValidationService;

  /// Callback when the remove button is tapped
  final VoidCallback? onRemove;

  /// Callback when the retry button is tapped (for failed uploads)
  final VoidCallback? onRetry;

  const FilePreviewCard({
    super.key,
    required this.file,
    required this.fileValidationService,
    this.onRemove,
    this.onRetry,
  });

  /// Responsive thumbnail size: mobile 48, tablet 52, desktop 60.
  static double thumbnailSize(BuildContext context) =>
      ScreenUtils.responsiveValue(
        context: context,
        mobile: 48.0,
        tablet: 52.0,
        desktop: 60.0,
      );

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = thumbnailSize(context);

    return Tooltip(
      message: '${file.fileName}\n'
          '${fileValidationService.formatFileSize(file.fileSize)}',
      preferBelow: false,
      child: SizedBox(
        width: size + 4.0, // extra room for remove button overflow
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Thumbnail or type icon
            _buildThumbnail(context, isDark, size),

            // Remove button (top-right)
            if (onRemove != null)
              Positioned(
                top: -4.0,
                right: -4.0,
                child: _buildRemoveButton(context),
              ),

            // Upload progress or error overlay
            if (file.isUploading)
              _buildProgressOverlay(context),

            if (file.hasFailed)
              _buildErrorOverlay(context),

            // Completed badge
            if (file.isCompleted)
              Positioned(
                bottom: 2.0,
                right: 2.0,
                child: _buildCompletedBadge(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isDark, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        color: isDark ? AppColors.surfaceDarkMode : AppColors.inputBackground,
        border: Border.all(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildThumbnailContent(context, size),
    );
  }

  Widget _buildThumbnailContent(BuildContext context, double size) {
    // Image preview: try bytes first (web/paste), then path (desktop)
    if (file.isImage) {
      if (file.bytes != null) {
        return Image.memory(
          file.bytes!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _buildTypeIcon(context),
        );
      }
      if (!kIsWeb && file.localPath != null) {
        return Image.file(
          File(file.localPath!),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _buildTypeIcon(context),
        );
      }
    }
    return _buildTypeIcon(context);
  }

  Widget _buildTypeIcon(BuildContext context) {
    final iconData = _getTypeIcon(file.type);
    final iconColor = _getTypeColor(file.type);

    return Center(
      child: Icon(
        iconData,
        size: 28.0,
        color: iconColor,
      ),
    );
  }

  IconData _getTypeIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image_outlined;
      case AttachmentType.video:
        return Icons.videocam_outlined;
      case AttachmentType.audio:
        return Icons.audiotrack_outlined;
      case AttachmentType.document:
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getTypeColor(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return AppColors.primary;
      case AttachmentType.video:
        return AppColors.secondary;
      case AttachmentType.audio:
        return AppColors.success;
      case AttachmentType.document:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildRemoveButton(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        width: 18.0,
        height: 18.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.error,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 2.0,
            ),
          ],
        ),
        child: const Icon(
          Icons.close,
          size: 12.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressOverlay(BuildContext context) {
    final percentage = (file.uploadProgress * 100).toInt();
    final showPercentage = file.uploadProgress > 0;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppProgressIndicator.circular(
                value: showPercentage ? file.uploadProgress : null,
                size: ProgressSize.small,
                color: Colors.white,
              ),
              if (showPercentage) ...[
                const SizedBox(height: 2.0),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            color: AppColors.error.withValues(alpha: 0.2),
          ),
          child: const Center(
            child: Icon(
              Icons.refresh,
              size: 24.0,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedBadge(BuildContext context) {
    return Container(
      width: 16.0,
      height: 16.0,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success,
      ),
      child: const Icon(
        Icons.check,
        size: 10.0,
        color: Colors.white,
      ),
    );
  }
}
