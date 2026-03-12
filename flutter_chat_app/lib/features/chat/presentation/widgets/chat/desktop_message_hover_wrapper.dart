import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_action_callbacks.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_hover_action_bar.dart';

/// **DESKTOP MESSAGE HOVER WRAPPER** (Lark-style)
///
/// Wraps a [MessageItem] to add desktop hover action bar support.
/// On desktop, hovering over a message shows a compact floating toolbar
/// **beside** the message bubble — to the right for other users' messages,
/// and to the left for the current user's messages.
///
/// On mobile (or when [isDesktop] is false), this widget is a transparent
/// pass-through with zero overhead — it simply returns [child] directly.
///
/// **Key behaviors**:
/// - Uses [MouseRegion] for hover detection
/// - Uses [OverlayEntry] to render the action bar above the scroll container
/// - Uses [bubbleKey] to measure the actual bubble position for precise placement
/// - 200ms hide delay prevents flicker when cursor moves between message and bar
/// - Only one action bar is visible at a time (singleton pattern)
/// - Scroll events (both mouse wheel and precision touchpad) dismiss the bar
/// - Right-click opens the "More" actions popup directly
///
/// **Usage**:
/// ```dart
/// DesktopMessageHoverWrapper(
///   isDesktop: AppDimens.isDesktop(screenWidth),
///   isCurrentUser: uiState.isFromCurrentUser,
///   isTextMessage: uiState.contentType == ContentType.text,
///   enabled: !_isSelectionMode && uiState.message != null,
///   quickReactions: ['👍', '❤️', '😂', '😮', '😢', '😡'],
///   bubbleKey: bubbleKey,
///   callbacks: MessageActionCallbacks(...),
///   child: MessageItem(bubbleKey: bubbleKey, ...),
/// )
/// ```
class DesktopMessageHoverWrapper extends BaseStatefulWidget {
  /// The message widget to wrap (typically a [MessageItem])
  final Widget child;

  /// All action callbacks for the hover action bar
  final MessageActionCallbacks callbacks;

  /// Whether this message is from the current user (affects bar positioning)
  final bool isCurrentUser;

  /// Whether this is a text message (affects available actions in More menu)
  final bool isTextMessage;

  /// Whether the current screen width is desktop size
  final bool isDesktop;

  /// Quick reaction emojis to show in the emoji quick-picker popup
  final List<String> quickReactions;

  /// Whether hover actions are enabled (false in selection mode, deleted msgs)
  final bool enabled;

  /// Key attached to the message bubble [RepaintBoundary] inside [MessageItem].
  /// Used to measure the bubble's exact position for side-placement.
  /// When null, falls back to legacy above/below positioning.
  final GlobalKey? bubbleKey;

  const DesktopMessageHoverWrapper({
    super.key,
    required this.child,
    required this.callbacks,
    required this.isCurrentUser,
    required this.isTextMessage,
    required this.isDesktop,
    required this.quickReactions,
    this.enabled = true,
    this.bubbleKey,
  });

  @override
  State<DesktopMessageHoverWrapper> createState() =>
      _DesktopMessageHoverWrapperState();
}

