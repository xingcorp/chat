import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/badges/badge_enums.dart';

/// A customizable badge component.
///
/// Features:
/// - Notification badges for counts (primary color)
/// - Muted notification badges (gray) for silenced chats
/// - Status indicators
/// - Dot badges
/// - Customizable colors and sizes
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// // Notification badge (primary color)
/// AppBadge.notification(count: 5)
///
/// // Muted notification badge (gray)
/// AppBadge.muted(count: 3)
///
/// // Status badge
/// AppBadge.status(color: Colors.green)
///
/// // Dot badge
/// AppBadge.dot()
/// ```
class AppBadge extends BaseStatelessWidget {
  /// Creates an [AppBadge].
  const AppBadge({
    this.count,
    this.type = BadgeType.notification,
    this.color,
    this.textColor,
    this.size,
    this.isMuted = false,
    super.key,
  });

  /// Creates a notification badge with count.
  const AppBadge.notification({
    required int count,
    Color? color,
    Color? textColor,
    double? size,
    Key? key,
  }) : this(
          count: count,
          type: BadgeType.notification,
          color: color,
          textColor: textColor,
          size: size,
          isMuted: false,
          key: key,
        );

  /// Creates a muted notification badge with a gray background.
  ///
  /// Used for muted/silenced chats where notifications are suppressed.
  /// Displays the same count text but with a subdued gray background
  /// to visually distinguish muted conversations from active ones.
  const AppBadge.muted({
    required int count,
    Color? textColor,
    double? size,
    Key? key,
  }) : this(
          count: count,
          type: BadgeType.notification,
          textColor: textColor,
          size: size,
          isMuted: true,
          key: key,
        );

  /// Creates a status badge.
  const AppBadge.status({
    Color? color,
    double? size,
    Key? key,
  }) : this(
          type: BadgeType.status,
          color: color,
          size: size,
          key: key,
        );

  /// Creates a dot badge.
  const AppBadge.dot({
    Color? color,
    double? size,
    Key? key,
  }) : this(
          type: BadgeType.dot,
          color: color,
          size: size,
          key: key,
        );

  /// The count to display (for notification badges).
  final int? count;

  /// The type of badge.
  final BadgeType type;

  /// The background color. When [isMuted] is true and [color] is null,
  /// defaults to a gray color instead of the theme error color.
  final Color? color;

  /// The text color.
  final Color? textColor;

  /// The size of the badge.
  final double? size;

  /// Whether the badge represents a muted/silenced chat.
  /// When true, the badge uses a gray background color by default.
  final bool isMuted;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve badge background color:
    // 1. Explicit color param takes priority
    // 2. Muted → gray
    // 3. Default → theme error (red)
    final Color badgeColor;
    if (color != null) {
      badgeColor = color!;
    } else if (isMuted) {
      badgeColor = isDark ? AppColors.greyDark : AppColors.textSecondary;
    } else {
      badgeColor = theme.colorScheme.error;
    }

    final badgeTextColor = textColor ?? theme.colorScheme.onError;

    switch (type) {
      case BadgeType.notification:
      case BadgeType.count:
        return _buildCountBadge(badgeColor, badgeTextColor);
      case BadgeType.status:
        return _buildStatusBadge(badgeColor);
      case BadgeType.dot:
        return _buildDotBadge(badgeColor);
    }
  }

  Widget _buildCountBadge(Color backgroundColor, Color textColor) {
    final badgeSize = size ?? AppDimens.iconSmall;
    final displayCount = count ?? 0;
    final displayText = displayCount > 99 ? '99+' : displayCount.toString();

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingXSmall),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    final badgeSize = size ?? AppDimens.iconSmall;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
      ),
    );
  }

  Widget _buildDotBadge(Color color) {
    final badgeSize = size ?? AppDimens.iconXSmall;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
