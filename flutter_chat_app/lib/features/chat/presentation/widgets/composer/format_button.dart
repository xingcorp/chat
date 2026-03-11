import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';

/// A single format toggle button (bold, italic, underline, etc.).
///
/// Renders as an [IconButton] with three visual states:
/// - **inactive**: default icon colour
/// - **active**: primary colour + subtle background tint
/// - **disabled**: greyed-out, non-interactive
///
/// Uses [AppColors] for all colour values and [ComposerConstants] for
/// sizing, complying with the design-system rules.
class FormatButton extends StatelessWidget {
  const FormatButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isEnabled = true,
    this.onPressed,
    super.key,
  });

  /// Icon shown inside the button.
  final IconData icon;

  /// Accessibility / hover tooltip.
  final String tooltip;

  /// Whether this format is currently applied at the cursor/selection.
  final bool isActive;

  /// Whether the button can be tapped.
  final bool isEnabled;

  /// Called when the button is tapped. Ignored when [isEnabled] is
  /// `false`.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final Color activeColor = AppColors.primary;
    final Color inactiveColor =
        isDark ? AppColors.iconDarkMode : AppColors.icon;
    final Color disabledColor =
        isDark ? AppColors.textHintDarkMode : AppColors.textHint;

    final Color iconColor;
    final Color? backgroundColor;

    if (!isEnabled) {
      iconColor = disabledColor;
      backgroundColor = null;
    } else if (isActive) {
      iconColor = activeColor;
      backgroundColor = activeColor.withValues(alpha: 0.12);
    } else {
      iconColor = inactiveColor;
      backgroundColor = null;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius:
            BorderRadius.circular(ComposerConstants.formatButtonRadius),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius:
              BorderRadius.circular(ComposerConstants.formatButtonRadius),
          child: SizedBox(
            width: ComposerConstants.formatButtonSize,
            height: ComposerConstants.formatButtonSize,
            child: Icon(
              icon,
              size: ComposerConstants.formatIconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
