import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/badges/badge_enums.dart';

/// A customizable badge component.
///
/// Features:
/// - Notification badges for counts
/// - Status indicators
/// - Dot badges
/// - Customizable colors and sizes
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// // Notification badge
/// AppBadge.notification(count: 5)
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
    Key? key,
  }) : this(
          type: BadgeType.dot,
          color: color,
          key: key,
        );

  /// The count to display (for notification badges).
  final int? count;

  /// The type of badge.
  final BadgeType type;

  /// The background color.
  final Color? color;

  /// The text color.
  final Color? textColor;

  /// The size of the badge.
  final double? size;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.error;
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
    return Container(
      width: AppDimens.iconXSmall,
      height: AppDimens.iconXSmall,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
