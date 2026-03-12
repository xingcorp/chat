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

  /// After a scroll-triggered dismiss, suppress re-showing until the user
  /// actually moves the mouse cursor. This matches Slack/Discord/Lark behavior.
  ///
  /// Why this works: `MouseRegion.onEnter` fires both when the user moves the
  /// cursor INTO a message AND when content scrolls causing a message to slide
  /// under a stationary cursor. These are indistinguishable from `onEnter` alone.
  /// But `MouseRegion.onHover` (PointerHoverEvent) ONLY fires on actual cursor
  /// movement — NOT when content scrolls under a stationary cursor.
  ///
  /// Flow: scroll → dismiss + suppress → onEnter blocked → user moves mouse →
  /// onHover clears suppress → bar shows.
  static bool _suppressUntilMouseMove = false;

  /// Timestamp of the most recent scroll event. Used by [_onMessageMouseMove]
  /// to avoid clearing the suppress flag during active scrolling — touchpad
  /// gestures can cause micro cursor movements (wobble) that trigger onHover
  /// even though the user is still scrolling. Creating and immediately
  /// destroying an OverlayEntry during scroll causes a visible hitch.
  static DateTime _lastScrollEventAt = DateTime(0);

  /// Minimum time after last scroll event before allowing suppress to clear.
  static const Duration _scrollSettleThreshold =
      Duration(milliseconds: 150);

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

    // After scroll dismiss, wait for actual mouse movement before showing.
    // This prevents flicker when content scrolls under a stationary cursor.
    if (_suppressUntilMouseMove) return;

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

  /// Called on actual mouse cursor movement ([PointerHoverEvent]).
  ///
  /// This ONLY fires when the user physically moves the cursor — NOT when
  /// content scrolls under a stationary cursor. Used to clear the scroll
  /// suppress flag and re-enable hover action bar.
  void _onMessageMouseMove() {
    if (!_suppressUntilMouseMove) return;

    // Don't clear suppress while scroll events are still arriving.
    // Touchpad scrolling can cause micro cursor movements (wobble) that
    // trigger onHover — creating+destroying an OverlayEntry mid-scroll
    // causes a visible hitch.
    final timeSinceScroll = DateTime.now().difference(_lastScrollEventAt);
    if (timeSinceScroll < _scrollSettleThreshold) return;

    _suppressUntilMouseMove = false;

    // Mouse actually moved — safe to show the action bar now.
    if (!_isMouseOnMessage || !mounted || _overlayEntry != null) return;

    if (_activeInstance != null && _activeInstance != this) {
      _showTimer?.cancel();
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
              _dismissOverlayOnScroll();
            }
          },
          // Dismiss on precision touchpad scroll (Windows/Mac trackpad)
          onPointerPanZoomStart: (_) => _dismissOverlayOnScroll(),
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

  /// Dismiss due to scroll event — activates suppress flag so the bar won't
  /// reappear until the user actually moves the mouse cursor.
  void _dismissOverlayOnScroll() {
    _dismissOverlay();
    _isMouseOnMessage = false;
    _isMouseOnBar = false;
    _showTimer?.cancel();
    _suppressUntilMouseMove = true;
    _lastScrollEventAt = DateTime.now();
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

    return Listener(
      // Track scroll events for settle detection + dismiss overlay if showing.
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _lastScrollEventAt = DateTime.now();
          if (_overlayEntry != null) {
            _dismissOverlayOnScroll();
          }
        }
      },
      onPointerPanZoomStart: (_) {
        _lastScrollEventAt = DateTime.now();
        if (_overlayEntry != null) {
          _dismissOverlayOnScroll();
        }
      },
      child: MouseRegion(
        onEnter: (_) => _onMessageMouseEnter(),
        onExit: (_) => _onMessageMouseExit(),
        onHover: (_) => _onMessageMouseMove(),
        child: GestureDetector(
          onSecondaryTapUp: _onSecondaryTap,
          child: widget.child,
        ),
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
