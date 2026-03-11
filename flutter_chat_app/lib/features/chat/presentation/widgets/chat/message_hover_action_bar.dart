import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_action_callbacks.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Default emoji grid shown in the "All Emojis" section of the quick picker.
// ---------------------------------------------------------------------------
const List<String> _kDefaultEmojis = [
  '\u{1F44D}', '\u{1F44E}', '\u{2764}\u{FE0F}', '\u{1F525}',
  '\u{1F389}', '\u{1F602}', '\u{1F62E}', '\u{1F622}',
  '\u{1F621}', '\u{1F970}', '\u{1F923}', '\u{1F60D}',
  '\u{1F618}', '\u{1F917}', '\u{1F929}', '\u{1F60E}',
  '\u{1F60F}', '\u{1F644}', '\u{1F634}', '\u{1F92E}',
  '\u{1F624}', '\u{1F62D}', '\u{1F631}', '\u{1F92F}',
  '\u{1F633}', '\u{1F97A}', '\u{1F64F}', '\u{1F4AA}',
  '\u{270C}\u{FE0F}', '\u{1F91D}', '\u{1F44A}', '\u{1F4AF}',
  '\u{1FAE1}', '\u{1F3AF}', '\u{1F4A1}', '\u{2B50}',
  '\u{1F31F}', '\u{1F496}', '\u{1F494}', '\u{1F44F}',
];

/// Like emoji used for the quick-like button.
const String _kLikeEmoji = '\u{1F44D}'; // 👍

// ---------------------------------------------------------------------------
// COMPACT ACTION BAR  (Lark-style)
// ---------------------------------------------------------------------------

/// Compact floating toolbar shown beside a message bubble on desktop hover.
///
/// **Layout**: `[👍  ↩  ↪  ⋯]` — 4 icon buttons, ~140 px width.
///
/// - **Like button (👍)**: tap → quick-like; hover → [EmojiQuickPickerPopup].
/// - **Reply / Forward / More**: same callbacks as the previous wide bar.
///
/// Rendered inside an [OverlayEntry] by [DesktopMessageHoverWrapper].
class CompactActionBar extends BaseStatefulWidget {
  final MessageActionCallbacks callbacks;
  final bool isCurrentUser;
  final bool isTextMessage;

  /// Frequently-used emoji list passed down for the emoji quick-picker popup.
  final List<String> quickReactions;

  final VoidCallback onMouseEnter;
  final VoidCallback onMouseExit;
  final GlobalKey moreButtonKey;

  /// Re-evaluate parent hide logic when the "More" popup dismisses.
  final VoidCallback? onMorePopupDismissed;

  const CompactActionBar({
    super.key,
    required this.callbacks,
    required this.isCurrentUser,
    required this.isTextMessage,
    required this.quickReactions,
    required this.onMouseEnter,
    required this.onMouseExit,
    required this.moreButtonKey,
    this.onMorePopupDismissed,
  });

  @override
  State<CompactActionBar> createState() => _CompactActionBarState();
}

class _CompactActionBarState extends BaseState<CompactActionBar> {
  // --- Emoji quick-picker overlay ---
  OverlayEntry? _emojiOverlay;
  Timer? _emojiShowTimer;
  Timer? _emojiHideTimer;
  bool _isMouseOnLikeButton = false;
  bool _isMouseOnEmojiPopup = false;
  final GlobalKey _likeButtonKey = GlobalKey();

  static const Duration _emojiShowDelay = Duration(milliseconds: 200);
  static const Duration _emojiHideDelay = Duration(milliseconds: 300);

