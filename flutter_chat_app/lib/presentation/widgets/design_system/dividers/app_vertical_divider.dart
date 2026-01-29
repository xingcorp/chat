import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable vertical divider component.
///
/// Features:
/// - Customizable thickness and color
/// - Indent options
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppVerticalDivider()
///
/// AppVerticalDivider(
///   thickness: 2.0,
///   indent: 8.0,
///   endIndent: 8.0,
/// )
/// ```
class AppVerticalDivider extends BaseStatelessWidget {
  /// Creates an [AppVerticalDivider].
  const AppVerticalDivider({
    this.width,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
    super.key,
  });

  /// The width of the divider.
  final double? width;

  /// The thickness of the divider line.
  final double? thickness;

  /// The indent from the top.
  final double? indent;

  /// The indent from the bottom.
  final double? endIndent;

  /// The color of the divider.
  final Color? color;

  @override
  Widget buildContent(BuildContext context) {
    return VerticalDivider(
      width: width ?? AppDimens.spaceMedium,
      thickness: thickness ?? 1.0,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}
