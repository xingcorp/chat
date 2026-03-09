import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_action_callbacks.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **MESSAGE HOVER ACTION BAR**
///
/// Floating toolbar displayed above a message bubble on desktop hover.
/// Shows quick reaction emojis + action icon buttons (Reply, Forward, More).
///
/// Rendered inside an `OverlayEntry` by [DesktopMessageHoverWrapper].
/// Wrapped in a [MouseRegion] to signal hover state back to the wrapper,
/// preventing flicker when cursor moves between message and action bar.
///
/// **Visual layout**:
/// ```
/// ┌──────────────────────────────────────────────────────────┐
/// │  👍  ❤️  😂  😮  😢  😡  ➕  │  ↩  ↪  ⋯               │
/// └──────────────────────────────────────────────────────────┘
/// ```
class MessageHoverActionBar extends BaseStatelessWidget {
  final MessageActionCallbacks callbacks;
  final bool isCurrentUser;
  final bool isTextMessage;
  final List<String> quickReactions;
  final VoidCallback onMouseEnter;
  final VoidCallback onMouseExit;
  final GlobalKey moreButtonKey;

  /// Called when the "More" popup is dismissed (barrier tap or action item).
  /// Allows [DesktopMessageHoverWrapper] to re-evaluate hide logic.
  final VoidCallback? onMorePopupDismissed;

  const MessageHoverActionBar({
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
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => onMouseEnter(),
      onExit: (_) => onMouseExit(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXSmall,
            vertical: 2.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === Quick Reaction Emojis ===
              ...quickReactions.map(
                (emoji) => _buildReactionButton(emoji, theme),
              ),
              _buildAddReactionButton(theme, l10n),

              // === Divider ===
              Container(
                width: AppDimens.dividerThin,
                height: 20.0,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingXSmall,
                ),
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),

              // === Action Buttons ===
              _buildActionIconButton(
                icon: Icons.reply,
                tooltip: l10n.reply,
                onPressed: callbacks.onReply,
                theme: theme,
              ),
              _buildActionIconButton(
                icon: Icons.shortcut,
                tooltip: l10n.forward,
                onPressed: callbacks.onForward,
                theme: theme,
              ),
              _buildActionIconButton(
                key: moreButtonKey,
                icon: Icons.more_horiz,
                tooltip: l10n.moreActions,
                onPressed: () => _showMoreActions(context),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(String emoji, ThemeData theme) {
    return InkWell(
      onTap: () => callbacks.onReaction(emoji),
      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }

  Widget _buildAddReactionButton(ThemeData theme, dynamic l10n) {
    return InkWell(
      onTap: callbacks.onOpenEmojiPicker,
      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      child: Tooltip(
        message: l10n.addReaction,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.add_reaction_outlined,
            size: AppDimens.iconSmall,
            color: theme.iconTheme.color?.withValues(alpha: 0.6),
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

  void _showMoreActions(BuildContext context) {
    final renderBox =
        moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    MoreActionsPopup.show(
      context,
      anchor: Offset(
        buttonPosition.dx + buttonSize.width / 2,
        buttonPosition.dy + buttonSize.height,
      ),
      isCurrentUser: isCurrentUser,
      isTextMessage: isTextMessage,
      onCopy: callbacks.onCopy,
      onEdit: callbacks.onEdit,
      onDelete: callbacks.onDelete,
      onSelect: callbacks.onSelect,
      onDismissed: onMorePopupDismissed,
    );
  }
}

/// **MORE ACTIONS POPUP**
///
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