  @override
  void dispose() {
    _emojiShowTimer?.cancel();
    _emojiHideTimer?.cancel();
    _dismissEmojiPopup();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Emoji popup hover state machine
  // -----------------------------------------------------------------------

  void _onLikeMouseEnter() {
    _isMouseOnLikeButton = true;
    _emojiHideTimer?.cancel();
    _emojiShowTimer?.cancel();
    _emojiShowTimer = Timer(_emojiShowDelay, () {
      if (_isMouseOnLikeButton && mounted) {
        _showEmojiPopup();
      }
    });
  }

  void _onLikeMouseExit() {
    _isMouseOnLikeButton = false;
    _emojiShowTimer?.cancel();
    _scheduleEmojiHideIfNeeded();
  }

  void _onEmojiPopupMouseEnter() {
    _isMouseOnEmojiPopup = true;
    _emojiHideTimer?.cancel();
    // CRITICAL: Tell the parent wrapper (DesktopMessageHoverWrapper) that the
    // mouse is still logically "on the bar". The emoji popup is a separate
    // OverlayEntry outside CompactActionBar's widget tree, so moving the mouse
    // onto it causes CompactActionBar's MouseRegion to fire onExit — which
    // would make the wrapper dismiss everything after its 200 ms hide timer.
    // By calling onMouseEnter here we keep the wrapper alive.
    widget.onMouseEnter();
  }

  void _onEmojiPopupMouseExit() {
    _isMouseOnEmojiPopup = false;
    _scheduleEmojiHideIfNeeded();
    // Mirror: let the parent wrapper know the mouse left the emoji popup.
    // If the mouse isn't back on the CompactActionBar's MouseRegion, the
    // wrapper will start its own hide timer.
    widget.onMouseExit();
  }

  void _scheduleEmojiHideIfNeeded() {
    if (_isMouseOnLikeButton || _isMouseOnEmojiPopup) return;
    _emojiHideTimer?.cancel();
    _emojiHideTimer = Timer(_emojiHideDelay, () {
      if (!_isMouseOnLikeButton && !_isMouseOnEmojiPopup) {
        _dismissEmojiPopup();
      }
    });
  }

  // -----------------------------------------------------------------------
  // Emoji popup overlay management
  // -----------------------------------------------------------------------

  void _showEmojiPopup() {
    if (_emojiOverlay != null) return;
    if (!mounted) return;

    final likeRenderBox =
        _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (likeRenderBox == null || !likeRenderBox.hasSize) return;

    final overlay = Overlay.of(context);
    final overlayRenderBox =
        overlay.context.findRenderObject() as RenderBox?;
    if (overlayRenderBox == null) return;

    final btnPos =
        likeRenderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
    final btnSize = likeRenderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // --- Position calculation ---
    const popupWidth = 324.0; // 8 emoji × 36 + padding
    const popupMaxHeight = 320.0;

    // Horizontal: try to center popup with the like button, clamp to screen.
    double dx = btnPos.dx - popupWidth / 2 + btnSize.width / 2;
    dx = dx.clamp(
      AppDimens.paddingSmall,
      screenSize.width - popupWidth - AppDimens.paddingSmall,
    );

    // Vertical: prefer ABOVE the action bar.
    double dy = btnPos.dy - popupMaxHeight - AppDimens.spaceSmall;
    final bool showAbove = dy >= AppDimens.paddingSmall;
    if (!showAbove) {
      // Not enough room above → place BELOW the action bar.
      dy = btnPos.dy + btnSize.height + AppDimens.spaceSmall;
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;

    _emojiOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: dx,
        top: dy,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: AppDimens.durationFast),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, showAbove ? (1 - value) * 6 : -(1 - value) * 6),
              child: child,
            ),
          ),
          child: _EmojiQuickPickerContent(
            frequentEmojis: widget.quickReactions,
            defaultEmojis: _kDefaultEmojis,
            onEmojiSelected: (emoji) {
              widget.callbacks.onReaction(emoji);
              _dismissEmojiPopup();
            },
            onAddReaction: () {
              _dismissEmojiPopup();
              widget.callbacks.onOpenEmojiPicker();
            },
            onMouseEnter: _onEmojiPopupMouseEnter,
            onMouseExit: _onEmojiPopupMouseExit,
            theme: theme,
            l10n: l10n,
          ),
        ),
      ),
    );

    overlay.insert(_emojiOverlay!);
  }

  void _dismissEmojiPopup() {
    _emojiOverlay?.remove();
    _emojiOverlay = null;
  }

  // -----------------------------------------------------------------------
  // More actions
  // -----------------------------------------------------------------------

  void _showMoreActions() {
    // Dismiss emoji popup first to avoid two popups.
    _dismissEmojiPopup();

    final renderBox =
        widget.moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    MoreActionsPopup.show(
      context,
      anchor: Offset(
        buttonPosition.dx + buttonSize.width / 2,
        buttonPosition.dy + buttonSize.height,
      ),
      isCurrentUser: widget.isCurrentUser,
      isTextMessage: widget.isTextMessage,
      onCopy: widget.callbacks.onCopy,
      onEdit: widget.callbacks.onEdit,
      onDelete: widget.callbacks.onDelete,
      onSelect: widget.callbacks.onSelect,
      onDismissed: widget.onMorePopupDismissed,
    );
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => widget.onMouseEnter(),
      onExit: (_) => widget.onMouseExit(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: AppDimens.dividerThin,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: AppDimens.elevationMedium,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXSmall,
            vertical: 2.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === Like / Emoji Button ===
              _buildLikeButton(theme, l10n),

              // === Divider ===
              Container(
                width: AppDimens.dividerThin,
                height: 20.0,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingXSmall,
                ),
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),

              // === Reply ===
              _buildActionIconButton(
                icon: Icons.reply,
                tooltip: l10n.reply,
                onPressed: widget.callbacks.onReply,
                theme: theme,
              ),

              // === Forward ===
              _buildActionIconButton(
                icon: Icons.shortcut,
                tooltip: l10n.forward,
                onPressed: widget.callbacks.onForward,
                theme: theme,
              ),

              // === More ===
              _buildActionIconButton(
                key: widget.moreButtonKey,
                icon: Icons.more_horiz,
                tooltip: l10n.moreActions,
                onPressed: _showMoreActions,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Like button: click → quick-like 👍, hover → emoji picker popup.
  Widget _buildLikeButton(ThemeData theme, dynamic l10n) {
    return MouseRegion(
      onEnter: (_) => _onLikeMouseEnter(),
      onExit: (_) => _onLikeMouseExit(),
      child: Tooltip(
        message: l10n.reactToMessage,
        child: InkWell(
          key: _likeButtonKey,
          onTap: () => widget.callbacks.onReaction(_kLikeEmoji),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              Icons.thumb_up_outlined,
              size: AppDimens.iconSmall,
              color: theme.iconTheme.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            size: AppDimens.iconSmall,
            color: theme.iconTheme.color?.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMOJI QUICK PICKER CONTENT  (2-section popup)
// ---------------------------------------------------------------------------

/// Internal content widget rendered inside the emoji overlay entry.
///
/// ```
/// ┌─────────────────────────────────────────┐
/// │  Frequently Used                         │
/// │  😀  🎉  👏  🔥  💯  ❤️  🤔  👀       │
/// │ ────────────────────────────────────────│
/// │  All Emojis                              │
/// │  👍  👎  ❤️  🔥  🎉  😂  😮  😢       │
/// │  😡  🥰  🤣  😍  😘  🤗  🤩  😎       │
/// │  …                                       │
/// └─────────────────────────────────────────┘
/// ```
class _EmojiQuickPickerContent extends StatelessWidget {
  final List<String> frequentEmojis;
  final List<String> defaultEmojis;
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onAddReaction;
  final VoidCallback onMouseEnter;
  final VoidCallback onMouseExit;
  final ThemeData theme;
  final dynamic l10n;

  static const double _cellSize = 36.0;
  static const double _emojiFontSize = 22.0;
  static const double _popupWidth = 324.0; // 8 × 36 + 2 × 10 padding
  static const double _popupMaxHeight = 320.0;

  const _EmojiQuickPickerContent({
    required this.frequentEmojis,
    required this.defaultEmojis,
    required this.onEmojiSelected,
    required this.onAddReaction,
    required this.onMouseEnter,
    required this.onMouseExit,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => onMouseEnter(),
      onExit: (_) => onMouseExit(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _popupWidth,
          constraints: const BoxConstraints(maxHeight: _popupMaxHeight),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: AppDimens.dividerThin,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: AppDimens.elevationLarge,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingSmall + 2,
              vertical: AppDimens.paddingSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // === Section 1: Frequently Used ===
                if (frequentEmojis.isNotEmpty) ...[
                  _buildSectionHeader(l10n.frequentlyUsed),
                  const SizedBox(height: AppDimens.spaceXSmall),
                  _buildEmojiRow(frequentEmojis, showAddButton: true),
                  const SizedBox(height: AppDimens.spaceSmall),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: AppDimens.spaceSmall),
                ],

                // === Section 2: Default / All Emojis ===
                _buildSectionHeader(l10n.defaultEmojis),
                const SizedBox(height: AppDimens.spaceXSmall),
                _buildEmojiGrid(defaultEmojis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Single-row layout with optional "+" add button (for frequent section).
  Widget _buildEmojiRow(List<String> emojis, {bool showAddButton = false}) {
    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: [
        ...emojis.map((emoji) => _buildEmojiCell(emoji)),
        if (showAddButton) _buildAddButton(),
      ],
    );
  }

  /// Grid layout for the "All Emojis" section.
  Widget _buildEmojiGrid(List<String> emojis) {
    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: emojis.map((emoji) => _buildEmojiCell(emoji)).toList(),
    );
  }

  Widget _buildEmojiCell(String emoji) {
    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: InkWell(
        onTap: () => onEmojiSelected(emoji),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        hoverColor: theme.hoverColor,
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: _emojiFontSize),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: Tooltip(
        message: l10n.addReaction,
        child: InkWell(
          onTap: onAddReaction,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          hoverColor: theme.hoverColor,
          child: Center(
            child: Icon(
              Icons.add_circle_outline,
              size: 20.0,
              color: theme.iconTheme.color?.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MORE ACTIONS POPUP  (unchanged from original)
// ---------------------------------------------------------------------------

/// Small popup appearing when "More" (⋯) is clicked in the hover action bar.
/// Shows contextual actions: Copy (text only), Edit (own text only),
/// Delete (own only), Select (always).
///
/// Uses [OverlayEntry] with a dismiss barrier (same pattern as [AppTooltip]).
class MoreActionsPopup {
  MoreActionsPopup._();

  static OverlayEntry? _overlayEntry;
  static OverlayEntry? _barrierEntry;

  /// Callback invoked after popup is dismissed (by barrier tap or action item).
  /// Used by [DesktopMessageHoverWrapper] to re-evaluate hide logic.
  static VoidCallback? _onDismissedCallback;

  /// Whether the popup is currently visible.
  static bool get isShowing => _overlayEntry != null;

  /// Show the more actions popup anchored below the given position.
  ///
  /// [onDismissed] is called after the popup is dismissed for any reason
  /// (action item tap, barrier tap, or programmatic dismiss).
  static void show(
    BuildContext context, {
    required Offset anchor,
    required bool isCurrentUser,
    required bool isTextMessage,
    required VoidCallback onCopy,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onSelect,
    VoidCallback? onDismissed,
  }) {
    dismiss();
    _onDismissedCallback = onDismissed;

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Build menu items
    final items = <_MoreActionItem>[];

    if (isTextMessage) {
      items.add(_MoreActionItem(
        icon: Icons.copy,
        label: l10n.copyMessage,
        onTap: () {
          dismiss();
          onCopy();
        },
      ));
    }

    if (isCurrentUser && isTextMessage) {
      items.add(_MoreActionItem(
        icon: Icons.edit,
        label: l10n.editMessage,
        onTap: () {
          dismiss();
          onEdit();
        },
      ));
    }

    if (isCurrentUser) {
      items.add(_MoreActionItem(
        icon: Icons.delete_outline,
        label: l10n.deleteMessage,
        onTap: () {
          dismiss();
          onDelete();
        },
        isDestructive: true,
      ));
    }

    items.add(_MoreActionItem(
      icon: Icons.checklist,
      label: l10n.selectMessage,
      onTap: () {
        dismiss();
        onSelect();
      },
    ));

    if (items.isEmpty) return;

    const popupWidth = 200.0;
    // Position: below anchor, clamped to screen
    final dx = (anchor.dx - popupWidth / 2).clamp(
      AppDimens.paddingSmall,
      screenSize.width - popupWidth - AppDimens.paddingSmall,
    );
    final dy = anchor.dy + AppDimens.paddingXSmall;

    // Dismiss barrier
    _barrierEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: dismiss,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      ),
    );

    // Popup content
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: dx,
        top: dy,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: popupWidth,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.surfaceDarkMode
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: AppDimens.dividerThin,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: AppDimens.elevationMedium,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                return InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingSmall * 1.5,
                      vertical: AppDimens.paddingSmall,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: AppDimens.iconSmall,
                          color: item.isDestructive
                              ? Colors.red
                              : theme.iconTheme.color,
                        ),
                        const SizedBox(width: AppDimens.spaceSmall),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: item.isDestructive
                                  ? Colors.red
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_barrierEntry!);
    overlay.insert(_overlayEntry!);
  }

  /// Dismiss the popup and its barrier.
  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _barrierEntry?.remove();
    _barrierEntry = null;
    final cb = _onDismissedCallback;
    _onDismissedCallback = null;
    cb?.call();
  }
}

/// Internal data class for a single menu item in [MoreActionsPopup].
class _MoreActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MoreActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
