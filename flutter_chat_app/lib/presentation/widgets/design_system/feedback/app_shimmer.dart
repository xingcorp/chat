import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_stateful_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A shimmer loading effect component.
///
/// Features:
/// - Smooth shimmer animation
/// - Customizable colors
/// - Customizable child widget
/// - Dark mode support
/// - Performance optimized
///
/// Example:
/// ```dart
/// // Basic shimmer
/// AppShimmer(
///   child: Container(
///     width: 200,
///     height: 20,
///     decoration: BoxDecoration(
///       color: Colors.white,
///       borderRadius: BorderRadius.circular(4),
///     ),
///   ),
/// )
///
/// // List item shimmer
/// AppShimmer.listItem()
///
/// // Card shimmer
/// AppShimmer.card()
/// ```
class AppShimmer extends BaseStatefulWidget {
  /// Creates an [AppShimmer].
  const AppShimmer({
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    super.key,
  });

  /// Creates a shimmer for a list item.
  factory AppShimmer.listItem({
    Key? key,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return AppShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: Row(
          children: [
            Container(
              width: AppDimens.avatarSizeMedium,
              height: AppDimens.avatarSizeMedium,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppDimens.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    ),
                  ),
                  SizedBox(height: AppDimens.spaceXSmall),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a shimmer for a card.
  factory AppShimmer.card({
    Key? key,
    Color? baseColor,
    Color? highlightColor,
    double? width,
    double? height,
  }) {
    return AppShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 200,
        margin: EdgeInsets.all(AppDimens.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
      ),
    );
  }

  /// The widget to apply shimmer effect to.
  final Widget child;

  /// The base color of the shimmer.
  final Color? baseColor;

  /// The highlight color of the shimmer.
  final Color? highlightColor;

  /// The duration of the shimmer animation.
  final Duration duration;

  @override
  AppShimmerState createState() => AppShimmerState();
}

/// State for [AppShimmer].
class AppShimmerState extends BaseState<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.baseColor ??
        (isDark
            ? theme.colorScheme.surfaceVariant
            : Colors.grey[300]!);

    final highlightColor = widget.highlightColor ??
        (isDark
            ? theme.colorScheme.surface
            : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
