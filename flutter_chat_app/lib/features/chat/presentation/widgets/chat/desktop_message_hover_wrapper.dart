import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_action_callbacks.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_hover_action_bar.dart';

/// **DESKTOP MESSAGE HOVER WRAPPER**
///
/// Wraps a [MessageItem] to add desktop hover action bar support.
/// On desktop, hovering over a message shows a floating toolbar above
/// the message bubble with quick reactions and action buttons.
///
/// On mobile (or when [isDesktop] is false), this widget is a transparent
/// pass-through with zero overhead — it simply returns [child] directly.
///
/// **Key behaviors**:
/// - Uses [MouseRegion] for hover detection
/// - Uses [OverlayEntry] to render the action bar above the scroll container
/// - 200ms hide delay prevents flicker when cursor moves between message and bar
/// - Only one action bar is visible at a time (singleton pattern)
/// - Scroll events dismiss the action bar immediately
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
///   callbacks: MessageActionCallbacks(...),
///   child: MessageItem(...),
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

  /// Quick reaction emojis to show in the action bar
  final List<String> quickReactions;

  /// Whether hover actions are enabled (false in selection mode, deleted msgs)
  final bool enabled;

  const DesktopMessageHoverWrapper({
    super.key,
    required this.child,
    required this.callbacks,
    required this.isCurrentUser,
    required this.isTextMessage,
    required this.isDesktop,
    required this.quickReactions,
    this.enabled = true,
  });

  @override
  State<DesktopMessageHoverWrapper> createState() =>
      _DesktopMessageHoverWrapperState();
}

class _DesktopMessageHoverWrapperState
    extends BaseState<DesktopMessageHoverWrapper> {
  /// Currently active instance — ensures only one bar is visible at a time
  static _DesktopMessageHoverWrapperState? _activeInstance;

  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  /// Timer to delay showing bar when stealing focus from another message.
  /// Prevents bar "jumping" when cursor crosses an intermediate message
  /// on the way to the currently active bar.
  Timer? _showTimer;

  bool _isMouseOnMessage = false;
  bool _isMouseOnBar = false;
  final GlobalKey _moreButtonKey = GlobalKey();

  /// Height of the action bar (estimated for positioning)
  static const double _barHeight = 40.0;

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
    final overlayRenderBox =
        overlay.context.findRenderObject() as RenderBox?;
    if (overlayRenderBox == null) return;

    final messagePosition =
        renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
    final messageSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Calculate position
    final positionData = _calculateBarPosition(
      messagePosition: messagePosition,
      messageSize: messageSize,
      screenSize: screenSize,
    );

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: positionData.dx,
        top: positionData.dy,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: AppDimens.durationFast),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 4),
              child: child,
            ),
          ),
          child: MessageHoverActionBar(
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
    );

    overlay.insert(_overlayEntry!);
  }

  _BarPosition _calculateBarPosition({
    required Offset messagePosition,
    required Size messageSize,
    required Size screenSize,
  }) {
    // Horizontal: align with the message bubble edge
    double dx;
    if (widget.isCurrentUser) {
      // Own messages: right-align the bar with the message right edge
      // Estimate bar width (~360px for 6 emojis + 3 action buttons)
      const estimatedBarWidth = 360.0;
      dx = messagePosition.dx + messageSize.width - estimatedBarWidth;
      // Clamp to screen
      if (dx < AppDimens.paddingSmall) {
        dx = AppDimens.paddingSmall;
      }
    } else {
      // Others' messages: left-align with avatar slot offset
      dx = messagePosition.dx + AppDimens.paddingSmall;
    }

    // Clamp right edge
    const estimatedBarWidth = 360.0;
    if (dx + estimatedBarWidth > screenSize.width - AppDimens.paddingSmall) {
      dx = screenSize.width - estimatedBarWidth - AppDimens.paddingSmall;
    }

    // Vertical: prefer above the message
    double dy = messagePosition.dy - _barHeight - _barGap;

    // If not enough space above, place below
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Dismiss action bar on any scroll
        if (_overlayEntry != null) {
          _dismissOverlay();
        }
        return false; // Don't consume the notification
      },
      child: MouseRegion(
        onEnter: (_) => _onMessageMouseEnter(),
        onExit: (_) => _onMessageMouseExit(),
        child: GestureDetector(
          onSecondaryTapUp: _onSecondaryTap,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Simple position data class for the action bar overlay.
class _BarPosition {
  final double dx;
  final double dy;

  const _BarPosition(this.dx, this.dy);
}
