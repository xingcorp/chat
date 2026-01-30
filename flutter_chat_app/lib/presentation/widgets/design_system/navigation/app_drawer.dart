import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// A customizable drawer component.
///
/// Features:
/// - Header support with user info
/// - Menu items with icons and badges
/// - Dividers for grouping
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppDrawer(
///   header: AppDrawerHeader(
///     avatar: CircleAvatar(child: Text('JD')),
///     name: 'John Doe',
///     email: 'john@example.com',
///   ),
///   items: [
///     AppDrawerItem(
///       icon: Icons.home,
///       title: 'Home',
///       onTap: () => navigateToHome(),
///     ),
///     AppDrawerItem(
///       icon: Icons.settings,
///       title: 'Settings',
///       badge: 2,
///       onTap: () => navigateToSettings(),
///     ),
///     AppDrawerDivider(),
///     AppDrawerItem(
///       icon: Icons.logout,
///       title: 'Logout',
///       onTap: () => logout(),
///     ),
///   ],
/// )
/// ```
class AppDrawer extends BaseStatelessWidget {
  /// Creates an [AppDrawer].
  const AppDrawer({
    this.header,
    required this.items,
    this.backgroundColor,
    this.elevation,
    this.width,
    super.key,
  });

  /// The header widget to display at the top.
  final Widget? header;

  /// The drawer items to display.
  final List<Widget> items;

  /// The background color of the drawer.
  final Color? backgroundColor;

  /// The elevation of the drawer.
  final double? elevation;

  /// The width of the drawer.
  final double? width;

  @override
  Widget buildContent(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      elevation: elevation,
      width: width,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (header != null) header!,
          ...items,
        ],
      ),
    );
  }
}

/// A header widget for [AppDrawer].
class AppDrawerHeader extends BaseStatelessWidget {
  /// Creates an [AppDrawerHeader].
  const AppDrawerHeader({
    this.avatar,
    this.name,
    this.email,
    this.decoration,
    this.margin,
    this.padding,
    this.onTap,
    super.key,
  });

  /// The avatar widget.
  final Widget? avatar;

  /// The user's name.
  final String? name;

  /// The user's email.
  final String? email;

  /// The decoration for the header.
  final Decoration? decoration;

  /// The margin around the header.
  final EdgeInsetsGeometry? margin;

  /// The padding inside the header.
  final EdgeInsetsGeometry? padding;

  /// Called when the header is tapped.
  final VoidCallback? onTap;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return DrawerHeader(
      decoration: decoration ??
          BoxDecoration(
            color: theme.colorScheme.primary,
          ),
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? EdgeInsets.all(AppDimens.paddingMedium),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (avatar != null) ...[
              avatar!,
              SizedBox(height: AppDimens.spaceSmall),
            ],
            if (name != null)
              Text(
                name!,
                style: AppTextStyles.titleLarge(context).copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (email != null) ...[
              SizedBox(height: AppDimens.spaceXSmall),
              Text(
                email!,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A menu item for [AppDrawer].
class AppDrawerItem extends BaseStatelessWidget {
  /// Creates an [AppDrawerItem].
  const AppDrawerItem({
    required this.title,
    this.icon,
    this.trailing,
    this.badge,
    this.selected = false,
    this.onTap,
    super.key,
  });

  /// The title of the item.
  final String title;

  /// The icon to display.
  final IconData? icon;

  /// Widget to display at the end.
  final Widget? trailing;

  /// Optional badge count.
  final int? badge;

  /// Whether this item is selected.
  final bool selected;

  /// Called when the item is tapped.
  final VoidCallback? onTap;

  @override
  Widget buildContent(BuildContext context) {
    Widget? trailingWidget = trailing;

    // Add badge if present
    if (badge != null && badge! > 0) {
      trailingWidget = Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSmall,
          vertical: AppDimens.paddingXSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
        constraints: BoxConstraints(
          minWidth: AppDimens.iconSizeSmall,
        ),
        child: Text(
          badge! > 99 ? '99+' : badge.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      trailing: trailingWidget,
      selected: selected,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingXSmall,
      ),
    );
  }
}

/// A divider for [AppDrawer].
class AppDrawerDivider extends BaseStatelessWidget {
  /// Creates an [AppDrawerDivider].
  const AppDrawerDivider({
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    super.key,
  });

  /// The height of the divider.
  final double? height;

  /// The thickness of the divider.
  final double? thickness;

  /// The indent from the start.
  final double? indent;

  /// The indent from the end.
  final double? endIndent;

  @override
  Widget buildContent(BuildContext context) {
    return Divider(
      height: height ?? AppDimens.spaceMedium,
      thickness: thickness ?? 1.0,
      indent: indent ?? AppDimens.paddingMedium,
      endIndent: endIndent ?? AppDimens.paddingMedium,
    );
  }
}
