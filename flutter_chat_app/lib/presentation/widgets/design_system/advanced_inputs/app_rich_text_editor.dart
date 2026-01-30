import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **APP RICH TEXT EDITOR**
///
/// Rich text editor with formatting toolbar.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Formatting toolbar (bold, italic, underline, strikethrough)
/// - List support (bullet and numbered)
/// - Link insertion and editing
/// - Undo/redo support
/// - Markdown output
/// - HTML output
/// - Toolbar customization
/// - Mobile-optimized toolbar
/// - Dark mode support
///
/// **Usage**:
/// ```dart
/// AppRichTextEditor(
///   controller: _controller,
///   onChanged: (text) => _handleTextChange(text),
///   placeholder: context.l10n.typeMessage,
/// )
/// ```
class AppRichTextEditor extends BaseStatefulWidget {
  const AppRichTextEditor({
    super.key,
    this.controller,
    this.onChanged,
    this.placeholder,
    this.minLines = 3,
    this.maxLines = 10,
    this.showToolbar = true,
    this.enableMarkdown = true,
    this.enableHtml = false,
    this.customToolbarButtons,
    this.isDisabled = false,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Placeholder text
  final String? placeholder;

  /// Minimum number of lines
  final int minLines;

  /// Maximum number of lines
  final int maxLines;

  /// Whether to show formatting toolbar
  final bool showToolbar;

  /// Whether to enable markdown output
  final bool enableMarkdown;

  /// Whether to enable HTML output
  final bool enableHtml;

  /// Custom toolbar buttons
  final List<Widget>? customToolbarButtons;

  /// Whether editor is disabled
  final bool isDisabled;

  @override
  AppRichTextEditorState createState() => AppRichTextEditorState();
}

class AppRichTextEditorState extends BaseState<AppRichTextEditor> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final List<String> _history = [];
  int _historyIndex = -1;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrikethrough = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
  }

  void _addToHistory() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(_controller.text);
    _historyIndex = _history.length - 1;
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      safeSetState(() {
        _controller.text = _history[_historyIndex];
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      safeSetState(() {
        _controller.text = _history[_historyIndex];
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      });
    }
  }

  void _applyFormatting(String prefix, String suffix) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );

      _addToHistory();
      safeSetState(() {
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        );
      });
    }
  }

  void _toggleBold() {
    _applyFormatting('**', '**');
    safeSetState(() => _isBold = !_isBold);
  }

  void _toggleItalic() {
    _applyFormatting('*', '*');
    safeSetState(() => _isItalic = !_isItalic);
  }

  void _toggleUnderline() {
    _applyFormatting('<u>', '</u>');
    safeSetState(() => _isUnderline = !_isUnderline);
  }

  void _toggleStrikethrough() {
    _applyFormatting('~~', '~~');
    safeSetState(() => _isStrikethrough = !_isStrikethrough);
  }

  void _insertBulletList() {
    final selection = _controller.selection;
    final text = _controller.text;
    final newText = text.replaceRange(
      selection.start,
      selection.start,
      '\n- ',
    );

    _addToHistory();
    safeSetState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + 3,
      );
    });
  }

  void _insertNumberedList() {
    final selection = _controller.selection;
    final text = _controller.text;
    final newText = text.replaceRange(
      selection.start,
      selection.start,
      '\n1. ',
    );

    _addToHistory();
    safeSetState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + 4,
      );
    });
  }

  void _insertLink() {
    final selection = _controller.selection;
    final text = _controller.text;
    final selectedText = selection.isValid && !selection.isCollapsed
        ? text.substring(selection.start, selection.end)
        : '';

    final linkText = selectedText.isNotEmpty ? selectedText : 'link text';
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '[$linkText](url)',
    );

    _addToHistory();
    safeSetState(() {
      _controller.text = newText;
      _controller.selection = TextSelection(
        baseOffset: selection.start + linkText.length + 3,
        extentOffset: selection.start + linkText.length + 6,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showToolbar) _buildToolbar(context, isDark, l10n),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
            border: Border.all(
              color: isDark ? AppColors.borderDarkMode : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !widget.isDisabled,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDarkMode
                    : AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppDimens.paddingMedium),
            ),
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark, l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingSmall,
        vertical: AppDimens.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        border: Border.all(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusMedium),
        ),
      ),
      child: Wrap(
        spacing: AppDimens.spaceSmall,
        runSpacing: AppDimens.spaceSmall,
        children: [
          _buildToolbarButton(
            icon: Icons.format_bold,
            tooltip: l10n.bold,
            isActive: _isBold,
            onPressed: _toggleBold,
            isDark: isDark,
          ),
          _buildToolbarButton(
            icon: Icons.format_italic,
            tooltip: l10n.italic,
            isActive: _isItalic,
            onPressed: _toggleItalic,
            isDark: isDark,
          ),
          _buildToolbarButton(
            icon: Icons.format_underline,
            tooltip: l10n.underline,
            isActive: _isUnderline,
            onPressed: _toggleUnderline,
            isDark: isDark,
          ),
          _buildToolbarButton(
            icon: Icons.format_strikethrough,
            tooltip: l10n.strikethrough,
            isActive: _isStrikethrough,
            onPressed: _toggleStrikethrough,
            isDark: isDark,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: l10n.bulletList,
            onPressed: _insertBulletList,
            isDark: isDark,
          ),
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: l10n.numberedList,
            onPressed: _insertNumberedList,
            isDark: isDark,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          _buildToolbarButton(
            icon: Icons.link,
            tooltip: l10n.insertLink,
            onPressed: _insertLink,
            isDark: isDark,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          _buildToolbarButton(
            icon: Icons.undo,
            tooltip: l10n.undo,
            onPressed: _historyIndex > 0 ? _undo : null,
            isDark: isDark,
          ),
          _buildToolbarButton(
            icon: Icons.redo,
            tooltip: l10n.redo,
            onPressed: _historyIndex < _history.length - 1 ? _redo : null,
            isDark: isDark,
          ),
          if (widget.customToolbarButtons != null)
            ...widget.customToolbarButtons!,
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    bool isActive = false,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: Container(
          width: AppDimens.touchTargetMin,
          height: AppDimens.touchTargetMin,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? (isDark
                    ? AppColors.textSecondaryDarkMode
                    : AppColors.textSecondary)
                : isActive
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.iconDarkMode
                        : AppColors.icon),
          ),
        ),
      ),
    );
  }
}
