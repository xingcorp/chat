import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/presence_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Premium PresenceIndicator — animated online/offline status dot
// ═══════════════════════════════════════════════════════════════════════════════

/// Premium presence indicator that shows an online/offline status dot with
/// a glowing pulse animation for online users.
///
/// **Online state**: Green dot ([AppColors.presenceOnline]) with a white border
/// and a concentric pulse ring that scales from 1.0 to
/// [AppDimens.presencePulseMaxScale] while fading from 0.6 to 0.0.
///
/// **Offline state**: Grey dot ([AppColors.textHint]) with a white border,
/// no animation.
///
/// **Performance & Accessibility**:
/// - Wrapped in [RepaintBoundary] for paint isolation.
/// - Respects [MediaQueryData.disableAnimations] — shows a static dot when
///   the platform requests reduced motion.
/// - Provides [Semantics] label ('Online' / 'Offline').
///
/// ```dart
/// PresenceIndicator(isOnline: true)
/// PresenceIndicator(isOnline: false, size: 16.0)
/// ```
class PresenceIndicator extends BaseStatefulWidget {
  /// Creates a presence indicator dot.
  const PresenceIndicator({
    required this.isOnline,
    this.size = AppDimens.presenceDotSize,
    this.borderWidth = AppDimens.presenceDotBorder,
    super.key,
  });

  /// Whether the user is currently online.
  final bool isOnline;

  /// Diameter of the status dot in logical pixels.
  final double size;

  /// Width of the white border around the dot.
  final double borderWidth;

  @override
  PresenceIndicatorState createState() => PresenceIndicatorState();
}

