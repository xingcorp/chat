import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_stateless_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A customizable tab bar component.
///
/// Features:
/// - Multiple tabs
/// - Badge support for unread counts
/// - Active state indication
/// - Icon and text support
/// - Scrollable option
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppTabBar(
///   tabs: [
///     AppTab(text: 'All', badge: 10),
///     AppTab(text: 'Unread', badge: 5),
///     AppTab(text: 'Groups'),
///   ],
///   controller: tabController,
/// )
/// ```
class AppTabBar extends BaseStatelessWidget implements PreferredSizeWidget {
  /// Creates an [AppTabBar].
  const AppTabBar({
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.indicatorColor,
    this.indicatorWeight,
    this.indicatorPadding,
    this.indicator,
    this.indicatorSize,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.overlayColor,
    this.splashFactory,
    this.onTap,
    super.key,
  });

  /// The tabs to display.
  final List<AppTab> tabs;

  /// The tab controller.
  final TabController? controller;

  /// Whether the tab bar should be scrollable.
  final bool isScrollable;

  /// The color of the selection indicator.
  final Color? indicatorColor;

  /// The thickness of the selection indicator.
  final double? indicatorWeight;

  /// The padding of the selection indicator.
  final EdgeInsetsGeometry? indicatorPadding;

  /// The decoration of the selection indicator.
  final Decoration? indicator;

  /// The size of the selection indicator.
  final TabBarIndicatorSize? indicatorSize;

  /// The color of selected tab labels.
  final Color? labelColor;

  /// The text style of selected tab labels.
  final TextStyle? labelStyle;

  /// The padding of tab labels.
  final EdgeInsetsGeometry? labelPadding;

  /// The color of unselected tab labels.
  final Color? unselectedLabelColor;

  /// The text style of unselected tab labels.
  final TextStyle? unselectedLabelStyle;

  /// The overlay color.
  final MaterialStateProperty<Color?>? overlayColor;

  /// The splash factory.
  final InteractiveInkFeatureFactory? splashFactory;

  /// Called when a tab is tapped.
  final ValueChanged<int>? onTap;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget buildContent(BuildContext context) {
    return TabBar(
      tabs: tabs.map((tab) => _buildTab(tab)).toList(),
      controller: controller,
      isScrollable: isScrollable,
      indicatorColor: indicatorColor,
      indicatorWeight: indicatorWeight ?? 2.0,
      indicatorPadding: indicatorPadding ?? EdgeInsets.zero,
      indicator: indicator,
      indicatorSize: indicatorSize,
      labelColor: labelColor,
      labelStyle: labelStyle,
      labelPadding: labelPadding ?? EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
      unselectedLabelColor: unselectedLabelColor,
      unselectedLabelStyle: unselectedLabelStyle,
      overlayColor: overlayColor,
      splashFactory: splashFactory,
      onTap: onTap,
    );
  }

  Widget _buildTab(AppTab tab) {
    Widget child;

    if (tab.icon != null && tab.text != null) {
      // Icon + Text
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tab.icon, size: AppDimens.iconSizeSmall),
          SizedBox(height: AppDimens.spaceXSmall),
          Text(tab.text!),
        ],
      );
    } else if (tab.icon != null) {
      // Icon only
      child = Icon(tab.icon, size: AppDimens.iconSizeMedium);
    } else if (tab.text != null) {
      // Text only
      child = Text(tab.text!);
    } else {
      // Custom child
      child = tab.child ?? const SizedBox.shrink();
    }

    // Add badge if present
    if (tab.badge != null && tab.badge! > 0) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -12,
            top: 0,
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
                tab.badge! > 99 ? '99+' : tab.badge.toString(),
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

    return Tab(
      child: child,
      icon: null,
      text: null,
    );
  }
}

/// A tab for [AppTabBar].
class AppTab {
  /// Creates an [AppTab].
  const AppTab({
    this.text,
    this.icon,
    this.child,
    this.badge,
  }) : assert(
          text != null || icon != null || child != null,
          'Must provide at least one of text, icon, or child',
        );

  /// The text to display.
  final String? text;

  /// The icon to display.
  final IconData? icon;

  /// Custom child widget.
  final Widget? child;

  /// Optional badge count.
  final int? badge;
}
