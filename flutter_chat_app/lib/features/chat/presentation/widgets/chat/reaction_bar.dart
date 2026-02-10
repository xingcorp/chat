import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Widget hiển thị reactions gom nhóm dưới message bubble
///
/// Khớp với:
/// - Angular: countReactions(), getUniqueReactors()
/// - stream_chat_flutter: reaction_bubble.dart + reaction_indicator.dart
///
/// Features:
/// - Hiển thị emoji với số lượng reactors
/// - Highlight emoji mà currentUser đã react
/// - Tap emoji → toggle add/remove reaction
/// - Long press emoji → hiện modal danh sách reactors
/// - Tap "+" → hiện emoji picker để thêm reaction
class ReactionBar extends StatelessWidget {
  /// Reactions đã gom nhóm theo emoji
  final List<ReactionGroup> groupedReactions;

  /// Callback khi user tap vào emoji để toggle reaction
  /// Tham số: emoji code, isCurrentlyReacted
  final void Function(String emojiCode, bool isCurrentlyReacted)? onReactionTap;

  /// Callback khi user long press vào emoji để xem danh sách reactors
  /// Tham số: emoji code, reactor IDs, reactor names
  final void Function(
    String emojiCode,
    List<String> reactorIds,
    List<String> reactorNames,
  )? onReactionLongPress;

  /// Callback khi user tap nút "+" để thêm reaction mới
  final VoidCallback? onAddReaction;

  /// Hiển thị nút "+" để thêm reaction không
  final bool showAddButton;

  const ReactionBar({
    Key? key,
    required this.groupedReactions,
    this.onReactionTap,
    this.onReactionLongPress,
    this.onAddReaction,
    this.showAddButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (groupedReactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: [
          // Render từng reaction group
          for (final reaction in groupedReactions)
            _buildReactionChip(context, theme, reaction),

          // Nút "+" để thêm reaction
          if (showAddButton && onAddReaction != null)
            _buildAddButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildReactionChip(
    BuildContext context,
    ThemeData theme,
    ReactionGroup reaction,
  ) {
    final isReacted = reaction.isReactedByCurrentUser;
    final backgroundColor = isReacted
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.colorScheme.surface;
    final borderColor = isReacted
        ? theme.colorScheme.primary
        : theme.dividerColor;

    return GestureDetector(
      onTap: () => onReactionTap?.call(reaction.code, isReacted),
      onLongPress: () => onReactionLongPress?.call(
        reaction.code,
        reaction.reactorIds,
        reaction.reactorNames,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isReacted ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji
            Text(
              reaction.code,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(width: 4.0),
            // Số lượng reactors
            Text(
              '${reaction.count}',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: isReacted ? FontWeight.w600 : FontWeight.normal,
                color: isReacted
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: onAddReaction,
      child: Container(
        width: 28.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.dividerColor,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(
          Icons.add,
          size: 16.0,
          color: theme.iconTheme.color,
        ),
      ),
    );
  }
}

/// Modal hiển thị danh sách người react một emoji cụ thể
///
/// Khớp Angular: hiển thị reactors[] với fullName
class ReactionDetailModal extends StatelessWidget {
  final String emojiCode;
  final List<String> reactorNames;

  const ReactionDetailModal({
    Key? key,
    required this.emojiCode,
    required this.reactorNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                emojiCode,
                style: const TextStyle(fontSize: 24.0),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  '${reactorNames.length} ${l10n.messageCount(reactorNames.length)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          // Danh sách reactors
          if (reactorNames.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  l10n.noUsers,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            )
          else
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: reactorNames.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final name = reactorNames[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        name.isNotEmpty
                            ? name.characters.first.toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(name),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Helper method để show modal
  static Future<void> show(
    BuildContext context, {
    required String emojiCode,
    required List<String> reactorNames,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReactionDetailModal(
        emojiCode: emojiCode,
        reactorNames: reactorNames,
      ),
    );
  }
}
