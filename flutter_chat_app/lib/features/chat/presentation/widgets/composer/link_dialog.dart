import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// A dialog for inserting or editing a hyperlink.
///
/// Provides two text fields — **display text** and **URL** — and
/// returns a `MapEntry<String, String>` on submit where key = text and
/// value = URL.
///
/// Usage:
/// ```dart
/// final result = await showLinkDialog(context, controller);
/// if (result != null) {
///   // apply link to selection
/// }
/// ```
Future<MapEntry<String, String>?> showComposerLinkDialog(
  BuildContext context,
  QuillController controller,
) {
  final selection = controller.selection;
  final selectedText = selection.isCollapsed
      ? ''
      : controller.document.getPlainText(
          selection.start,
          selection.end - selection.start,
        );

  // Check if selection already has a link attribute.
  final existingLink = controller
      .getSelectionStyle()
      .attributes[Attribute.link.key]
      ?.value as String?;

  return showDialog<MapEntry<String, String>>(
    context: context,
    builder: (_) => _LinkDialogContent(
      initialText: selectedText,
      initialUrl: existingLink ?? '',
    ),
  );
}

class _LinkDialogContent extends StatefulWidget {
  const _LinkDialogContent({
    required this.initialText,
    required this.initialUrl,
  });

  final String initialText;
  final String initialUrl;

  @override
  State<_LinkDialogContent> createState() => _LinkDialogContentState();
}

class _LinkDialogContentState extends State<_LinkDialogContent> {
  late final TextEditingController _textController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _urlController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        'Insert link',
        style: TextStyle(
          color: isDark
              ? AppColors.textPrimaryDarkMode
              : AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Display text',
              hintText: 'Link text',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'URL',
              hintText: 'https://',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? _submit : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  void _submit() {
    final text = _textController.text.trim().isNotEmpty
        ? _textController.text.trim()
        : _urlController.text.trim();
    final url = _urlController.text.trim();
    Navigator.of(context).pop(MapEntry(text, url));
  }
}
