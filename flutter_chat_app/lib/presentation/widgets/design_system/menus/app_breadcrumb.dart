import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/menus/menu_enums.dart';

/// **APP BREADCRUMB**
///
/// Navigation path with clickable segments and customizable separators.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Customizable separators (slash, chevron, arrow, etc.)
/// - Clickable segments with navigation callbacks
/// - Current page highlighting
/// - Overflow handling for long paths
/// - Responsive layout
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based navigation
///
/// **Usage**:
/// ```dart
/// // Basic breadcrumb
/// AppBreadcrumb(
///   items: [
///     BreadcrumbItem(label: 'Home', onTap: () => _goHome()),
///     BreadcrumbItem(label: 'Products', onTap: () => _goProducts()),
///     BreadcrumbItem(label: 'Details'), // Current page (no onTap)
///   ],
/// )
///
/// // With custom separator
/// AppBreadcrumb(
///   separator: BreadcrumbSeparator.chevron,
///   items: [...],
/// )
///
/// // With custom separator widget
/// AppBreadcrumb(
///   separator: BreadcrumbSeparator.custom,
///   customSeparator: Icon(Icons.arrow_forward_ios, size: 12),
///   items: [...],
/// )
///
/// // With overflow handling
/// AppBreadcrumb(
///   maxItems: 3, // Show first, last, and ellipsis
///   items: [...],
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic labels for navigation
/// - Keyboard navigation support
/// - Current page announced to screen readers
class AppBreadcrumb extends BaseStatelessWidget {
  /// Creates a breadcrumb navigation.
  const AppBreadcrumb({
    super.key,
    required this.items,
    this.separator = BreadcrumbSeparator.chevron,
    this.customSeparator,
    this.maxItems,
    this.textStyle,
    this.currentTextStyle,
    this.separatorColor,
  });

  /// Breadcrumb items
  final List<BreadcrumbItem> items;

  /// Separator style
  final BreadcrumbSeparator separator;

  /// Custom separator widget (used when separator is BreadcrumbSeparator.custom)
  final Widget? customSeparator;

  /// Maximum number of items to show (null = show all)
  /// When exceeded, shows first item, ellipsis, and last items
  final int? maxItems;

  /// Text style for clickable items
  final TextStyle? textStyle;

  /// Text style for current page (non-clickable item)
  final TextStyle? currentTextStyle;

  /// Separator color
  final Color? separatorColor;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayItems = _getDisplayItems();

    return Semantics(
      label: 'Breadcrumb navigation',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < displayItems.length; i++) ...[
            _buildBreadcrumbItem(
              context,
              displayItems[i],
              theme,
              isDark,
              isLast: i == displayItems.length - 1,
            ),
            if (i < displayItems.length - 1)
              _buildSeparator(context, theme, isDark),
          ],
        ],
      ),
    );
  }

  List<BreadcrumbItem> _getDisplayItems() {
    if (maxItems == null || items.length <= maxItems!) {
      return items;
    }

    // Show first item, ellipsis, and last (maxItems - 2) items
    final result = <BreadcrumbItem>[];
    result.add(items.first);
    result.add(BreadcrumbItem(label: '...', isEllipsis: true));

    final remainingCount = maxItems! - 2;
    final startIndex = items.length - remainingCount;
    result.addAll(items.sublist(startIndex));

    return result;
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item,
    ThemeData theme,
    bool isDark,
    {required bool isLast},
  ) {
    final isClickable = item.onTap != null && !item.isEllipsis;
    final isCurrent = isLast && !item.isEllipsis;

    final defaultTextStyle = AppTextStyles.bodyMedium.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6),
    );

    final defaultCurrentStyle = AppTextStyles.bodyMedium.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    if (item.isEllipsis) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXSmall),
        child: Text(
          item.label,
          style: textStyle ?? defaultTextStyle,
        ),
      );
    }

    if (!isClickable) {
      return Semantics(
        label: isCurrent ? 'Current page: ${item.label}' : item.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXSmall),
          child: Text(
            item.label,
            style: isCurrent
                ? (currentTextStyle ?? defaultCurrentStyle)
                : (textStyle ?? defaultTextStyle),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Navigate to ${item.label}',
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXSmall,
            vertical: AppDimens.paddingXSmall / 2,
          ),
          child: Text(
            item.label,
            style: (textStyle ?? defaultTextStyle)?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator(BuildContext context, ThemeData theme, bool isDark) {
    final color = separatorColor ??
        theme.colorScheme.onSurface.withOpacity(isDark ? 0.4 : 0.3);

    Widget separatorWidget;

    switch (separator) {
      case BreadcrumbSeparator.slash:
        separatorWidget = Text('/', style: TextStyle(color: color));
        break;
      case BreadcrumbSeparator.chevron:
        separatorWidget = Icon(
          Icons.chevron_right,
          size: AppDimens.iconSmall,
          color: color,
        );
        break;
      case BreadcrumbSeparator.greaterThan:
        separatorWidget = Text('>', style: TextStyle(color: color));
        break;
      case BreadcrumbSeparator.dot:
        separatorWidget = Text('•', style: TextStyle(color: color));
        break;
      case BreadcrumbSeparator.arrow:
        separatorWidget = Text('→', style: TextStyle(color: color));
        break;
      case BreadcrumbSeparator.custom:
        separatorWidget = customSeparator ??
            Icon(
              Icons.chevron_right,
              size: AppDimens.iconSmall,
              color: color,
            );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXSmall / 2),
      child: separatorWidget,
    );
  }
}

/// Breadcrumb item model
class BreadcrumbItem {
  /// Creates a breadcrumb item.
  const BreadcrumbItem({
    required this.label,
    this.onTap,
    this.isEllipsis = false,
  });

  /// Item label
  final String label;

  /// Callback when item is tapped (null for current page)
  final VoidCallback? onTap;

  /// Whether this is an ellipsis item (for overflow)
  final bool isEllipsis;
}
