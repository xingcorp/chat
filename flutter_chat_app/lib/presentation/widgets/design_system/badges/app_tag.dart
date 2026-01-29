import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// A customizable tag component for labels.
///
/// Features:
/// - Compact design
/// - Customizable colors
/// - Icon support
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppTag(
///   label: 'New',
///   color: Colors.blue,
/// )
///
/// AppTag(
///   label: 'Premium',
///   icon: Icons.star,
///   color: Colors.amber,
/// )
/// ```
class AppTag extends BaseStatelessWidget {
  /// Creates an [AppTag].
  const AppTag({
    required this.label,
    this.icon,
    this.color,
    this.textColor,
    this.onTap,
    super.key,
  });

  /// The label text.
  final String label;

  /// Optional icon.
  final IconData? icon;

  /// Background color.
  final Color? color;

  /// Text color.
  final Color? textColor;

  /// Called when tag is tapped.
  final VoidCallback? onTap;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = color ?? theme.colorScheme.primaryContainer;
    final tagTextColor = textColor ?? theme.colorScheme.onPrimaryContainer;

    Widget content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingSmall,
        vertical: AppDimens.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppDimens.iconSizeXSmall,
              color: tagTextColor,
            ),
            SizedBox(width: AppDimens.spaceXSmall),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: tagTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: content,
      );
    }

    return content;
  }
}
