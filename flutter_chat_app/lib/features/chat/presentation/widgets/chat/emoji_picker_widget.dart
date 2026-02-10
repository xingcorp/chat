import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';

/// Wrapper widget cho emoji_picker_flutter với i18n support
///
/// Features:
/// - Recent emojis tab
/// - Category-based organization
/// - Search support
/// - Localized UI (en + vi)
/// - Callback khi chọn emoji
/// - Responsive height
class AppEmojiPicker extends StatelessWidget {
  /// Callback khi user chọn emoji
  final void Function(String emoji) onEmojiSelected;

  /// Callback khi backspace pressed (để xóa emoji)
  final VoidCallback? onBackspacePressed;

  /// Controller cho TextField (optional - để insert emoji vào position)
  final TextEditingController? textController;

  /// Height của picker (default: 250)
  final double height;

  /// Có hiển thị search bar không
  final bool enableSearch;

  const AppEmojiPicker({
    Key? key,
    required this.onEmojiSelected,
    this.onBackspacePressed,
    this.textController,
    this.height = 250,
    this.enableSearch = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: height,
      child: EmojiPicker(
        textEditingController: textController,
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        onBackspacePressed: onBackspacePressed,
        config: Config(
          height: height,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            // Số cột emoji
            columns: 7,
            // Kích thước emoji
            emojiSizeMax: 28.0,
            // Khoảng cách giữa các emoji
            verticalSpacing: 0,
            horizontalSpacing: 0,
            // Hiển thị grid
            gridPadding: EdgeInsets.zero,
            // Background color
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            // Progress indicator
            loadingIndicator: const SizedBox.shrink(),
            // No emojis text
            noRecents: Text(
              _getNoRecentsText(l10n),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            // Button mode
            buttonMode: ButtonMode.MATERIAL,
            // Recents limit
            recentsLimit: 28,
            // Replace emoji when tapping on it
            replaceEmojiOnLimitExceed: false,
          ),
          categoryViewConfig: CategoryViewConfig(
            // Icon color
            iconColor: Theme.of(context).iconTheme.color ?? Colors.grey,
            iconColorSelected: Theme.of(context).colorScheme.primary,
            // Indicator color
            indicatorColor: Theme.of(context).colorScheme.primary,
            // Background color
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            // Category labels (localized)
            categoryIcons: CategoryIcons(
              recentIcon: Icons.access_time,
              smileyIcon: Icons.emoji_emotions_outlined,
              animalIcon: Icons.pets_outlined,
              foodIcon: Icons.restaurant_outlined,
              activityIcon: Icons.sports_soccer_outlined,
              travelIcon: Icons.flight_outlined,
              objectIcon: Icons.lightbulb_outlined,
              symbolIcon: Icons.emoji_symbols_outlined,
              flagIcon: Icons.flag_outlined,
            ),
            // Divider color
            dividerColor: Theme.of(context).dividerColor,
          ),
          skinToneConfig: SkinToneConfig(
            enabled: true,
            dialogBackgroundColor: Theme.of(context).dialogBackgroundColor,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            enabled: false,
          ),
          searchViewConfig: enableSearch
              ? SearchViewConfig(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  buttonIconColor: Theme.of(context).iconTheme.color ?? Colors.grey,
                  hintText: _getSearchHintText(l10n),
                )
              : const SearchViewConfig(),
        ),
      ),
    );
  }

  /// Get localized "No recents" text
  String _getNoRecentsText(AppLocalizations l10n) {
    return l10n.noRecentEmojis;
  }

  /// Get localized search hint text
  String _getSearchHintText(AppLocalizations l10n) {
    return l10n.search;
  }
}

/// Bottom sheet wrapper cho emoji picker
///
/// Dùng để show emoji picker từ input field hoặc reaction bar
class EmojiPickerBottomSheet extends StatelessWidget {
  final void Function(String emoji) onEmojiSelected;
  final TextEditingController? textController;

  const EmojiPickerBottomSheet({
    Key? key,
    required this.onEmojiSelected,
    this.textController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          // Emoji picker
          AppEmojiPicker(
            onEmojiSelected: (emoji) {
              onEmojiSelected(emoji);
              Navigator.pop(context);
            },
            textController: textController,
            height: 300,
            enableSearch: true,
          ),
        ],
      ),
    );
  }

  /// Static method để show bottom sheet
  static Future<void> show(
    BuildContext context, {
    required void Function(String emoji) onEmojiSelected,
    TextEditingController? textController,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmojiPickerBottomSheet(
        onEmojiSelected: onEmojiSelected,
        textController: textController,
      ),
    );
  }
}

/// Inline emoji picker widget (không dùng bottom sheet)
///
/// Dùng để hiện picker trực tiếp trong UI (e.g., trên keyboard)
class InlineEmojiPicker extends StatefulWidget {
  final void Function(String emoji) onEmojiSelected;
  final TextEditingController? textController;
  final double height;

  const InlineEmojiPicker({
    Key? key,
    required this.onEmojiSelected,
    this.textController,
    this.height = 250,
  }) : super(key: key);

  @override
  State<InlineEmojiPicker> createState() => _InlineEmojiPickerState();
}

class _InlineEmojiPickerState extends State<InlineEmojiPicker> {
  @override
  Widget build(BuildContext context) {
    return AppEmojiPicker(
      onEmojiSelected: widget.onEmojiSelected,
      textController: widget.textController,
      height: widget.height,
      enableSearch: false, // Không cần search cho inline
      onBackspacePressed: () {
        // Xóa character cuối cùng
        if (widget.textController != null &&
            widget.textController!.text.isNotEmpty) {
          final text = widget.textController!.text;
          final selection = widget.textController!.selection;

          if (selection.baseOffset > 0) {
            final newText = text.substring(0, selection.baseOffset - 1) +
                text.substring(selection.baseOffset);
            widget.textController!.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                offset: selection.baseOffset - 1,
              ),
            );
          }
        }
      },
    );
  }
}

/// Helper class để insert emoji vào TextEditingController tại cursor position
class EmojiTextEditingHelper {
  /// Insert emoji tại cursor position
  static void insertEmoji(
    TextEditingController controller,
    String emoji,
  ) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    if (cursorPos < 0) {
      // Không có cursor position, append vào cuối
      controller.text = text + emoji;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    } else {
      // Insert tại cursor position
      final newText =
          text.substring(0, cursorPos) + emoji + text.substring(cursorPos);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPos + emoji.length,
        ),
      );
    }
  }

  /// Xóa character cuối cùng (backspace)
  static void deleteLastCharacter(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;

    if (text.isEmpty) return;

    if (selection.baseOffset > 0) {
      final newText = text.substring(0, selection.baseOffset - 1) +
          text.substring(selection.baseOffset);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset - 1,
        ),
      );
    }
  }
}
