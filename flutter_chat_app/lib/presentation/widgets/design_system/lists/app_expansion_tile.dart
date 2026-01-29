import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_stateful_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable expansion tile component with consistent styling.
///
/// Features:
/// - Leading widget support
/// - Title and subtitle
/// - Trailing widget (defaults to expand/collapse icon)
/// - Expandable children
/// - Initial expansion state
/// - Expansion callbacks
/// - Controlled expansion
/// - Accessibility compliant
/// - Dark mode support
/// - Smooth animations
///
/// Example:
/// ```dart
/// AppExpansionTile(
///   leading: Icon(Icons.folder),
///   title: 'Documents',
///   subtitle: '5 items',
///   children: [
///     AppListTile(title: 'Document 1'),
///     AppListTile(title: 'Document 2'),
///   ],
///   onExpansionChanged: (expanded) {
///     print('Expanded: $expanded');
///   },
/// )
/// ```
class AppExpansionTile extends BaseStatefulWidget {
  /// Creates an [AppExpansionTile].
  const AppExpansionTile({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.children = const [],
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior,
    this.controlAffinity,
    this.controller,
    this.enabled = true,
    super.key,
  });

  /// The primary content of the list tile.
  final String title;

  /// Widget to display before the title.
  final Widget? leading;

  /// Additional content displayed below the title.
  final String? subtitle;

  /// Widget to display instead of the default expansion arrow.
  final Widget? trailing;

  /// The widgets that are displayed when the tile expands.
  final List<Widget> children;

  /// Whether the tile is initially expanded.
  final bool initiallyExpanded;

  /// Called when the tile expands or collapses.
  final ValueChanged<bool>? onExpansionChanged;

  /// Whether the state of the children is maintained when the tile collapses.
  final bool maintainState;

  /// The tile's internal padding.
  final EdgeInsetsGeometry? tilePadding;

  /// The alignment of the children along the cross axis when expanded.
  final CrossAxisAlignment? expandedCrossAxisAlignment;

  /// The alignment of the children along the main axis when expanded.
  final Alignment? expandedAlignment;

  /// The padding around the children when expanded.
  final EdgeInsetsGeometry? childrenPadding;

  /// The background color when expanded.
  final Color? backgroundColor;

  /// The background color when collapsed.
  final Color? collapsedBackgroundColor;

  /// The text color when expanded.
  final Color? textColor;

  /// The text color when collapsed.
  final Color? collapsedTextColor;

  /// The icon color when expanded.
  final Color? iconColor;

  /// The icon color when collapsed.
  final Color? collapsedIconColor;

  /// The shape when expanded.
  final ShapeBorder? shape;

  /// The shape when collapsed.
  final ShapeBorder? collapsedShape;

  /// The clip behavior.
  final Clip? clipBehavior;

  /// Whether the expansion arrow is before or after the title.
  final ListTileControlAffinity? controlAffinity;

  /// Optional controller to programmatically control expansion.
  final ExpansionTileController? controller;

  /// Whether the tile is interactive.
  final bool enabled;

  @override
  AppExpansionTileState createState() => AppExpansionTileState();
}

/// State for [AppExpansionTile].
class AppExpansionTileState extends BaseState<AppExpansionTile>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _handleTap() {
    if (!widget.enabled) return;

    safeSetState(() {
      _isExpanded = !_isExpanded;
    });

    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: widget.key,
      leading: widget.leading,
      title: Text(widget.title),
      subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      trailing: widget.trailing,
      initiallyExpanded: widget.initiallyExpanded,
      onExpansionChanged: widget.enabled ? widget.onExpansionChanged : null,
      maintainState: widget.maintainState,
      tilePadding: widget.tilePadding ??
          EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
      expandedCrossAxisAlignment: widget.expandedCrossAxisAlignment,
      expandedAlignment: widget.expandedAlignment,
      childrenPadding: widget.childrenPadding ??
          EdgeInsets.only(
            left: AppDimens.paddingLarge,
            right: AppDimens.paddingMedium,
            bottom: AppDimens.paddingSmall,
          ),
      backgroundColor: widget.backgroundColor,
      collapsedBackgroundColor: widget.collapsedBackgroundColor,
      textColor: widget.textColor,
      collapsedTextColor: widget.collapsedTextColor,
      iconColor: widget.iconColor,
      collapsedIconColor: widget.collapsedIconColor,
      shape: widget.shape,
      collapsedShape: widget.collapsedShape,
      clipBehavior: widget.clipBehavior,
      controlAffinity: widget.controlAffinity,
      controller: widget.controller,
      children: widget.children,
    );
  }
}
