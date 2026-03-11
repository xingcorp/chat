import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';

/// The always-visible quick-action row (Layer A in the 2-layer toolbar).
///
/// Contains: **emoji · attach · format-toggle · (spacer) · send**.
///
/// Send button and emoji/attach callbacks are provided by the parent
/// [QuillComposerWidget].
class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.onEmojiPressed,
    required this.onAttachPressed,
    required this.onFormatToggle,
    required this.isFormattingExpanded,
    super.key,
  });

  final VoidCallback onEmojiPressed;
  final VoidCallback onAttachPressed;
  final VoidCallback onFormatToggle;
  final bool isFormattingExpanded;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final iconColor = isDark ? AppColors.iconDarkMode : AppColors.icon;
    final activeColor = AppColors.primary;

    return Container(
      height: ComposerConstants.actionRowHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingSmall,
      ),
      child: Row(
        children: [
          // ── Emoji ──
          _ActionIconButton(
            icon: Icons.emoji_emotions_outlined,
            tooltip: 'Emoji',
            color: iconColor,
            onPressed: onEmojiPressed,
          ),

          // ── Attach ──
          _ActionIconButton(
            icon: Icons.attach_file,
            tooltip: 'Attach file',
            color: iconColor,
            onPressed: onAttachPressed,
          ),

          // ── Format toggle ──
          _ActionIconButton(
            icon: Icons.text_format,
            tooltip: isFormattingExpanded
                ? 'Hide formatting'
                : 'Show formatting',
            color: isFormattingExpanded ? activeColor : iconColor,
            onPressed: onFormatToggle,
          ),
        ],
      ),
    );
  }
}

/// Internal icon button used inside the action row.
class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(ComposerConstants.formatButtonRadius),
        child: SizedBox(
          width: ComposerConstants.formatButtonSize,
          height: ComposerConstants.formatButtonSize,
          child: Icon(
            icon,
            size: ComposerConstants.formatIconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}
