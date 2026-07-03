import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// Centralized animation constants and utilities for the Premium V2 design.
///
/// Provides standardized curves, durations, and helper methods to ensure
/// consistent animations across the app while respecting accessibility settings.
///
/// **Usage:**
/// ```dart
/// AnimatedContainer(
///   duration: AppAnimations.durationNormal,
///   curve: AppAnimations.curveDefault,
///   // ...
/// )
/// ```
class AppAnimations {
  const AppAnimations._();

  // ═══════════════════════════════════════════════════════════
  // Standard Curves
  // ═══════════════════════════════════════════════════════════

  /// Default easing curve for most transitions
  static const Curve curveDefault = Curves.easeInOut;

  /// Spring/elastic curve for playful animations (badges, bounces)
  static const Curve curveSpring = Curves.elasticOut;

  /// Bounce curve for entry animations
  static const Curve curveBounce = Curves.bounceOut;

  /// Sharp deceleration curve for slide-in effects
  static const Curve curveSharp = Curves.easeOutCubic;

  /// Smooth deceleration for fade-outs
  static const Curve curveSmooth = Curves.easeOut;

  // ═══════════════════════════════════════════════════════════
  // Standard Durations
  // ═══════════════════════════════════════════════════════════

  /// Fast duration for micro-interactions: 150ms
  static const Duration durationFast = Duration(
    milliseconds: AppDimens.durationFast,
  );

  /// Normal/medium duration for transitions: 300ms
  static const Duration durationNormal = Duration(
    milliseconds: AppDimens.durationMedium,
  );

  /// Slow duration for complex transitions: 500ms
  static const Duration durationSlow = Duration(
    milliseconds: AppDimens.durationSlow,
  );

  /// Page transition duration: 350ms
  static const Duration durationPageTransition = Duration(
    milliseconds: AppDimens.durationPageTransition,
  );

  // ═══════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════

  /// Calculate stagger delay for list item entrance animations.
  ///
  /// Returns a [Duration] proportional to [index], capped at [maxItems]
  /// to prevent excessively long animation sequences.
  ///
  /// **Example:**
  /// ```dart
  /// Future.delayed(AppAnimations.staggerDelay(index), () {
  ///   controller.forward();
  /// });
  /// ```
  static Duration staggerDelay(int index, {int maxItems = 10}) {
    final clampedIndex = index.clamp(0, maxItems);
    return Duration(
      milliseconds: clampedIndex * AppDimens.durationStagger,
    );
  }

  /// Check if animations should be reduced/disabled based on
  /// platform accessibility settings.
  ///
  /// Returns `true` when animations should play normally.
  /// Returns `false` when the user has requested reduced motion.
  ///
  /// **Usage:**
  /// ```dart
  /// if (AppAnimations.shouldAnimate(context)) {
  ///   controller.forward();
  /// } else {
  ///   controller.value = 1.0; // Skip to end state
  /// }
  /// ```
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration respecting accessibility settings.
  ///
  /// Returns [Duration.zero] if animations are disabled,
  /// otherwise returns the provided [duration].
  static Duration accessibleDuration(
    BuildContext context,
    Duration duration,
  ) {
    return shouldAnimate(context) ? duration : Duration.zero;
  }
}
