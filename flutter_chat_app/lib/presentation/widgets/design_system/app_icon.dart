import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// A widget that renders SVG icons from the `assets/icons/` directory.
///
/// Designed to be a drop-in replacement for [Icon] widget when using
/// custom SVG icons via [AppIcons] path constants.
///
/// Features:
/// - Automatic dark/light mode color adaptation
/// - Consistent sizing across the app
/// - SVG asset caching via [SvgPicture.asset]
///
/// Usage:
/// ```dart
/// AppIcon(AppIcons.send)
/// AppIcon(AppIcons.search, size: 20, color: AppColors.primary)
/// AppIcon(AppIcons.navChatActive, size: 28)
/// ```
///
/// For icon buttons, use with [IconButton]:
/// ```dart
/// IconButton(
///   icon: AppIcon(AppIcons.search, size: 22),
///   onPressed: () {},
/// )
/// ```
class AppIcon extends StatelessWidget {
  /// Creates an SVG icon widget.
  ///
  /// [assetPath] should be a constant from [AppIcons], e.g. `AppIcons.send`.
  /// [size] defaults to 24.0 (standard icon size).
  /// [color] defaults to the theme's icon color if not specified.
  const AppIcon(
    this.assetPath, {
    this.size = 24.0,
    this.color,
    super.key,
  });

  /// Asset path to the SVG file (use [AppIcons] constants).
  final String assetPath;

  /// Icon size (width and height). Defaults to 24.0.
  final double size;

  /// Icon color. If null, uses the theme-appropriate icon color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _defaultColor(context);

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }

  Color _defaultColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? AppColors.textPrimaryDarkMode
        : AppColors.textPrimary;
  }
}
