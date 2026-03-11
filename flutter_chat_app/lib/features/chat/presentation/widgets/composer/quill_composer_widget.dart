import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_theme.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/link_dialog.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/quill_composer_controller.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/toolbar_orchestrator.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// The main rich-text composer widget.
///
/// Assembles:
/// - [QuillEditor] with auto-growing height
/// - [ToolbarOrchestrator] (action row + formatting panel)
/// - Send button
///
/// This widget does NOT manage its own [QuillComposerController] — the
/// parent must create one and pass it in so that draft save/restore and
/// send logic can access the controller externally.
class QuillComposerWidget extends StatefulWidget {
  const QuillComposerWidget({
    required this.composerController,
    required this.onSend,
    required this.focusNode,
    this.onTypingStarted,
    this.onTypingEnded,
    this.onEmojiPressed,
    this.onAttachPressed,
    this.placeholder,
    this.showSendButton = true,
    this.readOnly = false,
    super.key,
  });

  /// The controller that wraps [QuillController].
  final QuillComposerController composerController;

  /// Called when the user triggers send (Enter on desktop or send button).
  final VoidCallback onSend;

  /// Focus node for the editor — owned by the parent so it can
  /// request focus after send, draft restore, etc.
  final FocusNode focusNode;

  /// Called when the user starts typing.
  final VoidCallback? onTypingStarted;

  /// Called when the user stops typing (debounced).
  final VoidCallback? onTypingEnded;

  /// Called when the emoji button is pressed.
  final VoidCallback? onEmojiPressed;

  /// Called when the attach button is pressed.
  final VoidCallback? onAttachPressed;

  /// Placeholder text shown when the editor is empty.
  final String? placeholder;

  /// Whether to show the send button in the action row.
  final bool showSendButton;

  /// Whether the editor is read-only (e.g. during voice recording).
  final bool readOnly;

  @override
  State<QuillComposerWidget> createState() => _QuillComposerWidgetState();
}

class _QuillComposerWidgetState extends State<QuillComposerWidget> {
  bool _isTyping = false;
  Timer? _typingTimer;
  static const _typingTimeout = Duration(milliseconds: 1500);

  StreamSubscription<void>? _changeSub;

  @override
  void initState() {
    super.initState();
    _syncReadOnly();
    _changeSub = widget.composerController.onDocumentChanged.listen((_) {
      _onContentChanged();
    });
  }

  @override
  void didUpdateWidget(covariant QuillComposerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly) {
      _syncReadOnly();
    }
    if (oldWidget.composerController != widget.composerController) {
      _syncReadOnly();
      _changeSub?.cancel();
      _changeSub = widget.composerController.onDocumentChanged.listen((_) {
        _onContentChanged();
      });
    }
  }

  void _syncReadOnly() {
    widget.composerController.quillController.readOnly = widget.readOnly;
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_isTyping) {
      _isTyping = true;
      widget.onTypingStarted?.call();
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingTimeout, () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingEnded?.call();
      }
    });
    // Trigger rebuild for send button visibility.
    if (mounted) setState(() {});
  }

  void _handleSend() {
    if (widget.composerController.isEmpty) return;
    _isTyping = false;
    _typingTimer?.cancel();
    widget.onTypingEnded?.call();
    widget.onSend();
  }

  void _handleInsertLink() async {
    final result = await showComposerLinkDialog(
      context,
      widget.composerController.quillController,
    );
    if (result == null) return;

    final controller = widget.composerController.quillController;
    final selection = controller.selection;
    final text = result.key;
    final url = result.value;

    if (selection.isCollapsed) {
      // Insert link text at cursor.
      final index = selection.baseOffset;
      controller.document.insert(index, text);
      controller.formatText(
        index,
        text.length,
        Attribute.fromKeyValue('link', url),
      );
      controller.updateSelection(
        TextSelection.collapsed(offset: index + text.length),
        ChangeSource.local,
      );
    } else {
      // Apply link to existing selection.
      controller.formatSelection(
        Attribute.fromKeyValue('link', url),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final isEmpty = widget.composerController.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Editor surface ──
        Container(
          constraints: const BoxConstraints(
            minHeight: ComposerConstants.editorMinHeight,
            maxHeight: ComposerConstants.editorMaxHeight,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
            borderRadius: BorderRadius.circular(
              ComposerConstants.editorBorderRadius,
            ),
            border: Border.all(
              color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ComposerConstants.editorHorizontalPadding,
            vertical: ComposerConstants.editorVerticalPadding,
          ),
          child: QuillEditor(
            controller: widget.composerController.quillController,
            focusNode: widget.focusNode,
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              placeholder: widget.placeholder,
              autoFocus: false,
              expands: false,
              padding: EdgeInsets.zero,
              customStyles: ComposerTheme.composerStyles(context),
            ),
          ),
        ),

        const SizedBox(height: AppDimens.spaceXSmall),

        // ── Toolbar + send button ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ToolbarOrchestrator(
                controller: widget.composerController.quillController,
                onEmojiPressed: widget.onEmojiPressed ?? () {},
                onAttachPressed: widget.onAttachPressed ?? () {},
                onInsertLink: _handleInsertLink,
              ),
            ),
            if (widget.showSendButton) ...[
              const SizedBox(width: AppDimens.spaceSmall),
              _SendButton(
                onPressed: isEmpty ? null : _handleSend,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Circular send button that enables/disables based on content.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: 'Send',
      child: Material(
        color: isEnabled
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: ComposerConstants.sendButtonSize,
            height: ComposerConstants.sendButtonSize,
            child: Icon(
              Icons.send_rounded,
              size: ComposerConstants.sendIconSize,
              color: isEnabled
                  ? AppColors.textButton
                  : AppColors.textButton.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
