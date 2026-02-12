import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Animated typing indicator with three bouncing dots.
///
/// Displays a smooth, professional typing animation using staggered
/// sine wave motion. Commonly used in chat interfaces to show when
/// other users are composing messages.
///
/// ## Features
/// - Staggered animation for natural feel
/// - Configurable dot size and color
/// - Smooth 60fps animation
/// - Minimal CPU usage (single AnimationController)
///
/// ## Usage
/// ```dart
/// // In chat list
/// if (chat.isTyping)
///   TypingIndicatorWidget()
///
/// // Custom styling
/// TypingIndicatorWidget(
///   dotSize: 5.0,
///   dotColor: Colors.blue,
/// )
/// ```
class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({
    super.key,
    this.dotSize = 4.0,
    this.dotColor,
  });

  /// Size of each dot in logical pixels.
  ///
  /// Default: 4.0 (appropriate for chat list tiles)
  final double dotSize;

  /// Color of the dots.
  ///
  /// Default: AppColors.primary
  final Color? dotColor;

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.dotColor ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Stagger each dot by 0.2 for wave effect
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);

            // Sine wave for smooth opacity bounce
            final opacity = (sin(progress * pi * 2) * 0.5 + 0.5);

            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
