import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/data/services/file_validation_service.dart';
import 'package:flutter_chat_app/domain/entities/pending_file.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/file_preview_card.dart';

/// Horizontal scrollable bar showing all pending file attachments.
///
/// Displayed between the message timeline and the chat input when
/// there are files in the attachment queue.
///
/// Bar height adapts to screen size via [FilePreviewCard.thumbnailSize].
class FilePreviewBar extends BaseStatelessWidget {
  /// List of pending files to display
  final List<PendingFile> files;

  /// File validation service for formatting file sizes
  final FileValidationService fileValidationService;

  /// Callback when a file's remove button is tapped
  final void Function(String localId) onRemove;

  /// Callback when a failed file's retry button is tapped
  final void Function(String localId) onRetry;

  /// Callback to open the file picker for adding more files
  final VoidCallback? onAddMore;

  /// Callback when a file card is tapped (for previewing images/videos)
  final void Function(PendingFile file)? onFileTap;

  /// Remaining attachment slots available
  final int remainingSlots;

  const FilePreviewBar({
    super.key,
    required this.files,
    required this.fileValidationService,
    required this.onRemove,
    required this.onRetry,
    this.onAddMore,
    this.onFileTap,
    this.remainingSlots = 0,
  });

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Derive bar height from the responsive thumbnail size + padding
    final thumbSize = FilePreviewCard.thumbnailSize(context);
    final barHeight = thumbSize + AppDimens.paddingSmall * 2;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: barHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingSmall,
            vertical: AppDimens.paddingSmall,
          ),
          itemCount: files.length + (remainingSlots > 0 ? 1 : 0),
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimens.spaceSmall),
          itemBuilder: (context, index) {
            // "Add more" button at the end
            if (index == files.length) {
              return _buildAddMoreButton(context, isDark, thumbSize);
            }

            final file = files[index];
            return FilePreviewCard(
              file: file,
              fileValidationService: fileValidationService,
              onRemove: () => onRemove(file.localId),
              onRetry: () => onRetry(file.localId),
              onTap: (file.isImage || file.isVideo) && onFileTap != null
                  ? () => onFileTap!(file)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddMoreButton(
      BuildContext context, bool isDark, double thumbSize) {
    return GestureDetector(
      onTap: onAddMore,
      child: Container(
        width: thumbSize,
        height: thumbSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: Border.all(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
            width: 1.0,
          ),
          color: isDark
              ? AppColors.inputBackgroundDarkMode
              : AppColors.inputBackground,
        ),
        child: Icon(
          Icons.add,
          size: 28.0,
          color: isDark ? AppColors.iconDarkMode : AppColors.icon,
        ),
      ),
    );
  }
}
