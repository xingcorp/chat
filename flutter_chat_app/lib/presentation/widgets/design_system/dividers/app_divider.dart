import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable horizontal divider component.
///
/// Features:
/// - Customizable thickness and color
/// - Indent options
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppDivider()
///
/// AppDivider(
///   thickness: 2.0,
///   indent: 16.0,
///   endIndent: 16.0,
/// )
/// ```
class AppDivider extends BaseStatelessWidget {
  /// Creates an [AppDivider].
  const AppDivider({
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
    super.key,
  });

  /// The height of the divider.
  final double? height;

  /// The thickness of the divider line.
  final double? thickness;

  /// The indent from the start.
  final double? indent;

  /// The indent from the end.
  final double? endIndent;

  /// The color of the divider.
  final Color? color;

  @override
  Widget buildContent(BuildContext context) {
    return Divider(
      height: height ?? AppDimens.spaceMedium,
      thickness: thickness ?? 1.0,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}
