import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/menus/menu_enums.dart';

/// **APP CONTEXT MENU**
///
/// Context menu displayed at tap/click position with automatic edge detection.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Position at tap coordinates
/// - Automatic edge detection and repositioning
/// - Menu items with icons and labels
/// - Dividers for grouping
/// - Dismiss on outside tap
/// - Keyboard navigation support
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Overlay-based menu with smart positioning
///
/// **Usage**:
/// ```dart
/// // Show context menu on tap
/// void _showContextMenu(BuildContext context, Offset position) {
///   showContextMenu(
///     context: context,
///     position: position,
///     items: [
///       ContextMenuItem(
///         icon: Icons.edit,
///         label: 'Edit',
///         onTap: () => _handleEdit(),
///       ),
///       ContextMenuItem(
///         icon: Icons.delete,
///         label: 'Delete',
///         onTap: () => _handleDelete(),
///         destructive: true,
///       ),
///       ContextMenuItem.divider(),
///       ContextMenuItem(
///         icon: Icons.share,
///         label: 'Share',
///         onTap: () => _handleShare(),
///       ),
///     ],
///   );
/// }
/// ```
///
/// **Accessibility**:
/// - Semantic labels for menu items
/// - Keyboard navigation support
/// - Focus management
class AppContextMenu extends BaseStatelessWidget {
  /// Creates a context menu.
  const AppContextMenu({
    super.key,
    required this.items,
    this.width = 200,
    this.maxHeight,
    this.elevation = 8,
    this.borderRadius,
  });

  /// Menu items to display
  final List<ContextMenuItem> items;

  /// Menu width
  final double width;

  /// Maximum menu height (scrollable if exceeded)
  final double? maxHeight;

  /// Menu elevation
  final double elevation;

  /// Menu border radius
  final BorderRadius? borderRadius;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: elevation,
      borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.radiusMedium),
      color: theme.colorScheme.surface,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.6,
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingXSmall),
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildMenuItem(context, item, theme, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    ContextMenuItem item,
    ThemeData theme,
    bool isDark,
  ) {
    if (item.isDivider) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingXSmall),
        child: Divider(
          height: 1,
          thickness: 1,
          color: theme.dividerColor,
        ),
      );
    }

    final isDestructive = item.destructive ?? false;
    final isDisabled = item.enabled == false;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: item.label,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                Navigator.of(context).pop();
                item.onTap?.call();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: AppDimens.iconSmall,
                  color: isDisabled
                      ? theme.disabledColor
                      : isDestructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppDimens.spaceSmall),
              ],
              Expanded(
                child: Text(
                  item.label ?? '',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: isDisabled
                        ? theme.disabledColor
                        : isDestructive
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (item.trailing != null) ...[
                const SizedBox(width: AppDimens.spaceSmall),
                item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Context menu item model
class ContextMenuItem {
  /// Creates a context menu item.
  const ContextMenuItem({
    this.icon,
    this.label,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
    this.trailing,
  }) : isDivider = false;

  /// Creates a divider menu item.
  const ContextMenuItem.divider()
      : icon = null,
        label = null,
        onTap = null,
        destructive = false,
        enabled = true,
        trailing = null,
        isDivider = true;

  /// Menu item icon
  final IconData? icon;

  /// Menu item label
  final String? label;

  /// Callback when item is tapped
  final VoidCallback? onTap;

  /// Whether this is a destructive action (red color)
  final bool destructive;

  /// Whether the item is enabled
  final bool enabled;

  /// Trailing widget (e.g., shortcut key)
  final Widget? trailing;

  /// Whether this is a divider
  final bool isDivider;
}

/// Shows a context menu at the specified position.
///
/// Returns a [Future] that completes when the menu is dismissed.
///
/// **Usage**:
/// ```dart
/// await showContextMenu(
///   context: context,
///   position: Offset(100, 200),
///   items: [
///     ContextMenuItem(
///       icon: Icons.edit,
///       label: 'Edit',
///       onTap: () => print('Edit'),
///     ),
///   ],
/// );
/// ```
Future<T?> showContextMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuItem> items,
  double width = 200,
  double? maxHeight,
  double elevation = 8,
  BorderRadius? borderRadius,
}) {
  final screenSize = MediaQuery.of(context).size;
  final menuHeight = maxHeight ?? screenSize.height * 0.6;

  // Calculate menu position with edge detection
  double left = position.dx;
  double top = position.dy;

  // Adjust horizontal position if menu would overflow right edge
  if (left + width > screenSize.width) {
    left = screenSize.width - width - AppDimens.paddingMedium;
  }

  // Adjust vertical position if menu would overflow bottom edge
  if (top + menuHeight > screenSize.height) {
    top = screenSize.height - menuHeight - AppDimens.paddingMedium;
  }

  // Ensure menu doesn't go off left edge
  if (left < AppDimens.paddingMedium) {
    left = AppDimens.paddingMedium;
  }

  // Ensure menu doesn't go off top edge
  if (top < AppDimens.paddingMedium) {
    top = AppDimens.paddingMedium;
  }

  return showDialog<T>(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    builder: (context) => Stack(
      children: [
        // Invisible barrier for dismissal
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Context menu
        Positioned(
          left: left,
          top: top,
          child: AppContextMenu(
            items: items,
            width: width,
            maxHeight: maxHeight,
            elevation: elevation,
            borderRadius: borderRadius,
          ),
        ),
      ],
    ),
  );
}
