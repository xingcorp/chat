import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_reaction_emoji.dart';

/// A modal bottom sheet that displays a curated list of 24 high-quality 3D reaction emojis.
///
/// Tap selects the emoji and triggers the callback.
class ReactionEmojiPickerBottomSheet extends StatelessWidget {
  final void Function(String emoji) onEmojiSelected;

  const ReactionEmojiPickerBottomSheet({
    Key? key,
    required this.onEmojiSelected,
  }) : super(key: key);

  static const List<String> _reactionEmojis = [
    '👍', '❤️', '😂', '😮', '😢', '😡', '🎉', '🔥',
    '👏', '🙏', '🤔', '🥳', '😎', '👀', '💯', '🤩',
    '😍', '🤭', '😱', '🤯', '🤫', '🤤', '💩', '💡',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              context.l10n.reactToMessage,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            // Emoji grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: _reactionEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _reactionEmojis[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      onEmojiSelected(emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: AppReactionEmoji(
                        emoji: emoji,
                        size: 30.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the reaction emoji picker sheet
  static Future<void> show(
    BuildContext context, {
    required void Function(String emoji) onEmojiSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReactionEmojiPickerBottomSheet(
        onEmojiSelected: onEmojiSelected,
      ),
    );
  }
}
