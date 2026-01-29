import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_stateless_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable app bar component with consistent styling.
///
/// Features:
/// - Title support (String or Widget)
/// - Leading widget (back button, menu icon, custom)
/// - Actions with badge support
/// - Bottom widget (for tabs)
/// - Flexible space (for collapsing effects)
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppAppBar(
///   title: 'Chat',
///   leading: IconButton(
///     icon: Icon(Icons.menu),
///     onPressed: () => openDrawer(),
///   ),
///   actions: [
///     AppIconButton(
///       icon: Icons.notifications,
///       badge: 5,
///       onPressed: () => openNotifications(),
///     ),
///     AppIconButton(
///       icon: Icons.more_vert,
///       onPressed: () => showMenu(),
///     ),
///   ],
/// )
/// ```
class AppAppBar extends BaseStatelessWidget implements PreferredSizeWidget {
  /// Creates an [AppAppBar].
  const AppAppBar({
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.flexibleSpace,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.centerTitle,
    this.titleSpacing,
    this.toolbarHeight,
    this.leadingWidth,
    this.automaticallyImplyLeading = true,
    this.scrolledUnderElevation,
    super.key,
  }) : assert(
          title == null || titleWidget == null,
          'Cannot provide both title and titleWidget',
        );

  /// The title text to display.
  final String? title;

  /// Custom title widget (alternative to title).
  final Widget? titleWidget;

  /// Widget to display before the title.
  final Widget? leading;

  /// Widgets to display after the title.
  final List<Widget>? actions;

  /// Widget to display at the bottom of the app bar.
  final PreferredSizeWidget? bottom;

  /// Widget to display behind the toolbar and bottom widget.
  final Widget? flexibleSpace;

  /// The background color of the app bar.
  final Color? backgroundColor;

  /// The foreground color of the app bar.
  final Color? foregroundColor;

  /// The elevation of the app bar.
  final double? elevation;

  /// The shadow color of the app bar.
  final Color? shadowColor;

  /// The surface tint color of the app bar.
  final Color? surfaceTintColor;

  /// Whether the title should be centered.
  final bool? centerTitle;

  /// The spacing around the title.
  final double? titleSpacing;

  /// The height of the toolbar.
  final double? toolbarHeight;

  /// The width of the leading widget.
  final double? leadingWidth;

  /// Whether to automatically imply the leading widget.
  final bool automaticallyImplyLeading;

  /// The elevation when scrolled under.
  final double? scrolledUnderElevation;

  @override
  Size get preferredSize {
    final double height = (toolbarHeight ?? kToolbarHeight) +
        (bottom?.preferredSize.height ?? 0.0);
    return Size.fromHeight(height);
  }

  @override
  Widget buildContent(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      actions: actions,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing ?? NavigationToolbar.kMiddleSpacing,
      toolbarHeight: toolbarHeight ?? kToolbarHeight,
      leadingWidth: leadingWidth ?? AppDimens.iconSizeLarge + AppDimens.paddingMedium,
      automaticallyImplyLeading: automaticallyImplyLeading,
      scrolledUnderElevation: scrolledUnderElevation,
    );
  }
}
