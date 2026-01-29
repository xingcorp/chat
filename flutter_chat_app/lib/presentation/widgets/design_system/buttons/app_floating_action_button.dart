import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **APP FLOATING ACTION BUTTON**
///
/// A customizable floating action button that follows the app's design system.
/// Supports regular and extended variants with optional mini size.
///
/// **Features**:
/// - Regular and extended variants
/// - Mini size option
/// - Icon and text support (extended)
/// - Haptic feedback
/// - Dark mode support
/// - Accessibility compliant
///
/// **Usage**:
/// ```dart
/// // Regular FAB
/// AppFloatingActionButton(
///   icon: Icons.add,
///   onPressed: () => _handleAdd(),
/// )
///
/// // Extended FAB with text
/// AppFloatingActionButton.extended(
///   icon: Icons.edit,
///   label: 'Compose',
///   onPressed: () => _handleCompose(),
/// )
///
/// // Mini FAB
/// AppFloatingActionButton(
///   icon: Icons.add,
///   onPressed: () => _handleAdd(),
///   isMini: true,
/// )
/// ```
class AppFloatingActionButton extends BaseStatelessWidget {
  /// Private constructor for internal use
  const AppFloatingActionButton._({
    required this.icon,
    required this.onPressed,
    this.label,
    this.isMini = false,
    this.tooltip,
    super.key,
  });

  /// Creates a regular floating action button
  const AppFloatingActionButton({
    Key? key,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isMini = false,
    String? tooltip,
  }) : this._(
          key: key,
          icon: icon,
          onPressed: onPressed,
          label: null,
          isMini: isMini,
          tooltip: tooltip,
        );

  /// Creates an extended floating action button with text
  const AppFloatingActionButton.extended({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
  }) : this._(
          key: key,
          icon: icon,
          onPressed: onPressed,
          label: label,
          isMini: false,
          tooltip: tooltip,
        );

  /// Icon to display
  final IconData icon;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Optional label for extended FAB
  final String? label;

  /// Whether button should be mini size
  final bool isMini;

  /// Optional tooltip text
  final String? tooltip;

  /// Whether button is disabled
  bool get _isDisabled => onPressed == null;

  /// Whether this is an extended FAB
  bool get _isExtended => label != null;

  /// Get FAB size
  double get _fabSize {
    if (isMini) {
      return AppDimens.fabSizeMini;
    }
    return AppDimens.fabSize;
  }

  /// Get icon size
  double get _iconSize {
    if (isMini) {
      return AppDimens.iconMedium;
    }
    return AppDimens.iconLarge;
  }

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);

    Widget fab;

    if (_isExtended) {
      // Extended FAB with icon and label
      fab = FloatingActionButton.extended(
        onPressed: _isDisabled ? null : _handlePressed,
        icon: Icon(icon, size: _iconSize),
        label: Text(
          label!,
          style: AppTextStyles.buttonMedium(color: Colors.white),
        ),
        backgroundColor: _isDisabled
            ? AppColors.primary.withOpacity(0.5)
            : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppDimens.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
        tooltip: tooltip ?? label,
      );
    } else {
      // Regular FAB
      fab = FloatingActionButton(
        onPressed: _isDisabled ? null : _handlePressed,
        mini: isMini,
        backgroundColor: _isDisabled
            ? AppColors.primary.withOpacity(0.5)
            : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppDimens.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
        tooltip: tooltip,
        child: Icon(icon, size: _iconSize),
      );
    }

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      label: _getAccessibilityLabel(context),
      child: fab,
    );
  }

  /// Get accessibility label for button
  String _getAccessibilityLabel(BuildContext context) {
    final l10n = context.l10n;

    String baseLabel;
    if (tooltip != null) {
      baseLabel = tooltip!;
    } else if (label != null) {
      baseLabel = label!;
    } else {
      baseLabel = 'Floating action button';
    }

    return _isDisabled ? '$baseLabel, ${l10n.buttonDisabled}' : baseLabel;
  }

  /// Handle button press with haptic feedback
  void _handlePressed() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}
