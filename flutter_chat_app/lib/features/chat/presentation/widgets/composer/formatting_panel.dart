import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/format_button.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// The expandable formatting panel (Layer B in the 2-layer toolbar
/// design).
///
/// Contains: **B I U S** · colour · bullet · number · alignment · link
/// · clear · undo · redo.
///
/// The panel reads active formats from [QuillController] and updates
/// reactively via [ValueListenableBuilder].
class FormattingPanel extends StatelessWidget {
  const FormattingPanel({
    required this.controller,
    required this.onInsertLink,
    this.editorFocusNode,
    super.key,
  });

  /// The Quill editor controller to query/toggle attributes.
  final QuillController controller;

  /// Callback when the "insert link" button is pressed.
  /// The parent is responsible for showing a dialog.
  final VoidCallback onInsertLink;

  /// Optional focus node of the editor — used to restore focus after
  /// formatting button taps so that `toggledStyle` is not lost.
  final FocusNode? editorFocusNode;

  // ─────────────────── Build ───────────────────

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      height: ComposerConstants.formattingPanelHeight,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDarkMode
            : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
            width: AppDimens.dividerThin,
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final attrs = controller.getSelectionStyle().attributes;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingSmall,
            ),
            child: Row(
              children: [
                // ── Inline styles ──
                FormatButton(
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                  isActive: attrs.containsKey(Attribute.bold.key),
                  onPressed: () => _toggleInline(Attribute.bold),
                ),
                FormatButton(
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                  isActive: attrs.containsKey(Attribute.italic.key),
                  onPressed: () => _toggleInline(Attribute.italic),
                ),
                FormatButton(
                  icon: Icons.format_underlined,
                  tooltip: 'Underline',
                  isActive: attrs.containsKey(Attribute.underline.key),
                  onPressed: () => _toggleInline(Attribute.underline),
                ),
                FormatButton(
                  icon: Icons.format_strikethrough,
                  tooltip: 'Strikethrough',
                  isActive: attrs.containsKey(Attribute.strikeThrough.key),
                  onPressed: () => _toggleInline(Attribute.strikeThrough),
                ),

                _divider(context),

                // ── Block styles ──
                FormatButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'Bullet list',
                  isActive: attrs[Attribute.list.key]?.value == 'bullet',
                  onPressed: () => _toggleBlock(Attribute.ul),
                ),
                FormatButton(
                  icon: Icons.format_list_numbered,
                  tooltip: 'Numbered list',
                  isActive: attrs[Attribute.list.key]?.value == 'ordered',
                  onPressed: () => _toggleBlock(Attribute.ol),
                ),

                _divider(context),

                // ── Link ──
                FormatButton(
                  icon: Icons.link,
                  tooltip: 'Insert link',
                  isActive: attrs.containsKey(Attribute.link.key),
                  onPressed: onInsertLink,
                ),

                // ── Clear formatting ──
                FormatButton(
                  icon: Icons.format_clear,
                  tooltip: 'Clear formatting',
                  onPressed: _clearFormatting,
                ),

                _divider(context),

                // ── Undo / Redo ──
                FormatButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  isEnabled: controller.hasUndo,
                  onPressed: () => controller.undo(),
                ),
                FormatButton(
                  icon: Icons.redo,
                  tooltip: 'Redo',
                  isEnabled: controller.hasRedo,
                  onPressed: () => controller.redo(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────── Helpers ───────────────────

  void _toggleInline(Attribute attribute) {
    controller.formatSelection(attribute);
    _restoreEditorFocus();
  }

  void _toggleBlock(Attribute attribute) {
    final style = controller.getSelectionStyle();
    final isActive = style.attributes[Attribute.list.key]?.value ==
        attribute.value;

    if (isActive) {
      controller.formatSelection(Attribute.clone(Attribute.list, null));
    } else {
      controller.formatSelection(attribute);
    }
    _restoreEditorFocus();
  }

  void _clearFormatting() {
    final selection = controller.selection;
    if (selection.isCollapsed) return;

    // Remove all inline attributes from selection by applying
    // key-only attributes with null value.
    final keysToRemove = <String>[
      Attribute.bold.key,
      Attribute.italic.key,
      Attribute.underline.key,
      Attribute.strikeThrough.key,
      Attribute.link.key,
    ];
    for (final key in keysToRemove) {
      controller.formatSelection(Attribute.fromKeyValue(key, null));
    }
    _restoreEditorFocus();
  }

  /// Re-focus the editor so that `toggledStyle` (pending format for
  /// the next typed character) is not cleared by a focus change.
  void _restoreEditorFocus() {
    final node = editorFocusNode;
    if (node != null && !node.hasFocus) {
      node.requestFocus();
    }
  }

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ComposerConstants.formatButtonSpacing,
      ),
      child: SizedBox(
        height: 20,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
        ),
      ),
    );
  }
}
