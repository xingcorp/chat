import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// A customizable section divider with text.
///
/// Features:
/// - Text label in the middle
/// - Customizable thickness and color
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppSectionDivider(text: 'OR')
///
/// AppSectionDivider(
///   text: 'Section 1',
///   thickness: 2.0,
/// )
/// ```
class AppSectionDivider extends BaseStatelessWidget {
  /// Creates an [AppSectionDivider].
  const AppSectionDivider({
    required this.text,
    this.thickness,
    this.color,
    this.textStyle,
    this.indent,
    this.endIndent,
    super.key,
  });

  /// The text to display.
  final String text;

  /// The thickness of the divider lines.
  final double? thickness;

  /// The color of the divider lines.
  final Color? color;

  /// The text style.
  final TextStyle? textStyle;

  /// The indent from the start.
  final double? indent;

  /// The indent from the end.
  final double? endIndent;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? theme.dividerColor;
    final dividerThickness = thickness ?? 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: indent ?? AppDimens.paddingMedium,
        vertical: AppDimens.paddingMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: dividerThickness,
              color: dividerColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall),
            child: Text(
              text,
              style: textStyle ??
                  AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Container(
              height: dividerThickness,
              color: dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}
