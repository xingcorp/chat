import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Extracts and displays a plain-text preview from a Quill Delta JSON string
/// for use in reply strips and forwarded message previews.
///
/// If [deltaJson] is null, empty, or invalid, falls back to [plainText].
/// This widget does NOT render rich formatting — it only extracts the text
/// content from the Delta for a compact one-line preview.
class RichTextReplyPreview extends StatelessWidget {
  const RichTextReplyPreview({
    required this.plainText,
    this.deltaJson,
    this.maxLines = 1,
    this.style,
    super.key,
  });

  /// Plain text fallback (always available from the server `message` field).
  final String plainText;

  /// Quill Delta JSON string. When non-null and valid, extracts plain text
  /// from the Delta ops; otherwise uses [plainText].
  final String? deltaJson;

  /// Maximum number of lines to display.
  final int maxLines;

  /// Optional text style override.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final displayText = _extractText();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      displayText,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style ??
          TextStyle(
            fontSize: 13.0,
            color: isDark
                ? AppColors.textSecondaryDarkMode
                : AppColors.textSecondary,
          ),
    );
  }

  /// Extract plain text from Delta JSON, falling back to [plainText].
  String _extractText() {
    if (deltaJson == null || deltaJson!.trim().isEmpty) {
      return plainText;
    }

    try {
      final decoded = jsonDecode(deltaJson!);
      final List<dynamic> ops;
      if (decoded is List) {
        ops = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
        ops = decoded['ops'] as List<dynamic>;
      } else {
        return plainText;
      }

      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map<String, dynamic>) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }

      final extracted = buffer.toString().trim();
      return extracted.isNotEmpty ? extracted : plainText;
    } catch (_) {
      return plainText;
    }
  }
}
