import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/menus/menu_enums.dart';

/// **APP POPUP MENU**
///
/// Popup menu anchored to a widget (typically a button).
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Anchored positioning relative to parent widget
/// - Overflow menu pattern (three dots)
/// - Custom menu items with callbacks
/// - Checkable items support
/// - Nested submenus support
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Anchor-based menu with Material PopupMenuButton
///
/// **Usage**:
/// ```dart
/// // Basic popup menu
/// AppPopupMenu<String>(
///   items: [
///     PopupMenuItem(
///       value: 'edit',
///       child: Text('Edit'),
///     ),
///     PopupMenuItem(
///       value: 'delete',
///       child: Text('Delete'),
///     ),
///   ],
///   onSelected: (value) {
///     if (value == 'edit') _handleEdit();
///     if (value == 'delete') _handleDelete();
///   },
/// )
///
/// // With custom button
/// AppPopupMenu<String>(
///   icon: Icons.more_horiz,
///   items: [...],
///   onSelected: (value) => print(value),
/// )
///
/// // With checkable items
/// AppPopupMenu<String>(
///   items: [
///     CheckedPopupMenuItem(
///       value: 'notifications',
///       checked: notificationsEnabled,
///       child: Text('Notifications'),
///     ),
///   ],
///   onSelected: (value) => _toggleNotifications(),
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic labels for menu button
/// - Keyboard navigation support
/// - Focus management
class AppPopupMenu<T> extends BaseStatelessWidget {
  /// Creates a popup menu.
  const AppPopupMenu({
    super.key,
    required this.items,
    this.onSelected,
    this.onCanceled,
    this.icon,
    this.child,
    this.tooltip,
    this.position = PopupMenuPosition.under,
    this.elevation,
    this.padding,
    this.enabled = true,
    this.iconSize,
    this.color,
    this.shape,
  });

  /// Menu items to display
  final List<PopupMenuEntry<T>> items;

  /// Callback when an item is selected
  final void Function(T)? onSelected;

  /// Callback when menu is dismissed without selection
  final VoidCallback? onCanceled;

  /// Icon to display (defaults to more_vert)
  final IconData? icon;

  /// Custom child widget (overrides icon)
  final Widget? child;

  /// Tooltip for the menu button
  final String? tooltip;

  /// Menu position relative to anchor
  final PopupMenuPosition position;

  /// Menu elevation
  final double? elevation;

  /// Menu padding
  final EdgeInsetsGeometry? padding;

  /// Whether the menu button is enabled
  final bool enabled;

  /// Icon size
  final double? iconSize;

  /// Menu background color
  final Color? color;

  /// Menu shape
  final ShapeBorder? shape;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<T>(
      itemBuilder: (context) => items,
      onSelected: onSelected,
      onCanceled: onCanceled,
      tooltip: tooltip ?? l10n?.messageOptions,
      position: position,
      elevation: elevation ?? 8,
      padding: padding ?? EdgeInsets.zero,
      enabled: enabled,
      iconSize: iconSize ?? AppDimens.iconMedium,
      color: color,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
      icon: child == null
          ? Icon(
              icon ?? Icons.more_vert,
              size: iconSize ?? AppDimens.iconMedium,
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.disabledColor,
            )
          : null,
      child: child,
    );
  }
}

/// Creates a standard popup menu item with icon and label.
///
/// **Usage**:
/// ```dart
/// createPopupMenuItem<String>(
///   value: 'edit',
///   icon: Icons.edit,
///   label: 'Edit',
/// )
/// ```
PopupMenuItem<T> createPopupMenuItem<T>({
  required T value,
  required String label,
  IconData? icon,
  bool enabled = true,
  VoidCallback? onTap,
}) {
  return PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    onTap: onTap,
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppDimens.iconSmall),
          const SizedBox(width: AppDimens.spaceSmall),
        ],
        Text(label),
      ],
    ),
  );
}

/// Creates a checkable popup menu item.
///
/// **Usage**:
/// ```dart
/// createCheckableMenuItem<String>(
///   value: 'notifications',
///   label: 'Notifications',
///   checked: true,
/// )
/// ```
CheckedPopupMenuItem<T> createCheckableMenuItem<T>({
  required T value,
  required String label,
  required bool checked,
  bool enabled = true,
}) {
  return CheckedPopupMenuItem<T>(
    value: value,
    checked: checked,
    enabled: enabled,
    child: Text(label),
  );
}

/// Creates a popup menu divider.
///
/// **Usage**:
/// ```dart
/// createPopupMenuDivider()
/// ```
PopupMenuDivider createPopupMenuDivider() {
  return const PopupMenuDivider(height: AppDimens.paddingSmall);
}
