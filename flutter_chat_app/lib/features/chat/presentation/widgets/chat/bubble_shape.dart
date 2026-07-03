import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Telegram-style asymmetric message bubble with gradient background for own
/// messages and solid color + border for others' messages.
///
/// The "tail" corner (smallest radius) sits at the **bottom** of the side
/// closest to the sender:
///   - Own messages  → tail at bottom-right
///   - Others' msgs  → tail at bottom-left
///
/// Grouped messages use a medium radius on the side that continues, so
/// consecutive bubbles from the same sender appear visually connected.
class BubbleShape extends BaseStatelessWidget {
  /// Whether this bubble belongs to the current user.
  final bool isOwn;

  /// First message in a consecutive group from the same sender.
  final bool isFirstInGroup;

  /// Last message in a consecutive group from the same sender.
  final bool isLastInGroup;

  /// The message content to wrap inside the bubble.
  final Widget child;

  const BubbleShape({
    super.key,
    required this.isOwn,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.child,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Border-radius logic
  // ──────────────────────────────────────────────────────────────────────────

  BorderRadius _buildBorderRadius() {
    const large = Radius.circular(AppDimens.bubbleRadiusLarge);
    const medium = Radius.circular(AppDimens.bubbleRadiusMedium);
    const small = Radius.circular(AppDimens.bubbleRadiusSmall);

    if (isOwn) {
      // Tail is at bottom-right
      return BorderRadius.only(
        topLeft: large,
        topRight: isFirstInGroup ? large : medium,
        bottomLeft: large,
        bottomRight: isLastInGroup ? small : medium,
      );
    }

    // Others — tail is at bottom-left
    return BorderRadius.only(
      topLeft: isFirstInGroup ? large : medium,
      topRight: large,
      bottomLeft: isLastInGroup ? small : medium,
      bottomRight: large,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Decoration logic
  // ──────────────────────────────────────────────────────────────────────────

  BoxDecoration _buildDecoration(bool isDark) {
    if (isOwn) {
      return const BoxDecoration(
        gradient: AppColors.bubbleOwnGradient,
      );
    }

    return BoxDecoration(
      color: isDark ? AppColors.bubbleOtherDark : AppColors.bubbleOtherLight,
      border: Border.all(
        color: isDark
            ? AppColors.bubbleOtherBorderDark
            : AppColors.bubbleOtherBorderLight,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = _buildBorderRadius();

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        decoration: _buildDecoration(isDark),
        child: child,
      ),
    );
  }
}
