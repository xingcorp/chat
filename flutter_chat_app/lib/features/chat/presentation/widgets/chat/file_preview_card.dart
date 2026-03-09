import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/data/services/file_validation_service.dart';
import 'package:flutter_chat_app/domain/entities/pending_file.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';

/// Individual file preview card showing thumbnail, name, size, and upload status.
///
/// Used in [FilePreviewBar] to display each pending attachment.
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

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 72.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail area with overlay controls
          Stack(
            children: [
              // Thumbnail or type icon
              _buildThumbnail(context, isDark),

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

          const SizedBox(height: AppDimens.spaceXSmall),

          // File name
          AppText(
            file.fileName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.0,
                  color: isDark
                      ? AppColors.textSecondaryDarkMode
                      : AppColors.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // File size
          AppText(
            fileValidationService.formatFileSize(file.fileSize),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9.0,
                  color: isDark
                      ? AppColors.textHintDarkMode
                      : AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isDark) {
    return Container(
      width: 64.0,
      height: 64.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        color: isDark ? AppColors.surfaceDarkMode : AppColors.inputBackground,
        border: Border.all(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildThumbnailContent(context),
    );
  }

  Widget _buildThumbnailContent(BuildContext context) {
    // Image preview: try bytes first (web/paste), then path (desktop)
    if (file.isImage) {
      if (file.bytes != null) {
        return Image.memory(
          file.bytes!,
          fit: BoxFit.cover,
          width: 64.0,
          height: 64.0,
          errorBuilder: (_, __, ___) => _buildTypeIcon(context),
        );
      }
      if (!kIsWeb && file.localPath != null) {
        return Image.file(
          File(file.localPath!),
          fit: BoxFit.cover,
          width: 64.0,
          height: 64.0,
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
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Center(
          child: AppProgressIndicator.circular(
            value: file.uploadProgress > 0 ? file.uploadProgress : null,
            size: ProgressSize.small,
            color: Colors.white,
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
