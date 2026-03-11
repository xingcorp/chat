import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_theme.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// A read-only Quill renderer for displaying rich-text content inside
/// message bubbles.
///
/// Accepts a Delta JSON string ([deltaJson]) and renders it using
/// [QuillEditor] in read-only mode with compact bubble styles from
/// [ComposerTheme.bubbleStyles].
///
/// If [deltaJson] is null, empty, or invalid, falls back to rendering
/// [plainText] as a simple [Text] widget — no Quill overhead.
class RichTextBubble extends StatefulWidget {
  const RichTextBubble({
    required this.plainText,
    required this.isSender,
    this.deltaJson,
    this.textStyle,
    super.key,
  });

  /// Plain text fallback (always available from the server `message` field).
  final String plainText;

  /// Whether this bubble belongs to the current user (affects styling).
  final bool isSender;

  /// Quill Delta JSON string. When non-null and valid, the widget renders
  /// rich text; otherwise falls back to [plainText].
  final String? deltaJson;

  /// Optional base text style override. When null, uses
  /// [ComposerTheme.bubbleStyles] defaults.
  final TextStyle? textStyle;

  @override
  State<RichTextBubble> createState() => _RichTextBubbleState();
}

class _RichTextBubbleState extends State<RichTextBubble> {
  QuillController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant RichTextBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deltaJson != widget.deltaJson ||
        oldWidget.plainText != widget.plainText) {
      _disposeController();
      _initController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _initController() {
    final delta = _parseDelta(widget.deltaJson);
    if (delta == null) return;

    final document = Document.fromDelta(delta);
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller?.readOnly = true;
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  /// Parse Delta JSON string into a [Delta] object.
  ///
  /// Returns null if the input is null, empty, or invalid JSON.
  Delta? _parseDelta(String? json) {
    if (json == null || json.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return Delta.fromJson(decoded);
      }
      if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
        return Delta.fromJson(decoded['ops'] as List<dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback: plain text when no valid delta.
    if (_controller == null) {
      return Text(
        widget.plainText,
        style: widget.textStyle,
      );
    }

    return QuillEditor(
      controller: _controller!,
      focusNode: FocusNode(canRequestFocus: false),
      scrollController: ScrollController(),
      config: QuillEditorConfig(
        autoFocus: false,
        expands: false,
        padding: EdgeInsets.zero,
        showCursor: false,
        customStyles: ComposerTheme.bubbleStyles(
          context,
          isSender: widget.isSender,
        ),
      ),
    );
  }
}
