import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/emoji_shortcode_service.dart';

/// Overlay widget hiển thị danh sách emoji suggestions khi user gõ `:shortcode`
///
/// Pattern: Discord / Telegram / Slack
/// - Hiện phía trên input field
/// - 4-6 suggestions tối đa
/// - Navigate bằng arrow keys (desktop) hoặc tap (mobile)
/// - Dismiss bằng Escape, tap outside, hoặc xóa `:`
///
/// Usage trong ChatInput:
/// ```dart
/// ShortcodeAutocompleteOverlay(
///   query: 'smi', // phần text sau ':'
///   onSelect: (emoji, shortcode) {
///     // Replace ':smi' bằng emoji trong TextEditingController
///   },
///   onDismiss: () {
///     // Ẩn overlay
///   },
///   anchorKey: _inputGlobalKey,
/// )
/// ```
class ShortcodeAutocompleteOverlay extends StatelessWidget {
  /// Query text (phần sau `:`, không bao gồm `:`)
  final String query;

  /// Callback khi user chọn emoji
  /// Parameters: (emoji Unicode character, shortcode name)
  final void Function(String emoji, String shortcode) onSelect;

  /// Callback khi overlay cần dismiss
  final VoidCallback? onDismiss;

  /// Chiều rộng tối đa
  final double maxWidth;

  const ShortcodeAutocompleteOverlay({
    super.key,
    required this.query,
    required this.onSelect,
    this.onDismiss,
    this.maxWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    final results = EmojiShortcodeService.search(query, limit: 6);

    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 8.0,
      borderRadius: BorderRadius.circular(12.0),
      color: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      shadowColor: Colors.black26,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: 300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final match = results[index];
              return _ShortcodeItem(
                match: match,
                onTap: () => onSelect(match.emoji, match.shortcode),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Single item trong shortcode autocomplete list
class _ShortcodeItem extends StatelessWidget {
  final EmojiShortcodeMatch match;
  final VoidCallback onTap;

  const _ShortcodeItem({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji character (lớn)
            Text(
              match.emoji,
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(width: 10.0),
            // Shortcode name
            Flexible(
              child: Text(
                ':${match.shortcode}:',
                style: TextStyle(
                  fontSize: 14.0,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