/// State for [PresenceIndicator].
///
/// Uses [SingleTickerProviderStateMixin] alongside [BaseState] because
/// the pulse animation requires a [Ticker]. [BaseState] already mixes in
/// [WidgetsBindingObserver]; Dart supports stacking mixins on subclasses,
/// so this is fully compatible.
class PresenceIndicatorState extends BaseState<PresenceIndicator>
    with SingleTickerProviderStateMixin {
  /// Duration of one pulse cycle.
  static const int _pulseDurationMs = 1500;

  /// Starting opacity of the pulse ring.
  static const double _pulseInitialOpacity = 0.6;

  AnimationController? _pulseController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(PresenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      if (widget.isOnline) {
        _setupAnimationIfNeeded();
      } else {
        _teardownAnimation();
      }
    }
  }

  @override
  void dispose() {
    _teardownAnimation();
    super.dispose();
  }

  /// Creates and starts the pulse animation controller + tweens.
  void _setupAnimationIfNeeded() {
    if (!widget.isOnline || _pulseController != null) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _pulseDurationMs),
    );

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppDimens.presencePulseMaxScale,
    ).animate(curved);

    _opacityAnimation = Tween<double>(
      begin: _pulseInitialOpacity,
      end: 0.0,
    ).animate(curved);

    _pulseController = controller;
    controller.repeat();
  }

  /// Stops and disposes the animation controller.
  void _teardownAnimation() {
    _pulseController?.dispose();
    _pulseController = null;
    _scaleAnimation = null;
    _opacityAnimation = null;
  }

  @override
  Widget build(BuildContext context) {
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final shouldAnimate =
        widget.isOnline && !animationsDisabled && _pulseController != null;

    // Total size accounts for the pulse ring at max scale so the widget
    // does not clip the glow.
    final dotWithBorder = widget.size + widget.borderWidth * 2;
    final totalSize = dotWithBorder * AppDimens.presencePulseMaxScale;

    return RepaintBoundary(
      child: Semantics(
        label: widget.isOnline ? 'Online' : 'Offline',
        child: SizedBox(
          width: totalSize,
          height: totalSize,
          child: Center(
            child: SizedBox(
              width: dotWithBorder,
              height: dotWithBorder,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring — only when online & animations enabled
                  if (shouldAnimate)
                    AnimatedBuilder(
                      animation: _pulseController!,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation?.value ?? 1.0,
                          child: Opacity(
                            opacity: _opacityAnimation?.value ?? 0.0,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: dotWithBorder,
                        height: dotWithBorder,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.presenceGlow,
                        ),
                      ),
                    ),

                  // Solid status dot with white border
                  Container(
                    width: dotWithBorder,
                    height: dotWithBorder,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isOnline
                          ? AppColors.presenceOnline
                          : AppColors.textHint,
                      border: Border.all(
                        color: AppColors.cardBackground,
                        width: widget.borderWidth,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PresenceIndicatorWithLabel — dot + text label (Online / Last seen …)
// ═══════════════════════════════════════════════════════════════════════════════

/// Presence indicator combined with a textual status label.
///
/// Shows either the [PresenceIndicator] dot, a text label, or both.
/// Used in chat headers, contact lists, etc.
class PresenceIndicatorWithLabel extends BaseStatelessWidget {
  /// Creates a presence indicator with optional label.
  const PresenceIndicatorWithLabel({
    required this.isOnline,
    this.lastSeen,
    this.showLabel = true,
    this.showDot = true,
    this.isLoading = false,
    this.dotSize = AppDimens.presenceDotSize,
    this.textStyle,
    super.key,
  });

  /// Whether the user is currently online.
  final bool isOnline;

  /// Last-seen timestamp (displayed when offline).
  final DateTime? lastSeen;

  /// Whether to display the text label.
  final bool showLabel;

  /// Whether to display the dot indicator.
  final bool showDot;

  /// Whether a loading spinner should replace the label.
  final bool isLoading;

  /// Diameter of the dot.
  final double dotSize;

  /// Custom text style override.
  final TextStyle? textStyle;

  @override
  Widget buildContent(BuildContext context) {
    if (isLoading && showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppProgressIndicator.circular(size: ProgressSize.small),
          const SizedBox(width: AppDimens.spaceXSmall),
          AppText(
            context.l10n.loading,
            style: _resolveTextStyle(),
          ),
        ],
      );
    }

    if (!showLabel) {
      if (!showDot) {
        return const SizedBox.shrink();
      }
      return PresenceIndicator(
        isOnline: isOnline,
        size: dotSize,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showDot)
          PresenceIndicator(
            isOnline: isOnline,
            size: dotSize,
          ),
        if (showDot) const SizedBox(width: AppDimens.spaceXSmall),
        AppText(
          _getStatusText(context.l10n),
          style: _resolveTextStyle(),
        ),
      ],
    );
  }

  String _getStatusText(AppLocalizations l10n) {
    if (isOnline) {
      return l10n.online;
    }

    if (lastSeen == null) {
      return l10n.offline;
    }

    final difference = DateTime.now().difference(lastSeen!);
    if (difference.inMinutes < 1) {
      return l10n.lastSeenRecently;
    }
    if (difference.inMinutes < 60) {
      return l10n.lastSeenMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.lastSeenHoursAgo(difference.inHours);
    }
    return l10n.lastSeenDaysAgo(difference.inDays);
  }

  TextStyle _resolveTextStyle() {
    return textStyle ??
        AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AvatarPresenceIndicator — positioned overlay for avatar stacks
// ═══════════════════════════════════════════════════════════════════════════════

/// Presence indicator designed to be positioned inside a [Stack] over an avatar.
///
/// Wraps [PresenceIndicator] in a [Positioned] widget pinned to the
/// bottom-right corner.
class AvatarPresenceIndicator extends BaseStatelessWidget {
  /// Creates an avatar-overlay presence indicator.
  const AvatarPresenceIndicator({
    required this.isOnline,
    this.size = AppDimens.presenceDotSize,
    this.offset = 0.0,
    super.key,
  });

  /// Whether the user is currently online.
  final bool isOnline;

  /// Diameter of the dot.
  final double size;

  /// Offset from the bottom-right corner of the parent [Stack].
  final double offset;

  @override
  Widget buildContent(BuildContext context) {
    // The PresenceIndicator bounding box is (size + borderWidth*2) * pulseMaxScale.
    // Compensate the positioning so the visible dot stays at the intended corner.
    final dotWithBorder = size + AppDimens.presenceDotBorder * 2;
    final pulseOffset = dotWithBorder * (AppDimens.presencePulseMaxScale - 1) / 2;
    return Positioned(
      bottom: offset - pulseOffset,
      right: offset - pulseOffset,
      child: PresenceIndicator(
        isOnline: isOnline,
        size: size,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LivePresenceIndicator — real-time stream-connected presence
// ═══════════════════════════════════════════════════════════════════════════════

/// Presence indicator connected to real-time [PresenceService].
///
/// Listens to a [UserPresence] stream and automatically updates the
/// displayed dot + label.
class LivePresenceIndicator extends BaseStatelessWidget {
  /// Creates a live presence indicator.
  const LivePresenceIndicator({
    required this.userId,
    this.showLabel = true,
    this.dotSize = AppDimens.presenceDotSize,
    this.textStyle,
    this.showDot = true,
    this.fallbackPresence,
    this.presenceStream,
    this.presenceService,
    super.key,
  });

  /// The user whose presence to observe.
  final String userId;

  /// Whether to display the text label.
  final bool showLabel;

  /// Diameter of the dot.
  final double dotSize;

  /// Custom text style override.
  final TextStyle? textStyle;

  /// Whether to display the dot indicator.
  final bool showDot;

  /// Presence to display when no stream data is available.
  final UserPresence? fallbackPresence;

  /// Explicit stream override (useful for testing).
  final Stream<UserPresence>? presenceStream;

  /// Explicit service override (useful for testing).
  final PresenceService? presenceService;

  @override
  Widget buildContent(BuildContext context) {
    final stream = _resolvePresenceStream();
    if (stream == null) {
      final fallback = fallbackPresence ?? UserPresence.offlineFor(userId);
      return PresenceIndicatorWithLabel(
        isOnline: fallback.isOnline,
        lastSeen: fallback.lastSeen,
        showLabel: showLabel,
        showDot: showDot,
        dotSize: dotSize,
        textStyle: textStyle,
      );
    }

    return StreamBuilder<UserPresence>(
      stream: stream,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            fallbackPresence == null;

        final presence = snapshot.hasError
            ? (fallbackPresence ?? UserPresence.offlineFor(userId))
            : (snapshot.data ?? fallbackPresence);

        return PresenceIndicatorWithLabel(
          isOnline: presence?.isOnline ?? false,
          lastSeen: presence?.lastSeen,
          showLabel: showLabel,
          showDot: showDot,
          dotSize: dotSize,
          textStyle: textStyle,
          isLoading: loading,
        );
      },
    );
  }

  Stream<UserPresence>? _resolvePresenceStream() {
    if (presenceStream != null) {
      return presenceStream;
    }

    if (presenceService != null) {
      return presenceService?.getUserPresenceStream(userId);
    }

    final getIt = GetIt.instance;
    if (!getIt.isRegistered<PresenceService>()) {
      return null;
    }

    return getIt<PresenceService>().getUserPresenceStream(userId);
  }
}
