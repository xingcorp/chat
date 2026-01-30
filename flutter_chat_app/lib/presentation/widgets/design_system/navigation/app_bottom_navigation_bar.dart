import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable bottom navigation bar component.
///
/// Features:
/// - Multiple navigation items
/// - Badge support for unread counts
/// - Active state indication
/// - Icon and label support
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppBottomNavigationBar(
///   currentIndex: 0,
///   onTap: (index) => navigateToTab(index),
///   items: [
///     AppBottomNavigationBarItem(
///       icon: Icons.chat,
///       label: 'Chats',
///       badge: 5,
///     ),
///     AppBottomNavigationBarItem(
///       icon: Icons.contacts,
///       label: 'Contacts',
///     ),
///     AppBottomNavigationBarItem(
///       icon: Icons.settings,
///       label: 'Settings',
///     ),
///   ],
/// )
/// ```
class AppBottomNavigationBar extends BaseStatelessWidget {
  /// Creates an [AppBottomNavigationBar].
  const AppBottomNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.type,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedFontSize,
    this.unselectedFontSize,
    this.iconSize,
    this.elevation,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    super.key,
  });

  /// The navigation items to display.
  final List<AppBottomNavigationBarItem> items;

  /// The index of the currently selected item.
  final int currentIndex;

  /// Called when a navigation item is tapped.
  final ValueChanged<int> onTap;

  /// The type of bottom navigation bar.
  final BottomNavigationBarType? type;

  /// The background color of the navigation bar.
  final Color? backgroundColor;

  /// The color of the selected item.
  final Color? selectedItemColor;

  /// The color of unselected items.
  final Color? unselectedItemColor;

  /// The font size of the selected item label.
  final double? selectedFontSize;

  /// The font size of unselected item labels.
  final double? unselectedFontSize;

  /// The size of the icons.
  final double? iconSize;

  /// The elevation of the navigation bar.
  final double? elevation;

  /// Whether to show labels for selected items.
  final bool showSelectedLabels;

  /// Whether to show labels for unselected items.
  final bool showUnselectedLabels;

  @override
  Widget buildContent(BuildContext context) {
    return BottomNavigationBar(
      items: items.map((item) => _buildNavigationBarItem(item)).toList(),
      currentIndex: currentIndex,
      onTap: onTap,
      type: type ?? BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      selectedFontSize: selectedFontSize ?? 12.0,
      unselectedFontSize: unselectedFontSize ?? 12.0,
      iconSize: iconSize ?? AppDimens.iconSizeMedium,
      elevation: elevation ?? 8.0,
      showSelectedLabels: showSelectedLabels,
      showUnselectedLabels: showUnselectedLabels,
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
    AppBottomNavigationBarItem item,
  ) {
    Widget icon = Icon(item.icon);
    Widget activeIcon = Icon(item.activeIcon ?? item.icon);

    // Add badge if present
    if (item.badge != null && item.badge! > 0) {
      icon = _buildIconWithBadge(icon, item.badge!);
      activeIcon = _buildIconWithBadge(activeIcon, item.badge!);
    }

    return BottomNavigationBarItem(
      icon: icon,
      activeIcon: activeIcon,
      label: item.label,
      tooltip: item.tooltip ?? item.label,
      backgroundColor: item.backgroundColor,
    );
  }

  Widget _buildIconWithBadge(Widget icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: EdgeInsets.all(AppDimens.paddingXSmall),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(
              minWidth: AppDimens.iconSizeSmall,
              minHeight: AppDimens.iconSizeSmall,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// A navigation bar item for [AppBottomNavigationBar].
class AppBottomNavigationBarItem {
  /// Creates an [AppBottomNavigationBarItem].
  const AppBottomNavigationBarItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
    this.tooltip,
    this.backgroundColor,
  });

  /// The icon to display.
  final IconData icon;

  /// The icon to display when active.
  final IconData? activeIcon;

  /// The label to display.
  final String label;

  /// Optional badge count.
  final int? badge;

  /// Optional tooltip.
  final String? tooltip;

  /// Optional background color.
  final Color? backgroundColor;
}