class _DesktopMessageHoverWrapperState
    extends BaseState<DesktopMessageHoverWrapper> {
  /// Currently active instance — ensures only one bar is visible at a time
  static _DesktopMessageHoverWrapperState? _activeInstance;

  /// Scroll cooldown: after dismissing due to scroll, suppress re-showing
  /// the bar for a short period. This prevents the overlay from immediately
  /// reappearing when scrolling causes a new message to slide under the cursor
  /// (which triggers MouseRegion.onEnter on the new message).
  static bool _scrollCooldown = false;
  static Timer? _scrollCooldownTimer;

  /// Duration to suppress re-showing after scroll-triggered dismiss.
  /// Must be long enough for scroll inertia to settle.
  static const Duration _scrollCooldownDuration =
      Duration(milliseconds: 400);

  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  /// Timer to delay showing bar when stealing focus from another message.
  /// Prevents bar "jumping" when cursor crosses an intermediate message
  /// on the way to the currently active bar.
  Timer? _showTimer;

  bool _isMouseOnMessage = false;
  bool _isMouseOnBar = false;
  final GlobalKey _moreButtonKey = GlobalKey();

  /// Compact bar estimated height (4 icon buttons + padding).
  static const double _barHeight = 36.0;

  /// Compact bar estimated width (like + divider + 3 icons + padding).
  static const double _barWidth = 150.0;

  /// Gap between action bar and message bubble
  static const double _barGap = 4.0;

  /// Delay before hiding the action bar after mouse exits
  static const Duration _hideDelay = Duration(milliseconds: 200);

  /// Delay before stealing focus from another active bar.
  /// Allows cursor to pass through intermediate messages without jumping.
  static const Duration _showDelay = Duration(milliseconds: 150);

  @override
  void dispose() {
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _dismissOverlay();
    if (_activeInstance == this) {
      _activeInstance = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(DesktopMessageHoverWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If widget becomes disabled, dismiss any showing overlay
    if (!widget.enabled && oldWidget.enabled) {
      _dismissOverlay();
    }
  }

  // ---------------------------------------------------------------------------
  // Hover State Machine
  // ---------------------------------------------------------------------------

  void _onMessageMouseEnter() {
    _isMouseOnMessage = true;
    _hideTimer?.cancel();
    _showTimer?.cancel();

    // If there's already an active bar from a different message,
    // DON'T immediately steal focus. Delay to allow cursor to pass
    // through intermediate messages on the way to the active bar.
    if (_activeInstance != null && _activeInstance != this) {
      _showTimer = Timer(_showDelay, () {
        if (_isMouseOnMessage && mounted) {
          _activeInstance?._dismissOverlay();
          _showActionBar();
          _activeInstance = this;
        }
      });
      return;
    }

    _showActionBar();
    _activeInstance = this;
  }

  void _onMessageMouseExit() {
    _isMouseOnMessage = false;
    _showTimer?.cancel();
    _scheduleHideIfNeeded();
  }

  void _onBarMouseEnter() {
    _isMouseOnBar = true;
    _hideTimer?.cancel();
  }

  void _onBarMouseExit() {
    _isMouseOnBar = false;
    _scheduleHideIfNeeded();
  }

  void _scheduleHideIfNeeded() {
    if (_isMouseOnMessage || _isMouseOnBar) return;
    // Don't hide while the "More" popup is open — it has its own barrier.
    // When the popup dismisses, _onMorePopupDismissed re-triggers this check.
    if (MoreActionsPopup.isShowing) return;

    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (!_isMouseOnMessage && !_isMouseOnBar && !MoreActionsPopup.isShowing) {
        _dismissOverlay();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Overlay Management
  // ---------------------------------------------------------------------------

  void _showActionBar() {
    if (_overlayEntry != null) return;
    if (!mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayRenderBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayRenderBox == null) return;

    final messagePosition =
        renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
    final messageSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Calculate position — prefer beside the bubble (Lark-style)
    final positionData = _calculateBarPosition(
      messagePosition: messagePosition,
      messageSize: messageSize,
      screenSize: screenSize,
      overlayRenderBox: overlayRenderBox,
    );

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: positionData.dx,
        top: positionData.dy,
        child: Listener(
          // Dismiss on mouse-wheel scroll (traditional mouse)
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _dismissOverlay();
            }
          },
          // Dismiss on precision touchpad scroll (Windows/Mac trackpad)
          onPointerPanZoomStart: (_) => _dismissOverlay(),
          behavior: HitTestBehavior.translucent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: AppDimens.durationFast),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                // Slide in from the side (right for others, left for mine)
                offset: positionData.isBesideBubble
                    ? Offset(
                        widget.isCurrentUser
                            ? -(1 - value) * 4
                            : (1 - value) * 4,
                        0,
                      )
                    : Offset(0, (1 - value) * 4), // fallback: slide down
                child: child,
              ),
            ),
            child: CompactActionBar(
              callbacks: widget.callbacks,
              isCurrentUser: widget.isCurrentUser,
              isTextMessage: widget.isTextMessage,
              quickReactions: widget.quickReactions,
              onMouseEnter: _onBarMouseEnter,
              onMouseExit: _onBarMouseExit,
              moreButtonKey: _moreButtonKey,
              onMorePopupDismissed: _onMorePopupDismissed,
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  _BarPosition _calculateBarPosition({
    required Offset messagePosition,
    required Size messageSize,
    required Size screenSize,
    required RenderBox overlayRenderBox,
  }) {
    // -----------------------------------------------------------------------
    // STRATEGY 1: Use bubbleKey to position BESIDE the bubble (Lark-style)
    // -----------------------------------------------------------------------
    RenderBox? bubbleRenderBox;
    if (widget.bubbleKey?.currentContext != null) {
      final renderObj = widget.bubbleKey!.currentContext!.findRenderObject();
      if (renderObj is RenderBox && renderObj.hasSize) {
        bubbleRenderBox = renderObj;
      }
    }

    if (bubbleRenderBox != null) {
      final bubblePos = bubbleRenderBox.localToGlobal(
        Offset.zero,
        ancestor: overlayRenderBox,
      );
      final bubbleSize = bubbleRenderBox.size;

      double dx;
      double dy = bubblePos.dy - _barGap; // Align top, slight offset up
      bool isBeside = true;

      if (!widget.isCurrentUser) {
        // Others' messages: place bar to the RIGHT of the bubble
        dx = bubblePos.dx + bubbleSize.width + _barGap;

        // If not enough space on the right → fallback ABOVE
        if (dx + _barWidth > screenSize.width - AppDimens.paddingSmall) {
          dx = bubblePos.dx;
          dy = bubblePos.dy - _barHeight - _barGap;
          isBeside = false;
        }
      } else {
        // My messages: place bar to the LEFT of the bubble
        dx = bubblePos.dx - _barWidth - _barGap;

        // If not enough space on the left → fallback ABOVE
        if (dx < AppDimens.paddingSmall) {
          dx = bubblePos.dx + bubbleSize.width - _barWidth;
          dy = bubblePos.dy - _barHeight - _barGap;
          isBeside = false;
        }
      }

      // Clamp to screen edges
      dx = dx.clamp(
        AppDimens.paddingSmall,
        screenSize.width - _barWidth - AppDimens.paddingSmall,
      );
      dy = dy.clamp(
        AppDimens.paddingSmall,
        screenSize.height - _barHeight - AppDimens.paddingSmall,
      );

      return _BarPosition(dx, dy, isBesideBubble: isBeside);
    }

    // -----------------------------------------------------------------------
    // STRATEGY 2: Fallback — legacy above/below positioning (no bubbleKey)
    // -----------------------------------------------------------------------
    double dx;
    if (widget.isCurrentUser) {
      dx = messagePosition.dx + messageSize.width - _barWidth;
      if (dx < AppDimens.paddingSmall) {
        dx = AppDimens.paddingSmall;
      }
    } else {
      dx = messagePosition.dx + AppDimens.paddingSmall;
    }

    if (dx + _barWidth > screenSize.width - AppDimens.paddingSmall) {
      dx = screenSize.width - _barWidth - AppDimens.paddingSmall;
    }

    // Vertical: prefer above the message
    double dy = messagePosition.dy - _barHeight - _barGap;
    if (dy < AppDimens.paddingSmall) {
      dy = messagePosition.dy + messageSize.height + _barGap;
    }

    return _BarPosition(dx, dy);
  }

  void _dismissOverlay() {
    MoreActionsPopup.dismiss();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _hideTimer?.cancel();
    if (_activeInstance == this) {
      _activeInstance = null;
    }
  }

  /// Called when the "More" popup is dismissed (barrier tap or action item).
  /// Re-evaluates whether the action bar should also hide.
  void _onMorePopupDismissed() {
    _scheduleHideIfNeeded();
  }

  // ---------------------------------------------------------------------------
  // Right-click Context Menu
  // ---------------------------------------------------------------------------

  void _onSecondaryTap(TapUpDetails details) {
    MoreActionsPopup.show(
      context,
      anchor: details.globalPosition,
      isCurrentUser: widget.isCurrentUser,
      isTextMessage: widget.isTextMessage,
      onCopy: widget.callbacks.onCopy,
      onEdit: widget.callbacks.onEdit,
      onDelete: widget.callbacks.onDelete,
      onSelect: widget.callbacks.onSelect,
      onDismissed: _onMorePopupDismissed,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // On mobile or when disabled: zero-overhead pass-through
    if (!widget.isDesktop || !widget.enabled) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => _onMessageMouseEnter(),
      onExit: (_) => _onMessageMouseExit(),
      child: GestureDetector(
        onSecondaryTapUp: _onSecondaryTap,
        child: widget.child,
      ),
    );
  }
}

/// Position data class for the action bar overlay.
class _BarPosition {
  final double dx;
  final double dy;

  /// Whether the bar is placed beside the bubble (Lark-style) or above/below
  /// (legacy fallback). Controls animation direction.
  final bool isBesideBubble;

  const _BarPosition(this.dx, this.dy, {this.isBesideBubble = false});
}
