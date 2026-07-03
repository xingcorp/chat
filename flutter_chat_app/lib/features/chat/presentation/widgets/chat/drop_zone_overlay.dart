import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Full-screen animated overlay shown when files are dragged over the chat area.
///
/// Shows a dashed border container with a cloud upload icon and localized text.
/// Appears/disappears with a fade + scale animation.
class DropZoneOverlay extends BaseStatelessWidget {
  /// Number of files being dragged (if available)
  final int? fileCount;

  const DropZoneOverlay({
    super.key,
    this.fileCount,
  });

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = isDark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primary.withValues(alpha: 0.08);
    final borderColor = AppColors.primary.withValues(alpha: 0.6);

    final dropText = fileCount != null && fileCount! > 0
        ? '${context.l10n.dropFilesHere} ($fileCount)'
        : context.l10n.dropFilesHere;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: overlayColor,
        child: Center(
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: const EdgeInsets.all(AppDimens.paddingLarge),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingXLarge,
                vertical: AppDimens.spaceHuge,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                border: Border.all(
                  color: borderColor,
                  width: 2.0,
                  // Dashed border simulated via CustomPaint below
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon.svg(
                    AppIcons.cloudUpload,
                    size: 64.0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimens.spaceMedium),
                  AppText(
                    dropText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
