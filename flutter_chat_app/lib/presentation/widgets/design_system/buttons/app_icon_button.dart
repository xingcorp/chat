import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';

/// **APP ICON BUTTON**
///
/// A customizable icon-only button widget that follows the app's design system.
/// Supports multiple sizes, shapes, and optional badge indicators.
///
/// **Features**:
/// - Three sizes (small, medium, large)
/// - Circular and square shapes
/// - Optional badge indicator
/// - Haptic feedback
/// - Dark mode support
/// - Accessibility compliant
/// - Minimum touch target size (48x48)
///
/// **Usage**:
/// ```dart
/// // Basic icon button
/// AppIconButton(
///   icon: Icons.favorite,
///   onPressed: () => _handleFavorite(),
/// )
///
/// // Icon button with badge
/// AppIconButton(
///   icon: Icons.notifications,
///   onPressed: () => _handleNotifications(),
///   showBadge: true,
/// )
///
/// // Square icon button
/// AppIconButton(
///   icon: Icons.menu,
///   onPressed: () => _handleMenu(),
///   isCircular: false,
/// )
///
/// // Large icon button
/// AppIconButton(
///   icon: Icons.add,
///   onPressed: () => _handleAdd(),
///   size: ButtonSize.large,
/// )
/// ```
class AppIconButton extends BaseStatelessWidget {
  /// Creates an icon button
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.size = ButtonSize.medium,
    this.isCircular = true,
    this.showBadge = false,
    this.tooltip,
    super.key,
  });

  /// Icon to display (can be [IconData] or [String] SVG asset path)
  final dynamic icon;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button size
  final ButtonSize size;

  /// Whether button should be circular (true) or square (false)
  final bool isCircular;

  /// Whether to show badge indicator
  final bool showBadge;

  /// Optional tooltip text
  final String? tooltip;

  /// Whether button is disabled
  bool get _isDisabled => onPressed == null;

  /// Get button size based on size variant
  double get _buttonSize {
    switch (size) {
      case ButtonSize.small:
        return AppDimens.iconButtonSize * 0.75; // 36dp
      case ButtonSize.medium:
        return AppDimens.iconButtonSize; // 48dp
      case ButtonSize.large:
        return AppDimens.iconButtonSize * 1.25; // 60dp
    }
  }

  /// Get icon size based on button size
  double get _iconSize {
    switch (size) {
      case ButtonSize.small:
        return AppDimens.iconSmall;
      case ButtonSize.medium:
        return AppDimens.iconMedium;
      case ButtonSize.large:
        return AppDimens.iconLarge;
    }
  }

  /// Get badge size
  double get _badgeSize {
    switch (size) {
      case ButtonSize.small:
        return AppDimens.badgeSmall * 0.75; // 12dp
      case ButtonSize.medium:
        return AppDimens.badgeSmall; // 16dp
      case ButtonSize.large:
        return AppDimens.badgeMedium; // 20dp
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget iconWidget;
    if (icon is IconData) {
      iconWidget = Icon(icon as IconData, size: _iconSize);
    } else if (icon is String) {
      iconWidget = AppIcon.svg(
        icon as String,
        size: _iconSize,
        color: _isDisabled
            ? (isDark ? AppColors.iconDarkMode : AppColors.icon).withOpacity(0.5)
            : null,
      );
    } else if (icon is Widget) {
      iconWidget = icon as Widget;
    } else {
      iconWidget = const SizedBox.shrink();
    }

    Widget button = IconButton(
      icon: iconWidget,
      onPressed: _isDisabled ? null : _handlePressed,
      iconSize: _iconSize,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: _buttonSize,
        minHeight: _buttonSize,
        maxWidth: _buttonSize,
        maxHeight: _buttonSize,
      ),
      style: IconButton.styleFrom(
        foregroundColor: isDark
            ? AppColors.iconDarkMode
            : AppColors.icon,
        disabledForegroundColor: (isDark
                ? AppColors.iconDarkMode
                : AppColors.icon)
            .withOpacity(0.5),
        shape: isCircular
            ? const CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
      ),
      tooltip: tooltip,
    );

    // Add badge if needed
    if (showBadge) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: _badgeSize,
              height: _badgeSize,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Ensure minimum touch target
    if (_buttonSize < AppDimens.touchTargetMin) {
      button = SizedBox(
        width: AppDimens.touchTargetMin,
        height: AppDimens.touchTargetMin,
        child: Center(child: button),
      );
    }

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      label: _getAccessibilityLabel(context),
      child: button,
    );
  }

  /// Get accessibility label for button
  String _getAccessibilityLabel(BuildContext context) {
    final l10n = context.l10n;

    if (tooltip != null) {
      return _isDisabled ? '$tooltip, ${l10n.buttonDisabled}' : tooltip!;
    }

    return _isDisabled ? l10n.buttonDisabled : 'Icon button';
  }

  /// Handle button press with haptic feedback
  void _handlePressed() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}
