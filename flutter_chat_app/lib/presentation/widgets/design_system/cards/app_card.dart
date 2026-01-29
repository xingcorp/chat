import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/card_enums.dart';

/// **APP CARD**
///
/// A customizable card widget that follows the app's design system.
/// Provides three variants: elevated, outlined, and filled.
///
/// **Features**:
/// - Three variants (elevated, outlined, filled)
/// - Clickable and non-clickable modes
/// - Custom padding options
/// - Border radius configuration
/// - Shadow elevation levels
/// - Dark mode support
/// - Accessibility compliant
///
/// **Usage**:
/// ```dart
/// // Elevated card (default)
/// AppCard.elevated(
///   child: Column(
///     children: [
///       Text('Title'),
///       Text('Content'),
///     ],
///   ),
/// )
///
/// // Outlined card
/// AppCard.outlined(
///   child: ListTile(
///     title: Text('Item'),
///     subtitle: Text('Description'),
///   ),
/// )
///
/// // Clickable card
/// AppCard.elevated(
///   onTap: () => _handleTap(),
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Tap me'),
///   ),
/// )
///
/// // Filled card
/// AppCard.filled(
///   padding: EdgeInsets.all(24),
///   child: Text('Custom padding'),
/// )
/// ```
class AppCard extends BaseStatelessWidget {
  /// Private constructor for internal use
  const AppCard._({
    required this.child,
    required this.variant,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    super.key,
  });

  /// Creates an elevated card with shadow
  const AppCard.elevated({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    double? elevation,
    Color? color,
    double? width,
    double? height,
  }) : this._(
          key: key,
          child: child,
          variant: CardVariant.elevated,
          onTap: onTap,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          elevation: elevation,
          color: color,
          borderColor: null,
          width: width,
          height: height,
        );

  /// Creates an outlined card with border
  const AppCard.outlined({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? color,
    Color? borderColor,
    double? width,
    double? height,
  }) : this._(
          key: key,
          child: child,
          variant: CardVariant.outlined,
          onTap: onTap,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          elevation: null,
          color: color,
          borderColor: borderColor,
          width: width,
          height: height,
        );

  /// Creates a filled card with background color
  const AppCard.filled({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? color,
    double? width,
    double? height,
  }) : this._(
          key: key,
          child: child,
          variant: CardVariant.filled,
          onTap: onTap,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          elevation: null,
          color: color,
          borderColor: null,
          width: width,
          height: height,
        );

  /// Card content
  final Widget child;

  /// Card visual variant
  final CardVariant variant;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Padding inside card
  final EdgeInsetsGeometry? padding;

  /// Margin around card
  final EdgeInsetsGeometry? margin;

  /// Border radius
  final double? borderRadius;

  /// Elevation (shadow depth)
  final double? elevation;

  /// Background color
  final Color? color;

  /// Border color (for outlined variant)
  final Color? borderColor;

  /// Card width
  final double? width;

  /// Card height
  final double? height;

  /// Whether card is clickable
  bool get _isClickable => onTap != null;

  /// Get effective border radius
  double get _effectiveBorderRadius =>
      borderRadius ?? AppDimens.radiusCard;

  /// Get effective elevation
  double get _effectiveElevation {
    switch (variant) {
      case CardVariant.elevated:
        return elevation ?? AppDimens.elevationCard;
      case CardVariant.outlined:
      case CardVariant.filled:
        return AppDimens.elevationNone;
    }
  }

  /// Get effective padding
  EdgeInsetsGeometry get _effectivePadding =>
      padding ?? const EdgeInsets.all(AppDimens.paddingCard);

  /// Get effective margin
  EdgeInsetsGeometry get _effectiveMargin =>
      margin ?? const EdgeInsets.all(AppDimens.marginSmall);

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardContent = Container(
      width: width,
      height: height,
      padding: _effectivePadding,
      child: child,
    );

    Widget card;

    switch (variant) {
      case CardVariant.elevated:
        card = Card(
          elevation: _effectiveElevation,
          color: color ?? (isDark ? AppColors.surfaceDarkMode : AppColors.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_effectiveBorderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          margin: _effectiveMargin,
          child: cardContent,
        );
        break;

      case CardVariant.outlined:
        card = Card(
          elevation: AppDimens.elevationNone,
          color: color ?? (isDark ? AppColors.surfaceDarkMode : AppColors.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_effectiveBorderRadius),
            side: BorderSide(
              color: borderColor ??
                  (isDark ? AppColors.borderDarkMode : AppColors.border),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          margin: _effectiveMargin,
          child: cardContent,
        );
        break;

      case CardVariant.filled:
        card = Card(
          elevation: AppDimens.elevationNone,
          color: color ??
              (isDark
                  ? AppColors.surfaceDarkMode.withOpacity(0.8)
                  : AppColors.surface.withOpacity(0.8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_effectiveBorderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          margin: _effectiveMargin,
          child: cardContent,
        );
        break;
    }

    if (_isClickable) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_effectiveBorderRadius),
        child: card,
      );
    }

    return Semantics(
      button: _isClickable,
      enabled: _isClickable,
      child: card,
    );
  }
}
