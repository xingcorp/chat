import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable icon component wrapper.
///
/// Features:
/// - Consistent sizing with AppDimens
/// - Color support
/// - Semantic label support
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppIcon(
///   icon: Icons.home,
///   size: IconSize.medium,
///   color: Colors.blue,
/// )
/// ```
class AppIcon extends BaseStatelessWidget {
  /// Creates an [AppIcon].
  const AppIcon({
    required this.icon,
    this.size = IconSize.medium,
    this.color,
    this.semanticLabel,
    super.key,
  });

  /// The icon to display.
  final IconData icon;

  /// The size of the icon.
  final IconSize size;

  /// The color of the icon.
  final Color? color;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget buildContent(BuildContext context) {
    return Icon(
      icon,
      size: _getSize(size),
      color: color,
      semanticLabel: semanticLabel,
    );
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
