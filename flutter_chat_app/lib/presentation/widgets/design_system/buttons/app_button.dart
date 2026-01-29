import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';

/// **APP BUTTON**
///
/// A customizable button widget that follows the app's design system.
/// Provides several variants through named constructors and supports
/// loading states, icons, and full-width layouts.
///
/// **Features**:
/// - Multiple variants (primary, secondary, text, outlined)
/// - Three sizes (small, medium, large)
/// - Loading state with spinner
/// - Icon support
/// - Full width option
/// - Haptic feedback
/// - Dark mode support
/// - Accessibility compliant
///
/// **Usage**:
/// ```dart
/// // Primary button
/// AppButton.primary(
///   text: 'Save',
///   onPressed: () => _handleSave(),
/// )
///
/// // Button with icon
/// AppButton.primary(
///   text: 'Send',
///   icon: Icons.send,
///   onPressed: () => _handleSend(),
/// )
///
/// // Loading state
/// AppButton.primary(
///   text: 'Saving',
///   isLoading: true,
///   onPressed: () {},
/// )
///
/// // Full width button
/// AppButton.primary(
///   text: 'Continue',
///   isFullWidth: true,
///   onPressed: () => _handleContinue(),
/// )
/// ```
class AppButton extends BaseStatelessWidget {
  /// Private constructor for internal use
  const AppButton._({
    required this.text,
    required this.onPressed,
    required this.variant,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  });

  /// Creates a primary button with filled background
  const AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: ButtonVariant.primary,
          size: size,
          icon: icon,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
        );

  /// Creates a secondary button with filled background
  const AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: ButtonVariant.secondary,
          size: size,
          icon: icon,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
        );

  /// Creates a text button with no background
  const AppButton.text({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: ButtonVariant.text,
          size: size,
          icon: icon,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
        );

  /// Creates an outlined button with border
  const AppButton.outlined({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: ButtonVariant.outlined,
          size: size,
          icon: icon,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
        );

  /// Button text
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button visual variant
  final ButtonVariant variant;

  /// Button size
  final ButtonSize size;

  /// Optional icon to display before text
  final IconData? icon;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button should take full width
  final bool isFullWidth;

  /// Whether button is disabled
  bool get _isDisabled => onPressed == null || isLoading;

  /// Get button height based on size
  double get _height {
    switch (size) {
      case ButtonSize.small:
        return AppDimens.buttonHeightSmall;
      case ButtonSize.medium:
        return AppDimens.buttonHeightMedium;
      case ButtonSize.large:
        return AppDimens.buttonHeightLarge;
    }
  }

  /// Get horizontal padding based on size
  double get _horizontalPadding {
    switch (size) {
      case ButtonSize.small:
        return AppDimens.paddingSmall + AppDimens.paddingXSmall;
      case ButtonSize.medium:
        return AppDimens.paddingMedium;
      case ButtonSize.large:
        return AppDimens.paddingLarge;
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

  /// Get text style based on button size
  TextStyle _getTextStyle(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall();
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium();
      case ButtonSize.large:
        return AppTextStyles.buttonLarge();
    }
  }

  /// Get loading indicator size based on button size
  double get _loadingIndicatorSize {
    switch (size) {
      case ButtonSize.small:
        return AppDimens.iconSmall;
      case ButtonSize.medium:
        return AppDimens.iconSmall;
      case ButtonSize.large:
        return AppDimens.iconMedium;
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    Widget button = _buildButton(context);

    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  /// Build the appropriate button based on variant
  Widget _buildButton(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final content = _buildButtonContent(context);

    Widget button;
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: _isDisabled ? null : _handlePressed,
          style: buttonStyle,
          child: content,
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: _isDisabled ? null : _handlePressed,
          style: buttonStyle,
          child: content,
        );
        break;
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: _isDisabled ? null : _handlePressed,
          style: buttonStyle,
          child: content,
        );
        break;
    }

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      label: _getAccessibilityLabel(context),
      child: button,
    );
  }

  /// Build button content (icon + text or loading indicator)
  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: _loadingIndicatorSize,
        width: _loadingIndicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getLoadingIndicatorColor(context),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize),
          SizedBox(width: AppDimens.spaceSmall),
          Text(text, style: _getTextStyle(context)),
        ],
      );
    }

    return Text(text, style: _getTextStyle(context));
  }

  /// Get button style based on variant and size
  ButtonStyle _getButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(AppDimens.buttonMinWidth, _height),
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: _horizontalPadding),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
        ),
      ),
    );

    switch (variant) {
      case ButtonVariant.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withOpacity(0.5);
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return 0;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppDimens.elevationSmall;
            }
            return AppDimens.elevationButton;
          }),
        );

      case ButtonVariant.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.secondary.withOpacity(0.5);
            }
            return AppColors.secondary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return 0;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppDimens.elevationSmall;
            }
            return AppDimens.elevationButton;
          }),
        );

      case ButtonVariant.text:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return (isDark
                      ? AppColors.textPrimaryDarkMode
                      : AppColors.textPrimary)
                  .withOpacity(0.5);
            }
            return AppColors.primary;
          }),
          elevation: WidgetStateProperty.all(AppDimens.elevationNone),
        );

      case ButtonVariant.outlined:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withOpacity(0.5);
            }
            return AppColors.primary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: AppColors.primary.withOpacity(0.5),
                width: 1.5,
              );
            }
            return const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            );
          }),
          elevation: WidgetStateProperty.all(AppDimens.elevationNone),
        );
    }
  }

  /// Get loading indicator color based on variant
  Color _getLoadingIndicatorColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.text:
      case ButtonVariant.outlined:
        return AppColors.primary;
    }
  }

  /// Get accessibility label for button
  String _getAccessibilityLabel(BuildContext context) {
    final l10n = context.l10n;

    if (isLoading) {
      return '${text}, ${l10n.buttonLoading}';
    }

    if (_isDisabled) {
      return '${text}, ${l10n.buttonDisabled}';
    }

    String variantLabel;
    switch (variant) {
      case ButtonVariant.primary:
        variantLabel = l10n.primaryButton;
        break;
      case ButtonVariant.secondary:
        variantLabel = l10n.secondaryButton;
        break;
      case ButtonVariant.text:
        variantLabel = l10n.textButton;
        break;
      case ButtonVariant.outlined:
        variantLabel = l10n.outlinedButton;
        break;
    }

    return '$text, $variantLabel';
  }

  /// Handle button press with haptic feedback
  void _handlePressed() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}
