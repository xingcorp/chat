import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';

/// Zalo-style desktop toolbar row displayed above the editor.
///
/// Icons (left-to-right, matching Zalo PC):
/// Sticker · Image · File · Screenshot · Format toggle · More
///
/// Mobile layout is NOT affected — this widget is only used on desktop.
class DesktopComposerToolbar extends StatelessWidget {
  const DesktopComposerToolbar({
    required this.onStickerPressed,
    required this.onEmojiPressed,
    required this.onImagePressed,
    required this.onCameraPressed,
    required this.onVideoPressed,
    required this.onFilePressed,
    required this.onLocationPressed,
    required this.onFormatToggle,
    required this.isFormattingExpanded,
    this.onScreenshotPressed,
    this.onMorePressed,
    super.key,
  });

  final VoidCallback onStickerPressed;
  final VoidCallback onEmojiPressed;
  final VoidCallback onImagePressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onVideoPressed;
  final VoidCallback onFilePressed;
  final VoidCallback onLocationPressed;
  final VoidCallback onFormatToggle;
  final bool isFormattingExpanded;
  final VoidCallback? onScreenshotPressed;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.iconDarkMode : AppColors.icon;
    final activeColor = AppColors.primary;

    return Container(
      height: ComposerConstants.desktopToolbarHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
            width: AppDimens.dividerThin,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingSmall,
      ),
      child: Row(
        children: [
          // ── Sticker (distinct from emoji) ──
          _ToolbarIcon(
            icon: AppIcons.sticker,
            tooltip: context.l10n.stickers,
            color: iconColor,
            onPressed: onStickerPressed,
          ),
          // ── Emoji ──
          _ToolbarIcon(
            icon: AppIcons.emoji,
            tooltip: 'Emoji',
            color: iconColor,
            onPressed: onEmojiPressed,
          ),
          // ── Image gallery ──
          _ToolbarIcon(
            icon: AppIcons.imageGallery,
            tooltip: context.l10n.attachments,
            color: iconColor,
            onPressed: onImagePressed,
          ),
          // ── Camera ──
          _ToolbarIcon(
            icon: AppIcons.camera,
            tooltip: 'Camera',
            color: iconColor,
            onPressed: onCameraPressed,
          ),
          // ── Video ──
          _ToolbarIcon(
            icon: AppIcons.video,
            tooltip: 'Video',
            color: iconColor,
            onPressed: onVideoPressed,
          ),
          // ── File attach ──
          _ToolbarIcon(
            icon: AppIcons.attach,
            tooltip: context.l10n.attachments,
            color: iconColor,
            onPressed: onFilePressed,
          ),
          // ── Location ──
          _ToolbarIcon(
            icon: AppIcons.location,
            tooltip: 'Location',
            color: iconColor,
            onPressed: onLocationPressed,
          ),
          // ── Screenshot ──
          if (onScreenshotPressed != null)
            _ToolbarIcon(
              icon: AppIcons.screenshot,
              tooltip: 'Screenshot',
              color: iconColor,
              onPressed: onScreenshotPressed!,
            ),
          // ── Format toggle (Aa) ──
          _ToolbarIcon(
            icon: AppIcons.textFormat,
            tooltip: isFormattingExpanded
                ? context.l10n.save
                : 'Aa',
            color: isFormattingExpanded ? activeColor : iconColor,
            onPressed: onFormatToggle,
          ),
          const Spacer(),
          // ── More options ──
          if (onMorePressed != null)
            _ToolbarIcon(
              icon: AppIcons.moreHoriz,
              tooltip: context.l10n.attachments,
              color: iconColor,
              onPressed: onMorePressed!,
            ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final String icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          ComposerConstants.formatButtonRadius,
        ),
        child: SizedBox(
          width: ComposerConstants.formatButtonSize,
          height: ComposerConstants.formatButtonSize,
          child: AppIcon.svg(
            icon,
            size: ComposerConstants.desktopToolbarIconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}
