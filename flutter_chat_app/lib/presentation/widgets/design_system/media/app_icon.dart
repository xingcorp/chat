import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/config/app_environment.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// A customizable icon component that supports both Material Icons (IconData)
/// and custom SVG icons (asset paths from [AppIcons]).
///
/// **Dual-mode rendering:**
/// - [AppIcon] with named `icon:` → renders Material [IconData] via [Icon]
/// - [AppIcon.svg] with positional path → renders SVG via [SvgPicture.asset]
///
/// Example with Material Icon:
/// ```dart
/// AppIcon(icon: Icons.home, size: IconSize.medium, color: Colors.blue)
/// ```
///
/// Example with SVG Icon:
/// ```dart
/// AppIcon.svg(AppIcons.send, size: 24, color: AppColors.primary)
/// ```
class AppIcon extends BaseStatelessWidget {
  /// Creates an [AppIcon] with a Material [IconData].
  const AppIcon({
    required this.icon,
    this.size = IconSize.medium,
    this.color,
    this.semanticLabel,
    super.key,
  }) : svgAsset = null,
       svgSize = null;

  /// Creates an [AppIcon] from an SVG asset path (use [AppIcons] constants).
  ///
  /// [size] is in logical pixels (default 24.0).
  const AppIcon.svg(
    this.svgAsset, {
    double? size,
    this.color,
    this.semanticLabel,
    super.key,
  }) : icon = null,
       svgSize = size,
       size = IconSize.medium;

  /// Material icon data. Mutually exclusive with [svgAsset].
  final IconData? icon;

  /// SVG asset path from [AppIcons]. Mutually exclusive with [icon].
  final String? svgAsset;

  /// The enum size of the icon (used for Material icon constructor).
  final IconSize size;

  /// Pixel size for SVG icons. If null, defaults to 24.0.
  final double? svgSize;

  /// The color of the icon.
  final Color? color;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget buildContent(BuildContext context) {
    if (svgAsset != null) {
      return _buildSvgIcon(context);
    }
    return _buildMaterialIcon(context);
  }

  Widget _buildMaterialIcon(BuildContext context) {
    return Icon(
      icon,
      size: _getSize(size),
      color: color,
      semanticLabel: semanticLabel,
    );
  }

  Widget _buildSvgIcon(BuildContext context) {
    final effectiveColor = color ?? _defaultIconColor(context);
    final effectiveSize = svgSize ?? 24.0;

    return SvgPicture.asset(
      svgAsset!,
      width: effectiveSize,
      height: effectiveSize,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      package: AppEnvironment.assetPackage,
    );
  }

  Color _defaultIconColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? AppColors.textPrimaryDarkMode
        : AppColors.textPrimary;
  }

  double _getSize(IconSize size) {
    switch (size) {
      case IconSize.xsmall:
        return AppDimens.iconSizeXSmall;
      case IconSize.small:
        return AppDimens.iconSizeSmall;
      case IconSize.medium:
        return AppDimens.iconSizeMedium;
      case IconSize.large:
        return AppDimens.iconSizeLarge;
      case IconSize.xlarge:
        return AppDimens.iconSizeXLarge;
    }
  }
}

/// Size variants for icons.
enum IconSize {
  /// Extra small icon.
  xsmall,

  /// Small icon.
  small,

  /// Medium icon.
  medium,

  /// Large icon.
  large,

  /// Extra large icon.
  xlarge,
}
