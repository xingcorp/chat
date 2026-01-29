import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_stateless_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable list tile component with consistent styling.
///
/// Features:
/// - Leading widget support (icon, avatar, etc.)
/// - Title and subtitle
/// - Trailing widget support (icon, badge, etc.)
/// - Tap and long press callbacks
/// - Selected state
/// - Enabled/disabled state
/// - Dense mode for compact lists
/// - Divider option
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppListTile(
///   leading: CircleAvatar(child: Text('JD')),
///   title: 'John Doe',
///   subtitle: 'Software Engineer',
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => navigateToProfile(),
///   selected: isSelected,
/// )
/// ```
class AppListTile extends BaseStatelessWidget {
  /// Creates an [AppListTile].
  const AppListTile({
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.dense = false,
    this.isThreeLine = false,
    this.contentPadding,
    this.visualDensity,
    this.shape,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    super.key,
  });

  /// Widget to display before the title.
  final Widget? leading;

  /// The primary content of the list tile.
  final String? title;

  /// Additional content displayed below the title.
  final String? subtitle;

  /// Widget to display after the title.
  final Widget? trailing;

  /// Called when the user taps this list tile.
  final VoidCallback? onTap;

  /// Called when the user long-presses on this list tile.
  final VoidCallback? onLongPress;

  /// Whether this list tile is selected.
  final bool selected;

  /// Whether this list tile is interactive.
  final bool enabled;

  /// Whether this list tile is part of a vertically dense list.
  final bool dense;

  /// Whether this list tile is intended to display three lines of text.
  final bool isThreeLine;

  /// The tile's internal padding.
  final EdgeInsetsGeometry? contentPadding;

  /// Defines how compact the list tile's layout will be.
  final VisualDensity? visualDensity;

  /// The shape of the tile's InkWell.
  final ShapeBorder? shape;

  /// The color for the tile's Material when it has the input focus.
  final Color? selectedColor;

  /// The color for the tile's icons.
  final Color? iconColor;

  /// The color for the tile's text.
  final Color? textColor;

  /// The tile's background color.
  final Color? tileColor;

  /// The tile's background color when selected.
  final Color? selectedTileColor;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  final bool? enableFeedback;

  /// The horizontal gap between the leading and title widgets.
  final double? horizontalTitleGap;

  /// The minimum padding on the top and bottom of the title and subtitle widgets.
  final double? minVerticalPadding;

  /// The minimum width allocated for the leading widget.
  final double? minLeadingWidth;

  /// The text style for the title.
  final TextStyle? titleTextStyle;

  /// The text style for the subtitle.
  final TextStyle? subtitleTextStyle;

  /// The text style for the leading and trailing widgets.
  final TextStyle? leadingAndTrailingTextStyle;

  @override
  Widget buildContent(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title != null ? Text(title!) : null,
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      selected: selected,
      enabled: enabled,
      dense: dense,
      isThreeLine: isThreeLine,
      contentPadding: contentPadding ??
          EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
      visualDensity: visualDensity,
      shape: shape,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap ?? AppDimens.spaceSmall,
      minVerticalPadding: minVerticalPadding ?? AppDimens.paddingSmall,
      minLeadingWidth: minLeadingWidth ?? AppDimens.iconSizeLarge,
      titleTextStyle: titleTextStyle,
      subtitleTextStyle: subtitleTextStyle,
      leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
    );
  }
}
