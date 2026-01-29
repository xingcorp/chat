/// **MENU ENUMS**
///
/// Enumerations for menu and navigation components.
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Type-safe enums for component configuration
///
/// **Usage**:
/// ```dart
/// AppContextMenu(
///   position: MenuPosition.bottomRight,
///   items: [...],
/// )
///
/// AppTooltip(
///   position: TooltipPosition.top,
///   child: Text('Hover me'),
/// )
///
/// AppBreadcrumb(
///   separator: BreadcrumbSeparator.chevron,
///   items: [...],
/// )
/// ```

/// Menu positioning relative to anchor point
enum MenuPosition {
  /// Position menu at top-left of anchor
  topLeft,

  /// Position menu at top-center of anchor
  topCenter,

  /// Position menu at top-right of anchor
  topRight,

  /// Position menu at bottom-left of anchor
  bottomLeft,

  /// Position menu at bottom-center of anchor
  bottomCenter,

  /// Position menu at bottom-right of anchor
  bottomRight,

  /// Position menu at left-center of anchor
  leftCenter,

  /// Position menu at right-center of anchor
  rightCenter,

  /// Auto-position based on available space
  auto,
}

/// Tooltip positioning relative to child widget
enum TooltipPosition {
  /// Position tooltip above the child
  top,

  /// Position tooltip below the child
  bottom,

  /// Position tooltip to the left of the child
  left,

  /// Position tooltip to the right of the child
  right,

  /// Position tooltip at top-left corner
  topLeft,

  /// Position tooltip at top-right corner
  topRight,

  /// Position tooltip at bottom-left corner
  bottomLeft,

  /// Position tooltip at bottom-right corner
  bottomRight,

  /// Auto-position based on available space
  auto,
}

/// Breadcrumb separator style
enum BreadcrumbSeparator {
  /// Forward slash separator (/)
  slash,

  /// Chevron right separator (›)
  chevron,

  /// Greater than separator (>)
  greaterThan,

  /// Dot separator (•)
  dot,

  /// Arrow separator (→)
  arrow,

  /// Custom separator (provided by user)
  custom,
}

/// Popover positioning relative to anchor
enum PopoverPosition {
  /// Position popover above the anchor (centered)
  top,

  /// Position popover above the anchor (left-aligned)
  topLeft,

  /// Position popover above the anchor (right-aligned)
  topRight,

  /// Position popover below the anchor (centered)
  bottom,

  /// Position popover below the anchor (left-aligned)
  bottomLeft,

  /// Position popover below the anchor (right-aligned)
  bottomRight,

  /// Position popover to the left of the anchor
  left,

  /// Position popover to the right of the anchor
  right,

  /// Auto-position based on available space
  auto,
}

/// Context menu trigger type
enum MenuTrigger {
  /// Show menu on tap
  tap,

  /// Show menu on long press
  longPress,

  /// Show menu on right click (desktop)
  rightClick,

  /// Show menu on secondary tap (mobile)
  secondaryTap,
}

/// Menu item type
enum MenuItemType {
  /// Regular menu item
  normal,

  /// Checkable menu item (with checkbox)
  checkable,

  /// Radio menu item (mutually exclusive)
  radio,

  /// Divider (separator line)
  divider,

  /// Submenu (opens another menu)
  submenu,
}
